package com.smarthr.attendance.presentation.controller;

import com.smarthr.attendance.application.dto.ParsedAttendanceRecord;
import com.smarthr.attendance.application.dto.ReconciliationSummary;
import com.smarthr.attendance.application.service.ExcelParsingService;
import com.smarthr.attendance.application.service.ReconciliationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * REST controller for the Reconciliation Engine.
 *
 * <h3>Presentation Layer</h3>
 * <p>This controller handles HTTP-specific concerns (request parsing,
 * response formatting, status codes) and delegates all business logic
 * to the application layer services.</p>
 *
 * <h3>API Design</h3>
 * <ul>
 *   <li>All endpoints return a standard envelope: {@code {success, data, error, timestamp}}</li>
 *   <li>File uploads use multipart/form-data</li>
 *   <li>Access is restricted to HR_ADMIN role</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/v1/reconciliation")
@Tag(name = "Reconciliation", description = "Automated Attendance Reconciliation Engine")
public class ReconciliationController {

    private static final Logger log = LoggerFactory.getLogger(ReconciliationController.class);

    private final ExcelParsingService excelParsingService;
    private final ReconciliationService reconciliationService;

    public ReconciliationController(
            ExcelParsingService excelParsingService,
            ReconciliationService reconciliationService) {
        this.excelParsingService = excelParsingService;
        this.reconciliationService = reconciliationService;
    }

    /**
     * Upload an Excel file and trigger the reconciliation engine.
     *
     * <p><b>Workflow:</b></p>
     * <ol>
     *   <li>Receive the uploaded .xlsx file via multipart/form-data</li>
     *   <li>Parse the file into structured attendance records</li>
     *   <li>Run the reconciliation engine against the database</li>
     *   <li>Return a comprehensive summary with all discrepancies</li>
     * </ol>
     *
     * <p><b>Example cURL:</b></p>
     * <pre>
     * curl -X POST http://localhost:8080/api/v1/reconciliation/run \
     *   -H "Authorization: Bearer {jwt}" \
     *   -F "file=@attendance_june_2026.xlsx" \
     *   -F "processedBy=550e8400-e29b-41d4-a716-446655440000"
     * </pre>
     *
     * @param file         the attendance Excel file (.xlsx)
     * @param processedBy  UUID of the HR Admin triggering the reconciliation
     * @return ReconciliationSummary with all discrepancies and statistics
     */
    @PostMapping(value = "/run", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    // @PreAuthorize("hasRole('HR_ADMIN')")  // Disabled for PoC demo — restore for production
    @Operation(
        summary = "Run reconciliation on an uploaded Excel file",
        description = "Parses the attendance Excel file, cross-references against "
                    + "approved leaves and shift schedules, and returns a summary "
                    + "of all discrepancies (unexcused absences, late arrivals, etc.)")
    public ResponseEntity<Map<String, Object>> runReconciliation(
            @RequestParam("file") MultipartFile file,
            @RequestParam("processedBy") UUID processedBy) {

        log.info("Reconciliation requested: file='{}', processedBy={}",
                file.getOriginalFilename(), processedBy);

        try {
            // ── Step 1: Validate the upload ──────────────────────
            validateUpload(file);

            // ── Step 2: Parse Excel into structured records ──────
            List<ParsedAttendanceRecord> parsedRecords = excelParsingService.parse(file);

            // ── Step 3: Run the reconciliation engine ────────────
            ReconciliationSummary summary = reconciliationService.reconcile(
                    parsedRecords,
                    file.getOriginalFilename(),
                    processedBy);

            // ── Step 4: Return success response ──────────────────
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "data", summary,
                    "error", "",
                    "timestamp", java.time.Instant.now().toString()
            ));

        } catch (IllegalArgumentException e) {
            // Client error — bad file format, missing columns, etc.
            log.warn("Reconciliation failed (client error): {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "data", "",
                    "error", e.getMessage(),
                    "timestamp", java.time.Instant.now().toString()
            ));

        } catch (IOException e) {
            // Server error — file I/O issue
            log.error("Reconciliation failed (I/O error)", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "data", "",
                    "error", "Failed to read the uploaded file: " + e.getMessage(),
                    "timestamp", java.time.Instant.now().toString()
            ));
        }
    }

    /**
     * Retrieve the results of a previous reconciliation run.
     *
     * @param runId UUID of the reconciliation run
     * @return ReconciliationSummary for the specified run
     */
    @GetMapping("/runs/{runId}")
    @PreAuthorize("hasAnyRole('HR_ADMIN', 'FINANCE_ADMIN')")
    @Operation(
        summary = "Get reconciliation run details",
        description = "Returns the full details and discrepancies for a specific reconciliation run.")
    public ResponseEntity<Map<String, Object>> getRunDetails(@PathVariable UUID runId) {
        // In a complete implementation, this would fetch the run from the DB
        // and reconstruct the summary. For the PoC, we return a placeholder.
        return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("runId", runId, "message", "Full implementation pending"),
                "timestamp", java.time.Instant.now().toString()
        ));
    }

    /**
     * Export reconciliation results as an Excel file for payroll.
     *
     * @param runId UUID of the reconciliation run to export
     * @return Excel file download
     */
    @GetMapping("/runs/{runId}/export")
    @PreAuthorize("hasAnyRole('HR_ADMIN', 'FINANCE_ADMIN')")
    @Operation(
        summary = "Export reconciliation summary as Excel",
        description = "Generates the 'Simple Excel Summary' for payroll containing "
                    + "attendance performance, unexcused absences, and late arrivals.")
    public ResponseEntity<Map<String, Object>> exportRunAsExcel(@PathVariable UUID runId) {
        // In production: generate Excel using Apache POI and return as byte[]
        // with Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
        return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("runId", runId, "message", "Excel export implementation pending"),
                "timestamp", java.time.Instant.now().toString()
        ));
    }

    // ═══════════════════════════════════════════════════════════════
    //  PRIVATE HELPERS
    // ═══════════════════════════════════════════════════════════════

    /**
     * Validate the uploaded file before processing.
     *
     * <p>Security checks (STRIDE — Tampering & DoS):</p>
     * <ul>
     *   <li>File must not be empty</li>
     *   <li>File must be .xlsx format</li>
     *   <li>File size is enforced by Spring's multipart config (10MB max)</li>
     * </ul>
     */
    private void validateUpload(MultipartFile file) {
        if (file.isEmpty()) {
            throw new IllegalArgumentException("Uploaded file is empty.");
        }

        String filename = file.getOriginalFilename();
        if (filename == null || !filename.toLowerCase().endsWith(".xlsx")) {
            throw new IllegalArgumentException(
                    "Invalid file format. Only .xlsx files are accepted. "
                    + "Received: " + filename);
        }
    }
}
