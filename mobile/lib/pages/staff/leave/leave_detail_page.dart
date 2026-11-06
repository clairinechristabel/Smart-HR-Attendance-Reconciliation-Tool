// lib/pages/staff/leave/leave_detail_page.dart
import 'package:flutter/material.dart' hide Text;
import 'package:staff_portal/core/localization/localized_text.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/leave_service.dart';
import '../../../models/leave_request_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/app_card.dart';

class LeaveDetailPage extends StatefulWidget {
  final String leaveId;
  const LeaveDetailPage({super.key, required this.leaveId});

  @override
  State<LeaveDetailPage> createState() => _LeaveDetailPageState();
}

class _LeaveDetailPageState extends State<LeaveDetailPage> {
  final _leaveService = LeaveService();
  LeaveRequestModel? _leave;
  bool _isLoading = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadLeave();
  }

  Future<void> _loadLeave() async {
    final userId = context.read<AuthProvider>().user!.id;
    try {
      final leaves = await _leaveService.getMyLeaves(userId: userId);
      final leave = leaves.firstWhere(
        (l) => l.id == widget.leaveId,
        orElse: () => throw Exception('Leave not found'),
      );
      if (mounted) setState(() { _leave = leave; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Leave Request?'),
        content: const Text(
            'Are you sure you want to cancel this leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isCancelling = true);

    try {
      await _leaveService.cancelLeave(widget.leaveId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request cancelled'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_leave == null) {
      return const Scaffold(
        body: Center(child: Text('Leave request not found')),
      );
    }

    final leave = _leave!;
    final df = DateFormat('EEE, d MMM yyyy');
    final typeName = LeaveType.labels[leave.leaveType] ?? leave.leaveType;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Leave Details'),
        actions: [
          if (leave.canBeCancelled)
            TextButton(
              onPressed: _isCancelling ? null : _cancelLeave,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status Banner ──────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.leaveStatusColor(leave.status).withOpacity(0.15),
                  AppTheme.leaveStatusColor(leave.status).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.leaveStatusColor(leave.status)
                      .withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  _statusIcon(leave.status),
                  size: 32,
                  color: AppTheme.leaveStatusColor(leave.status),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _statusText(leave.status),
                        style: TextStyle(
                          color: AppTheme.leaveStatusColor(leave.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Details ────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Leave Details',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _detailRow(Icons.calendar_today_outlined, 'Start Date',
                    df.format(leave.startDate)),
                const Divider(height: 20),
                _detailRow(Icons.event_available_outlined, 'End Date',
                    df.format(leave.endDate)),
                const Divider(height: 20),
                _detailRow(Icons.date_range_outlined, 'Duration',
                    '${leave.durationDays} day${leave.durationDays > 1 ? 's' : ''}'),
                const Divider(height: 20),
                _detailRow(
                  Icons.history_outlined,
                  'Type',
                  leave.isRetrospective ? 'Retrospective' : 'Pre-approved',
                ),
                if (leave.reason != null && leave.reason!.isNotEmpty) ...[
                  const Divider(height: 20),
                  _detailRow(Icons.notes_outlined, 'Reason', leave.reason!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Approval Chain ─────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Approval Chain',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _approvalStep(1, 'Supervisor', leave),
                const SizedBox(height: 12),
                _approvalStep(2, 'HR Admin', leave),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Timestamps ─────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Timeline',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _detailRow(Icons.schedule_outlined, 'Submitted',
                    DateFormat('d MMM yyyy, HH:mm').format(leave.createdAt)),
                if (leave.updatedAt != null) ...[
                  const Divider(height: 20),
                  _detailRow(Icons.update_outlined, 'Last Updated',
                      DateFormat('d MMM yyyy, HH:mm').format(leave.updatedAt!)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _approvalStep(int level, String title, LeaveRequestModel leave) {
    final approval = leave.approvals?.firstWhere(
      (a) => a.approvalLevel == level,
      orElse: () => LeaveApprovalModel(
          id: '', leaveRequestId: '', approverId: '',
          approvalLevel: level, decision: 'PENDING'),
    );

    final isPending = approval?.decision == 'PENDING' || approval == null;
    final isApproved = approval?.decision == 'APPROVED';
    final color = isApproved
        ? AppTheme.success
        : approval?.decision == 'REJECTED'
            ? AppTheme.error
            : AppTheme.gray400;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              isApproved
                  ? Icons.check
                  : isPending
                      ? Icons.hourglass_empty
                      : Icons.close,
              size: 16,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Level $level — $title',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              if (!isPending && approval.id.isNotEmpty)
                Text(
                  '${approval.approverName ?? 'Unknown'} · ${approval.decidedAt != null ? DateFormat('d MMM HH:mm').format(approval.decidedAt!) : ''}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted),
                ),
            ],
          ),
        ),
        Text(
          isPending ? 'Pending' : (isApproved ? 'Approved' : 'Rejected'),
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'FULLY_APPROVED':
        return Icons.check_circle;
      case 'L1_APPROVED':
        return Icons.pending;
      case 'REJECTED':
        return Icons.cancel;
      case 'CANCELLED':
        return Icons.remove_circle;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'FULLY_APPROVED':
        return 'Fully Approved';
      case 'L1_APPROVED':
        return 'Supervisor Approved — Awaiting HR';
      case 'REJECTED':
        return 'Rejected';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return 'Pending Approval';
    }
  }
}
