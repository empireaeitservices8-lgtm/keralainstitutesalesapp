import 'package:flutter/material.dart';
import '../../screens/splash_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/attendance_screen.dart';
import '../../screens/tasks/task_screen.dart';
import '../../screens/incentive_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/eod_screen.dart';
import '../../screens/set_password_screen.dart';
import '../../screens/training_videos_screen.dart';
import '../../screens/leave_screen.dart';
import '../../screens/checkout_success_screen.dart';
import '../../screens/attendance_history_screen.dart';
import '../../screens/employee_dashboard_screen.dart';
import '../../screens/dashboard/requests_approvals_screen.dart';
import '../../screens/asm/bde_details_screen.dart';
import '../../models/asm_bde_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
String? currentRouteName;

/// Safely navigates the user to the login screen and clears the entire route stack.
void navigateToLogin() {
  void doNavigate([int retryCount = 0]) {
    final state = navigatorKey.currentState;
    if (state != null) {
      if (currentRouteName != LoginScreen.path) {
        state.pushNamedAndRemoveUntil(LoginScreen.path, (route) => false);
      }
    } else if (retryCount < 5) {
      Future.delayed(
        const Duration(milliseconds: 100),
        () => doNavigate(retryCount + 1),
      );
    }
  }

  WidgetsBinding.instance.addPostFrameCallback((_) => doNavigate());
}

Route<dynamic>? generateRoute(RouteSettings settings) {
  currentRouteName = settings.name;
  debugPrint(settings.name);
  switch (settings.name) {
    case SplashScreen.path:
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    case LoginScreen.path:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case SetPasswordScreen.path:
      return MaterialPageRoute(builder: (_) => const SetPasswordScreen());
    case DashboardScreen.path:
      return MaterialPageRoute(builder: (_) => const DashboardScreen());
    case AttendanceScreen.path:
      return MaterialPageRoute(builder: (_) => const AttendanceScreen());
    case TaskScreen.path:
      return MaterialPageRoute(builder: (_) => const TaskScreen());
    case IncentiveScreen.path:
      return MaterialPageRoute(builder: (_) => const IncentiveScreen());
    case ProfileScreen.path:
      return MaterialPageRoute(builder: (_) => const ProfileScreen());
    case EodScreen.path:
      return MaterialPageRoute(builder: (_) => const EodScreen());
    case TrainingVideosScreen.path:
      return MaterialPageRoute(builder: (_) => const TrainingVideosScreen());
    case LeaveScreen.path:
      return MaterialPageRoute(builder: (_) => const LeaveScreen());
    case CheckoutSuccessScreen.path:
      return MaterialPageRoute(builder: (_) => const CheckoutSuccessScreen());
    case AttendanceHistoryScreen.path:
      return MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen());
    case RequestsApprovalsScreen.path:
      return MaterialPageRoute(builder: (_) => const RequestsApprovalsScreen());
    case BdeDetailsScreen.path:
      final bde = settings.arguments as AsmBdeModel?;
      if (bde != null) {
        return MaterialPageRoute(builder: (_) => BdeDetailsScreen(bde: bde));
      }
      return null;
    case EmployeeDashboardScreen.path:
      final args = settings.arguments is Map ? settings.arguments as Map : {};
      final rawEmpId = args['employeeId'];
      final empId = rawEmpId is num
          ? rawEmpId.toInt()
          : (int.tryParse(rawEmpId?.toString() ?? '') ?? 0);
      return MaterialPageRoute(
        builder: (_) => EmployeeDashboardScreen(
          employeeId: empId,
          employeeName: args['employeeName']?.toString() ?? 'Employee',
        ),
      );
    default:
      return null;
  }
}
