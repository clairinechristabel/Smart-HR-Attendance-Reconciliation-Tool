package com.smarthr.attendance.application.dto;

import com.smarthr.attendance.domain.entity.User;

public class AuthResponse {
    private boolean success;
    private String message;
    private User user;
    private String token; // For future JWT integration

    public AuthResponse(boolean success, String message, User user, String token) {
        this.success = success;
        this.message = message;
        this.user = user;
        this.token = token;
    }

    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }
}
