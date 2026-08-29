import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/operations_provider.dart';
import '../../providers/home_provider.dart';
import '../tasks/task_screen.dart';
import '../incentive_screen.dart';
import '../profile_screen.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const String path = '/dashboard';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Preload data
    OperationsProvider.instance.loadOperationsData();
    HomeProvider.instance.fetchHomeData();
    AttendanceProvider.instance.loadTodayAttendance();
  }

  Widget _buildBottomNavBar(HomeProvider homeProvider) {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Home'},
      {'icon': Icons.task_alt_rounded, 'label': 'Leads'},
      {'icon': Icons.auto_graph_rounded, 'label': 'Incentive'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final isSelected = homeProvider.currentIndex == index;
          return GestureDetector(
            onTap: () {
              homeProvider.setCurrentIndex(index);
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: AppColors.accentGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.accentTeal.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    items[index]['icon'] as IconData,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    size: 20,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Row(
                      children: [
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Text(
                            items[index]['label'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthProvider.instance.session;
    return ListenableBuilder(
      listenable: HomeProvider.instance,
      builder: (context, _) {
        final homeProvider = HomeProvider.instance;
        final currentIndex = homeProvider.currentIndex;
        Widget currentBody;
        switch (currentIndex) {
          case 0:
            currentBody = const HomeScreen();
            break;
          case 1:
            currentBody = const TaskScreen();
            break;
          case 2:
            currentBody = const IncentiveScreen();
            break;
          case 3:
            currentBody = const ProfileScreen();
            break;
          default:
            currentBody = const HomeScreen();
        }

        return Scaffold(
          backgroundColor: AppColors.primaryDark,
          appBar: currentIndex == 0
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  title: Text(
                    '${user.role} COMMAND CENTER',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  centerTitle: true,
                )
              : null,
          body: currentBody,
          bottomNavigationBar: _buildBottomNavBar(homeProvider),
        );
      },
    );
  }
}
