package com.smarthr.attendance.domain.enums;

/**
 * Classification of employee types.
 *
 * <p>Each staff type has fundamentally different attendance rules,
 * which the Reconciliation Engine handles via the Strategy Pattern.</p>
 *
 * <ul>
 *   <li><b>FULL_TIME</b> — Strict shift-based tracking against 6 absence reasons</li>
 *   <li><b>PART_TIME</b> — Hours-based tracking for payroll calculation</li>
 *   <li><b>VOLUNTEER</b> — Presence verification across changing locations (100+ daily)</li>
 * </ul>
 */
public enum StaffType {
    FULL_TIME,
    PART_TIME,
    VOLUNTEER
}
