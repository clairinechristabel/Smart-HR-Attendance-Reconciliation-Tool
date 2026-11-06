// lib/pages/supervisor/supervisor_dashboard_page.dart
import 'package:flutter/material.dart' hide Text;
import 'package:staff_portal/core/localization/localized_text.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/leave_service.dart';
import '../../services/attendance_service.dart';
import '../../models/leave_request_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/mini_tour_modal.dart';
import '../../core/constants/app_constants.dart';

class SupervisorDashboardPage extends StatefulWidget {
  const SupervisorDashboardPage({super.key});

  @override
  State<SupervisorDashboardPage> createState() => _SupervisorDashboardPageState();
}

class _SupervisorDashboardPageState extends State<SupervisorDashboardPage> {
  final LeaveService _leaveService = LeaveService();
  final AttendanceService _attendanceService = AttendanceService();

  bool _loading = true;
  List<LeaveRequestModel> _pendingLeaves = [];
  int _teamPresentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    // Show mini tour on first open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) MiniTourModal.show(context, role: UserRole.supervisor);
      });
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      final leaves = await _leaveService.getPendingLeaves(approvalLevel: 1);
      final attendance = await _attendanceService.getTeamAttendance(
        locationIds: user.managedLocations ?? [],
        date: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _pendingLeaves = leaves;
          _teamPresentCount = attendance.where((a) => a.hasCheckedIn).length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _quickApprove(LeaveRequestModel leave) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      await _leaveService.approveL1(
        leaveId: leave.id,
        approverId: user.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request approved (L1 Approved)'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final now = DateTime.now();
    final dateStr = formatDate(context, now, 'EEEE, d MMMM yyyy');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.fullName ?? 'Supervisor'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              user?.location ?? 'Operations Hub',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr(context, 'App Mini Tour'),
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => MiniTourModal.show(context, force: true, role: UserRole.supervisor),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date banner
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Stat Row ──
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Pending Approvals',
                            value: '${_pendingLeaves.length}',
                            icon: Icons.pending_actions,
                            color: AppTheme.warning,
                            onTap: () => context.go('/supervisor/leaves'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'Team Present',
                            value: '$_teamPresentCount',
                            icon: Icons.groups,
                            color: AppTheme.info,
                            onTap: () => context.go('/supervisor/attendance'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Quick Actions ──
                    const Text(
                      'Supervisor Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppCard(
                            padding: const EdgeInsets.all(14),
                            onTap: () => context.go('/supervisor/leaves'),
                            child: const Column(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Color(0xFFEFF6FF),
                                  child: Icon(Icons.rule, color: AppTheme.info),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Review Leaves',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppCard(
                            padding: const EdgeInsets.all(14),
                            onTap: () => context.go('/supervisor/attendance'),
                            child: const Column(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Color(0xFFF0FDF4),
                                  child: Icon(Icons.how_to_reg, color: AppTheme.primaryGreen),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Team Attendance',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Urgent Action Needed ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Requires Your Approval (L1)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/supervisor/leaves'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_pendingLeaves.isEmpty)
                      AppCard(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: const [
                              Icon(Icons.check_circle_outline, size: 48, color: AppTheme.primaryGreen),
                              SizedBox(height: 8),
                              Text(
                                'All caught up!',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              Text(
                                'No pending leave requests requiring your review',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pendingLeaves.take(4).length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final item = _pendingLeaves[idx];
                          final start = formatDate(context, item.startDate, 'MMM d');
                          final end = formatDate(context, item.endDate, 'MMM d');

                          return AppCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    UserAvatar(
                                      initials: item.userName != null && item.userName!.isNotEmpty
                                          ? item.userName![0]
                                          : '?',
                                      size: 38,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.userName ?? 'Staff Member',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            '${item.leaveType} • $start - $end (${item.durationDays}d)',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(status: item.status),
                                  ],
                                ),
                                if (item.reason != null && item.reason!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '"${item.reason}"',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        minimumSize: Size.zero,
                                      ),
                                      onPressed: () => context.go('/supervisor/leaves'),
                                      child: const Text('Details'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        minimumSize: Size.zero,
                                        backgroundColor: AppTheme.primaryGreen,
                                      ),
                                      onPressed: () => _quickApprove(item),
                                      child: const Text('Approve L1'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
