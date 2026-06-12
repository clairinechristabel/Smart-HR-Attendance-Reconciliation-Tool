package com.smarthr.attendance.application.service;

import com.smarthr.attendance.application.dto.ParsedAttendanceRecord;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

/**
 * Service interface for parsing attendance data from uploaded files.
 *
 * <h3>SOLID: Dependency Inversion Principle</h3>
 * <p>The application layer depends on this abstraction, not on the concrete
 * Apache POI implementation. This allows:</p>
 * <ul>
 *   <li>Swapping the parser (e.g., from Apache POI to a CSV parser) without
 *       changing the ReconciliationService</li>
 *   <li>Easy unit testing with mock implementations</li>
 *   <li>Support for multiple file formats in the future</li>
 * </ul>
 *
 * <h3>SOLID: Interface Segregation Principle</h3>
 * <p>This interface exposes only what the application layer needs — a single
 * method to parse a file into a list of DTOs. No unnecessary coupling to
 * Apache POI, file I/O, or Excel-specific concepts.</p>
 */
public interface ExcelParsingService {

    /**
     * Parse an uploaded Excel file into a list of attendance records.
     *
     * <p>The parser is responsible for:</p>
     * <ol>
     *   <li>Validating the file format (must be .xlsx)</li>
     *   <li>Locating and validating required columns</li>
     *   <li>Parsing each row into a {@link ParsedAttendanceRecord}</li>
     *   <li>Generating source references for audit trail (e.g., "Sheet1!Row42")</li>
     *   <li>Skipping empty rows and handling common data quality issues</li>
     * </ol>
     *
     * @param file the uploaded Excel file
     * @return list of parsed attendance records
     * @throws IOException              if the file cannot be read
     * @throws IllegalArgumentException if the file format is invalid or
     *                                  required columns are missing
     */
    List<ParsedAttendanceRecord> parse(MultipartFile file) throws IOException;
}
