package com.smarthr.attendance.application.dto;

import com.smarthr.attendance.domain.enums.UserRole;

public class AuthRequest {
    private String fullName;
    private String email;
    private String password;
    private UserRole role; // Expected: STAFF or HR_ADMIN

    public AuthRequest() {}

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public UserRole getRole() { return role; }
    public void setRole(UserRole role) { this.role = role; }
}
