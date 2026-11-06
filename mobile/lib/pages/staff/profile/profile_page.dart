// lib/pages/staff/profile/profile_page.dart
import 'package:flutter/material.dart' hide Text;
import 'package:staff_portal/core/localization/localized_text.dart';
import 'package:staff_portal/widgets/language_switcher.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/user_avatar.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/mini_tour_modal.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  bool _isEditing = false;
  late TextEditingController _phoneController;
  late TextEditingController _nameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _nameController = TextEditingController(text: user?.fullName ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await _authService.updateProfile(
        userId: user.id,
        phone: _phoneController.text.trim(),
        fullName: _nameController.text.trim(),
      );

      final updated = user.copyWith(
        phone: _phoneController.text.trim(),
        fullName: _nameController.text.trim(),
      );
      if (mounted) {
        context.read<AuthProvider>().updateUser(updated);
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from Food Angel Staff Portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (mounted) context.go('/login');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: tr(context, 'Edit Profile'),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: tr(context, 'Cancel'),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _phoneController.text = user.phone ?? '';
                  _nameController.text = user.fullName;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // ── Avatar & Name Card ──
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  UserAvatar(
                    initials: user.initials,
                    role: user.role,
                    size: 72,
                  ),
                  const SizedBox(height: 12),
                  if (!_isEditing) ...[
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ] else ...[
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: tr(context, 'Full Name'),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ColoredBadge(
                        label: user.employeeId,
                        color: AppTheme.gray700,
                        icon: Icons.badge_outlined,
                      ),
                      ColoredBadge(
                        label: user.role.replaceAll('_', ' '),
                        color: AppTheme.roleColor(user.role),
                        icon: Icons.shield_outlined,
                      ),
                      ColoredBadge(
                        label: user.staffType.replaceAll('_', ' '),
                        color: AppTheme.staffTypeColor(user.staffType),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Details Card ──
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Work Information',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Primary Location',
                    value: user.location ?? 'Sham Shui Po Factory',
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    icon: Icons.apartment_outlined,
                    label: 'Department',
                    value: user.department ?? 'Operations',
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    icon: Icons.work_outline,
                    label: 'Position',
                    value: user.position ?? (user.isSupervisor ? 'Site Supervisor' : 'General Staff'),
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    icon: Icons.date_range_outlined,
                    label: 'Join Date',
                    value: user.joinDate ?? '2024-01-15',
                  ),
                  const Divider(height: 20),
                  if (!_isEditing)
                    _buildDetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Contact Phone',
                      value: user.phone?.isNotEmpty == true ? user.phone! : 'Not provided',
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: tr(context, 'Contact Phone'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (_isEditing) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _handleSave,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save Profile Changes'),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Quick Preferences & Security ──
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                    title: const Text('Password & Security'),
                    subtitle: const Text('Default credentials: 1234 or admin'),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.gray400),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password changes are managed by HR Admin.'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_none_outlined, color: AppTheme.textSecondary),
                    title: const Text('Notifications'),
                    subtitle: const Text('Push alerts for approvals & reminders'),
                    trailing: Switch(
                      value: true,
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (val) {},
                    ),
                  ),
                  const Divider(height: 1),
                  const LanguageSwitcher(),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.explore_outlined, color: AppTheme.primaryGreen),
                    title: const Text('App Mini Tour'),
                    subtitle: const Text('Replay guided tour of portal features'),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.gray400),
                    onTap: () => MiniTourModal.show(context, force: true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Sign Out Button ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                onPressed: _confirmSignOut,
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Food Angel Smart HR Tool • v1.0.0 (Build 2026)',
              style: TextStyle(color: AppTheme.gray400, fontSize: 12),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.gray500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
