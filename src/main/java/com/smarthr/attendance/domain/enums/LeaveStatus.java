package com.smarthr.attendance.domain.enums;

/**
 * Leave request lifecycle status.
 *
 * <p>Models the multi-level approval flow:</p>
 * <pre>
 * PENDING → L1_APPROVED → FULLY_APPROVED
 *    ↓           ↓
 * REJECTED    REJECTED
 *    ↓
 * CANCELLED (by requester)
 * </pre>
 *
 * <p>Only {@code FULLY_APPROVED} leaves are considered by the
 * Reconciliation Engine when checking for excused absences.</p>
 */
public enum LeaveStatus {
    /** Initial state — awaiting supervisor approval */
    PENDING,

    /** Supervisor (Level 1) has approved; awaiting HR Admin (Level 2) if required */
    L1_APPROVED,

    /** All required approval levels completed — leave is active */
    FULLY_APPROVED,

    /** Rejected at any approval level */
    REJECTED,

    /** Cancelled by the requester before full approval */
    CANCELLED
}
