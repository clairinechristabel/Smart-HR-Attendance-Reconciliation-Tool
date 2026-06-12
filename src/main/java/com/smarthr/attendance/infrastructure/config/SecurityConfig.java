package com.smarthr.attendance.infrastructure.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Spring Security configuration implementing RBAC for the Smart HR Tool.
 *
 * <h3>Security Design (STRIDE Mitigations)</h3>
 * <ul>
 *   <li><b>Spoofing</b> — JWT-based stateless authentication (token validation
 *       would be added via a JwtAuthenticationFilter in production)</li>
 *   <li><b>Elevation of Privilege</b> — URL-level access control below +
 *       method-level {@code @PreAuthorize} annotations on service methods</li>
 *   <li><b>Denial of Service</b> — Stateless sessions prevent session flooding</li>
 * </ul>
 *
 * <h3>PoC Simplification</h3>
 * <p>For this PoC, we configure the security filter chain with role-based
 * URL patterns. In production, a {@code JwtAuthenticationFilter} would be
 * added before {@code UsernamePasswordAuthenticationFilter} to validate
 * JWT tokens on every request.</p>
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)  // Enables @PreAuthorize annotations
public class SecurityConfig {

    /**
     * Configure the HTTP security filter chain.
     *
     * <p>Endpoint access rules mirror the RBAC permission matrix from
     * the technical proposal (Section 5).</p>
     */
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            // ── Disable CSRF (stateless JWT API — no browser sessions) ──
            .csrf(AbstractHttpConfigurer::disable)

            // ── Stateless session management ────────────────────────────
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

            // ── URL-Level Authorization Rules ───────────────────────────
            .authorizeHttpRequests(auth -> auth

                // Public endpoints — authentication & API docs
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers("/swagger-ui/**", "/api-docs/**").permitAll()
                .requestMatchers("/actuator/health").permitAll()

                // Data Ingestion — HR_ADMIN only
                .requestMatchers("/api/v1/ingestion/**")
                    .hasRole("HR_ADMIN")

                // Reconciliation — HR_ADMIN triggers; FINANCE_ADMIN can view/export
                .requestMatchers(HttpMethod.POST, "/api/v1/reconciliation/run")
                    .hasRole("HR_ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/v1/reconciliation/discrepancies/*/resolve")
                    .hasRole("HR_ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/v1/reconciliation/**")
                    .hasAnyRole("HR_ADMIN", "FINANCE_ADMIN")

                // User Management — HR_ADMIN only
                .requestMatchers("/api/v1/users/**")
                    .hasRole("HR_ADMIN")

                // Medical Claims — role-specific access
                .requestMatchers(HttpMethod.POST, "/api/v1/medical-claims")
                    .hasAnyRole("SUPERVISOR", "HR_ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/v1/medical-claims/*/reimburse")
                    .hasRole("FINANCE_ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/v1/medical-claims/*/review")
                    .hasRole("HR_ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/v1/medical-claims/**")
                    .hasAnyRole("HR_ADMIN", "FINANCE_ADMIN")

                // Reports — Finance access
                .requestMatchers("/api/v1/reports/**")
                    .hasRole("FINANCE_ADMIN")

                // Everything else requires authentication
                .anyRequest().authenticated()
            );

            // In production, add JWT filter here:
            // .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)

        return http.build();
    }
}
