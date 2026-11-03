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
import 'incentive_request_sheet.dart';

class BdeDashboardView extends StatelessWidget {
  final HomeDashboardModel data;

  const BdeDashboardView({
    super.key,
    required this.data,
  });

  String _formatTime12Hr(String timeStr) {
    if (timeStr == '--:--' || timeStr.isEmpty || timeStr == 'null') return '--:--';
    final trimmed = timeStr.trim();
    final upper = trimmed.toUpperCase();
    if (upper.contains('AM') || upper.contains('PM')) {
      return trimmed;
    }
    try {
      DateTime? parsed = DateTime.tryParse(trimmed);
      if (parsed == null) {
        final parts = trimmed.split(':');
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
    return trimmed;
  }

  String _formatAttendanceDate(String dateStr) {
    if (dateStr.isNotEmpty && dateStr != 'null') {
      try {
        final parsed = DateTime.tryParse(dateStr);
        if (parsed != null) {
          return DateFormat('EEEE, dd MMMM yyyy').format(parsed.toLocal());
        }
      } catch (_) {}
    }
    return DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
  }

  Widget _buildAttendanceCard({
    required BuildContext context,
    required bool checkedIn,
    required bool checkedOut,
    required String checkInTime,
    required String checkOutTime,
    required String shiftStatus,
    String? date,
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
                    _formatAttendanceDate(date ?? ''),
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
                          ? 'LOGGED OUT'
                          : checkedIn
                          ? 'LOGGED IN'
                          : 'NOT LOGGED IN',
                      style: TextStyle(
                        color: checkedOut
                            ? Colors.red.shade700
                            : checkedIn
                            ? Colors.green.shade700
                            : Colors.amber.shade700,
                        fontSize: 9.5,
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
    final effectiveAtt = apiAttendance ?? data.attendance;
    final bool checkedIn = data.isUserCheckedIn || (effectiveAtt?.isCheckedIn ?? false);
    final bool checkedOut = data.isUserCheckedOut ||
        (effectiveAtt != null &&
            (effectiveAtt.isCheckedOut ||
                effectiveAtt.shiftStatus == 'COMPLETED' ||
                effectiveAtt.shiftStatus == 'CHECKED_OUT'));

    final String checkInTime = checkedIn && effectiveAtt != null && effectiveAtt.checkInTime.isNotEmpty && effectiveAtt.checkInTime != 'null'
        ? _formatTime12Hr(effectiveAtt.checkInTime)
        : (checkedIn ? 'Logged In' : '--:--');

    final String checkOutTime = checkedOut && effectiveAtt != null && effectiveAtt.checkOutTime.isNotEmpty && effectiveAtt.checkOutTime != 'null'
        ? _formatTime12Hr(effectiveAtt.checkOutTime)
        : (checkedOut ? 'Logged Out' : '--:--');

    final String shiftStatus = effectiveAtt?.shiftStatus ??
        (checkedOut ? 'LOGGED OUT' : (checkedIn ? 'LOGGED IN' : 'NOT LOGGED IN'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAttendanceCard(
          context: context,
          checkedIn: checkedIn,
          checkedOut: checkedOut,
          checkInTime: checkInTime,
          checkOutTime: checkOutTime,
          shiftStatus: shiftStatus,
          date: effectiveAtt?.date,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isUserLoggedIn = data.isUserCheckedIn;
    final totalTasks = data.totalTasksCount;
    final completedTasks = data.completedTasksCount;
    final progressPct = (data.eodSync?.completionPercentage ?? (totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0)) / 100.0;

    final assignedLeads = data.totalMonthlyLeadsCount > 0
        ? data.totalMonthlyLeadsCount
        : (data.operationalOverview?.assignedLeads ?? 0);
    final followUpLeads = data.teamFollowUpCount > 0
        ? data.teamFollowUpCount
        : (data.operationalOverview?.followUpLeads ?? 0);
    final closedLeads = data.admittedLeadsCount > 0
        ? data.admittedLeadsCount
        : (data.operationalOverview?.closedLeads ?? 0);
    final incentives = data.walletBalance > 0
        ? data.walletBalance
        : (data.operationalOverview?.incentivesEarned ?? 0);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.teamName ?? (data.user.team.isNotEmpty ? data.user.team : 'BDE Workspace'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${data.user.name} • Executive Command Center',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 600 ? 4 : 2;
              final aspectRatio = width > 600
                  ? 1.45
                  : (width < 345 ? 1.05 : (width < 380 ? 1.12 : 1.2));

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: aspectRatio,
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
                    value: '\u20B9${NumberFormat('#,##,###').format(incentives.toInt())} Earn.',
                    icon: Icons.auto_graph_rounded,
                    iconColor: Colors.amber,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (ctx) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F766E).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.payments_rounded, color: Color(0xFF0F766E)),
                                  ),
                                  title: const Text('Request Incentive Withdrawal', style: TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: const Text('Submit claim directly to ASM'),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    showIncentiveRequestSheet(context, currentBalance: incentives.toDouble());
                                  },
                                ),
                                const Divider(),
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.auto_graph_rounded, color: Colors.amber),
                                  ),
                                  title: const Text('View Incentives & Milestones', style: TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: const Text('See transaction history and performance bonus'),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    HomeProvider.instance.setCurrentIndex(2);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    bottom: const Text(
                      'Tap to Request or View',
                      style: TextStyle(
                        color: AppColors.accentTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
          // Quick Action Banner: Request Incentive Withdrawal to ASM
          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF334155)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: Color(0xFFFBBF24),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Incentive Wallet',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Available: \u20B9${NumberFormat('#,##,###').format(incentives.toInt())}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => showIncentiveRequestSheet(
                    context,
                    currentBalance: incentives.toDouble(),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: const Text(
                    'Request',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildPerformanceSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    final tasks = HomeProvider.instance.performanceTasks;
    final summary = HomeProvider.instance.tasksSummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Tasks & Targets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Daily performance metrics & targets',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (summary != null)
              Row(
                children: [
                  _buildSummaryBadge(
                    '${summary.pending} Pending',
                    Colors.amber.shade800,
                    Colors.amber.shade50,
                  ),
                  const SizedBox(width: 6),
                  _buildSummaryBadge(
                    '${summary.completed} Done',
                    Colors.green.shade800,
                    Colors.green.shade50,
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (tasks.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.accentTeal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Tasks Assigned',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'You are all caught up! No pending targets.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...tasks.map((task) {
            final double progress = task.totalTarget > 0
                ? (task.achieved / task.totalTarget).clamp(0.0, 1.0)
                : 0.0;
            final int percentage = (progress * 100).toInt();

            String dateRange = '';
            if (task.periodStart.isNotEmpty && task.periodEnd.isNotEmpty) {
              dateRange = task.periodStart == task.periodEnd
                  ? task.periodStart
                  : '${task.periodStart} - ${task.periodEnd}';
            } else if (task.periodStart.isNotEmpty) {
              dateRange = task.periodStart;
            }

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? Colors.green.shade50
                              : AppColors.accentTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          task.isCompleted
                              ? Icons.task_alt_rounded
                              : Icons.track_changes_rounded,
                          size: 18,
                          color: task.isCompleted
                              ? Colors.green.shade700
                              : AppColors.accentTeal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (task.employee.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${task.employee}${task.employeeId.isNotEmpty ? ' (${task.employeeId})' : ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? Colors.green.shade50
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: task.isCompleted
                                ? Colors.green.shade200
                                : Colors.amber.shade200,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          task.isCompleted ? 'Completed' : 'Pending',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: task.isCompleted
                                ? Colors.green.shade800
                                : Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress: ${task.achieved} / ${task.totalTarget}${task.metricType.isNotEmpty ? ' ${task.metricType}' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.isCompleted ? Colors.green : AppColors.accentTeal,
                      ),
                    ),
                  ),
                  if (dateRange.isNotEmpty ||
                      task.frequency.isNotEmpty ||
                      task.metricType.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (dateRange.isNotEmpty)
                          _buildDetailChip(
                            Icons.calendar_today_outlined,
                            dateRange,
                          ),
                        if (task.metricType.isNotEmpty)
                          _buildDetailChip(
                            Icons.ads_click_rounded,
                            task.metricType,
                          ),
                        if (task.frequency.isNotEmpty)
                          _buildDetailChip(
                            Icons.repeat_rounded,
                            task.frequency.toUpperCase(),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildSummaryBadge(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
