package com.smarthr.attendance.domain.enums;

/**
 * Standard absence / leave reasons as specified in the project brief.
 *
 * <p>Full-time staff are tracked against these 6 categories. Each type
 * has different approval requirements and may require supporting documents.</p>
 */
public enum LeaveType {
    /** Annual leave — requires L1 + L2 approval */
    ANNUAL,

    /** Sick leave — L1 only; retrospective requires doctor note */
    SICK,

    /** Personal leave — requires L1 + L2 approval */
    PERSONAL,

    /** Maternity leave — requires L1 + L2 approval + medical certificate */
    MATERNITY,

    /** Compassionate leave — requires L1 + L2 approval */
    COMPASSIONATE,

    /** Unpaid leave — requires L1 + L2 approval */
    UNPAID
}
