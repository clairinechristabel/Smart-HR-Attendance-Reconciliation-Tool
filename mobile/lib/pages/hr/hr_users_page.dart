// lib/pages/hr/hr_users_page.dart
import 'package:flutter/material.dart' hide Text;
import 'package:staff_portal/core/localization/localized_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';
import '../../services/mock_data.dart';

class HRUsersPage extends StatefulWidget {
  const HRUsersPage({super.key});

  @override
  State<HRUsersPage> createState() => _HRUsersPageState();
}

class _HRUsersPageState extends State<HRUsersPage> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _loading = true;
  List<UserModel> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final response = await _client
          .from('users')
          .select('*')
          .order('full_name', ascending: true);

      if (mounted) {
        setState(() {
          _users = (response as List).map((e) => UserModel.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _users = MockDatabase.users.values.toList();
          _loading = false;
        });
      }
    }
  }

  void _showStaffDetail(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(initials: user.initials, role: user.role, size: 64),
            const SizedBox(height: 12),
            Text(
              user.fullName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ColoredBadge(
                  label: user.employeeId,
                  color: AppTheme.gray700,
                  icon: Icons.badge_outlined,
                ),
                ColoredBadge(
                  label: user.role.replaceAll('_', ' '),
                  color: AppTheme.roleColor(user.role),
                ),
                ColoredBadge(
                  label: user.staffType.replaceAll('_', ' '),
                  color: AppTheme.staffTypeColor(user.staffType),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.location_on_outlined, 'Location', user.location ?? 'Sham Shui Po'),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.apartment_outlined, 'Department', user.department ?? 'Operations'),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.phone_outlined, 'Phone', user.phone ?? 'Not provided'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.gray500),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((u) {
      final q = _searchQuery.toLowerCase();
      return u.fullName.toLowerCase().contains(q) ||
          u.employeeId.toLowerCase().contains(q) ||
          (u.location?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Staff Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: tr(context, 'Search staff by name, ID or site...'),
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: AppTheme.gray50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.gray200),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: filtered.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'No staff found matching query',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final u = filtered[index];
                              return AppCard(
                                padding: const EdgeInsets.all(14),
                                onTap: () => _showStaffDetail(u),
                                child: Row(
                                  children: [
                                    UserAvatar(
                                      initials: u.initials,
                                      role: u.role,
                                      size: 42,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            u.fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${u.employeeId} • ${u.location ?? 'Sham Shui Po'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ColoredBadge(
                                      label: u.role.replaceAll('_', ' '),
                                      color: AppTheme.roleColor(u.role),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
