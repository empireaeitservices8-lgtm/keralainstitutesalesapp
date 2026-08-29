import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:keralainstitutesalesapp/api/api_response.dart';
import 'package:keralainstitutesalesapp/models/user_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/exceptions/api_exception.dart';
import '../api/exceptions/network_exception.dart';
import '../models/beat_plan_model.dart';
import '../models/lead_model.dart';
import '../models/task_model.dart';
import '../models/incentive_model.dart';
import '../models/leave_model.dart';
import '../models/eod_model.dart';
import '../models/training_video_model.dart';
import '../models/lead_import_response.dart';
import 'auth_provider.dart';
import 'user_profile_provider.dart';

class OperationsProvider extends ChangeNotifier {
  static final OperationsProvider instance = OperationsProvider._internal();
  OperationsProvider._internal();

  bool _isSubmittingEod = false;
  bool _isSubmittingTask = false;
  bool _isImportingLeads = false;

  String _taskSearchQuery = '';
  String? _selectedBdeEmail;
  String? _selectedTeam;
  String? _selectedDistrict;
  int? _selectedBdeId;
  int? _selectedTeamId;
  int? _selectedDistrictId;
  String? _selectedAsmEmail;
  int? _selectedAsmId;
  String? _selectedBdmEmail;
  int? _selectedBdmId;

  int? get selectedBdeId => _selectedBdeId;
  int? get selectedTeamId => _selectedTeamId;
  int? get selectedDistrictId => _selectedDistrictId;
  String? get selectedAsmEmail => _selectedAsmEmail;
  int? get selectedAsmId => _selectedAsmId;
  String? get selectedBdmEmail => _selectedBdmEmail;
  int? get selectedBdmId => _selectedBdmId;

  List<Map<String, dynamic>> _hierarchyDistricts = [];
  List<Map<String, dynamic>> get hierarchyDistricts => _hierarchyDistricts;

  List<Map<String, dynamic>> _hierarchyTeams = [];
  List<Map<String, dynamic>> get hierarchyTeams => _hierarchyTeams;

  List<Map<String, dynamic>> _hierarchyBdes = [];
  List<Map<String, dynamic>> get hierarchyBdes => _hierarchyBdes;

  List<Map<String, dynamic>> _hierarchyBdms = [];
  List<Map<String, dynamic>> get hierarchyBdms => _hierarchyBdms;

  List<Map<String, dynamic>> _hierarchyAsms = [];
  List<Map<String, dynamic>> get hierarchyAsms => _hierarchyAsms;

  bool _isLoadingHierarchyFilters = false;
  bool get isLoadingHierarchyFilters => _isLoadingHierarchyFilters;

  void setSelectedBde(String? name, int? id) {
    _selectedBdeEmail = name;
    _selectedBdeId = id;
    if (id != null) {
      _selectedAsmEmail = null;
      _selectedAsmId = null;
      _selectedBdmEmail = null;
      _selectedBdmId = null;
    }
    notifyListeners();
  }

  void setSelectedAsm(String? name, int? id) {
    _selectedAsmEmail = name;
    _selectedAsmId = id;
    if (id != null) {
      _selectedBdmEmail = null;
      _selectedBdmId = null;
      _selectedBdeEmail = null;
      _selectedBdeId = null;
    }
    notifyListeners();
  }

  void setSelectedBdm(String? name, int? id) {
    _selectedBdmEmail = name;
    _selectedBdmId = id;
    if (id != null) {
      _selectedAsmEmail = null;
      _selectedAsmId = null;
      _selectedBdeEmail = null;
      _selectedBdeId = null;
    }
    notifyListeners();
  }

  bool get isSubmittingEod => _isSubmittingEod;
  bool get isSubmittingTask => _isSubmittingTask;
  bool get isImportingLeads => _isImportingLeads;

  String get taskSearchQuery => _taskSearchQuery;
  String? get selectedBdeEmail => _selectedBdeEmail;
  String? get selectedTeam => _selectedTeam;
  String? get selectedDistrict => _selectedDistrict;

  void setTaskSearchQuery(String query) {
    _taskSearchQuery = query;
    notifyListeners();
  }

  void setSelectedBdeEmail(String? email) {
    _selectedBdeEmail = email;
    notifyListeners();
  }

  void setSelectedTeam(String? team, [int? teamId]) {
    _selectedTeam = team;
    _selectedTeamId = teamId;
    notifyListeners();
  }

  void setSelectedDistrict(String? district, [int? districtId]) {
    _selectedDistrict = district;
    _selectedDistrictId = districtId;
    notifyListeners();
  }

  List<BeatPlanModel> _beatPlans = [];
  List<TaskModel> _tasks = [];
  List<IncentiveModel> _incentives = [];
  List<LeaveModel> _leaves = [];
  List<TrainingVideoModel> _trainingVideos = [];
  EodModel _todayEod = EodModel.empty();

  int _leaveBalanceCasual = 8;
  int _leaveBalanceMedical = 4;
  int _leaveBalanceEarned = 10;

  // Selected district filter for ZM Dashboard
  String? _selectedDistrictFilter;
  bool _isLeavesLoaded = false;
  bool _isLoadingLeaves = false;
  bool get isLoadingLeaves => _isLoadingLeaves;

  // Getters (filtered dynamically based on user session role & zone/district)
  List<BeatPlanModel> get beatPlans {
    final user = AuthProvider.instance.session;
    if (user.isEmpty) return [];
    return _filterBeatPlans(user);
  }

  List<TaskModel> get tasks {
    final user = AuthProvider.instance.session;
    if (user.isEmpty) return [];
    return _filterTasks(user);
  }

  List<IncentiveModel> get incentives => _incentives;
  List<LeaveModel> get leaves => _leaves;
  List<TrainingVideoModel> get trainingVideos => _trainingVideos;
  EodModel get todayEod => _todayEod;

  int get leaveBalanceCasual => _leaveBalanceCasual;
  int get leaveBalanceMedical => _leaveBalanceMedical;
  int get leaveBalanceEarned => _leaveBalanceEarned;

  String? get selectedDistrictFilter => _selectedDistrictFilter;

  // Reactive Stats for Home Dashboard (calculated on filtered items)
  int get completedVisitsCount => beatPlans.where((v) => v.isVisited).length;
  int get pendingVisitsCount => beatPlans.where((v) => !v.isVisited).length;
  int get totalVisitsCount => beatPlans.length;

  int get completedTasksCount =>
      tasks.where((t) => t.status == 'Completed').length;
  int get pendingTasksCount =>
      tasks.where((t) => t.status != 'Completed').length;

  double get totalEarnedIncentives => _incentives
      .where((i) => i.status == 'Approved' || i.status == 'Paid')
      .fold(0.0, (sum, item) => sum + item.amount);

  int get totalLeavesTakenThisMonth => _leaves
      .where(
        (l) =>
            l.status == 'Approved' && l.fromDate.month == DateTime.now().month,
      )
      .length;

  // ZM filter setter
  void setDistrictFilter(String? district) {
    _selectedDistrictFilter = district;
    notifyListeners();
  }

  // Raw underlying lists for MD/Admin use
  List<TaskModel> get rawTasks => _tasks;
  List<BeatPlanModel> get rawBeatPlans => _beatPlans;

  List<TaskModel> _filterTasks(dynamic user) {
    final String role = user.role;
    debugPrint('[TaskFilter] role=$role, tasks=${_tasks.length}, userEmail=${user.email}');
    switch (role) {
      case 'MD':
        return _tasks;
      case 'ZM':
        // If zone info isn't in API data yet, return all tasks
        final zoneFiltered = _tasks.where((t) => t.zone == user.zone || t.zone == null || t.zone.isEmpty).toList();
        if (_selectedDistrictFilter != null &&
            _selectedDistrictFilter!.isNotEmpty) {
          return zoneFiltered
              .where((t) => t.district == _selectedDistrictFilter)
              .toList();
        }
        return zoneFiltered;
      case 'ASM':
        return _tasks.where((t) => t.district == user.district || (user.district == null || user.district.isEmpty)).toList();
      case 'BDM':
        return _tasks.where((t) => t.team == user.team || (user.team == null || user.team.isEmpty)).toList();
      case 'BDE':
      default:
        // API already scopes results to the authenticated user via Bearer token.
        // Return all tasks directly — no need to re-filter by email.
        debugPrint('[TaskFilter] BDE → returning all ${_tasks.length} tasks');
        return _tasks;
    }
  }

  List<BeatPlanModel> _filterBeatPlans(dynamic user) {
    final String role = user.role;
    switch (role) {
      case 'MD':
        return _beatPlans;
      case 'ZM':
        var list = _beatPlans.where((v) => v.zone == user.zone).toList();
        if (_selectedDistrictFilter != null &&
            _selectedDistrictFilter!.isNotEmpty) {
          list = list
              .where((v) => v.district == _selectedDistrictFilter)
              .toList();
        }
        return list;
      case 'ASM':
        return _beatPlans.where((v) => v.district == user.district).toList();
      case 'BDM':
        return _beatPlans.where((v) => v.team == user.team).toList();
      case 'BDE':
      default:
        return _beatPlans
            .where((v) => v.assignedBdeEmail == user.email)
            .toList();
    }
  }

  Future<void> saveFollowUp(String leadId, DateTime combinedDateTime, String remark) async {
    // 1. Call API
    final numericId = int.tryParse(leadId.replaceFirst('LD_', ''));
    if (numericId != null) {
      final formattedApiDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(combinedDateTime);
      await ApiClient.instance.post(
        ApiEndpoints.followUpLead(numericId),
        data: {
          'followup_date': formattedApiDate,
          'notes': remark,
        },
      );
    }
  }

  /// Load data from local persistence or generate defaults
  Future<void> loadOperationsData({bool isRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Load Leaves & Balances
    _leaveBalanceCasual = prefs.getInt('leave_bal_casual') ?? 8;
    _leaveBalanceMedical = prefs.getInt('leave_bal_medical') ?? 4;
    _leaveBalanceEarned = prefs.getInt('leave_bal_earned') ?? 10;

    // Set Mock Leaves if empty
    if (_leaves.isEmpty) {
      _leaves = [
        LeaveModel(
          id: 'LV_101',
          leaveType: 'Casual Leave',
          fromDate: DateTime.now().subtract(const Duration(days: 15)),
          toDate: DateTime.now().subtract(const Duration(days: 14)),
          reason: 'Personal work in native town.',
          status: 'Approved',
          appliedDate: DateTime.now().subtract(const Duration(days: 20)),
        ),
        LeaveModel(
          id: 'LV_102',
          leaveType: 'Medical Leave',
          fromDate: DateTime.now().subtract(const Duration(days: 5)),
          toDate: DateTime.now().subtract(const Duration(days: 5)),
          reason: 'Severe fever and doctor consultation.',
          status: 'Approved',
          appliedDate: DateTime.now().subtract(const Duration(days: 6)),
        ),
      ];
    }

    // Set Mock Incentives if empty
    if (_incentives.isEmpty) {
      _incentives = [
        IncentiveModel(
          id: 'INC_001',
          category: 'Sales Target',
          amount: 3500.00,
          remarks: 'Achieved 100% of July volume target.',
          date: DateTime.now().subtract(const Duration(days: 3)),
          status: 'Paid',
        ),
        IncentiveModel(
          id: 'INC_002',
          category: 'New Client',
          amount: 1500.00,
          remarks: 'Acquired 5 new retail outlets.',
          date: DateTime.now().subtract(const Duration(days: 1)),
          status: 'Approved',
        ),
        IncentiveModel(
          id: 'INC_003',
          category: 'Route Bonus',
          amount: 500.00,
          remarks: 'Completed 100% of planned beat route sequence.',
          date: DateTime.now(),
          status: 'Pending',
        ),
      ];
    }

    // Set Mock Training Videos if empty
    if (_trainingVideos.isEmpty) {
      _trainingVideos = [
        TrainingVideoModel(
          id: 'VID_001',
          title: 'KIDE Advanced AI & ML Pitching',
          description:
              'Learn the core syllabus details for AI/ML, career prospects, and post-graduate placements to pitch parents.',
          duration: '6 min 15 sec',
          difficulty: 'Beginner',
          videoUrl: 'https://www.youtube.com/watch?v=2ePf97aNfCo',
        ),
        TrainingVideoModel(
          id: 'VID_002',
          title: 'Handling Parent & Fee Concerns',
          description:
              'How to handle common questions regarding course fees, monthly installment options, and scholarship criteria.',
          duration: '5 min 45 sec',
          difficulty: 'Intermediate',
          videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        TrainingVideoModel(
          id: 'VID_003',
          title: 'Pitching Cyber Security & Dev Ops',
          description:
              'Guide to explaining online-hybrid program tracks, industrial tie-ups, and placement eligibility checks.',
          duration: '4 min 30 sec',
          difficulty: 'Intermediate',
          videoUrl: 'https://www.youtube.com/watch?v=nz20e0Q6ZkE',
        ),
        TrainingVideoModel(
          id: 'VID_004',
          title: 'Logging Biometric Reports & Proofs',
          description:
              'Tutorial on capturing correct document/selfie proof and selecting the appropriate status for student leads.',
          duration: '3 min 12 sec',
          difficulty: 'Beginner',
          videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
      ];
    }

    // Set mock tasks removed. Live leads are loaded dynamically from /leads API below.

    // Set Mock Beat Plans representing the hierarchy
    if (_beatPlans.isEmpty) {
      _beatPlans = [
        BeatPlanModel(
          id: 'BP_301',
          customerName: 'Govt. Model School Drive',
          address: 'Model School Junction, Kochi (45 Leads Assigned)',
          sequence: 1,
          scheduleTime: '10:00 AM',
          distanceKm: 2.4,
          latitude: 9.9764,
          longitude: 76.2863,
          isVisited: true,
          checkInTime: DateTime.now().subtract(const Duration(hours: 3)),
          selfiePath: 'campus_selfie.jpg',
          visitNotes:
              'Completed counselling session, 12 admissions registered.',
          orderValue: 150000.0,
          status: 'Completed',
          assignedBdeEmail: 'bde.ernakulam.a1@keralainstitute.org',
          team: 'Ernakulam Team A',
          district: 'Ernakulam',
          zone: 'Central Zone',
        ),
        BeatPlanModel(
          id: 'BP_302',
          customerName: 'Calicut Arts College Campus',
          address: 'Calicut Bypass Road, Kozhikode (80 Leads Assigned)',
          sequence: 2,
          scheduleTime: '11:30 AM',
          distanceKm: 1.8,
          latitude: 9.9880,
          longitude: 76.3021,
          isVisited: true,
          checkInTime: DateTime.now().subtract(const Duration(hours: 1)),
          selfiePath: 'college_drive.jpg',
          visitNotes:
              'Document collection drive completed. Verified 18 applications.',
          orderValue: 0.0,
          status: 'Completed',
          assignedBdeEmail: 'bde.kozhikode.a1@keralainstitute.org',
          team: 'Kozhikode Team A',
          district: 'Kozhikode',
          zone: 'North Zone',
        ),
        BeatPlanModel(
          id: 'BP_303',
          customerName: 'Adarsh Nair (Student House)',
          address: 'Nair Villa, Kakkanad, Kochi (High Match Lead - CS)',
          sequence: 3,
          scheduleTime: '02:00 PM',
          distanceKm: 12.5,
          latitude: 11.2502,
          longitude: 75.7873,
          assignedBdeEmail: 'bde.ernakulam.a2@keralainstitute.org',
          team: 'Ernakulam Team A',
          district: 'Ernakulam',
          zone: 'Central Zone',
        ),
        BeatPlanModel(
          id: 'BP_304',
          customerName: 'Trivandrum Job Fair Venue',
          address: 'Luminar Expo Hall, Trivandrum (120 leads uploaded by Head)',
          sequence: 4,
          scheduleTime: '04:15 PM',
          distanceKm: 45.2,
          latitude: 8.5241,
          longitude: 76.9366,
          assignedBdeEmail: 'bde.trivandrum.a1@keralainstitute.org',
          team: 'Trivandrum Team A',
          district: 'Thiruvananthapuram',
          zone: 'South Zone',
        ),
        BeatPlanModel(
          id: 'BP_311',
          customerName: 'Thrissur Round Retail Survey',
          address: 'Vadakkunnathan North Gate, Thrissur',
          sequence: 1,
          scheduleTime: '10:15 AM',
          distanceKm: 4.5,
          latitude: 10.5276,
          longitude: 76.2144,
          isVisited: true,
          checkInTime: DateTime.now().subtract(const Duration(hours: 4)),
          selfiePath: 'thrissur_survey.jpg',
          visitNotes:
              'Collected feedback from 15 merchants. Registered 3 follow-ups.',
          status: 'Completed',
          assignedBdeEmail: 'bde.thrissur.a1@keralainstitute.org',
          team: 'Thrissur Team A',
          district: 'Thrissur',
          zone: 'Central Zone',
        ),
        BeatPlanModel(
          id: 'BP_312',
          customerName: 'Kollam Beach Job Fair Drive',
          address: 'Kollam Beach Pavilion, Kollam',
          sequence: 1,
          scheduleTime: '11:00 AM',
          distanceKm: 8.2,
          latitude: 8.8821,
          longitude: 76.5779,
          assignedBdeEmail: 'bde.kollam.a1@keralainstitute.org',
          team: 'Kollam Team A',
          district: 'Kollam',
          zone: 'South Zone',
        ),
        BeatPlanModel(
          id: 'BP_313',
          customerName: 'Kannur Town Hall Seminar',
          address: 'Town Hall Junction, Kannur',
          sequence: 1,
          scheduleTime: '09:45 AM',
          distanceKm: 3.1,
          latitude: 11.8745,
          longitude: 75.3704,
          assignedBdeEmail: 'bde.kannur.a1@keralainstitute.org',
          team: 'Kannur Team A',
          district: 'Kannur',
          zone: 'North Zone',
        ),
      ];
    }

    final isSubmitted = prefs.getBool('eod_submitted') ?? false;
    if (isSubmitted) {
      _todayEod = EodModel(
        id: 'EOD_TODAY',
        totalVisits: prefs.getInt('eod_visits') ?? 0,
        leadsCreated: prefs.getInt('eod_leads') ?? 0,
        followUpsScheduled: prefs.getInt('eod_followups') ?? 0,
        pendingVisits: prefs.getInt('eod_pending') ?? 0,
        remarks: prefs.getString('eod_remarks') ?? '',
        dailySummary: prefs.getString('eod_summary') ?? '',
        submissionTime: DateTime.parse(
          prefs.getString('eod_time') ?? DateTime.now().toIso8601String(),
        ),
        isSubmitted: true,
      );
    } else {
      _todayEod = EodModel.empty();
    }

    // Fetch live leaves from API
    await fetchLeaves(isRefresh: isRefresh);

    notifyListeners();
  }

  /// Fetch leaves from remote API GET /api/leaves
  Future<void> fetchLeaves({bool isRefresh = false}) async {
    if (_isLoadingLeaves) return;
    if (!isRefresh && _isLeavesLoaded) return;
    _isLoadingLeaves = true;
    notifyListeners();

    try {
      final response = await ApiClient.instance.get(ApiEndpoints.leaves);
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];

        // Update balances
        if (data['balances'] != null) {
          final balances = data['balances'];
          _leaveBalanceCasual = balances['casual'] ?? _leaveBalanceCasual;
          _leaveBalanceMedical = balances['medical'] ?? _leaveBalanceMedical;
          _leaveBalanceEarned = balances['earned'] ?? _leaveBalanceEarned;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('leave_bal_casual', _leaveBalanceCasual);
          await prefs.setInt('leave_bal_medical', _leaveBalanceMedical);
          await prefs.setInt('leave_bal_earned', _leaveBalanceEarned);
        }

        // Update leave history list
        if (data['history'] != null) {
          final List<dynamic> history = data['history'];
          _leaves = history.map((item) {
            final id = item['id'].toString();
            final typeName = item['type_name'] ?? '';
            String mappedLeaveType = typeName;
            if (mappedLeaveType.isNotEmpty &&
                !mappedLeaveType.toLowerCase().contains('leave')) {
              mappedLeaveType = '$mappedLeaveType Leave';
            }
            final fromDate =
                DateTime.tryParse(item['start_date'] ?? '') ?? DateTime.now();
            final toDate =
                DateTime.tryParse(item['end_date'] ?? '') ?? DateTime.now();
            final reason = item['reason'] ?? '';
            final status = item['status_name'] ?? 'Pending';
            final appliedDate =
                DateTime.tryParse(item['applied_on'] ?? '') ?? DateTime.now();

            return LeaveModel(
              id: id,
              leaveType: mappedLeaveType,
              fromDate: fromDate,
              toDate: toDate,
              reason: reason,
              status: status,
              appliedDate: appliedDate,
            );
          }).toList();
        }

        // Update UserProfileProvider leave balances to keep them in sync
        final profileState = UserProfileProvider.instance.state;
        if (profileState.data != null) {
          final profile = profileState.data!;
          final updatedProfile = UserProfileModel(
            name: profile.name,
            designation: profile.designation,
            email: profile.email,
            contactNumber: profile.contactNumber,
            employeeId: profile.employeeId,
            leaveBalances: LeaveBalances(
              casual: _leaveBalanceCasual,
              medical: _leaveBalanceMedical,
              earned: _leaveBalanceEarned,
            ),
          );
          UserProfileProvider.instance.setState(
            ApiResponse.success(updatedProfile),
          );
        }

        _isLeavesLoaded = true;
      }
    } catch (e) {
      debugPrint('Error fetching leaves: $e');
    } finally {
      _isLoadingLeaves = false;
      notifyListeners();
    }
  }

  /// Reset all simulation logs to defaults (testing shortcut)
  Future<void> resetOperations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('leave_bal_casual');
    await prefs.remove('leave_bal_medical');
    await prefs.remove('leave_bal_earned');
    await prefs.remove('eod_submitted');
    await prefs.remove('eod_visits');
    await prefs.remove('eod_leads');
    await prefs.remove('eod_followups');
    await prefs.remove('eod_pending');
    await prefs.remove('eod_remarks');
    await prefs.remove('eod_summary');
    await prefs.remove('eod_time');

    _beatPlans.clear();
    _tasks.clear();
    _completedTasks.clear();
    _incentives.clear();
    for (var video in _trainingVideos) {
      video.isCompleted = false;
    }
    _leaves.clear();
    _todayEod = EodModel.empty();
    _selectedDistrictFilter = null;
    _isLeavesLoaded = false;

    await loadOperationsData();
  }

  // --- Beat Plan Actions ---

  /// Check-in at a customer location
  Future<void> checkInVisit(
    String id,
    String selfie,
    double lat,
    double lng,
  ) async {
    final index = _beatPlans.indexWhere((v) => v.id == id);
    if (index != -1) {
      _beatPlans[index] = _beatPlans[index].copyWith(
        isVisited: true,
        checkInTime: DateTime.now(),
        selfiePath: selfie,
        status: 'Completed',
      );
      notifyListeners();
    }
  }

  /// Log activities during visit
  Future<void> logVisitActivities(
    String id, {
    required String notes,
    required double orderValue,
    required String followUp,
    String? attachment,
  }) async {
    final index = _beatPlans.indexWhere((v) => v.id == id);
    if (index != -1) {
      _beatPlans[index] = _beatPlans[index].copyWith(
        visitNotes: notes,
        orderValue: orderValue,
        followUpDate: followUp,
        attachmentPath: attachment,
      );
      notifyListeners();
    }
  }

  // --- Task Actions ---

  /// Update task status (Student Lead admission / close)
  Future<void> updateTaskStatus(
    String id,
    String status, {
    required String leadStatus,
    required String remarks,
    required String proof,
    String? followUpDate,
  }) async {
    _isSubmittingTask = true;
    notifyListeners();
    try {
      // If the BDE is closing the lead, hit the dedicated close endpoint.
      // Only `remark` is required — no schedule_date or status field.
      if (leadStatus == 'Closed') {
        // Task IDs are stored as 'LD_<numericId>' — extract the numeric part.
        final numericId = int.tryParse(id.replaceFirst('LD_', ''));
        if (numericId != null) {
          await ApiClient.instance.post(
            ApiEndpoints.closeLead(numericId),
            data: {
              'remarks': remarks,
            },
          );
        }
      }

      // Update local state to reflect the change immediately in the UI.
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final currentTask = _tasks[index];
        List<FollowUpItem>? updatedFollowUps = currentTask.followUps;
        if (followUpDate != null && followUpDate.isNotEmpty) {
          updatedFollowUps = List<FollowUpItem>.from(currentTask.followUps ?? [])
            ..add(FollowUpItem(dateTime: followUpDate, remark: remarks));
        }

        _tasks[index] = currentTask.copyWith(
          status: status,
          leadStatus: leadStatus,
          completedDate: status == 'Completed' ? DateTime.now() : null,
          completionProofPath: proof,
          remarks: remarks,
          followUps: updatedFollowUps,
        );
      }

      // Refresh lead lists so the UI reflects the latest server state.
      await fetchLeads(status: 1);
    } catch (e) {
      debugPrint('[updateTaskStatus] ERROR: $e');
      rethrow;
    } finally {
      _isSubmittingTask = false;
      notifyListeners();
    }
  }


  /// Bulk Lead Upload & Assign (For BDM/TL)
  Future<void> bulkUploadLeads(List<TaskModel> newLeads) async {
    _tasks.insertAll(0, newLeads);
    notifyListeners();
  }

  /// Import Leads from File via API
  /// POST /leads/import
  Future<LeadImportResult?> importLeads(File file) async {
    _isImportingLeads = true;
    notifyListeners();
    try {
      final fileName = file.path.split(RegExp(r'[/\\]')).last;
      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType.parse('text/csv'),
      );

      final response = await ApiClient.instance.uploadMultipart(
        ApiEndpoints.importLeads,
        data: {
          'file': multipartFile,
        },
      );

      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data as Map<String, dynamic>;
        return LeadImportResult.fromJson(responseData);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to import leads from file: $e');
      rethrow;
    } finally {
      _isImportingLeads = false;
      notifyListeners();
    }
  }

  /// Add single lead dynamically (BDM or Self-created by BDE)
  void addTask(TaskModel item) {
    _tasks.insert(0, item);
    notifyListeners();
  }

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> get courses => _courses;
  bool _isLoadingCourses = false;
  bool get isLoadingCourses => _isLoadingCourses;

  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> get districts => _districts;
  bool _isLoadingDistricts = false;
  bool get isLoadingDistricts => _isLoadingDistricts;

  Future<void> fetchCourses({bool isRefresh = false}) async {
    if (_isLoadingCourses) return;
    if (!isRefresh && _courses.isNotEmpty) return;
    _isLoadingCourses = true;
    notifyListeners();
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.courses);
      if (response.data != null) {
        final Map<String, dynamic> data = response.data['data'] as Map<String, dynamic>;
        final List<dynamic> list = data['courses'] as List<dynamic>;
        _courses = list.map((c) => c as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch courses from server: $e');
    } finally {
      _isLoadingCourses = false;
      notifyListeners();
    }
  }

  Future<void> fetchDistricts({bool isRefresh = false}) async {
    if (_isLoadingDistricts) return;
    if (!isRefresh && _districts.isNotEmpty) return;
    _isLoadingDistricts = true;
    notifyListeners();
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.districts);
      if (response.data != null) {
        final List<dynamic> list = response.data['data'] as List<dynamic>;
        _districts = list.map((d) => d as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch districts from server: $e');
    } finally {
      _isLoadingDistricts = false;
      notifyListeners();
    }
  }

  Future<void> fetchHierarchyFilters({bool isRefresh = false}) async {
    if (_isLoadingHierarchyFilters) return;
    if (!isRefresh && _hierarchyDistricts.isNotEmpty) return;
    _isLoadingHierarchyFilters = true;
    notifyListeners();
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.hierarchyFilters);
      if (response.data != null && response.data['success'] == true) {
        final Map<String, dynamic> data = response.data['data'] is Map<String, dynamic>
            ? response.data['data'] as Map<String, dynamic>
            : {};
        
        final rawDistricts = data['districts'];
        final List<dynamic> districtsList = (rawDistricts is List<dynamic>) ? rawDistricts : [];
        _hierarchyDistricts = districtsList.map((d) => d as Map<String, dynamic>).toList();

        final rawTeams = data['teams'];
        final List<dynamic> teamsList = (rawTeams is List<dynamic>) ? rawTeams : [];
        _hierarchyTeams = teamsList.map((t) => t as Map<String, dynamic>).toList();

        final rawEmployees = data['employees'];
        final Map<String, dynamic> employeesMap = (rawEmployees is Map<String, dynamic>) ? rawEmployees : {};
        
        if (employeesMap['BDE'] is List<dynamic>) {
          final List<dynamic> bdeList = employeesMap['BDE'] as List<dynamic>;
          _hierarchyBdes = bdeList.map((b) => b as Map<String, dynamic>).toList();
        } else {
          _hierarchyBdes = [];
        }

        if (employeesMap['BDM'] is List<dynamic>) {
          final List<dynamic> bdmList = employeesMap['BDM'] as List<dynamic>;
          _hierarchyBdms = bdmList.map((b) => b as Map<String, dynamic>).toList();
        } else {
          _hierarchyBdms = [];
        }

        if (employeesMap['ASM'] is List<dynamic>) {
          final List<dynamic> asmList = employeesMap['ASM'] as List<dynamic>;
          _hierarchyAsms = asmList.map((a) => a as Map<String, dynamic>).toList();
        } else {
          _hierarchyAsms = [];
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch hierarchy filters: $e');
    } finally {
      _isLoadingHierarchyFilters = false;
      notifyListeners();
    }
  }

  static const int STATUS_NEW = 1;
  static const int STATUS_WON = 4;
  static const int STATUS_LOST = 5;

  bool _isLoadingLeads = false;
  bool get isLoadingLeads => _isLoadingLeads;

  List<TaskModel> _completedTasks = [];
  List<TaskModel> get completedTasks => _completedTasks;
  bool _isLoadingCompletedLeads = false;
  bool get isLoadingCompletedLeads => _isLoadingCompletedLeads;

  /// Converts a [LeadModel] to the [TaskModel] used by the UI.
  TaskModel _mapLead(LeadModel lead) {
    final currentUser = AuthProvider.instance.session;
    final zoneName  = currentUser.zone  ?? '';
    final teamName  = currentUser.team  ?? '';
    
    final leadId = 'LD_${lead.id}';

    // Map API follow-ups to FollowUpItem
    final apiFollowUps = lead.followups?.map((f) {
      String formattedDate = f.followupDate;
      try {
        final parsed = DateTime.parse(f.followupDate);
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
      } catch (_) {
        // Fallback to original
      }
      return FollowUpItem(
        dateTime: formattedDate,
        remark: f.notes ?? '',
      );
    }).toList() ?? [];

    // API already scopes results via Bearer token; use session values as fallback.
    return TaskModel(
      id: leadId,
      studentName: lead.name,
      location: lead.address,
      course: lead.course?.name ?? '',
      description: lead.notes,
      assignedDate: lead.createdAt,
      assignedBdeEmail: currentUser.email,
      team: teamName,
      district: lead.district?.name ?? currentUser.district ?? '',
      zone: zoneName,
      creatorEmail: currentUser.email,
      status: lead.isCompleted ? 'Completed' : 'Pending',
      leadStatus: lead.statusLabel,
      followUps: apiFollowUps,
      phone: lead.phone,
      email: lead.email,
    );
  }

  /// // Fetches pending leads (status=1) and populates [tasks].
  Future<void> fetchLeads({int status = 1, int? employeeId, int? teamId, int? districtId, bool isRefresh = false}) async {
    if (_isLoadingLeads) return;
    if (!isRefresh && _tasks.isNotEmpty && employeeId == null && teamId == null && districtId == null) return;
    _isLoadingLeads = true;
    notifyListeners();
    try {
      final Map<String, dynamic> queryParams = {'status': status};
      final activeEmployeeId = employeeId ?? _selectedBdeId ?? _selectedBdmId ?? _selectedAsmId;
      if (activeEmployeeId != null) {
        queryParams['employee_id'] = activeEmployeeId;
      }
      final activeTeamId = teamId ?? _selectedTeamId;
      if (activeTeamId != null) {
        queryParams['team_id'] = activeTeamId;
      }
      final activeDistrictId = districtId ?? _selectedDistrictId;
      if (activeDistrictId != null) {
        queryParams['district_id'] = activeDistrictId;
      }

      final response = await ApiClient.instance.get(
        ApiEndpoints.leads,
        queryParameters: queryParams,
      );
      if (response.data != null && response.data['success'] == true) {
        final leadsPage = LeadsPage.fromJson(
          response.data['data']['leads'] as Map<String, dynamic>,
        );
        final allMapped = leadsPage.data.map(_mapLead).toList();
        _tasks = allMapped.where((t) => t.status == 'Pending').toList();
        debugPrint('[fetchLeads] status=1, employee_id=$activeEmployeeId, team_id=$activeTeamId, district_id=$activeDistrictId → ${_tasks.length} pending leads loaded');
      }
    } catch (e, st) {
      debugPrint('[fetchLeads] ERROR: $e\n$st');
    } finally {
      _isLoadingLeads = false;
      notifyListeners();
    }
  }

  /// Fetches completed leads (status=4 and status=5) and populates [completedTasks].
  Future<void> fetchCompletedLeads({int? employeeId, int? teamId, int? districtId, bool isRefresh = false}) async {
    if (_isLoadingCompletedLeads) return;
    if (!isRefresh && _completedTasks.isNotEmpty && employeeId == null && teamId == null && districtId == null) return;
    _isLoadingCompletedLeads = true;
    notifyListeners();
    try {
      final Map<String, dynamic> queryParams4 = {'status': 4};
      final Map<String, dynamic> queryParams5 = {'status': 5};
      final activeEmployeeId = employeeId ?? _selectedBdeId ?? _selectedBdmId ?? _selectedAsmId;
      if (activeEmployeeId != null) {
        queryParams4['employee_id'] = activeEmployeeId;
        queryParams5['employee_id'] = activeEmployeeId;
      }
      final activeTeamId = teamId ?? _selectedTeamId;
      if (activeTeamId != null) {
        queryParams4['team_id'] = activeTeamId;
        queryParams5['team_id'] = activeTeamId;
      }
      final activeDistrictId = districtId ?? _selectedDistrictId;
      if (activeDistrictId != null) {
        queryParams4['district_id'] = activeDistrictId;
        queryParams5['district_id'] = activeDistrictId;
      }

      final responses = await Future.wait([
        ApiClient.instance.get(
          ApiEndpoints.leads,
          queryParameters: queryParams4,
        ),
        ApiClient.instance.get(
          ApiEndpoints.leads,
          queryParameters: queryParams5,
        ),
      ]);

      final List<TaskModel> combined = [];
      for (final response in responses) {
        if (response.data != null && response.data['success'] == true) {
          final leadsPage = LeadsPage.fromJson(
            response.data['data']['leads'] as Map<String, dynamic>,
          );
          combined.addAll(leadsPage.data.map(_mapLead));
        }
      }
      _completedTasks = combined.where((t) => t.status == 'Completed').toList();
      debugPrint('[fetchCompletedLeads] status=4,5, employee_id=$activeEmployeeId, team_id=$activeTeamId, district_id=$activeDistrictId → ${_completedTasks.length} completed leads loaded');
    } catch (e, st) {
      debugPrint('[fetchCompletedLeads] ERROR: $e\n$st');
    } finally {
      _isLoadingCompletedLeads = false;
      notifyListeners();
    }
  }

  Future<bool> createLeadOnServer({
    required String name,
    required String phone,
    required String email,
    required String address,
    required int districtId,
    required int courseId,
    required int source,
    required int status,
    required int assignedEmployeeId,
    required String notes,
  }) async {
    _isSubmittingTask = true;
    notifyListeners();
    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.createLead,
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'address': address,
          'district_id': districtId,
          'course_id': courseId,
          'source': source,
          'status': status,
          'assigned_employee_id': assignedEmployeeId,
          'notes': notes,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final Map<String, dynamic> data = response.data['data'] as Map<String, dynamic>;
        final leadData = data['lead'] as Map<String, dynamic>;
        
        // Map course_id back to name
        final courseName = _courses.firstWhere(
          (c) => c['id'] == courseId,
          orElse: () => {'name': 'Web Development Bootcamp'},
        )['name'] as String;

        // Map district_id back to name
        final districtName = _districts.firstWhere(
          (d) => d['id'] == districtId,
          orElse: () => {'name': 'Ernakulam'},
        )['name'] as String;

        // Add to local list to reflect in UI immediately
        final newLead = TaskModel(
          id: 'LD_${leadData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
          studentName: name,
          location: address,
          course: courseName,
          description: notes,
          assignedDate: DateTime.now(),
          assignedBdeEmail: AuthProvider.instance.session.email,
          team: AuthProvider.instance.session.team ?? 'Ernakulam Team A',
          district: districtName,
          zone: AuthProvider.instance.session.zone ?? 'Central Zone',
          creatorEmail: AuthProvider.instance.session.email,
          status: 'Pending',
          leadStatus: 'Interested',
          phone: phone,
          email: email,
        );

        addTask(newLead);
        await fetchLeads(status: 1);
        return true;
      }
    } catch (e) {
      debugPrint('Failed to create lead on server: $e');
      rethrow;
    } finally {
      _isSubmittingTask = false;
      notifyListeners();
    }
    return false;
  }

  // --- Incentive Actions ---

  /// Create new incentive claim
  Future<void> createIncentive(
    String category,
    double amount,
    String remarks,
    String? proofPath,
  ) async {
    final newInc = IncentiveModel(
      id: 'INC_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      category: category,
      amount: amount,
      remarks: remarks,
      date: DateTime.now(),
      achievementProofPath: proofPath,
      status: 'Pending',
    );
    _incentives.insert(0, newInc);
    notifyListeners();
  }

  // --- Training Video Actions ---

  /// Mark video as completed/watched
  void toggleVideoCompleted(String id) {
    final index = _trainingVideos.indexWhere((v) => v.id == id);
    if (index != -1) {
      _trainingVideos[index].isCompleted = !_trainingVideos[index].isCompleted;
      notifyListeners();
    }
  }

  // --- Leave Actions ---

  /// Apply for a new leave request
  Future<bool> applyLeave(
    String type,
    DateTime from,
    DateTime to,
    String reason,
  ) async {
    final diff = to.difference(from).inDays + 1;

    // Map string leaveType to API integer code
    int apiTypeCode = 1;
    if (type == 'Medical Leave') {
      apiTypeCode = 2;
    } else if (type == 'Earned Leave') {
      apiTypeCode = 3;
    }

    // Combine selected from-date with current hour/minute/second to match API ISO 8601 example (e.g. 2026-08-07T10:31:59)
    final now = DateTime.now();
    final startDateTime = DateTime(
      from.year,
      from.month,
      from.day,
      now.hour,
      now.minute,
      now.second,
    );
    final formattedFrom = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(startDateTime);
    final formattedTo = DateFormat('yyyy-MM-dd').format(to);

    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.applyLeave,
        data: {
          'type': apiTypeCode,
          'start_date': formattedFrom,
          'end_date': formattedTo,
          'reason': reason,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        // Refresh profile to fetch updated leave balances from the server
        await UserProfileProvider.instance.fetchUserProfile(isRefresh: true);
      }
    } on NetworkException catch (_) {
      // Offline/TLS decryption fallback: locally decrease mock balances to maintain function
      if (type == 'Casual Leave' && _leaveBalanceCasual >= diff) {
        _leaveBalanceCasual -= diff;
      } else if (type == 'Medical Leave' && _leaveBalanceMedical >= diff) {
        _leaveBalanceMedical -= diff;
      } else if (type == 'Earned Leave' && _leaveBalanceEarned >= diff) {
        _leaveBalanceEarned -= diff;
      } else {
        return false; // insufficient balance
      }
    } catch (e) {
      // Rethrow validation or other API errors so the UI can catch and display the exact error message
      rethrow;
    }

    final newLeave = LeaveModel(
      id: 'LV_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      leaveType: type,
      fromDate: from,
      toDate: to,
      reason: reason,
      status: 'Pending',
      appliedDate: DateTime.now(),
    );

    _leaves.insert(0, newLeave);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('leave_bal_casual', _leaveBalanceCasual);
    await prefs.setInt('leave_bal_medical', _leaveBalanceMedical);
    await prefs.setInt('leave_bal_earned', _leaveBalanceEarned);

    notifyListeners();
    return true;
  }

  // --- EOD Actions ---

  /// Submit End of Day Report
  Future<void> submitEodReport(String remarks, String summary) async {
    _isSubmittingEod = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 1500));
      final completedVisits = completedVisitsCount;
      final pending = pendingVisitsCount;
      final time = DateTime.now();

      final leads = completedVisits;
      final followups = beatPlans
          .where(
            (v) =>
                v.isVisited &&
                v.followUpDate != null &&
                v.followUpDate!.isNotEmpty,
          )
          .length;

      _todayEod = EodModel(
        id: 'EOD_TODAY',
        totalVisits: completedVisits,
        leadsCreated: leads,
        followUpsScheduled: followups,
        pendingVisits: pending,
        remarks: remarks,
        dailySummary: summary,
        submissionTime: time,
        isSubmitted: true,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('eod_submitted', true);
      await prefs.setInt('eod_visits', completedVisits);
      await prefs.setInt('eod_leads', leads);
      await prefs.setInt('eod_followups', followups);
      await prefs.setInt('eod_pending', pending);
      await prefs.setString('eod_remarks', remarks);
      await prefs.setString('eod_summary', summary);
      await prefs.setString('eod_time', time.toIso8601String());
    } finally {
      _isSubmittingEod = false;
      notifyListeners();
    }
  }

  /// Add new beat plan item dynamically
  void addBeatPlan(BeatPlanModel item) {
    _beatPlans.add(item);
    notifyListeners();
  }

  /// Reset provider state on logout
  void clearData() {
    _beatPlans = [];
    _tasks = [];
    _incentives = [];
    _leaves = [];
    _trainingVideos = [];
    _todayEod = EodModel.empty();
    _leaveBalanceCasual = 8;
    _leaveBalanceMedical = 4;
    _leaveBalanceEarned = 10;
    _selectedDistrictFilter = null;
    _isLeavesLoaded = false;
    _taskSearchQuery = '';
    _selectedBdeEmail = null;
    _selectedTeam = null;
    _selectedTeamId = null;
    _selectedDistrict = null;
    _selectedDistrictId = null;
    _selectedAsmEmail = null;
    _selectedAsmId = null;
    _selectedBdmEmail = null;
    _selectedBdmId = null;
    notifyListeners();
  }
}
