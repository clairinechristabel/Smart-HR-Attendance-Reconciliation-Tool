package com.smarthr.attendance.domain.entity;

import com.smarthr.attendance.domain.enums.DiscrepancyType;
import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Individual discrepancy detected during a reconciliation run.
 *
 * <p>Each discrepancy represents a single business rule violation for
 * one employee on one date. Discrepancies can be manually resolved by
 * an HR Admin with resolution notes (e.g., "Employee had verbal approval
 * from floor manager").</p>
 */
@Entity
@Table(name = "reconciliation_discrepancies")
public class ReconciliationDiscrepancy {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** The reconciliation run that produced this discrepancy */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "run_id", nullable = false)
    private ReconciliationRun run;

    /** The employee with the discrepancy (NULL if unknown employee) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "discrepancy_date", nullable = false)
    private LocalDate discrepancyDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "discrepancy_type", nullable = false)
    private DiscrepancyType discrepancyType;

    /** When the employee was expected (e.g., shift start time) */
    @Column(name = "expected_time")
    private LocalDateTime expectedTime;

    /** When the employee actually arrived/left (NULL if absent) */
    @Column(name = "actual_time")
    private LocalDateTime actualTime;

    /** Time difference in minutes between expected and actual */
    @Column(name = "variance_minutes", nullable = false)
    private int varianceMinutes = 0;

    /** Human-readable explanation of the discrepancy */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String details;

    /** Whether an HR Admin has manually reviewed and resolved this */
    @Column(name = "is_resolved", nullable = false)
    private boolean resolved = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resolved_by")
    private User resolvedBy;

    @Column(name = "resolution_notes", columnDefinition = "TEXT")
    private String resolutionNotes;

    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;

    // ─── Constructors ────────────────────────────────────────────
    public ReconciliationDiscrepancy() {}

    // ─── Getters & Setters ───────────────────────────────────────
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public ReconciliationRun getRun() { return run; }
    public void setRun(ReconciliationRun run) { this.run = run; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public LocalDate getDiscrepancyDate() { return discrepancyDate; }
    public void setDiscrepancyDate(LocalDate discrepancyDate) { this.discrepancyDate = discrepancyDate; }

    public DiscrepancyType getDiscrepancyType() { return discrepancyType; }
    public void setDiscrepancyType(DiscrepancyType discrepancyType) { this.discrepancyType = discrepancyType; }

    public LocalDateTime getExpectedTime() { return expectedTime; }
    public void setExpectedTime(LocalDateTime expectedTime) { this.expectedTime = expectedTime; }

    public LocalDateTime getActualTime() { return actualTime; }
    public void setActualTime(LocalDateTime actualTime) { this.actualTime = actualTime; }

    public int getVarianceMinutes() { return varianceMinutes; }
    public void setVarianceMinutes(int varianceMinutes) { this.varianceMinutes = varianceMinutes; }

    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }

    public boolean isResolved() { return resolved; }
    public void setResolved(boolean resolved) { this.resolved = resolved; }

    public User getResolvedBy() { return resolvedBy; }
    public void setResolvedBy(User resolvedBy) { this.resolvedBy = resolvedBy; }

    public String getResolutionNotes() { return resolutionNotes; }
    public void setResolutionNotes(String resolutionNotes) { this.resolutionNotes = resolutionNotes; }

    public LocalDateTime getResolvedAt() { return resolvedAt; }
    public void setResolvedAt(LocalDateTime resolvedAt) { this.resolvedAt = resolvedAt; }
}
