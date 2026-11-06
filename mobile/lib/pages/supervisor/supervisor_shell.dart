// lib/pages/supervisor/supervisor_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:staff_portal/core/localization/app_language.dart';
import 'package:staff_portal/providers/language_provider.dart';
import '../../core/theme/app_theme.dart';

class SupervisorShell extends StatelessWidget {
  final Widget child;

  const SupervisorShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/supervisor/dashboard')) return 0;
    if (location.startsWith('/supervisor/leaves')) return 1;
    if (location.startsWith('/supervisor/attendance')) return 2;
    if (location.startsWith('/supervisor/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final languageCode = context.watch<LanguageProvider>().languageCode;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.gray100, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) {
              switch (i) {
                case 0:
                  context.go('/supervisor/dashboard');
                  break;
                case 1:
                  context.go('/supervisor/leaves');
                  break;
                case 2:
                  context.go('/supervisor/attendance');
                  break;
                case 3:
                  context.go('/supervisor/profile');
                  break;
              }
            },
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: AppTheme.info.withValues(alpha: 0.15),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.info),
                label: AppLanguage.translate('Dashboard', languageCode),
              ),
              NavigationDestination(
                icon: Icon(Icons.approval_outlined),
                selectedIcon: Icon(Icons.approval_rounded, color: AppTheme.info),
                label: AppLanguage.translate('Leaves', languageCode),
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded, color: AppTheme.info),
                label: AppLanguage.translate('Team', languageCode),
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppTheme.info),
                label: AppLanguage.translate('Profile', languageCode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
