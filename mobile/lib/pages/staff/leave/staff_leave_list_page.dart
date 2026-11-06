// lib/pages/staff/leave/staff_leave_list_page.dart
import 'package:flutter/material.dart' hide Text;
import 'package:staff_portal/core/localization/localized_text.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/leave_service.dart';
import '../../../models/leave_request_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/status_badge.dart';

class StaffLeaveListPage extends StatefulWidget {
  const StaffLeaveListPage({super.key});

  @override
  State<StaffLeaveListPage> createState() => _StaffLeaveListPageState();
}

class _StaffLeaveListPageState extends State<StaffLeaveListPage>
    with SingleTickerProviderStateMixin {
  final _leaveService = LeaveService();
  List<LeaveRequestModel> _leaves = [];
  bool _isLoading = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadLeaves();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLeaves() async {
    final userId = context.read<AuthProvider>().user!.id;
    try {
      final leaves = await _leaveService.getMyLeaves(userId: userId);
      if (mounted) setState(() { _leaves = leaves; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LeaveRequestModel> _filteredLeaves(String? statusFilter) {
    if (statusFilter == null) return _leaves;
    return _leaves.where((l) => l.status == statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Leave Requests'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.gray500,
          indicatorColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildLeaveList(null),
          _buildLeaveList('PENDING'),
          _buildLeaveList('FULLY_APPROVED'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/staff/leave/submit'),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Request Leave',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLeaveList(String? status) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final leaves = _filteredLeaves(status);

    if (leaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 64, color: AppTheme.gray300),
            const SizedBox(height: 16),
            const Text('No leave requests found',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaves,
      color: AppTheme.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: leaves.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildLeaveCard(leaves[i]),
      ),
    );
  }

  Widget _buildLeaveCard(LeaveRequestModel leave) {
    final typeName =
        LeaveType.labels[leave.leaveType] ?? leave.leaveType;
    final statusLabel = _statusLabel(leave.status);
    final df = DateFormat('d MMM yyyy');

    return AppCard(
      onTap: () => context.go('/staff/leave/${leave.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(typeName,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              StatusBadge(status: leave.status, label: statusLabel),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                '${df.format(leave.startDate)} → ${df.format(leave.endDate)}',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${leave.durationDays} day${leave.durationDays > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (leave.reason != null && leave.reason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              leave.reason!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'L1_APPROVED':
        return 'Supervisor Approved';
      case 'FULLY_APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
