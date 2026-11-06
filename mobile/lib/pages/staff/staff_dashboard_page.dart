// lib/pages/staff/staff_dashboard_page.dart
import 'package:flutter/material.dart' hide Text;
import 'package:staff_portal/core/localization/localized_text.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../services/leave_service.dart';
import '../../models/attendance_log_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/mini_tour_modal.dart';
import '../../core/constants/app_constants.dart';

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  final _attendanceService = AttendanceService();
  final _leaveService = LeaveService();

  AttendanceLogModel? _todayLog;
  Map<String, int> _monthlyStats = {};
  Map<String, int> _leaveBalances = {};
  bool _isLoading = true;
  bool _isClockingIn = false;

  // Live timer
  final _now = ValueNotifier<DateTime>(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();

    // Update clock every second
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      _now.value = DateTime.now();
      return true;
    });

    // Check if mini tour should be displayed on first run
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) MiniTourModal.show(context, role: UserRole.staff);
      });
    });
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user!;
    final now = DateTime.now();

    try {
      final results = await Future.wait([
        _attendanceService.getTodayLog(user.id),
        _attendanceService.getMonthlyStats(
            userId: user.id, year: now.year, month: now.month),
        _leaveService.getLeaveBalances(userId: user.id, year: now.year),
      ]);

      if (mounted) {
        setState(() {
          _todayLog = results[0] as AttendanceLogModel?;
          _monthlyStats = results[1] as Map<String, int>;
          _leaveBalances = results[2] as Map<String, int>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleClockIn() async {
    // Navigate to barcode scan page for clock-in
    if (mounted) {
      context.go('/staff/checkin');
    }
  }

  Future<void> _handleClockOut() async {
    // Navigate to barcode scan page for clock-out
    if (mounted) {
      context.go('/staff/checkin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final greeting = _getGreeting();
    final dateStr = formatDate(context, DateTime.now(), 'EEEE, d MMMM yyyy');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── Hero AppBar ────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              collapsedHeight: 60,
              pinned: true,
              elevation: 0,
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/images/foodangellogo.png',
                      height: 20,
                      width: 20,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.restaurant,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Food Angel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: tr(context, 'App Mini Tour'),
                  icon: const Icon(Icons.explore_outlined, color: Colors.white),
                  onPressed: () => MiniTourModal.show(context, force: true, role: UserRole.staff),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 8, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    greeting,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.fullName.split(' ').first,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              UserAvatar(
                                initials: user.initials,
                                role: user.role,
                                size: 52,
                                backgroundColor: Colors.white.withValues(alpha: 0.25),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Body Content ───────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Check-In Card ─────────────────
                  _buildCheckInCard(),
                  const SizedBox(height: 20),

                  // ── Monthly Stats ─────────────────
                  const Text(
                    'This Month',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMonthlyStats(),
                  const SizedBox(height: 20),

                  // ── Leave Balance ─────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Leave Balance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/staff/leave'),
                        child: const Text('Manage →'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildLeaveBalances(),
                  const SizedBox(height: 20),

                  // ── Quick Actions ─────────────────
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInCard() {
    if (_isLoading) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
            child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final hasCheckedIn = _todayLog?.hasCheckedIn ?? false;
    final hasCheckedOut = _todayLog?.hasCheckedOut ?? false;
    final isComplete = hasCheckedIn && hasCheckedOut;

    return GradientCard(
      gradient: isComplete
          ? const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : AppTheme.primaryGradient,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isComplete
                        ? 'Work Complete 🎉'
                        : hasCheckedIn
                            ? 'Currently Working'
                            : 'Not Checked In',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ValueListenableBuilder<DateTime>(
                    valueListenable: _now,
                    builder: (_, now, __) {
                      return Text(
                        hasCheckedIn && !hasCheckedOut
                            ? _elapsedTime(_todayLog!.clockIn!)
                            : DateFormat('HH:mm').format(now),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      );
                    },
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isComplete
                      ? Icons.check_circle
                      : hasCheckedIn
                          ? Icons.timer
                          : Icons.fingerprint,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (hasCheckedIn)
                _timeChip(
                    'IN', _todayLog!.formattedClockIn, AppTheme.success),
              if (hasCheckedIn) const SizedBox(width: 8),
              if (hasCheckedOut)
                _timeChip(
                    'OUT', _todayLog!.formattedClockOut, AppTheme.warning),
              const Spacer(),
              if (!isComplete)
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _isClockingIn
                        ? null
                        : hasCheckedIn
                            ? _handleClockOut
                            : _handleClockIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _isClockingIn
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryGreen))
                        : Text(
                            hasCheckedIn ? 'Clock Out' : 'Clock In',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeChip(String label, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Days Worked',
            value: '${_monthlyStats['daysWorked'] ?? 0}',
            icon: Icons.calendar_today,
            color: AppTheme.success,
            subtitle: 'this month',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Late Days',
            value: '${_monthlyStats['lateDays'] ?? 0}',
            icon: Icons.watch_later_outlined,
            color: AppTheme.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Missing Out',
            value: '${_monthlyStats['missingClockOut'] ?? 0}',
            icon: Icons.warning_amber_rounded,
            color: AppTheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveBalances() {
    final annual = _leaveBalances['annual_used'] ?? 0;
    final annualTotal = _leaveBalances['annual_total'] ?? 14;
    final sick = _leaveBalances['sick_used'] ?? 0;
    final sickTotal = _leaveBalances['sick_total'] ?? 14;
    final personal = _leaveBalances['personal_used'] ?? 0;
    final personalTotal = _leaveBalances['personal_total'] ?? 3;

    return AppCard(
      child: Column(
        children: [
          _leaveBalanceRow('Annual Leave', annual, annualTotal, AppTheme.info),
          const SizedBox(height: 12),
          _leaveBalanceRow(
              'Sick Leave', sick, sickTotal, AppTheme.primaryGreen),
          const SizedBox(height: 12),
          _leaveBalanceRow(
              'Personal Leave', personal, personalTotal, AppTheme.purple),
        ],
      ),
    );
  }

  Widget _leaveBalanceRow(
      String label, int used, int total, Color color) {
    final remaining = total - used;
    final pct = total > 0 ? used / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary)),
            Text(
              '$remaining days left',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: remaining > 0 ? color : AppTheme.error),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$used used of $total',
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _Action('Scan\nCheck-In', Icons.qr_code_scanner,
          AppTheme.primaryGreen, '/staff/checkin'),
      _Action('Request\nLeave', Icons.calendar_today_outlined,
          AppTheme.info, '/staff/leave/submit'),
      _Action('My\nLeaves', Icons.calendar_month_outlined,
          AppTheme.purple, '/staff/leave'),
      _Action('Attendance\nHistory', Icons.access_time_outlined,
          AppTheme.orange, '/staff/attendance'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: actions
          .map((a) => _buildQuickAction(context, a))
          .toList(),
    );
  }

  Widget _buildQuickAction(BuildContext context, _Action action) {
    return InkWell(
      onTap: () => context.go(action.route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.gray200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _elapsedTime(DateTime clockIn) {
    final elapsed = DateTime.now().difference(clockIn);
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _Action {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  _Action(this.label, this.icon, this.color, this.route);
}
