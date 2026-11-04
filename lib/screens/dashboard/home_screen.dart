import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/operations_provider.dart';
import '../../providers/home_provider.dart';
import 'bde_dashboard_view.dart';
import 'management_dashboard_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthProvider.instance.session;
    return ListenableBuilder(
      listenable: HomeProvider.instance,
      builder: (context, _) {
        final homeState = HomeProvider.instance.state;

        if (homeState.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
            ),
          );
        }

        if (homeState.isError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    homeState.message ?? 'An unexpected error occurred.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () =>
                        HomeProvider.instance.fetchHomeData(isRefresh: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTeal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = homeState.data;
        if (data == null) {
          return const Center(
            child: Text(
              'No dashboard data available.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final desigLower = data.designationName.toLowerCase();
        final bool isAsm = user.role == 'ASM' ||
            data.dashboardType?.toUpperCase() == 'ASM' ||
            data.designationName.toUpperCase() == 'ASM' ||
            desigLower.contains('area sales') ||
            desigLower.contains('area manager') ||
            desigLower.contains('area') ||
            desigLower == 'asm' ||
            desigLower.contains('asm');

        final bool isSm = !isAsm && (user.role == 'SM' ||
            data.dashboardType?.toUpperCase() == 'SM' ||
            data.designationName.toUpperCase() == 'SM' ||
            data.designationName.toLowerCase().contains('state manager') ||
            data.designationName.toLowerCase().contains('sales manager'));

        Widget dashboardWidget = (!isSm && !isAsm && user.role == 'BDE')
            ? BdeDashboardView(data: data)
            : ManagementDashboardView(data: data, user: user);

        return RefreshIndicator(
          color: AppColors.accentTeal,
          onRefresh: () async {
            await Future.wait([
              HomeProvider.instance.fetchHomeData(isRefresh: true),
              OperationsProvider.instance.loadOperationsData(),
              if (isSm) OperationsProvider.instance.fetchSmAsms(isRefresh: true),
              OperationsProvider.instance.fetchOfficeTelecallers(isRefresh: true),
              OperationsProvider.instance.fetchSmPayoutRequests(isRefresh: true),
              OperationsProvider.instance.fetchAsmBdes(isRefresh: true),
              OperationsProvider.instance.fetchBdePendingRequests(isRefresh: true),
              OperationsProvider.instance.fetchWalletApprovalRequests(isRefresh: true),
              AttendanceProvider.instance.loadTodayAttendance(isRefresh: true),
            ]);
          },
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: dashboardWidget,
            ),
          ),
        );
      },
    );
  }
}
