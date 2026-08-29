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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Route<dynamic>? generateRoute(RouteSettings settings) {
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
    case EmployeeDashboardScreen.path:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => EmployeeDashboardScreen(
          employeeId: args['employeeId'] as int,
          employeeName: args['employeeName'] as String,
        ),
      );
    default:
      return null;
  }
}
