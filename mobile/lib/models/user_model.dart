// lib/models/user_model.dart

class UserModel {
  final String id;
  final String employeeId;
  final String fullName;
  final String email;
  final String? phone;
  final String staffType;
  final String role;
  final String? primaryLocationId;
  final String? location;
  final String? department;
  final String? position;
  final String? joinDate;
  final List<String>? managedLocations;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.staffType,
    required this.role,
    this.primaryLocationId,
    this.location,
    this.department,
    this.position,
    this.joinDate,
    this.managedLocations,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id'] ?? json['employeeId'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      staffType: json['staff_type'] ?? json['staffType'] ?? 'FULL_TIME',
      role: json['role'] ?? 'STAFF',
      primaryLocationId: json['primary_location_id'],
      location: json['location'],
      department: json['department'],
      position: json['position'],
      joinDate: json['join_date'] ?? json['joinDate'],
      managedLocations: json['managed_locations'] != null
          ? List<String>.from(json['managed_locations'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'staff_type': staffType,
        'role': role,
        'location': location,
        'department': department,
        'position': position,
        'join_date': joinDate,
        'managed_locations': managedLocations,
        'is_active': isActive,
      };

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  bool get isStaff => role == 'STAFF' || role == 'LABORER';
  bool get isSupervisor => role == 'SUPERVISOR';
  bool get isHRAdmin => role == 'HR_ADMIN';
  bool get isFinanceAdmin => role == 'FINANCE_ADMIN';
  bool get canApproveLeave => isSupervisor || isHRAdmin;
  bool get canViewAllStaff => isSupervisor || isHRAdmin || isFinanceAdmin;

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? position,
    String? department,
    String? location,
  }) {
    return UserModel(
      id: id,
      employeeId: employeeId,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      staffType: staffType,
      role: role,
      primaryLocationId: primaryLocationId,
      location: location ?? this.location,
      department: department ?? this.department,
      position: position ?? this.position,
      joinDate: joinDate,
      managedLocations: managedLocations,
      isActive: isActive,
    );
  }
}
