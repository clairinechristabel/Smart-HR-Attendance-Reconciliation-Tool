package com.smarthr.attendance.domain.entity;

import com.smarthr.attendance.domain.enums.StaffType;
import com.smarthr.attendance.domain.enums.UserRole;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalTime;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Core user entity representing all staff types in the system.
 *
 * <p>This is a unified table for Full-Time, Part-Time, and Volunteer staff.
 * The {@link #staffType} field drives different business logic at the service
 * layer via the Strategy Pattern — avoiding complex table-per-type inheritance.</p>
 *
 * <p>Design Decision: Laborers may not have email/password (they use physical
 * punch cards). Only Supervisors and Admins have login credentials.</p>
 */
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Unique employee identifier visible on punch cards (e.g., "EMP-00142") */
    @Column(name = "employee_id", nullable = false, unique = true, length = 20)
    private String employeeId;

    @Column(name = "full_name", nullable = false, length = 100)
    private String fullName;

    @Column(length = 100)
    private String email;

    @Column(length = 20)
    private String phone;

    @Column(name = "password_hash")
    private String passwordHash;

    /** Determines which reconciliation strategy is applied to this user */
    @Enumerated(EnumType.STRING)
    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.NAMED_ENUM)
    @Column(name = "staff_type", nullable = false)
    private StaffType staffType;

    /** RBAC role — controls API access and feature visibility */
    @Enumerated(EnumType.STRING)
    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.NAMED_ENUM)
    @Column(nullable = false)
    private UserRole role;

    /** Primary work location — used for dashboard filtering */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "primary_location_id")
    private Location primaryLocation;

    /** Expected shift start time (e.g., 08:00). NULL for volunteers. */
    @Column(name = "default_shift_start")
    private LocalTime defaultShiftStart;

    /** Expected shift end time (e.g., 17:00). NULL for volunteers. */
    @Column(name = "default_shift_end")
    private LocalTime defaultShiftEnd;

    /**
     * Contracted daily working hours for part-time staff.
     * NULL for full-time and volunteers. Used by PartTimeReconciliationStrategy
     * to detect hours mismatches.
     */
    @Column(name = "contracted_hours_per_day", precision = 4, scale = 2)
    private BigDecimal contractedHoursPerDay;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    // ─── Lifecycle Callbacks ─────────────────────────────────────
    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    // ─── Constructors ────────────────────────────────────────────
    public User() {}

    public User(String employeeId, String fullName, StaffType staffType, UserRole role) {
        this.employeeId = employeeId;
        this.fullName = fullName;
        this.staffType = staffType;
        this.role = role;
    }

    // ─── Getters & Setters ───────────────────────────────────────
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getEmployeeId() { return employeeId; }
    public void setEmployeeId(String employeeId) { this.employeeId = employeeId; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }

    public StaffType getStaffType() { return staffType; }
    public void setStaffType(StaffType staffType) { this.staffType = staffType; }

    public UserRole getRole() { return role; }
    public void setRole(UserRole role) { this.role = role; }

    public Location getPrimaryLocation() { return primaryLocation; }
    public void setPrimaryLocation(Location primaryLocation) { this.primaryLocation = primaryLocation; }

    public LocalTime getDefaultShiftStart() { return defaultShiftStart; }
    public void setDefaultShiftStart(LocalTime defaultShiftStart) { this.defaultShiftStart = defaultShiftStart; }

    public LocalTime getDefaultShiftEnd() { return defaultShiftEnd; }
    public void setDefaultShiftEnd(LocalTime defaultShiftEnd) { this.defaultShiftEnd = defaultShiftEnd; }

    public BigDecimal getContractedHoursPerDay() { return contractedHoursPerDay; }
    public void setContractedHoursPerDay(BigDecimal contractedHoursPerDay) { this.contractedHoursPerDay = contractedHoursPerDay; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
