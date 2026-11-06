// lib/models/attendance_log_model.dart

class AttendanceLogModel {
  final String id;
  final String userId;
  final String? locationId;
  final String? location;
  final DateTime attendanceDate;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final double? hoursWorked;
  final String source;
  final DateTime createdAt;

  // Joined
  final String? userName;
  final String? userEmployeeId;

  const AttendanceLogModel({
    required this.id,
    required this.userId,
    this.locationId,
    this.location,
    required this.attendanceDate,
    this.clockIn,
    this.clockOut,
    this.hoursWorked,
    this.source = 'MANUAL',
    required this.createdAt,
    this.userName,
    this.userEmployeeId,
  });

  factory AttendanceLogModel.fromJson(Map<String, dynamic> json) {
    return AttendanceLogModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      locationId: json['location_id']?.toString(),
      location: json['locations']?['name'] ?? json['location'],
      attendanceDate: DateTime.parse(json['attendance_date']),
      clockIn: json['clock_in'] != null ? DateTime.parse(json['clock_in']) : null,
      clockOut: json['clock_out'] != null ? DateTime.parse(json['clock_out']) : null,
      hoursWorked: json['hours_worked']?.toDouble(),
      source: json['source'] ?? 'MANUAL',
      createdAt: DateTime.parse(json['created_at']),
      userName: json['users']?['full_name'],
      userEmployeeId: json['users']?['employee_id'],
    );
  }

  bool get hasCheckedIn => clockIn != null;
  bool get hasCheckedOut => clockOut != null;
  bool get isComplete => hasCheckedIn && hasCheckedOut;

  String get formattedClockIn {
    if (clockIn == null) return '--:--';
    return '${clockIn!.hour.toString().padLeft(2, '0')}:${clockIn!.minute.toString().padLeft(2, '0')}';
  }

  String get formattedClockOut {
    if (clockOut == null) return '--:--';
    return '${clockOut!.hour.toString().padLeft(2, '0')}:${clockOut!.minute.toString().padLeft(2, '0')}';
  }

  String get formattedHoursWorked {
    if (hoursWorked == null) return '--';
    final hours = hoursWorked!.floor();
    final minutes = ((hoursWorked! - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }
}
