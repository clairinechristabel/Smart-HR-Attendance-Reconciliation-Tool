package com.smarthr.attendance;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Smart HR Attendance & Reconciliation Tool — Application Entry Point.
 *
 * <p>This Spring Boot application provides a backend system for automating
 * HR attendance reconciliation across factories, logistics hubs, and retail
 * locations in Hong Kong.</p>
 */
@SpringBootApplication
public class SmartHrAttendanceApplication {

    public static void main(String[] args) {
        SpringApplication.run(SmartHrAttendanceApplication.class, args);
    }
}
