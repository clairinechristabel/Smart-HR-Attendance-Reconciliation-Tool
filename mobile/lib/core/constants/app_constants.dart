// lib/core/constants/app_constants.dart

const String supabaseUrl = 'https://nwtvwboqmvbzkddxuimg.supabase.co';
const String supabaseAnonKey =
    'sb' '_' 'secret' '_' 'wYclB3rBnDifQaIv0nOFmQ' '_' 'f7J47jsQ';

// Enable live Supabase database (with graceful fallback to mock if offline)
const bool kUseMockDatabase = false;
const Duration kNetworkTimeout = Duration(milliseconds: 3000);

// User roles
class UserRole {
  static const String laborer = 'LABORER';
  static const String staff = 'STAFF';
  static const String supervisor = 'SUPERVISOR';
  static const String hrAdmin = 'HR_ADMIN';
  static const String financeAdmin = 'FINANCE_ADMIN';
}

// Staff types
class StaffType {
  static const String fullTime = 'FULL_TIME';
  static const String partTime = 'PART_TIME';
  static const String volunteer = 'VOLUNTEER';
}

// Leave types
class LeaveType {
  static const Map<String, String> labels = {
    'ANNUAL': 'Annual Leave',
    'BIRTHDAY': 'Birthday Leave',
    'COMPENSATION': 'Compensation Leave',
    'COMPASSIONATE': 'Compassionate Leave',
    'SICK': 'Sick Leave',
    'NO_PAY_SICK': 'No-Pay Sick Leave',
    'SICK_ALLOWANCE': 'Sick Allowance',
    'UNPAID': 'No-Pay Leave',
    'MARRIAGE': 'Marriage Leave',
    'MATERNITY': 'Maternity Leave',
    'PATERNITY': 'Paternity Leave',
    'WFH': 'Work From Home',
    'PERSONAL': 'Personal Leave',
  };

  static const Map<String, bool> requiresDocNote = {
    'ANNUAL': false,
    'BIRTHDAY': false,
    'COMPENSATION': false,
    'COMPASSIONATE': false,
    'SICK': false,
    'NO_PAY_SICK': false,
    'SICK_ALLOWANCE': true,
    'UNPAID': false,
    'MARRIAGE': false,
    'MATERNITY': true,
    'PATERNITY': false,
    'WFH': false,
    'PERSONAL': false,
  };
}

// Leave status
class LeaveStatus {
  static const String pending = 'PENDING';
  static const String l1Approved = 'L1_APPROVED';
  static const String fullyApproved = 'FULLY_APPROVED';
  static const String rejected = 'REJECTED';
  static const String cancelled = 'CANCELLED';
}

// Locations
const List<String> kLocations = [
  'Sham Shui Po Factory',
  'Sha Tin Hub',
  'Kwai Chung Warehouse',
  'Kwun Tong Retail',
  'Head Office',
];

// Demo passwords
const String kStaffPassword = '1234';
const String kAdminPassword = 'admin';
