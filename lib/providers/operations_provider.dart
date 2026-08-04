import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/beat_plan_model.dart';
import '../models/task_model.dart';
import '../models/incentive_model.dart';
import '../models/leave_model.dart';
import '../models/eod_model.dart';
import '../models/training_video_model.dart';
import 'auth_provider.dart';

class OperationsProvider extends ChangeNotifier {
  static final OperationsProvider instance = OperationsProvider._internal();
  OperationsProvider._internal();

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
  
  int get completedTasksCount => tasks.where((t) => t.status == 'Completed').length;
  int get pendingTasksCount => tasks.where((t) => t.status != 'Completed').length;
  
  double get totalEarnedIncentives => _incentives
      .where((i) => i.status == 'Approved' || i.status == 'Paid')
      .fold(0.0, (sum, item) => sum + item.amount);

  int get totalLeavesTakenThisMonth => _leaves
      .where((l) => l.status == 'Approved' && l.fromDate.month == DateTime.now().month)
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
    switch (role) {
      case 'MD':
        return _tasks;
      case 'ZM':
        var list = _tasks.where((t) => t.zone == user.zone).toList();
        if (_selectedDistrictFilter != null && _selectedDistrictFilter!.isNotEmpty) {
          list = list.where((t) => t.district == _selectedDistrictFilter).toList();
        }
        return list;
      case 'ASM':
        return _tasks.where((t) => t.district == user.district).toList();
      case 'BDM':
        return _tasks.where((t) => t.team == user.team).toList();
      case 'BDE':
      default:
        return _tasks.where((t) => t.assignedBdeEmail == user.email || t.creatorEmail == user.email).toList();
    }
  }

  List<BeatPlanModel> _filterBeatPlans(dynamic user) {
    final String role = user.role;
    switch (role) {
      case 'MD':
        return _beatPlans;
      case 'ZM':
        var list = _beatPlans.where((v) => v.zone == user.zone).toList();
        if (_selectedDistrictFilter != null && _selectedDistrictFilter!.isNotEmpty) {
          list = list.where((v) => v.district == _selectedDistrictFilter).toList();
        }
        return list;
      case 'ASM':
        return _beatPlans.where((v) => v.district == user.district).toList();
      case 'BDM':
        return _beatPlans.where((v) => v.team == user.team).toList();
      case 'BDE':
      default:
        return _beatPlans.where((v) => v.assignedBdeEmail == user.email).toList();
    }
  }

  /// Load data from local persistence or generate defaults
  Future<void> loadOperationsData() async {
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
          description: 'Learn the core syllabus details for AI/ML, career prospects, and post-graduate placements to pitch parents.',
          duration: '6 min 15 sec',
          difficulty: 'Beginner',
          videoUrl: 'https://www.youtube.com/watch?v=2ePf97aNfCo',
        ),
        TrainingVideoModel(
          id: 'VID_002',
          title: 'Handling Parent & Fee Concerns',
          description: 'How to handle common questions regarding course fees, monthly installment options, and scholarship criteria.',
          duration: '5 min 45 sec',
          difficulty: 'Intermediate',
          videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        TrainingVideoModel(
          id: 'VID_003',
          title: 'Pitching Cyber Security & Dev Ops',
          description: 'Guide to explaining online-hybrid program tracks, industrial tie-ups, and placement eligibility checks.',
          duration: '4 min 30 sec',
          difficulty: 'Intermediate',
          videoUrl: 'https://www.youtube.com/watch?v=nz20e0Q6ZkE',
        ),
        TrainingVideoModel(
          id: 'VID_004',
          title: 'Logging Biometric Reports & Proofs',
          description: 'Tutorial on capturing correct document/selfie proof and selecting the appropriate status for student leads.',
          duration: '3 min 12 sec',
          difficulty: 'Beginner',
          videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
      ];
    }

    // Set Mock Tasks (Leads) representing the hierarchy
    if (_tasks.isEmpty) {
      _tasks = [
        // --- Central Zone (Ernakulam District) ---
        TaskModel(
          id: 'LD_201',
          studentName: 'Sujith Kumar',
          location: 'Kakkanad Junction, Kochi (Opp. Sunrise Hospital)',
          course: 'Diploma in Advanced AI & ML',
          description: 'Introduce KIDE career programs, verify school records, and check scholarship eligibility.',
          status: 'Completed',
          leadStatus: 'Admitted',
          remarks: 'Parent checked fee installment options, registered first term admission.',
          assignedDate: DateTime.now().subtract(const Duration(days: 2)),
          completedDate: DateTime.now().subtract(const Duration(days: 1)),
          completionProofPath: 'receipt_sujith.jpg',
          assignedBdeEmail: 'bde.ernakulam.a1@keralainstitute.org',
          team: 'Ernakulam Team A',
          district: 'Ernakulam',
          zone: 'Central Zone',
        ),
        TaskModel(
          id: 'LD_202',
          studentName: 'Akhila Pillai',
          location: 'Vyttila Hub Road, Ernakulam (Behind Metro Station)',
          course: 'Executive MBA & Digital Business',
          description: 'Explain business program curriculum, flexible online-hybrid classes, and career opportunities.',
          status: 'Completed',
          leadStatus: 'Interested',
          remarks: 'Applicant is working full-time. Will discuss hybrid program schedule next Monday.',
          assignedDate: DateTime.now().subtract(const Duration(days: 2)),
          completedDate: DateTime.now().subtract(const Duration(days: 1)),
          completionProofPath: 'callback_akhila.jpg',
          assignedBdeEmail: 'bde.ernakulam.a2@keralainstitute.org',
          team: 'Ernakulam Team A',
          district: 'Ernakulam',
          zone: 'Central Zone',
        ),
        TaskModel(
          id: 'LD_203',
          studentName: 'Sneha Mary John',
          location: 'Palarivattom Metro Exit, Kochi (Green Villa Lane)',
          course: 'Certified Digital Marketing Specialist',
          description: 'Introduce KIDE career scholarship benefits, discuss internship tracks.',
          status: 'Pending',
          assignedDate: DateTime.now(),
          assignedBdeEmail: 'bde.ernakulam.b1@keralainstitute.org',
          team: 'Ernakulam Team B',
          district: 'Ernakulam',
          zone: 'Central Zone',
        ),
        TaskModel(
          id: 'LD_204',
          studentName: 'Abhishek Nair',
          location: 'Edappally Toll, Kochi',
          course: 'M.Tech in Cyber Security',
          description: 'Counselling regarding scholarship criteria & placement track record.',
          status: 'Pending',
          assignedDate: DateTime.now(),
          assignedBdeEmail: 'bde.ernakulam.a1@keralainstitute.org',
          team: 'Ernakulam Team A',
          district: 'Ernakulam',
          zone: 'Central Zone',
        ),
        TaskModel(
          id: 'LD_205',
          studentName: 'Rinu Joseph',
          location: 'Angamaly Town, Ernakulam',
          course: 'B.Tech in Artificial Intelligence',
          description: 'Discuss post-graduate placement statistics and schedule entry exam.',
          status: 'Pending',
          assignedDate: DateTime.now(),
          assignedBdeEmail: 'bde.ernakulam.a2@keralainstitute.org',
          team: 'Ernakulam Team A',
          district: 'Ernakulam',
          zone: 'Central Zone',
        ),
        
        // --- South Zone (Thiruvananthapuram District) ---
        TaskModel(
          id: 'LD_301',
          studentName: 'Ajay Kumar',
          location: 'Technopark Phase-3 Gate, Kazhakoottam, TVM',
          course: 'Post-Graduate Program in Devops',
          description: 'Brief details on course modules, flexible online classes.',
          status: 'Pending',
          assignedDate: DateTime.now(),
          assignedBdeEmail: 'bde.trivandrum.a1@keralainstitute.org',
          team: 'Trivandrum Team A',
          district: 'Thiruvananthapuram',
          zone: 'South Zone',
        ),
        TaskModel(
          id: 'LD_302',
          studentName: 'Reshma S.',
          location: 'Kowdiar Junction, Trivandrum',
          course: 'Certified Digital Marketing Specialist',
          description: 'Verify certificates for 20% scholarship program.',
          status: 'Completed',
          leadStatus: 'Admitted',
          remarks: 'Admission fee processed, invoice shared.',
          assignedDate: DateTime.now().subtract(const Duration(days: 4)),
          completedDate: DateTime.now().subtract(const Duration(days: 3)),
          completionProofPath: 'reshma_receipt.jpg',
          assignedBdeEmail: 'bde.trivandrum.a1@keralainstitute.org',
          team: 'Trivandrum Team A',
          district: 'Thiruvananthapuram',
          zone: 'South Zone',
        ),
        TaskModel(
          id: 'LD_303',
          studentName: 'Abhirami Suresh',
          location: 'Kazhakoottam Bypass Road, Thiruvananthapuram',
          course: 'Post-Graduate Program in Devops',
          description: 'Explain hybrid learning options, verify standard criteria.',
          status: 'Pending',
          assignedDate: DateTime.now(),
          assignedBdeEmail: 'bde.trivandrum.a1@keralainstitute.org',
          team: 'Trivandrum Team A',
          district: 'Thiruvananthapuram',
          zone: 'South Zone',
        ),
        TaskModel(
          id: 'LD_304',
          studentName: 'Midhun Murali',
          location: 'Kowdiar Junction, Thiruvananthapuram',
          course: 'B.Tech in Artificial Intelligence',
          description: 'Counselling session for admission with parent.',
          status: 'Pending',
          assignedDate: DateTime.now(),
          assignedBdeEmail: 'bde.trivandrum.a2@keralainstitute.org',
          team: 'Trivandrum Team A',
          district: 'Thiruvananthapuram',
          zone: 'South Zone',
        ),

        // --- North Zone (Kozhikode District) ---
        TaskModel(
          id: 'LD_401',
          studentName: 'Devanand R.',
          location: 'MG Road, Kozhikode (Near City Mall)',
          course: 'Full Stack Web Development & UI/UX',
          description: 'Discuss post-graduate placement statistics and schedule entry exam.',
          status: 'Pending',
          assignedDate: DateTime.now(),
          assignedBdeEmail: 'bde.kozhikode.a1@keralainstitute.org',
          team: 'Kozhikode Team A',
          district: 'Kozhikode',
          zone: 'North Zone',
        ),
        TaskModel(
          id: 'LD_402',
          studentName: 'Fahad Fazil',
          location: 'Mavoor Road, Kozhikode',
          course: 'Certified Cloud Architect',
          description: 'Verify degree marksheet and check eligibility.',
          status: 'Completed',
          leadStatus: 'Closed',
          remarks: 'Candidate joined a full-time university course elsewhere.',
          assignedDate: DateTime.now().subtract(const Duration(days: 5)),
          completedDate: DateTime.now().subtract(const Duration(days: 2)),
          completionProofPath: 'closed_fahad.jpg',
          assignedBdeEmail: 'bde.kozhikode.a1@keralainstitute.org',
          team: 'Kozhikode Team A',
          district: 'Kozhikode',
          zone: 'North Zone',
        ),
        TaskModel(
          id: 'LD_403',
          studentName: 'Sandra Joseph',
          location: 'Calicut Bypass Road, Kozhikode',
          course: 'M.Tech in Cyber Security',
          description: 'Explain registration procedures and class schedules.',
          status: 'Pending',
          assignedDate: DateTime.now(),
          assignedBdeEmail: 'bde.kozhikode.a2@keralainstitute.org',
          team: 'Kozhikode Team A',
          district: 'Kozhikode',
          zone: 'North Zone',
        ),
        TaskModel(
          id: 'LD_404',
          studentName: 'Nikhil Raj',
          location: 'MG Road, Kozhikode',
          course: 'Certified Digital Marketing Specialist',
          description: 'Parent meeting regarding course features and loan option.',
          status: 'Pending',
          assignedDate: DateTime.now(),
          assignedBdeEmail: 'bde.kozhikode.a2@keralainstitute.org',
          team: 'Kozhikode Team A',
          district: 'Kozhikode',
          zone: 'North Zone',
        ),
        // --- Central Zone (Thrissur District) ---
        TaskModel(
          id: 'LD_211',
          studentName: 'Aswathy S.',
          location: 'Swaraj Round, Thrissur',
          course: 'Certified Digital Marketing Specialist',
          description: 'Parent meeting regarding course features and career prospects.',
          status: 'Pending',
          assignedDate: DateTime.now(),
          assignedBdeEmail: 'bde.thrissur.a1@keralainstitute.org',
          team: 'Thrissur Team A',
          district: 'Thrissur',
          zone: 'Central Zone',
        ),
        TaskModel(
          id: 'LD_212',
          studentName: 'Gokul Das',
          location: 'West Fort, Thrissur',
          course: 'B.Tech in Artificial Intelligence',
          description: 'Counselling session and scholarship documents verification.',
          status: 'Completed',
          leadStatus: 'Admitted',
          remarks: 'Registered under scholarship quota. Paid registration token.',
          assignedDate: DateTime.now().subtract(const Duration(days: 3)),
          completedDate: DateTime.now().subtract(const Duration(days: 1)),
          completionProofPath: 'thrissur_gokul_receipt.jpg',
          assignedBdeEmail: 'bde.thrissur.a1@keralainstitute.org',
          team: 'Thrissur Team A',
          district: 'Thrissur',
          zone: 'Central Zone',
        ),
        // --- South Zone (Kollam District) ---
        TaskModel(
          id: 'LD_311',
          studentName: 'Neethu Krishnan',
          location: 'Chinnakada Clock Tower, Kollam',
          course: 'M.Tech in Cyber Security',
          description: 'Check eligibility for hybrid program mode.',
          status: 'Pending',
          assignedDate: DateTime.now(),
          assignedBdeEmail: 'bde.kollam.a1@keralainstitute.org',
          team: 'Kollam Team A',
          district: 'Kollam',
          zone: 'South Zone',
        ),
        TaskModel(
          id: 'LD_312',
          studentName: 'Hariprasad M.',
          location: 'High School Junction, Kollam',
          course: 'Post-Graduate Program in Devops',
          description: 'Verify certificates for 15% regional discount.',
          status: 'Completed',
          leadStatus: 'Interested',
          remarks: 'Candidate is highly interested. Discussion with father scheduled next Tuesday.',
          assignedDate: DateTime.now().subtract(const Duration(days: 4)),
          completedDate: DateTime.now().subtract(const Duration(days: 2)),
          completionProofPath: 'kollam_hari_status.jpg',
          assignedBdeEmail: 'bde.kollam.a1@keralainstitute.org',
          team: 'Kollam Team A',
          district: 'Kollam',
          zone: 'South Zone',
        ),
        // --- North Zone (Kannur District) ---
        TaskModel(
          id: 'LD_411',
          studentName: 'Rithika Raj',
          location: 'Payyambalam Beach Road, Kannur',
          course: 'Diploma in Advanced AI & ML',
          description: 'Introduce career placement tie-ups and syllabus.',
          status: 'Pending',
          assignedDate: DateTime.now(),
          assignedBdeEmail: 'bde.kannur.a1@keralainstitute.org',
          team: 'Kannur Team A',
          district: 'Kannur',
          zone: 'North Zone',
        ),
        TaskModel(
          id: 'LD_412',
          studentName: 'Karan Johar',
          location: 'Caltex Junction, Kannur',
          course: 'Certified Cloud Architect',
          description: 'Explain corporate admission criteria & fee schedules.',
          status: 'Completed',
          leadStatus: 'Closed',
          remarks: 'Candidate joined a local science college program.',
          assignedDate: DateTime.now().subtract(const Duration(days: 5)),
          completedDate: DateTime.now().subtract(const Duration(days: 3)),
          completionProofPath: 'closed_kannur_karan.jpg',
          assignedBdeEmail: 'bde.kannur.a1@keralainstitute.org',
          team: 'Kannur Team A',
          district: 'Kannur',
          zone: 'North Zone',
        ),
      ];
    }

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
          visitNotes: 'Completed counselling session, 12 admissions registered.',
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
          visitNotes: 'Document collection drive completed. Verified 18 applications.',
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
          visitNotes: 'Collected feedback from 15 merchants. Registered 3 follow-ups.',
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
        submissionTime: DateTime.parse(prefs.getString('eod_time') ?? DateTime.now().toIso8601String()),
        isSubmitted: true,
      );
    } else {
      _todayEod = EodModel.empty();
    }

    notifyListeners();
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
    _incentives.clear();
    for (var video in _trainingVideos) {
      video.isCompleted = false;
    }
    _leaves.clear();
    _todayEod = EodModel.empty();
    _selectedDistrictFilter = null;

    await loadOperationsData();
  }

  // --- Beat Plan Actions ---
  
  /// Check-in at a customer location
  Future<void> checkInVisit(String id, String selfie, double lat, double lng) async {
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
  Future<void> logVisitActivities(String id, {required String notes, required double orderValue, required String followUp, String? attachment}) async {
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
  
  /// Update task status (Student Lead admission)
  Future<void> updateTaskStatus(
    String id,
    String status, {
    required String leadStatus,
    required String remarks,
    required String proof,
    String? followUpDate,
  }) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: status,
        leadStatus: leadStatus,
        completedDate: status == 'Completed' ? DateTime.now() : null,
        completionProofPath: proof,
        remarks: remarks,
        followUpDate: followUpDate,
      );
      notifyListeners();
    }
  }

  /// Bulk Lead Upload & Assign (For BDM/TL)
  Future<void> bulkUploadLeads(List<TaskModel> newLeads) async {
    _tasks.insertAll(0, newLeads);
    notifyListeners();
  }

  /// Add single lead dynamically (BDM or Self-created by BDE)
  void addTask(TaskModel item) {
    _tasks.insert(0, item);
    notifyListeners();
  }

  // --- Incentive Actions ---
  
  /// Create new incentive claim
  Future<void> createIncentive(String category, double amount, String remarks, String? proofPath) async {
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
  Future<bool> applyLeave(String type, DateTime from, DateTime to, String reason) async {
    final diff = to.difference(from).inDays + 1;
    
    // Deduct from balance check
    if (type == 'Casual Leave' && _leaveBalanceCasual >= diff) {
      _leaveBalanceCasual -= diff;
    } else if (type == 'Medical Leave' && _leaveBalanceMedical >= diff) {
      _leaveBalanceMedical -= diff;
    } else if (type == 'Earned Leave' && _leaveBalanceEarned >= diff) {
      _leaveBalanceEarned -= diff;
    } else {
      return false; // insufficient balance
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
    final completedVisits = completedVisitsCount;
    final pending = pendingVisitsCount;
    final time = DateTime.now();

    final leads = completedVisits;
    final followups = beatPlans.where((v) => v.isVisited && v.followUpDate != null && v.followUpDate!.isNotEmpty).length;

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

    notifyListeners();
  }

  /// Add new beat plan item dynamically
  void addBeatPlan(BeatPlanModel item) {
    _beatPlans.add(item);
    notifyListeners();
  }
}
