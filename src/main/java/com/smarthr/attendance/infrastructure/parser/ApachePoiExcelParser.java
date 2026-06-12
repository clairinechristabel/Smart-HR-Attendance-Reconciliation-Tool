package com.smarthr.attendance.infrastructure.parser;

import com.smarthr.attendance.application.dto.ParsedAttendanceRecord;
import com.smarthr.attendance.application.service.ExcelParsingService;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;

/**
 * Apache POI-based implementation of the Excel parsing service.
 *
 * <h3>Infrastructure Layer</h3>
 * <p>This class lives in the infrastructure layer — it deals with the
 * concrete details of Excel file I/O using Apache POI. The application
 * layer only knows about the {@link ExcelParsingService} interface.</p>
 *
 * <h3>Expected Excel Format</h3>
 * <p>The parser expects a standard format from the IM/Punch-card system:</p>
 * <pre>
 * | Employee ID | Date       | Clock In         | Clock Out        | Location     |
 * |-------------|------------|------------------|------------------|--------------|
 * | EMP-00142   | 2026-06-10 | 2026-06-10 08:15 | 2026-06-10 17:02 | Sha Tin      |
 * | EMP-00088   | 2026-06-10 | 2026-06-10 09:30 |                  | Kwai Chung   |
 * </pre>
 *
 * <h3>Column Detection</h3>
 * <p>The parser locates columns by matching header names (case-insensitive).
 * This makes it resilient to column reordering in the source file.</p>
 */
@Component
public class ApachePoiExcelParser implements ExcelParsingService {

    private static final Logger log = LoggerFactory.getLogger(ApachePoiExcelParser.class);

    // ─── Expected Column Headers (case-insensitive matching) ─────
    private static final String COL_EMPLOYEE_ID = "employee id";
    private static final String COL_DATE        = "date";
    private static final String COL_CLOCK_IN    = "clock in";
    private static final String COL_CLOCK_OUT   = "clock out";
    private static final String COL_LOCATION    = "location";

    /**
     * Parse an uploaded .xlsx file into structured attendance records.
     *
     * <p>Process:</p>
     * <ol>
     *   <li>Open the workbook from the uploaded file's input stream</li>
     *   <li>Read the first sheet (standard for IM/Punch-card exports)</li>
     *   <li>Detect column positions from the header row</li>
     *   <li>Iterate data rows, mapping each to a ParsedAttendanceRecord</li>
     *   <li>Skip empty rows; log warnings for malformed data</li>
     * </ol>
     *
     * @param file the uploaded .xlsx file
     * @return list of parsed records
     * @throws IOException if the file cannot be read
     * @throws IllegalArgumentException if required columns are missing
     */
    @Override
    public List<ParsedAttendanceRecord> parse(MultipartFile file) throws IOException {
        log.info("Parsing Excel file: name='{}', size={} bytes",
                file.getOriginalFilename(), file.getSize());

        List<ParsedAttendanceRecord> records = new ArrayList<>();

        try (InputStream is = file.getInputStream();
             Workbook workbook = new XSSFWorkbook(is)) {

            // Use the first sheet — standard for IM/Punch-card exports
            Sheet sheet = workbook.getSheetAt(0);
            String sheetName = sheet.getSheetName();
            log.debug("Reading sheet: '{}'", sheetName);

            // ── Step 1: Detect column positions from header row ──
            Row headerRow = sheet.getRow(0);
            if (headerRow == null) {
                throw new IllegalArgumentException(
                        "Excel file is empty — no header row found.");
            }

            Map<String, Integer> columnIndex = detectColumns(headerRow);
            validateRequiredColumns(columnIndex);

            // ── Step 2: Parse data rows ──────────────────────────
            int totalRows = sheet.getLastRowNum();
            log.debug("Processing {} data rows", totalRows);

            for (int rowNum = 1; rowNum <= totalRows; rowNum++) {
                Row row = sheet.getRow(rowNum);
                if (row == null || isRowEmpty(row)) {
                    continue;  // Skip empty rows
                }

                try {
                    ParsedAttendanceRecord record = parseRow(
                            row, columnIndex, sheetName, rowNum);
                    records.add(record);
                } catch (Exception e) {
                    // Log warning but continue — don't let one bad row
                    // kill the entire import
                    log.warn("Skipping malformed row {} in sheet '{}': {}",
                            rowNum + 1, sheetName, e.getMessage());
                }
            }
        }

        log.info("Successfully parsed {} attendance records from '{}'",
                records.size(), file.getOriginalFilename());

        return records;
    }

    // ═══════════════════════════════════════════════════════════════
    //  PRIVATE HELPER METHODS
    // ═══════════════════════════════════════════════════════════════

    /**
     * Detect column positions by scanning the header row.
     *
     * <p>Uses case-insensitive, trimmed matching so column order in the
     * source file doesn't matter. This makes the parser resilient to
     * minor format changes from the IM/Punch-card vendor.</p>
     */
    private Map<String, Integer> detectColumns(Row headerRow) {
        Map<String, Integer> columnIndex = new HashMap<>();

        for (int col = 0; col < headerRow.getLastCellNum(); col++) {
            Cell cell = headerRow.getCell(col);
            if (cell != null && cell.getCellType() == CellType.STRING) {
                String header = cell.getStringCellValue().trim().toLowerCase();
                columnIndex.put(header, col);
            }
        }

        log.debug("Detected columns: {}", columnIndex.keySet());
        return columnIndex;
    }

    /**
     * Validate that all required columns are present in the Excel file.
     *
     * @throws IllegalArgumentException if any required column is missing
     */
    private void validateRequiredColumns(Map<String, Integer> columnIndex) {
        List<String> requiredColumns = List.of(COL_EMPLOYEE_ID, COL_DATE);
        List<String> missingColumns = requiredColumns.stream()
                .filter(col -> !columnIndex.containsKey(col))
                .toList();

        if (!missingColumns.isEmpty()) {
            throw new IllegalArgumentException(
                    "Missing required columns in Excel file: " + missingColumns
                    + ". Expected headers: Employee ID, Date, Clock In, Clock Out, Location");
        }
    }

    /**
     * Parse a single data row into a ParsedAttendanceRecord.
     */
    private ParsedAttendanceRecord parseRow(
            Row row, Map<String, Integer> columnIndex,
            String sheetName, int rowNum) {

        ParsedAttendanceRecord record = new ParsedAttendanceRecord();

        // Employee ID (required — string)
        record.setEmployeeId(
                getCellStringValue(row, columnIndex.get(COL_EMPLOYEE_ID)));

        if (record.getEmployeeId() == null || record.getEmployeeId().isBlank()) {
            throw new IllegalArgumentException("Empty employee ID");
        }

        // Date (required)
        record.setAttendanceDate(
                getCellDateValue(row, columnIndex.get(COL_DATE)));

        // Clock In (optional — may be null if employee was absent)
        Integer clockInCol = columnIndex.get(COL_CLOCK_IN);
        if (clockInCol != null) {
            record.setClockIn(getCellDateTimeValue(row, clockInCol));
        }

        // Clock Out (optional — may be null for missing clock-out)
        Integer clockOutCol = columnIndex.get(COL_CLOCK_OUT);
        if (clockOutCol != null) {
            record.setClockOut(getCellDateTimeValue(row, clockOutCol));
        }

        // Location (optional)
        Integer locationCol = columnIndex.get(COL_LOCATION);
        if (locationCol != null) {
            record.setLocationName(getCellStringValue(row, locationCol));
        }

        // Source reference for audit trail (e.g., "Sheet1!Row42")
        record.setSourceReference(
                String.format("%s!Row%d", sheetName, rowNum + 1));

        return record;
    }

    /**
     * Extract a string value from a cell, handling numeric-to-string conversion.
     */
    private String getCellStringValue(Row row, Integer colIndex) {
        if (colIndex == null) return null;
        Cell cell = row.getCell(colIndex);
        if (cell == null) return null;

        return switch (cell.getCellType()) {
            case STRING  -> cell.getStringCellValue().trim();
            case NUMERIC -> String.valueOf((long) cell.getNumericCellValue());
            default      -> null;
        };
    }

    /**
     * Extract a LocalDate from a cell.
     */
    private LocalDate getCellDateValue(Row row, Integer colIndex) {
        if (colIndex == null) return null;
        Cell cell = row.getCell(colIndex);
        if (cell == null) return null;

        if (cell.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(cell)) {
            return cell.getDateCellValue().toInstant()
                    .atZone(ZoneId.systemDefault())
                    .toLocalDate();
        }

        // Fallback: try parsing as string
        if (cell.getCellType() == CellType.STRING) {
            return LocalDate.parse(cell.getStringCellValue().trim());
        }

        throw new IllegalArgumentException(
                "Cannot parse date from cell at column " + colIndex);
    }

    /**
     * Extract a LocalDateTime from a cell (for clock-in/out timestamps).
     */
    private LocalDateTime getCellDateTimeValue(Row row, Integer colIndex) {
        if (colIndex == null) return null;
        Cell cell = row.getCell(colIndex);
        if (cell == null || cell.getCellType() == CellType.BLANK) return null;

        if (cell.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(cell)) {
            return cell.getDateCellValue().toInstant()
                    .atZone(ZoneId.systemDefault())
                    .toLocalDateTime();
        }

        // Fallback: try parsing as ISO string
        if (cell.getCellType() == CellType.STRING) {
            String val = cell.getStringCellValue().trim();
            if (val.isEmpty()) return null;
            return LocalDateTime.parse(val);
        }

        return null;
    }

    /**
     * Check if a row is entirely empty (all cells blank or null).
     */
    private boolean isRowEmpty(Row row) {
        for (int col = row.getFirstCellNum(); col < row.getLastCellNum(); col++) {
            Cell cell = row.getCell(col);
            if (cell != null && cell.getCellType() != CellType.BLANK) {
                return false;
            }
        }
        return true;
    }
}
