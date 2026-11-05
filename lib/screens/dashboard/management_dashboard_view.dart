import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../api/api_client.dart';
import '../../api/api_endpoints.dart';
import '../../constants/colors.dart';
import '../../models/home_dashboard_model.dart';
import '../../models/office_telecaller_model.dart';
import '../../models/performance_task.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/operations_provider.dart';
import '../attendance_screen.dart';
import '../../utils/helpers.dart';
import 'create_asm_sheet.dart';
import 'create_bde_sheet.dart';
import 'requests_approvals_screen.dart';
import '../asm/bde_details_screen.dart';

class ManagementDashboardView extends StatelessWidget {
  final HomeDashboardModel data;
  final dynamic user;

  const ManagementDashboardView({
    super.key,
    required this.data,
    required this.user,
  });

  static String _keralaPerformancePeriod = 'Monthly';

  double _parseConversionPercentage(String val) {
    final match = RegExp(r'([0-9\.]+)').firstMatch(val);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }
    return 0.0;
  }

  Widget _buildDashboardHeader({
    required String title,
    required String subtitle,
    bool? isCheckedIn,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const Divider(height: 24, color: Color(0xFFE2E8F0)),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime12Hr(String timeStr) {
    final trimmed = timeStr.trim();
    if (trimmed == '--:--' || trimmed.isEmpty || trimmed == 'null')
      return '--:--';
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
              Expanded(
                child: Column(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                      : const Color(0xFFFEF3C7),
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
                            : const Color(0xFFF59E0B),
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
                            : const Color(0xFFB45309),
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
          const Divider(height: 28, color: Color(0xFFE2E8F0)),
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            checkInTime,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            checkOutTime,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
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
          const SizedBox(height: 18),
          Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.accentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection(
    BuildContext context, [
    HomeAttendance? apiAttendance,
  ]) {
    return AnimatedBuilder(
      animation: AttendanceProvider.instance,
      builder: (context, _) {
        final currentAtt = AttendanceProvider.instance.currentAttendance;
        final providerHomeAtt = AttendanceProvider.instance.todayHomeAttendance;
        final effectiveAtt =
            providerHomeAtt ?? apiAttendance ?? data.attendance;

        final bool hasProviderCheckIn = currentAtt.status != 'Absent';
        final bool hasProviderCheckOut = currentAtt.checkOutTime != null;

        final bool checkedIn =
            data.isUserCheckedIn ||
            (effectiveAtt?.isCheckedIn ?? false) ||
            currentAtt.status == 'Present';

        final bool checkedOut =
            data.isUserCheckedOut ||
            (effectiveAtt != null &&
                (effectiveAtt.isCheckedOut ||
                    effectiveAtt.shiftStatus.toUpperCase() == 'COMPLETED' ||
                    effectiveAtt.shiftStatus.toUpperCase() == 'CHECKED_OUT')) ||
            currentAtt.status == 'Completed';

        // 1. Resolve Check-In Time: Prioritize authoritative recorded time
        String rawCheckIn = '';
        if (providerHomeAtt != null &&
            providerHomeAtt.checkInTime.isNotEmpty &&
            providerHomeAtt.checkInTime != '--:--' &&
            providerHomeAtt.checkInTime != 'null') {
          rawCheckIn = providerHomeAtt.checkInTime;
        } else if (effectiveAtt != null &&
            effectiveAtt.checkInTime.isNotEmpty &&
            effectiveAtt.checkInTime != '--:--' &&
            effectiveAtt.checkInTime != 'null') {
          rawCheckIn = effectiveAtt.checkInTime;
        } else if (hasProviderCheckIn) {
          rawCheckIn = DateFormat('hh:mm a').format(currentAtt.checkInTime);
        }

        final String checkInTime = rawCheckIn.isNotEmpty
            ? _formatTime12Hr(rawCheckIn)
            : (checkedIn ? 'Logged In' : '--:--');

        // 2. Resolve Check-Out Time
        String rawCheckOut = '';
        if (providerHomeAtt != null &&
            providerHomeAtt.checkOutTime.isNotEmpty &&
            providerHomeAtt.checkOutTime != '--:--' &&
            providerHomeAtt.checkOutTime != 'null') {
          rawCheckOut = providerHomeAtt.checkOutTime;
        } else if (effectiveAtt != null &&
            effectiveAtt.checkOutTime.isNotEmpty &&
            effectiveAtt.checkOutTime != '--:--' &&
            effectiveAtt.checkOutTime != 'null') {
          rawCheckOut = effectiveAtt.checkOutTime;
        } else if (hasProviderCheckOut) {
          rawCheckOut = DateFormat('hh:mm a').format(currentAtt.checkOutTime!);
        }

        final String checkOutTime = rawCheckOut.isNotEmpty
            ? _formatTime12Hr(rawCheckOut)
            : (checkedOut ? 'Logged Out' : '--:--');

        final String shiftStatus =
            effectiveAtt?.shiftStatus ??
            (currentAtt.statusText?.isNotEmpty == true
                ? currentAtt.statusText!
                : (checkedOut
                      ? 'LOGGED OUT'
                      : (checkedIn ? 'LOGGED IN' : 'NOT LOGGED IN')));

        final String? effectiveDate = (providerHomeAtt?.date.isNotEmpty == true)
            ? providerHomeAtt!.date
            : ((effectiveAtt?.date.isNotEmpty == true)
                  ? effectiveAtt!.date
                  : null);

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
              date: effectiveDate,
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildZonalReportCard(
    String zoneName,
    int totalLeads,
    double conversion,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFF1F3)),
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
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    zoneName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                '${conversion.toStringAsFixed(1)}% Conv.',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: conversion / 100,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$totalLeads leads',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MD DASHBOARD VIEW ---
  Widget _buildMdDashboard(BuildContext context, OperationsProvider provider) {
    final allLeads = provider.rawTasks;

    final admitted = allLeads.where((t) => t.leadStatus == 'Admitted').length;
    final pending = allLeads.where((t) => t.status != 'Completed').length;
    final conversion = allLeads.isNotEmpty
        ? (admitted / allLeads.length) * 100
        : 0.0;

    final List<Map<String, String>> hierarchyUsers = [];
    hierarchyUsers.add({
      'name': user.name.isNotEmpty ? user.name : 'Super Admin',
      'role': 'MD',
      'scope': 'State-wide',
      'status': 'Active',
    });
    for (var asm in provider.hierarchyAsms) {
      hierarchyUsers.add({
        'name': asm['name'] ?? 'Unknown ASM',
        'role': 'ASM',
        'scope': 'District Manager',
        'status': 'Active',
      });
    }
    for (var bdm in provider.hierarchyBdms) {
      hierarchyUsers.add({
        'name': bdm['name'] ?? 'Unknown BDM',
        'role': 'BDM',
        'scope': 'Team Manager',
        'status': 'Active',
      });
    }
    for (var bde in provider.hierarchyBdes) {
      hierarchyUsers.add({
        'name': bde['name'] ?? 'Unknown BDE',
        'role': 'BDE',
        'scope': 'Field Executive',
        'status': 'Active',
      });
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardHeader(
            title: 'Kerala State Operations',
            subtitle: 'Super Admin Overview & Global Analytics',
          ),
          const SizedBox(height: 16),
          _buildAttendanceSection(context),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _buildStatCard(
                'Total State Leads',
                '${allLeads.length}',
                Icons.layers_outlined,
                Colors.blue,
              ),
              _buildStatCard(
                'Admissions Registered',
                '$admitted',
                Icons.check_circle_outline,
                Colors.green,
              ),
              _buildStatCard(
                'Conversion Rate',
                '${conversion.toStringAsFixed(1)}%',
                Icons.pie_chart_outline,
                Colors.amber,
              ),
              _buildStatCard(
                'Pending Followups',
                '$pending',
                Icons.hourglass_empty_rounded,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Zonal Performance Panels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ZONAL PERFORMANCE SUMMARY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              TextButton(
                onPressed: () => HomeProvider.instance.setCurrentIndex(1),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'View All Leads',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.accentTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (data.territoryReport == null || data.territoryReport!.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEFF1F3)),
              ),
              child: const Center(
                child: Text(
                  'No dynamic zonal reports available.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...data.territoryReport!.map((report) {
              final double conversion =
                  double.tryParse(
                    report.conversionPercentage.replaceAll('%', ''),
                  ) ??
                  0.0;
              return Column(
                children: [
                  _buildZonalReportCard(
                    '${report.territoryName} (${report.managerName})',
                    report.leadsCount,
                    conversion,
                    Colors.teal,
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }),

          const SizedBox(height: 24),

          // User Control & Org Directory
          const Text(
            'ORGANIZATIONAL USER ROLES CONTROL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEFF1F3)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hierarchyUsers.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final u = hierarchyUsers[index];
                final String initials = u['name']!
                    .split(' ')
                    .map((n) => n[0])
                    .take(2)
                    .join();

                Color roleColor = AppColors.accentTeal;
                if (u['role'] == 'MD') roleColor = Colors.redAccent;
                if (u['role'] == 'ZM') roleColor = Colors.blueAccent;
                if (u['role'] == 'ASM') roleColor = Colors.purpleAccent;
                if (u['role'] == 'BDM') roleColor = Colors.orangeAccent;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: roleColor.withOpacity(0.08),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    u['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${u['role']} • ${u['scope']}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      u['status']!,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildTasksSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- SM DASHBOARD VIEW (SM COMMAND CENTER) ---
  static final List<Map<String, dynamic>> _officeTelecallers = [];

  static final List<Map<String, dynamic>> _smRequests = [];

  static final List<Map<String, dynamic>> _processedPayments = [];

  static Map<String, dynamic> _monthlyTargetData = {};
  static final List<Map<String, dynamic>> _keralaRegions = [];

  Widget _buildSmOperationalCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: subtext,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeralaPerformanceRow({
    required String code,
    required String districts,
    required int leads,
    required int admissions,
    required int percentage,
    bool isOfficeTeam = false,
  }) {
    if (isOfficeTeam) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF5EEFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9D5FF)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            return Row(
              children: [
                const Icon(
                  Icons.corporate_fare_rounded,
                  color: Color(0xFF7C3AED),
                  size: 14,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Office Team',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                Container(
                  height: 12,
                  width: 1,
                  color: const Color(0xFFDDD6FE),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
                Expanded(
                  child: Text(
                    districts,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B21A8),
                    ),
                  ),
                ),
                Container(
                  height: 12,
                  width: 1,
                  color: const Color(0xFFDDD6FE),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isNarrow
                        ? '$admissions/$leads L'
                        : '$admissions/$leads Leads',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  height: 12,
                  width: 1,
                  color: const Color(0xFFDDD6FE),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
                SizedBox(
                  width: isNarrow ? 44 : 52,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100.0,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFDDD6FE),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B21A8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          return Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                height: 12,
                width: 1,
                color: const Color(0xFFE2E8F0),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              Expanded(
                child: Text(
                  districts,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                height: 12,
                width: 1,
                color: const Color(0xFFE2E8F0),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isNarrow
                      ? '$admissions/$leads L'
                      : '$admissions/$leads Leads',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                height: 12,
                width: 1,
                color: const Color(0xFFE2E8F0),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              SizedBox(
                width: isNarrow ? 44 : 52,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100.0,
                          minHeight: 4,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0EA5E9),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAssignTaskToAsmSheet(
    BuildContext context, {
    bool isForBde = false,
  }) {
    final asms = OperationsProvider.instance.smAsms;
    final bdes = OperationsProvider.instance.asmBdes;

    final List<Map<String, String>> employeeOptions = isForBde
        ? (bdes.isNotEmpty
              ? bdes.map((b) {
                  final label = b.district.isNotEmpty
                      ? '${b.name} (${b.district})'
                      : (b.employeeId.isNotEmpty
                            ? '${b.name} (${b.employeeId})'
                            : b.name);
                  return {
                    'value': label,
                    'label': label,
                    'id': b.id,
                    'name': b.name,
                    'code': b.employeeId,
                  };
                }).toList()
              : const [
                  {
                    'value': 'BDE Rahul (Ernakulam)',
                    'label': 'BDE Rahul (Ernakulam)',
                    'id': 'bde1',
                    'name': 'Rahul',
                    'code': 'BDE001',
                  },
                  {
                    'value': 'BDE Priya (Kottayam)',
                    'label': 'BDE Priya (Kottayam)',
                    'id': 'bde2',
                    'name': 'Priya',
                    'code': 'BDE002',
                  },
                ])
        : (asms.isNotEmpty
              ? asms.map((a) {
                  final label = a.districtsDisplay.isNotEmpty
                      ? '${a.name} (${a.districtsDisplay})'
                      : (a.code.isNotEmpty ? '${a.name} (${a.code})' : a.name);
                  return {
                    'value': label,
                    'label': label,
                    'id': a.id,
                    'name': a.name,
                    'code': a.code,
                  };
                }).toList()
              : const [
                  {
                    'value': 'Anjali Krishna (Ernakulam)',
                    'label': 'Anjali Krishna (Ernakulam)',
                    'id': 'asm1',
                    'name': 'Anjali Krishna',
                    'code': 'ASM001',
                  },
                  {
                    'value': 'Bipin Joseph (Trivandrum)',
                    'label': 'Bipin Joseph (Trivandrum)',
                    'id': 'asm2',
                    'name': 'Bipin Joseph',
                    'code': 'ASM002',
                  },
                  {
                    'value': 'Manoj Kumar (Kozhikode)',
                    'label': 'Manoj Kumar (Kozhikode)',
                    'id': 'asm3',
                    'name': 'Manoj Kumar',
                    'code': 'ASM003',
                  },
                  {
                    'value': 'Ramesh P. (Thrissur)',
                    'label': 'Ramesh P. (Thrissur)',
                    'id': 'asm4',
                    'name': 'Ramesh P.',
                    'code': 'ASM004',
                  },
                  {
                    'value': 'Deepa S. (Kollam)',
                    'label': 'Deepa S. (Kollam)',
                    'id': 'asm5',
                    'name': 'Deepa S.',
                    'code': 'ASM005',
                  },
                  {
                    'value': 'Shine J. (Kannur)',
                    'label': 'Shine J. (Kannur)',
                    'id': 'asm6',
                    'name': 'Shine J.',
                    'code': 'ASM006',
                  },
                ]);

    // Deduplicate options by value to avoid any duplicate assertion
    final seen = <String>{};
    final uniqueEmployeeOptions = employeeOptions
        .where((opt) => seen.add(opt['value']!))
        .toList();

    // ALL FIELDS ARE INITIALLY CLEARED (EMPTY)
    String? selectedEmployee;
    final taskTemplateController = TextEditingController();
    final targetController = TextEditingController();
    String selectedMetric = 'Leads';
    String selectedFrequency = 'Daily';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0F766E,
                                ).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in_rounded,
                                color: Color(0xFF0F766E),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isForBde
                                      ? 'Assign Task to BDE'
                                      : 'Assign Task to ASM',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  isForBde
                                      ? 'Assign custom task target to a BDE'
                                      : 'Assign custom task target to an ASM',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 24),

                    // 1. SELECT EMPLOYEE (CLEARED / EMPTY BY DEFAULT)
                    Text(
                      isForBde
                          ? 'SELECT BDE *'
                          : 'SELECT AREA SALES MANAGER (ASM) *',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text(
                            isForBde
                                ? 'Choose a BDE...'
                                : 'Choose an Area Sales Manager (ASM)...',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                          ),
                          value: selectedEmployee,
                          items: uniqueEmployeeOptions
                              .map(
                                (opt) => DropdownMenuItem<String>(
                                  value: opt['value'],
                                  child: Text(
                                    opt['label']!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setModalState(() => selectedEmployee = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. TASK TEMPLATE / TITLE (FREE-FORM TEXT INPUT - NOT PREDEFINED)
                    const Row(
                      children: [
                        Text(
                          'TASK TEMPLATE / TITLE *',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '(Custom)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: taskTemplateController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText:
                            'Enter task template / title (e.g. Spot Admission Drive)',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFF0F766E),
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0F766E),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick suggestion chips helper for quick entry
                    // Wrap(
                    //   spacing: 6,
                    //   runSpacing: 6,
                    //   children:
                    //       [
                    //             'Daily Lead Generation Campaign',
                    //             'Campus Awareness & Seminar',
                    //             'High School Outreach Drive',
                    //             'Spot Admission Campaign',
                    //             'Cold Calling Sprint',
                    //           ]
                    //           .map(
                    //             (s) => InkWell(
                    //               onTap: () {
                    //                 taskTemplateController.text = s;
                    //                 setModalState(() {});
                    //               },
                    //               borderRadius: BorderRadius.circular(6),
                    //               child: Container(
                    //                 padding: const EdgeInsets.symmetric(
                    //                   horizontal: 8,
                    //                   vertical: 3.5,
                    //                 ),
                    //                 decoration: BoxDecoration(
                    //                   color: const Color(0xFFF1F5F9),
                    //                   borderRadius: BorderRadius.circular(6),
                    //                   border: Border.all(
                    //                     color: const Color(0xFFE2E8F0),
                    //                   ),
                    //                 ),
                    //                 child: Text(
                    //                   '+ $s',
                    //                   style: const TextStyle(
                    //                     fontSize: 10.5,
                    //                     fontWeight: FontWeight.w600,
                    //                     color: Color(0xFF475569),
                    //                   ),
                    //                 ),
                    //               ),
                    //             ),
                    //           )
                    //           .toList(),
                    // ),
                    const SizedBox(height: 16),

                    // 3. TARGET QUANTITY & METRIC ROW
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TARGET QUANTITY *',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: targetController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  hintText: 'e.g. 50',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.track_changes_rounded,
                                    color: Color(0xFF0F766E),
                                    size: 18,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0F766E),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'METRIC TYPE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFFF8FAFC),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedMetric,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Leads',
                                        child: Text(
                                          'Leads',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Admissions',
                                        child: Text(
                                          'Admissions',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Visits',
                                        child: Text(
                                          'Visits',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Calls',
                                        child: Text(
                                          'Calls',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(
                                          () => selectedMetric = val,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. FREQUENCY / PERIOD
                    const Text(
                      'TARGET FREQUENCY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: ['Daily', 'Monthly'].map((freq) {
                        final isSelected = selectedFrequency == freq;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () {
                                setModalState(() => selectedFrequency = freq);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0F766E)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0F766E)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    freq,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 5. SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                // Validation
                                if (selectedEmployee == null ||
                                    selectedEmployee!.trim().isEmpty) {
                                  UiHelpers.showSnackBar(
                                    context,
                                    'Please select ${isForBde ? "a BDE" : "an Area Sales Manager"}',
                                    Colors.redAccent,
                                  );
                                  return;
                                }

                                final template = taskTemplateController.text
                                    .trim();
                                if (template.isEmpty) {
                                  UiHelpers.showSnackBar(
                                    context,
                                    'Please enter a task template / title',
                                    Colors.redAccent,
                                  );
                                  return;
                                }

                                final target = int.tryParse(
                                  targetController.text.trim(),
                                );
                                if (target == null || target <= 0) {
                                  UiHelpers.showSnackBar(
                                    context,
                                    'Please enter a valid target quantity',
                                    Colors.redAccent,
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                final empMatch = uniqueEmployeeOptions
                                    .firstWhere(
                                      (opt) => opt['value'] == selectedEmployee,
                                      orElse: () => {
                                        'name': selectedEmployee!,
                                        'code': '',
                                        'id': '',
                                      },
                                    );
                                final empName =
                                    empMatch['name'] ?? selectedEmployee!;
                                final empCode = empMatch['code'] ?? '';

                                // Add to HomeProvider
                                final newTask = PerformanceTask(
                                  id: 'task_${DateTime.now().millisecondsSinceEpoch}',
                                  title: template,
                                  taskTemplate: template,
                                  employee: empName,
                                  employeeId: empCode,
                                  metricType: selectedMetric.toLowerCase(),
                                  frequency: selectedFrequency.toLowerCase(),
                                  periodStart: DateTime.now()
                                      .toIso8601String()
                                      .substring(0, 10),
                                  periodEnd: DateTime.now()
                                      .toIso8601String()
                                      .substring(0, 10),
                                  baseTarget: target,
                                  carriedOver: 0,
                                  totalTarget: target,
                                  achieved: 0,
                                  isCompleted: false,
                                  completionPercentage: 0.0,
                                );
                                HomeProvider.instance.addPerformanceTask(
                                  newTask,
                                );

                                // Fire API if available in background
                                try {
                                  await ApiClient.instance.post(
                                    ApiEndpoints.performanceTasks,
                                    data: {
                                      'employee': empName,
                                      'employee_id': empCode,
                                      'title': template,
                                      'task_template': template,
                                      'target': target,
                                      'metric_type': selectedMetric
                                          .toLowerCase(),
                                      'frequency': selectedFrequency
                                          .toLowerCase(),
                                    },
                                  );
                                } catch (e) {
                                  debugPrint('[AssignTask] API call: $e');
                                }

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  UiHelpers.showSnackBar(
                                    context,
                                    'Task "$template" ($target $selectedMetric) assigned to $empName successfully!',
                                    Colors.green,
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Assign Task Now',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showSetMonthlyTargetSheet(BuildContext context) {
    String selectedMetric = 'Admissions Target';
    String selectedRegion = 'Kerala State Total';
    final targetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Set Monthly Target',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  const Text(
                    'SELECT METRIC TYPE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedMetric,
                        items: const [
                          DropdownMenuItem(
                            value: 'Admissions Target',
                            child: Text('Admissions Target'),
                          ),
                          DropdownMenuItem(
                            value: 'Total Leads Target',
                            child: Text('Total Leads Target'),
                          ),
                          DropdownMenuItem(
                            value: 'Conversion Rate % Target',
                            child: Text('Conversion Rate % Target'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null)
                            setModalState(() => selectedMetric = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TERRITORY / REGION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedRegion,
                        items: const [
                          DropdownMenuItem(
                            value: 'Kerala State Total',
                            child: Text('Kerala State Total'),
                          ),
                          DropdownMenuItem(
                            value: 'TVM (Thiruvananthapuram \u2022 Kollam)',
                            child: Text(
                              'TVM (Thiruvananthapuram \u2022 Kollam)',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'PTM (Pathanamthitta \u2022 Alappuzha)',
                            child: Text(
                              'PTM (Pathanamthitta \u2022 Alappuzha)',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'KTM (Kottayam \u2022 Idukki)',
                            child: Text('KTM (Kottayam \u2022 Idukki)'),
                          ),
                          DropdownMenuItem(
                            value: 'EKM (Ernakulam \u2022 Thrissur)',
                            child: Text('EKM (Ernakulam \u2022 Thrissur)'),
                          ),
                          DropdownMenuItem(
                            value: 'PKD (Palakkad \u2022 Malappuram)',
                            child: Text('PKD (Palakkad \u2022 Malappuram)'),
                          ),
                          DropdownMenuItem(
                            value: 'CLT (Kozhikode \u2022 Wayanad)',
                            child: Text('CLT (Kozhikode \u2022 Wayanad)'),
                          ),
                          DropdownMenuItem(
                            value: 'KZD (Kannur \u2022 Kasaragod)',
                            child: Text('KZD (Kannur \u2022 Kasaragod)'),
                          ),
                          DropdownMenuItem(
                            value: 'Office Team (Tele-calling)',
                            child: Text('Office Team (Tele-calling)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null)
                            setModalState(() => selectedRegion = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MONTHLY TARGET VALUE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 150',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        final valText = targetController.text.trim();
                        final parsedVal = int.tryParse(valText);
                        if (parsedVal == null || parsedVal <= 0) {
                          UiHelpers.showSnackBar(
                            context,
                            'Please enter a valid monthly target value',
                            Colors.redAccent,
                          );
                          return;
                        }
                        if (selectedMetric.contains('Lead')) {
                          _monthlyTargetData['target_leads'] = parsedVal;
                          OperationsProvider.instance.setMonthlyTarget(
                            leads: parsedVal,
                          );
                        } else if (selectedMetric.contains('Admission')) {
                          _monthlyTargetData['target_admissions'] = parsedVal;
                          OperationsProvider.instance.setMonthlyTarget(
                            admissions: parsedVal,
                          );
                        } else {
                          _monthlyTargetData['team_follow_up'] = parsedVal;
                          OperationsProvider.instance.refreshTargetState();
                        }
                        Navigator.pop(ctx);
                        UiHelpers.showSnackBar(
                          context,
                          'Target of $parsedVal for $selectedRegion saved successfully!',
                          Colors.green,
                        );
                      },
                      child: const Text(
                        'Save Monthly Target',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRequestsAndApprovalsSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RequestsApprovalsScreen()),
    );
    if (!context.mounted) return;
    // Sync with OperationsProvider smPayoutRequests
    final providerRequests = OperationsProvider.instance.smPayoutRequests;
    for (final pr in providerRequests) {
      final exists = _smRequests.any((r) => r['id'] == pr.id);
      if (!exists) {
        _smRequests.insert(0, {
          'id': pr.id,
          'title': '${pr.employeeName} (${pr.employeeId})',
          'role': pr.designation,
          'type': '${pr.type} Approval',
          'amount': pr.formattedAmount,
          'raw_amount': pr.amount,
          'status': pr.status == 'Pending_SM' ? 'Pending Review' : pr.status,
          'details': pr.notes ?? '${pr.type} request awaiting SM verification',
          'date': pr.submittedAt ?? 'Today',
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3E8FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Color(0xFF7C3AED),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Requests & Approvals',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Text(
                    '${_smRequests.where((r) => r['status'] == 'Pending Review').length} requests awaiting your review & forward',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 24),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _smRequests.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Color(0xFFE2E8F0), height: 16),
                      itemBuilder: (context, index) {
                        final req = _smRequests[index];
                        final isPending = req['status'] == 'Pending Review';
                        final isForwarded =
                            req['status'] == 'Forwarded to Accounts';
                        final isPaid = req['status'] == 'Paid & Verified';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isForwarded
                                        ? const Color(0xFFF3E8FF)
                                        : isPaid
                                        ? Colors.green.shade50
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isForwarded
                                        ? Icons.forward_to_inbox_rounded
                                        : isPaid
                                        ? Icons.check_circle_rounded
                                        : Icons.receipt_long_rounded,
                                    color: isForwarded
                                        ? const Color(0xFF7C3AED)
                                        : isPaid
                                        ? Colors.green
                                        : const Color(0xFFD97706),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            (req['title'] ?? '').toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              (req['role'] ?? '').toString(),
                                              style: const TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${req['type']} \u2022 ${req['amount']}',
                                        style: const TextStyle(
                                          color: Color(0xFF0F766E),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        (req['details'] ?? '').toString(),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isPending) ...[
                                  IconButton(
                                    tooltip: 'Approve Directly',
                                    icon: const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        req['status'] = 'Approved by SM';
                                      });
                                      UiHelpers.showSnackBar(
                                        ctx,
                                        'Request approved by SM!',
                                        Colors.green,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Reject',
                                    icon: const Icon(
                                      Icons.cancel_rounded,
                                      color: Colors.redAccent,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        req['status'] = 'Rejected by SM';
                                      });
                                      UiHelpers.showSnackBar(
                                        ctx,
                                        'Request rejected',
                                        Colors.redAccent,
                                      );
                                    },
                                  ),
                                ] else if (isForwarded)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E8FF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE9D5FF),
                                      ),
                                    ),
                                    child: const Text(
                                      'Forwarded to Accounts',
                                      style: TextStyle(
                                        color: Color(0xFF7C3AED),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else if (isPaid)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Paid & Verified',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (isPending) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C3AED),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () async {
                                    final reqId = req['id']?.toString() ?? '';
                                    final reqType =
                                        req['type']?.toString() ?? '';
                                    final isSalary = reqType
                                        .toLowerCase()
                                        .contains('salary');

                                    if (isSalary) {
                                      await OperationsProvider.instance
                                          .forwardSalaryToAccounts(reqId);
                                    } else {
                                      await OperationsProvider.instance
                                          .forwardIncentiveToAccounts(reqId);
                                    }

                                    setModalState(() {
                                      req['status'] = 'Forwarded to Accounts';
                                    });
                                    UiHelpers.showSnackBar(
                                      ctx,
                                      'Request for ${req['title']} forwarded to Accounts for payment verification!',
                                      Colors.purple,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.forward_to_inbox_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Forward to Accounts',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }

  Widget _buildSmDisplayMetricsCard(
    BuildContext context, [
    OperationsProvider? provider,
  ]) {
    final int dynamicTargetLeads = (data.target != null && data.target!.monthlyTarget > 0)
        ? data.target!.monthlyTarget
        : (data.monthlyTargetLeads > 0
            ? data.monthlyTargetLeads
            : (data.rawJson?['targets']?['monthly_target'] != null
                ? UiHelpers.parseInt(data.rawJson!['targets']['monthly_target'])
                : (data.rawJson?['performance_bar']?['assigned_target'] != null
                    ? UiHelpers.parseInt(data.rawJson!['performance_bar']['assigned_target'])
                    : (provider?.customMonthlyTargetLeads ??
                        (provider != null && provider.smAsms.isNotEmpty
                            ? provider.smAsms.fold(0, (sum, a) => sum + a.monthlyTarget)
                            : (_monthlyTargetData['target_leads'] ?? 0))))));

    final int dynamicTargetAdmissions =
        (data.target != null && data.target!.targetAdmissions > 0)
        ? data.target!.targetAdmissions
        : (data.monthlyTargetAdmissions > 0
              ? data.monthlyTargetAdmissions
              : (provider?.customMonthlyTargetAdmissions ??
                    (provider != null && provider.smAsms.isNotEmpty
                        ? provider.smAsms.fold(
                            0,
                            (sum, a) => sum + a.monthlyAchieved,
                          )
                        : (_monthlyTargetData['target_admissions'] ?? 0))));

    final int totalMonthlyLeads =
        data.teamMetrics?.teamLeads ??
        data.operationalOverview?.assignedLeads ??
        data.totalMonthlyLeadsCount;

    final int teamFollowUp =
        data.operationalOverview?.followUpLeads ?? data.teamFollowUpCount;

    final int pendingFollowUps =
        data.teamMetrics?.visitsPending ??
        data.tasks?.pending ??
        data.pendingFollowUpsCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        size: 16,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Target & Follow-ups',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'State team active tracking display',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'MONTHLY TARGET',
                  value: '$dynamicTargetLeads',
                  unit: dynamicTargetAdmissions > 0 ? 'Leads ($dynamicTargetAdmissions Adm.)' : 'Target Leads',
                  icon: Icons.flag_rounded,
                  color: const Color(0xFF0F766E),
                  bgColor: const Color(0xFFF0FDFA),
                  onTap: null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'TOTAL MONTHLY LEAD',
                  value: '$totalMonthlyLeads',
                  unit: 'Leads Generated',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFF0F9FF),
                  onTap: null,
                  // onTap: () => HomeProvider.instance.setCurrentIndex(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'TEAM FOLLOW-UP',
                  value: '$teamFollowUp',
                  unit: 'Calls & Visits Done',
                  icon: Icons.phone_in_talk_rounded,
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFFAF5FF),
                  // onTap: () => HomeProvider.instance.setCurrentIndex(1),
                  onTap: null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'PENDING FOLLOW-UPS',
                  value: '$pendingFollowUps',
                  unit: 'Awaiting Response',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFFFBEB),
                  // onTap: () => HomeProvider.instance.setCurrentIndex(1),
                  onTap: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openAddTelecallerDialog(
    BuildContext context,
    StateSetter setParentState,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String? selectedDistrict;
    bool isPasswordVisible = false;
    bool isSubmitting = false;

    final districts = OperationsProvider.instance.allDistrictNames;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Color(0xFF7C3AED),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Telecaller',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Create member under Office Team',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    splashRadius: 18,
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name
                        const Text(
                          'FULL NAME *',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'e.g. Ananya Nair',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              size: 18,
                              color: Color(0xFF7C3AED),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF7C3AED),
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter telecaller name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Email Address
                        const Text(
                          'EMAIL ADDRESS *',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'e.g. ananya.tc@kide.com',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: Color(0xFF7C3AED),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF7C3AED),
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter email address';
                            }
                            if (!val.contains('@') || !val.contains('.')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Phone Number
                        const Text(
                          'CONTACT NUMBER *',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'e.g. +91 98471 11223',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              size: 18,
                              color: Color(0xFF7C3AED),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF7C3AED),
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter contact number';
                            }
                            final digitsOnly = val.replaceAll(
                              RegExp(r'\D'),
                              '',
                            );
                            if (digitsOnly.length < 10) {
                              return 'Please enter a valid 10-digit number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Password with Show/Hide toggle
                        const Text(
                          'PASSWORD *',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Enter login password (min 6 chars)',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: Color(0xFF7C3AED),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                size: 18,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF7C3AED),
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please set a password';
                            }
                            if (val.trim().length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // District Selection (loaded from /districts API, cleared initially)
                        const Text(
                          'DISTRICT *',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: selectedDistrict,
                          decoration: InputDecoration(
                            hintText: 'Select District...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: Color(0xFF7C3AED),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF7C3AED),
                                width: 1.5,
                              ),
                            ),
                          ),
                          items: districts.map((dist) {
                            return DropdownMenuItem<String>(
                              value: dist,
                              child: Text(
                                dist,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please select a district';
                            }
                            return null;
                          },
                          onChanged: (val) {
                            setDialogState(() => selectedDistrict = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          final name = nameController.text.trim();
                          final email = emailController.text.trim();
                          final phone = phoneController.text.trim();
                          final password = passwordController.text.trim();
                          final district = selectedDistrict!;

                          final res = await OperationsProvider.instance
                              .createTelecaller(
                                name: name,
                                email: email,
                                phone: phone,
                                password: password,
                                district: district,
                              );

                          final bool success = res['success'] == true;
                          final String message =
                              res['message']?.toString() ??
                              'Tele-caller $name created successfully under Office Team.';
                          final caller =
                              res['telecaller'] as OfficeTelecallerModel?;

                          if (success && caller != null) {
                            _officeTelecallers.insert(0, {
                              'id': caller.id,
                              'employee_id': caller.employeeId,
                              'name': caller.name,
                              'phone': caller.contactNumber,
                              'email': caller.email,
                              'district': caller.district ?? district,
                              'shift': caller.shift,
                              'calls_today': 0,
                              'leads_generated': 0,
                              'admissions': 0,
                              'base_salary': caller.baseSalary,
                              'incentive_per_admission':
                                  caller.incentivePerAdmission,
                              'monthly_target': caller.monthlyTarget,
                            });
                            setParentState(() {});
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            if (context.mounted) {
                              UiHelpers.showSnackBar(
                                context,
                                message,
                                Colors.green,
                              );
                            }
                          } else {
                            setDialogState(() => isSubmitting = false);
                            if (context.mounted) {
                              UiHelpers.showSnackBar(
                                context,
                                message,
                                Colors.redAccent,
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Add Telecaller',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openEditSalaryIncentiveDialog(
    BuildContext context,
    Map<String, dynamic> tc,
    StateSetter setParentState,
  ) {
    final salaryController = TextEditingController(
      text: '${tc['base_salary']}',
    );
    final incentiveController = TextEditingController(
      text: '${tc['incentive_per_admission']}',
    );
    final targetController = TextEditingController(
      text: '${tc['monthly_target']}',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF0F766E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Set Salary & Incentive: ${tc['name']}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BASE SALARY (\u20B9 / MONTH)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: salaryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'INCENTIVE PER ADMISSION (\u20B9)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: incentiveController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'MONTHLY TARGET (ADMISSIONS)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                tc['base_salary'] =
                    int.tryParse(salaryController.text) ?? tc['base_salary'];
                tc['incentive_per_admission'] =
                    int.tryParse(incentiveController.text) ??
                    tc['incentive_per_admission'];
                tc['monthly_target'] =
                    int.tryParse(targetController.text) ?? tc['monthly_target'];
                setParentState(() {});
                Navigator.pop(dialogCtx);
                UiHelpers.showSnackBar(
                  context,
                  'Salary and incentive options updated for ${tc['name']}!',
                  Colors.green,
                );
              },
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showManageOfficeTeamSheet(BuildContext context) {
    // Sync with OperationsProvider officeTelecallers
    final providerCallers = OperationsProvider.instance.officeTelecallers;
    for (final pc in providerCallers) {
      final exists = _officeTelecallers.any(
        (tc) => tc['id'] == pc.id || tc['id'] == pc.employeeId,
      );
      if (!exists) {
        _officeTelecallers.insert(0, {
          'id': pc.id,
          'name': pc.name,
          'phone': pc.contactNumber,
          'email': pc.email,
          'shift': pc.shift,
          'calls_today': pc.callsToday,
          'leads_generated': pc.leadsAssigned,
          'admissions': pc.admissionsClosed,
          'base_salary': pc.baseSalary,
          'incentive_per_admission': pc.incentivePerAdmission,
          'monthly_target': pc.monthlyTarget,
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int totalCalls = _officeTelecallers.fold(
              0,
              (sum, item) => sum + ((item['calls_today'] as int?) ?? 0),
            );
            int totalLeads = _officeTelecallers.fold(
              0,
              (sum, item) => sum + ((item['leads_generated'] as int?) ?? 0),
            );
            int totalAdmissions = _officeTelecallers.fold(
              0,
              (sum, item) => sum + ((item['admissions'] as int?) ?? 0),
            );

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3E8FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.corporate_fare_rounded,
                              color: Color(0xFF7C3AED),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Office Team',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Direct reporting under Sales Manager (SM)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Summary Banner
                  // Container(
                  //   padding: const EdgeInsets.all(12),
                  //   decoration: BoxDecoration(
                  //     color: const Color(0xFFF5EEFD),
                  //     borderRadius: BorderRadius.circular(16),
                  //     border: Border.all(color: const Color(0xFFE9D5FF)),
                  //   ),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //     children: [
                  //       _buildOfficeStatItem(
                  //         'CALLERS',
                  //         '${_officeTelecallers.length}',
                  //         const Color(0xFF7C3AED),
                  //       ),
                  //       _buildOfficeStatItem(
                  //         'CALLS TODAY',
                  //         '$totalCalls',
                  //         const Color(0xFF0284C7),
                  //       ),
                  //       _buildOfficeStatItem(
                  //         'LEADS',
                  //         '$totalLeads',
                  //         const Color(0xFF0F766E),
                  //       ),
                  //       _buildOfficeStatItem(
                  //         'ADMISSIONS',
                  //         '$totalAdmissions',
                  //         const Color(0xFF16A34A),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Office Team',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () =>
                            _openAddTelecallerDialog(context, setModalState),
                        icon: const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        label: const Text(
                          'Add Member',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _officeTelecallers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tc = _officeTelecallers[index];
                        final int admissions = tc['admissions'] as int? ?? 0;
                        final int incentivePerAdmission =
                            tc['incentive_per_admission'] as int? ?? 500;
                        final int baseSalary =
                            tc['base_salary'] as int? ?? 18000;
                        final int projectedPayout =
                            baseSalary + (admissions * incentivePerAdmission);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEDE9FE),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.headset_mic_rounded,
                                          color: Color(0xFF7C3AED),
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tc['name']?.toString() ??
                                                'Telecaller',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            (tc['shift'] ??
                                                    tc['district'] ??
                                                    'Office Team')
                                                .toString(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Target: ${tc['monthly_target']} Adm.',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildMiniStat(
                                      'Calls Today',
                                      '${tc['calls_today']}',
                                    ),
                                    _buildMiniStat(
                                      'Leads Gen.',
                                      '${tc['leads_generated']}',
                                    ),
                                    _buildMiniStat('Admissions', '$admissions'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Salary & Incentive options display
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFBBF7D0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Base: \u20B9${NumberFormat('#,##,###').format(baseSalary)} | Incentive: \u20B9$incentivePerAdmission/Adm.',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF166534),
                                          ),
                                        ),
                                        Text(
                                          'Projected Payout: \u20B9${NumberFormat('#,##,###').format(projectedPayout)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF15803D),
                                          ),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          _openEditSalaryIncentiveDialog(
                                            context,
                                            tc,
                                            setModalState,
                                          ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF16A34A),
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.edit_rounded,
                                              size: 11,
                                              color: Color(0xFF16A34A),
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Set Options',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF16A34A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOfficeStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _openVerifyPaymentDialog(
    BuildContext context,
    Map<String, dynamic> req,
    StateSetter setParentState,
  ) {
    String selectedMode = 'NEFT Bank Transfer';
    final txnController = TextEditingController(
      text:
          'TXN_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
    );
    final notesController = TextEditingController(
      text: 'Verified by Accounts Department',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Verify & Process Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (req['title'] ?? '').toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${req['type']} \u2022 ${req['amount']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'PAYMENT MODE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedMode,
                          items: const [
                            DropdownMenuItem(
                              value: 'NEFT Bank Transfer',
                              child: Text('NEFT Bank Transfer'),
                            ),
                            DropdownMenuItem(
                              value: 'UPI / IMPS Transfer',
                              child: Text('UPI / IMPS Transfer'),
                            ),
                            DropdownMenuItem(
                              value: 'Salary Direct Credit',
                              child: Text('Salary Direct Credit'),
                            ),
                            DropdownMenuItem(
                              value: 'Cheque Disbursement',
                              child: Text('Cheque Disbursement'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null)
                              setDialogState(() => selectedMode = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TRANSACTION / UTR NUMBER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: txnController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'REMARKS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    req['status'] = 'Paid & Verified';
                    _processedPayments.insert(0, {
                      'id':
                          'PAY_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                      'recipient': req['title'],
                      'type': req['type'],
                      'amount': req['raw_amount'] ?? 10000,
                      'mode': selectedMode,
                      'transaction_id': txnController.text.trim(),
                      'status': 'Verified & Paid',
                      'date': DateFormat('dd MMM yyyy').format(DateTime.now()),
                    });
                    setParentState(() {});
                    Navigator.pop(dialogCtx);
                    UiHelpers.showSnackBar(
                      context,
                      'Payment of ${req['amount']} successfully verified and processed!',
                      Colors.green,
                    );
                  },
                  child: const Text(
                    'Confirm & Pay',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCalculationStepCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCalculationsCard() {
    const int admissions = 36;
    const int incomePerAdmission = 45000;
    const int grossIncome = admissions * incomePerAdmission; // 1,620,000
    const int salaries = 320000;
    const int incentives = 165000;
    const int totalDeductions = salaries + incentives; // 485,000
    const int netProfit = grossIncome - totalDeductions; // 1,135,000
    final double profitMargin = (netProfit / grossIncome) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: Color(0xFF16A34A),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial & Profit Calculations',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Total Admission \u00D7 Total Income \u2212 (Incentive + Salary)',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${profitMargin.toStringAsFixed(1)}% PROFIT MARGIN',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: Color(0xFFF1F5F9)),
          // Profit formula highlight banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL NET PROFIT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Accounts Verified Formula',
                      style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\u20B9${NumberFormat('#,##,###').format(netProfit)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4ADE80),
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFF4ADE80),
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Profitable Operations',
                          style: TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '36 Admissions \u00D7 \u20B945,000 \u2212 (\u20B93,20,000 Salary + \u20B91,65,000 Incentive) = \u20B911,35,000 Profit',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 4 Breakdown rows
          Row(
            children: [
              Expanded(
                child: _buildCalculationStepCard(
                  title: 'TOTAL ADMISSIONS',
                  value: '$admissions Closed',
                  sub: '@ \u20B945,000 fee',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFF0F9FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCalculationStepCard(
                  title: 'GROSS INCOME',
                  value:
                      '\u20B9${NumberFormat('#,##,###').format(grossIncome)}',
                  sub: 'Total Revenue',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFF0FDF4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildCalculationStepCard(
                  title: 'STAFF SALARIES',
                  value: '\u20B9${NumberFormat('#,##,###').format(salaries)}',
                  sub: 'Base Payroll Deductions',
                  icon: Icons.badge_rounded,
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFFFBEB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCalculationStepCard(
                  title: 'INCENTIVES DISBURSED',
                  value: '\u20B9${NumberFormat('#,##,###').format(incentives)}',
                  sub: 'Performance Bonuses',
                  icon: Icons.card_giftcard_rounded,
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFFAF5FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void showAccountsVerificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0F766E,
                                ).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Color(0xFF0F766E),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Accounts & Payments Portal',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Payment verification, incentives & profit calculations',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),

                    // 1. Profit Calculations Card
                    _buildProfitCalculationsCard(),
                    const SizedBox(height: 24),

                    // 2. SM Payment Requests Verification Queue
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Requests from SM',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_smRequests.where((r) => r['status'] != 'Paid & Verified').length} Pending Verification',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Verify and disburse incentive/travel requests forwarded by SM',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._smRequests.map((req) {
                      final isPaid = req['status'] == 'Paid & Verified';
                      final isForwarded =
                          req['status'] == 'Forwarded to Accounts';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? const Color(0xFFF8FAFC)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPaid
                                ? const Color(0xFFE2E8F0)
                                : isForwarded
                                ? const Color(0xFFC084FC)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? Colors.green.shade50
                                    : isForwarded
                                    ? const Color(0xFFF3E8FF)
                                    : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isPaid
                                    ? Icons.check_circle_rounded
                                    : isForwarded
                                    ? Icons.forward_to_inbox_rounded
                                    : Icons.pending_rounded,
                                color: isPaid
                                    ? Colors.green
                                    : isForwarded
                                    ? const Color(0xFF7C3AED)
                                    : const Color(0xFFD97706),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        (req['title'] ?? '').toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          (req['role'] ?? '').toString(),
                                          style: const TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${req['type']} \u2022 ${req['amount']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F766E),
                                    ),
                                  ),
                                  Text(
                                    (req['details'] ?? '').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isPaid)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => _openVerifyPaymentDialog(
                                  context,
                                  req,
                                  setModalState,
                                ),
                                child: const Text(
                                  'Verify & Pay',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 12,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    // 3. Processed Payments Ledger
                    const Text(
                      'Recent Verified Disbursements',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._processedPayments.map((pay) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (pay['recipient'] ?? '').toString(),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '${pay['mode']} \u2022 ${pay['transaction_id']}',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\u20B9${NumberFormat('#,##,###').format(pay['amount'])}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                Text(
                                  (pay['date'] ?? '').toString(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- SM DASHBOARD VIEW MAIN ---
  Widget _buildSmDashboard(BuildContext context, OperationsProvider provider) {
    final int totalLeads =
        data.teamMetrics?.teamLeads ??
        data.operationalOverview?.assignedLeads ??
        data.totalMonthlyLeadsCount;
    final int totalAdmissions =
        data.teamMetrics?.teamAdmissions ??
        data.operationalOverview?.closedLeads ??
        data.admittedLeadsCount;
    final int pendingRequests = provider.walletApprovalRequests
        .where((r) => r.isPending)
        .length;
    final num incentives =
        data.operationalOverview?.incentivesEarned ?? data.walletBalance;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600 ? 32 : 16,
        vertical: 15,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Shift Attendance Card
              _buildAttendanceSection(context, data.attendance),

              // 2. SM Display Metrics (Set team target, total monthly lead, team follow-up, pending follow-ups)
              _buildSmDisplayMetricsCard(context, provider),

              // 3. Operational Overview
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
                      ? 1.55
                      : (width < 345 ? 1.15 : (width < 380 ? 1.25 : 1.35));

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: aspectRatio,
                    children: [
                      _buildSmOperationalCard(
                        title: 'TOTAL LEADS',
                        value: '$totalLeads',
                        subtext: 'Active',
                        icon: Icons.groups_outlined,
                        iconColor: const Color(0xFF0284C7),
                        iconBgColor: const Color(0xFFE0F2FE),
                        //onTap: () => HomeProvider.instance.setCurrentIndex(1),
                        onTap: () {},
                      ),
                      _buildSmOperationalCard(
                        title: 'TOTAL ADMISSIONS',
                        value: '$totalAdmissions',
                        subtext: 'Closed',
                        icon: Icons.school_outlined,
                        iconColor: const Color(0xFF16A34A),
                        iconBgColor: const Color(0xFFDCFCE7),
                        // onTap: () => HomeProvider.instance.setCurrentIndex(
                        //   1,
                        //   initialTaskTabIndex: 1,
                        // ),
                        onTap: () {},
                      ),
                      _buildSmOperationalCard(
                        title: 'PENDING ASM REQUESTS',
                        value: '$pendingRequests',
                        subtext: 'Pending',
                        icon: Icons.access_time_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBgColor: const Color(0xFFFEF3C7),
                        //onTap: () => _showRequestsAndApprovalsSheet(context),
                        onTap: () {},
                      ),
                      _buildSmOperationalCard(
                        title: 'INCENTIVES',
                        value:
                            '\u20B9${NumberFormat('#,##,###').format(incentives.toInt())}',
                        subtext: 'Earned',
                        icon: Icons.card_giftcard_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        iconBgColor: const Color(0xFFF3E8FF),
                        onTap: () => HomeProvider.instance.setCurrentIndex(2),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // 4. Kerala Team Performance
              StatefulBuilder(
                builder: (context, setPerformanceState) {
                  final isDaily = _keralaPerformancePeriod == 'Daily';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Team Performance',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => showCreateAsmSheet(
                                  context,
                                  teams: data.teams,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF0F766E,
                                    ).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF0F766E,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.person_add_alt_1_rounded,
                                        size: 14,
                                        color: Color(0xFF0F766E),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Add ASM',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Filter Segment (Daily vs Monthly)
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setPerformanceState(() {
                                          _keralaPerformancePeriod = 'Daily';
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 4.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDaily
                                              ? const Color(0xFF0F766E)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: isDaily
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF0F766E,
                                                    ).withOpacity(0.25),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.today_rounded,
                                              size: 13,
                                              color: isDaily
                                                  ? Colors.white
                                                  : const Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Daily',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isDaily
                                                    ? Colors.white
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setPerformanceState(() {
                                          _keralaPerformancePeriod = 'Monthly';
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 4.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: !isDaily
                                              ? const Color(0xFF0F766E)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: !isDaily
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF0F766E,
                                                    ).withOpacity(0.25),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_month_rounded,
                                              size: 13,
                                              color: !isDaily
                                                  ? Colors.white
                                                  : const Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Monthly',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: !isDaily
                                                    ? Colors.white
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (provider.smAsms.isNotEmpty)
                              ...provider.smAsms.map(
                                (asm) => _buildKeralaPerformanceRow(
                                  code: asm.code,
                                  districts: asm.districtsDisplay,
                                  leads: isDaily
                                      ? asm.dailyTarget
                                      : asm.monthlyTarget,
                                  admissions: isDaily
                                      ? asm.dailyAchieved
                                      : asm.monthlyAchieved,
                                  percentage: isDaily
                                      ? asm.dailyCompletionPercentage
                                      : asm.monthlyCompletionPercentage,
                                  isOfficeTeam: asm.code.toUpperCase() == 'OFFICE' ||
                                      asm.team.toLowerCase().contains('office'),
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'No ASM teams found',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            // ➢ LAST PERCENTAGE BAR : Total performance vs total completed lead percentage
                            Container(
                              margin: const EdgeInsets.only(top: 14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF0F172A).withOpacity(0.04),
                                    const Color(0xFF7C3AED).withOpacity(0.06),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF0EA5E9,
                                                ).withOpacity(0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.analytics_rounded,
                                                size: 14,
                                                color: Color(0xFF0284C7),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Total Performance",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 11,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  // Text(
                                                  //   isDaily
                                                  //       ? "Real-time State Daily Target Realization"
                                                  //       : "Overall State Monthly Target Conversion Ratio",
                                                  //   maxLines: 1,
                                                  //   overflow:
                                                  //       TextOverflow.ellipsis,
                                                  //   style: const TextStyle(
                                                  //     fontSize: 9.5,
                                                  //     color: AppColors
                                                  //         .textSecondary,
                                                  //   ),
                                                  // ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Builder(
                                        builder: (context) {
                                          final asms = provider.smAsms;
                                          final int totalAchieved =
                                              asms.isNotEmpty
                                              ? (asms.fold(
                                                  0,
                                                  (sum, a) =>
                                                      sum + (a.monthlyAchieved),
                                                ))
                                              : ((data
                                                        .target
                                                        ?.monthlyAchieved ??
                                                    0));
                                          final int totalTarget =
                                              (data.target != null && data.target!.monthlyTarget > 0)
                                              ? data.target!.monthlyTarget
                                              : (data.monthlyTargetLeads > 0
                                                  ? data.monthlyTargetLeads
                                                  : (asms.isNotEmpty
                                                      ? asms.fold(0, (sum, a) => sum + a.monthlyTarget)
                                                      : 0));
                                          final int totalPct = totalTarget == 0
                                              ? 0
                                              : ((totalAchieved / totalTarget) *
                                                        100)
                                                    .round();

                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: totalPct >= 50
                                                  ? const Color(0xFFDCFCE7)
                                                  : const Color(0xFFFEF3C7),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '$totalPct% ${"ON TRACK"}',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                color: totalPct >= 50
                                                    ? const Color(0xFF16A34A)
                                                    : const Color(0xFFD97706),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Builder(
                                    builder: (context) {
                                      final asms = provider.smAsms;
                                      final int totalAchieved = asms.isNotEmpty
                                          ? (asms.fold(
                                              0,
                                              (sum, a) =>
                                                  sum +
                                                  (isDaily
                                                      ? a.dailyAchieved
                                                      : a.monthlyAchieved),
                                            ))
                                          : (isDaily
                                                ? (data.target?.dailyAchieved ??
                                                      0)
                                                : (data
                                                          .target
                                                          ?.monthlyAchieved ??
                                                      0));
                                      final int totalTarget = isDaily
                                          ? ((data.target != null && data.target!.dailyTarget > 0)
                                              ? data.target!.dailyTarget
                                              : (asms.isNotEmpty
                                                  ? asms.fold(0, (sum, a) => sum + a.dailyTarget)
                                                  : 0))
                                          : ((data.target != null && data.target!.monthlyTarget > 0)
                                              ? data.target!.monthlyTarget
                                              : (data.monthlyTargetLeads > 0
                                                  ? data.monthlyTargetLeads
                                                  : (asms.isNotEmpty
                                                      ? asms.fold(0, (sum, a) => sum + a.monthlyTarget)
                                                      : 0)));

                                      final int totalPct = totalTarget == 0
                                          ? 0
                                          : ((totalAchieved / totalTarget) *
                                                    100)
                                                .round();

                                      final double progressVal = totalTarget > 0
                                          ? (totalAchieved / totalTarget).clamp(
                                              0.0,
                                              1.0,
                                            )
                                          : 0.7;

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    '$totalAchieved Achieved Leads',
                                                    style: const TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    '${isDaily ? "Daily" : "Monthly"} Target: $totalTarget Leads ($totalPct%)',
                                                    style: const TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Color(0xFF7C3AED),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: progressVal,
                                              minHeight: 8,
                                              backgroundColor: const Color(
                                                0xFFE2E8F0,
                                              ),
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Color(0xFF7C3AED)),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // 5. Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF1E3A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F766E).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _showAssignTaskToAsmSheet(context),
                        icon: const Icon(
                          Icons.assignment_turned_in_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Assign Tasks',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _showManageOfficeTeamSheet(context),
                        icon: const Icon(
                          Icons.corporate_fare_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Office Team ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 6. Requests & Approvals
              const Text(
                'Requests & Approvals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showRequestsAndApprovalsSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Color(0xFF7C3AED),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Salary / Incentive requests',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$pendingRequests awaiting review',
                              style: const TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }

  // --- ACCOUNTS & ADMIN DASHBOARD VIEW ---
  Widget _buildAccountsAdminDashboard(
    BuildContext context,
    OperationsProvider provider,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Shift Attendance Card
          _buildAttendanceSection(context, data.attendance),

          // 2. Accounts Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accounts & Finance Command',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Payment verification, incentives & profit calculations',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 12,
                      color: Color(0xFF16A34A),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'ACCOUNTS HEAD',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Profit Calculations Card
          _buildProfitCalculationsCard(),
          const SizedBox(height: 24),

          // 4. SM Requests Verification Queue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SM Requests Verification Queue',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_smRequests.where((r) => r['status'] != 'Paid & Verified').length} Pending',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StatefulBuilder(
            builder: (context, setAccountsState) {
              return Column(
                children: _smRequests.map((req) {
                  final isPaid = req['status'] == 'Paid & Verified';
                  final isForwarded = req['status'] == 'Forwarded to Accounts';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPaid ? const Color(0xFFF8FAFC) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isPaid
                            ? const Color(0xFFE2E8F0)
                            : isForwarded
                            ? const Color(0xFFC084FC)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? Colors.green.shade50
                                : isForwarded
                                ? const Color(0xFFF3E8FF)
                                : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isPaid
                                ? Icons.check_circle_rounded
                                : isForwarded
                                ? Icons.forward_to_inbox_rounded
                                : Icons.pending_rounded,
                            color: isPaid
                                ? Colors.green
                                : isForwarded
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFFD97706),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    (req['title'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      (req['role'] ?? '').toString(),
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${req['type']} \u2022 ${req['amount']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              Text(
                                (req['details'] ?? '').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isPaid)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _openVerifyPaymentDialog(
                              context,
                              req,
                              setAccountsState,
                            ),
                            child: const Text(
                              'Verify & Pay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Paid & Verified',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // 5. Office Team Payroll & Incentive Option
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Office Team (Telecallers Payroll)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Direct office staff under SM supervision',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showManageOfficeTeamSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Manage Roster',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: _officeTelecallers.map((tc) {
                final base = tc['base_salary'] as int? ?? 18000;
                final inc =
                    (tc['admissions'] as int? ?? 0) *
                    (tc['incentive_per_admission'] as int? ?? 500);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3E8FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tc['name']?.toString() ?? 'Telecaller',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Base: \u20B9${NumberFormat('#,##,###').format(base)} \u2022 Inc: \u20B9${NumberFormat('#,##,###').format(inc)} (${tc['admissions']} Adm.)',
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Total: \u20B9${NumberFormat('#,##,###').format(base + inc)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // 6. Recent Verified Disbursements Ledger
          const Text(
            'Verified Payment Records Ledger',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ..._processedPayments.map((pay) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (pay['recipient'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${pay['mode']} \u2022 ${pay['transaction_id']}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\u20B9${NumberFormat('#,##,###').format(pay['amount'])}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      Text(
                        (pay['date'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 35),
        ],
      ),
    );
  }

  Widget _buildZmDashboard(BuildContext context, OperationsProvider provider) {
    final zone = user.zone ?? 'Central Zone';
    final List<Map<String, dynamic>> rawDistricts = provider.districts;
    final List<Map<String, dynamic>> distList = [
      {'id': null, 'name': 'All Districts'},
    ];
    distList.addAll(rawDistricts);

    final selectedDistrictId = HomeProvider.instance.selectedDistrictId;
    final currentSelected = distList.firstWhere(
      (d) => d['id'] == selectedDistrictId,
      orElse: () => {'id': null, 'name': 'All Districts'},
    );

    final teamMetrics = data.teamMetrics;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardHeader(
            title: '$zone Manager Desk',
            subtitle: 'Territory Reports & District Overview',
          ),
          const SizedBox(height: 16),
          _buildAttendanceSection(context),

          const Text(
            'FILTER BY SPECIFIC DISTRICT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFF1F3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                value: currentSelected,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.accentTeal,
                ),
                items: distList.map((dist) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: dist,
                    child: Text((dist['name'] ?? '').toString()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final int? distId = UiHelpers.parseIntNullable(val['id']);
                    HomeProvider.instance.setSelectedDistrictId(distId);
                    HomeProvider.instance.fetchHomeData(
                      isRefresh: true,
                      districtId: distId,
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _buildStatCard(
                'Zonal Leads',
                '${teamMetrics?.teamLeads ?? 0}',
                Icons.format_list_bulleted_rounded,
                Colors.teal,
              ),
              _buildStatCard(
                'Converted Admissions',
                '${teamMetrics?.teamAdmissions ?? 0}',
                Icons.school_outlined,
                Colors.green,
              ),
              _buildStatCard(
                'Zonal Conversion',
                teamMetrics?.teamConversion ?? '0%',
                Icons.trending_up,
                Colors.purple,
              ),
              _buildStatCard(
                'Pending Visits',
                '${teamMetrics?.visitsPending ?? 0}',
                Icons.directions_run_rounded,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'DISTRICTS & AREA MANAGERS (ASM) REPORT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEFF1F3)),
            ),
            child: Column(
              children: (data.territoryReport ?? []).isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(18.0),
                        child: Center(
                          child: Text(
                            'No territory reports available.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ]
                  : (data.territoryReport ?? []).map((r) {
                      double distConv = 0.0;
                      final match = RegExp(
                        r'(\d+)%',
                      ).firstMatch(r.conversionPercentage);
                      if (match != null) {
                        distConv =
                            double.tryParse(match.group(1) ?? '0') ?? 0.0;
                      }

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_city_rounded,
                                          color: AppColors.accentTeal,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          r.territoryName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      r.conversionPercentage,
                                      style: const TextStyle(
                                        color: AppColors.accentTeal,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.person_pin_rounded,
                                          color: AppColors.textSecondary,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${r.managerDesignation}: ${r.managerName}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${r.leadsCount} Leads • ${r.bdesCount} BDEs',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: distConv / 100,
                                    minHeight: 5,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.accentTeal,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (r != (data.territoryReport ?? []).last)
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ],
                      );
                    }).toList(),
            ),
          ),
          _buildTasksSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- ASM (AREA SALES MANAGER) DEDICATED DASHBOARD VIEW ---
  Widget _buildAsmDashboard(BuildContext context, OperationsProvider provider) {
    final team =
        data.teamName ??
        (user.team != null && user.team.toString().isNotEmpty
            ? user.team.toString()
            : 'Regional Team');
    final districtName =
        user.district != null && user.district.toString().isNotEmpty
        ? user.district.toString()
        : 'Kerala Region';

    final int totalBdeLeads = provider.asmBdes.fold(
      0,
      (sum, b) => sum + b.leadsAssigned,
    );
    final int totalBdeAdmissions = provider.asmBdes.fold(
      0,
      (sum, b) => sum + b.admissionsClosed,
    );
    final int teamLeads =
        data.teamMetrics?.teamLeads ??
        (totalBdeLeads > 0 ? totalBdeLeads : 120);
    final int teamAdmissions =
        data.teamMetrics?.teamAdmissions ??
        (totalBdeAdmissions > 0 ? totalBdeAdmissions : 35);
    final String teamConversion =
        data.teamMetrics?.teamConversion ??
        (teamLeads > 0
            ? '${((teamAdmissions / teamLeads) * 100).toStringAsFixed(1)}%'
            : '0%');
    final int pendingBdeRequests = provider.bdePayoutRequests
        .where((r) => r.isPending)
        .length;
    final int pendingApprovals = provider.walletApprovalRequests.isNotEmpty
        ? provider.walletApprovalRequests
              .where((r) => r.isPending && !r.isForwardedToSm)
              .length
        : pendingBdeRequests;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardHeader(
            title: 'ASM Command Center',
            subtitle:
                '${team.isNotEmpty && team != "Regional Team" ? "$team • " : ""}$districtName • Area Sales & Regional Operations',
          ),
          const SizedBox(height: 16),
          _buildAttendanceSection(context),
          const SizedBox(height: 16),

          // 1. Monthly Target & Pipeline Card
          _buildAsmMonthlyTargetCard(
            context,
            provider,
            teamLeads,
            teamAdmissions,
          ),
          const SizedBox(height: 20),

          // 2. Operational Overview Responsive Grid
          _buildAsmOperationalGrid(
            context,
            teamLeads: teamLeads,
            teamAdmissions: teamAdmissions,
            teamConversion: teamConversion,
            pendingRequestsCount: pendingApprovals,
          ),
          const SizedBox(height: 24),

          // 3. Regional BDE Team Roster (with "Add BDE")
          _buildAsmBdeRoster(context, provider, districtName, team),
          const SizedBox(height: 24),

          // 4. Requests & Approvals Section (Same design & API as SM Dashboard)
          _buildAsmRequestsAndApprovalsSection(
            context,
            provider,
            pendingApprovals,
          ),
          const SizedBox(height: 24),

          // 5. Territory / District Target Breakdown
          _buildAsmTerritoryBreakdown(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAsmMonthlyTargetCard(
    BuildContext context,
    OperationsProvider provider,
    int achievedLeads,
    int achievedAdmissions,
  ) {
    final int targetLeads =
        provider.customMonthlyTargetLeads ??
        (data.monthlyTargetLeads > 0
            ? data.monthlyTargetLeads
            : (data.target?.targetLeads != null && data.target!.targetLeads > 0
                  ? data.target!.targetLeads
                  : 120));

    final int targetAdmissions =
        provider.customMonthlyTargetAdmissions ??
        (data.monthlyTargetAdmissions > 0
            ? data.monthlyTargetAdmissions
            : (data.target?.targetAdmissions != null &&
                      data.target!.targetAdmissions > 0
                  ? data.target!.targetAdmissions
                  : 35));

    final double completionPercent = targetAdmissions > 0
        ? ((achievedAdmissions / targetAdmissions) * 100).clamp(0.0, 100.0)
        : (targetLeads > 0
              ? ((achievedLeads / targetLeads) * 100).clamp(0.0, 100.0)
              : 0.0);

    final int pendingAdmissions = (targetAdmissions - achievedAdmissions).clamp(
      0,
      999999,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          // Header row with "Set Monthly Target"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        size: 18,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Target & Progress',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Territory admissions & lead performance',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Progress Bar & Percentage
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ADMISSIONS COMPLETION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      '${completionPercent.toInt()}% Achieved',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: completionPercent / 100.0,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF34D399),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$achievedAdmissions',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: ' / $targetAdmissions Admissions',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$pendingAdmissions Remaining',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFDE68A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2-column detail tiles: Leads Target & Admissions Target
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MONTHLY ADMISSIONS',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$achievedAdmissions / $targetAdmissions',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target: $targetAdmissions closed',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MONTHLY LEADS',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$achievedLeads / $targetLeads',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF075985),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target: $targetLeads leads',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAsmOperationalGrid(
    BuildContext context, {
    required int teamLeads,
    required int teamAdmissions,
    required String teamConversion,
    required int pendingRequestsCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width > 550 ? 4 : 2;
        final double childAspectRatio = width > 550 ? 1.55 : 1.35;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              'Team Leads',
              '$teamLeads',
              Icons.groups_outlined,
              const Color(0xFF7C3AED),
            ),
            _buildStatCard(
              'Team Admissions',
              '$teamAdmissions',
              Icons.verified_outlined,
              const Color(0xFF10B981),
            ),
            _buildStatCard(
              'Team Conversion',
              teamConversion,
              Icons.pie_chart_outline_rounded,
              const Color(0xFF0F766E),
            ),
            _buildStatCard(
              'Pending Payouts',
              '$pendingRequestsCount',
              Icons.receipt_long_rounded,
              pendingRequestsCount > 0
                  ? const Color(0xFFEA580C)
                  : const Color(0xFF64748B),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAsmBdeRoster(
    BuildContext context,
    OperationsProvider provider,
    String defaultDistrict,
    String defaultTeam,
  ) {
    final bdes = provider.asmBdes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'REGIONAL BDE TEAM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${bdes.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      _showAssignTaskToAsmSheet(context, isForBde: true),
                  icon: const Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 14,
                    color: Color(0xFF0F766E),
                  ),
                  label: const Text(
                    'Assign Task',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0F766E)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => showCreateBdeSheet(
                    context,
                    defaultDistrict: defaultDistrict,
                    defaultTeam: defaultTeam,
                  ),
                  icon: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Add BDE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (bdes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.group_off_outlined,
                    size: 36,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No Regional BDEs Registered',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add Business Development Executives to start assigning leads',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => showCreateBdeSheet(
                      context,
                      defaultDistrict: defaultDistrict,
                      defaultTeam: defaultTeam,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add BDE Now'),
                  ),
                ],
              ),
            ),
          )
        else
          ...bdes.map((bde) {
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
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BdeDetailsScreen(bde: bde),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(
                                0xFF0F766E,
                              ).withOpacity(0.12),
                              child: Text(
                                bde.name.isNotEmpty
                                    ? bde.name.substring(0, 1).toUpperCase()
                                    : 'B',
                                style: const TextStyle(
                                  color: Color(0xFF0F766E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      bde.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        bde.employeeId,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${bde.zone.isNotEmpty ? '${bde.zone} • ' : ''}${bde.district} • ${bde.team}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            bde.status.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Performance Row: Leads Assigned, Admissions Closed, Conversion Rate
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: Container(
                    //         padding: const EdgeInsets.symmetric(
                    //           vertical: 8,
                    //           horizontal: 10,
                    //         ),
                    //         decoration: BoxDecoration(
                    //           color: const Color(0xFFF8FAFC),
                    //           borderRadius: BorderRadius.circular(10),
                    //           border: Border.all(color: const Color(0xFFE2E8F0)),
                    //         ),
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             const Text(
                    //               'LEADS',
                    //               style: TextStyle(
                    //                 fontSize: 9,
                    //                 fontWeight: FontWeight.w700,
                    //                 color: Color(0xFF64748B),
                    //               ),
                    //             ),
                    //             const SizedBox(height: 2),
                    //             Text(
                    //               '${bde.leadsAssigned}',
                    //               style: const TextStyle(
                    //                 fontSize: 13,
                    //                 fontWeight: FontWeight.bold,
                    //                 color: Color(0xFF0F172A),
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     Expanded(
                    //       child: Container(
                    //         padding: const EdgeInsets.symmetric(
                    //           vertical: 8,
                    //           horizontal: 10,
                    //         ),
                    //         decoration: BoxDecoration(
                    //           color: const Color(0xFFF8FAFC),
                    //           borderRadius: BorderRadius.circular(10),
                    //           border: Border.all(color: const Color(0xFFE2E8F0)),
                    //         ),
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             const Text(
                    //               'ADMISSIONS',
                    //               style: TextStyle(
                    //                 fontSize: 9,
                    //                 fontWeight: FontWeight.w700,
                    //                 color: Color(0xFF64748B),
                    //               ),
                    //             ),
                    //             const SizedBox(height: 2),
                    //             Text(
                    //               '${bde.admissionsClosed}',
                    //               style: const TextStyle(
                    //                 fontSize: 13,
                    //                 fontWeight: FontWeight.bold,
                    //                 color: Color(0xFF0F172A),
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     Expanded(
                    //       child: Container(
                    //         padding: const EdgeInsets.symmetric(
                    //           vertical: 8,
                    //           horizontal: 10,
                    //         ),
                    //         decoration: BoxDecoration(
                    //           color: const Color(0xFFF0FDF4),
                    //           borderRadius: BorderRadius.circular(10),
                    //           border: Border.all(color: const Color(0xFFBBF7D0)),
                    //         ),
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             const Text(
                    //               'CONVERSION',
                    //               style: TextStyle(
                    //                 fontSize: 9,
                    //                 fontWeight: FontWeight.w700,
                    //                 color: Color(0xFF16A34A),
                    //               ),
                    //             ),
                    //             const SizedBox(height: 2),
                    //             Text(
                    //               bde.conversionRate,
                    //               style: const TextStyle(
                    //                 fontSize: 13,
                    //                 fontWeight: FontWeight.bold,
                    //                 color: Color(0xFF15803D),
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAsmRequestsAndApprovalsSection(
    BuildContext context,
    OperationsProvider provider,
    int pendingCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requests & Approvals',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RequestsApprovalsScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Salary / Incentive requests',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$pendingCount awaiting review',
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildAsmBdeRequestsSection(
    BuildContext context,
    OperationsProvider provider,
  ) {
    final requests = provider.bdePayoutRequests;
    final int pendingCount = requests.where((r) => r.isPending).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'BDE INCENTIVE & PAYOUT REQUESTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$pendingCount PENDING',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RequestsApprovalsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: Color(0xFF0F766E),
                  ),
                  label: const Text(
                    'All Approvals',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: () =>
                      provider.fetchBdePendingRequests(isRefresh: true),
                  tooltip: 'Refresh BDE requests',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No pending BDE incentive or payout requests.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          )
        else
          ...requests.map((req) {
            final bool isPending = req.isPending;
            final bool isIncentive = req.type == 'Incentive';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isPending
                      ? const Color(0xFFFED7AA)
                      : const Color(0xFFE2E8F0),
                  width: isPending ? 1.2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Name + Type Badge + Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isIncentive
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isIncentive
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF4338CA),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            req.employeeName,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (req.employeeId.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${req.employeeId})',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        req.formattedAmount,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Notes or details
                  if (req.notes != null && req.notes!.isNotEmpty)
                    Text(
                      req.notes!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF334155),
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Bottom action row: Submitted date and "Forward to SM" button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        req.submittedAt ?? 'Recently',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      if (isPending)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final success = isIncentive
                                ? await provider.forwardBdeIncentiveToSm(req.id)
                                : await provider.forwardBdeSalaryToSm(req.id);
                            if (context.mounted && success) {
                              UiHelpers.showSnackBar(
                                context,
                                '${req.type} request of ${req.formattedAmount} from ${req.employeeName} forwarded to Sales Manager (SM)!',
                                Colors.green,
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.send_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Forward to SM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: Color(0xFF16A34A),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Forwarded to SM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAsmTerritoryBreakdown(BuildContext context) {
    final reports = data.territoryReport;
    if (reports == null || reports.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TERRITORY & DISTRICT TARGET BREAKDOWN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        ...reports.map((item) {
          final int leads = item.leadsCount;
          final int bdes = item.bdesCount;
          final String conv = item.conversionPercentage;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.territoryName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$bdes Active BDEs assigned',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$leads Leads',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    Text(
                      'Conv: $conv',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- BDM / ASM DASHBOARD VIEW ---
  Widget _buildBdmDashboard(BuildContext context, String role) {
    final team = data.teamName ?? 'Regional Team';
    final teamMetrics = data.teamMetrics;
    final bdeStatuses = role == 'ASM'
        ? (data.teamSubordinateStatus?['BDM'] ?? [])
        : (data.teamSubordinateStatus?['BDE'] ?? []);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardHeader(
            title: team,
            subtitle: role == 'ASM'
                ? 'Area Manager Command Center & Live Team Tracking'
                : 'Team Leader Performance & Live BDE Tracking',
          ),
          const SizedBox(height: 16),
          _buildAttendanceSection(context),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _buildStatCard(
                'Team Leads',
                '${teamMetrics?.teamLeads ?? 0}',
                Icons.group_work_outlined,
                Colors.purple,
              ),
              _buildStatCard(
                'Team Admissions',
                '${teamMetrics?.teamAdmissions ?? 0}',
                Icons.offline_pin_outlined,
                Colors.green,
              ),
              _buildStatCard(
                'Team Conversion',
                teamMetrics?.teamConversion ?? '0%',
                Icons.assessment_outlined,
                Colors.teal,
              ),
              _buildStatCard(
                'Visits Pending',
                '${teamMetrics?.visitsPending ?? 0}',
                Icons.run_circle_outlined,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            role == 'ASM'
                ? 'TEAM BDM STATUS & METRICS'
                : 'TEAM BDE STATUS & METRICS',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          if (bdeStatuses.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEFF1F3)),
              ),
              child: Center(
                child: Text(
                  role == 'ASM'
                      ? 'No active BDMs assigned to this team'
                      : 'No active BDEs assigned to this team',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...bdeStatuses.map((bde) {
              final bool isOnline = bde.onlineStatus.toUpperCase() != 'OFFLINE';
              final double bdeConv = _parseConversionPercentage(
                bde.conversionPercentage,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEFF1F3)),
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline ? Colors.green : Colors.grey)
                          .withOpacity(0.02),
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
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                                boxShadow: isOnline
                                    ? [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.4),
                                          blurRadius: 6,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              bde.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          bde.conversionPercentage,
                          style: TextStyle(
                            color: isOnline
                                ? Colors.green.shade700
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isOnline
                                  ? Icons.location_on_outlined
                                  : Icons.location_off_outlined,
                              color: AppColors.textSecondary,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOnline
                                  ? 'Active${bde.onlineTime != null ? ' @ ${bde.onlineTime}' : ''}'
                                  : 'Offline / Check-out complete',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          bde.leadsAssigned,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: bdeConv / 100.0,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOnline ? Colors.green : AppColors.accentTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          _buildTasksSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTasksSection() {
    final tasks = HomeProvider.instance.performanceTasks;
    final summary = HomeProvider.instance.tasksSummary;
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
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
                  'Performance tracking & targets',
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${summary.pending} Pending',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${summary.completed} Done',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),
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
                        _buildTaskChip(
                          Icons.calendar_today_outlined,
                          dateRange,
                        ),
                      if (task.metricType.isNotEmpty)
                        _buildTaskChip(
                          Icons.ads_click_rounded,
                          task.metricType,
                        ),
                      if (task.frequency.isNotEmpty)
                        _buildTaskChip(
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

  Widget _buildTaskChip(IconData icon, String text) {
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OperationsProvider.instance,
      builder: (context, _) {
        final provider = OperationsProvider.instance;
        final desig = data.designationName.toLowerCase();
        final role = user.role.toString().toUpperCase();
        final dType = (data.dashboardType ?? '').toUpperCase();

        String effectiveRole;
        if (role == 'ASM' ||
            dType == 'ASM' ||
            data.designationName.toUpperCase() == 'ASM' ||
            desig.contains('area sales') ||
            desig.contains('area manager') ||
            desig.contains('area') ||
            desig == 'asm' ||
            desig.contains('asm')) {
          effectiveRole = 'ASM';
        } else if (role == 'SM' ||
            dType == 'SM' ||
            data.designationName.toUpperCase() == 'SM' ||
            desig.contains('state manager') ||
            desig.contains('sales manager')) {
          effectiveRole = 'SM';
        } else {
          effectiveRole = user.role.toString();
        }

        Widget dashboardWidget;
        switch (effectiveRole) {
          case 'MD':
            dashboardWidget = _buildMdDashboard(context, provider);
            break;
          case 'SM':
            dashboardWidget = _buildSmDashboard(context, provider);
            break;
          case 'ADMIN':
          case 'ACCOUNTS':
            dashboardWidget = _buildAccountsAdminDashboard(context, provider);
            break;
          case 'ZM':
            dashboardWidget = _buildZmDashboard(context, provider);
            break;
          case 'ASM':
            dashboardWidget = _buildAsmDashboard(context, provider);
            break;
          case 'BDM':
          default:
            dashboardWidget = _buildBdmDashboard(context, 'BDM');
            break;
        }
        return dashboardWidget;
      },
    );
  }
}
