package com.smarthr.attendance.application.service;

import com.smarthr.attendance.application.dto.ApprovalRequest;
import com.smarthr.attendance.application.dto.AuthRequest;
import com.smarthr.attendance.application.dto.AuthResponse;
import com.smarthr.attendance.domain.entity.Location;
import com.smarthr.attendance.domain.entity.User;
import com.smarthr.attendance.domain.enums.StaffType;
import com.smarthr.attendance.domain.enums.UserRole;
import com.smarthr.attendance.domain.repository.LocationRepository;
import com.smarthr.attendance.domain.repository.UserRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

@Service
@Transactional
public class AuthService {

    private final UserRepository userRepository;
    private final LocationRepository locationRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthService(UserRepository userRepository, LocationRepository locationRepository) {
        this.userRepository = userRepository;
        this.locationRepository = locationRepository;
        this.passwordEncoder = new BCryptPasswordEncoder();
    }

    public AuthResponse register(AuthRequest request) {
        // Check if email already exists
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            return new AuthResponse(false, "Email already registered", null, null);
        }

        User user = new User();
        user.setEmail(request.getEmail());
        user.setFullName(request.getFullName());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setRole(request.getRole());
        user.setStaffType(StaffType.FULL_TIME); // Default for online registration
        
        // Generate a random employee ID for simplicity
        user.setEmployeeId("EMP-" + (int)(Math.random() * 90000 + 10000));

        // All self-registered users require HR Admin approval
        user.setActive(false);

        userRepository.save(user);

        return new AuthResponse(true, "Registration successful. Pending admin approval.", user, null);
    }

    public AuthResponse login(String email, String password) {
        Optional<User> optionalUser = userRepository.findByEmail(email);

        if (optionalUser.isEmpty()) {
            return new AuthResponse(false, "Invalid email or password", null, null);
        }

        User user = optionalUser.get();

        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            return new AuthResponse(false, "Invalid email or password", null, null);
        }

        if (!user.isActive()) {
            return new AuthResponse(false, "Account pending admin approval", null, null);
        }

        // Dummy token for PoC
        String dummyToken = UUID.randomUUID().toString();
        
        return new AuthResponse(true, "Login successful", user, dummyToken);
    }

    public AuthResponse approveUser(UUID userId, ApprovalRequest request) {
        Optional<User> optionalUser = userRepository.findById(userId);
        if (optionalUser.isEmpty()) {
            return new AuthResponse(false, "User not found", null, null);
        }
        
        User user = optionalUser.get();
        user.setActive(true);
        
        if (request != null) {
            if (request.getStaffType() != null) {
                user.setStaffType(request.getStaffType());
            }
            if (request.getRole() != null) {
                user.setRole(request.getRole());
            }
            if (request.getLocationId() != null) {
                Optional<Location> loc = locationRepository.findById(request.getLocationId());
                loc.ifPresent(user::setPrimaryLocation);
            }
        }
        
        userRepository.save(user);
        
        return new AuthResponse(true, "User approved successfully", user, null);
    }

    public AuthResponse rejectRegistration(UUID userId) {
        Optional<User> optionalUser = userRepository.findById(userId);
        if (optionalUser.isEmpty()) {
            return new AuthResponse(false, "User not found", null, null);
        }
        
        userRepository.delete(optionalUser.get());
        return new AuthResponse(true, "User registration rejected and deleted", null, null);
    }
}
