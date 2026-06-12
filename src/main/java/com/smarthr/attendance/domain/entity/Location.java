package com.smarthr.attendance.domain.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Operational location entity.
 *
 * <p>Represents the physical sites where staff work:</p>
 * <ul>
 *   <li>Factories/Hubs: Sha Tin, Sham Shui Po</li>
 *   <li>Logistics: Kwai Chung (Warehouse)</li>
 *   <li>Retail: Kwun Tong (Shops, Vending Machines)</li>
 * </ul>
 *
 * <p>Used for multi-location dashboard filtering and volunteer
 * assignment tracking.</p>
 */
@Entity
@Table(name = "locations")
public class Location {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 100)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(name = "location_type", nullable = false)
    private LocationType locationType;

    @Column(length = 255)
    private String address;

    /** District for geographic grouping (e.g., "Sha Tin", "Kwai Chung") */
    @Column(nullable = false, length = 50)
    private String district;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    // ─── Constructors ────────────────────────────────────────────
    public Location() {}

    public Location(String name, LocationType locationType, String district) {
        this.name = name;
        this.locationType = locationType;
        this.district = district;
    }

    // ─── Inner Enum ──────────────────────────────────────────────
    public enum LocationType {
        FACTORY,
        LOGISTICS,
        RETAIL
    }

    // ─── Getters & Setters ───────────────────────────────────────
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public LocationType getLocationType() { return locationType; }
    public void setLocationType(LocationType locationType) { this.locationType = locationType; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getDistrict() { return district; }
    public void setDistrict(String district) { this.district = district; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public LocalDateTime getCreatedAt() { return createdAt; }
}
