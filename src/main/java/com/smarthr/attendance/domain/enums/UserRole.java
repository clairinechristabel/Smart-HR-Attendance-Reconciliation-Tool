package com.smarthr.attendance.domain.enums;

/**
 * RBAC roles for the system.
 *
 * <p>Roles are hierarchical in terms of data access but not in a strict
 * inheritance chain — each role has a distinct permission set defined
 * in the SecurityConfig.</p>
 */
public enum UserRole {
    /** Factory laborers / field staff — view own data only */
    LABORER,

    /** Kitchen/factory managers — manage team, approve L1 leaves */
    SUPERVISOR,

    /** HR power users — reconciliation, reports, user management */
    HR_ADMIN,

    /** Finance users — payroll export, medical claim reimbursement */
    FINANCE_ADMIN
}
