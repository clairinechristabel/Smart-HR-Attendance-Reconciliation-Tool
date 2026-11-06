// lib/pages/hr/hr_register_staff_page.dart
//
// HR Admin: register a new staff account and assign them to a location.
// Credentials are created locally (mock) or inserted into Supabase.
//
import 'package:flutter/material.dart' hide Text;
import 'package:staff_portal/core/localization/localized_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/mock_data.dart';
import '../../models/user_model.dart';

const _kLocations = [
  'Sham Shui Po Factory',
  'Kwai Chung Warehouse',
  'Sha Tin Hub',
  'Kwun Tong Retail',
  'Head Office',
];

const _kRoles = ['STAFF', 'SUPERVISOR'];
const _kStaffTypes = ['FULL_TIME', 'PART_TIME', 'VOLUNTEER'];

class HRRegisterStaffPage extends StatefulWidget {
  const HRRegisterStaffPage({super.key});

  @override
  State<HRRegisterStaffPage> createState() => _HRRegisterStaffPageState();
}

class _HRRegisterStaffPageState extends State<HRRegisterStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedRole = 'STAFF';
  String _selectedStaffType = 'FULL_TIME';
  String _selectedLocation = _kLocations.first;
  bool _isLoading = false;
  bool _obscurePass = true;
  String? _createdEmail;
  String? _createdPassword;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _positionCtrl.dispose();
    _deptCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _generateEmployeeId() {
    final prefix = _selectedRole == 'VOLUNTEER' ? 'VOL' : 'FA';
    final num = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
    return '$prefix-$num';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;
    final empId = _generateEmployeeId();
    final now = DateTime.now();

    final userData = {
      'id': 'usr-${now.millisecondsSinceEpoch}',
      'employee_id': empId,
      'full_name': _nameCtrl.text.trim(),
      'email': email,
      'phone': _phoneCtrl.text.trim(),
      'role': _selectedRole,
      'staff_type': _selectedStaffType,
      'location': _selectedLocation,
      'department': _deptCtrl.text.trim().isEmpty ? 'Operations' : _deptCtrl.text.trim(),
      'position': _positionCtrl.text.trim(),
      'password': password,
      'join_date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'is_active': true,
    };

    try {
      // Try Supabase first
      if (!kUseMockDatabase) {
        try {
          await Supabase.instance.client
              .from('users')
              .insert(userData)
              .timeout(kNetworkTimeout);
        } catch (_) {
          // Fall back to mock
        }
      }

      // Always update mock so the session can immediately use it
      MockDatabase.users[email] = UserModel.fromJson(userData);

      if (mounted) {
        setState(() {
          _createdEmail = email;
          _createdPassword = password;
          _isLoading = false;
        });
        _showSuccessSheet();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${tr(context, 'Error')}: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppTheme.primaryGreen, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              tr(context, 'Staff Registered!'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              tr(context, 'The account has been created. Share credentials securely.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _credentialRow(Icons.email_outlined, tr(ctx, 'Email'), _createdEmail ?? ''),
            const SizedBox(height: 12),
            _credentialRow(Icons.lock_outline, tr(ctx, 'Password'), _createdPassword ?? ''),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppTheme.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr(ctx, 'Please share login credentials privately and ask staff to keep them secure.'),
                      style: const TextStyle(
                          color: AppTheme.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text(tr(ctx, 'Done')),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _credentialRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(tr(context, 'Register New Staff')),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(context, 'New Staff Account'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            tr(context, 'Fill in the details to create a login credential'),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _sectionLabel(tr(context, 'Personal Information')),
              const SizedBox(height: 12),

              _buildField(
                controller: _nameCtrl,
                label: tr(context, 'Full Name'),
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.isEmpty)
                    ? tr(context, 'Name is required')
                    : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _phoneCtrl,
                label: tr(context, 'Contact Phone'),
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              _sectionLabel(tr(context, 'Work Information')),
              const SizedBox(height: 12),

              // Role dropdown
              _buildDropdown<String>(
                label: tr(context, 'Role'),
                value: _selectedRole,
                icon: Icons.badge_outlined,
                items: _kRoles,
                itemLabel: (r) => r.replaceAll('_', ' '),
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 12),

              // Staff type dropdown
              _buildDropdown<String>(
                label: tr(context, 'Staff Type'),
                value: _selectedStaffType,
                icon: Icons.work_outline,
                items: _kStaffTypes,
                itemLabel: (s) => s.replaceAll('_', ' '),
                onChanged: (v) => setState(() => _selectedStaffType = v!),
              ),
              const SizedBox(height: 12),

              // Location dropdown
              _buildDropdown<String>(
                label: tr(context, 'Primary Location'),
                value: _selectedLocation,
                icon: Icons.location_on_outlined,
                items: _kLocations,
                itemLabel: (l) => l,
                onChanged: (v) => setState(() => _selectedLocation = v!),
              ),
              const SizedBox(height: 12),

              _buildField(
                controller: _positionCtrl,
                label: tr(context, 'Position'),
                icon: Icons.work_history_outlined,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _deptCtrl,
                label: tr(context, 'Department'),
                icon: Icons.apartment_outlined,
              ),
              const SizedBox(height: 24),

              _sectionLabel(tr(context, 'Login Credentials')),
              const SizedBox(height: 12),

              _buildField(
                controller: _emailCtrl,
                label: tr(context, 'Email Address'),
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return tr(context, 'Email is required');
                  if (!v.contains('@')) return tr(context, 'Enter a valid email');
                  if (MockDatabase.users.containsKey(v.trim().toLowerCase())) {
                    return tr(context, 'Email already exists');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Password field
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: tr(context, 'Password'),
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  helperText: tr(context, 'Min 4 characters'),
                ),
                validator: (v) {
                  if (v == null || v.length < 4) {
                    return tr(context, 'Password must be at least 4 characters');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _register,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.person_add),
                  label: Text(
                    _isLoading
                        ? tr(context, 'Creating Account...')
                        : tr(context, 'Create Staff Account'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMuted,
          letterSpacing: 0.5,
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required IconData icon,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      items: items
          .map((i) => DropdownMenuItem<T>(
                value: i,
                child: Text(itemLabel(i)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
