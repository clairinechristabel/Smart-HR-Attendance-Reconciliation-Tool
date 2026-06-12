package com.smarthr.attendance.application.service.strategy;

import com.smarthr.attendance.application.dto.ParsedAttendanceRecord;
import com.smarthr.attendance.domain.entity.LeaveRequest;
import com.smarthr.attendance.domain.entity.ReconciliationDiscrepancy;
import com.smarthr.attendance.domain.entity.ReconciliationRun;
import com.smarthr.attendance.domain.entity.User;
import com.smarthr.attendance.domain.enums.StaffType;

import java.util.List;

/**
 * Strategy interface for staff-type-specific reconciliation logic.
 *
 * <h3>Design Pattern: Strategy (GoF)</h3>
 * <p>Each staff type (Full-Time, Part-Time, Volunteer) has fundamentally
 * different attendance rules. Instead of a monolithic {@code if/else} chain
 * in the service layer, each rule set is encapsulated in its own strategy.</p>
 *
 * <h3>SOLID: Open/Closed Principle</h3>
 * <p>New staff types (e.g., Contractors, Interns) can be added by simply
 * creating a new implementation of this interface and annotating it with
 * {@code @Component}. The core {@code ReconciliationService} requires
 * zero modifications — it auto-discovers strategies via Spring DI.</p>
 *
 * <h3>SOLID: Liskov Substitution Principle</h3>
 * <p>All implementations are interchangeable — the service dispatches
 * to the correct strategy based on the user's staff type, and each
 * strategy returns the same output type (List of discrepancies).</p>
 */
public interface ReconciliationStrategy {

    /**
     * Returns the staff type this strategy handles.
     * Used by {@code ReconciliationService} to build a dispatch map.
     *
     * @return the supported staff type
     */
    StaffType getSupportedStaffType();

    /**
     * Reconcile a single attendance record against the user's expected
     * schedule and approved leaves.
     *
     * @param run           the parent reconciliation run (for FK reference)
     * @param user          the employee being checked
     * @param record        the parsed attendance data from the Excel file
     * @param approvedLeaves list of FULLY_APPROVED leaves for this user in the period
     * @return list of discrepancies found (empty list if everything is clean)
     */
    List<ReconciliationDiscrepancy> reconcile(
            ReconciliationRun run,
            User user,
            ParsedAttendanceRecord record,
            List<LeaveRequest> approvedLeaves);
}
