package com.smarthr.attendance.domain.entity;

import com.smarthr.attendance.domain.enums.AttendanceSource;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Raw attendance data record — a single clock-in/clock-out entry.
 *
 * <p>Attendance logs are ingested from multiple sources (Excel imports from
 * punch-card systems, IM logs, kiosk entries, or manual supervisor input).
 * Each record captures one employee's attendance for one day.</p>
 *
 * <p>The {@link #rawDataReference} field maintains traceability back to the
 * exact row in the source Excel file — critical for auditing discrepancies.</p>
 */
@Entity
@Table(name = "attendance_logs",
       uniqueConstraints = @UniqueConstraint(
           columnNames = {"user_id", "attendance_date", "source"},
           name = "uq_attendance_user_date_source"))
public class AttendanceLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** The employee this attendance record belongs to */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** The location where this attendance was recorded */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "location_id")
    private Location location;

    /** The calendar date of attendance */
    @Column(name = "attendance_date", nullable = false)
    private LocalDate attendanceDate;

    /** Clock-in timestamp — NULL if the employee did not clock in */
    @Column(name = "clock_in")
    private LocalDateTime clockIn;

    /** Clock-out timestamp — NULL if missing (flagged as MISSING_CLOCK_OUT) */
    @Column(name = "clock_out")
    private LocalDateTime clockOut;

    /** Computed hours worked (clock_out - clock_in). Used for part-time payroll. */
    @Column(name = "hours_worked", precision = 5, scale = 2)
    private BigDecimal hoursWorked;

    /** How this data was captured — important for data quality assessment */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AttendanceSource source;

    /** Reference to the source row (e.g., "Sheet1!Row42") for audit trail */
    @Column(name = "raw_data_reference", length = 100)
    private String rawDataReference;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        computeHoursWorked();
    }

    /** Auto-compute hours worked from clock-in and clock-out */
    private void computeHoursWorked() {
        if (clockIn != null && clockOut != null) {
            long minutes = java.time.Duration.between(clockIn, clockOut).toMinutes();
            this.hoursWorked = BigDecimal.valueOf(minutes / 60.0)
                    .setScale(2, java.math.RoundingMode.HALF_UP);
        }
    }

    // ─── Constructors ────────────────────────────────────────────
    public AttendanceLog() {}

    // ─── Getters & Setters ───────────────────────────────────────
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Location getLocation() { return location; }
    public void setLocation(Location location) { this.location = location; }

    public LocalDate getAttendanceDate() { return attendanceDate; }
    public void setAttendanceDate(LocalDate attendanceDate) { this.attendanceDate = attendanceDate; }

    public LocalDateTime getClockIn() { return clockIn; }
    public void setClockIn(LocalDateTime clockIn) { this.clockIn = clockIn; }

    public LocalDateTime getClockOut() { return clockOut; }
    public void setClockOut(LocalDateTime clockOut) { this.clockOut = clockOut; }

    public BigDecimal getHoursWorked() { return hoursWorked; }
    public void setHoursWorked(BigDecimal hoursWorked) { this.hoursWorked = hoursWorked; }

    public AttendanceSource getSource() { return source; }
    public void setSource(AttendanceSource source) { this.source = source; }

    public String getRawDataReference() { return rawDataReference; }
    public void setRawDataReference(String rawDataReference) { this.rawDataReference = rawDataReference; }

    public LocalDateTime getCreatedAt() { return createdAt; }
}
