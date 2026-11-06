// lib/pages/hr/hr_leave_management_page.dart
import 'package:flutter/material.dart' hide Text;
import 'package:staff_portal/core/localization/localized_text.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/leave_service.dart';
import '../../models/leave_request_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';

class HRLeaveManagementPage extends StatefulWidget {
  const HRLeaveManagementPage({super.key});

  @override
  State<HRLeaveManagementPage> createState() => _HRLeaveManagementPageState();
}

class _HRLeaveManagementPageState extends State<HRLeaveManagementPage>
    with SingleTickerProviderStateMixin {
  final LeaveService _leaveService = LeaveService();
  late TabController _tabController;

  bool _loading = true;
  List<LeaveRequestModel> _allLeaves = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeaves();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaves() async {
    setState(() => _loading = true);
    try {
      final leaves = await _leaveService.getAllLeaves(limit: 100);
      if (mounted) {
        setState(() {
          _allLeaves = leaves;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleDecision(LeaveRequestModel leave, bool approve) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final commentController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Final Approve (L2)' : 'Reject Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applicant: ${leave.userName ?? 'Staff'}\n'
              'Type: ${leave.leaveType} (${leave.durationDays} days)\n'
              'Status: ${leave.status}',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: tr(context, 'HR Remarks (Optional)'),
                hintText: tr(context, 'Add HR notes or conditions'),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? AppTheme.purple : AppTheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(approve ? 'Grant Final Approval' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (approve) {
        await _leaveService.approveL2(
          leaveId: leave.id,
          approverId: user.id,
          comments: commentController.text.trim().isNotEmpty
              ? commentController.text.trim()
              : null,
        );
      } else {
        await _leaveService.rejectLeave(
          leaveId: leave.id,
          approverId: user.id,
          approvalLevel: 2,
          comments: commentController.text.trim().isNotEmpty
              ? commentController.text.trim()
              : 'Rejected by HR Admin',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? 'Leave request fully approved'
                : 'Leave request rejected'),
            backgroundColor: approve ? AppTheme.primaryGreen : AppTheme.error,
          ),
        );
        _loadLeaves();
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Leave Management Console'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.purple,
          unselectedLabelColor: AppTheme.gray500,
          indicatorColor: AppTheme.purple,
          tabs: const [
            Tab(text: 'Awaiting L2'),
            Tab(text: 'Approved'),
            Tab(text: 'All Records'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_allLeaves.where((l) => l.isL1Approved).toList()),
                _buildList(_allLeaves.where((l) => l.isFullyApproved).toList()),
                _buildList(_allLeaves),
              ],
            ),
    );
  }

  Widget _buildList(List<LeaveRequestModel> items) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadLeaves,
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: AppTheme.gray400),
                  SizedBox(height: 8),
                  Text(
                    'No leave requests in this category',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaves,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final leave = items[index];
          final start = DateFormat('yyyy-MM-dd').format(leave.startDate);
          final end = DateFormat('yyyy-MM-dd').format(leave.endDate);

          return AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      initials: leave.userName != null && leave.userName!.isNotEmpty
                          ? leave.userName![0]
                          : '?',
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.userName ?? 'Employee',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          Text(
                            '${leave.userEmployeeId ?? ''} • ${leave.userLocation ?? 'Hong Kong'}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: leave.status),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      leave.leaveType,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      '${leave.durationDays} day${leave.durationDays > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: $start to $end',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                if (leave.reason != null && leave.reason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.gray50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.gray200),
                    ),
                    child: Text(
                      'Reason: ${leave.reason}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
                if (leave.isL1Approved) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        onPressed: () => _handleDecision(leave, false),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.purple,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Grant Final (L2)'),
                        onPressed: () => _handleDecision(leave, true),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
