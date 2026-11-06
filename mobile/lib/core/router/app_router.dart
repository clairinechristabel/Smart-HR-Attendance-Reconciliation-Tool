// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../pages/splash_page.dart';
import '../../pages/login_page.dart';
import '../../pages/staff/staff_shell.dart';
import '../../pages/staff/staff_dashboard_page.dart';
import '../../pages/staff/leave/staff_leave_list_page.dart';
import '../../pages/staff/leave/leave_submit_page.dart';
import '../../pages/staff/leave/leave_detail_page.dart';
import '../../pages/staff/attendance/attendance_history_page.dart';
import '../../pages/staff/attendance/barcode_checkin_page.dart';
import '../../pages/staff/profile/profile_page.dart';
import '../../pages/supervisor/supervisor_shell.dart';
import '../../pages/supervisor/supervisor_dashboard_page.dart';
import '../../pages/supervisor/leave_approval_page.dart';
import '../../pages/supervisor/team_attendance_page.dart';
import '../../pages/hr/hr_shell.dart';
import '../../pages/hr/hr_dashboard_page.dart';
import '../../pages/hr/hr_leave_management_page.dart';
import '../../pages/hr/hr_users_page.dart';
import '../../pages/hr/hr_register_staff_page.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final location = state.matchedLocation;

        // Still loading
        if (auth.status == AuthStatus.initial ||
            auth.status == AuthStatus.loading) {
          return location == '/splash' ? null : '/splash';
        }

        // Not logged in
        if (!auth.isAuthenticated) {
          return location == '/login' ? null : '/login';
        }

        // Already logged in, redirect from splash/login to role dashboard
        if (location == '/splash' || location == '/login') {
          final user = auth.user!;
          if (user.isHRAdmin) return '/hr/dashboard';
          if (user.isSupervisor) return '/supervisor/dashboard';
          if (user.isFinanceAdmin) return '/hr/dashboard'; // Finance uses HR views
          return '/staff/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),

        // ── Staff routes ──────────────────────────────────
        ShellRoute(
          builder: (context, state, child) => StaffShell(child: child),
          routes: [
            GoRoute(
              path: '/staff/dashboard',
              builder: (context, state) => const StaffDashboardPage(),
            ),
            GoRoute(
              path: '/staff/checkin',
              builder: (context, state) => const BarcodeCheckinPage(),
            ),
            GoRoute(
              path: '/staff/attendance',
              builder: (context, state) => const AttendanceHistoryPage(),
            ),
            GoRoute(
              path: '/staff/leave',
              builder: (context, state) => const StaffLeaveListPage(),
            ),
            GoRoute(
              path: '/staff/leave/submit',
              builder: (context, state) => const LeaveSubmitPage(),
            ),
            GoRoute(
              path: '/staff/leave/:id',
              builder: (context, state) =>
                  LeaveDetailPage(leaveId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/staff/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),

        // ── Supervisor routes ─────────────────────────────
        ShellRoute(
          builder: (context, state, child) => SupervisorShell(child: child),
          routes: [
            GoRoute(
              path: '/supervisor/dashboard',
              builder: (context, state) => const SupervisorDashboardPage(),
            ),
            GoRoute(
              path: '/supervisor/leaves',
              builder: (context, state) => const LeaveApprovalPage(),
            ),
            GoRoute(
              path: '/supervisor/attendance',
              builder: (context, state) => const TeamAttendancePage(),
            ),
            GoRoute(
              path: '/supervisor/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),

        // ── HR Admin routes ───────────────────────────────
        ShellRoute(
          builder: (context, state, child) => HRShell(child: child),
          routes: [
            GoRoute(
              path: '/hr/dashboard',
              builder: (context, state) => const HRDashboardPage(),
            ),
            GoRoute(
              path: '/hr/leaves',
              builder: (context, state) => const HRLeaveManagementPage(),
            ),
            GoRoute(
              path: '/hr/users',
              builder: (context, state) => const HRUsersPage(),
            ),
            GoRoute(
              path: '/hr/profile',
              builder: (context, state) => const ProfilePage(),
            ),
            GoRoute(
              path: '/hr/register-staff',
              builder: (context, state) => const HRRegisterStaffPage(),
            ),
          ],
        ),
      ],
    );
  }
}
