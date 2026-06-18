package com.smarthr.attendance.application.dto;

import com.smarthr.attendance.domain.enums.StaffType;
import com.smarthr.attendance.domain.enums.UserRole;
import java.util.UUID;

public class ApprovalRequest {
    private StaffType staffType;
    private UUID locationId;
    private UserRole role;

    public StaffType getStaffType() {
        return staffType;
    }

    public void setStaffType(StaffType staffType) {
        this.staffType = staffType;
    }

    public UUID getLocationId() {
        return locationId;
    }

    public void setLocationId(UUID locationId) {
        this.locationId = locationId;
    }

    public UserRole getRole() {
        return role;
    }

    public void setRole(UserRole role) {
        this.role = role;
    }
}
