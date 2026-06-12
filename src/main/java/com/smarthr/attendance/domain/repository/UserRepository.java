package com.smarthr.attendance.domain.repository;

import com.smarthr.attendance.domain.entity.User;
import com.smarthr.attendance.domain.enums.StaffType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Repository for User entity operations.
 *
 * <p>Follows Interface Segregation Principle — only exposes query methods
 * needed by the application layer. JPA handles the implementation.</p>
 */
@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByEmployeeId(String employeeId);

    /**
     * Batch-fetch users by employee IDs — used by the Reconciliation Engine
     * to avoid N+1 queries when resolving employee references from Excel data.
     */
    List<User> findByEmployeeIdIn(Collection<String> employeeIds);

    List<User> findByStaffTypeAndActiveTrue(StaffType staffType);

    List<User> findByPrimaryLocationIdAndActiveTrue(UUID locationId);
}
