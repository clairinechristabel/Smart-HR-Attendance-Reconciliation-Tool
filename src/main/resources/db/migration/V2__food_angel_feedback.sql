-- ═══════════════════════════════════════════════════════════════════════════
-- Smart HR Attendance & Reconciliation Tool
-- Flyway Migration V2 — Food Angel Feedback: New leave types, attendance columns
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── EXPAND LEAVE TYPE ENUM ─────────────────────────────────────────────
-- Adding Food Angel's full leave type codes: BL, CPL, NSL, SLA, M, PL, WFH

ALTER TYPE leave_type_enum ADD VALUE IF NOT EXISTS 'BIRTHDAY';
ALTER TYPE leave_type_enum ADD VALUE IF NOT EXISTS 'COMPENSATION';
ALTER TYPE leave_type_enum ADD VALUE IF NOT EXISTS 'NO_PAY_SICK';
ALTER TYPE leave_type_enum ADD VALUE IF NOT EXISTS 'SICK_ALLOWANCE';
ALTER TYPE leave_type_enum ADD VALUE IF NOT EXISTS 'MARRIAGE';
ALTER TYPE leave_type_enum ADD VALUE IF NOT EXISTS 'PATERNITY';
ALTER TYPE leave_type_enum ADD VALUE IF NOT EXISTS 'WFH';

-- ─── ADD DEPARTMENT TO USERS ────────────────────────────────────────────
-- Food Angel requested Department/Position to be visible on dashboards.

ALTER TABLE users ADD COLUMN IF NOT EXISTS department VARCHAR(100);

-- ─── ADD IMS-COMPATIBLE COLUMNS TO ATTENDANCE LOGS ──────────────────────
-- These map directly to the IMS Daily In/Out Report format:
--   LA = Late Arrival, EL = Early Leave, OT = Overtime

ALTER TABLE attendance_logs ADD COLUMN IF NOT EXISTS late_arrival_mins  INT DEFAULT 0;
ALTER TABLE attendance_logs ADD COLUMN IF NOT EXISTS early_leave_mins   INT DEFAULT 0;
ALTER TABLE attendance_logs ADD COLUMN IF NOT EXISTS overtime_mins      INT DEFAULT 0;

-- ─── ADD ANNUAL LEAVE ENTITLEMENT TO USERS ──────────────────────────────
-- Used for calculating AL Balance on the Leave History view.
-- Default: 14 days (Hong Kong statutory minimum after 12 months).

ALTER TABLE users ADD COLUMN IF NOT EXISTS annual_leave_entitlement INT DEFAULT 14;
