package com.smarthr.attendance.domain.entity;

import com.smarthr.attendance.domain.enums.LeaveStatus;
import com.smarthr.attendance.domain.enums.LeaveType;
import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Leave request entity — represents both pre-approved and retrospective leaves.
 *
 * <p>Key business rules:</p>
 * <ul>
 *   <li>Pre-approved: submitted before the leave date (e.g., Annual Leave)</li>
 *   <li>Retrospective: submitted after returning (e.g., Sick Leave with doctor note)</li>
 *   <li>Only {@link LeaveStatus#FULLY_APPROVED} requests are considered by
 *       the Reconciliation Engine when marking absences as excused</li>
 * </ul>
 */
@Entity
@Table(name = "leave_requests")
public class LeaveRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "leave_type", nullable = false)
    private LeaveType leaveType;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    /**
     * TRUE if this leave was logged after the employee already returned.
     * Retrospective sick leaves require a supporting document (doctor note).
     */
    @Column(name = "is_retrospective", nullable = false)
    private boolean retrospective = false;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LeaveStatus status = LeaveStatus.PENDING;

    /** MinIO/S3 URL for uploaded doctor notes or receipts */
    @Column(name = "supporting_doc_url", length = 500)
    private String supportingDocUrl;

    @Column(columnDefinition = "TEXT")
    private String reason;

    /** The approval chain for this request (one entry per approval level) */
    @OneToMany(mappedBy = "leaveRequest", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("approvalLevel ASC")
    private List<LeaveApproval> approvals = new ArrayList<>();

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    // ─── Domain Logic ────────────────────────────────────────────

    /**
     * Checks if the given date falls within this leave request's date range.
     * Used by the Reconciliation Engine to determine if an absence is excused.
     *
     * @param date the date to check
     * @return true if the date is covered by this leave
     */
    public boolean coversDate(LocalDate date) {
        return !date.isBefore(startDate) && !date.isAfter(endDate);
    }

    /**
     * Checks if this leave has been fully approved (all levels).
     */
    public boolean isFullyApproved() {
        return status == LeaveStatus.FULLY_APPROVED;
    }

    // ─── Constructors ────────────────────────────────────────────
    public LeaveRequest() {}

    // ─── Getters & Setters ───────────────────────────────────────
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public LeaveType getLeaveType() { return leaveType; }
    public void setLeaveType(LeaveType leaveType) { this.leaveType = leaveType; }

    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }

    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }

    public boolean isRetrospective() { return retrospective; }
    public void setRetrospective(boolean retrospective) { this.retrospective = retrospective; }

    public LeaveStatus getStatus() { return status; }
    public void setStatus(LeaveStatus status) { this.status = status; }

    public String getSupportingDocUrl() { return supportingDocUrl; }
    public void setSupportingDocUrl(String supportingDocUrl) { this.supportingDocUrl = supportingDocUrl; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public List<LeaveApproval> getApprovals() { return approvals; }
    public void setApprovals(List<LeaveApproval> approvals) { this.approvals = approvals; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
