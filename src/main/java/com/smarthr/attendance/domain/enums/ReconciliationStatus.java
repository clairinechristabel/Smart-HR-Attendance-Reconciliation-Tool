package com.smarthr.attendance.domain.enums;

/**
 * Reconciliation run execution status.
 */
public enum ReconciliationStatus {
    /** Run is currently in progress */
    PROCESSING,

    /** Run completed successfully — discrepancies are available */
    COMPLETED,

    /** Run failed due to an error (e.g., corrupt file, DB issue) */
    FAILED
}
