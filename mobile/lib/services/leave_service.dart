// lib/services/leave_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leave_request_model.dart';
import '../core/constants/app_constants.dart';
import 'mock_data.dart';

class LeaveService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Get my leave requests ─────────────────────────────────
  Future<List<LeaveRequestModel>> getMyLeaves({
    required String userId,
    String? status,
    int limit = 20,
  }) async {
    if (kUseMockDatabase) {
      if (status != null) {
        return MockDatabase.leaveRequests.where((l) => l.status == status).toList();
      }
      return MockDatabase.leaveRequests;
    }

    try {
      var filter = _client
          .from('leave_requests')
          .select('*, leave_approvals(*, users(full_name))')
          .eq('user_id', userId);

      if (status != null) {
        filter = filter.eq('status', status);
      }

      final response = await filter
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(kNetworkTimeout);
      return (response as List)
          .map((e) => LeaveRequestModel.fromJson(e))
          .toList();
    } catch (_) {
      if (status != null) {
        return MockDatabase.leaveRequests.where((l) => l.status == status).toList();
      }
      return MockDatabase.leaveRequests;
    }
  }

  // ── Get all pending leaves (supervisor/HR) ────────────────
  Future<List<LeaveRequestModel>> getPendingLeaves({
    String? locationFilter,
    int? approvalLevel,
    int limit = 50,
  }) async {
    if (kUseMockDatabase) {
      if (approvalLevel == 1) {
        return MockDatabase.leaveRequests.where((l) => l.status == 'PENDING').toList();
      } else if (approvalLevel == 2) {
        return MockDatabase.leaveRequests.where((l) => l.status == 'L1_APPROVED').toList();
      }
      return MockDatabase.leaveRequests
          .where((l) => l.status == 'PENDING' || l.status == 'L1_APPROVED')
          .toList();
    }

    try {
      var filter = _client
          .from('leave_requests')
          .select(
              '*, users(full_name, employee_id, location, role), leave_approvals(*, users(full_name))');

      if (approvalLevel == 1) {
        filter = filter.eq('status', 'PENDING');
      } else if (approvalLevel == 2) {
        filter = filter.eq('status', 'L1_APPROVED');
      } else {
        filter = filter.inFilter('status', ['PENDING', 'L1_APPROVED']);
      }

      final response = await filter
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(kNetworkTimeout);
      return (response as List)
          .map((e) => LeaveRequestModel.fromJson(e))
          .toList();
    } catch (_) {
      if (approvalLevel == 1) {
        return MockDatabase.leaveRequests.where((l) => l.status == 'PENDING').toList();
      } else if (approvalLevel == 2) {
        return MockDatabase.leaveRequests.where((l) => l.status == 'L1_APPROVED').toList();
      }
      return MockDatabase.leaveRequests;
    }
  }

  // ── Get all leaves (HR Admin) ─────────────────────────────
  Future<List<LeaveRequestModel>> getAllLeaves({
    String? status,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) async {
    if (kUseMockDatabase) {
      if (status != null) {
        return MockDatabase.leaveRequests.where((l) => l.status == status).toList();
      }
      return MockDatabase.leaveRequests;
    }

    try {
      var filter = _client
          .from('leave_requests')
          .select('*, users(full_name, employee_id, location)');

      if (status != null) filter = filter.eq('status', status);
      if (from != null) {
        filter =
            filter.gte('created_at', from.toIso8601String().split('T')[0]);
      }
      if (to != null) {
        filter = filter.lte('created_at', to.toIso8601String().split('T')[0]);
      }

      final response = await filter
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(kNetworkTimeout);
      return (response as List)
          .map((e) => LeaveRequestModel.fromJson(e))
          .toList();
    } catch (_) {
      if (status != null) {
        return MockDatabase.leaveRequests.where((l) => l.status == status).toList();
      }
      return MockDatabase.leaveRequests;
    }
  }

  // ── Submit leave request ──────────────────────────────────
  Future<LeaveRequestModel> submitLeave({
    required String userId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    bool isRetrospective = false,
    String? reason,
    String? supportingDocUrl,
  }) async {
    if (kUseMockDatabase) {
      final mock = LeaveRequestModel(
        id: 'lv-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        status: 'PENDING',
        reason: reason,
        createdAt: DateTime.now(),
        userName: 'Lisa Chan',
        userEmployeeId: 'FA-0142',
        userLocation: 'Sham Shui Po Factory',
      );
      MockDatabase.leaveRequests.insert(0, mock);
      return mock;
    }

    try {
      final response = await _client
          .from('leave_requests')
          .insert({
            'user_id': userId,
            'leave_type': leaveType,
            'start_date': startDate.toIso8601String().split('T')[0],
            'end_date': endDate.toIso8601String().split('T')[0],
            'is_retrospective': isRetrospective,
            'status': 'PENDING',
            'reason': reason,
            'supporting_doc_url': supportingDocUrl,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('*, users(full_name, employee_id, location)')
          .single()
          .timeout(kNetworkTimeout);

      return LeaveRequestModel.fromJson(response);
    } catch (_) {
      final mock = LeaveRequestModel(
        id: 'lv-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        status: 'PENDING',
        reason: reason,
        createdAt: DateTime.now(),
        userName: 'Lisa Chan',
        userEmployeeId: 'FA-0142',
        userLocation: 'Sham Shui Po Factory',
      );
      MockDatabase.leaveRequests.insert(0, mock);
      return mock;
    }
  }

  // ── Approve leave (L1 or L2) ──────────────────────────────
  Future<void> approveL1({
    required String leaveId,
    required String approverId,
    String? comments,
    bool needsL2 = false,
  }) async {
    final newStatus = needsL2 ? 'L1_APPROVED' : 'FULLY_APPROVED';
    await _updateApproval(
      leaveId: leaveId,
      approverId: approverId,
      approvalLevel: 1,
      newStatus: newStatus,
      comments: comments,
    );
  }

  Future<void> approveL2({
    required String leaveId,
    required String approverId,
    String? comments,
  }) async {
    await _updateApproval(
      leaveId: leaveId,
      approverId: approverId,
      approvalLevel: 2,
      newStatus: 'FULLY_APPROVED',
      comments: comments,
    );
  }

  Future<void> _updateApproval({
    required String leaveId,
    required String approverId,
    required int approvalLevel,
    required String newStatus,
    String? comments,
  }) async {
    if (kUseMockDatabase) {
      final index = MockDatabase.leaveRequests.indexWhere((l) => l.id == leaveId);
      if (index != -1) {
        final old = MockDatabase.leaveRequests[index];
        MockDatabase.leaveRequests[index] = LeaveRequestModel(
          id: old.id,
          userId: old.userId,
          leaveType: old.leaveType,
          startDate: old.startDate,
          endDate: old.endDate,
          status: newStatus,
          reason: old.reason,
          createdAt: old.createdAt,
          userName: old.userName,
          userEmployeeId: old.userEmployeeId,
          userLocation: old.userLocation,
        );
      }
      return;
    }

    try {
      await _client.from('leave_approvals').insert({
        'leave_request_id': leaveId,
        'approver_id': approverId,
        'approval_level': approvalLevel,
        'decision': 'APPROVED',
        'comments': comments,
        'decided_at': DateTime.now().toIso8601String(),
      }).timeout(kNetworkTimeout);

      await _client
          .from('leave_requests')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', leaveId)
          .timeout(kNetworkTimeout);
    } catch (_) {
      final index = MockDatabase.leaveRequests.indexWhere((l) => l.id == leaveId);
      if (index != -1) {
        final old = MockDatabase.leaveRequests[index];
        MockDatabase.leaveRequests[index] = LeaveRequestModel(
          id: old.id,
          userId: old.userId,
          leaveType: old.leaveType,
          startDate: old.startDate,
          endDate: old.endDate,
          status: newStatus,
          reason: old.reason,
          createdAt: old.createdAt,
          userName: old.userName,
          userEmployeeId: old.userEmployeeId,
          userLocation: old.userLocation,
        );
      }
    }
  }

  // ── Reject leave ──────────────────────────────────────────
  Future<void> rejectLeave({
    required String leaveId,
    required String approverId,
    required int approvalLevel,
    String? comments,
  }) async {
    if (kUseMockDatabase) {
      final index = MockDatabase.leaveRequests.indexWhere((l) => l.id == leaveId);
      if (index != -1) {
        final old = MockDatabase.leaveRequests[index];
        MockDatabase.leaveRequests[index] = LeaveRequestModel(
          id: old.id,
          userId: old.userId,
          leaveType: old.leaveType,
          startDate: old.startDate,
          endDate: old.endDate,
          status: 'REJECTED',
          reason: old.reason,
          createdAt: old.createdAt,
          userName: old.userName,
          userEmployeeId: old.userEmployeeId,
          userLocation: old.userLocation,
        );
      }
      return;
    }

    try {
      await _client.from('leave_approvals').insert({
        'leave_request_id': leaveId,
        'approver_id': approverId,
        'approval_level': approvalLevel,
        'decision': 'REJECTED',
        'comments': comments,
        'decided_at': DateTime.now().toIso8601String(),
      }).timeout(kNetworkTimeout);

      await _client
          .from('leave_requests')
          .update({
            'status': 'REJECTED',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', leaveId)
          .timeout(kNetworkTimeout);
    } catch (_) {
      final index = MockDatabase.leaveRequests.indexWhere((l) => l.id == leaveId);
      if (index != -1) {
        final old = MockDatabase.leaveRequests[index];
        MockDatabase.leaveRequests[index] = LeaveRequestModel(
          id: old.id,
          userId: old.userId,
          leaveType: old.leaveType,
          startDate: old.startDate,
          endDate: old.endDate,
          status: 'REJECTED',
          reason: old.reason,
          createdAt: old.createdAt,
          userName: old.userName,
          userEmployeeId: old.userEmployeeId,
          userLocation: old.userLocation,
        );
      }
    }
  }

  // ── Cancel leave (by applicant) ───────────────────────────
  Future<void> cancelLeave(String leaveId) async {
    if (kUseMockDatabase) {
      final index = MockDatabase.leaveRequests.indexWhere((l) => l.id == leaveId);
      if (index != -1) {
        final old = MockDatabase.leaveRequests[index];
        MockDatabase.leaveRequests[index] = LeaveRequestModel(
          id: old.id,
          userId: old.userId,
          leaveType: old.leaveType,
          startDate: old.startDate,
          endDate: old.endDate,
          status: 'CANCELLED',
          reason: old.reason,
          createdAt: old.createdAt,
          userName: old.userName,
          userEmployeeId: old.userEmployeeId,
          userLocation: old.userLocation,
        );
      }
      return;
    }

    try {
      await _client
          .from('leave_requests')
          .update({
            'status': 'CANCELLED',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', leaveId)
          .timeout(kNetworkTimeout);
    } catch (_) {
      final index = MockDatabase.leaveRequests.indexWhere((l) => l.id == leaveId);
      if (index != -1) {
        final old = MockDatabase.leaveRequests[index];
        MockDatabase.leaveRequests[index] = LeaveRequestModel(
          id: old.id,
          userId: old.userId,
          leaveType: old.leaveType,
          startDate: old.startDate,
          endDate: old.endDate,
          status: 'CANCELLED',
          reason: old.reason,
          createdAt: old.createdAt,
          userName: old.userName,
          userEmployeeId: old.userEmployeeId,
          userLocation: old.userLocation,
        );
      }
    }
  }

  // ── Get leave balances ────────────────────────────────────
  Future<Map<String, int>> getLeaveBalances({
    required String userId,
    required int year,
  }) async {
    if (kUseMockDatabase) {
      return {
        'annual_used': 3,
        'annual_total': 14,
        'sick_used': 2,
        'sick_total': 14,
        'personal_used': 1,
        'personal_total': 3,
      };
    }

    final yearStart = '$year-01-01';
    final yearEnd = '$year-12-31';

    try {
      final response = await _client
          .from('leave_requests')
          .select('leave_type, start_date, end_date, status')
          .eq('user_id', userId)
          .inFilter('status', ['FULLY_APPROVED', 'L1_APPROVED'])
          .gte('start_date', yearStart)
          .lte('end_date', yearEnd)
          .timeout(kNetworkTimeout);

      final Map<String, int> used = {};
      for (final req in response as List) {
        final type = req['leave_type'] as String;
        final start = DateTime.parse(req['start_date']);
        final end = DateTime.parse(req['end_date']);
        final days = end.difference(start).inDays + 1;
        used[type] = (used[type] ?? 0) + days;
      }

      return {
        'annual_used': used['ANNUAL'] ?? 0,
        'annual_total': 14,
        'sick_used': used['SICK'] ?? 0,
        'sick_total': 14,
        'personal_used': used['PERSONAL'] ?? 0,
        'personal_total': 3,
      };
    } catch (_) {
      return {
        'annual_used': 3,
        'annual_total': 14,
        'sick_used': 2,
        'sick_total': 14,
        'personal_used': 1,
        'personal_total': 3,
      };
    }
  }
}
