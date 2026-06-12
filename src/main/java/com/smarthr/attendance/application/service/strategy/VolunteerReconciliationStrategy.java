package com.smarthr.attendance.application.service.strategy;

import com.smarthr.attendance.application.dto.ParsedAttendanceRecord;
import com.smarthr.attendance.domain.entity.LeaveRequest;
import com.smarthr.attendance.domain.entity.ReconciliationDiscrepancy;
import com.smarthr.attendance.domain.entity.ReconciliationRun;
import com.smarthr.attendance.domain.entity.User;
import com.smarthr.attendance.domain.enums.DiscrepancyType;
import com.smarthr.attendance.domain.enums.StaffType;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Reconciliation strategy for <b>Volunteers</b>.
 *
 * <h3>Business Rules</h3>
 * <p>Volunteers (100+ daily, changing locations) have the most relaxed
 * attendance rules. The primary concern is <b>presence verification</b>
 * — did the volunteer show up at their assigned location?</p>
 *
 * <h3>Key Differences from Full-Time/Part-Time</h3>
 * <ul>
 *   <li>No strict shift start/end times — no late arrival or early departure checks</li>
 *   <li>Presence is binary: either they showed up or they didn't</li>
 *   <li>Location verification is important — volunteers are assigned to specific
 *       sites daily, and showing up at the wrong site is flagged</li>
 * </ul>
 *
 * <h3>Checks Performed</h3>
 * <ol>
 *   <li><b>Presence Check</b> — Was there any clock-in at all?</li>
 *   <li><b>Location Mismatch</b> — Does the recorded location match the
 *       expected assignment? (Requires volunteer_assignments table lookup,
 *       simplified here for PoC)</li>
 * </ol>
 */
@Component
public class VolunteerReconciliationStrategy implements ReconciliationStrategy {

    @Override
    public StaffType getSupportedStaffType() {
        return StaffType.VOLUNTEER;
    }

    @Override
    public List<ReconciliationDiscrepancy> reconcile(
            ReconciliationRun run,
            User user,
            ParsedAttendanceRecord record,
            List<LeaveRequest> approvedLeaves) {

        List<ReconciliationDiscrepancy> discrepancies = new ArrayList<>();
        LocalDate date = record.getAttendanceDate();

        // ── Check 1: Basic presence verification ─────────────────
        // Volunteers don't have traditional leave — if they don't show up,
        // it's simply recorded as an absence for tracking purposes.
        if (record.getClockIn() == null) {
            discrepancies.add(buildDiscrepancy(
                    run, user, date,
                    DiscrepancyType.UNEXCUSED_ABSENCE,
                    null, null, 0,
                    "Volunteer did not clock in at any location on this date."
            ));
            return discrepancies;
        }

        // ── Check 2: Location mismatch detection ─────────────────
        // In a full implementation, this would query the volunteer_assignments
        // table to check if the recorded location matches the assigned location.
        // For the PoC, we check if the location name from the Excel matches
        // the user's primary location.
        if (record.getLocationName() != null && user.getPrimaryLocation() != null) {
            String expectedLocation = user.getPrimaryLocation().getName();
            if (!record.getLocationName().equalsIgnoreCase(expectedLocation)) {
                discrepancies.add(buildDiscrepancy(
                        run, user, date,
                        DiscrepancyType.LOCATION_MISMATCH,
                        null, null, 0,
                        String.format(
                                "Volunteer clocked in at '%s' but was assigned to '%s'. "
                                + "Please verify with the site supervisor.",
                                record.getLocationName(), expectedLocation)
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
