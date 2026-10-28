import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../models/home_dashboard_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/operations_provider.dart';
import '../attendance_screen.dart';
import '../../utils/helpers.dart';

class ManagementDashboardView extends StatelessWidget {
  final HomeDashboardModel data;
  final dynamic user;

  const ManagementDashboardView({
    super.key,
    required this.data,
    required this.user,
  });

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
  }) {
    return Column(
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
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

  Widget _buildAttendanceCard({
    required BuildContext context,
    required bool checkedIn,
    required bool checkedOut,
    required String checkInTime,
    required String checkOutTime,
    required String shiftStatus,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.login_rounded,
                        color: Colors.green,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CHECK IN',
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          checkInTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 24,
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
                            fontSize: 8,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          checkOutTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          Container(
            height: 40,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.accentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
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
        ],
      ),
    );
  }

  Widget _buildAttendanceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Attendance Activity',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
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
    final interested = allLeads.where((t) => t.leadStatus == 'Interested').length;
    final pending = allLeads.where((t) => t.status != 'Completed').length;
    final conversion = allLeads.isNotEmpty ? (admitted / allLeads.length) * 100 : 0.0;

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
                  double.tryParse(report.conversionPercentage.replaceAll('%', '')) ?? 0.0;
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

  // --- ZM DASHBOARD VIEW ---
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
                      final match = RegExp(r'(\d+)%').firstMatch(r.conversionPercentage);
                      if (match != null) {
                        distConv = double.tryParse(match.group(1) ?? '0') ?? 0.0;
                      }

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    valueColor: const AlwaysStoppedAnimation<Color>(
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
            role == 'ASM' ? 'TEAM BDM STATUS & METRICS' : 'TEAM BDE STATUS & METRICS',
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
              final double bdeConv = _parseConversionPercentage(bde.conversionPercentage);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEFF1F3)),
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline ? Colors.green : Colors.grey).withOpacity(0.02),
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
                            color: isOnline ? Colors.green.shade700 : AppColors.textSecondary,
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
                              isOnline ? Icons.location_on_outlined : Icons.location_off_outlined,
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
        Widget dashboardWidget;
        switch (user.role) {
          case 'MD':
            dashboardWidget = _buildMdDashboard(context, provider);
            break;
          case 'ZM':
            dashboardWidget = _buildZmDashboard(context, provider);
            break;
          case 'ASM':
            dashboardWidget = _buildBdmDashboard(context, 'ASM');
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
