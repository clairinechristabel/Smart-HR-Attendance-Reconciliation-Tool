// lib/widgets/mini_tour_modal.dart
import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_portal/core/localization/localized_text.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class MiniTourModal extends StatefulWidget {
  final String? userId;
  final String? role;
  final VoidCallback? onComplete;

  const MiniTourModal({
    super.key,
    this.userId,
    this.role,
    this.onComplete,
  });

  /// Show the role-specific mini tour if not seen before, or forced when tapped manually
  static Future<void> show(
    BuildContext context, {
    bool force = false,
    String? userId,
    String? role,
  }) async {
    final effectiveRole = role ??
        (context.read<AuthProvider>().user?.role ?? UserRole.staff);
    final effectiveUserId = userId ?? context.read<AuthProvider>().user?.id;
    final prefs = await SharedPreferences.getInstance();

    final roleKey = effectiveRole.toLowerCase();
    final userKey = effectiveUserId != null
        ? 'has_seen_${roleKey}_tour_$effectiveUserId'
        : 'has_seen_${roleKey}_tour_v1';
    final hasSeen = prefs.getBool(userKey) ?? false;

    if (!force && hasSeen) return;
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MiniTourModal(
        userId: effectiveUserId,
        role: effectiveRole,
      ),
    );
  }

  @override
  State<MiniTourModal> createState() => _MiniTourModalState();
}

class _TourStep {
  final String tag;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final List<String> highlights;
  final Widget preview;

  const _TourStep({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.highlights,
    required this.preview,
  });
}

class _MiniTourModalState extends State<MiniTourModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = true;

  // Interactive demo states for Staff
  bool _demoClockedIn = false;
  bool _demoClockedOut = false;
  String _demoLeaveStatus = 'Pending';

  // Interactive demo states for Supervisor
  bool _supervisorDemoApproved = false;
  String _supervisorTeamFilter = 'All';

  // Interactive demo states for HR
  bool _hrDemoStaffRegistered = false;
  bool _hrDemoL2Approved = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeTour() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      final roleKey = (widget.role ?? UserRole.staff).toLowerCase();
      if (widget.userId != null) {
        await prefs.setBool('has_seen_${roleKey}_tour_${widget.userId}', true);
      }
      await prefs.setBool('has_seen_${roleKey}_tour_v1', true);
    }
    if (mounted) {
      Navigator.of(context).pop();
      widget.onComplete?.call();
    }
  }

  void _nextPage(int totalSteps) {
    if (_currentPage < totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeTour();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════
  // STAFF TOUR STEPS
  // ══════════════════════════════════════════════════════════════
  List<_TourStep> _buildStaffSteps() {
    return [
      _TourStep(
        tag: 'WELCOME ABOARD',
        title: 'Welcome to Food Angel',
        subtitle:
            'Your all-in-one Smart HR mobile tool for daily shifts, real-time attendance, and seamless leave requests.',
        icon: Icons.volunteer_activism_rounded,
        gradientColors: const [Color(0xFF16A34A), Color(0xFF0D9488)],
        highlights: [
          '⚡ Scan QR Attendance with Location Verification',
          '📋 Real-Time Leave Balances & Fast Submissions',
          '📊 Monthly Timesheets & Worked Hours Tracking',
        ],
        preview: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/foodangellogo.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.restaurant,
                    size: 24,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Food Angel Staff Portal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Staff Quick Tour & Guide',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreenDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Staff Step 2: Check in via QR scan
      _TourStep(
        tag: 'STEP 1 • SCAN CHECK-IN',
        title: 'Scan QR Code to Check In',
        subtitle:
            'You are NOT checked in automatically upon login. Turn on your GPS location and scan the workstation QR code to start your shift.',
        icon: Icons.qr_code_scanner_rounded,
        gradientColors: const [Color(0xFF22C55E), Color(0xFF15803D)],
        highlights: [
          '📍 Location Required: GPS ensures you are physically at your station.',
          '📷 Scan QR Code: Tap "Scan Check-In QR" to open the camera scanner.',
          '⏱️ Live Timer Starts: Shift timer begins counting immediately after scan.',
        ],
        preview: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: _demoClockedIn
                ? const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _demoClockedIn ? 'Currently Working' : 'Not Checked In',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _demoClockedIn ? '04:12:30' : '09:00 AM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _demoClockedIn ? Icons.timer : Icons.qr_code_2,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _demoClockedIn
                        ? const Color(0xFF0F172A)
                        : AppTheme.primaryGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _demoClockedIn = !_demoClockedIn;
                      if (!_demoClockedIn) _demoClockedOut = false;
                    });
                  },
                  icon: Icon(
                    _demoClockedIn ? Icons.restart_alt : Icons.qr_code_scanner,
                    size: 16,
                  ),
                  label: Text(
                    _demoClockedIn
                        ? 'Checked In! (Tap to reset)'
                        : 'Tap to Simulate QR Scan',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Staff Step 3: Check out
      _TourStep(
        tag: 'STEP 2 • SCAN CHECK-OUT',
        title: 'Scan QR Code to Check Out',
        subtitle:
            'When your shift ends, tap "Scan Check-Out QR" to record your departure and log your total hours.',
        icon: Icons.logout_rounded,
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        highlights: [
          '🛑 Scan Out QR: Scan workstation QR to complete shift record.',
          '⏱️ Accurate Timesheet: Hours worked are calculated and logged automatically.',
          '📈 Shift Summary: View your completed shift duration and status.',
        ],
        preview: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _demoClockedOut
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _demoClockedOut
                              ? Icons.task_alt
                              : Icons.access_time_filled,
                          color: _demoClockedOut
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _demoClockedOut
                            ? 'Work Complete 🎉'
                            : 'Shift In Progress',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_demoClockedOut)
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () =>
                          setState(() => _demoClockedOut = false),
                      child: const Text('Undo', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sham Shui Po Factory',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      _demoClockedOut ? '8h 00m Worked' : 'Active 08:30 → Now',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _demoClockedOut
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Staff Step 4: Leave Requests
      _TourStep(
        tag: 'STEP 3 • LEAVE REQUEST',
        title: 'How to Submit a Leave Request',
        subtitle:
            'Need time off? Check your live leave balance and submit your request in seconds for quick supervisor approval.',
        icon: Icons.calendar_month_rounded,
        gradientColors: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
        highlights: [
          '📊 Real-Time Balances: Check remaining Annual, Sick, and Personal quotas.',
          '⚡ 2-Step Application: Select leave type, pick start and end dates.',
          '🔄 Transparent Tracking: View real-time status as supervisor & HR review.',
        ],
        preview: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCCFBF1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Annual Leave • 2 Days',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _demoLeaveStatus,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniQuotaCard(
                      label: 'Annual',
                      days: '14 Left',
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildMiniQuotaCard(
                      label: 'Sick',
                      days: '12 Left',
                      color: const Color(0xFFE11D48),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildMiniQuotaCard(
                      label: 'Personal',
                      days: '3 Left',
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // Staff Step 5: Profile & Replay
      _TourStep(
        tag: 'STEP 4 • PROFILE & HELP',
        title: 'Profile, Help & Ready to Go!',
        subtitle:
            'Update your personal contact details, get approval notifications, and replay this tour whenever you need a refresher.',
        icon: Icons.rocket_launch_rounded,
        gradientColors: const [Color(0xFFF97316), Color(0xFFEA580C)],
        highlights: [
          '👤 Profile & Contacts: Update phone number and emergency contacts.',
          '🧭 Replay Tour Anytime: Tap the top bar 🧭 icon or visit Profile > App Mini Tour.',
          '🔔 Status Notifications: Real-time updates when supervisor approves leaves.',
        ],
        preview: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF97316).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF97316).withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.stars_rounded, color: Color(0xFFF97316), size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You\'re ready! Tap "Get Started" to start using your Food Angel Portal.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // ══════════════════════════════════════════════════════════════
  // SUPERVISOR TOUR STEPS (No checkin/checkout; approval & team focus)
  // ══════════════════════════════════════════════════════════════
  List<_TourStep> _buildSupervisorSteps() {
    return [
      _TourStep(
        tag: 'SUPERVISOR WORKSPACE',
        title: 'Welcome, Supervisor!',
        subtitle:
            'Supervisors do NOT check in or check out. Your role is leading your team, approving leaves, and monitoring shift coverage across stations.',
        icon: Icons.supervisor_account_rounded,
        gradientColors: const [Color(0xFF0284C7), Color(0xFF1E40AF)],
        highlights: [
          '🛡️ No Punch Needed: Supervisors manage shifts without checking in/out.',
          '📋 Level 1 Leave Approvals: Verify and approve staff leave requests.',
          '👥 Live Team Roster: Real-time oversight across your assigned stations.',
        ],
        preview: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Color(0xFF0284C7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Supervisor Operations Hub',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Shift Management & Approvals',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'No Punch Req.',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Supervisor Step 2: How to approve leave requests
      _TourStep(
        tag: 'STEP 1 • LEAVE APPROVALS',
        title: 'How to Approve Leave Requests',
        subtitle:
            'When team members apply for sick, annual, or emergency leave, you conduct Level 1 review and approval.',
        icon: Icons.fact_check_rounded,
        gradientColors: const [Color(0xFF0D9488), Color(0xFF059669)],
        highlights: [
          '⚡ 1-Tap Quick Approve: Tap "Approve" directly on pending leave cards.',
          '🔍 Inspect Reason & Proof: View reason, dates, and medical certificates.',
          '⏩ Escalates to HR: L1 approved requests automatically advance to HR.',
        ],
        preview: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lisa Chan • Kitchen Helper',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _supervisorDemoApproved
                          ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _supervisorDemoApproved ? 'L1 APPROVED' : 'PENDING',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: _supervisorDemoApproved
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Annual Leave • 3 Days (Nov 15 - 17)\nReason: Family gathering vacation',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _supervisorDemoApproved
                        ? const Color(0xFF15803D)
                        : const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() =>
                        _supervisorDemoApproved = !_supervisorDemoApproved);
                  },
                  icon: Icon(
                    _supervisorDemoApproved
                        ? Icons.check_circle
                        : Icons.thumb_up_alt_rounded,
                    size: 15,
                  ),
                  label: Text(
                    _supervisorDemoApproved
                        ? '✓ Approved (Tap to Reset)'
                        : 'Simulate 1-Tap Approve',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Supervisor Step 3: Team Attendance Monitoring
      _TourStep(
        tag: 'STEP 2 • TEAM ROSTER',
        title: 'Live Team Attendance & Coverage',
        subtitle:
            'Monitor who has scanned in at your assigned workstations (Sham Shui Po, Kwai Chung, etc.) in real time without roll calls.',
        icon: Icons.groups_rounded,
        gradientColors: const [Color(0xFF6366F1), Color(0xFF4338CA)],
        highlights: [
          '🟢 Real-Time Presence: See who is on site and who hasn\'t scanned in yet.',
          '⏱️ Shift Hours: Inspect exact clock-in times and accumulated hours.',
          '📍 Station Filter: Switch between your assigned warehouses and hubs.',
        ],
        preview: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Coverage',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3730A3),
                    ),
                  ),
                  Row(
                    children: [
                      _buildMiniFilterPill('All', _supervisorTeamFilter == 'All', () {
                        setState(() => _supervisorTeamFilter = 'All');
                      }),
                      const SizedBox(width: 4),
                      _buildMiniFilterPill('SSP', _supervisorTeamFilter == 'SSP', () {
                        setState(() => _supervisorTeamFilter = 'SSP');
                      }),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildMiniTeamRow(
                name: 'Lisa Chan',
                site: 'Sham Shui Po',
                time: '08:30 AM',
                isPresent: true,
              ),
              const SizedBox(height: 6),
              _buildMiniTeamRow(
                name: 'David Ho',
                site: 'Kwai Chung',
                time: 'Scheduled',
                isPresent: false,
              ),
            ],
          ),
        ),
      ),

      // Supervisor Step 4: What You Can Do as Supervisor
      _TourStep(
        tag: 'STEP 3 • SUPERVISOR TOOLS',
        title: 'What You Can Do as Supervisor',
        subtitle:
            'Quick overview of your supervisor tools across bottom navigation tabs.',
        icon: Icons.admin_panel_settings_rounded,
        gradientColors: const [Color(0xFF0EA5E9), Color(0xFF0369A1)],
        highlights: [
          '📊 Dashboard: Summary counts of pending leaves & present staff today.',
          '📋 Leaves Tab: Filter pending, approved, and past leave submissions.',
          '👥 Team Tab: View staff profiles, contact numbers, and shifts.',
          '🧭 Quick Replay: Tap the compass 🧭 on the top bar anytime to replay.',
        ],
        preview: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabPreviewIcon(Icons.dashboard_rounded, 'Dashboard', true),
              _buildTabPreviewIcon(Icons.approval_rounded, 'Leaves', true),
              _buildTabPreviewIcon(Icons.groups_rounded, 'Team', true),
              _buildTabPreviewIcon(Icons.person_rounded, 'Profile', false),
            ],
          ),
        ),
      ),
    ];
  }

  // ══════════════════════════════════════════════════════════════
  // HR ADMIN TOUR STEPS (Staff registration, L2 approvals, directory)
  // ══════════════════════════════════════════════════════════════
  List<_TourStep> _buildHRSteps() {
    return [
      _TourStep(
        tag: 'HR ADMIN CENTER',
        title: 'Welcome to HR Administration',
        subtitle:
            'As HR Administrator, you oversee the entire organization: registering new staff, setting up office credentials, and issuing final leave approvals.',
        icon: Icons.corporate_fare_rounded,
        gradientColors: const [Color(0xFF7C3AED), Color(0xFF9333EA)],
        highlights: [
          '👥 Register New Staff & Assign Office Credentials Instantly',
          '⚖️ Level 2 (Final) Leave Authorizations & Company Policies',
          '📈 Organization-Wide Workforce Directory & Audit Records',
        ],
        preview: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Color(0xFF7C3AED),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'HR Central Administration',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'All-Staff Operations & Policies',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Full Access',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B21A8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // HR Step 2: Register Staff & Office Credentials
      _TourStep(
        tag: 'STEP 1 • REGISTER STAFF',
        title: 'Register Staff & Office Credentials',
        subtitle:
            'Easily create employee accounts, assign them to a physical workstation or office, and grant credentials they can immediately use to log in.',
        icon: Icons.person_add_alt_1_rounded,
        gradientColors: const [Color(0xFF059669), Color(0xFF0D9488)],
        highlights: [
          '🏢 Office & Station: Assign Sham Shui Po, Kwai Chung, Sha Tin, etc.',
          '🔑 Instant Login Credentials: Password works right away upon registration.',
          '📝 Staff Categories: Support Full-Time, Part-Time, and Volunteers.',
        ],
        preview: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'New Employee Registration',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _hrDemoStaffRegistered
                          ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                          : const Color(0xFF0D9488).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _hrDemoStaffRegistered ? 'READY TO LOGIN' : 'DRAFT',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: _hrDemoStaffRegistered
                            ? const Color(0xFF15803D)
                            : const Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'FA-0205 • Michael Wong (michael.wong@foodangel.hk)\nOffice: Sham Shui Po Factory • Full Time',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hrDemoStaffRegistered
                        ? const Color(0xFF15803D)
                        : const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() =>
                        _hrDemoStaffRegistered = !_hrDemoStaffRegistered);
                  },
                  icon: Icon(
                    _hrDemoStaffRegistered
                        ? Icons.check_circle
                        : Icons.person_add_rounded,
                    size: 15,
                  ),
                  label: Text(
                    _hrDemoStaffRegistered
                        ? '✓ Account Ready (Tap to Reset)'
                        : 'Simulate Staff Registration',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // HR Step 3: Level 2 Final Leave Authorizations
      _TourStep(
        tag: 'STEP 2 • FINAL APPROVALS',
        title: 'Level 2 (Final) Leave Authorization',
        subtitle:
            'Review leaves pre-approved by supervisors and issue final authorization for payroll and quota deduction.',
        icon: Icons.verified_user_rounded,
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        highlights: [
          '🛡️ Dual Verification: Supervisor checks shift feasibility; HR validates policies.',
          '⚡ 1-Tap Final Sign-off: One tap marks leave as FULLY APPROVED.',
          '📉 Automatic Balance Sync: Employee leave balance updates automatically.',
        ],
        preview: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amy Cheung • Logistics Assistant',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _hrDemoL2Approved
                          ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                          : const Color(0xFF7C3AED).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _hrDemoL2Approved ? 'FULLY APPROVED' : 'L1 APPROVED',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: _hrDemoL2Approved
                            ? const Color(0xFF15803D)
                            : const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Sick Leave • 2 Days\n✓ Pre-approved by Supervisor David Wong',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hrDemoL2Approved
                        ? const Color(0xFF15803D)
                        : const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _hrDemoL2Approved = !_hrDemoL2Approved);
                  },
                  icon: Icon(
                    _hrDemoL2Approved ? Icons.verified : Icons.done_all_rounded,
                    size: 15,
                  ),
                  label: Text(
                    _hrDemoL2Approved
                        ? '✓ Final Signed Off (Reset)'
                        : 'Simulate Final HR Sign-off',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // HR Step 4: What You Can Do as HR Admin
      _TourStep(
        tag: 'STEP 3 • HR TOOLS',
        title: 'What You Can Do as HR Admin',
        subtitle:
            'Quick overview of HR capabilities across bottom navigation tabs.',
        icon: Icons.badge_rounded,
        gradientColors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        highlights: [
          '📊 Dashboard: Overview of pending L2 leaves & company-wide presence.',
          '📑 Leaves Tab: Filter all employee leave requests by location & status.',
          '👥 Staff Tab: Staff directory, user inspection, and registration.',
          '🧭 Quick Replay: Tap the compass 🧭 on the top bar anytime to replay.',
        ],
        preview: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabPreviewIcon(Icons.dashboard_rounded, 'Dashboard', true),
              _buildTabPreviewIcon(Icons.calendar_month_rounded, 'Leaves', true),
              _buildTabPreviewIcon(Icons.badge_rounded, 'Staff', true),
              _buildTabPreviewIcon(Icons.person_rounded, 'Profile', false),
            ],
          ),
        ),
      ),
    ];
  }

  List<_TourStep> _buildSteps() {
    final role = widget.role ?? UserRole.staff;
    if (role == UserRole.supervisor) {
      return _buildSupervisorSteps();
    } else if (role == UserRole.hrAdmin) {
      return _buildHRSteps();
    } else {
      return _buildStaffSteps();
    }
  }

  Widget _buildMiniQuotaCard({
    required String label,
    required String days,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            days,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFilterPill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF4338CA),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTeamRow({
    required String name,
    required String site,
    required String time,
    required bool isPresent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isPresent ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    site,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isPresent ? const Color(0xFF059669) : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPreviewIcon(IconData icon, String label, bool isHighlighted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isHighlighted
                ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isHighlighted
                ? const Color(0xFF0284C7)
                : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            color: isHighlighted
                ? const Color(0xFF0284C7)
                : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    final safeIndex = _currentPage.clamp(0, steps.length - 1);
    final step = steps[safeIndex];
    final isLast = safeIndex == steps.length - 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top Header bar ─────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: step.gradientColors.first.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'STEP ${safeIndex + 1} OF ${steps.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: step.gradientColors.first,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: _completeTour,
                      child: const Text(
                        'Skip Tour',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.gray500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Carousel Body ──────────────────────────────
              Flexible(
                child: SizedBox(
                  height: 385,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    itemCount: steps.length,
                    itemBuilder: (ctx, idx) {
                      final item = steps[idx];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Big animated Icon container
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: item.gradientColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: item.gradientColors.first
                                        .withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                item.icon,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Tag pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: item.gradientColors.first
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: item.gradientColors.first,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Title
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Subtitle
                            Text(
                              item.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Mini preview
                            item.preview,
                            const SizedBox(height: 12),

                            // Highlights bullets
                            Column(
                              children: item.highlights.map((h) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: item.gradientColors.first,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          h,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.gray700,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Dots Indicator ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(steps.length, (i) {
                    final isSel = i == safeIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isSel ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSel
                            ? step.gradientColors.first
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

              // ── Bottom Action Controls ─────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (safeIndex > 0) ...[
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onPressed: _previousPage,
                            child: const Text(
                              'Back',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLast
                                  ? AppTheme.primaryGreen
                                  : step.gradientColors.first,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: () => _nextPage(steps.length),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLast ? 'Get Started!' : 'Next Step',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  isLast
                                      ? Icons.check_circle_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() => _dontShowAgain = !_dontShowAgain);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 22,
                            width: 22,
                            child: Checkbox(
                              value: _dontShowAgain,
                              activeColor: AppTheme.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                setState(() => _dontShowAgain = val ?? true);
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Don't show this automatically again",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.gray500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
