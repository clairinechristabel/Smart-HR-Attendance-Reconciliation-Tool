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

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Reconciliation strategy for <b>Part-Time</b> staff.
 *
 * <h3>Business Rules</h3>
 * <p>Part-time staff are primarily tracked by <b>hours worked</b> rather than
 * strict shift adherence. The key concern for payroll is whether the actual
 * hours match the contracted daily hours.</p>
 *
 * <h3>Checks Performed</h3>
 * <ol>
 *   <li><b>Approved Leave Check</b> — Same as full-time.</li>
 *   <li><b>Missing Clock-Out</b> — Prevents hours calculation; flagged immediately.</li>
 *   <li><b>Hours Mismatch</b> — If actual hours deviate from contracted hours
 *       by more than the configured threshold (default: 0.5 hours / 30 min),
 *       a discrepancy is raised.</li>
 * </ol>
 */
@Component
public class PartTimeReconciliationStrategy implements ReconciliationStrategy {

    /** Maximum acceptable deviation in hours before flagging a mismatch */
    private final double hoursVarianceThreshold;

    public PartTimeReconciliationStrategy(
            @Value("${app.reconciliation.hours-variance-threshold:0.5}") double hoursVarianceThreshold) {
        this.hoursVarianceThreshold = hoursVarianceThreshold;
    }

    @Override
    public StaffType getSupportedStaffType() {
        return StaffType.PART_TIME;
    }

    @Override
    public List<ReconciliationDiscrepancy> reconcile(
            ReconciliationRun run,
            User user,
            ParsedAttendanceRecord record,
            List<LeaveRequest> approvedLeaves) {

        List<ReconciliationDiscrepancy> discrepancies = new ArrayList<>();
        LocalDate date = record.getAttendanceDate();

        // ── Check 1: Approved leave ──────────────────────────────
        boolean isOnApprovedLeave = approvedLeaves.stream()
                .anyMatch(leave -> leave.coversDate(date));

        if (record.getClockIn() == null) {
            if (!isOnApprovedLeave) {
                discrepancies.add(buildDiscrepancy(
                        run, user, date,
                        DiscrepancyType.UNEXCUSED_ABSENCE,
                        null, null, 0,
                        "Part-time employee: no clock-in recorded and no approved leave."
                ));
            }
            return discrepancies;
        }

        // ── Check 2: Missing clock-out ───────────────────────────
        if (record.getClockOut() == null) {
            discrepancies.add(buildDiscrepancy(
                    run, user, date,
                    DiscrepancyType.MISSING_CLOCK_OUT,
                    null, null, 0,
                    "Clock-in at " + record.getClockIn().toLocalTime()
                    + " but no clock-out. Cannot calculate hours for payroll."
            ));
            return discrepancies;
        }

        // ── Check 3: Hours mismatch ─────────────────────────────
        // Calculate actual hours worked from clock-in/out
        double actualHours = Duration.between(record.getClockIn(), record.getClockOut())
                .toMinutes() / 60.0;

        BigDecimal contractedHours = user.getContractedHoursPerDay();
        if (contractedHours != null) {
            double variance = Math.abs(actualHours - contractedHours.doubleValue());

            if (variance > hoursVarianceThreshold) {
                int varianceMinutes = (int) (variance * 60);
                String direction = actualHours < contractedHours.doubleValue()
                        ? "under" : "over";

                discrepancies.add(buildDiscrepancy(
                        run, user, date,
                        DiscrepancyType.HOURS_MISMATCH,
                        null, null, varianceMinutes,
                        String.format(
                                "Part-time hours mismatch: worked %.1f hours, contracted %.1f hours "
                                + "(%.1f hours %s, threshold: %.1f hours).",
                                actualHours, contractedHours.doubleValue(),
                                variance, direction, hoursVarianceThreshold)
                ));
            }
        }

        return discrepancies;
    }

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
}
