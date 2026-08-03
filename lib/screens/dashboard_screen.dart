import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/operations_provider.dart';
import '../widgets/dashboard_module_card.dart';
import '../models/task_model.dart';
import 'attendance_screen.dart';
import 'login_screen.dart';
import 'task_screen.dart';
import 'incentive_screen.dart';
import 'profile_screen.dart';
import 'eod_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const String path = '/dashboard';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // MD System Configurations state
  bool _gpsLoggingEnforced = true;
  bool _biometricEnforced = true;
  bool _autoSyncActive = true;

  @override
  void initState() {
    super.initState();
    // Preload data
    OperationsProvider.instance.loadOperationsData();
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logging out...', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Row(
          children: [
            CircularProgressIndicator(color: AppColors.accentTeal),
            SizedBox(width: 20),
            Text('Ending active session...', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1500));
    await AuthProvider.instance.logout();

    if (mounted) {
      Navigator.pop(context);
      Navigator.pushReplacementNamed(context, LoginScreen.path);
    }
  }

  void _routeToEod() {
    Navigator.pushNamed(
      context,
      EodScreen.path,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthProvider.instance.session;
    Widget currentBody;
    switch (_currentIndex) {
      case 0:
        currentBody = _buildHomeOverview();
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
        currentBody = _buildHomeOverview();
    }

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: _currentIndex == 0
          ? AppBar(
              title: Text(
                '${user.role} COMMAND CENTER',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 20),
                  tooltip: 'Logout Session',
                  onPressed: _handleLogout,
                )
              ],
            )
          : null,
      body: currentBody,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHomeOverview() {
    final user = AuthProvider.instance.session;
    switch (user.role) {
      case 'MD':
        return _buildMdDashboard();
      case 'ZM':
        return _buildZmDashboard(user);
      case 'ASM':
        return _buildAsmDashboard(user);
      case 'BDM':
        return _buildBdmDashboard(user);
      case 'BDE':
      default:
        return _buildBdeDashboard();
    }
  }

  // --- MD DASHBOARD VIEW (Unrestricted Super Admin) ---
  Widget _buildMdDashboard() {
    return ListenableBuilder(
      listenable: OperationsProvider.instance,
      builder: (context, _) {
        final provider = OperationsProvider.instance;
        final allLeads = provider.rawTasks;
        
        final admitted = allLeads.where((t) => t.leadStatus == 'Admitted').length;
        final interested = allLeads.where((t) => t.leadStatus == 'Interested').length;
        final pending = allLeads.where((t) => t.status != 'Completed').length;
        final conversion = allLeads.isNotEmpty ? (admitted / allLeads.length) * 100 : 0.0;

        // Group by zone
        final southLeads = allLeads.where((t) => t.zone == 'South Zone').length;
        final centralLeads = allLeads.where((t) => t.zone == 'Central Zone').length;
        final northLeads = allLeads.where((t) => t.zone == 'North Zone').length;

        final southAdmitted = allLeads.where((t) => t.zone == 'South Zone' && t.leadStatus == 'Admitted').length;
        final centralAdmitted = allLeads.where((t) => t.zone == 'Central Zone' && t.leadStatus == 'Admitted').length;
        final northAdmitted = allLeads.where((t) => t.zone == 'North Zone' && t.leadStatus == 'Admitted').length;

        final double southConv = southLeads > 0 ? (southAdmitted / southLeads) * 100 : 0.0;
        final double centralConv = centralLeads > 0 ? (centralAdmitted / centralLeads) * 100 : 0.0;
        final double northConv = northLeads > 0 ? (northAdmitted / northLeads) * 100 : 0.0;

        final List<Map<String, String>> hierarchyUsers = [
          {'name': 'Dr. K. Kurian', 'role': 'MD', 'scope': 'State-wide', 'status': 'Active'},
          {'name': 'Thomas Mathew', 'role': 'ZM', 'scope': 'South Zone', 'status': 'Active'},
          {'name': 'Sandhya Nair', 'role': 'ZM', 'scope': 'Central Zone', 'status': 'Active'},
          {'name': 'Raghesh Pillai', 'role': 'ZM', 'scope': 'North Zone', 'status': 'Active'},
          {'name': 'Anjali Krishna', 'role': 'ASM', 'scope': 'Ernakulam Dist.', 'status': 'On Duty'},
          {'name': 'Bipin Joseph', 'role': 'ASM', 'scope': 'Trivandrum Dist.', 'status': 'On Duty'},
          {'name': 'Deepak S.', 'role': 'BDM', 'scope': 'Ernakulam Team A', 'status': 'Active'},
          {'name': 'Rahul R. V.', 'role': 'BDE', 'scope': 'Ernakulam A1', 'status': 'In Field'},
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDashboardHeader(
                title: 'Kerala State Operations',
                subtitle: 'Super Admin Overview & Global Analytics',
              ),
              const SizedBox(height: 16),
              
              // MD KPIs Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard('Total State Leads', '${allLeads.length}', Icons.layers_outlined, Colors.blue),
                  _buildStatCard('Admissions Registered', '$admitted', Icons.check_circle_outline, Colors.green),
                  _buildStatCard('Conversion Rate', '${conversion.toStringAsFixed(1)}%', Icons.pie_chart_outline, Colors.amber),
                  _buildStatCard('Pending Followups', '$pending', Icons.hourglass_empty_rounded, Colors.purple),
                ],
              ),
              const SizedBox(height: 24),

              // Zonal Performance Panels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ZONAL PERFORMANCE SUMMARY',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero),
                    child: const Text('View All Leads', style: TextStyle(fontSize: 11, color: AppColors.accentTeal, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 10),
              _buildZonalReportCard('South Zone (Thomas Mathew)', southLeads, southConv, Colors.blue),
              const SizedBox(height: 10),
              _buildZonalReportCard('Central Zone (Sandhya Nair)', centralLeads, centralConv, Colors.teal),
              const SizedBox(height: 10),
              _buildZonalReportCard('North Zone (Raghesh Pillai)', northLeads, northConv, Colors.orange),
              const SizedBox(height: 24),

              // User Control & Org Directory
              const Text(
                'ORGANIZATIONAL USER ROLES CONTROL',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: hierarchyUsers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final u = hierarchyUsers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u['name']!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                              Text('${u['role']} • ${u['scope']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (u['status'] == 'In Field' || u['status'] == 'On Duty')
                                      ? Colors.green.withOpacity(0.08)
                                      : Colors.blue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  u['status']!,
                                  style: TextStyle(
                                    color: (u['status'] == 'In Field' || u['status'] == 'On Duty') ? Colors.green : Colors.blue,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.settings_outlined, size: 16, color: AppColors.textSecondary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Modifying profile/permissions for ${u['name']} (Simulated)')),
                                  );
                                },
                              )
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // System Settings & Configuration Toggles
              const Text(
                'SYSTEM HEALTH & CONFIGURATIONS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildInteractiveSettingRow(
                      title: 'Enforce GPS Beat Visit Logs',
                      subtitle: 'BDE check-ins require location verification',
                      value: _gpsLoggingEnforced,
                      onChanged: (val) {
                        setState(() => _gpsLoggingEnforced = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('GPS Beat Visit logs ${val ? 'Enforced' : 'Disabled'} globally.')),
                        );
                      },
                    ),
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),
                    _buildInteractiveSettingRow(
                      title: 'Biometric Attendance Lock',
                      subtitle: 'Face/Fingerprint verify on check-in',
                      value: _biometricEnforced,
                      onChanged: (val) {
                        setState(() => _biometricEnforced = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Biometric Attendance Lock ${val ? 'Activated' : 'Suspended'}.')),
                        );
                      },
                    ),
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),
                    _buildInteractiveSettingRow(
                      title: 'Auto Cloud Sync Logs',
                      subtitle: 'Sync local sales data to head servers',
                      value: _autoSyncActive,
                      onChanged: (val) {
                        setState(() => _autoSyncActive = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Auto Cloud Sync set to ${val ? 'Automatic' : 'Manual Run'}.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // Helper to build a zonal report card for MD
  Widget _buildZonalReportCard(String zoneName, int totalLeads, double conversion, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                width: 4,
                height: 36,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zoneName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                  Text('$totalLeads Leads Assigned', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${conversion.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15)),
              const Text('Conv. Rate', style: TextStyle(color: AppColors.textSecondary, fontSize: 9)),
            ],
          )
        ],
      ),
    );
  }

  // Interactive Switch Row for MD
  Widget _buildInteractiveSettingRow({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: AppColors.accentTeal,
          activeTrackColor: AppColors.accentTeal.withOpacity(0.2),
          onChanged: onChanged,
        )
      ],
    );
  }

  // --- ZM DASHBOARD VIEW (Zonal Metrics & District Reports) ---
  Widget _buildZmDashboard(dynamic user) {
    return ListenableBuilder(
      listenable: OperationsProvider.instance,
      builder: (context, _) {
        final provider = OperationsProvider.instance;
        final zone = user.zone ?? 'Central Zone';
        
        final List<String> districts = zone == 'South Zone'
            ? ['All Districts', 'Thiruvananthapuram', 'Kollam', 'Pathanamthitta', 'Alappuzha', 'Kottayam']
            : zone == 'Central Zone'
                ? ['All Districts', 'Idukki', 'Ernakulam', 'Thrissur', 'Palakkad', 'Malappuram']
                : ['All Districts', 'Wayanad', 'Kozhikode', 'Kannur', 'Kasaragod'];

        final activeDistrictFilter = provider.selectedDistrictFilter ?? 'All Districts';
        final filteredTasks = provider.tasks;
        final totalLeads = filteredTasks.length;
        final admitted = filteredTasks.where((t) => t.leadStatus == 'Admitted').length;
        final pending = filteredTasks.where((t) => t.status != 'Completed').length;
        final conversion = totalLeads > 0 ? (admitted / totalLeads) * 100 : 0.0;

        // District to ASM name mapping for reports
        final Map<String, String> asmMapping = {
          'Ernakulam': 'Anjali Krishna',
          'Thiruvananthapuram': 'Bipin Joseph',
          'Kozhikode': 'Manoj Kumar',
          'Idukki': 'Thomas K. (Sim.)',
          'Thrissur': 'Ramesh P. (Sim.)',
          'Palakkad': 'Sonia M. (Sim.)',
          'Malappuram': 'Faisal H. (Sim.)',
          'Kollam': 'Deepa S. (Sim.)',
          'Pathanamthitta': 'Roy V. (Sim.)',
          'Alappuzha': 'Varun A. (Sim.)',
          'Kottayam': 'Jose N. (Sim.)',
          'Wayanad': 'Kiran D. (Sim.)',
          'Kannur': 'Shine J. (Sim.)',
          'Kasaragod': 'Abdul K. (Sim.)',
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDashboardHeader(
                title: '$zone Manager Desk',
                subtitle: 'Territory Reports & District Overview',
              ),
              const SizedBox(height: 16),

              // District Filter Selector
              const Text(
                'FILTER BY SPECIFIC DISTRICT',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: districts.contains(activeDistrictFilter) ? activeDistrictFilter : 'All Districts',
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    items: districts.map((dist) {
                      return DropdownMenuItem<String>(
                        value: dist,
                        child: Text(dist),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == 'All Districts') {
                        provider.setDistrictFilter(null);
                      } else {
                        provider.setDistrictFilter(val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ZM KPIs Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard('Zonal Leads', '$totalLeads', Icons.format_list_bulleted_rounded, Colors.teal),
                  _buildStatCard('Converted Admissions', '$admitted', Icons.school_outlined, Colors.green),
                  _buildStatCard('Zonal Conversion', '${conversion.toStringAsFixed(1)}%', Icons.trending_up, Colors.purple),
                  _buildStatCard('Pending Visits', '$pending', Icons.directions_run_rounded, Colors.orange),
                ],
              ),
              const SizedBox(height: 24),

              // District comparison list (Detailed Reports)
              const Text(
                'DISTRICTS & AREA MANAGERS (ASM) REPORT',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: districts.where((d) => d != 'All Districts').map((d) {
                    final distTasks = provider.rawTasks.where((t) => t.district == d).toList();
                    final count = distTasks.length;
                    final distAdmitted = distTasks.where((t) => t.leadStatus == 'Admitted').length;
                    final double distConv = count > 0 ? (distAdmitted / count) * 100 : 0.0;
                    
                    final asmName = asmMapping[d] ?? 'No ASM Assigned';
                    final bdeCount = distTasks.map((t) => t.assignedBdeEmail).toSet().length;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(d, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                                  Text('${distConv.toStringAsFixed(0)}% Conv.', style: const TextStyle(color: AppColors.accentTeal, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('ASM: $asmName', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  Text('$count Leads • $bdeCount BDEs', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (d != districts.last) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // --- ASM DASHBOARD VIEW (District Head View) ---
  Widget _buildAsmDashboard(dynamic user) {
    return ListenableBuilder(
      listenable: OperationsProvider.instance,
      builder: (context, _) {
        final provider = OperationsProvider.instance;
        final district = user.district ?? 'Ernakulam';
        
        final filteredTasks = provider.tasks; // Filtered to district
        final totalLeads = filteredTasks.length;
        final admitted = filteredTasks.where((t) => t.leadStatus == 'Admitted').length;
        final pending = filteredTasks.where((t) => t.status != 'Completed').length;
        final conversion = totalLeads > 0 ? (admitted / totalLeads) * 100 : 0.0;

        // Find teams under this district dynamically
        final teamNames = filteredTasks.map((t) => t.team).toSet().toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDashboardHeader(
                title: '$district Area Command',
                subtitle: 'District Head / Area Sales Manager',
              ),
              const SizedBox(height: 16),

              // ASM KPIs Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard('District Leads', '$totalLeads', Icons.apartment_rounded, Colors.purple),
                  _buildStatCard('Admissions Registered', '$admitted', Icons.assignment_turned_in_outlined, Colors.green),
                  _buildStatCard('District Conversion', '${conversion.toStringAsFixed(1)}%', Icons.pie_chart_outline, Colors.teal),
                  _buildStatCard('Visits Left', '$pending', Icons.map_outlined, Colors.orange),
                ],
              ),
              const SizedBox(height: 24),

              // BDM Team Performance comparisons
              const Text(
                'TEAMS & BDM LEADER BOARDS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              
              if (teamNames.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('No active teams in this district', style: TextStyle(color: AppColors.textSecondary))),
                )
              else
                ...teamNames.map((teamName) {
                  final teamTasks = filteredTasks.where((t) => t.team == teamName).toList();
                  final teamTotal = teamTasks.length;
                  final teamAdmitted = teamTasks.where((t) => t.leadStatus == 'Admitted').length;
                  final double teamConv = teamTotal > 0 ? (teamAdmitted / teamTotal) * 100 : 0.0;
                  
                  // BDM name lookup
                  String bdmName = 'Unknown BDM';
                  if (teamName.contains('Team A')) bdmName = 'Deepak S.';
                  if (teamName.contains('Team B')) bdmName = 'Greeshma P.';
                  if (teamName.contains('Trivandrum')) bdmName = 'Sanjay R.';

                  final activeBdeCount = teamTasks.map((t) => t.assignedBdeEmail).toSet().length;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                            Text('${teamConv.toStringAsFixed(1)}% Conv.', style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('TL/BDM: $bdmName', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const Divider(height: 20, color: Color(0xFFE2E8F0)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Active BDEs: $activeBdeCount', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            Text('$teamTotal Assigned Leads', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // Quick activity logs
              const Text(
                'DISTRICT TEAM ACTIVITY LOGS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildSystemRow('BDE Rahul R. V. Checked-in', '10:05 AM at Kakkanad', true),
                    const Divider(height: 20, color: Color(0xFFE2E8F0)),
                    _buildSystemRow('BDM Deepak S. uploaded 5 leads', '09:30 AM via bulk csv', true),
                    const Divider(height: 20, color: Color(0xFFE2E8F0)),
                    _buildSystemRow('GPS Audit Compliance', '100% Verified in district', true),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // --- BDM DASHBOARD VIEW (Team Leader View with BDE metrics) ---
  Widget _buildBdmDashboard(dynamic user) {
    return ListenableBuilder(
      listenable: OperationsProvider.instance,
      builder: (context, _) {
        final provider = OperationsProvider.instance;
        final team = user.team ?? 'Ernakulam Team A';
        
        final filteredTasks = provider.tasks; // Filtered to team
        final totalLeads = filteredTasks.length;
        final admitted = filteredTasks.where((t) => t.leadStatus == 'Admitted').length;
        final pending = filteredTasks.where((t) => t.status != 'Completed').length;
        final conversion = totalLeads > 0 ? (admitted / totalLeads) * 100 : 0.0;

        // BDE members under this team dynamically
        final bdeEmails = filteredTasks.map((t) => t.assignedBdeEmail).toSet().toList();

        // BDE status mock mapping
        final Map<String, Map<String, String>> bdeStatusMock = {
          'bde.ernakulam.a1@keralainstitute.org': {'name': 'Rahul R. V. (BDE 1)', 'status': 'Checked In', 'time': '10:05 AM', 'loc': 'Kakkanad'},
          'bde.ernakulam.a2@keralainstitute.org': {'name': 'Meera K. S. (BDE 2)', 'status': 'Checked In', 'time': '10:15 AM', 'loc': 'Vyttila'},
          'bde.ernakulam.b1@keralainstitute.org': {'name': 'Sujith P. V. (BDE 1)', 'status': 'Offline', 'time': '09:00 AM', 'loc': 'Palarivattom'},
          'bde.trivandrum.a1@keralainstitute.org': {'name': 'Akhila Mohan (BDE 1)', 'status': 'Checked In', 'time': '09:45 AM', 'loc': 'Technopark'},
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDashboardHeader(
                title: '$team Command',
                subtitle: 'Team Leader Performance & Live BDE Tracking',
              ),
              const SizedBox(height: 16),

              // BDM KPIs Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard('Team Leads', '$totalLeads', Icons.group_work_outlined, Colors.purple),
                  _buildStatCard('Team Admissions', '$admitted', Icons.offline_pin_outlined, Colors.green),
                  _buildStatCard('Team Conversion', '${conversion.toStringAsFixed(1)}%', Icons.assessment_outlined, Colors.teal),
                  _buildStatCard('Visits Pending', '$pending', Icons.run_circle_outlined, Colors.orange),
                ],
              ),
              const SizedBox(height: 24),

              // BDE Performance Chart/Progress
              const Text(
                'TEAM BDE STATUS & METRICS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),

              if (bdeEmails.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('No active BDEs assigned to this team', style: TextStyle(color: AppColors.textSecondary))),
                )
              else
                ...bdeEmails.map((email) {
                  final bdeTasks = filteredTasks.where((t) => t.assignedBdeEmail == email).toList();
                  final bdeTotal = bdeTasks.length;
                  final bdeAdmitted = bdeTasks.where((t) => t.leadStatus == 'Admitted').length;
                  final double bdeConv = bdeTotal > 0 ? (bdeAdmitted / bdeTotal) * 100 : 0.0;
                  
                  final details = bdeStatusMock[email] ?? {
                    'name': email.split('@').first.toUpperCase(),
                    'status': 'Offline',
                    'time': 'N/A',
                    'loc': 'N/A'
                  };
                  final bool isOnline = details['status'] == 'Checked In';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 6,
                                  backgroundColor: isOnline ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(details['name']!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                              ],
                            ),
                            Text('${bdeConv.toStringAsFixed(0)}% Conv.', style: TextStyle(color: isOnline ? Colors.green.shade700 : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isOnline ? 'Online: ${details['time']} @ ${details['loc']}' : 'Offline / Signed Out', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            Text('$bdeTotal Leads Assigned', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: bdeTotal > 0 ? (bdeAdmitted / bdeTotal) : 0.0,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(isOnline ? Colors.green.shade600 : Colors.grey.shade400),
                          ),
                        )
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'TEAM UTILITY CONSOLE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.accentTeal,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.accentTeal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                  label: const Text('Bulk Lead Upload & Assign', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    // Navigate to tasks tab (index 1) where upload features are exposed
                    setState(() => _currentIndex = 1);
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // --- BDE DASHBOARD VIEW (Field Officer View) ---
  Widget _buildBdeDashboard() {
    final operationsProvider = OperationsProvider.instance;
    final totalVisits = operationsProvider.totalVisitsCount;
    final completedVisits = operationsProvider.completedVisitsCount;
    final totalTasks = operationsProvider.tasks.length;
    final completedTasks = operationsProvider.completedTasksCount;
    
    // BDE leads status filters
    final followUpLeads = operationsProvider.tasks.where((t) => t.leadStatus == 'Interested').length;
    final closedLeads = operationsProvider.tasks.where((t) => t.leadStatus == 'Admitted' || t.leadStatus == 'Closed').length;

    final totalPTOLeft = operationsProvider.leaveBalanceCasual + 
                         operationsProvider.leaveBalanceMedical + 
                         operationsProvider.leaveBalanceEarned;

    final progressPct = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Highlight Header
          const Text(
            'Daily Attendance Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),

          ListenableBuilder(
            listenable: AttendanceProvider.instance,
            builder: (context, _) {
              final attProvider = AttendanceProvider.instance;
              final att = attProvider.currentAttendance;
              final bool checkedIn = att.isPresent || att.isCompleted;
              final bool checkedOut = att.isCompleted;
              final String checkInTime = att.isAbsent ? '--:--' : DateFormat('hh:mm a').format(att.checkInTime);
              final String checkOutTime = (att.checkOutTime == null) ? '--:--' : DateFormat('hh:mm a').format(att.checkOutTime!);

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: (checkedIn ? Colors.green.shade50 : Colors.amber.shade50),
                          child: Icon(
                            checkedIn ? Icons.verified_user_rounded : Icons.lock_clock,
                            color: checkedIn ? Colors.green.shade700 : Colors.amber.shade800,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                checkedIn ? 'Logged Checked In' : 'Attendance Required',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                              ),
                              Text(
                                checkedIn ? 'Face verification ID linked' : 'No biometric token registered today',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: checkedIn ? Colors.green.shade50 : AppColors.accentTeal,
                            foregroundColor: checkedIn ? Colors.green.shade700 : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: checkedOut
                              ? null
                              : () {
                                  Navigator.pushNamed(context, AttendanceScreen.path);
                                },
                          child: Text(
                            checkedOut
                                ? 'Done'
                                : checkedIn
                                    ? 'Check Out'
                                    : 'Check In',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30, color: Color(0xFFE2E8F0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Check-In Time', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(checkInTime, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 12)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Check-Out Time', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(checkOutTime, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 12)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Shift Hours', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(checkedIn ? 'Active' : 'Offline', style: TextStyle(fontWeight: FontWeight.bold, color: checkedIn ? Colors.green.shade700 : AppColors.textPrimary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // EOD Sync
          InkWell(
            onTap: _routeToEod,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.analytics_outlined, color: AppColors.accentTeal, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'End of Day (EOD) Sync',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (operationsProvider.todayEod.isSubmitted ? Colors.green : AppColors.accentTeal).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          operationsProvider.todayEod.isSubmitted 
                              ? 'EOD Compiled' 
                              : '${(progressPct * 100).toStringAsFixed(0)}% Tasks Completed',
                          style: TextStyle(
                            color: operationsProvider.todayEod.isSubmitted ? Colors.green : AppColors.accentTeal,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPct,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        operationsProvider.todayEod.isSubmitted ? Colors.green : AppColors.accentTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tasks Completed: $completedTasks / $totalTasks Done',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      Row(
                        children: [
                          Text(
                            operationsProvider.todayEod.isSubmitted ? 'View summary' : 'Tap to submit EOD',
                            style: TextStyle(
                              color: operationsProvider.todayEod.isSubmitted ? Colors.green : AppColors.accentTeal,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right, 
                            color: operationsProvider.todayEod.isSubmitted ? Colors.green : AppColors.accentTeal, 
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Operational Overview
          const Text(
            'Operational Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.5),
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
                value: '$totalTasks Active',
                icon: Icons.task_alt_rounded,
                iconColor: Colors.cyan,
                onTap: () => setState(() => _currentIndex = 1),
                bottom: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalTasks > 0 ? (completedTasks / totalTasks) : 0.0,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                  ),
                ),
              ),
              DashboardModuleCard(
                title: 'Follow-up Leads',
                value: '$followUpLeads Scheduled',
                icon: Icons.next_plan_outlined,
                iconColor: Colors.teal,
                onTap: () => setState(() => _currentIndex = 1),
                bottom: const Text('Interested status leads', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ),
              DashboardModuleCard(
                title: 'Closed & Converted',
                value: '$closedLeads Resolved',
                icon: Icons.done_all_rounded,
                iconColor: Colors.orange,
                onTap: () => setState(() => _currentIndex = 1),
                bottom: const Text('Admitted or closed leads', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ),
              DashboardModuleCard(
                title: 'Incentives',
                value: '₹${operationsProvider.totalEarnedIncentives.toStringAsFixed(0)} Earn.',
                icon: Icons.auto_graph_rounded,
                iconColor: Colors.amber,
                onTap: () => setState(() => _currentIndex = 2),
                bottom: const Text('Target & Volume bonus', style: TextStyle(color: AppColors.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- SUB-WIDGET HELPERS ---
  Widget _buildDashboardHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
              Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildZonalDistributionProgress(String label, int count, int total, Color color) {
    final double pct = total > 0 ? count / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
              Text('$count Leads', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemRow(String title, String status, bool check) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(check ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: check ? Colors.green : Colors.orange, size: 16),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
          ],
        ),
        Text(status, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBottomNavBar() {
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
          final isSelected = _currentIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = index;
              });
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
                        ]
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
}
