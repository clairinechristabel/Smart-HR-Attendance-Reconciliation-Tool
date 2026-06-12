-- ═══════════════════════════════════════════════════════════════════════════
-- Smart HR Attendance & Reconciliation Tool
-- Flyway Migration V1 — Initial Schema
-- Database: PostgreSQL 15+
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── CUSTOM ENUM TYPES ──────────────────────────────────────────────────

CREATE TYPE staff_type      AS ENUM ('FULL_TIME', 'PART_TIME', 'VOLUNTEER');
CREATE TYPE user_role        AS ENUM ('LABORER', 'SUPERVISOR', 'HR_ADMIN', 'FINANCE_ADMIN');
CREATE TYPE location_type    AS ENUM ('FACTORY', 'LOGISTICS', 'RETAIL');
CREATE TYPE attendance_source AS ENUM ('PUNCH_CARD', 'IM_LOG', 'KIOSK', 'MANUAL');
CREATE TYPE leave_type_enum  AS ENUM ('ANNUAL', 'SICK', 'PERSONAL', 'MATERNITY', 'COMPASSIONATE', 'UNPAID');
CREATE TYPE leave_status     AS ENUM ('PENDING', 'L1_APPROVED', 'FULLY_APPROVED', 'REJECTED', 'CANCELLED');
CREATE TYPE approval_decision AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
CREATE TYPE claim_status     AS ENUM ('SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'REIMBURSED');
CREATE TYPE discrepancy_type AS ENUM ('UNEXCUSED_ABSENCE', 'LATE_ARRIVAL', 'EARLY_DEPARTURE', 'MISSING_CLOCK_OUT', 'HOURS_MISMATCH', 'LOCATION_MISMATCH');
CREATE TYPE recon_status     AS ENUM ('PROCESSING', 'COMPLETED', 'FAILED');

-- ─── LOCATIONS ──────────────────────────────────────────────────────────
-- Operational sites across multiple types: factories, logistics, retail.

CREATE TABLE locations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100)  NOT NULL,           -- e.g. "Sha Tin Factory"
    location_type   location_type NOT NULL,           -- FACTORY | LOGISTICS | RETAIL
    address         VARCHAR(255),
    district        VARCHAR(50)   NOT NULL,           -- e.g. "Sha Tin", "Kwai Chung"
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ─── USERS ──────────────────────────────────────────────────────────────
-- Unified table for all staff types. staff_type drives business logic at
-- the service layer via the Strategy Pattern.

CREATE TABLE users (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id               VARCHAR(20)  NOT NULL UNIQUE,  -- e.g. "EMP-00142"
    full_name                 VARCHAR(100) NOT NULL,
    email                     VARCHAR(100),
    phone                     VARCHAR(20),
    password_hash             VARCHAR(255),                   -- NULL for laborers (no login)
    staff_type                staff_type   NOT NULL,
    role                      user_role    NOT NULL,
    primary_location_id       UUID REFERENCES locations(id),
    default_shift_start       TIME,                           -- e.g. 08:00
    default_shift_end         TIME,                           -- e.g. 17:00
    contracted_hours_per_day  DECIMAL(4,2),                   -- For PART_TIME only
    is_active                 BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at                TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_staff_type ON users(staff_type);
CREATE INDEX idx_users_location   ON users(primary_location_id);
CREATE INDEX idx_users_active     ON users(is_active) WHERE is_active = TRUE;

-- ─── ATTENDANCE LOGS ────────────────────────────────────────────────────
-- Raw clock-in/out data ingested from Excel or logged manually.

CREATE TABLE attendance_logs (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID           NOT NULL REFERENCES users(id),
    location_id        UUID           REFERENCES locations(id),
    attendance_date    DATE           NOT NULL,
    clock_in           TIMESTAMP,
    clock_out          TIMESTAMP,
    hours_worked       DECIMAL(5,2),                          -- Computed from clock_in/out
    source             attendance_source NOT NULL,             -- How the data was captured
    raw_data_reference VARCHAR(100),                           -- Row ref in source Excel
    created_at         TIMESTAMP      NOT NULL DEFAULT NOW(),

    -- Prevent duplicate entries for the same employee on the same day from the same source
    CONSTRAINT uq_attendance_user_date_source UNIQUE (user_id, attendance_date, source)
);

CREATE INDEX idx_attendance_user_date ON attendance_logs(user_id, attendance_date);
CREATE INDEX idx_attendance_date      ON attendance_logs(attendance_date);
CREATE INDEX idx_attendance_location  ON attendance_logs(location_id);

-- ─── LEAVE REQUESTS ────────────────────────────────────────────────────
-- Both pre-approved and retrospective (post-fact sick leave) requests.

CREATE TABLE leave_requests (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID            NOT NULL REFERENCES users(id),
    leave_type        leave_type_enum NOT NULL,
    start_date        DATE            NOT NULL,
    end_date          DATE            NOT NULL,
    is_retrospective  BOOLEAN         NOT NULL DEFAULT FALSE,   -- After-the-fact sick leave
    status            leave_status    NOT NULL DEFAULT 'PENDING',
    supporting_doc_url VARCHAR(500),                             -- MinIO URL for doctor notes
    reason            TEXT,
    created_at        TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP       NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_leave_dates CHECK (end_date >= start_date)
);

CREATE INDEX idx_leave_user       ON leave_requests(user_id);
CREATE INDEX idx_leave_status     ON leave_requests(status);
CREATE INDEX idx_leave_date_range ON leave_requests(start_date, end_date);

-- ─── LEAVE APPROVALS ───────────────────────────────────────────────────
-- Multi-level approval chain. Level 1 = Supervisor, Level 2 = HR Admin.

CREATE TABLE leave_approvals (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    leave_request_id  UUID              NOT NULL REFERENCES leave_requests(id) ON DELETE CASCADE,
    approver_id       UUID              NOT NULL REFERENCES users(id),
    approval_level    INT               NOT NULL,              -- 1 = Supervisor, 2 = HR Admin
    decision          approval_decision NOT NULL DEFAULT 'PENDING',
    comments          TEXT,
    decided_at        TIMESTAMP,

    CONSTRAINT uq_approval_level UNIQUE (leave_request_id, approval_level)
);

-- ─── MEDICAL CLAIMS ────────────────────────────────────────────────────
-- Self-insured medical claims tracker for reimbursement.

CREATE TABLE medical_claims (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID          NOT NULL REFERENCES users(id),
    claim_date    DATE          NOT NULL,
    amount        DECIMAL(10,2) NOT NULL,                      -- HKD amount
    receipt_url   VARCHAR(500),                                 -- MinIO URL for scanned receipt
    status        claim_status  NOT NULL DEFAULT 'SUBMITTED',
    reviewed_by   UUID          REFERENCES users(id),
    notes         TEXT,
    created_at    TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_positive_amount CHECK (amount > 0)
);

CREATE INDEX idx_claims_user   ON medical_claims(user_id);
CREATE INDEX idx_claims_status ON medical_claims(status);

-- ─── RECONCILIATION RUNS ───────────────────────────────────────────────
-- Each execution of the reconciliation engine is tracked as a "run".

CREATE TABLE reconciliation_runs (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    processed_by           UUID         NOT NULL REFERENCES users(id),
    source_file_name       VARCHAR(255) NOT NULL,
    source_file_checksum   VARCHAR(64),                        -- SHA-256 hash
    period_start           DATE,
    period_end             DATE,
    total_records_processed INT         NOT NULL DEFAULT 0,
    discrepancy_count      INT          NOT NULL DEFAULT 0,
    status                 recon_status NOT NULL DEFAULT 'PROCESSING',
    started_at             TIMESTAMP    NOT NULL DEFAULT NOW(),
    completed_at           TIMESTAMP
);

CREATE INDEX idx_recon_runs_status ON reconciliation_runs(status);

-- ─── RECONCILIATION DISCREPANCIES ──────────────────────────────────────
-- Individual discrepancies detected during a reconciliation run.

CREATE TABLE reconciliation_discrepancies (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id            UUID             NOT NULL REFERENCES reconciliation_runs(id) ON DELETE CASCADE,
    user_id           UUID             REFERENCES users(id),   -- NULL if unknown employee
    discrepancy_date  DATE             NOT NULL,
    discrepancy_type  discrepancy_type NOT NULL,
    expected_time     TIMESTAMP,                                -- When they should have clocked in/out
    actual_time       TIMESTAMP,                                -- When they actually did (NULL if absent)
    variance_minutes  INT              NOT NULL DEFAULT 0,
    details           TEXT             NOT NULL,                 -- Human-readable explanation
    is_resolved       BOOLEAN          NOT NULL DEFAULT FALSE,
    resolved_by       UUID             REFERENCES users(id),
    resolution_notes  TEXT,
    resolved_at       TIMESTAMP
);

CREATE INDEX idx_discrepancies_run   ON reconciliation_discrepancies(run_id);
CREATE INDEX idx_discrepancies_user  ON reconciliation_discrepancies(user_id);
CREATE INDEX idx_discrepancies_type  ON reconciliation_discrepancies(discrepancy_type);

-- ─── VOLUNTEER ASSIGNMENTS ─────────────────────────────────────────────
-- Tracks 100+ daily volunteers across changing locations.

CREATE TABLE volunteer_assignments (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID    NOT NULL REFERENCES users(id),
    location_id      UUID    NOT NULL REFERENCES locations(id),
    assignment_date  DATE    NOT NULL,
    task_description VARCHAR(255),
    attended         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_volunteer_assignment UNIQUE (user_id, assignment_date)
);

CREATE INDEX idx_volunteer_date     ON volunteer_assignments(assignment_date);
CREATE INDEX idx_volunteer_location ON volunteer_assignments(location_id);

-- ─── AUDIT LOGS ────────────────────────────────────────────────────────
-- Immutable audit trail for all state-changing operations.

CREATE TABLE audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id    UUID         NOT NULL REFERENCES users(id),
    action      VARCHAR(20)  NOT NULL,                         -- CREATE, UPDATE, DELETE, APPROVE, REJECT
    entity_type VARCHAR(50)  NOT NULL,                         -- e.g. "LeaveRequest", "MedicalClaim"
    entity_id   UUID         NOT NULL,
    old_value   JSONB,                                          -- Previous state (NULL for CREATE)
    new_value   JSONB,                                          -- New state (NULL for DELETE)
    ip_address  VARCHAR(45),                                    -- IPv4 or IPv6
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_actor  ON audit_logs(actor_id);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_date   ON audit_logs(created_at);

-- ─── SEED DATA: LOCATIONS ──────────────────────────────────────────────
-- Placeholder locations — replace with actual operational sites during deployment.

INSERT INTO locations (name, location_type, address, district) VALUES
    ('Main Factory',          'FACTORY',   'Factory Address Line 1',     'District A'),
    ('Secondary Factory',     'FACTORY',   'Factory Address Line 2',     'District B'),
    ('Central Warehouse',     'LOGISTICS', 'Warehouse Address Line 1',   'District C'),
    ('Retail Shop',           'RETAIL',    'Shop Address Line 1',        'District D'),
    ('Vending Location',      'RETAIL',    'Vending Address Line 1',     'District D');
