-- ═══════════════════════════════════════════════════════════════════════════
-- Food Angel — Smart HR Tool Database Setup (Supabase)
-- Target Project: https://nwtvwboqmvbzkddxuimg.supabase.co
-- Run this script in your Supabase SQL Editor: Dashboard > SQL Editor > New Query
-- ═══════════════════════════════════════════════════════════════════════════

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── 1. LOCATIONS TABLE ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    location_type VARCHAR(50) DEFAULT 'FACTORY',
    district VARCHAR(100),
    address VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed standard Food Angel branch locations
INSERT INTO locations (name, location_type, district, address) VALUES
    ('Sham Shui Po Factory', 'FACTORY', 'Sham Shui Po', '11 Shun Ning Road, Sham Shui Po, Kowloon'),
    ('Sha Tin Hub', 'FACTORY', 'Sha Tin', 'Unit 12, Fo Tan Industrial Area, Sha Tin'),
    ('Kwai Chung Warehouse', 'LOGISTICS', 'Kwai Chung', '8 Kwai Hei Street, Kwai Chung, NT'),
    ('Kwun Tong Retail', 'RETAIL', 'Kwun Tong', 'Shop B, 55 Hoi Yuen Road, Kwun Tong, Kowloon'),
    ('Head Office', 'OFFICE', 'Lai Chi Kok', 'Tower 2, Cheung Sha Wan Plaza, Kowloon')
ON CONFLICT (name) DO NOTHING;

-- ─── 2. USERS TABLE ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id VARCHAR(50) NOT NULL UNIQUE,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    phone VARCHAR(50),
    role VARCHAR(50) NOT NULL DEFAULT 'STAFF',            -- 'HR_ADMIN', 'SUPERVISOR', 'STAFF', 'FINANCE_ADMIN', 'LABORER'
    staff_type VARCHAR(50) NOT NULL DEFAULT 'FULL_TIME',  -- 'FULL_TIME', 'PART_TIME', 'VOLUNTEER'
    location VARCHAR(120) NOT NULL DEFAULT 'Head Office', -- Primary branch/location
    department VARCHAR(100) DEFAULT 'Operations',
    position VARCHAR(100) DEFAULT 'Staff Member',
    password VARCHAR(255) DEFAULT '1234',                 -- Plaintext/hash for demo/credential auth
    join_date DATE DEFAULT CURRENT_DATE,
    managed_locations TEXT[],                              -- For Supervisors managing multiple locations
    contracted_hours_per_day NUMERIC(4,2) DEFAULT 8.0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 3. ATTENDANCE RECORDS TABLE (Web & Sync) ────────────────────────────
CREATE TABLE IF NOT EXISTS attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_email VARCHAR(120) NOT NULL,
    staff_name VARCHAR(120) NOT NULL,
    date DATE NOT NULL,
    check_in VARCHAR(20),                                 -- e.g. "08:55"
    check_out VARCHAR(20),                                -- e.g. "17:15"
    status VARCHAR(50) NOT NULL DEFAULT 'ON_TIME',        -- 'ON_TIME', 'LATE', 'EARLY_LEAVE', 'ABSENT'
    method VARCHAR(50) NOT NULL DEFAULT 'BIOMETRIC',      -- 'BIOMETRIC', 'MOBILE', 'MANUAL'
    hours_worked NUMERIC(5,2),
    staff_type VARCHAR(50) DEFAULT 'FULL_TIME',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_staff_date UNIQUE (staff_email, date)
);

-- ─── 4. ATTENDANCE LOGS TABLE (Mobile App) ──────────────────────────────
CREATE TABLE IF NOT EXISTS attendance_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL,
    clock_in TIMESTAMPTZ,
    clock_out TIMESTAMPTZ,
    hours_worked NUMERIC(5,2),
    source VARCHAR(50) NOT NULL DEFAULT 'MOBILE',          -- 'MOBILE', 'PUNCH_CARD', 'KIOSK'
    status VARCHAR(50) DEFAULT 'ON_TIME',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 5. LEAVE REQUESTS TABLE ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS leave_requests (
    id VARCHAR(50) PRIMARY KEY,                           -- e.g. 'LR-00123'
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    staff_email VARCHAR(120) NOT NULL,
    staff_name VARCHAR(120) NOT NULL,
    staff_location VARCHAR(120),
    type VARCHAR(50) NOT NULL,                            -- 'ANNUAL', 'SICK', 'PERSONAL', 'COMPENSATION', etc.
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days NUMERIC(4,1) NOT NULL DEFAULT 1.0,
    reason TEXT,
    attachment_url TEXT,
    attachment_name VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',        -- 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'
    supervisor_approval VARCHAR(50) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'REJECTED'
    hr_approval VARCHAR(50) NOT NULL DEFAULT 'PENDING',   -- 'PENDING', 'APPROVED', 'REJECTED'
    supervisor_note TEXT,
    hr_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 6. LEAVE APPROVALS TABLE (Mobile Audit) ─────────────────────────────
CREATE TABLE IF NOT EXISTS leave_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    leave_request_id VARCHAR(50) REFERENCES leave_requests(id) ON DELETE CASCADE,
    approver_id UUID REFERENCES users(id),
    decision VARCHAR(50) NOT NULL,                        -- 'APPROVED', 'REJECTED'
    tier VARCHAR(20) NOT NULL,                            -- 'L1', 'L2'
    comments TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 7. ROW LEVEL SECURITY (RLS) POLICIES ────────────────────────────────
-- Enable RLS
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_approvals ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any to allow safe re-runs
DROP POLICY IF EXISTS "Public read locations" ON locations;
DROP POLICY IF EXISTS "Public write locations" ON locations;

DROP POLICY IF EXISTS "Public read users" ON users;
DROP POLICY IF EXISTS "Public write users" ON users;

DROP POLICY IF EXISTS "Public read attendance_records" ON attendance_records;
DROP POLICY IF EXISTS "Public write attendance_records" ON attendance_records;

DROP POLICY IF EXISTS "Public read attendance_logs" ON attendance_logs;
DROP POLICY IF EXISTS "Public write attendance_logs" ON attendance_logs;

DROP POLICY IF EXISTS "Public read leave_requests" ON leave_requests;
DROP POLICY IF EXISTS "Public write leave_requests" ON leave_requests;

DROP POLICY IF EXISTS "Public read leave_approvals" ON leave_approvals;
DROP POLICY IF EXISTS "Public write leave_approvals" ON leave_approvals;

-- Allow public / anon role full CRUD for prototype demo & mobile/web integration
CREATE POLICY "Public read locations" ON locations FOR SELECT USING (true);
CREATE POLICY "Public write locations" ON locations FOR ALL USING (true);

CREATE POLICY "Public read users" ON users FOR SELECT USING (true);
CREATE POLICY "Public write users" ON users FOR ALL USING (true);

CREATE POLICY "Public read attendance_records" ON attendance_records FOR SELECT USING (true);
CREATE POLICY "Public write attendance_records" ON attendance_records FOR ALL USING (true);

CREATE POLICY "Public read attendance_logs" ON attendance_logs FOR SELECT USING (true);
CREATE POLICY "Public write attendance_logs" ON attendance_logs FOR ALL USING (true);

CREATE POLICY "Public read leave_requests" ON leave_requests FOR SELECT USING (true);
CREATE POLICY "Public write leave_requests" ON leave_requests FOR ALL USING (true);

CREATE POLICY "Public read leave_approvals" ON leave_approvals FOR SELECT USING (true);
CREATE POLICY "Public write leave_approvals" ON leave_approvals FOR ALL USING (true);

-- ─── 8. SEED USERS WITH CREDENTIALS ──────────────────────────────────────
INSERT INTO users (employee_id, full_name, email, phone, role, staff_type, location, department, position, password, managed_locations) VALUES
    ('FA-0001', 'Sarah Au', 'admin@foodangel.hk', '+852 9876 5432', 'HR_ADMIN', 'FULL_TIME', 'Head Office', 'Human Resources', 'HR Manager', 'admin', NULL),
    ('FA-0025', 'David Wong', 'david.wong@foodangel.hk', '+852 9111 2233', 'SUPERVISOR', 'FULL_TIME', 'Sham Shui Po Factory', 'Operations', 'Kitchen Supervisor', '1234', ARRAY['Sham Shui Po Factory', 'Kwai Chung Warehouse']),
    ('FA-0030', 'Kelly Lam', 'kelly.lam@foodangel.hk', '+852 9888 9900', 'SUPERVISOR', 'FULL_TIME', 'Sha Tin Hub', 'Operations', 'Hub Supervisor', '1234', ARRAY['Sha Tin Hub', 'Kwun Tong Retail']),
    ('FA-0142', 'Lisa Chan', 'lisa.chan@foodangel.hk', '+852 9123 4567', 'STAFF', 'FULL_TIME', 'Sham Shui Po Factory', 'Kitchen Operations', 'Kitchen Helper', '1234', NULL),
    ('FA-0088', 'Mark Lee', 'mark.lee@foodangel.hk', '+852 9222 3344', 'STAFF', 'FULL_TIME', 'Sha Tin Hub', 'Production', 'Line Worker', '1234', NULL),
    ('FA-0201', 'Peter Ho', 'peter.ho@foodangel.hk', '+852 9555 6677', 'STAFF', 'FULL_TIME', 'Kwai Chung Warehouse', 'Logistics', 'Driver', '1234', NULL),
    ('FA-0310', 'Amy Cheung', 'amy.cheung@foodangel.hk', '+852 9333 4455', 'STAFF', 'PART_TIME', 'Kwai Chung Warehouse', 'Warehouse', 'Packing Assistant', '1234', NULL),
    ('FA-0315', 'Tom Ng', 'tom.ng@foodangel.hk', '+852 9444 5566', 'STAFF', 'PART_TIME', 'Kwun Tong Retail', 'Retail', 'Shop Assistant', '1234', NULL),
    ('VOL-0501', 'Wing Ho', 'wing.ho@foodangel.hk', '+852 9666 7788', 'STAFF', 'VOLUNTEER', 'Sham Shui Po Factory', 'Community Service', 'Volunteer', '1234', NULL),
    ('VOL-0502', 'Jenny Yip', 'jenny.yip@foodangel.hk', '+852 9777 8899', 'STAFF', 'VOLUNTEER', 'Sha Tin Hub', 'Community Service', 'Volunteer', '1234', NULL)
ON CONFLICT (email) DO UPDATE SET
    role = EXCLUDED.role,
    location = EXCLUDED.location,
    password = EXCLUDED.password;

-- ─── 9. SEED INITIAL LEAVE REQUESTS ──────────────────────────────────────
INSERT INTO leave_requests (id, staff_email, staff_name, staff_location, type, start_date, end_date, days, reason, status, supervisor_approval, hr_approval) VALUES
    ('LR-10021', 'lisa.chan@foodangel.hk', 'Lisa Chan', 'Sham Shui Po Factory', 'ANNUAL', '2026-08-03', '2026-08-05', 3.0, 'Family vacation', 'PENDING', 'APPROVED', 'PENDING'),
    ('LR-10022', 'mark.lee@foodangel.hk', 'Mark Lee', 'Sha Tin Hub', 'SICK', '2026-07-28', '2026-07-29', 2.0, 'Flu and fever', 'APPROVED', 'APPROVED', 'APPROVED'),
    ('LR-10023', 'peter.ho@foodangel.hk', 'Peter Ho', 'Kwai Chung Warehouse', 'COMPENSATION', '2026-08-10', '2026-08-10', 1.0, 'Overtime compensation from Sunday shift', 'PENDING', 'APPROVED', 'PENDING')
ON CONFLICT (id) DO NOTHING;

-- ─── 10. SEED SAMPLE TODAY ATTENDANCE ────────────────────────────────────
INSERT INTO attendance_records (staff_email, staff_name, date, check_in, check_out, status, method, hours_worked, staff_type) VALUES
    ('lisa.chan@foodangel.hk', 'Lisa Chan', CURRENT_DATE, '08:52', '17:05', 'ON_TIME', 'BIOMETRIC', 8.2, 'FULL_TIME'),
    ('mark.lee@foodangel.hk', 'Mark Lee', CURRENT_DATE, '09:12', '17:30', 'LATE', 'BIOMETRIC', 8.3, 'FULL_TIME'),
    ('peter.ho@foodangel.hk', 'Peter Ho', CURRENT_DATE, '08:45', '17:00', 'ON_TIME', 'BIOMETRIC', 8.25, 'FULL_TIME')
ON CONFLICT (staff_email, date) DO NOTHING;
