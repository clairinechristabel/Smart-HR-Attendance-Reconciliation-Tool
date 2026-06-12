package com.smarthr.attendance.application.service;

import com.smarthr.attendance.application.dto.DiscrepancyReport;
import com.smarthr.attendance.application.dto.ParsedAttendanceRecord;
import com.smarthr.attendance.application.dto.ReconciliationSummary;
import com.smarthr.attendance.application.service.strategy.ReconciliationStrategy;
import com.smarthr.attendance.domain.entity.LeaveRequest;
import com.smarthr.attendance.domain.entity.ReconciliationDiscrepancy;
import com.smarthr.attendance.domain.entity.ReconciliationRun;
import com.smarthr.attendance.domain.entity.User;
import com.smarthr.attendance.domain.enums.DiscrepancyType;
import com.smarthr.attendance.domain.enums.ReconciliationStatus;
import com.smarthr.attendance.domain.enums.StaffType;
import com.smarthr.attendance.domain.repository.LeaveRequestRepository;
import com.smarthr.attendance.domain.repository.ReconciliationDiscrepancyRepository;
import com.smarthr.attendance.domain.repository.ReconciliationRunRepository;
import com.smarthr.attendance.domain.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * ReconciliationService — The Core Automated Reconciliation Engine
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * <h2>Purpose</h2>
 * <p>This service is the heart of the Smart HR Attendance Tool. It replaces
 * a <b>1-week manual process</b> of cross-referencing punch-card Excel exports
 * against paper leave forms with an <b>instant, automated analysis</b>.</p>
 *
 * <h2>Orchestration Flow</h2>
 * <pre>
 * ┌─────────────────────────────────────────────────────────────────────┐
 * │ Step 1: Initialize ReconciliationRun record                        │
 * │ Step 2: Determine date range from parsed records                   │
 * │ Step 3: Batch-fetch reference data (users, approved leaves)        │
 * │ Step 4: For each record → select strategy → detect discrepancies   │
 * │ Step 5: Batch-persist all discrepancies                            │
 * │ Step 6: Finalize run with summary statistics                       │
 * │ Step 7: Build and return ReconciliationSummary                     │
 * └─────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h2>SOLID Principles Applied</h2>
 * <ul>
 *   <li><b>S — Single Responsibility:</b> This service ONLY orchestrates
 *       reconciliation. Parsing is in ExcelParsingService. Per-record logic
 *       is in ReconciliationStrategy implementations.</li>
 *   <li><b>O — Open/Closed:</b> New staff types = new Strategy implementation.
 *       This class requires zero modifications.</li>
 *   <li><b>L — Liskov Substitution:</b> All strategies are interchangeable
 *       through the ReconciliationStrategy interface.</li>
 *   <li><b>I — Interface Segregation:</b> Each repository interface exposes
 *       only the methods needed by this service.</li>
 *   <li><b>D — Dependency Inversion:</b> This service depends on repository
 *       interfaces (abstractions), not JPA implementations (concretions).</li>
 * </ul>
 *
 * <h2>Performance Design</h2>
 * <ul>
 *   <li>All reference data is batch-loaded upfront (prevents N+1 queries)</li>
 *   <li>HashMap lookups for O(1) per-record resolution</li>
 *   <li>Discrepancies are batch-inserted via saveAll()</li>
 *   <li>JPA batch sizing configured in application.yml (hibernate.jdbc.batch_size)</li>
 * </ul>
 *
 * @see ReconciliationStrategy
 * @see ExcelParsingService
 */
@Service
@Transactional
public class ReconciliationService {

    private static final Logger log = LoggerFactory.getLogger(ReconciliationService.class);

    // ─── Dependencies (injected via constructor — DIP) ───────────

    private final UserRepository userRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final ReconciliationRunRepository runRepository;
    private final ReconciliationDiscrepancyRepository discrepancyRepository;

    /**
     * Strategy dispatch map: StaffType → ReconciliationStrategy.
     * Built from all @Component-annotated strategy implementations
     * discovered by Spring's component scan.
     */
    private final Map<StaffType, ReconciliationStrategy> strategyMap;

    /**
     * Constructor injection with auto-discovery of strategies.
     *
     * <p>Spring automatically collects all beans implementing
     * {@link ReconciliationStrategy} into the {@code strategies} list.
     * We build a HashMap for O(1) dispatch based on staff type.</p>
     *
     * <p>This design means adding a new staff type (e.g., CONTRACTOR)
     * only requires creating a new Strategy class annotated with @Component.
     * No changes to this service are needed — demonstrating the Open/Closed Principle.</p>
     *
     * @param userRepository          for resolving employee IDs to User entities
     * @param leaveRequestRepository  for fetching approved leaves in the period
     * @param runRepository           for persisting reconciliation run metadata
     * @param discrepancyRepository   for batch-persisting discrepancies
     * @param strategies              all ReconciliationStrategy implementations (auto-discovered)
     */
    public ReconciliationService(
            UserRepository userRepository,
            LeaveRequestRepository leaveRequestRepository,
            ReconciliationRunRepository runRepository,
            ReconciliationDiscrepancyRepository discrepancyRepository,
            List<ReconciliationStrategy> strategies) {

        this.userRepository = userRepository;
        this.leaveRequestRepository = leaveRequestRepository;
        this.runRepository = runRepository;
        this.discrepancyRepository = discrepancyRepository;

        // Build the strategy dispatch map from injected implementations
        this.strategyMap = strategies.stream()
                .collect(Collectors.toMap(
                        ReconciliationStrategy::getSupportedStaffType,
                        Function.identity()
                ));

        log.info("ReconciliationService initialized with {} strategies: {}",
                strategyMap.size(), strategyMap.keySet());
    }

    // ═══════════════════════════════════════════════════════════════
    //  PUBLIC API — Main Entry Point
    // ═══════════════════════════════════════════════════════════════

    /**
     * Execute the full reconciliation workflow.
     *
     * <p>This is the primary method called by the REST controller when an
     * HR Admin uploads an Excel file and triggers reconciliation. It:</p>
     * <ol>
     *   <li>Creates a tracking record for this run</li>
     *   <li>Loads all needed reference data in batch</li>
     *   <li>Processes every attendance record through the appropriate strategy</li>
     *   <li>Persists results and returns a comprehensive summary</li>
     * </ol>
     *
     * <p>The entire operation is wrapped in a {@code @Transactional} boundary.
     * If any step fails, all database writes are rolled back — ensuring
     * we never have partial results in the database.</p>
     *
     * @param parsedRecords  attendance records parsed from the uploaded Excel file
     * @param sourceFileName original filename for the audit trail
     * @param processedByUserId UUID of the HR Admin who initiated this run
     * @return a comprehensive ReconciliationSummary with all discrepancies and stats
     * @throws IllegalArgumentException if parsedRecords is empty
     * @throws IllegalStateException    if no strategy exists for an employee's staff type
     */
    public ReconciliationSummary reconcile(
            List<ParsedAttendanceRecord> parsedRecords,
            String sourceFileName,
            UUID processedByUserId) {

        log.info("Starting reconciliation: file='{}', records={}, initiatedBy={}",
                sourceFileName, parsedRecords.size(), processedByUserId);

        // Validate input
        if (parsedRecords == null || parsedRecords.isEmpty()) {
            throw new IllegalArgumentException(
                    "Cannot reconcile: no attendance records provided. "
                    + "The uploaded Excel file may be empty or incorrectly formatted.");
        }

        // ──────────────────────────────────────────────────────────
        // STEP 1: Initialize the Reconciliation Run
        // ──────────────────────────────────────────────────────────
        // Create a persistent record of this run for audit trail and
        // status tracking. Status starts as PROCESSING.
        ReconciliationRun run = initializeRun(sourceFileName, processedByUserId, parsedRecords.size());
        log.debug("Created reconciliation run: id={}", run.getId());

        // ──────────────────────────────────────────────────────────
        // STEP 2: Determine the Date Range
        // ──────────────────────────────────────────────────────────
        // Scan all parsed records to find the min/max dates.
        // This range is used to batch-fetch only the relevant leaves.
        LocalDate periodStart = parsedRecords.stream()
                .map(ParsedAttendanceRecord::getAttendanceDate)
                .min(LocalDate::compareTo)
                .orElseThrow(() -> new IllegalArgumentException("No valid dates in records"));

        LocalDate periodEnd = parsedRecords.stream()
                .map(ParsedAttendanceRecord::getAttendanceDate)
                .max(LocalDate::compareTo)
                .orElseThrow();

        log.debug("Reconciliation period: {} to {}", periodStart, periodEnd);

        // ──────────────────────────────────────────────────────────
        // STEP 3: Batch-Fetch All Reference Data
        // ──────────────────────────────────────────────────────────
        // PERFORMANCE: Instead of querying per-record (N+1 problem),
        // we load ALL needed data in exactly 2 database queries:
        //   1. All users matching the employee IDs in the Excel
        //   2. All FULLY_APPROVED leaves overlapping the date range
        // Results are indexed into HashMaps for O(1) lookup.

        // 3a. Collect unique employee IDs from the Excel file
        Set<String> employeeIds = parsedRecords.stream()
                .map(ParsedAttendanceRecord::getEmployeeId)
                .collect(Collectors.toSet());

        // 3b. Batch-fetch users and index by employee ID
        Map<String, User> usersByEmployeeId = userRepository
                .findByEmployeeIdIn(employeeIds)
                .stream()
                .collect(Collectors.toMap(User::getEmployeeId, Function.identity()));

        log.debug("Resolved {}/{} employee IDs to users",
                usersByEmployeeId.size(), employeeIds.size());

        // 3c. Batch-fetch approved leaves and index by user ID
        Set<UUID> resolvedUserIds = usersByEmployeeId.values().stream()
                .map(User::getId)
                .collect(Collectors.toSet());

        Map<UUID, List<LeaveRequest>> approvedLeavesByUserId = new HashMap<>();
        if (!resolvedUserIds.isEmpty()) {
            List<LeaveRequest> allLeaves = leaveRequestRepository
                    .findApprovedLeavesForUsersInPeriod(resolvedUserIds, periodStart, periodEnd);

            // Group leaves by user ID for O(1) lookup per employee
            approvedLeavesByUserId = allLeaves.stream()
                    .collect(Collectors.groupingBy(leave -> leave.getUser().getId()));
        }

        log.debug("Loaded {} approved leave records for {} users",
                approvedLeavesByUserId.values().stream().mapToLong(List::size).sum(),
                approvedLeavesByUserId.size());

        // ──────────────────────────────────────────────────────────
        // STEP 4: Process Each Record Through the Reconciliation Engine
        // ──────────────────────────────────────────────────────────
        // For each attendance record:
        //   a) Resolve the employee → if unknown, flag immediately
        //   b) Select the strategy based on staff type
        //   c) Delegate reconciliation to the strategy
        //   d) Collect all discrepancies
        List<ReconciliationDiscrepancy> allDiscrepancies = new ArrayList<>();
        int unknownEmployeeCount = 0;

        for (ParsedAttendanceRecord record : parsedRecords) {

            // 4a. Resolve the employee from the pre-loaded map
            User user = usersByEmployeeId.get(record.getEmployeeId());

            if (user == null) {
                // Unknown employee ID — not in our system
                // This could be a typo in the Excel, a new hire not yet registered,
                // or data from a different system.
                log.warn("Unknown employee ID '{}' in source file (ref: {})",
                        record.getEmployeeId(), record.getSourceReference());

                allDiscrepancies.add(createUnknownEmployeeDiscrepancy(run, record));
                unknownEmployeeCount++;
                continue;
            }

            // 4b. Select the reconciliation strategy for this employee's staff type
            ReconciliationStrategy strategy = strategyMap.get(user.getStaffType());
            if (strategy == null) {
                // This should never happen if all staff types have strategies.
                // Failing hard here ensures we catch configuration errors early.
                throw new IllegalStateException(
                        "No reconciliation strategy registered for staff type: "
                        + user.getStaffType() + ". Employee: " + user.getEmployeeId());
            }

            // 4c. Get the approved leaves for this specific employee
            List<LeaveRequest> userLeaves = approvedLeavesByUserId
                    .getOrDefault(user.getId(), Collections.emptyList());

            // 4d. Delegate to the strategy — it returns 0 or more discrepancies
            List<ReconciliationDiscrepancy> discrepancies =
                    strategy.reconcile(run, user, record, userLeaves);

            allDiscrepancies.addAll(discrepancies);
        }

        log.info("Reconciliation complete: {} total discrepancies, {} unknown employees",
                allDiscrepancies.size(), unknownEmployeeCount);

        // ──────────────────────────────────────────────────────────
        // STEP 5: Batch-Persist All Discrepancies
        // ──────────────────────────────────────────────────────────
        // Single saveAll() call → JPA batch insert (configured in
        // application.yml: hibernate.jdbc.batch_size=50)
        if (!allDiscrepancies.isEmpty()) {
            discrepancyRepository.saveAll(allDiscrepancies);
            log.debug("Persisted {} discrepancies", allDiscrepancies.size());
        }

        // ──────────────────────────────────────────────────────────
        // STEP 6: Finalize the Reconciliation Run
        // ──────────────────────────────────────────────────────────
        run.setPeriodStart(periodStart);
        run.setPeriodEnd(periodEnd);
        run.setDiscrepancyCount(allDiscrepancies.size());
        run.setStatus(ReconciliationStatus.COMPLETED);
        run.setCompletedAt(LocalDateTime.now());
        runRepository.save(run);

        // ──────────────────────────────────────────────────────────
        // STEP 7: Build and Return the Summary
        // ──────────────────────────────────────────────────────────
        return buildSummary(run, allDiscrepancies, unknownEmployeeCount);
    }

    // ═══════════════════════════════════════════════════════════════
    //  PRIVATE HELPER METHODS
    // ═══════════════════════════════════════════════════════════════

    /**
     * Initialize a new ReconciliationRun record in the database.
     *
     * <p>This creates the parent record that all discrepancies will
     * reference via FK. Status starts as PROCESSING.</p>
     */
    private ReconciliationRun initializeRun(String sourceFileName, UUID processedByUserId, int totalRecords) {
        // Fetch the HR Admin user who initiated this run
        User processedBy = userRepository.findById(processedByUserId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Unknown user ID: " + processedByUserId));

        ReconciliationRun run = new ReconciliationRun();
        run.setSourceFileName(sourceFileName);
        run.setProcessedBy(processedBy);
        run.setTotalRecordsProcessed(totalRecords);
        run.setStatus(ReconciliationStatus.PROCESSING);

        return runRepository.save(run);
    }

    /**
     * Create a discrepancy for an employee ID that doesn't exist in the system.
     *
     * <p>This handles the edge case where the Excel file contains employee IDs
     * that aren't registered in our database. Common causes:</p>
     * <ul>
     *   <li>Typo in the source data</li>
     *   <li>New hire not yet added to the system</li>
     *   <li>Data from a different organizational unit</li>
     * </ul>
     */
    private ReconciliationDiscrepancy createUnknownEmployeeDiscrepancy(
            ReconciliationRun run, ParsedAttendanceRecord record) {

        ReconciliationDiscrepancy d = new ReconciliationDiscrepancy();
        d.setRun(run);
        d.setUser(null);  // No user to reference — that's the point
        d.setDiscrepancyDate(record.getAttendanceDate());
        d.setDiscrepancyType(DiscrepancyType.UNEXCUSED_ABSENCE);
        d.setVarianceMinutes(0);
        d.setDetails(String.format(
                "Unknown employee ID '%s' found in source file (ref: %s). "
                + "This employee is not registered in the system.",
                record.getEmployeeId(), record.getSourceReference()));
        return d;
    }

    /**
     * Build a comprehensive ReconciliationSummary from the run results.
     *
     * <p>This transforms internal domain objects into a clean DTO suitable
     * for API serialization and Excel export. It includes:</p>
     * <ul>
     *   <li>Run metadata (file name, period, timestamps)</li>
     *   <li>Aggregate statistics (counts by type, by location)</li>
     *   <li>Full list of individual discrepancies</li>
     * </ul>
     */
    private ReconciliationSummary buildSummary(
            ReconciliationRun run,
            List<ReconciliationDiscrepancy> discrepancies,
            int unknownEmployeeCount) {

        ReconciliationSummary summary = new ReconciliationSummary();

        // ── Run metadata ─────────────────────────────────────────
        summary.setRunId(run.getId());
        summary.setSourceFileName(run.getSourceFileName());
        summary.setPeriodStart(run.getPeriodStart());
        summary.setPeriodEnd(run.getPeriodEnd());
        summary.setProcessedAt(run.getCompletedAt());
        summary.setTotalRecordsProcessed(run.getTotalRecordsProcessed());
        summary.setTotalDiscrepancies(discrepancies.size());
        summary.setUnknownEmployeeCount(unknownEmployeeCount);

        // ── Breakdown by discrepancy type ────────────────────────
        Map<DiscrepancyType, Long> byType = discrepancies.stream()
                .collect(Collectors.groupingBy(
                        ReconciliationDiscrepancy::getDiscrepancyType,
                        Collectors.counting()));
        summary.setDiscrepanciesByType(byType);

        // ── Breakdown by location ────────────────────────────────
        Map<String, Long> byLocation = discrepancies.stream()
                .filter(d -> d.getUser() != null && d.getUser().getPrimaryLocation() != null)
                .collect(Collectors.groupingBy(
                        d -> d.getUser().getPrimaryLocation().getName(),
                        Collectors.counting()));
        summary.setDiscrepanciesByLocation(byLocation);

        // ── Transform discrepancies into flat DTOs ───────────────
        List<DiscrepancyReport> reports = discrepancies.stream()
                .map(this::toDiscrepancyReport)
                .collect(Collectors.toList());
        summary.setDiscrepancies(reports);

        return summary;
    }

    /**
     * Map a domain entity to a flat DTO for API serialization.
     * The DTO deliberately avoids nested objects for easy JSON/Excel output.
     */
    private DiscrepancyReport toDiscrepancyReport(ReconciliationDiscrepancy d) {
        DiscrepancyReport report = new DiscrepancyReport();
        report.setDate(d.getDiscrepancyDate());
        report.setType(d.getDiscrepancyType());
        report.setExpectedTime(d.getExpectedTime());
        report.setActualTime(d.getActualTime());
        report.setVarianceMinutes(d.getVarianceMinutes());
        report.setDetails(d.getDetails());

        if (d.getUser() != null) {
            report.setEmployeeId(d.getUser().getEmployeeId());
            report.setEmployeeName(d.getUser().getFullName());
            if (d.getUser().getPrimaryLocation() != null) {
                report.setLocationName(d.getUser().getPrimaryLocation().getName());
            }
        } else {
            report.setEmployeeId("UNKNOWN");
            report.setEmployeeName("Unknown Employee");
        }

        return report;
    }
}
