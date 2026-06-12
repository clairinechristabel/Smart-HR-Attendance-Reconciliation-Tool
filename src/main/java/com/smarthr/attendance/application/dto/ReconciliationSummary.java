package com.smarthr.attendance.application.dto;

import com.smarthr.attendance.domain.enums.DiscrepancyType;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Comprehensive summary of a reconciliation run.
 *
 * <p>This is the top-level output returned after the Reconciliation Engine
 * completes. It contains both aggregate statistics and the detailed list
 * of discrepancies — everything needed to generate the "Simple Excel Summary"
 * for payroll.</p>
 */
public class ReconciliationSummary {

    // ─── Run Metadata ────────────────────────────────────────────

    /** Unique identifier of this reconciliation run */
    private UUID runId;

    /** Name of the uploaded source file */
    private String sourceFileName;

    /** Start of the reconciliation period (derived from data) */
    private LocalDate periodStart;

    /** End of the reconciliation period (derived from data) */
    private LocalDate periodEnd;

    /** When the reconciliation was executed */
    private LocalDateTime processedAt;

    // ─── Aggregate Statistics ────────────────────────────────────

    /** Total number of attendance records processed */
    private int totalRecordsProcessed;

    /** Total number of discrepancies found */
    private int totalDiscrepancies;

    /** Breakdown of discrepancy counts by type */
    private Map<DiscrepancyType, Long> discrepanciesByType;

    /** Breakdown of discrepancy counts by location */
    private Map<String, Long> discrepanciesByLocation;

    /** Number of unknown employee IDs found in the Excel file */
    private int unknownEmployeeCount;

    // ─── Detailed Results ────────────────────────────────────────

    /** Full list of discrepancies — each one is an actionable item for HR */
    private List<DiscrepancyReport> discrepancies;

    // ─── Constructors ────────────────────────────────────────────
    public ReconciliationSummary() {}

    // ─── Getters & Setters ───────────────────────────────────────
    public UUID getRunId() { return runId; }
    public void setRunId(UUID runId) { this.runId = runId; }

    public String getSourceFileName() { return sourceFileName; }
    public void setSourceFileName(String sourceFileName) { this.sourceFileName = sourceFileName; }

    public LocalDate getPeriodStart() { return periodStart; }
    public void setPeriodStart(LocalDate periodStart) { this.periodStart = periodStart; }

    public LocalDate getPeriodEnd() { return periodEnd; }
    public void setPeriodEnd(LocalDate periodEnd) { this.periodEnd = periodEnd; }

    public LocalDateTime getProcessedAt() { return processedAt; }
    public void setProcessedAt(LocalDateTime processedAt) { this.processedAt = processedAt; }

    public int getTotalRecordsProcessed() { return totalRecordsProcessed; }
    public void setTotalRecordsProcessed(int totalRecordsProcessed) { this.totalRecordsProcessed = totalRecordsProcessed; }

    public int getTotalDiscrepancies() { return totalDiscrepancies; }
    public void setTotalDiscrepancies(int totalDiscrepancies) { this.totalDiscrepancies = totalDiscrepancies; }

    public Map<DiscrepancyType, Long> getDiscrepanciesByType() { return discrepanciesByType; }
    public void setDiscrepanciesByType(Map<DiscrepancyType, Long> discrepanciesByType) { this.discrepanciesByType = discrepanciesByType; }

    public Map<String, Long> getDiscrepanciesByLocation() { return discrepanciesByLocation; }
    public void setDiscrepanciesByLocation(Map<String, Long> discrepanciesByLocation) { this.discrepanciesByLocation = discrepanciesByLocation; }

    public int getUnknownEmployeeCount() { return unknownEmployeeCount; }
    public void setUnknownEmployeeCount(int unknownEmployeeCount) { this.unknownEmployeeCount = unknownEmployeeCount; }

    public List<DiscrepancyReport> getDiscrepancies() { return discrepancies; }
    public void setDiscrepancies(List<DiscrepancyReport> discrepancies) { this.discrepancies = discrepancies; }
}
