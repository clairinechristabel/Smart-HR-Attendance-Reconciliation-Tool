// lib/pages/hr/hr_dashboard_page.dart
import 'package:flutter/material.dart' hide Text;
import 'package:staff_portal/core/localization/localized_text.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/leave_service.dart';
import '../../models/leave_request_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/mini_tour_modal.dart';
import '../../core/constants/app_constants.dart';
import 'hr_register_staff_page.dart';

class HRDashboardPage extends StatefulWidget {
  const HRDashboardPage({super.key});

  @override
  State<HRDashboardPage> createState() => _HRDashboardPageState();
}

class _HRDashboardPageState extends State<HRDashboardPage> {
  final LeaveService _leaveService = LeaveService();

  bool _loading = true;
  List<LeaveRequestModel> _pendingL2Leaves = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    // Show mini tour on first open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) MiniTourModal.show(context, role: UserRole.hrAdmin);
      });
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // HR needs to approve L1_APPROVED leaves (L2 approval)
      final leaves = await _leaveService.getPendingLeaves(approvalLevel: 2);

      if (mounted) {
        setState(() {
          _pendingL2Leaves = leaves;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _quickApproveL2(LeaveRequestModel leave) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      await _leaveService.approveL2(
        leaveId: leave.id,
        approverId: user.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave fully approved (L2 Approved)'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
              'HR Operations Portal',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              user?.fullName ?? 'HR Administrator',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr(context, 'App Mini Tour'),
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => MiniTourModal.show(context, force: true, role: UserRole.hrAdmin),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header banner
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 16, color: AppTheme.purple),
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

                    // ── Stat Cards ──
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: tr(context, 'L2 Final Approvals'),
                            value: '${_pendingL2Leaves.length}',
                            icon: Icons.done_all,
                            color: AppTheme.purple,
                            onTap: () => context.go('/hr/leaves'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: tr(context, 'Staff Directory'),
                            value: tr(context, 'Manage'),
                            icon: Icons.people_outline,
                            color: AppTheme.info,
                            onTap: () => context.go('/hr/users'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Management Shortcuts ──
                    Text(
                      tr(context, 'Management Consoles'),
                      style: const TextStyle(
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
                            onTap: () => context.go('/hr/leaves'),
                            child: Column(
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Color(0xFFF3E8FF),
                                  child: Icon(Icons.event_available, color: AppTheme.purple),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tr(context, 'Leave Console'),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
                            onTap: () => context.go('/hr/users'),
                            child: Column(
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Color(0xFFEFF6FF),
                                  child: Icon(Icons.people_outline, color: AppTheme.info),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tr(context, 'Staff Directory'),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HRRegisterStaffPage(),
                              ),
                            ),
                            child: Column(
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Color(0xFFF0FDF4),
                                  child: Icon(Icons.person_add_outlined, color: AppTheme.primaryGreen),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tr(context, 'Register Staff'),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── L2 Pending Approvals ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Awaiting HR L2 Approval',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/hr/leaves'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_pendingL2Leaves.isEmpty)
                      AppCard(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: const [
                              Icon(Icons.check_circle_outline, size: 48, color: AppTheme.purple),
                              SizedBox(height: 8),
                              Text(
                                'No pending L2 approvals',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              Text(
                                'All leaves endorsed by supervisors are processed',
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
                        itemCount: _pendingL2Leaves.take(4).length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final item = _pendingL2Leaves[idx];
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
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        minimumSize: Size.zero,
                                      ),
                                      onPressed: () => context.go('/hr/leaves'),
                                      child: const Text('Review'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        minimumSize: Size.zero,
                                        backgroundColor: AppTheme.purple,
                                      ),
                                      onPressed: () => _quickApproveL2(item),
                                      child: const Text('Approve L2'),
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
