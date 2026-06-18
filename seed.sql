-- Insert Locations
INSERT INTO locations (id, name, location_type, district) VALUES 
('11111111-1111-1111-1111-111111111111', 'Sham Shui Po Kitchen', 'FACTORY', 'Sham Shui Po'),
('22222222-2222-2222-2222-222222222222', 'Kwai Chung', 'LOGISTICS', 'Kwai Chung');

-- Insert HR Admin user (id used in frontend)
INSERT INTO users (id, employee_id, full_name, email, staff_type, role, is_active) VALUES 
('550e8400-e29b-41d4-a716-446655440000', 'HR-0001', 'Sarah Au', 'admin@foodangel.org', 'FULL_TIME', 'HR_ADMIN', true);

-- Insert Staff users
INSERT INTO users (id, employee_id, full_name, email, staff_type, role, primary_location_id, contracted_hours_per_day, is_active) VALUES 
(gen_random_uuid(), 'EMP-00142', 'Lisa Chan', 'lisa.chan@foodangel.org', 'FULL_TIME', 'LABORER', '11111111-1111-1111-1111-111111111111', 8.0, true),
(gen_random_uuid(), 'EMP-00088', 'David Wong', 'david.wong@foodangel.org', 'PART_TIME', 'LABORER', '22222222-2222-2222-2222-222222222222', 4.0, true);
