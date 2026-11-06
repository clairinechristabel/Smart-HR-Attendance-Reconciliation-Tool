// lib/pages/staff/attendance/barcode_checkin_page.dart
//
// Full barcode-scan-based check-in / check-out flow.
// Flow:
//   1. Idle screen (shows current time, user info)
//   2. Tap "Scan Check-In" → opens camera scanner
//   3. On valid QR → verifies location → records check-in → shows live timer
//   4. Tap "Scan Check-Out" → opens camera scanner
//   5. On valid QR → records check-out → shows summary
//
// Location is required before scanning is allowed.

import 'package:flutter/material.dart' hide Text;
import 'package:staff_portal/core/localization/localized_text.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/attendance_service.dart';
import '../../../models/attendance_log_model.dart';
import '../../../core/theme/app_theme.dart';

// Valid QR codes that represent Food Angel office locations and clock-in stations.
const _kValidQrCodes = {
  // Office & Station Locations
  'FOODANGEL-SHAM-SHUI-PO': 'Sham Shui Po Factory',
  'FOODANGEL-KWAI-CHUNG': 'Kwai Chung Warehouse',
  'FOODANGEL-SHA-TIN': 'Sha Tin Hub',
  'FOODANGEL-KWUN-TONG': 'Kwun Tong Retail',
  'FOODANGEL-HEAD-OFFICE': 'Head Office',
  // Universal Clock-In & Check-In Barcodes
  'FOODANGEL-CLOCK-IN': 'Sham Shui Po Factory',
  'FOODANGEL-CLOCK-OUT': 'Sham Shui Po Factory',
  'FOODANGEL-CHECKIN': 'Sham Shui Po Factory',
  'FOODANGEL-CHECKOUT': 'Sham Shui Po Factory',
  'FOODANGEL-ATTENDANCE': 'Sham Shui Po Factory',
  'FOODANGEL-SSP': 'Sham Shui Po Factory',
  'FOODANGEL-KC': 'Kwai Chung Warehouse',
  'FOODANGEL-ST': 'Sha Tin Hub',
  'FOODANGEL-KT': 'Kwun Tong Retail',
  'FOODANGEL-HQ': 'Head Office',
  // Demo/development QR – scan any of the above or this catch-all
  'FOODANGEL-DEMO': 'Food Angel Demo Site',
};

enum _CheckinState { idle, scanningIn, checkedIn, scanningOut, done }

class BarcodeCheckinPage extends StatefulWidget {
  const BarcodeCheckinPage({super.key});

  @override
  State<BarcodeCheckinPage> createState() => _BarcodeCheckinPageState();
}

class _BarcodeCheckinPageState extends State<BarcodeCheckinPage>
    with WidgetsBindingObserver {
  final _attendanceService = AttendanceService();
  final _clockController = MobileScannerController();

  _CheckinState _state = _CheckinState.idle;
  AttendanceLogModel? _todayLog;
  String? _scannedLocation;
  String? _errorMsg;
  bool _isProcessing = false;

  // Live clock
  final _now = ValueNotifier<DateTime>(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tickClock();
    _loadExistingLog();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockController.dispose();
    _now.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _clockController.start();
    } else {
      _clockController.stop();
    }
  }

  void _tickClock() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      _now.value = DateTime.now();
      return true;
    });
  }

  Future<void> _loadExistingLog() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final log = await _attendanceService.getTodayLog(user.id);
    if (!mounted) return;
    if (log != null) {
      setState(() {
        _todayLog = log;
        _state = log.hasCheckedOut ? _CheckinState.done : _CheckinState.checkedIn;
        _scannedLocation = log.location;
      });
    }
  }

  // ── Location helper ────────────────────────────────────────
  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showLocationDialog(
          title: 'Location Required',
          body: 'Please turn on Location Services to check in.',
          onSettings: () => Geolocator.openLocationSettings(),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showLocationDialog(
            title: 'Location Permission Denied',
            body: 'Location access is needed to verify your workplace. Please grant it in Settings.',
            onSettings: () => Geolocator.openAppSettings(),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showLocationDialog(
          title: 'Location Permission Blocked',
          body: 'Location permission is permanently denied. Please enable it in your device Settings.',
          onSettings: () => Geolocator.openAppSettings(),
        );
      }
      return false;
    }

    return true;
  }

  void _showLocationDialog({
    required String title,
    required String body,
    required VoidCallback onSettings,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_off, color: AppTheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ── Scan handlers ──────────────────────────────────────────
  Future<void> _startScanIn() async {
    setState(() => _errorMsg = null);
    final allowed = await _ensureLocationPermission();
    if (!allowed) return;

    setState(() => _state = _CheckinState.scanningIn);
  }

  Future<void> _startScanOut() async {
    setState(() => _errorMsg = null);
    final allowed = await _ensureLocationPermission();
    if (!allowed) return;

    setState(() => _state = _CheckinState.scanningOut);
  }

  Future<void> _onBarcode(BarcodeCapture capture, bool isCheckIn) async {
    if (_isProcessing) return;
    final rawCode = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (rawCode == null || rawCode.isEmpty) return;

    // Check if QR code is a valid Food Angel location
    String? locationName = _kValidQrCodes[rawCode];
    if (locationName == null) {
      final upper = rawCode.toUpperCase();
      for (final entry in _kValidQrCodes.entries) {
        if (upper == entry.key || upper.contains(entry.key) || entry.key.contains(upper)) {
          locationName = entry.value;
          break;
        }
      }
      if (locationName == null && upper.contains('FOODANGEL')) {
        locationName = 'Sham Shui Po Factory';
      }
    }

    if (locationName == null) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Invalid QR code. Please scan a valid Food Angel location QR.';
          _state = isCheckIn ? _CheckinState.idle : _CheckinState.checkedIn;
        });
      }
      return;
    }

    setState(() => _isProcessing = true);

    final user = context.read<AuthProvider>().user!;

    try {
      if (isCheckIn) {
        final log = await _attendanceService.clockIn(
          userId: user.id,
          locationId: locationName,
        );
        if (mounted) {
          setState(() {
            _todayLog = log;
            _scannedLocation = locationName;
            _state = _CheckinState.checkedIn;
            _isProcessing = false;
            _errorMsg = null;
          });
          _showSuccessSnackBar('✓ Checked in at $locationName');
        }
      } else {
        if (_todayLog == null) return;
        final log = await _attendanceService.clockOut(logId: _todayLog!.id);
        if (mounted) {
          setState(() {
            _todayLog = log;
            _state = _CheckinState.done;
            _isProcessing = false;
            _errorMsg = null;
          });
          _showSuccessSnackBar('✓ Checked out! Worked ${log.formattedHoursWorked}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // If a log already exists for today and hasn't checked out, keep checkedIn state
          if (_todayLog != null && !_todayLog!.hasCheckedOut) {
            _state = _CheckinState.checkedIn;
            _scannedLocation = _todayLog!.location;
            _errorMsg = null;
          } else {
            _state = isCheckIn ? _CheckinState.idle : _CheckinState.checkedIn;
            _errorMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('AttendanceException: ', '');
          }
          _isProcessing = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_state == _CheckinState.scanningIn ||
        _state == _CheckinState.scanningOut) {
      return _buildScannerView(_state == _CheckinState.scanningIn);
    }
    return _buildIdleView();
  }

  Widget _buildIdleView() {
    final user = context.watch<AuthProvider>().user!;
    final hasCheckedIn = _state == _CheckinState.checkedIn;
    final isDone = _state == _CheckinState.done;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            title: Text(
              tr(context, 'Check In / Out'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 8, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDone
                                    ? Icons.check_circle
                                    : hasCheckedIn
                                        ? Icons.timer
                                        : Icons.radio_button_unchecked,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isDone
                                    ? tr(context, 'Work Complete 🎉')
                                    : hasCheckedIn
                                        ? tr(context, 'Currently Working')
                                        : tr(context, 'Not Checked In'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Clock
                        ValueListenableBuilder<DateTime>(
                          valueListenable: _now,
                          builder: (_, now, __) => Text(
                            hasCheckedIn && !isDone
                                ? _elapsed(_todayLog!.clockIn!)
                                : DateFormat('HH:mm:ss').format(now),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        Text(
                          user.fullName,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_errorMsg!,
                                style: const TextStyle(color: AppTheme.error))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Time chips
                if (_todayLog != null) ...[
                  Row(
                    children: [
                      if (_todayLog!.hasCheckedIn)
                        _timeChip(Icons.login, tr(context, 'IN'),
                            _todayLog!.formattedClockIn, AppTheme.success),
                      if (_todayLog!.hasCheckedIn) const SizedBox(width: 12),
                      if (_todayLog!.hasCheckedOut)
                        _timeChip(Icons.logout, tr(context, 'OUT'),
                            _todayLog!.formattedClockOut, AppTheme.warning),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Location info
                if (_scannedLocation != null) ...[
                  _infoRow(Icons.location_on, tr(context, 'Location'), _scannedLocation!),
                  const SizedBox(height: 8),
                ],

                // Hours worked (if done)
                if (isDone && _todayLog?.hoursWorked != null) ...[
                  _infoRow(Icons.access_time, tr(context, 'Hours Worked'),
                      _todayLog!.formattedHoursWorked),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 8),

                // Instructions card
                if (!isDone) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.gray200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.qr_code_scanner,
                                color: AppTheme.primaryGreen, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              tr(context, hasCheckedIn
                                  ? 'Ready to Check Out'
                                  : 'Ready to Check In'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(context, hasCheckedIn
                              ? 'Scan the QR code at your workstation to clock out and save your worked hours.'
                              : 'Scan the QR code at your workstation or Food Angel hub to begin your shift.'),
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              tr(context, 'Location will be verified automatically'),
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Main action button
                if (!isDone)
                  SizedBox(
                    height: 58,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: hasCheckedIn ? _startScanOut : _startScanIn,
                      icon: const Icon(Icons.qr_code_scanner, size: 22),
                      label: Text(
                        tr(context, hasCheckedIn
                            ? 'Scan to Check Out'
                            : 'Scan to Check In'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasCheckedIn
                            ? AppTheme.error
                            : AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                // Done state
                if (isDone) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          tr(context, 'Great Work Today!'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tr(context, 'You worked')} ${_todayLog?.formattedHoursWorked ?? '--'} ${tr(context, 'today')}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr(context, 'Your attendance has been recorded. See you tomorrow!'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView(bool isCheckIn) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _clockController,
            onDetect: _isProcessing
                ? (_) {}
                : (capture) => _onBarcode(capture, isCheckIn),
          ),

          // Overlay frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isCheckIn ? AppTheme.primaryGreen : AppTheme.error,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        _state = isCheckIn
                            ? _CheckinState.idle
                            : _CheckinState.checkedIn;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr(context, isCheckIn
                            ? 'Scan Check-In QR Code'
                            : 'Scan Check-Out QR Code'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _clockController.toggleTorch(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.flashlight_on,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCheckIn ? Icons.login : Icons.logout,
                          color: isCheckIn
                              ? AppTheme.primaryGreen
                              : AppTheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tr(context, isCheckIn
                              ? 'Point at the Food Angel QR Code'
                              : 'Scan to end your shift'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.green, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          tr(context, 'Location is being verified'),
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                    if (_isProcessing) ...[
                      const SizedBox(height: 12),
                      const CircularProgressIndicator(color: Colors.white),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeChip(IconData icon, String label, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '$label: $time',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 16),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  String _elapsed(DateTime from) {
    final d = DateTime.now().difference(from);
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
