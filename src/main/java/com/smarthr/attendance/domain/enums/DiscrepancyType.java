package com.smarthr.attendance.domain.enums;

/**
 * Types of discrepancies detected by the Reconciliation Engine.
 *
 * <p>Each type corresponds to a specific business rule violation
 * identified during the cross-referencing of clock-in logs against
 * leave records and shift schedules.</p>
 */
public enum DiscrepancyType {
    /** No clock-in recorded and no approved leave for the date */
    UNEXCUSED_ABSENCE,

    /** Clock-in time exceeds shift start + grace period */
    LATE_ARRIVAL,

    /** Clock-out time precedes shift end - grace period */
    EARLY_DEPARTURE,

    /** Clock-in recorded but no clock-out — possible data error */
    MISSING_CLOCK_OUT,

    /** Part-time: actual hours deviate significantly from contracted hours */
    HOURS_MISMATCH,

    /** Volunteer: clocked in at a different location than assigned */
    LOCATION_MISMATCH
}
