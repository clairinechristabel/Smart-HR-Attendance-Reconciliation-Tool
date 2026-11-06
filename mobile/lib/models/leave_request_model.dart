// lib/models/leave_request_model.dart

class LeaveRequestModel {
  final String id;
  final String userId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final bool isRetrospective;
  final String status;
  final String? supportingDocUrl;
  final String? reason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Joined fields
  final String? userName;
  final String? userEmployeeId;
  final String? userLocation;

  // Approval info
  final List<LeaveApprovalModel>? approvals;

  const LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    this.isRetrospective = false,
    required this.status,
    this.supportingDocUrl,
    this.reason,
    required this.createdAt,
    this.updatedAt,
    this.userName,
    this.userEmployeeId,
    this.userLocation,
    this.approvals,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      leaveType: json['leave_type'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isRetrospective: json['is_retrospective'] ?? false,
      status: json['status'] ?? 'PENDING',
      supportingDocUrl: json['supporting_doc_url'],
      reason: json['reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      userName: json['users']?['full_name'] ?? json['user_name'],
      userEmployeeId: json['users']?['employee_id'] ?? json['user_employee_id'],
      userLocation: json['users']?['location'] ?? json['user_location'],
      approvals: json['leave_approvals'] != null
          ? (json['leave_approvals'] as List)
              .map((a) => LeaveApprovalModel.fromJson(a))
              .toList()
          : null,
    );
  }

  int get durationDays {
    return endDate.difference(startDate).inDays + 1;
  }

  bool get isPending => status == 'PENDING';
  bool get isL1Approved => status == 'L1_APPROVED';
  bool get isFullyApproved => status == 'FULLY_APPROVED';
  bool get isRejected => status == 'REJECTED';
  bool get isCancelled => status == 'CANCELLED';
  bool get canBeCancelled => isPending || isL1Approved;
}

class LeaveApprovalModel {
  final String id;
  final String leaveRequestId;
  final String approverId;
  final int approvalLevel;
  final String decision;
  final String? comments;
  final DateTime? decidedAt;
  final String? approverName;

  const LeaveApprovalModel({
    required this.id,
    required this.leaveRequestId,
    required this.approverId,
    required this.approvalLevel,
    required this.decision,
    this.comments,
    this.decidedAt,
    this.approverName,
  });

  factory LeaveApprovalModel.fromJson(Map<String, dynamic> json) {
    return LeaveApprovalModel(
      id: json['id']?.toString() ?? '',
      leaveRequestId: json['leave_request_id']?.toString() ?? '',
      approverId: json['approver_id']?.toString() ?? '',
      approvalLevel: json['approval_level'] ?? 1,
      decision: json['decision'] ?? 'PENDING',
      comments: json['comments'],
      decidedAt: json['decided_at'] != null
          ? DateTime.parse(json['decided_at'])
          : null,
      approverName: json['users']?['full_name'] ?? json['approver_name'],
    );
  }
}
