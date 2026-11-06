// lib/pages/staff/staff_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:staff_portal/core/localization/app_language.dart';
import 'package:staff_portal/providers/language_provider.dart';
import '../../core/theme/app_theme.dart';

class StaffShell extends StatelessWidget {
  final Widget child;

  const StaffShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/staff/dashboard')) return 0;
    if (location.startsWith('/staff/attendance')) return 1;
    if (location.startsWith('/staff/leave')) return 2;
    if (location.startsWith('/staff/profile')) return 3;
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
                  context.go('/staff/dashboard');
                  break;
                case 1:
                  context.go('/staff/attendance');
                  break;
                case 2:
                  context.go('/staff/leave');
                  break;
                case 3:
                  context.go('/staff/profile');
                  break;
              }
            },
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: AppTheme.primaryGreen.withOpacity(0.12),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded,
                    color: AppTheme.primaryGreen),
                label: AppLanguage.translate('Home', languageCode),
              ),
              NavigationDestination(
                icon: Icon(Icons.access_time_outlined),
                selectedIcon: Icon(Icons.access_time_filled_rounded,
                    color: AppTheme.primaryGreen),
                label: AppLanguage.translate('Attendance', languageCode),
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month,
                    color: AppTheme.primaryGreen),
                label: AppLanguage.translate('Leave', languageCode),
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon:
                    Icon(Icons.person, color: AppTheme.primaryGreen),
                label: AppLanguage.translate('Profile', languageCode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
