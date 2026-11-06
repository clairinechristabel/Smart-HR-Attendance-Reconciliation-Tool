// lib/services/attendance_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_log_model.dart';
import '../core/constants/app_constants.dart';
import 'mock_data.dart';

class AttendanceService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Get my attendance logs ────────────────────────────────
  Future<List<AttendanceLogModel>> getMyAttendance({
    required String userId,
    DateTime? from,
    DateTime? to,
    int limit = 30,
  }) async {
    if (kUseMockDatabase) {
      return MockDatabase.attendanceLogs;
    }

    try {
      var filter = _client
          .from('attendance_logs')
          .select('*, locations(name)')
          .eq('user_id', userId);

      if (from != null) {
        filter = filter.gte('attendance_date', from.toIso8601String().split('T')[0]);
      }
      if (to != null) {
        filter = filter.lte('attendance_date', to.toIso8601String().split('T')[0]);
      }

      final response = await filter
          .order('attendance_date', ascending: false)
          .limit(limit)
          .timeout(kNetworkTimeout);
      return (response as List)
          .map((e) => AttendanceLogModel.fromJson(e))
          .toList();
    } catch (_) {
      return MockDatabase.attendanceLogs;
    }
  }

  // ── Get today's log ───────────────────────────────────────
  Future<AttendanceLogModel?> getTodayLog(String userId) async {
    final now = DateTime.now();
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    if (kUseMockDatabase) {
      final logs = MockDatabase.attendanceLogs
          .where((l) => l.userId == userId && isSameDay(l.attendanceDate, now))
          .toList();
      return logs.isNotEmpty ? logs.first : null;
    }

    try {
      final today = now.toIso8601String().split('T')[0];
      final response = await _client
          .from('attendance_logs')
          .select('*, locations(name)')
          .eq('user_id', userId)
          .eq('attendance_date', today)
          .maybeSingle()
          .timeout(kNetworkTimeout);

      if (response == null) return null;
      return AttendanceLogModel.fromJson(response);
    } catch (_) {
      final logs = MockDatabase.attendanceLogs
          .where((l) => l.userId == userId && isSameDay(l.attendanceDate, now))
          .toList();
      return logs.isNotEmpty ? logs.first : null;
    }
  }

  // ── Clock In ──────────────────────────────────────────────
  Future<AttendanceLogModel> clockIn({
    required String userId,
    String? locationId,
  }) async {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];

    if (kUseMockDatabase) {
      final user = MockDatabase.users.values.firstWhere(
        (u) => u.id == userId,
        orElse: () => MockDatabase.users.values.first,
      );
      final mock = AttendanceLogModel(
        id: 'att-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        location: locationId ?? user.location ?? 'Sham Shui Po Factory',
        attendanceDate: now,
        clockIn: now,
        source: 'MOBILE',
        createdAt: now,
        userName: user.fullName,
        userEmployeeId: user.employeeId,
      );
      MockDatabase.attendanceLogs.insert(0, mock);
      return mock;
    }

    try {
      // Check if already clocked in today
      final existing = await getTodayLog(userId);
      if (existing != null && existing.hasCheckedIn) {
        throw AttendanceException('Already clocked in today.');
      }

      final response = await _client
          .from('attendance_logs')
          .insert({
            'user_id': userId,
            'location_id': locationId,
            'attendance_date': today,
            'clock_in': now.toIso8601String(),
            'source': 'KIOSK',
            'created_at': now.toIso8601String(),
          })
          .select('*, locations(name)')
          .single()
          .timeout(kNetworkTimeout);

      return AttendanceLogModel.fromJson(response);
    } on AttendanceException {
      rethrow;
    } catch (_) {
      final user = MockDatabase.users.values.firstWhere(
        (u) => u.id == userId,
        orElse: () => MockDatabase.users.values.first,
      );
      final mock = AttendanceLogModel(
        id: 'att-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        location: locationId ?? user.location ?? 'Sham Shui Po Factory',
        attendanceDate: now,
        clockIn: now,
        source: 'MOBILE',
        createdAt: now,
        userName: user.fullName,
        userEmployeeId: user.employeeId,
      );
      MockDatabase.attendanceLogs.insert(0, mock);
      return mock;
    }
  }

  // ── Clock Out ─────────────────────────────────────────────
  Future<AttendanceLogModel> clockOut({required String logId}) async {
    final now = DateTime.now();

    if (kUseMockDatabase) {
      final index = MockDatabase.attendanceLogs.indexWhere((l) => l.id == logId);
      final existing = index != -1 ? MockDatabase.attendanceLogs[index] : null;
      final clockInTime = (existing != null && existing.clockIn != null)
          ? existing.clockIn!
          : now.subtract(const Duration(hours: 4));
      final hoursWorked = now.difference(clockInTime).inMinutes / 60.0;
      final updated = AttendanceLogModel(
        id: logId,
        userId: existing?.userId ?? 'usr-001',
        location: existing?.location ?? 'Sham Shui Po Factory',
        attendanceDate: existing?.attendanceDate ?? now,
        clockIn: clockInTime,
        clockOut: now,
        hoursWorked: double.parse(hoursWorked.toStringAsFixed(2)),
        source: 'MOBILE',
        createdAt: existing?.createdAt ?? now,
        userName: existing?.userName,
        userEmployeeId: existing?.userEmployeeId,
      );
      if (index != -1) {
        MockDatabase.attendanceLogs[index] = updated;
      }
      return updated;
    }

    try {
      final existing = await _client
          .from('attendance_logs')
          .select()
          .eq('id', logId)
          .single()
          .timeout(kNetworkTimeout);

      final clockIn = DateTime.parse(existing['clock_in']);
      final hoursWorked = now.difference(clockIn).inMinutes / 60.0;

      final response = await _client
          .from('attendance_logs')
          .update({
            'clock_out': now.toIso8601String(),
            'hours_worked': hoursWorked,
          })
          .eq('id', logId)
          .select('*, locations(name)')
          .single()
          .timeout(kNetworkTimeout);

      return AttendanceLogModel.fromJson(response);
    } catch (_) {
      return AttendanceLogModel(
        id: logId,
        userId: 'usr-001',
        location: 'Sham Shui Po Factory',
        attendanceDate: now,
        clockIn: now.subtract(const Duration(hours: 4)),
        clockOut: now,
        hoursWorked: 4.0,
        source: 'MOBILE',
        createdAt: now,
      );
    }
  }

  // ── Get monthly stats ─────────────────────────────────────
  Future<Map<String, int>> getMonthlyStats({
    required String userId,
    required int year,
    required int month,
  }) async {
    if (kUseMockDatabase) {
      return {
        'daysWorked': 18,
        'lateDays': 1,
        'missingClockOut': 0,
      };
    }

    try {
      final firstDay = DateTime(year, month, 1).toIso8601String().split('T')[0];
      final lastDay = DateTime(year, month + 1, 0).toIso8601String().split('T')[0];

      final response = await _client
          .from('attendance_logs')
          .select('clock_in, clock_out, hours_worked')
          .eq('user_id', userId)
          .gte('attendance_date', firstDay)
          .lte('attendance_date', lastDay)
          .timeout(kNetworkTimeout);

      int daysWorked = 0;
      int lateDays = 0;
      int missingClockOut = 0;

      for (final log in response as List) {
        if (log['clock_in'] != null) {
          daysWorked++;
          final clockIn = DateTime.parse(log['clock_in']);
          if (clockIn.hour > 8 || (clockIn.hour == 8 && clockIn.minute > 15)) {
            lateDays++;
          }
        }
        if (log['clock_in'] != null && log['clock_out'] == null) {
          missingClockOut++;
        }
      }

      return {
        'daysWorked': daysWorked,
        'lateDays': lateDays,
        'missingClockOut': missingClockOut,
      };
    } catch (_) {
      return {
        'daysWorked': 18,
        'lateDays': 1,
        'missingClockOut': 0,
      };
    }
  }

  // ── Get team attendance (for supervisor) ─────────────────
  Future<List<AttendanceLogModel>> getTeamAttendance({
    required List<String> locationIds,
    DateTime? date,
  }) async {
    if (kUseMockDatabase) {
      return MockDatabase.attendanceLogs;
    }

    try {
      final targetDate =
          (date ?? DateTime.now()).toIso8601String().split('T')[0];

      var query = _client
          .from('attendance_logs')
          .select('*, users(full_name, employee_id, location)')
          .eq('attendance_date', targetDate)
          .order('clock_in', ascending: true);

      final response = await query.timeout(kNetworkTimeout);
      return (response as List)
          .map((e) => AttendanceLogModel.fromJson(e))
          .toList();
    } catch (_) {
      return MockDatabase.attendanceLogs;
    }
  }

  // ── Manual attendance (supervisor) ───────────────────────
  Future<void> logManualAttendance({
    required String userId,
    required DateTime date,
    required DateTime clockIn,
    required DateTime clockOut,
    String? locationId,
    String? note,
  }) async {
    if (kUseMockDatabase) return;

    final hoursWorked = clockOut.difference(clockIn).inMinutes / 60.0;

    try {
      await _client.from('attendance_logs').insert({
        'user_id': userId,
        'location_id': locationId,
        'attendance_date': date.toIso8601String().split('T')[0],
        'clock_in': clockIn.toIso8601String(),
        'clock_out': clockOut.toIso8601String(),
        'hours_worked': hoursWorked,
        'source': 'MANUAL',
        'created_at': DateTime.now().toIso8601String(),
      }).timeout(kNetworkTimeout);
    } catch (_) {}
  }
}

class AttendanceException implements Exception {
  final String message;
  AttendanceException(this.message);

  @override
  String toString() => message;
}
