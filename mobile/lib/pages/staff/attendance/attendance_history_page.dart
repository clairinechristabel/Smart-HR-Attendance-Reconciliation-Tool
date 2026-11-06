// lib/pages/staff/attendance/attendance_history_page.dart
import 'package:flutter/material.dart' hide Text;
import 'package:staff_portal/core/localization/localized_text.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/attendance_service.dart';
import '../../../models/attendance_log_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_card.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  final _service = AttendanceService();
  List<AttendanceLogModel> _logs = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final userId = context.read<AuthProvider>().user!.id;
    setState(() => _isLoading = true);

    try {
      final from = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final to = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      final logs = await _service.getMyAttendance(
        userId: userId,
        from: from,
        to: to,
        limit: 50,
      );
      if (mounted) setState(() { _logs = logs; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
          _selectedMonth.year, _selectedMonth.month + delta);
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = formatDate(context, _selectedMonth, 'MMMM yyyy');

    // Summary
    final totalDays = _logs.length;
    final workedDays =
        _logs.where((l) => l.hasCheckedIn).length;
    final totalHours = _logs.fold<double>(
        0, (sum, l) => sum + (l.hoursWorked ?? 0));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: Column(
        children: [
          // ── Month Selector ─────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  monthLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedMonth.month >= DateTime.now().month &&
                          _selectedMonth.year >= DateTime.now().year
                      ? null
                      : () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // ── Summary Strip ──────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primaryGreen.withOpacity(0.05),
            child: Row(
              children: [
                _summaryChip(
                    '$workedDays', 'Days Present', AppTheme.success),
                const SizedBox(width: 12),
                _summaryChip(
                    '${(totalDays - workedDays)}', 'Days Absent', AppTheme.error),
                const SizedBox(width: 12),
                _summaryChip(
                    totalHours.toStringAsFixed(1), 'Hours', AppTheme.info),
              ],
            ),
          ),

          // ── Log List ───────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy,
                                size: 64, color: AppTheme.gray300),
                            const SizedBox(height: 12),
                            const Text('No attendance records',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        color: AppTheme.primaryGreen,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _logs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _buildLogCard(context, _logs[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, AttendanceLogModel log) {
    final isPresent = log.hasCheckedIn;
    final isLate = log.clockIn != null &&
        (log.clockIn!.hour > 8 ||
            (log.clockIn!.hour == 8 && log.clockIn!.minute > 15));

    Color statusColor = isPresent
        ? (isLate ? AppTheme.warning : AppTheme.success)
        : AppTheme.error;
    String statusLabel =
        isPresent ? (isLate ? 'Late' : 'Present') : 'Absent';

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPresent ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDate(context, log.attendanceDate, 'EEE, d MMM'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${log.formattedClockIn} → ${log.formattedClockOut}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (log.hoursWorked != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${log.formattedHoursWorked})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                if (log.location != null)
                  Text(
                    log.location!,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
