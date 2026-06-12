package com.smarthr.attendance.application.service.strategy;

import com.smarthr.attendance.application.dto.ParsedAttendanceRecord;
import com.smarthr.attendance.domain.entity.LeaveRequest;
import com.smarthr.attendance.domain.entity.ReconciliationDiscrepancy;
import com.smarthr.attendance.domain.entity.ReconciliationRun;
import com.smarthr.attendance.domain.entity.User;
import com.smarthr.attendance.domain.enums.DiscrepancyType;
import com.smarthr.attendance.domain.enums.StaffType;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Reconciliation strategy for <b>Full-Time</b> staff.
 *
 * <h3>Business Rules</h3>
 * <p>Full-time employees have the strictest attendance requirements.
 * They are expected to clock in and out at their scheduled shift times,
 * with a configurable grace period for minor delays.</p>
 *
 * <h3>Checks Performed (in order)</h3>
 * <ol>
 *   <li><b>Approved Leave Check</b> — Is this date covered by a FULLY_APPROVED leave?
 *       If yes, the absence is excused and no further checks are needed.</li>
 *   <li><b>Unexcused Absence</b> — No clock-in AND no approved leave = flagged.</li>
 *   <li><b>Late Arrival</b> — Clock-in time exceeds shift start + grace period.</li>
 *   <li><b>Missing Clock-Out</b> — Clock-in exists but no clock-out recorded.</li>
 *   <li><b>Early Departure</b> — Clock-out time precedes shift end - grace period.</li>
 * </ol>
 *
 * <h3>Configuration</h3>
 * <p>Grace periods are externalized to {@code application.yml}:</p>
 * <pre>
 * app.reconciliation.late-arrival-grace-minutes: 15
 * app.reconciliation.early-departure-grace-minutes: 15
 * </pre>
 */
@Component
public class FullTimeReconciliationStrategy implements ReconciliationStrategy {

    /** Minutes after shift start before a late arrival is flagged */
    private final int lateArrivalGraceMinutes;

    /** Minutes before shift end before an early departure is flagged */
    private final int earlyDepartureGraceMinutes;

    /**
     * Constructor with externalized configuration.
     * Spring injects values from application.yml via @Value.
     */
    public FullTimeReconciliationStrategy(
            @Value("${app.reconciliation.late-arrival-grace-minutes:15}") int lateArrivalGraceMinutes,
            @Value("${app.reconciliation.early-departure-grace-minutes:15}") int earlyDepartureGraceMinutes) {
        this.lateArrivalGraceMinutes = lateArrivalGraceMinutes;
        this.earlyDepartureGraceMinutes = earlyDepartureGraceMinutes;
    }

    @Override
    public StaffType getSupportedStaffType() {
        return StaffType.FULL_TIME;
    }

    /**
     * Reconcile a single full-time employee's attendance record.
     *
     * <p>The method follows a fail-fast approach: if the employee is on
     * approved leave, we return immediately with no discrepancies. Otherwise,
     * we check each rule sequentially and collect all violations.</p>
     *
     * @param run            the parent reconciliation run
     * @param user           the full-time employee being checked
     * @param record         parsed clock-in/out data from the Excel file
     * @param approvedLeaves all FULLY_APPROVED leaves for this user in the period
     * @return list of discrepancies (may be empty if attendance is clean)
     */
    @Override
    public List<ReconciliationDiscrepancy> reconcile(
            ReconciliationRun run,
            User user,
            ParsedAttendanceRecord record,
            List<LeaveRequest> approvedLeaves) {

        List<ReconciliationDiscrepancy> discrepancies = new ArrayList<>();
        LocalDate date = record.getAttendanceDate();

        // ──────────────────────────────────────────────────────────
        // CHECK 1: Is this date covered by an approved leave?
        // ──────────────────────────────────────────────────────────
        // If the employee has a FULLY_APPROVED leave that covers this date,
        // their absence is excused — no discrepancy should be raised.
        boolean isOnApprovedLeave = approvedLeaves.stream()
                .anyMatch(leave -> leave.coversDate(date));

        // ──────────────────────────────────────────────────────────
        // CHECK 2: Was there a clock-in?
        // ──────────────────────────────────────────────────────────
        if (record.getClockIn() == null) {
            if (!isOnApprovedLeave) {
                // NO clock-in + NO approved leave = UNEXCUSED ABSENCE
                // This is the most critical discrepancy type — it directly
                // affects payroll and requires HR action.
                discrepancies.add(buildDiscrepancy(
                        run, user, date,
                        DiscrepancyType.UNEXCUSED_ABSENCE,
                        shiftStartAsDateTime(user, date),  // expected time
                        null,                               // no actual time (absent)
                        0,                                  // no variance calculable
                        "No clock-in recorded and no approved leave found for this date."
                ));
            }
            // If on approved leave and no clock-in, that's expected — return empty
            return discrepancies;
        }

        // ──────────────────────────────────────────────────────────
        // CHECK 3: Late arrival detection
        // ──────────────────────────────────────────────────────────
        // Compare actual clock-in time against the employee's scheduled
        // shift start plus the grace period.
        LocalTime shiftStart = user.getDefaultShiftStart();
        if (shiftStart != null) {
            LocalTime clockInTime = record.getClockIn().toLocalTime();
            LocalTime graceDeadline = shiftStart.plusMinutes(lateArrivalGraceMinutes);

            if (clockInTime.isAfter(graceDeadline)) {
                int varianceMinutes = (int) Duration.between(shiftStart, clockInTime).toMinutes();
                discrepancies.add(buildDiscrepancy(
                        run, user, date,
                        DiscrepancyType.LATE_ARRIVAL,
                        shiftStartAsDateTime(user, date),
                        record.getClockIn(),
                        varianceMinutes,
                        String.format(
                                "Clocked in at %s, which is %d minutes after the scheduled "
                                + "shift start of %s (grace period: %d min).",
                                clockInTime, varianceMinutes, shiftStart, lateArrivalGraceMinutes)
                ));
            }
        }

        // ──────────────────────────────────────────────────────────
        // CHECK 4: Missing clock-out
        // ──────────────────────────────────────────────────────────
        // A missing clock-out is a data integrity issue that prevents
        // accurate hours calculation. It needs manual correction.
        if (record.getClockOut() == null) {
            discrepancies.add(buildDiscrepancy(
                    run, user, date,
                    DiscrepancyType.MISSING_CLOCK_OUT,
                    shiftEndAsDateTime(user, date),
                    null,  // no actual clock-out
                    0,
                    "Clock-in recorded at " + record.getClockIn().toLocalTime()
                    + " but no clock-out was found. Manual correction required for payroll."
            ));
            // Return early — cannot check early departure without clock-out
            return discrepancies;
        }

        // ──────────────────────────────────────────────────────────
        // CHECK 5: Early departure detection
        // ──────────────────────────────────────────────────────────
        // Compare actual clock-out against the employee's scheduled
        // shift end minus the grace period.
        LocalTime shiftEnd = user.getDefaultShiftEnd();
        if (shiftEnd != null) {
            LocalTime clockOutTime = record.getClockOut().toLocalTime();
            LocalTime earlyDeadline = shiftEnd.minusMinutes(earlyDepartureGraceMinutes);

            if (clockOutTime.isBefore(earlyDeadline)) {
                int varianceMinutes = (int) Duration.between(clockOutTime, shiftEnd).toMinutes();
                discrepancies.add(buildDiscrepancy(
                        run, user, date,
                        DiscrepancyType.EARLY_DEPARTURE,
                        shiftEndAsDateTime(user, date),
                        record.getClockOut(),
                        varianceMinutes,
                        String.format(
                                "Clocked out at %s, which is %d minutes before the scheduled "
                                + "shift end of %s (grace period: %d min).",
                                clockOutTime, varianceMinutes, shiftEnd, earlyDepartureGraceMinutes)
                ));
            }
        }

        return discrepancies;
    }

    // ═══════════════════════════════════════════════════════════════
    //  HELPER METHODS
    // ═══════════════════════════════════════════════════════════════

    /**
     * Build a fully-populated ReconciliationDiscrepancy entity.
     * Centralizes construction to maintain consistency and reduce duplication.
     */
    private ReconciliationDiscrepancy buildDiscrepancy(
            ReconciliationRun run, User user, LocalDate date,
            DiscrepancyType type,
            java.time.LocalDateTime expectedTime,
            java.time.LocalDateTime actualTime,
            int varianceMinutes, String details) {

        ReconciliationDiscrepancy d = new ReconciliationDiscrepancy();
        d.setRun(run);
        d.setUser(user);
        d.setDiscrepancyDate(date);
        d.setDiscrepancyType(type);
        d.setExpectedTime(expectedTime);
        d.setActualTime(actualTime);
        d.setVarianceMinutes(varianceMinutes);
        d.setDetails(details);
        return d;
    }

    /** Convert a user's default shift start time to a LocalDateTime on the given date */
    private java.time.LocalDateTime shiftStartAsDateTime(User user, LocalDate date) {
        return user.getDefaultShiftStart() != null
                ? user.getDefaultShiftStart().atDate(date)
                : null;
    }

    /** Convert a user's default shift end time to a LocalDateTime on the given date */
    private java.time.LocalDateTime shiftEndAsDateTime(User user, LocalDate date) {
        return user.getDefaultShiftEnd() != null
                ? user.getDefaultShiftEnd().atDate(date)
                : null;
    }
}
