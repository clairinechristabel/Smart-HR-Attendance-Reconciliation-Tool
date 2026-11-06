// lib/pages/hr/hr_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:staff_portal/core/localization/app_language.dart';
import 'package:staff_portal/providers/language_provider.dart';
import '../../core/theme/app_theme.dart';

class HRShell extends StatelessWidget {
  final Widget child;

  const HRShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/hr/dashboard')) return 0;
    if (location.startsWith('/hr/leaves')) return 1;
    if (location.startsWith('/hr/users')) return 2;
    if (location.startsWith('/hr/profile')) return 3;
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
                  context.go('/hr/dashboard');
                  break;
                case 1:
                  context.go('/hr/leaves');
                  break;
                case 2:
                  context.go('/hr/users');
                  break;
                case 3:
                  context.go('/hr/profile');
                  break;
              }
            },
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: AppTheme.purple.withValues(alpha: 0.15),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.purple),
                label: AppLanguage.translate('Dashboard', languageCode),
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded, color: AppTheme.purple),
                label: AppLanguage.translate('Leaves', languageCode),
              ),
              NavigationDestination(
                icon: Icon(Icons.badge_outlined),
                selectedIcon: Icon(Icons.badge_rounded, color: AppTheme.purple),
                label: AppLanguage.translate('Staff', languageCode),
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppTheme.purple),
                label: AppLanguage.translate('Profile', languageCode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
