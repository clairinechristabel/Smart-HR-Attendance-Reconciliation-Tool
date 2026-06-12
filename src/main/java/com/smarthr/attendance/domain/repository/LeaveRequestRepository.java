package com.smarthr.attendance.domain.repository;

import com.smarthr.attendance.domain.entity.LeaveRequest;
import com.smarthr.attendance.domain.enums.LeaveStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

/**
 * Repository for LeaveRequest queries.
 *
 * <p>The key query for reconciliation is {@link #findApprovedLeavesForUsersInPeriod},
 * which batch-fetches all FULLY_APPROVED leaves that overlap a given date range.
 * This prevents N+1 queries during reconciliation processing.</p>
 */
@Repository
public interface LeaveRequestRepository extends JpaRepository<LeaveRequest, UUID> {

    /**
     * Fetch all fully-approved leave requests for a set of users within a date range.
     *
     * <p>A leave overlaps the period if:
     * {@code leave.startDate <= periodEnd AND leave.endDate >= periodStart}</p>
     *
     * <p>This is the critical query for the Reconciliation Engine — it loads
     * all reference data in a single round-trip to enable O(1) lookups.</p>
     *
     * @param userIds    set of user UUIDs to check
     * @param periodStart  start of the reconciliation period
     * @param periodEnd    end of the reconciliation period
     * @return list of approved leaves overlapping the period
     */
    @Query("SELECT lr FROM LeaveRequest lr " +
           "WHERE lr.user.id IN :userIds " +
           "AND lr.status = 'FULLY_APPROVED' " +
           "AND lr.startDate <= :periodEnd " +
           "AND lr.endDate >= :periodStart")
    List<LeaveRequest> findApprovedLeavesForUsersInPeriod(
            @Param("userIds") Collection<UUID> userIds,
            @Param("periodStart") LocalDate periodStart,
            @Param("periodEnd") LocalDate periodEnd);

    List<LeaveRequest> findByUserIdAndStatus(UUID userId, LeaveStatus status);

    List<LeaveRequest> findByUserId(UUID userId);
}
