package com.smarthr.attendance.application.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Data Transfer Object representing a single row parsed from an Excel attendance file.
 *
 * <p>This DTO acts as the boundary between the infrastructure layer (Excel parsing)
 * and the application layer (reconciliation logic). It is intentionally decoupled
 * from the JPA entity to allow the parser to evolve independently.</p>
 *
 * <p>Example mapping from a typical Excel row:</p>
 * <pre>
 * | Employee ID | Date       | Clock In         | Clock Out        | Location     |
 * |-------------|------------|------------------|------------------|--------------|
 * | EMP-00142   | 2026-06-10 | 2026-06-10 08:15 | 2026-06-10 17:02 | Sha Tin      |
 * </pre>
 */
public class ParsedAttendanceRecord {

    /** Employee ID as it appears in the Excel file (e.g., "EMP-00142") */
    private String employeeId;

    /** The calendar date of this attendance record */
    private LocalDate attendanceDate;

    /** Clock-in timestamp — NULL if the employee did not clock in */
    private LocalDateTime clockIn;

    /** Clock-out timestamp — NULL if missing (possible data issue) */
    private LocalDateTime clockOut;

    /** Location name as it appears in the Excel file (e.g., "Sha Tin") */
    private String locationName;

    /** Reference to the source row for audit trail (e.g., "Sheet1!Row42") */
    private String sourceReference;

    // ─── Constructors ────────────────────────────────────────────
    public ParsedAttendanceRecord() {}

    public ParsedAttendanceRecord(String employeeId, LocalDate attendanceDate,
                                   LocalDateTime clockIn, LocalDateTime clockOut,
                                   String locationName, String sourceReference) {
        this.employeeId = employeeId;
        this.attendanceDate = attendanceDate;
        this.clockIn = clockIn;
        this.clockOut = clockOut;
        this.locationName = locationName;
        this.sourceReference = sourceReference;
    }

    // ─── Getters & Setters ───────────────────────────────────────
    public String getEmployeeId() { return employeeId; }
    public void setEmployeeId(String employeeId) { this.employeeId = employeeId; }

    public LocalDate getAttendanceDate() { return attendanceDate; }
    public void setAttendanceDate(LocalDate attendanceDate) { this.attendanceDate = attendanceDate; }

    public LocalDateTime getClockIn() { return clockIn; }
    public void setClockIn(LocalDateTime clockIn) { this.clockIn = clockIn; }

    public LocalDateTime getClockOut() { return clockOut; }
    public void setClockOut(LocalDateTime clockOut) { this.clockOut = clockOut; }

    public String getLocationName() { return locationName; }
    public void setLocationName(String locationName) { this.locationName = locationName; }

    public String getSourceReference() { return sourceReference; }
    public void setSourceReference(String sourceReference) { this.sourceReference = sourceReference; }

    @Override
    public String toString() {
        return String.format("ParsedAttendanceRecord{empId='%s', date=%s, in=%s, out=%s, loc='%s'}",
                employeeId, attendanceDate, clockIn, clockOut, locationName);
    }
}
