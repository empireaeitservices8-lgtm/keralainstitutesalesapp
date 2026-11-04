import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/home_dashboard_model.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../providers/operations_provider.dart';
import '../providers/home_provider.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  static const String path = '/employee-dashboard';
  final int employeeId;
  final String employeeName;

  const EmployeeDashboardScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  HomeDashboardModel? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeDashboard();
  }

  Future<void> _fetchEmployeeDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.home,
        queryParameters: {'employee_id': widget.employeeId},
      );

      if (response.data != null && response.data['success'] == true) {
        final rawData = response.data['data'];
        if (rawData is Map) {
          final dataMap = Map<String, dynamic>.from(rawData);
          setState(() {
            _dashboardData = HomeDashboardModel.fromJson(dataMap);
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _errorMessage =
            response.data?['message'] ?? 'Failed to load dashboard data.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading dashboard: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.employeeName.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            if (_dashboardData != null)
              Text(
                _dashboardData!.designationName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        centerTitle: false,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentTeal),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _fetchEmployeeDashboard,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_dashboardData == null) {
      return const Center(child: Text('No dashboard data available.'));
    }

    final isManager = _dashboardData!.dashboardType == 'manager';

    return RefreshIndicator(
      color: AppColors.accentTeal,
      onRefresh: _fetchEmployeeDashboard,
      child: isManager
          ? _buildManagerDashboard(_dashboardData!)
          : _buildBdeDashboard(_dashboardData!),
    );
  }

  Widget _buildManagerDashboard(HomeDashboardModel data) {
    final teamMetrics = data.teamMetrics;
    final isAsm =
        data.designationName.toLowerCase().contains('area') ||
        data.designationName.toLowerCase().contains('asm');
    final bdeStatuses = isAsm
        ? (data.teamSubordinateStatus?['BDM'] ?? [])
        : (data.teamSubordinateStatus?['BDE'] ?? []);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.teamName ?? 'Team Overview',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
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
            isAsm ? 'TEAM BDM STATUS & METRICS' : 'TEAM BDE STATUS & METRICS',
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
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEFF1F3)),
              ),
              child: Center(
                child: Text(
                  isAsm
                      ? 'No active BDMs assigned to this team'
                      : 'No active BDEs assigned to this team',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...bdeStatuses.map((bde) {
              final bool isOnline = bde.onlineStatus.toUpperCase() != 'OFFLINE';
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEFF1F3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: (isOnline ? Colors.green : Colors.grey)
                          .withOpacity(0.08),
                      child: Icon(
                        isOnline
                            ? Icons.sensors_rounded
                            : Icons.sensors_off_rounded,
                        color: isOnline ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bde.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            bde.designation,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          bde.conversionPercentage,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentTeal,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          bde.leadsAssigned,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBdeDashboard(HomeDashboardModel data) {
    final assignedLeads = data.operationalOverview?.assignedLeads ?? 0;
    final followUpLeads = data.operationalOverview?.followUpLeads ?? 0;
    final closedLeads = data.operationalOverview?.closedLeads ?? 0;
    final incentives = data.operationalOverview?.incentivesEarned ?? 0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendanceSection(data.attendance),
          const SizedBox(height: 16),
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
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _buildStatCard(
                'Assigned Leads',
                '$assignedLeads',
                Icons.assignment_outlined,
                Colors.purple,
              ),
              _buildStatCard(
                'Follow-Up Needed',
                '$followUpLeads',
                Icons.chat_bubble_outline_rounded,
                Colors.teal,
              ),
              _buildStatCard(
                'Admissions Registered',
                '$closedLeads',
                Icons.check_circle_outline_rounded,
                Colors.green,
              ),
              _buildStatCard(
                'Incentives Earned',
                '\u20B9${NumberFormat('#,##,###').format(incentives)}',
                Icons.monetization_on_outlined,
                Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(
                Icons.filter_alt_outlined,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                'Filter and View Leads for ${widget.employeeName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              onPressed: () {
                OperationsProvider.instance.setSelectedBde(
                  widget.employeeName,
                  widget.employeeId,
                );
                OperationsProvider.instance.fetchLeads(
                  status: 1,
                  employeeId: widget.employeeId,
                );
                OperationsProvider.instance.fetchCompletedLeads(
                  employeeId: widget.employeeId,
                );
                HomeProvider.instance.setCurrentIndex(1);
                Navigator.pop(context); // Close employee dashboard detail view
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime12Hr(String timeStr) {
    if (timeStr == '--:--' || timeStr.isEmpty || timeStr == 'null')
      return '--:--';
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

  Widget _buildAttendanceSection(HomeAttendance? apiAttendance) {
    if (apiAttendance == null) return const SizedBox.shrink();

    final bool checkedIn = apiAttendance.isCheckedIn;
    final bool checkedOut =
        apiAttendance.isCheckedOut ||
        apiAttendance.shiftStatus == 'COMPLETED' ||
        apiAttendance.shiftStatus == 'CHECKED_OUT';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFF1F3)),
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
                      color: (checkedIn ? Colors.green : Colors.orange)
                          .withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      checkedIn
                          ? Icons.check_circle_outline_rounded
                          : Icons.pending_actions_rounded,
                      color: checkedIn ? Colors.green : Colors.orange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Attendance Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (checkedOut
                              ? Colors.grey
                              : (checkedIn ? Colors.green : Colors.orange))
                          .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  apiAttendance.shiftStatus,
                  style: TextStyle(
                    color: checkedOut
                        ? Colors.grey
                        : (checkedIn ? Colors.green : Colors.orange),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHECK IN',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    checkedIn && apiAttendance.checkInTime.isNotEmpty
                        ? _formatTime12Hr(apiAttendance.checkInTime)
                        : '--:--',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'CHECK OUT',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    checkedOut && apiAttendance.checkOutTime.isNotEmpty
                        ? _formatTime12Hr(apiAttendance.checkOutTime)
                        : '--:--',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFF1F3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
