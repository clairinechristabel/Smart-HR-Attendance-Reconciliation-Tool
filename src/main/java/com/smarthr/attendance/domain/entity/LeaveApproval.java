package com.smarthr.attendance.domain.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Individual approval step in a multi-level leave approval chain.
 *
 * <p>Each leave request may require one or more approval levels:</p>
 * <ul>
 *   <li>Level 1: Supervisor (kitchen/factory manager)</li>
 *   <li>Level 2: HR Admin (required for Annual, Personal, Maternity,
 *       Compassionate, and Unpaid leaves)</li>
 * </ul>
 */
@Entity
@Table(name = "leave_approvals",
       uniqueConstraints = @UniqueConstraint(
           columnNames = {"leave_request_id", "approval_level"},
           name = "uq_approval_level"))
public class LeaveApproval {

    public enum Decision {
        PENDING, APPROVED, REJECTED
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "leave_request_id", nullable = false)
    private LeaveRequest leaveRequest;

    /** The manager/admin who is responsible for this approval level */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "approver_id", nullable = false)
    private User approver;

    /** 1 = Supervisor, 2 = HR Admin */
    @Column(name = "approval_level", nullable = false)
    private int approvalLevel;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Decision decision = Decision.PENDING;

    @Column(columnDefinition = "TEXT")
    private String comments;

    @Column(name = "decided_at")
    private LocalDateTime decidedAt;

    // ─── Constructors ────────────────────────────────────────────
    public LeaveApproval() {}

    public LeaveApproval(LeaveRequest leaveRequest, User approver, int approvalLevel) {
        this.leaveRequest = leaveRequest;
        this.approver = approver;
        this.approvalLevel = approvalLevel;
    }

    // ─── Getters & Setters ───────────────────────────────────────
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public LeaveRequest getLeaveRequest() { return leaveRequest; }
    public void setLeaveRequest(LeaveRequest leaveRequest) { this.leaveRequest = leaveRequest; }

    public User getApprover() { return approver; }
    public void setApprover(User approver) { this.approver = approver; }

    public int getApprovalLevel() { return approvalLevel; }
    public void setApprovalLevel(int approvalLevel) { this.approvalLevel = approvalLevel; }

    public Decision getDecision() { return decision; }
    public void setDecision(Decision decision) { this.decision = decision; }

    public String getComments() { return comments; }
    public void setComments(String comments) { this.comments = comments; }

    public LocalDateTime getDecidedAt() { return decidedAt; }
    public void setDecidedAt(LocalDateTime decidedAt) { this.decidedAt = decidedAt; }
}
