import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/task_model.dart';
import '../providers/operations_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/helpers.dart';

class TaskScreen extends StatefulWidget {
  static const String path = '/tasks';
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSubmitting = false;

  // Search & Filter State
  String _searchQuery = '';
  String? _selectedBdeEmail;
  String? _selectedTeam;
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    OperationsProvider.instance.loadOperationsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Handle visit status reporting with progress logs (BDE Flow)
  Future<void> _submitVisitReport({
    required TaskModel task,
    required String leadStatus,
    required String remarks,
    required String proofPath,
    String? followUpDate,
  }) async {
    setState(() => _isSubmitting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Row(
          children: [
            CircularProgressIndicator(color: AppColors.accentTeal),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'Syncing Lead Status & Proof documents...',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pop(context); // Dismiss syncing dialog

    await OperationsProvider.instance.updateTaskStatus(
      task.id,
      'Completed',
      leadStatus: leadStatus,
      remarks: remarks,
      proof: proofPath,
      followUpDate: followUpDate,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      UiHelpers.showSnackBar(
        context,
        'Lead status updated successfully for ${task.studentName}!',
        Colors.green,
      );
    }
  }

  // Open Bulk Upload Bottom Sheet (BDM Flow)
  void _showBulkUploadBottomSheet(dynamic bdmUser) {
    final namesController = TextEditingController();
    final locationController = TextEditingController(text: 'Kakkanad, Kochi');
    String selectedCourse = 'Diploma in Advanced AI & ML';
    
    // Determine eligible BDEs under this team
    final List<String> bdeEmails = bdmUser.team == 'Ernakulam Team A'
        ? ['bde.ernakulam.a1@keralainstitute.org', 'bde.ernakulam.a2@keralainstitute.org']
        : bdmUser.team == 'Ernakulam Team B'
            ? ['bde.ernakulam.b1@keralainstitute.org']
            : ['bde.ernakulam.a1@keralainstitute.org']; // fallback

    String selectedBde = bdeEmails.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'BULK LEAD UPLOAD & ASSIGN',
                      style: TextStyle(color: AppColors.accentTeal, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 12),
                    
                    // Names input area
                    const Text('STUDENT NAMES (One per line or comma-separated)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: namesController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g.,\nSuresh Nair\nRohit Kumar\nDevika Pillai',
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Assign to BDE Dropdown
                    const Text('ASSIGN BDE MEMBER', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBde,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          onChanged: (val) {
                            if (val != null) setSheetState(() => selectedBde = val);
                          },
                          items: bdeEmails.map((email) {
                            return DropdownMenuItem<String>(
                              value: email,
                              child: Text(email.split('@').first.toUpperCase(), style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Course Dropdown
                    const Text('COURSE SCHEME', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCourse,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          onChanged: (val) {
                            if (val != null) setSheetState(() => selectedCourse = val);
                          },
                          items: [
                            'Diploma in Advanced AI & ML',
                            'Executive MBA & Digital Business',
                            'Full Stack Web Development & UI/UX',
                            'Certified Digital Marketing Specialist'
                          ].map((c) {
                            return DropdownMenuItem<String>(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Location Text field
                    const Text('VISIT DISTRICT/LOCATION', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: locationController,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(colors: AppColors.accentGradient),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                          onPressed: () async {
                            final rawText = namesController.text.trim();
                            if (rawText.isEmpty) {
                              UiHelpers.showSnackBar(context, 'Please enter at least one student name!', Colors.orange);
                              return;
                            }
                            // Parse names
                            final List<String> names = rawText
                                .split(RegExp(r'[\n,]'))
                                .map((n) => n.trim())
                                .where((n) => n.isNotEmpty)
                                .toList();

                            if (names.isEmpty) return;

                            int idx = 0;
                            final List<TaskModel> bulkTasks = names.map((name) {
                              final timestamp = DateTime.now().millisecondsSinceEpoch;
                              return TaskModel(
                                id: 'LD_${timestamp.toString().substring(9)}_${idx++}',
                                studentName: name,
                                location: locationController.text.trim(),
                                course: selectedCourse,
                                description: 'Bulk uploaded by BDM team lead.',
                                assignedDate: DateTime.now(),
                                assignedBdeEmail: selectedBde,
                                team: bdmUser.team!,
                                district: bdmUser.district!,
                                zone: bdmUser.zone!,
                              );
                            }).toList();

                            Navigator.pop(context);
                            
                            // Show progress dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const AlertDialog(
                                backgroundColor: Colors.white,
                                content: Row(
                                  children: [
                                    CircularProgressIndicator(color: AppColors.accentTeal),
                                    SizedBox(width: 20),
                                    Text('Routing & assigning leads...', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            );

                            await Future.delayed(const Duration(milliseconds: 1500));
                            Navigator.pop(context);

                            await OperationsProvider.instance.bulkUploadLeads(bulkTasks);

                            if (mounted) {
                              UiHelpers.showSnackBar(context, 'Uploaded and routed ${bulkTasks.length} leads successfully!', Colors.green);
                            }
                          },
                          child: const Text('Process & Assign Leads', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // Open BDE Single Lead Creation Sheet (Self-created leads flow)
  void _showBdeCreateLeadBottomSheet(dynamic bdeUser) {
    final nameController = TextEditingController();
    final locationController = TextEditingController(text: bdeUser.district ?? 'Ernakulam');
    final descController = TextEditingController(text: 'Self-created lead by BDE.');
    String selectedCourse = 'Diploma in Advanced AI & ML';
    String selectedFollowUpDate = DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 2)));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'CREATE NEW STUDENT LEAD',
                      style: TextStyle(color: AppColors.accentTeal, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 12),
                    
                    // Name
                    const Text('STUDENT FULL NAME', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g., Harish Kumar',
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Course
                    const Text('COURSE SCHEME', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCourse,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          onChanged: (val) {
                            if (val != null) setSheetState(() => selectedCourse = val);
                          },
                          items: [
                            'Diploma in Advanced AI & ML',
                            'Executive MBA & Digital Business',
                            'Full Stack Web Development & UI/UX',
                            'Certified Digital Marketing Specialist'
                          ].map((c) {
                            return DropdownMenuItem<String>(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Location
                    const Text('VISIT DISTRICT/LOCATION', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: locationController,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description / Notes
                    const Text('LEAD DESCRIPTION / NOTES', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Follow-up Date Simulation picker
                    const Text('SCHEDULE NEXT FOLLOW-UP DATE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 2)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            selectedFollowUpDate = DateFormat('dd MMM yyyy').format(picked);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(selectedFollowUpDate, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                            const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.accentTeal),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(colors: AppColors.accentGradient),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              UiHelpers.showSnackBar(context, 'Please enter a student name!', Colors.orange);
                              return;
                            }
                            
                            final timestamp = DateTime.now().millisecondsSinceEpoch;
                            final newLead = TaskModel(
                              id: 'LD_${timestamp.toString().substring(9)}',
                              studentName: name,
                              location: locationController.text.trim(),
                              course: selectedCourse,
                              description: descController.text.trim(),
                              assignedDate: DateTime.now(),
                              assignedBdeEmail: bdeUser.email,
                              team: bdeUser.team ?? 'Ernakulam Team A',
                              district: bdeUser.district ?? 'Ernakulam',
                              zone: bdeUser.zone ?? 'Central Zone',
                              creatorEmail: bdeUser.email,
                              status: 'Pending',
                              leadStatus: 'Interested',
                              followUpDate: selectedFollowUpDate,
                            );

                            Navigator.pop(context);
                            
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const AlertDialog(
                                backgroundColor: Colors.white,
                                content: Row(
                                  children: [
                                    CircularProgressIndicator(color: AppColors.accentTeal),
                                    SizedBox(width: 20),
                                    Text('Creating self-assigned lead...', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            );

                            await Future.delayed(const Duration(milliseconds: 1000));
                            Navigator.pop(context);

                            OperationsProvider.instance.addTask(newLead);

                            if (mounted) {
                              UiHelpers.showSnackBar(context, 'Lead created successfully!', Colors.green);
                            }
                          },
                          child: const Text('Create Lead & Schedule Visit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // Filter Tasks list locally for search and headers
  List<TaskModel> _getFilteredTasks(List<TaskModel> rawTasks) {
    var list = rawTasks;

    if (_searchQuery.isNotEmpty) {
      list = list.where((t) => t.studentName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_selectedBdeEmail != null && _selectedBdeEmail != 'All BDEs') {
      list = list.where((t) => t.assignedBdeEmail == _selectedBdeEmail).toList();
    }
    if (_selectedTeam != null && _selectedTeam != 'All Teams') {
      list = list.where((t) => t.team == _selectedTeam).toList();
    }
    if (_selectedDistrict != null && _selectedDistrict != 'All Districts') {
      list = list.where((t) => t.district == _selectedDistrict).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthProvider.instance.session;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'STUDENT LEADS & VISITS',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: AppColors.accentGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentTeal.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              tabs: const [
                Tab(text: 'ASSIGNED VISITS'),
                Tab(text: 'CLOSED / COMPLETE'),
              ],
            ),
          ),
        ),
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
        child: SafeArea(
          child: ListenableBuilder(
            listenable: OperationsProvider.instance,
            builder: (context, _) {
              final provider = OperationsProvider.instance;
              
              // Get filtered lists locally
              final allFiltered = _getFilteredTasks(provider.tasks);
              final pending = allFiltered.where((t) => t.status != 'Completed').toList();
              final completed = allFiltered.where((t) => t.status == 'Completed').toList();

              return Column(
                children: [
                  // Search & Filter header bar
                  _buildSearchAndFilters(provider, user),
                  
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTaskList(pending, isPending: true),
                        _buildTaskList(completed, isPending: false),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: user.role == 'BDM'
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accentTeal,
              icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
              label: const Text('Bulk Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => _showBulkUploadBottomSheet(user),
            )
          : user.role == 'BDE'
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.accentTeal,
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                  label: const Text('Create Lead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () => _showBdeCreateLeadBottomSheet(user),
                )
              : null,
    );
  }

  // Build local search and filters row
  Widget _buildSearchAndFilters(OperationsProvider provider, dynamic user) {
    // Dynamically limit filter options based on user role and territory restrictions
    final List<String> bdeOptions = ['All BDEs'];
    final List<String> teamOptions = ['All Teams'];
    final List<String> districtOptions = ['All Districts'];

    if (user.role == 'MD') {
      bdeOptions.addAll(provider.rawTasks.map((t) => t.assignedBdeEmail).toSet());
      teamOptions.addAll(provider.rawTasks.map((t) => t.team).toSet());
      districtOptions.addAll(provider.rawTasks.map((t) => t.district).toSet());
    } else if (user.role == 'ZM') {
      final zonalTasks = provider.rawTasks.where((t) => t.zone == user.zone).toList();
      bdeOptions.addAll(zonalTasks.map((t) => t.assignedBdeEmail).toSet());
      teamOptions.addAll(zonalTasks.map((t) => t.team).toSet());
      districtOptions.addAll(zonalTasks.map((t) => t.district).toSet());
    } else if (user.role == 'ASM') {
      final districtTasks = provider.rawTasks.where((t) => t.district == user.district).toList();
      bdeOptions.addAll(districtTasks.map((t) => t.assignedBdeEmail).toSet());
      teamOptions.addAll(districtTasks.map((t) => t.team).toSet());
    } else if (user.role == 'BDM') {
      final teamTasks = provider.rawTasks.where((t) => t.team == user.team).toList();
      bdeOptions.addAll(teamTasks.map((t) => t.assignedBdeEmail).toSet());
    }

    final bool showBdeFilter = user.role != 'BDE';
    final bool showTeamFilter = user.role == 'MD' || user.role == 'ZM' || user.role == 'ASM';
    final bool showDistrictFilter = user.role == 'MD' || user.role == 'ZM';

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Search Input
          TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search leads by student name...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentTeal, size: 18),
              filled: true,
              fillColor: AppColors.bgInput,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          
          if (showBdeFilter || showTeamFilter) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (showBdeFilter)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: bdeOptions.contains(_selectedBdeEmail) ? _selectedBdeEmail : 'All BDEs',
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          items: bdeOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value == 'All BDEs' ? 'All BDEs' : value.split('@').first.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedBdeEmail = val == 'All BDEs' ? null : val;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                if (showBdeFilter && showTeamFilter) const SizedBox(width: 8),
                if (showTeamFilter)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: teamOptions.contains(_selectedTeam) ? _selectedTeam : 'All Teams',
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          items: teamOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedTeam = val == 'All Teams' ? null : val;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (showDistrictFilter) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: districtOptions.contains(_selectedDistrict) ? _selectedDistrict : 'All Districts',
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        items: districtOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDistrict = val == 'All Districts' ? null : val;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskList(List<TaskModel> list, {required bool isPending}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.verified_rounded : Icons.folder_shared_rounded,
              color: AppColors.textSecondary.withOpacity(0.2),
              size: 64,
            ),
            const SizedBox(height: 14),
            const Text(
              'No Student Leads match criteria.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = list[index];
        final formattedDate = DateFormat('dd MMM yyyy').format(task.assignedDate);
        
        final Color statusColor = isPending
            ? AppColors.accentCyan
            : _getLeadStatusColor(task.leadStatus);

        return GestureDetector(
          onTap: () => _showTaskDetailsBottomSheet(task),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4,
                    child: Container(color: statusColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 18, right: 16, top: 16, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentTeal.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task.id,
                                style: const TextStyle(
                                  color: AppColors.accentTeal,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'Assigned: $formattedDate',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          task.studentName,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Course: ${task.course}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${task.location} (${task.district})',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        
                        // Management attribution badge
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'BDE: ${task.assignedBdeEmail.split('@').first.toUpperCase()} (${task.team})',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),

                        const Divider(color: Color(0xFFE2E8F0), height: 28),
                        if (isPending) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(colors: AppColors.accentGradient),
                                ),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () => _showTaskDetailsBottomSheet(task),
                                  icon: const Icon(Icons.assignment_outlined, size: 14, color: Colors.white),
                                  label: Text(
                                    AuthProvider.instance.session.role == 'BDE' ? 'Report Visit' : 'View File',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getLeadStatusColor(task.leadStatus).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  task.leadStatus.toUpperCase(),
                                  style: TextStyle(
                                    color: _getLeadStatusColor(task.leadStatus),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Row(
                                children: [
                                  Icon(Icons.verified_user_rounded, color: Colors.green, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Synced to Cloud',
                                    style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getLeadStatusColor(String status) {
    switch (status) {
      case 'Admitted':
        return Colors.green.shade700;
      case 'Interested':
        return Colors.blue.shade700;
      case 'Closed':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  void _showTaskDetailsBottomSheet(TaskModel task) {
    final bool isCompleted = task.status == 'Completed';
    final user = AuthProvider.instance.session;
    
    final formattedAssignedDate = DateFormat('dd MMM yyyy').format(task.assignedDate);
    final formattedCompletedDate = task.completedDate != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(task.completedDate!)
        : 'N/A';

    final remarksController = TextEditingController(text: task.remarks ?? '');
    String selectedLeadStatus = isCompleted ? task.leadStatus : 'Interested';
    String? proofPath = isCompleted ? task.completionProofPath : null;
    String selectedFollowUpDate = task.followUpDate ?? DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 2)));
    bool isUploadingProof = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LEAD VISIT FILE • ${task.id}',
                          style: const TextStyle(color: AppColors.accentTeal, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getLeadStatusColor(task.leadStatus).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.leadStatus.toUpperCase(),
                              style: TextStyle(color: _getLeadStatusColor(task.leadStatus), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      task.studentName,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 32),

                    _buildMetaRow('Location Visit Address', task.location, Icons.location_on_outlined),
                    const SizedBox(height: 8),
                    _buildMetaRow('Assigned On Date', formattedAssignedDate, Icons.calendar_today_outlined),
                    const SizedBox(height: 8),
                    _buildMetaRow('Manager Directive', task.description, Icons.assignment_outlined),
                    const SizedBox(height: 8),
                    _buildMetaRow('Assigned BDE Email', task.assignedBdeEmail, Icons.email_outlined),
                    const SizedBox(height: 8),
                    _buildMetaRow('Territory', '${task.zone} / ${task.district}', Icons.public_outlined),
                    if (task.followUpDate != null) ...[
                      const SizedBox(height: 8),
                      _buildMetaRow('Scheduled Follow-up', task.followUpDate!, Icons.next_plan_outlined),
                    ],
                    
                    if (isCompleted) ...[
                      const SizedBox(height: 8),
                      _buildMetaRow('Visit Resolved On', formattedCompletedDate, Icons.verified_rounded),
                      if (task.completionProofPath != null && task.completionProofPath != 'N/A') ...[
                        const SizedBox(height: 8),
                        _buildMetaRow('Attached Admission Proof', task.completionProofPath!, Icons.description_outlined),
                      ],
                      const Divider(color: Color(0xFFE2E8F0), height: 32),
                      const Text('VISIT REMARKS & LOGS', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(12)),
                        child: Text(task.remarks ?? 'No remarks provided.', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
                      ),
                      const SizedBox(height: 24),
                    ] else if (user.role != 'BDE') ...[
                      const Divider(color: Color(0xFFE2E8F0), height: 32),
                      const Text('VISIT DISPATCH STATUS', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Text(
                          'READ-ONLY VIEW:\nThis lead is dispatched to BDE ${task.assignedBdeEmail.split('@').first.toUpperCase()} under team ${task.team}. Only the assigned BDE can check in and submit visit reports.',
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 12, height: 1.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      const Divider(color: Color(0xFFE2E8F0), height: 32),
                      
                      const Text('REPORT VISIT STATUS', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black.withOpacity(0.06)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedLeadStatus,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                            items: ['Interested', 'Admitted', 'Closed'].map((val) {
                              return DropdownMenuItem<String>(value: val, child: Text(val));
                            }).toList(),
                            onChanged: (val) {
                              setSheetState(() {
                                selectedLeadStatus = val!;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('VISIT REMARKS / DISCUSSION NOTE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: remarksController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'e.g., Parent requested fee split options, positive response.',
                          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          filled: true,
                          fillColor: AppColors.bgInput,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.accentTeal),
                          ),
                        ),
                      ),

                      if (selectedLeadStatus == 'Interested') ...[
                        const SizedBox(height: 16),
                        const Text('SCHEDULE NEXT FOLLOW-UP DATE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 2)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              setSheetState(() {
                                selectedFollowUpDate = DateFormat('dd MMM yyyy').format(picked);
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.bgInput,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black.withOpacity(0.06)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(selectedFollowUpDate, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.accentTeal),
                              ],
                            ),
                          ),
                        ),
                      ],

                      if (selectedLeadStatus == 'Admitted') ...[
                        const SizedBox(height: 16),
                        const Text('UPLOAD PROOF (RECEIPT / ADMISSION FORM)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: isUploadingProof
                              ? null
                              : () async {
                                  setSheetState(() => isUploadingProof = true);
                                  await Future.delayed(const Duration(seconds: 1));
                                  setSheetState(() {
                                    isUploadingProof = false;
                                    proofPath = 'proof_${task.studentName.toLowerCase().replaceAll(' ', '_')}.jpg';
                                  });
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.bgInput,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: proofPath != null ? Colors.green.shade400 : Colors.black.withOpacity(0.06)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  proofPath != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                                  color: proofPath != null ? Colors.green.shade700 : AppColors.accentTeal,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isUploadingProof
                                        ? 'Uploading file...'
                                        : proofPath ?? 'Tap to capture / upload document receipt image',
                                    style: TextStyle(color: proofPath != null ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(colors: AppColors.accentGradient),
                            boxShadow: [
                              BoxShadow(color: AppColors.accentTeal.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    if (remarksController.text.trim().isEmpty) {
                                      UiHelpers.showSnackBar(context, 'Please fill in visit remarks!', Colors.orange);
                                      return;
                                    }
                                    if (selectedLeadStatus == 'Admitted' && proofPath == null) {
                                      UiHelpers.showSnackBar(context, 'Please upload a proof document!', Colors.orange);
                                      return;
                                    }
                                    Navigator.pop(context);
                                    _submitVisitReport(
                                      task: task,
                                      leadStatus: selectedLeadStatus,
                                      remarks: remarksController.text.trim(),
                                      proofPath: selectedLeadStatus == 'Admitted' ? proofPath! : 'N/A',
                                      followUpDate: selectedLeadStatus == 'Interested' ? selectedFollowUpDate : null,
                                    );
                                  },
                            icon: const Icon(Icons.cloud_done_rounded, color: Colors.white),
                            label: const Text('Submit Visit Report & Sync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetaRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
