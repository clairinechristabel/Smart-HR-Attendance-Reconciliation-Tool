package com.smarthr.attendance.application.dto;

import com.smarthr.attendance.domain.enums.DiscrepancyType;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * DTO representing a single discrepancy in the reconciliation report.
 *
 * <p>This is the output format — what the API returns to the client.
 * It is intentionally flat (no nested entities) for easy serialization
 * to JSON and Excel export.</p>
 */
public class DiscrepancyReport {

    private String employeeId;
    private String employeeName;
    private LocalDate date;
    private DiscrepancyType type;
    private LocalDateTime expectedTime;
    private LocalDateTime actualTime;
    private int varianceMinutes;
    private String details;
    private String locationName;

    // ─── Constructors ────────────────────────────────────────────
    public DiscrepancyReport() {}

    public DiscrepancyReport(String employeeId, String employeeName,
                              LocalDate date, DiscrepancyType type,
                              LocalDateTime expectedTime, LocalDateTime actualTime,
                              int varianceMinutes, String details,
                              String locationName) {
        this.employeeId = employeeId;
        this.employeeName = employeeName;
        this.date = date;
        this.type = type;
        this.expectedTime = expectedTime;
        this.actualTime = actualTime;
        this.varianceMinutes = varianceMinutes;
        this.details = details;
        this.locationName = locationName;
    }

    // ─── Getters & Setters ───────────────────────────────────────
    public String getEmployeeId() { return employeeId; }
    public void setEmployeeId(String employeeId) { this.employeeId = employeeId; }

    public String getEmployeeName() { return employeeName; }
    public void setEmployeeName(String employeeName) { this.employeeName = employeeName; }

    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }

    public DiscrepancyType getType() { return type; }
    public void setType(DiscrepancyType type) { this.type = type; }

    public LocalDateTime getExpectedTime() { return expectedTime; }
    public void setExpectedTime(LocalDateTime expectedTime) { this.expectedTime = expectedTime; }

    public LocalDateTime getActualTime() { return actualTime; }
    public void setActualTime(LocalDateTime actualTime) { this.actualTime = actualTime; }

    public int getVarianceMinutes() { return varianceMinutes; }
    public void setVarianceMinutes(int varianceMinutes) { this.varianceMinutes = varianceMinutes; }

    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }

    public String getLocationName() { return locationName; }
    public void setLocationName(String locationName) { this.locationName = locationName; }
}
