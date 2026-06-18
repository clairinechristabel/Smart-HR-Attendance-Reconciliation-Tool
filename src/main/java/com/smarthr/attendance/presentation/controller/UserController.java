package com.smarthr.attendance.presentation.controller;

import com.smarthr.attendance.domain.entity.User;
import com.smarthr.attendance.domain.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/users")
@CrossOrigin(origins = "*") // For local dev PoC
public class UserController {

    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/pending")
    public ResponseEntity<List<User>> getPendingUsers() {
        List<User> pendingUsers = userRepository.findByActiveFalse();
        // Securely remove password hash before returning
        pendingUsers.forEach(u -> u.setPasswordHash(null));
        return ResponseEntity.ok(pendingUsers);
    }
}
