package com.smarthr.attendance.domain.enums;

/**
 * Leave type codes as specified by Food Angel's HR policy.
 *
 * <p>Each type maps to an official code used in the IMS system
 * and has different approval requirements and entitlements.</p>
 */
public enum LeaveType {
    /** AL — Annual leave (per company policy). Requires L1 + L2 approval. */
    ANNUAL,

    /** BL — Birthday leave (1 day). */
    BIRTHDAY,

    /** CPL — Compensation leave (per company policy). */
    COMPENSATION,

    /** CL — Compassionate leave (per company policy). Requires L1 + L2 approval. */
    COMPASSIONATE,

    /** SL — Full pay sick leave (per company policy). L1 only; retrospective requires doctor note. */
    SICK,

    /** NSL — No pay sick leave (per company policy). */
    NO_PAY_SICK,

    /** SLA — 4/5 Sick leave allowance (per labour ordinance). */
    SICK_ALLOWANCE,

    /** NPL — No pay leave (per company policy). Requires L1 + L2 approval. */
    UNPAID,

    /** M — Marriage leave (3 days). */
    MARRIAGE,

    /** MML — Maternity leave (per labour ordinance). Requires L1 + L2 + medical certificate. */
    MATERNITY,

    /** PL — Paternity leave (per labour ordinance). */
    PATERNITY,

    /** WFH — Work from home (2 days/month, SSP office staff only). */
    WFH,

    /** PER — Personal leave. Requires L1 + L2 approval. */
    PERSONAL
}
