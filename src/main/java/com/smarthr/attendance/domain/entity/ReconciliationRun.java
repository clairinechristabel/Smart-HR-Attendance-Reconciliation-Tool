package com.smarthr.attendance.domain.entity;

import com.smarthr.attendance.domain.enums.ReconciliationStatus;
import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Represents a single execution of the Reconciliation Engine.
 *
 * <p>Each time an HR Admin uploads an Excel file and triggers reconciliation,
 * a new run record is created. It tracks:</p>
 * <ul>
 *   <li>Source file metadata (name, checksum for tamper detection)</li>
 *   <li>Processing status (PROCESSING → COMPLETED / FAILED)</li>
 *   <li>Summary statistics (total records, discrepancy count)</li>
 *   <li>All discrepancies detected during this run</li>
 * </ul>
 */
@Entity
@Table(name = "reconciliation_runs")
public class ReconciliationRun {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** HR Admin who initiated this reconciliation run */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "processed_by", nullable = false)
    private User processedBy;

    @Column(name = "source_file_name", nullable = false)
    private String sourceFileName;

    /** SHA-256 hash of the uploaded file — detects tampering (STRIDE: Tampering) */
    @Column(name = "source_file_checksum", length = 64)
    private String sourceFileChecksum;

    @Column(name = "period_start")
    private LocalDate periodStart;

    @Column(name = "period_end")
    private LocalDate periodEnd;

    @Column(name = "total_records_processed", nullable = false)
    private int totalRecordsProcessed = 0;

    @Column(name = "discrepancy_count", nullable = false)
    private int discrepancyCount = 0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ReconciliationStatus status = ReconciliationStatus.PROCESSING;

    @Column(name = "started_at", nullable = false, updatable = false)
    private LocalDateTime startedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    /** All discrepancies detected in this run */
    @OneToMany(mappedBy = "run", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ReconciliationDiscrepancy> discrepancies = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        this.startedAt = LocalDateTime.now();
    }

    // ─── Constructors ────────────────────────────────────────────
    public ReconciliationRun() {}

    // ─── Getters & Setters ───────────────────────────────────────
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getProcessedBy() { return processedBy; }
    public void setProcessedBy(User processedBy) { this.processedBy = processedBy; }

    public String getSourceFileName() { return sourceFileName; }
    public void setSourceFileName(String sourceFileName) { this.sourceFileName = sourceFileName; }

    public String getSourceFileChecksum() { return sourceFileChecksum; }
    public void setSourceFileChecksum(String sourceFileChecksum) { this.sourceFileChecksum = sourceFileChecksum; }

    public LocalDate getPeriodStart() { return periodStart; }
    public void setPeriodStart(LocalDate periodStart) { this.periodStart = periodStart; }

    public LocalDate getPeriodEnd() { return periodEnd; }
    public void setPeriodEnd(LocalDate periodEnd) { this.periodEnd = periodEnd; }

    public int getTotalRecordsProcessed() { return totalRecordsProcessed; }
    public void setTotalRecordsProcessed(int totalRecordsProcessed) { this.totalRecordsProcessed = totalRecordsProcessed; }

    public int getDiscrepancyCount() { return discrepancyCount; }
    public void setDiscrepancyCount(int discrepancyCount) { this.discrepancyCount = discrepancyCount; }

    public ReconciliationStatus getStatus() { return status; }
    public void setStatus(ReconciliationStatus status) { this.status = status; }

    public LocalDateTime getStartedAt() { return startedAt; }

    public LocalDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(LocalDateTime completedAt) { this.completedAt = completedAt; }

    public List<ReconciliationDiscrepancy> getDiscrepancies() { return discrepancies; }
    public void setDiscrepancies(List<ReconciliationDiscrepancy> discrepancies) { this.discrepancies = discrepancies; }
}
