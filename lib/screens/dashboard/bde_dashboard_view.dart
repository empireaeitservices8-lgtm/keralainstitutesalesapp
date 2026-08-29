import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../models/home_dashboard_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/operations_provider.dart';
import '../../widgets/dashboard_module_card.dart';
import '../attendance_screen.dart';
import '../../models/performance_task.dart';

class BdeDashboardView extends StatelessWidget {
  final HomeDashboardModel data;

  const BdeDashboardView({
    super.key,
    required this.data,
  });

  String _formatTime12Hr(String timeStr) {
    if (timeStr == '--:--' || timeStr.isEmpty) return '--:--';
    try {
      DateTime? parsed = DateTime.tryParse(timeStr);
      if (parsed == null) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final hr = int.tryParse(parts[0]) ?? 0;
          final min = int.tryParse(parts[1]) ?? 0;
          final now = DateTime.now();
          parsed = DateTime(now.year, now.month, now.day, hr, min);
        }
      }
      if (parsed != null) {
        return DateFormat('hh:mm a').format(parsed.toLocal());
      }
    } catch (_) {}
    return timeStr;
  }

  Widget _buildAttendanceCard({
    required BuildContext context,
    required bool checkedIn,
    required bool checkedOut,
    required String checkInTime,
    required String checkOutTime,
    required String shiftStatus,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shift Attendance',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: checkedOut
                      ? Colors.red.shade50
                      : checkedIn
                      ? Colors.green.shade50
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: checkedOut
                            ? Colors.red
                            : checkedIn
                            ? Colors.green
                            : Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      checkedOut
                          ? 'COMPLETED'
                          : checkedIn
                          ? 'ACTIVE SHIFT'
                          : 'NOT CHECKED-IN',
                      style: TextStyle(
                        color: checkedOut
                            ? Colors.red.shade700
                            : checkedIn
                            ? Colors.green.shade700
                            : Colors.amber.shade700,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.login_rounded,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CHECK IN',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          checkInTime,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 30,
                width: 1,
                color: const Color(0xFFE2E8F0),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'CHECK OUT',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          checkOutTime,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: AppColors.accentGradient,
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, AttendanceScreen.path);
                },
                child: const Text(
                  'Manage Attendance & Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection(BuildContext context, [HomeAttendance? apiAttendance]) {
    if (apiAttendance != null) {
      final bool checkedIn = apiAttendance.isCheckedIn;
      final bool checkedOut =
          apiAttendance.shiftStatus == 'COMPLETED' ||
          apiAttendance.shiftStatus == 'CHECKED_OUT';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendanceCard(
            context: context,
            checkedIn: checkedIn,
            checkedOut: checkedOut,
            checkInTime: _formatTime12Hr(apiAttendance.checkInTime),
            checkOutTime: _formatTime12Hr(apiAttendance.checkOutTime),
            shiftStatus: apiAttendance.shiftStatus,
          ),
          const SizedBox(height: 20),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Attendance Activity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: AttendanceProvider.instance,
          builder: (context, _) {
            final attProvider = AttendanceProvider.instance;
            final att = attProvider.currentAttendance;
            final bool checkedIn = att.isPresent || att.isCompleted;
            final bool checkedOut = att.isCompleted;
            final String checkInTime = att.isAbsent
                ? '--:--'
                : DateFormat('hh:mm a').format(att.checkInTime);
            final String checkOutTime = (att.checkOutTime == null)
                ? '--:--'
                : DateFormat('hh:mm a').format(att.checkOutTime!);

            return _buildAttendanceCard(
              context: context,
              checkedIn: checkedIn,
              checkedOut: checkedOut,
              checkInTime: checkInTime,
              checkOutTime: checkOutTime,
              shiftStatus: checkedOut
                  ? 'COMPLETED'
                  : checkedIn
                  ? 'ACTIVE'
                  : 'OFFLINE',
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalTasks = data.eodSync?.totalTasks ?? 0;
    final completedTasks = data.eodSync?.tasksCompleted ?? 0;
    final progressPct = (data.eodSync?.completionPercentage ?? 0.0) / 100.0;

    final assignedLeads = data.operationalOverview?.assignedLeads ?? 0;
    final followUpLeads = data.operationalOverview?.followUpLeads ?? 0;
    final closedLeads = data.operationalOverview?.closedLeads ?? 0;
    final incentives = data.operationalOverview?.incentivesEarned ?? 0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendanceSection(context, data.attendance),
          const Text(
            'Operational Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.15,
            children: [
              DashboardModuleCard(
                title: 'Assigned Leads',
                value: '$assignedLeads Active',
                icon: Icons.task_alt_rounded,
                iconColor: Colors.cyan,
                onTap: () => HomeProvider.instance.setCurrentIndex(1),
                bottom: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalTasks > 0 ? (completedTasks / totalTasks) : 0.0,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.cyan,
                    ),
                  ),
                ),
              ),
              DashboardModuleCard(
                title: 'Follow-up Leads',
                value: '$followUpLeads Scheduled',
                icon: Icons.next_plan_outlined,
                iconColor: Colors.teal,
                onTap: () => HomeProvider.instance.setCurrentIndex(1),
                bottom: const Text(
                  'Interested status leads',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              DashboardModuleCard(
                title: 'Closed & Converted',
                value: '$closedLeads Resolved',
                icon: Icons.done_all_rounded,
                iconColor: Colors.orange,
                onTap: () => HomeProvider.instance.setCurrentIndex(1, initialTaskTabIndex: 1),
                bottom: const Text(
                  'Admitted or closed leads',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              DashboardModuleCard(
                title: 'Incentives',
                value: '₹${incentives.toStringAsFixed(0)} Earn.',
                icon: Icons.auto_graph_rounded,
                iconColor: Colors.amber,
                onTap: () => HomeProvider.instance.setCurrentIndex(2),
                bottom: const Text(
                  'Target & Volume bonus',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          _buildPerformanceSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    final tasks = HomeProvider.instance.performanceTasks;
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        const Text(
          'Performance Targets',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ...tasks.map((task) {
          final double progress = task.totalTarget > 0 ? (task.achieved / task.totalTarget).clamp(0.0, 1.0) : 0.0;
          final int percentage = (progress * 100).toInt();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${task.achieved} / ${task.totalTarget}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentTeal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Frequency: ${task.frequency.toUpperCase()} • Metric: ${task.metricType.replaceAll('_', ' ')}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
