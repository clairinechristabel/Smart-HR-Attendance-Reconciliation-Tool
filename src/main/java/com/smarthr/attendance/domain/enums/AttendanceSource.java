package com.smarthr.attendance.domain.enums;

/**
 * Source of attendance data capture.
 *
 * <p>Tracks how attendance data entered the system, critical for
 * audit trail and data quality assessment.</p>
 */
public enum AttendanceSource {
    /** Physical punch-card system at factory */
    PUNCH_CARD,

    /** Instant messaging (IM) log data */
    IM_LOG,

    /** Physical kiosk interface at work site */
    KIOSK,

    /** Manual entry by a supervisor on behalf of a laborer */
    MANUAL
}
