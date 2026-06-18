package com.smarthr.attendance.presentation.controller;

import com.smarthr.attendance.application.dto.AuthRequest;
import com.smarthr.attendance.application.dto.AuthResponse;
import com.smarthr.attendance.application.service.AuthService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/auth")
@CrossOrigin(origins = "*") // For local dev PoC
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@RequestBody AuthRequest request) {
        AuthResponse response = authService.register(request);
        if (response.isSuccess()) {
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.badRequest().body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody AuthRequest request) {
        AuthResponse response = authService.login(request.getEmail(), request.getPassword());
        if (response.isSuccess()) {
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.status(401).body(response);
    }

    @PutMapping("/approve/{userId}")
    public ResponseEntity<AuthResponse> approveUser(
            @PathVariable UUID userId,
            @RequestBody(required = false) com.smarthr.attendance.application.dto.ApprovalRequest request) {
        AuthResponse response = authService.approveUser(userId, request);
        if (response.isSuccess()) {
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.badRequest().body(response);
    }

    @DeleteMapping("/reject/{userId}")
    public ResponseEntity<AuthResponse> rejectUser(@PathVariable UUID userId) {
        AuthResponse response = authService.rejectRegistration(userId);
        if (response.isSuccess()) {
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.badRequest().body(response);
    }
}
