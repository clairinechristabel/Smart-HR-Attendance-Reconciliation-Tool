package com.smarthr.attendance.domain.repository;

import com.smarthr.attendance.domain.entity.ReconciliationDiscrepancy;
import com.smarthr.attendance.domain.enums.DiscrepancyType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ReconciliationDiscrepancyRepository extends JpaRepository<ReconciliationDiscrepancy, UUID> {

    List<ReconciliationDiscrepancy> findByRunId(UUID runId);

    List<ReconciliationDiscrepancy> findByRunIdAndDiscrepancyType(UUID runId, DiscrepancyType type);

    long countByRunIdAndResolvedFalse(UUID runId);
}
