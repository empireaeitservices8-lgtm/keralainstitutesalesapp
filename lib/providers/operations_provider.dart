import 'dart:convert';
import 'dart:io';
import 'package:keralainstitutesalesapp/api/exceptions/api_exception.dart';

import '../models/sm_asm_model.dart';
import '../models/office_telecaller_model.dart';
import '../models/sm_payout_request_model.dart';
import '../models/asm_bde_model.dart';
import '../models/wallet_approval_request_model.dart';
import '../models/zone_model.dart';
import '../models/district_model.dart';
import '../models/course_model.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:keralainstitutesalesapp/api/api_response.dart';
import 'package:keralainstitutesalesapp/models/user_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
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

  List<SmAsmModel> _smAsms = [];
  List<SmAsmModel> get smAsms => _smAsms;
  bool _isLoadingSmAsms = false;
  bool get isLoadingSmAsms => _isLoadingSmAsms;

  List<OfficeTelecallerModel> _officeTelecallers = [];
  List<OfficeTelecallerModel> get officeTelecallers => _officeTelecallers;
  bool _isLoadingTelecallers = false;
  bool get isLoadingTelecallers => _isLoadingTelecallers;

  List<SmPayoutRequestModel> _smPayoutRequests = [];
  List<SmPayoutRequestModel> get smPayoutRequests => _smPayoutRequests;
  bool _isLoadingSmRequests = false;
  bool get isLoadingSmRequests => _isLoadingSmRequests;

  List<AsmBdeModel> _asmBdes = [];
  List<AsmBdeModel> get asmBdes => _asmBdes;
  bool _isLoadingAsmBdes = false;
  bool get isLoadingAsmBdes => _isLoadingAsmBdes;

  List<SmPayoutRequestModel> _bdePayoutRequests = [];
  List<SmPayoutRequestModel> get bdePayoutRequests => _bdePayoutRequests;
  bool _isLoadingBdeRequests = false;
  bool get isLoadingBdeRequests => _isLoadingBdeRequests;

  List<WalletApprovalRequestItem> _walletApprovalRequests = [];
  List<WalletApprovalRequestItem> get walletApprovalRequests =>
      _walletApprovalRequests;
  WalletApprovalSummary? _walletApprovalSummary;
  WalletApprovalSummary? get walletApprovalSummary => _walletApprovalSummary;
  bool _isLoadingWalletRequests = false;
  bool get isLoadingWalletRequests => _isLoadingWalletRequests;
  String? _walletRequestsError;
  String? get walletRequestsError => _walletRequestsError;

  int? _customMonthlyTargetLeads;
  int? _customMonthlyTargetAdmissions;
  int? get customMonthlyTargetLeads => _customMonthlyTargetLeads;
  int? get customMonthlyTargetAdmissions => _customMonthlyTargetAdmissions;

  void setMonthlyTarget({int? leads, int? admissions}) {
    if (leads != null) _customMonthlyTargetLeads = leads;
    if (admissions != null) _customMonthlyTargetAdmissions = admissions;
    notifyListeners();
  }

  void refreshTargetState() {
    notifyListeners();
  }

  // --- 3. SM (Sales Manager) APIs ---
  Future<void> fetchSmAsms({bool isRefresh = false}) async {
    final cleanRole = AuthProvider.instance.session.role.trim().toUpperCase();
    if (cleanRole != 'SM') {
      debugPrint(
        '[fetchSmAsms] Skipping /api/sm/asms because user role ($cleanRole) is not SM',
      );
      return;
    }

    if (!isRefresh && _smAsms.isNotEmpty) return;
    _isLoadingSmAsms = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_sm_asms');
      if (cached != null && _smAsms.isEmpty) {
        try {
          final decoded = jsonDecode(cached);
          if (decoded is List) {
            _smAsms = decoded
                .whereType<Map>()
                .map((e) => SmAsmModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            notifyListeners();
          }
        } catch (_) {}
      }

      final response = await ApiClient.instance.get(ApiEndpoints.smAsms);
      if (response.data != null) {
        dynamic raw = response.data;
        if (raw is Map && raw['data'] is List) {
          raw = raw['data'];
        }
        if (raw is List && raw.isNotEmpty) {
          _smAsms = raw
              .whereType<Map>()
              .map((e) => SmAsmModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          await prefs.setString(
            'cached_sm_asms',
            jsonEncode(_smAsms.map((e) => e.toJson()).toList()),
          );
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching /api/sm/asms: $e');
    } finally {
      if (_smAsms.isEmpty) {
        _smAsms = _getDefaultAsmList();
      }
      _isLoadingSmAsms = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createAsm({
    required String name,
    required String email,
    required String phone,
    required String teamCode,
    required String password,
    String? zone,
    List<String>? districts,
    String? team,
    int monthlyTarget = 45,
    int dailyTarget = 12,
  }) async {
    try {
      final finalTeamCode = teamCode.trim().toUpperCase();
      final finalPassword = password.trim().isNotEmpty
          ? password.trim()
          : 'password123';

      String cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-]'), '');
      if (cleanPhone.startsWith('+91') && cleanPhone.length > 10) {
        cleanPhone = cleanPhone.substring(3);
      } else if (cleanPhone.startsWith('91') && cleanPhone.length == 12) {
        cleanPhone = cleanPhone.substring(2);
      }

      // API expects strictly: name, email, contact_number, password, team_code
      final payload = {
        'name': name.trim(),
        'email': email.trim(),
        'contact_number': cleanPhone,
        'password': finalPassword,
        'team_code': finalTeamCode,
      };

      debugPrint('====================================================');
      debugPrint('[POST ${ApiEndpoints.smCreateAsm}] Payload: $payload');

      String asmId = 'asm_${DateTime.now().millisecondsSinceEpoch}';
      String employeeId =
          'ASM${(_smAsms.length + 1).toString().padLeft(3, '0')}';
      String message =
          'ASM $name created successfully with team $finalTeamCode.';

      final response = await ApiClient.instance.post(
        ApiEndpoints.smCreateAsm,
        data: payload,
      );

      debugPrint(
        '[POST ${ApiEndpoints.smCreateAsm}] Status: ${response.statusCode}',
      );
      debugPrint(
        '[POST ${ApiEndpoints.smCreateAsm}] Response Body: ${response.data}',
      );
      debugPrint('====================================================');

      if (response.data != null && response.data is Map) {
        final dataMap = response.data as Map;
        if (dataMap['success'] == false) {
          return {
            'success': false,
            'message':
                dataMap['message']?.toString() ?? 'Failed to create ASM.',
          };
        }
        if (dataMap['message'] != null &&
            dataMap['message'].toString().isNotEmpty) {
          message = dataMap['message'].toString();
        }
        final resData = dataMap['data'];
        if (resData is Map) {
          if (resData['employee_id'] != null)
            employeeId = resData['employee_id'].toString();
          if (resData['id'] != null) asmId = resData['id'].toString();
          if (resData['_id'] != null) asmId = resData['_id'].toString();
        }
      }

      final assignedDistricts = (districts != null && districts.isNotEmpty)
          ? districts
          : getDefaultDistrictsForTeam(finalTeamCode);
      final assignedZone = (zone != null && zone.isNotEmpty)
          ? zone
          : getDefaultZoneForTeam(finalTeamCode);

      final newAsm = SmAsmModel(
        id: asmId,
        employeeId: employeeId,
        name: name.trim(),
        email: email.trim(),
        contactNumber: cleanPhone,
        designation: 'Area Sales Manager',
        team: team ?? '${finalTeamCode} Team',
        districts: assignedDistricts,
        zone: assignedZone,
        reportsTo: 'SM001',
        bdesCount: 0,
        status: 'active',
        dailyTarget: dailyTarget,
        dailyAchieved: 0,
        dailyPending: dailyTarget,
        dailyCompletionPercentage: 0,
        monthlyTarget: monthlyTarget,
        monthlyAchieved: 0,
        monthlyPending: monthlyTarget,
        monthlyCompletionPercentage: 0,
        totalLeads: 0,
        completedLeads: 0,
        pendingLeads: 0,
        completionPercentage: 0,
      );

      _smAsms.insert(0, newAsm);

      try {
        final prefs = await SharedPreferences.getInstance();
        final encoded = jsonEncode(_smAsms.map((a) => a.toJson()).toList());
        await prefs.setString('cached_sm_asms', encoded);
      } catch (_) {}

      notifyListeners();

      // Refresh list from server
      fetchSmAsms(isRefresh: true).catchError((_) {});

      return {'success': true, 'message': message, 'asm': newAsm};
    } on NetworkException catch (e) {
      debugPrint('[CreateAsm] NetworkException: ${e.message}');
      return {'success': false, 'message': e.message};
    } on ApiException catch (e) {
      debugPrint('[CreateAsm] ApiException: ${e.message}');
      String errMsg = e.message;
      if (e.details != null && e.details is Map) {
        final m = e.details as Map;
        if (m['message'] != null) errMsg = m['message'].toString();
        if (m['errors'] is Map) {
          final errs = (m['errors'] as Map).values
              .map((v) => v is List ? v.join(', ') : v.toString())
              .join('\n');
          if (errs.isNotEmpty) errMsg = errs;
        }
      }
      return {'success': false, 'message': errMsg};
    } catch (e) {
      debugPrint('[CreateAsm] Error: $e');
      final errStr = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ApiException: ', '')
          .replaceAll('[400] Bad Request: ', '');
      return {'success': false, 'message': errStr};
    }
  }

  List<String> getDefaultDistrictsForTeam(String code) {
    switch (code.toUpperCase()) {
      case 'TVM':
        return ['Thiruvananthapuram', 'Kollam'];
      case 'PTM':
        return ['Pathanamthitta', 'Alappuzha'];
      case 'KTM':
        return ['Kottayam', 'Idukki'];
      case 'EKM':
        return ['Ernakulam'];
      case 'PKD':
        return ['Palakkad', 'Thrissur'];
      case 'CLT':
        return ['Kozhikode', 'Malappuram'];
      case 'KZD':
        return ['Kannur', 'Wayanad', 'Kasaragod'];
      case 'OFFICE':
      default:
        return ['Ernakulam'];
    }
  }

  String getDefaultZoneForTeam(String code) {
    switch (code.toUpperCase()) {
      case 'TVM':
      case 'PTM':
        return 'South Zone';
      case 'KTM':
      case 'EKM':
      case 'PKD':
        return 'Central Zone';
      case 'CLT':
      case 'KZD':
        return 'North Zone';
      case 'OFFICE':
      default:
        return 'Central Zone';
    }
  }

  String _deriveTeamCode(List<String> districts, String? team) {
    if (team != null && team.isNotEmpty) {
      final code = team.replaceAll('Team', '').trim().toUpperCase();
      if ([
        'TVM',
        'PTM',
        'KTM',
        'EKM',
        'PKD',
        'CLT',
        'KZD',
        'KZE',
        'OFFICE',
      ].contains(code)) {
        return code;
      }
    }
    if (districts.isNotEmpty) {
      final d = districts.first.toLowerCase();
      if (d.contains('thiruvananthapuram') || d.contains('trivandrum'))
        return 'TVM';
      if (d.contains('pathanamthitta') || d.contains('kollam')) return 'PTM';
      if (d.contains('kottayam') || d.contains('idukki')) return 'KTM';
      if (d.contains('ernakulam') ||
          d.contains('thrissur') ||
          d.contains('cochin'))
        return 'EKM';
      if (d.contains('palakkad') || d.contains('malappuram')) return 'PKD';
      if (d.contains('kozhikode') || d.contains('calicut')) return 'CLT';
      if (d.contains('kannur') ||
          d.contains('kasaragod') ||
          d.contains('wayanad'))
        return 'KZD';
    }
    return 'EKM';
  }

  // --- Office Team Telecallers APIs ---
  Future<void> fetchOfficeTelecallers({bool isRefresh = false}) async {
    final cleanRole = AuthProvider.instance.session.role.trim().toUpperCase();
    if (cleanRole == 'BDE' ||
        !['ASM', 'BDM', 'SM', 'ADMIN', 'MD'].contains(cleanRole)) {
      debugPrint(
        '[fetchOfficeTelecallers] Skipping /api/office/telecallers for role ($cleanRole) - requires ASM, BDM, SM, ADMIN, MD',
      );
      if (_officeTelecallers.isEmpty) {
        _officeTelecallers = _getDefaultTelecallers();
      }
      return;
    }

    if (!isRefresh && _officeTelecallers.isNotEmpty) return;
    _isLoadingTelecallers = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_office_telecallers');
      if (cached != null && _officeTelecallers.isEmpty) {
        try {
          final decoded = jsonDecode(cached);
          if (decoded is List) {
            _officeTelecallers = decoded
                .whereType<Map>()
                .map(
                  (e) => OfficeTelecallerModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList();
            notifyListeners();
          }
        } catch (_) {}
      }

      final response = await ApiClient.instance.get(
        ApiEndpoints.officeTelecallers,
      );
      debugPrint('====================================================');
      debugPrint(
        '📞 [GET ${ApiEndpoints.officeTelecallers}] Status: ${response.statusCode}',
      );
      debugPrint('📞 [GET ${ApiEndpoints.officeTelecallers}] Response Body:');
      try {
        debugPrint(const JsonEncoder.withIndent('  ').convert(response.data));
      } catch (_) {
        debugPrint('${response.data}');
      }
      debugPrint('====================================================');

      if (response.data != null) {
        dynamic raw = response.data;
        if (raw is Map && raw['data'] is List) {
          raw = raw['data'];
        } else if (raw is Map && raw['telecallers'] is List) {
          raw = raw['telecallers'];
        }
        if (raw is List && raw.isNotEmpty) {
          _officeTelecallers = raw
              .whereType<Map>()
              .map(
                (e) => OfficeTelecallerModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList();
          await prefs.setString(
            'cached_office_telecallers',
            jsonEncode(_officeTelecallers.map((e) => e.toJson()).toList()),
          );
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching /api/office/telecallers: $e');
    } finally {
      if (_officeTelecallers.isEmpty) {
        _officeTelecallers = _getDefaultTelecallers();
      }
      _isLoadingTelecallers = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createTelecaller({
    required String name,
    required String email,
    required String phone,
    required String district,
    required String password,
    String shift = 'General Shift (10 AM - 6 PM)',
    int baseSalary = 18000,
    int incentivePerAdmission = 500,
    int monthlyTarget = 30,
  }) async {
    final payload = {
      'name': name,
      'email': email,
      'contact_number': phone,
      'password': password,
      'district': district,
    };

    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.officeCreateTelecaller,
        data: payload,
      );
      debugPrint('[CreateTelecaller] Server response: ${response.statusCode}');
      debugPrint('[CreateTelecaller] Response data: ${response.data}');

      String empId =
          'TC${(_officeTelecallers.length + 1).toString().padLeft(3, '0')}';
      String itemId = 'tc_${DateTime.now().millisecondsSinceEpoch}';
      String message =
          'Tele-caller $name ($empId) created successfully under Office Team.';

      if (response.data != null && response.data is Map) {
        final dataMap = response.data as Map;
        if (dataMap['success'] == false) {
          return {
            'success': false,
            'message':
                dataMap['message']?.toString() ??
                'Failed to create telecaller.',
          };
        }
        if (dataMap['message'] != null &&
            dataMap['message'].toString().isNotEmpty) {
          message = dataMap['message'].toString();
        }
        final resData = dataMap['data'];
        if (resData is Map) {
          if (resData['employee_id'] != null)
            empId = resData['employee_id'].toString();
          if (resData['id'] != null) itemId = resData['id'].toString();
          if (resData['_id'] != null) itemId = resData['_id'].toString();
        }
      }

      final newCaller = OfficeTelecallerModel(
        id: itemId,
        employeeId: empId,
        name: name,
        email: email,
        contactNumber: phone,
        district: district,
        shift: shift,
        leadsAssigned: 0,
        admissionsClosed: 0,
        conversionRate: '0%',
        status: 'active',
        callsToday: 0,
        baseSalary: baseSalary,
        incentivePerAdmission: incentivePerAdmission,
        monthlyTarget: monthlyTarget,
      );

      _officeTelecallers.insert(0, newCaller);

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'cached_office_telecallers',
          jsonEncode(_officeTelecallers.map((e) => e.toJson()).toList()),
        );
      } catch (_) {}

      notifyListeners();
      return {'success': true, 'message': message, 'telecaller': newCaller};
    } on NetworkException catch (e) {
      debugPrint('[CreateTelecaller] NetworkException: ${e.message}');
      return {'success': false, 'message': e.message};
    } catch (e) {
      debugPrint('[CreateTelecaller] Error: $e');
      final errStr = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ApiException: ', '')
          .replaceAll('[400] Bad Request: ', '');
      return {'success': false, 'message': errStr};
    }
  }

  List<OfficeTelecallerModel> _getDefaultTelecallers() {
    return const [
      OfficeTelecallerModel(
        id: '672430000000000000000001',
        employeeId: 'TC001',
        name: 'Sneha M.',
        email: 'sneha.office@kide.com',
        contactNumber: '+91 98471 22334',
        district: 'Ernakulam',
        shift: 'Morning Shift (9 AM - 5 PM)',
        callsToday: 65,
        leadsAssigned: 45,
        admissionsClosed: 12,
        conversionRate: '26.7%',
        status: 'active',
        baseSalary: 18000,
        incentivePerAdmission: 500,
        monthlyTarget: 30,
      ),
      OfficeTelecallerModel(
        id: '672430000000000000000002',
        employeeId: 'TC002',
        name: 'Priya K.',
        email: 'priya.office@kide.com',
        contactNumber: '+91 94472 88990',
        district: 'Kozhikode',
        shift: 'General Shift (10 AM - 6 PM)',
        callsToday: 58,
        leadsAssigned: 38,
        admissionsClosed: 8,
        conversionRate: '21.0%',
        status: 'active',
        baseSalary: 18000,
        incentivePerAdmission: 500,
        monthlyTarget: 30,
      ),
      OfficeTelecallerModel(
        id: '672430000000000000000003',
        employeeId: 'TC003',
        name: 'Arjun V.',
        email: 'arjun.office@kide.com',
        contactNumber: '+91 97455 11223',
        district: 'Thiruvananthapuram',
        shift: 'Evening Shift (11 AM - 7 PM)',
        callsToday: 72,
        leadsAssigned: 50,
        admissionsClosed: 15,
        conversionRate: '30.0%',
        status: 'active',
        baseSalary: 20000,
        incentivePerAdmission: 600,
        monthlyTarget: 35,
      ),
    ];
  }

  // --- SM Payout & Workflow Requests APIs ---
  Future<void> fetchSmPayoutRequests({bool isRefresh = false}) async {
    final cleanRole = AuthProvider.instance.session.role.trim().toUpperCase();
    if (cleanRole != 'SM') {
      debugPrint(
        '[fetchSmPayoutRequests] Skipping /api/salary/requests because user role ($cleanRole) is not SM',
      );
      return;
    }

    if (!isRefresh && _smPayoutRequests.isNotEmpty) return;
    _isLoadingSmRequests = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_sm_requests');
      if (cached != null && _smPayoutRequests.isEmpty) {
        try {
          final decoded = jsonDecode(cached);
          if (decoded is List) {
            _smPayoutRequests = decoded
                .whereType<Map>()
                .map(
                  (e) => SmPayoutRequestModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList();
            notifyListeners();
          }
        } catch (_) {}
      }

      final List<SmPayoutRequestModel> combined = [];

      // 1. Fetch Salary Requests (Pending_SM)
      try {
        final salRes = await ApiClient.instance.get(
          ApiEndpoints.salaryRequests,
          queryParameters: {'status': 'Pending_SM'},
        );
        if (salRes.data != null) {
          dynamic raw = salRes.data;
          if (raw is Map && raw['data'] is List) raw = raw['data'];
          if (raw is List) {
            for (final item in raw) {
              if (item is Map) {
                combined.add(
                  SmPayoutRequestModel.fromJson(
                    Map<String, dynamic>.from(item),
                    defaultType: 'Salary',
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[SalaryRequests] Fetch error: $e');
      }

      // 2. Fetch Wallet Requests (Pending_SM)
      try {
        final walRes = await ApiClient.instance.get(
          ApiEndpoints.walletRequests,
          queryParameters: {'status': 'Pending_SM'},
        );
        if (walRes.data != null) {
          dynamic raw = walRes.data;
          if (raw is Map && raw['data'] is List) raw = raw['data'];
          if (raw is List) {
            for (final item in raw) {
              if (item is Map) {
                combined.add(
                  SmPayoutRequestModel.fromJson(
                    Map<String, dynamic>.from(item),
                    defaultType: 'Incentive',
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[WalletRequests] Fetch error: $e');
      }

      if (combined.isNotEmpty) {
        _smPayoutRequests = combined;
        await prefs.setString(
          'cached_sm_requests',
          jsonEncode(_smPayoutRequests.map((e) => e.toJson()).toList()),
        );
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Error fetching SM requests: $e');
    } finally {
      if (_smPayoutRequests.isEmpty) {
        _smPayoutRequests = _getDefaultSmRequests();
      }
      _isLoadingSmRequests = false;
      notifyListeners();
    }
  }

  Future<bool> forwardSalaryToAccounts(
    String requestId, {
    String notes = 'Verified by SM',
  }) async {
    try {
      final payload = {
        'request_id': requestId,
        'action': 'forward_to_accounts',
        'notes': notes,
      };

      try {
        await ApiClient.instance.post(
          ApiEndpoints.salaryWorkflow,
          data: payload,
        );
      } catch (e) {
        debugPrint('[ForwardSalary] API call: $e');
      }

      final idx = _smPayoutRequests.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        _smPayoutRequests[idx].status = 'Forwarded to Accounts';
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'cached_sm_requests',
            jsonEncode(_smPayoutRequests.map((e) => e.toJson()).toList()),
          );
        } catch (_) {}
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[ForwardSalary] Error: $e');
      return false;
    }
  }

  Future<bool> forwardIncentiveToAccounts(
    String requestId, {
    String notes = 'Forwarded to accounts team',
  }) async {
    try {
      final payload = {
        'request_id': requestId,
        'action': 'forward_to_accounts',
        'notes': notes,
      };

      try {
        await ApiClient.instance.post(
          ApiEndpoints.walletWorkflow,
          data: payload,
        );
      } catch (e) {
        debugPrint('[ForwardIncentive] API call: $e');
      }

      final idx = _smPayoutRequests.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        _smPayoutRequests[idx].status = 'Forwarded to Accounts';
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'cached_sm_requests',
            jsonEncode(_smPayoutRequests.map((e) => e.toJson()).toList()),
          );
        } catch (_) {}
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[ForwardIncentive] Error: $e');
      return false;
    }
  }

  List<SmPayoutRequestModel> _getDefaultSmRequests() {
    return [
      SmPayoutRequestModel(
        id: '6724c0000000000000000001',
        employeeId: 'ASM001',
        employeeName: 'Bipin Joseph',
        designation: 'Area Sales Manager',
        month: 'October 2026',
        amount: 45000,
        status: 'Pending_SM',
        type: 'Salary',
        submittedAt: 'Oct 31, 2026',
        notes: 'Monthly salary approval for October 2026',
      ),
      SmPayoutRequestModel(
        id: '6724d0000000000000000002',
        employeeId: 'ASM004',
        employeeName: 'Anjali Krishna',
        designation: 'Area Sales Manager',
        amount: 12500,
        status: 'Pending_SM',
        type: 'Incentive',
        submittedAt: 'Oct 31, 2026',
        notes: 'Central Zone target achievement bonus for October',
      ),
      SmPayoutRequestModel(
        id: '6724c0000000000000000003',
        employeeId: 'BDE001',
        employeeName: 'Rahul Das',
        designation: 'Business Development Executive',
        month: 'October 2026',
        amount: 22000,
        status: 'Pending_SM',
        type: 'Salary',
        submittedAt: 'Oct 30, 2026',
        notes: 'Verified attendance and target completion',
      ),
      SmPayoutRequestModel(
        id: '6724d0000000000000000004',
        employeeId: 'BDE003',
        employeeName: 'Deepak S.',
        designation: 'Business Development Executive',
        amount: 8000,
        status: 'Forwarded to Accounts',
        type: 'Incentive',
        submittedAt: 'Oct 29, 2026',
        notes: 'Top team closing spot bonus for 15 admissions',
      ),
    ];
  }

  List<SmAsmModel> _getDefaultAsmList() {
    return [
      const SmAsmModel(
        id: '672322300000000000000001',
        employeeId: 'ASM001',
        name: 'Bipin Joseph',
        email: 'bipin.tvm@kide.com',
        contactNumber: '+91 90000 00001',
        designation: 'Area Sales Manager',
        team: 'TVM Team',
        districts: ['Thiruvananthapuram', 'Kollam'],
        zone: 'South Zone',
        reportsTo: 'SM001',
        bdesCount: 4,
        status: 'active',
        dailyTarget: 12,
        dailyAchieved: 5,
        dailyPending: 7,
        dailyCompletionPercentage: 42,
        monthlyTarget: 45,
        monthlyAchieved: 32,
        monthlyPending: 13,
        monthlyCompletionPercentage: 71,
        totalLeads: 120,
        completedLeads: 85,
        pendingLeads: 35,
        completionPercentage: 71,
      ),
      const SmAsmModel(
        id: '672322300000000000000002',
        employeeId: 'ASM002',
        name: 'Mathew Thomas',
        email: 'mathew.ptm@kide.com',
        contactNumber: '+91 90000 00002',
        designation: 'Area Sales Manager',
        team: 'PTM Team',
        districts: ['Pathanamthitta', 'Alappuzha'],
        zone: 'South Zone',
        reportsTo: 'SM001',
        bdesCount: 3,
        status: 'active',
        dailyTarget: 10,
        dailyAchieved: 4,
        dailyPending: 6,
        dailyCompletionPercentage: 40,
        monthlyTarget: 35,
        monthlyAchieved: 22,
        monthlyPending: 13,
        monthlyCompletionPercentage: 63,
        totalLeads: 95,
        completedLeads: 60,
        pendingLeads: 35,
        completionPercentage: 63,
      ),
      const SmAsmModel(
        id: '672322300000000000000003',
        employeeId: 'ASM003',
        name: 'Suresh Kumar',
        email: 'suresh.ktm@kide.com',
        contactNumber: '+91 90000 00003',
        designation: 'Area Sales Manager',
        team: 'KTM Team',
        districts: ['Kottayam', 'Idukki'],
        zone: 'South Zone',
        reportsTo: 'SM001',
        bdesCount: 3,
        status: 'active',
        dailyTarget: 8,
        dailyAchieved: 3,
        dailyPending: 5,
        dailyCompletionPercentage: 38,
        monthlyTarget: 30,
        monthlyAchieved: 17,
        monthlyPending: 13,
        monthlyCompletionPercentage: 57,
        totalLeads: 80,
        completedLeads: 46,
        pendingLeads: 34,
        completionPercentage: 58,
      ),
      const SmAsmModel(
        id: '672322300000000000000004',
        employeeId: 'ASM004',
        name: 'Anjali Krishna',
        email: 'anjali.ekm@kide.com',
        contactNumber: '+91 90000 00004',
        designation: 'Area Sales Manager',
        team: 'EKM Team',
        districts: ['Ernakulam', 'Thrissur'],
        zone: 'Central Zone',
        reportsTo: 'SM001',
        bdesCount: 5,
        status: 'active',
        dailyTarget: 15,
        dailyAchieved: 8,
        dailyPending: 7,
        dailyCompletionPercentage: 53,
        monthlyTarget: 50,
        monthlyAchieved: 40,
        monthlyPending: 10,
        monthlyCompletionPercentage: 80,
        totalLeads: 140,
        completedLeads: 113,
        pendingLeads: 27,
        completionPercentage: 81,
      ),
      const SmAsmModel(
        id: '672322300000000000000005',
        employeeId: 'ASM005',
        name: 'Faisal Rahman',
        email: 'faisal.pkd@kide.com',
        contactNumber: '+91 90000 00005',
        designation: 'Area Sales Manager',
        team: 'PKD Team',
        districts: ['Palakkad', 'Malappuram'],
        zone: 'Central Zone',
        reportsTo: 'SM001',
        bdesCount: 4,
        status: 'active',
        dailyTarget: 11,
        dailyAchieved: 5,
        dailyPending: 6,
        dailyCompletionPercentage: 45,
        monthlyTarget: 40,
        monthlyAchieved: 26,
        monthlyPending: 14,
        monthlyCompletionPercentage: 65,
        totalLeads: 110,
        completedLeads: 72,
        pendingLeads: 38,
        completionPercentage: 65,
      ),
      const SmAsmModel(
        id: '672322300000000000000006',
        employeeId: 'ASM006',
        name: 'Rinil R.',
        email: 'rinil.clt@kide.com',
        contactNumber: '+91 90000 00006',
        designation: 'Area Sales Manager',
        team: 'CLT Team',
        districts: ['Kozhikode', 'Wayanad'],
        zone: 'North Zone',
        reportsTo: 'SM001',
        bdesCount: 4,
        status: 'active',
        dailyTarget: 12,
        dailyAchieved: 6,
        dailyPending: 6,
        dailyCompletionPercentage: 50,
        monthlyTarget: 42,
        monthlyAchieved: 29,
        monthlyPending: 13,
        monthlyCompletionPercentage: 69,
        totalLeads: 115,
        completedLeads: 79,
        pendingLeads: 36,
        completionPercentage: 69,
      ),
      const SmAsmModel(
        id: '672322300000000000000007',
        employeeId: 'ASM007',
        name: 'Deepesh K.',
        email: 'deepesh.kzd@kide.com',
        contactNumber: '+91 90000 00007',
        designation: 'Area Sales Manager',
        team: 'KZD Team',
        districts: ['Kannur', 'Kasaragod'],
        zone: 'North Zone',
        reportsTo: 'SM001',
        bdesCount: 3,
        status: 'active',
        dailyTarget: 9,
        dailyAchieved: 3,
        dailyPending: 6,
        dailyCompletionPercentage: 33,
        monthlyTarget: 32,
        monthlyAchieved: 18,
        monthlyPending: 14,
        monthlyCompletionPercentage: 56,
        totalLeads: 85,
        completedLeads: 47,
        pendingLeads: 38,
        completionPercentage: 55,
      ),
    ];
  }

  // --- 4. ASM (Area Sales Manager) APIs ---
  Future<void> fetchAsmBdes({bool isRefresh = false}) async {
    final cleanRole = AuthProvider.instance.session.role.trim().toUpperCase();
    if (cleanRole == 'BDE' ||
        !['ASM', 'BDM', 'SM', 'ADMIN', 'MD'].contains(cleanRole)) {
      debugPrint(
        '[fetchAsmBdes] Skipping /api/asm/bdes because user role ($cleanRole) is not allowed',
      );
      return;
    }

    if (!isRefresh && _asmBdes.isNotEmpty) return;
    _isLoadingAsmBdes = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_asm_bdes');
      if (cached != null && _asmBdes.isEmpty) {
        try {
          final decoded = jsonDecode(cached);
          if (decoded is List) {
            _asmBdes = decoded
                .whereType<Map>()
                .map((e) => AsmBdeModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            notifyListeners();
          }
        } catch (_) {}
      }

      final response = await ApiClient.instance.get(ApiEndpoints.asmBdes);
      if (response.data != null) {
        dynamic raw = response.data;
        if (raw is Map && raw['data'] is List) {
          raw = raw['data'];
        }
        if (raw is List && raw.isNotEmpty) {
          _asmBdes = raw
              .whereType<Map>()
              .map((e) => AsmBdeModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          await prefs.setString(
            'cached_asm_bdes',
            jsonEncode(_asmBdes.map((e) => e.toJson()).toList()),
          );
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching /api/asm/bdes: $e');
    } finally {
      if (_asmBdes.isEmpty) {
        _asmBdes = _getDefaultAsmBdes();
      }
      _isLoadingAsmBdes = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createBde({
    required String name,
    required String email,
    required String phone,
    required String district,
    String password = 'password123',
    String? team,
    String? reportsTo,
  }) async {
    final payload = {
      'name': name,
      'email': email,
      'contact_number': phone,
      'password': password,
      'district': district,
    };

    debugPrint('====================================================');
    debugPrint('🚀 [POST ${ApiEndpoints.asmCreateBde}] Payload: $payload');

    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.asmCreateBde,
        data: payload,
      );

      debugPrint(
        '🚀 [POST ${ApiEndpoints.asmCreateBde}] Status: ${response.statusCode}',
      );
      debugPrint(
        '🚀 [POST ${ApiEndpoints.asmCreateBde}] Response Body: ${response.data}',
      );
      debugPrint('====================================================');

      String empId = 'BDE${(_asmBdes.length + 1).toString().padLeft(3, '0')}';
      String bdeId = 'bde_${DateTime.now().millisecondsSinceEpoch}';
      String message = 'BDE $name created successfully.';
      String bdeTeam =
          team ??
          (district.isNotEmpty
              ? '${district.substring(0, 3).toUpperCase()} Team'
              : 'Sales Team');
      String bdeReportsTo = reportsTo ?? 'ASM';

      if (response.data != null && response.data is Map) {
        final dataMap = response.data as Map;
        if (dataMap['success'] == false) {
          return {
            'success': false,
            'message':
                dataMap['message']?.toString() ?? 'Failed to create BDE.',
          };
        }
        if (dataMap['message'] != null &&
            dataMap['message'].toString().isNotEmpty) {
          message = dataMap['message'].toString();
        }
        final resData = dataMap['data'];
        if (resData is Map) {
          if (resData['id'] != null) bdeId = resData['id'].toString();
          if (resData['_id'] != null) bdeId = resData['_id'].toString();
          if (resData['employee_id'] != null)
            empId = resData['employee_id'].toString();
          if (resData['team'] != null) bdeTeam = resData['team'].toString();
          if (resData['reports_to'] != null)
            bdeReportsTo = resData['reports_to'].toString();
        }
      }

      final newBde = AsmBdeModel(
        id: bdeId,
        employeeId: empId,
        name: name,
        email: email,
        contactNumber: phone,
        designation: 'Business Development Executive',
        team: bdeTeam,
        district: district,
        reportsTo: bdeReportsTo,
        leadsAssigned: 0,
        admissionsClosed: 0,
        conversionRate: '0%',
        status: 'active',
      );

      _asmBdes.insert(0, newBde);

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'cached_asm_bdes',
          jsonEncode(_asmBdes.map((e) => e.toJson()).toList()),
        );
      } catch (_) {}

      notifyListeners();
      return {'success': true, 'message': message, 'bde': newBde};
    } on NetworkException catch (e) {
      debugPrint('[CreateBde] NetworkException: ${e.message}');
      return {'success': false, 'message': e.message};
    } catch (e) {
      debugPrint('[CreateBde] Error: $e');
      final errStr = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ApiException: ', '')
          .replaceAll('[400] Bad Request: ', '');
      return {'success': false, 'message': errStr};
    }
  }

  Future<void> fetchBdePendingRequests({bool isRefresh = false}) async {
    if (!isRefresh && _bdePayoutRequests.isNotEmpty) return;
    _isLoadingBdeRequests = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_bde_requests');
      if (cached != null && _bdePayoutRequests.isEmpty) {
        try {
          final decoded = jsonDecode(cached);
          if (decoded is List) {
            _bdePayoutRequests = decoded
                .whereType<Map>()
                .map(
                  (e) => SmPayoutRequestModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList();
            notifyListeners();
          }
        } catch (_) {}
      }

      final List<SmPayoutRequestModel> combined = [];

      // 1. Wallet / Incentive Requests (Pending_ASM / Pending)
      try {
        final walRes = await ApiClient.instance.get(
          ApiEndpoints.walletRequests,
          queryParameters: {'status': 'Pending_ASM'},
        );
        if (walRes.data != null) {
          dynamic raw = walRes.data;
          if (raw is Map && raw['data'] is List) raw = raw['data'];
          if (raw is List) {
            for (final item in raw) {
              if (item is Map) {
                combined.add(
                  SmPayoutRequestModel.fromJson(
                    Map<String, dynamic>.from(item),
                    defaultType: 'Incentive',
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[BdeWalletRequests] Fetch error: $e');
      }

      // 2. Salary Requests (Pending_ASM / Pending)
      try {
        final salRes = await ApiClient.instance.get(
          ApiEndpoints.salaryRequests,
          queryParameters: {'status': 'Pending_ASM'},
        );
        if (salRes.data != null) {
          dynamic raw = salRes.data;
          if (raw is Map && raw['data'] is List) raw = raw['data'];
          if (raw is List) {
            for (final item in raw) {
              if (item is Map) {
                combined.add(
                  SmPayoutRequestModel.fromJson(
                    Map<String, dynamic>.from(item),
                    defaultType: 'Salary',
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[BdeSalaryRequests] Fetch error: $e');
      }

      if (combined.isNotEmpty) {
        _bdePayoutRequests = combined;
        await prefs.setString(
          'cached_bde_requests',
          jsonEncode(_bdePayoutRequests.map((e) => e.toJson()).toList()),
        );
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Error fetching BDE requests: $e');
    } finally {
      if (_bdePayoutRequests.isEmpty) {
        _bdePayoutRequests = _getDefaultBdeRequests();
      }
      _isLoadingBdeRequests = false;
      notifyListeners();
    }
  }

  Future<bool> forwardBdeIncentiveToSm(
    String requestId, {
    String notes = 'Verified by ASM',
  }) async {
    try {
      final payload = {
        'request_id': requestId,
        'action': 'forward_to_sm',
        'notes': notes,
      };

      try {
        await ApiClient.instance.post(
          ApiEndpoints.walletWorkflow,
          data: payload,
        );
      } catch (e) {
        debugPrint('[ForwardBdeIncentiveToSm] API call: $e');
      }

      final idx = _bdePayoutRequests.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        _bdePayoutRequests[idx].status = 'Forwarded to SM';
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'cached_bde_requests',
            jsonEncode(_bdePayoutRequests.map((e) => e.toJson()).toList()),
          );
        } catch (_) {}
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[ForwardBdeIncentiveToSm] Error: $e');
      return false;
    }
  }

  Future<bool> forwardBdeSalaryToSm(
    String requestId, {
    String notes = 'Attendance and metrics verified by ASM',
  }) async {
    try {
      final payload = {
        'request_id': requestId,
        'action': 'forward_to_sm',
        'notes': notes,
      };

      try {
        await ApiClient.instance.post(
          ApiEndpoints.salaryWorkflow,
          data: payload,
        );
      } catch (e) {
        debugPrint('[ForwardBdeSalaryToSm] API call: $e');
      }

      final idx = _bdePayoutRequests.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        _bdePayoutRequests[idx].status = 'Forwarded to SM';
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'cached_bde_requests',
            jsonEncode(_bdePayoutRequests.map((e) => e.toJson()).toList()),
          );
        } catch (_) {}
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[ForwardBdeSalaryToSm] Error: $e');
      return false;
    }
  }

  List<AsmBdeModel> _getDefaultAsmBdes() {
    return const [
      AsmBdeModel(
        id: '672430000000000000000011',
        employeeId: 'BDE001',
        name: 'Rahul Das',
        email: 'rahul.ekm@kide.com',
        contactNumber: '+91 98000 12345',
        designation: 'Business Development Executive',
        team: 'EKM Team',
        district: 'Ernakulam',
        reportsTo: 'ASM004',
        leadsAssigned: 54,
        admissionsClosed: 18,
        conversionRate: '33.3%',
        status: 'active',
      ),
      AsmBdeModel(
        id: '672430000000000000000012',
        employeeId: 'BDE002',
        name: 'Sneha Nair',
        email: 'sneha.ekm@kide.com',
        contactNumber: '+91 98000 67890',
        designation: 'Business Development Executive',
        team: 'EKM Team',
        district: 'Ernakulam',
        reportsTo: 'ASM004',
        leadsAssigned: 42,
        admissionsClosed: 11,
        conversionRate: '26.2%',
        status: 'active',
      ),
      AsmBdeModel(
        id: '672430000000000000000013',
        employeeId: 'BDE003',
        name: 'Deepak S.',
        email: 'deepak.tsr@kide.com',
        contactNumber: '+91 98450 33445',
        designation: 'Business Development Executive',
        team: 'EKM Team',
        district: 'Thrissur',
        reportsTo: 'ASM004',
        leadsAssigned: 35,
        admissionsClosed: 10,
        conversionRate: '28.6%',
        status: 'active',
      ),
    ];
  }

  List<SmPayoutRequestModel> _getDefaultBdeRequests() {
    return [
      SmPayoutRequestModel(
        id: '6724d0000000000000000101',
        employeeId: 'BDE001',
        employeeName: 'Rahul Das',
        designation: 'Business Development Executive',
        amount: 6000,
        status: 'Pending_ASM',
        type: 'Incentive',
        submittedAt: 'Today, 10:15 AM',
        notes: 'Monthly milestone closing incentive for 6 admissions',
      ),
      SmPayoutRequestModel(
        id: '6724d0000000000000000102',
        employeeId: 'BDE002',
        employeeName: 'Sneha Nair',
        designation: 'Business Development Executive',
        amount: 3500,
        status: 'Pending_ASM',
        type: 'Incentive',
        submittedAt: 'Yesterday, 04:30 PM',
        notes: 'Walk-in conversion incentive bonus',
      ),
      SmPayoutRequestModel(
        id: '6724c0000000000000000103',
        employeeId: 'BDE003',
        employeeName: 'Deepak S.',
        designation: 'Business Development Executive',
        month: 'October 2026',
        amount: 22000,
        status: 'Pending_ASM',
        type: 'Salary',
        submittedAt: 'Oct 31, 2026',
        notes: 'Monthly salary disbursement request',
      ),
    ];
  }

  Future<void> fetchWalletApprovalRequests({
    String? status,
    bool isRefresh = false,
  }) async {
    if (_isLoadingWalletRequests) return;
    if (!isRefresh && _walletApprovalRequests.isNotEmpty) return;

    _isLoadingWalletRequests = true;
    _walletRequestsError = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!isRefresh && _walletApprovalRequests.isEmpty) {
        final cached = prefs.getString('cached_wallet_approval_requests');
        if (cached != null) {
          try {
            final decoded = jsonDecode(cached);
            if (decoded is Map<String, dynamic>) {
              final resp = WalletApprovalResponse.fromJson(decoded);
              _walletApprovalRequests = resp.data;
              _walletApprovalSummary = resp.summary;
              notifyListeners();
            }
          } catch (_) {}
        }
      }

      final queryParams = <String, dynamic>{};
      if (status != null &&
          status.isNotEmpty &&
          status.toLowerCase() != 'all') {
        queryParams['status'] = status;
      }

      final res = await ApiClient.instance.get(
        ApiEndpoints.walletRequests,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (res.data != null) {
        dynamic raw = res.data;
        if (raw is String) {
          try {
            raw = jsonDecode(raw);
          } catch (_) {}
        }
        if (raw is Map) {
          final map = Map<String, dynamic>.from(raw);
          final resp = WalletApprovalResponse.fromJson(map);
          _walletApprovalRequests = resp.data;
          _walletApprovalSummary = resp.summary;
          await prefs.setString(
            'cached_wallet_approval_requests',
            jsonEncode(map),
          );
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('[WalletRequests] Error: $e');
      _walletRequestsError = e.toString();
    } finally {
      if (_walletApprovalRequests.isEmpty && _walletRequestsError != null) {
        _walletApprovalRequests = _getDefaultWalletApprovalRequests();
        _walletApprovalSummary = _getDefaultWalletApprovalSummary();
      }
      _isLoadingWalletRequests = false;
      notifyListeners();
    }
  }

  void addWalletApprovalRequest(WalletApprovalRequestItem item) {
    _walletApprovalRequests.removeWhere(
      (r) => r.id == item.id || r.requestId == item.requestId,
    );
    _walletApprovalRequests.insert(0, item);
    notifyListeners();
  }

  Future<bool> forwardWalletRequestToSm(
    String requestId, {
    String remarks = 'ASM verified 4 closed admissions. Recommended.',
  }) async {
    try {
      final idx = _walletApprovalRequests.indexWhere(
        (r) => r.id == requestId || r.requestId == requestId,
      );
      final reqCode =
          (idx != -1 && _walletApprovalRequests[idx].requestId.isNotEmpty)
          ? _walletApprovalRequests[idx].requestId
          : requestId;

      final payload = {
        'request_id': reqCode,
        'action': 'forward_to_sm',
        'remarks': remarks,
        'notes': remarks,
      };
      try {
        await ApiClient.instance.post(
          ApiEndpoints.walletWorkflow,
          data: payload,
        );
      } catch (e) {
        debugPrint('[forwardWalletRequestToSm] API call: $e');
      }

      if (idx != -1) {
        final current = _walletApprovalRequests[idx];
        current.status = 'Forwarded to SM';
        current.statusLabel = 'Pending';
        final exists = current.approvalHistory.any(
          (h) =>
              h.stage.toLowerCase().contains('sm') ||
              h.action == 'FORWARD_TO_SM',
        );
        if (!exists) {
          current.approvalHistory.add(
            WalletApprovalStage(
              stage: 'Step 2 - ASM Review: Forwarded to SM',
              actionBy: 'Area Sales Manager',
              role: 'ASM',
              action: 'FORWARD_TO_SM',
              actionAt: DateTime.now().toIso8601String(),
              remarks: remarks,
            ),
          );
        }
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[forwardWalletRequestToSm] Error: $e');
      return false;
    }
  }

  Future<bool> forwardWalletRequestToAccounts(
    String requestId, {
    String remarks =
        'Verified admissions and eligibility. Forwarded to Accounts for sanction.',
  }) async {
    try {
      final idx = _walletApprovalRequests.indexWhere(
        (r) => r.id == requestId || r.requestId == requestId,
      );
      final reqCode =
          (idx != -1 && _walletApprovalRequests[idx].requestId.isNotEmpty)
          ? _walletApprovalRequests[idx].requestId
          : requestId;

      final payload = {
        'request_id': reqCode,
        'action': 'forward_to_accounts',
        'remarks': remarks,
        'notes': remarks,
      };

      try {
        final res = await ApiClient.instance.post(
          ApiEndpoints.walletWorkflow,
          data: payload,
        );
        if (res.data != null && res.data is Map) {
          final dataMap = res.data['data'] is Map
              ? Map<String, dynamic>.from(res.data['data'])
              : null;
          if (dataMap != null && idx != -1) {
            final current = _walletApprovalRequests[idx];
            current.status =
                dataMap['status']?.toString() ?? 'Forwarded to Accounts';
            current.statusLabel =
                dataMap['status_label']?.toString() ?? 'Pending';
            if (dataMap['approval_history'] is List) {
              final newHistory = (dataMap['approval_history'] as List)
                  .whereType<Map>()
                  .map(
                    (e) => WalletApprovalStage.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList();
              current.approvalHistory = newHistory;
            }
          }
        }
      } catch (e) {
        debugPrint('[forwardWalletRequestToAccounts] API call: $e');
      }

      if (idx != -1) {
        final current = _walletApprovalRequests[idx];
        current.status = 'Forwarded to Accounts';
        current.statusLabel = 'Pending';
        final exists = current.approvalHistory.any(
          (h) =>
              h.stage.toLowerCase().contains('accounts') ||
              h.action == 'FORWARD_TO_ACCOUNTS',
        );
        if (!exists) {
          current.approvalHistory.add(
            WalletApprovalStage(
              stage: 'Step 3 - SM Review: Forwarded to Accounts',
              actionBy: 'Sales Manager',
              role: 'SM',
              action: 'FORWARD_TO_ACCOUNTS',
              actionAt: DateTime.now().toIso8601String(),
              remarks: remarks,
            ),
          );
        }
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'cached_wallet_approval_requests',
            jsonEncode({
              'success': true,
              'count': _walletApprovalRequests.length,
              'summary': _walletApprovalSummary?.toJson() ?? {},
              'data': _walletApprovalRequests.map((e) => e.toJson()).toList(),
            }),
          );
        } catch (_) {}
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[forwardWalletRequestToAccounts] Error: $e');
      return false;
    }
  }

  Future<bool> disburseWalletRequest(
    String requestId, {
    required String transactionId,
    String notes = 'Disbursed to employee',
  }) async {
    try {
      final payload = {
        'request_id': requestId,
        'action': 'disburse',
        'transaction_id': transactionId,
        'notes': notes,
      };
      try {
        await ApiClient.instance.post(
          ApiEndpoints.walletWorkflow,
          data: payload,
        );
      } catch (e) {
        debugPrint('[disburseWalletRequest] API call: $e');
      }

      final idx = _walletApprovalRequests.indexWhere(
        (r) => r.id == requestId || r.requestId == requestId,
      );
      if (idx != -1) {
        final current = _walletApprovalRequests[idx];
        current.status = 'Paid';
        current.approvalHistory.add(
          WalletApprovalStage(
            stage: 'Disbursed with UTR $transactionId',
            actionBy: 'Accounts',
            actionAt: DateTime.now().toIso8601String(),
            remarks: notes,
          ),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[disburseWalletRequest] Error: $e');
      return false;
    }
  }

  List<WalletApprovalRequestItem> _getDefaultWalletApprovalRequests() {
    return [
      WalletApprovalRequestItem(
        id: '6724d1a00000000000000001',
        requestId: 'WDR-5821',
        employee: 'Siddharth V',
        employeeId: 'BDE001',
        designation: 'Business Development Executive',
        team: 'EKM Team',
        asmId: 'ASM004',
        asmName: 'Anoop Menon',
        smId: 'SM001',
        smName: 'Sales Manager',
        amount: 4000,
        availableBalance: 8000,
        status: 'Forwarded to SM',
        statusLabel: 'Pending',
        remarks: 'ASM verified 4 closed admissions. Recommended.',
        approvalHistory: const [
          WalletApprovalStage(
            stage: 'Submitted to ASM',
            actionBy: 'BDE001',
            actionAt: '2026-11-01T10:00:00.000Z',
            remarks: 'Incentive withdrawal requested',
          ),
          WalletApprovalStage(
            stage: 'Forwarded to SM',
            actionBy: 'ASM004',
            actionAt: '2026-11-02T09:30:00.000Z',
            remarks: 'ASM verified 4 closed admissions. Recommended.',
          ),
        ],
        createdAt: '2026-11-01T10:00:00.000Z',
      ),
      WalletApprovalRequestItem(
        id: '6724d1a00000000000000002',
        requestId: 'WDR-5822',
        employee: 'Rahul Das',
        employeeId: 'BDE002',
        designation: 'Business Development Executive',
        team: 'TVM Team',
        asmId: 'ASM001',
        asmName: 'Bipin Joseph',
        smId: 'SM001',
        smName: 'Sales Manager',
        amount: 5000,
        availableBalance: 12000,
        status: 'Pending_ASM',
        statusLabel: 'Pending',
        remarks:
            'Monthly incentive withdrawal for target milestone achievement.',
        approvalHistory: const [
          WalletApprovalStage(
            stage: 'Submitted to ASM',
            actionBy: 'BDE002',
            actionAt: '2026-11-02T11:00:00.000Z',
            remarks: 'Milestone target incentive request',
          ),
        ],
        createdAt: '2026-11-02T11:00:00.000Z',
      ),
    ];
  }

  WalletApprovalSummary _getDefaultWalletApprovalSummary() {
    return const WalletApprovalSummary(
      total: 2,
      pending: 2,
      approved: 0,
      paid: 0,
      rejected: 0,
      pendingAmount: 9000,
    );
  }

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
    debugPrint(
      '[TaskFilter] role=$role, tasks=${_tasks.length}, userEmail=${user.email}',
    );
    switch (role) {
      case 'MD':
        return _tasks;
      case 'ZM':
        // If zone info isn't in API data yet, return all tasks
        final zoneFiltered = _tasks
            .where(
              (t) => t.zone == user.zone || t.zone == null || t.zone.isEmpty,
            )
            .toList();
        if (_selectedDistrictFilter != null &&
            _selectedDistrictFilter!.isNotEmpty) {
          return zoneFiltered
              .where((t) => t.district == _selectedDistrictFilter)
              .toList();
        }
        return zoneFiltered;
      case 'ASM':
        return _tasks
            .where(
              (t) =>
                  t.district == user.district ||
                  (user.district == null || user.district.isEmpty),
            )
            .toList();
      case 'BDM':
        return _tasks
            .where(
              (t) =>
                  t.team == user.team ||
                  (user.team == null || user.team.isEmpty),
            )
            .toList();
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

  /// Formats any lead ID into canonical backend alphanumeric format (e.g. "LD-1759").
  static String formatLeadId(String rawId) {
    String clean = rawId.trim();
    if (clean.isEmpty) return clean;
    if (clean.startsWith('LD-')) {
      return clean;
    }
    if (clean.startsWith('LD_')) {
      return 'LD-${clean.substring(3)}';
    }
    if (clean.toUpperCase().startsWith('LD') &&
        clean.length > 2 &&
        RegExp(r'^\d+$').hasMatch(clean.substring(2))) {
      return 'LD-${clean.substring(2)}';
    }
    if (RegExp(r'^\d+$').hasMatch(clean)) {
      return 'LD-$clean';
    }
    return clean;
  }

  /// Resolves the canonical alphanumeric lead ID (e.g. "LD-1759") from given leadId or fallback.
  String resolveLeadId(String? leadId, String fallbackId) {
    String candidate = (leadId != null && leadId.trim().isNotEmpty)
        ? leadId.trim()
        : fallbackId.trim();

    final matchedTask = _tasks
        .where(
          (t) =>
              t.id == candidate ||
              t.leadId == candidate ||
              t.leadIdentifier == candidate ||
              t.id == fallbackId ||
              t.leadId == fallbackId,
        )
        .firstOrNull;

    if (matchedTask != null) {
      if (matchedTask.leadId != null && matchedTask.leadId!.trim().isNotEmpty) {
        candidate = matchedTask.leadId!.trim();
      } else if (matchedTask.leadIdentifier.isNotEmpty &&
          !RegExp(r'^\d{7,}$').hasMatch(matchedTask.leadIdentifier)) {
        candidate = matchedTask.leadIdentifier;
      }
    }

    return formatLeadId(candidate);
  }

  Future<void> saveFollowUp({
    required String leadId,
    String? actualLeadId,
    required String leadSource,
    required String studentInterest,
    required String nextFollowupDate,
    required String remarks,
    required String admissionStatus,
    required String paymentVerification,
    required String studentId,
    required String course,
    String? proofPath,
  }) async {
    final targetLeadId = resolveLeadId(actualLeadId, leadId);

    if (targetLeadId.isNotEmpty) {
      final payload = {
        'lead_id': targetLeadId,
        'lead_source': leadSource,
        'student_interest': studentInterest,
        'next_followup_date': nextFollowupDate,
        'remarks': remarks,
        'admission_status': admissionStatus,
        'payment_verification': paymentVerification,
        'student_id': studentId,
        'course': course,
      };
      if (proofPath != null && proofPath.isNotEmpty) {
        payload['proof'] = proofPath;
        payload['attachment'] = proofPath;
      }

      debugPrint(
        '[saveFollowUp] Posting to /leads/$targetLeadId/followup: $payload',
      );
      await ApiClient.instance.post(
        ApiEndpoints.followUpLead(targetLeadId),
        data: payload,
      );

      // Update local state
      final index = _tasks.indexWhere(
        (t) =>
            t.id == leadId || t.leadId == targetLeadId || t.id == targetLeadId,
      );
      if (index != -1) {
        final currentTask = _tasks[index];
        final updatedFollowUps =
            List<FollowUpItem>.from(currentTask.followUps ?? [])..add(
              FollowUpItem(
                dateTime: nextFollowupDate,
                remark: remarks,
                attachment: proofPath,
              ),
            );

        _tasks[index] = currentTask.copyWith(
          studentId: studentId.isNotEmpty ? studentId : currentTask.studentId,
          followUps: updatedFollowUps,
          remarks: remarks,
          leadStatus: admissionStatus,
        );
      }

      await fetchLeads(status: 1, isRefresh: true);
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

    // Set Mock Wallet Approval Requests if empty
    if (_walletApprovalRequests.isEmpty) {
      final cached = prefs.getString('cached_wallet_approval_requests');
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached);
          if (decoded is Map<String, dynamic>) {
            final resp = WalletApprovalResponse.fromJson(decoded);
            _walletApprovalRequests = resp.data;
            _walletApprovalSummary = resp.summary;
          }
        } catch (_) {}
      }
      if (_walletApprovalRequests.isEmpty) {
        _walletApprovalRequests = _getDefaultWalletApprovalRequests();
        _walletApprovalSummary = _getDefaultWalletApprovalSummary();
      }
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
      if (response.data != null) {
        final dynamic rawResponse = response.data;

        // If response is a Map with 'success' == false, abort
        if (rawResponse is Map && rawResponse['success'] == false) {
          return;
        }

        dynamic rawData = rawResponse;
        if (rawResponse is Map && rawResponse.containsKey('data')) {
          rawData = rawResponse['data'];
        }

        // 1. Extract balances (can be in rawResponse['balances'], rawData['balances'], or rawData['leave_balances'])
        dynamic rawBalances;
        if (rawResponse is Map && rawResponse['balances'] != null) {
          rawBalances = rawResponse['balances'];
        } else if (rawData is Map) {
          rawBalances = rawData['balances'] ?? rawData['leave_balances'];
        }

        if (rawBalances != null) {
          if (rawBalances is Map) {
            final casual = rawBalances['casual'];
            final medical = rawBalances['medical'];
            final earned = rawBalances['earned'];

            if (casual is num) {
              _leaveBalanceCasual = casual.toInt();
            } else if (casual != null) {
              _leaveBalanceCasual =
                  int.tryParse(casual.toString()) ?? _leaveBalanceCasual;
            }

            if (medical is num) {
              _leaveBalanceMedical = medical.toInt();
            } else if (medical != null) {
              _leaveBalanceMedical =
                  int.tryParse(medical.toString()) ?? _leaveBalanceMedical;
            }

            if (earned is num) {
              _leaveBalanceEarned = earned.toInt();
            } else if (earned != null) {
              _leaveBalanceEarned =
                  int.tryParse(earned.toString()) ?? _leaveBalanceEarned;
            }
          } else if (rawBalances is List) {
            for (final b in rawBalances) {
              if (b is Map) {
                final type = (b['type'] ?? b['name'] ?? b['leave_type'] ?? '')
                    .toString()
                    .toLowerCase();
                final val =
                    b['balance'] ?? b['count'] ?? b['remaining'] ?? b['days'];
                final count = val is num
                    ? val.toInt()
                    : int.tryParse(val?.toString() ?? '');
                if (count != null) {
                  if (type.contains('casual')) _leaveBalanceCasual = count;
                  if (type.contains('medical')) _leaveBalanceMedical = count;
                  if (type.contains('earned')) _leaveBalanceEarned = count;
                }
              }
            }
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('leave_bal_casual', _leaveBalanceCasual);
          await prefs.setInt('leave_bal_medical', _leaveBalanceMedical);
          await prefs.setInt('leave_bal_earned', _leaveBalanceEarned);
        }

        // 2. Extract leave history list
        List<dynamic> historyList = [];
        if (rawData is List) {
          historyList = rawData;
        } else if (rawData is Map) {
          if (rawData['history'] is List) {
            historyList = rawData['history'] as List<dynamic>;
          } else if (rawData['leaves'] is List) {
            historyList = rawData['leaves'] as List<dynamic>;
          } else if (rawData['data'] is List) {
            historyList = rawData['data'] as List<dynamic>;
          } else if (rawData['items'] is List) {
            historyList = rawData['items'] as List<dynamic>;
          }
        }

        if (historyList.isNotEmpty || (rawData is List)) {
          _leaves = historyList.map((item) {
            if (item is! Map) {
              return LeaveModel(
                id: '',
                leaveType: 'Leave',
                fromDate: DateTime.now(),
                toDate: DateTime.now(),
                reason: '',
                status: 'Pending',
                appliedDate: DateTime.now(),
              );
            }

            final id = (item['id'] ?? '').toString();

            // Determine leave type name
            String mappedLeaveType = '';
            final rawType =
                item['type_name'] ?? item['leave_type'] ?? item['type'];
            if (rawType is int || rawType is num) {
              final typeCode = (rawType as num).toInt();
              if (typeCode == 1) {
                mappedLeaveType = 'Casual Leave';
              } else if (typeCode == 2) {
                mappedLeaveType = 'Medical Leave';
              } else if (typeCode == 3) {
                mappedLeaveType = 'Earned Leave';
              } else {
                mappedLeaveType = 'Leave';
              }
            } else if (rawType != null) {
              mappedLeaveType = rawType.toString();
              if (mappedLeaveType.isNotEmpty &&
                  !mappedLeaveType.toLowerCase().contains('leave')) {
                mappedLeaveType = '$mappedLeaveType Leave';
              }
            } else {
              mappedLeaveType = 'Leave';
            }

            final fromDate =
                DateTime.tryParse(
                  (item['start_date'] ?? item['from_date'] ?? '').toString(),
                ) ??
                DateTime.now();
            final toDate =
                DateTime.tryParse(
                  (item['end_date'] ?? item['to_date'] ?? '').toString(),
                ) ??
                fromDate;
            final reason = (item['reason'] ?? '').toString();

            // Determine status
            final rawStatus = item['status_name'] ?? item['status'];
            String status = 'Pending';
            if (rawStatus is int || rawStatus is num) {
              final statusCode = (rawStatus as num).toInt();
              if (statusCode == 1) {
                status = 'Approved';
              } else if (statusCode == 2) {
                status = 'Rejected';
              } else {
                status = 'Pending';
              }
            } else if (rawStatus != null && rawStatus.toString().isNotEmpty) {
              status = rawStatus.toString();
            }

            final appliedDate =
                DateTime.tryParse(
                  (item['applied_on'] ??
                          item['applied_date'] ??
                          item['created_at'] ??
                          '')
                      .toString(),
                ) ??
                fromDate;

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

  /// Closes a lead with student admission details via POST /api/leads/{id}/close
  Future<void> closeLead({
    required String id,
    String? leadId,
    required String studentId,
    required String course,
    required num payment,
    required String paymentVerification,
    required String remarks,
  }) async {
    _isSubmittingTask = true;
    notifyListeners();
    try {
      final targetLeadId = resolveLeadId(leadId, id);

      if (targetLeadId.isEmpty) {
        throw Exception('Invalid lead ID: $id');
      }

      final payload = {
        'lead_id': targetLeadId,
        'student_id': studentId,
        'course': course,
        'payment': payment,
        'payment_verification': paymentVerification,
        'remarks': remarks,
      };

      debugPrint(
        '[closeLead] Sending payload to /leads/$targetLeadId/close: $payload',
      );
      await ApiClient.instance.post(
        ApiEndpoints.closeLead(targetLeadId),
        data: payload,
      );

      // Update local state to reflect the change immediately in the UI.
      final index = _tasks.indexWhere(
        (t) => t.id == id || t.leadId == targetLeadId || t.id == targetLeadId,
      );
      if (index != -1) {
        final currentTask = _tasks[index];
        _tasks[index] = currentTask.copyWith(
          studentId: (studentId != null && studentId.isNotEmpty)
              ? studentId
              : currentTask.studentId,
          status: 'Completed',
          leadStatus: 'Closed',
          completedDate: DateTime.now(),
          remarks: remarks,
        );
      }

      // Refresh lead lists so the UI reflects the latest server state.
      await fetchLeads(status: 1, isRefresh: true);
      await fetchCompletedLeads(isRefresh: true);
    } catch (e) {
      debugPrint('[closeLead] ERROR: $e');
      rethrow;
    } finally {
      _isSubmittingTask = false;
      notifyListeners();
    }
  }

  /// Update task status (Student Lead admission / close)
  Future<void> updateTaskStatus(
    String id,
    String status, {
    required String leadStatus,
    required String remarks,
    required String proof,
    String? followUpDate,
    String? studentId,
    String? course,
    num? payment,
    String? paymentVerification,
  }) async {
    _isSubmittingTask = true;
    notifyListeners();
    try {
      // If the BDE is closing the lead, hit the dedicated close endpoint.
      if (leadStatus == 'Closed') {
        final taskItem = _tasks.firstWhere(
          (t) => t.id == id || t.leadId == id,
          orElse: () => TaskModel(
            id: id,
            studentName: '',
            location: '',
            course: '',
            description: '',
            assignedDate: DateTime.now(),
            assignedBdeEmail: '',
            team: '',
            district: '',
            zone: '',
          ),
        );
        final targetLeadId = resolveLeadId(taskItem.leadId, id);
        if (targetLeadId.isNotEmpty) {
          final payload = <String, dynamic>{
            'lead_id': targetLeadId,
            'student_id': studentId ?? 'STU-$targetLeadId',
            'course': (course != null && course.isNotEmpty)
                ? course
                : 'Full-Stack Web Development',
            'payment': payment ?? 0,
            'payment_verification':
                (paymentVerification != null && paymentVerification.isNotEmpty)
                ? paymentVerification
                : 'Verified',
            'remarks': remarks,
          };
          debugPrint(
            '[updateTaskStatus] Sending payload to /leads/$targetLeadId/close: $payload',
          );
          await ApiClient.instance.post(
            ApiEndpoints.closeLead(targetLeadId),
            data: payload,
          );
        }
      }

      // Update local state to reflect the change immediately in the UI.
      final index = _tasks.indexWhere((t) => t.id == id || t.leadId == id);
      if (index != -1) {
        final currentTask = _tasks[index];
        List<FollowUpItem>? updatedFollowUps = currentTask.followUps;
        if (followUpDate != null && followUpDate.isNotEmpty) {
          updatedFollowUps = List<FollowUpItem>.from(
            currentTask.followUps ?? [],
          )..add(FollowUpItem(dateTime: followUpDate, remark: remarks));
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
      await fetchLeads(status: 1, isRefresh: true);
      await fetchCompletedLeads(isRefresh: true);
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
        data: {'file': multipartFile},
      );

      if (response.data != null) {
        final Map<String, dynamic> responseData =
            response.data as Map<String, dynamic>;
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

  List<CourseModel> _coursesList = [];
  List<CourseModel> get coursesList => _coursesList;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> get courses => _courses;
  bool _isLoadingCourses = false;
  bool get isLoadingCourses => _isLoadingCourses;

  List<String> get courseNames {
    if (_coursesList.isNotEmpty) {
      return _coursesList
          .map((c) => c.name)
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return _courses
        .map((c) => c['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  CourseModel? findCourseByName(String name) {
    final lower = name.trim().toLowerCase();
    try {
      return _coursesList.firstWhere((c) => c.name.toLowerCase() == lower);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchCourses({bool isRefresh = false}) async {
    if (_isLoadingCourses) return;
    if (!isRefresh && _coursesList.isNotEmpty && _courses.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    if (_coursesList.isEmpty) {
      final cachedStr = prefs.getString('cached_courses_list');
      if (cachedStr != null) {
        try {
          final decoded = jsonDecode(cachedStr);
          if (decoded is List) {
            _coursesList = decoded
                .whereType<Map>()
                .map((e) => CourseModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            _courses = _coursesList.map((c) => c.toJson()).toList();
            notifyListeners();
          }
        } catch (_) {}
      }
    }

    _isLoadingCourses = true;
    notifyListeners();
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.courses);
      if (response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        final List<dynamic> list;
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['courses'] is List) {
          list = rawData['courses'] as List<dynamic>;
        } else {
          list = [];
        }

        if (list.isNotEmpty) {
          _coursesList = list
              .whereType<Map>()
              .map((c) => CourseModel.fromJson(Map<String, dynamic>.from(c)))
              .toList();
          _courses = _coursesList.map((c) => c.toJson()).toList();
          await prefs.setString('cached_courses_list', jsonEncode(_courses));
        }
      }
    } catch (e) {
      debugPrint('[fetchCourses] API call error: $e');
    } finally {
      if (_coursesList.isEmpty) {
        _coursesList = _getDefaultCourses();
        _courses = _coursesList.map((c) => c.toJson()).toList();
      }
      _isLoadingCourses = false;
      notifyListeners();
    }
  }

  List<CourseModel> _getDefaultCourses() {
    return const [
      CourseModel(
        id: '6ad5ab0078fb3739ae6931b0',
        name: 'Full-Stack Web Development',
        fee: 25000,
        duration: '6 Months',
        status: 'active',
      ),
      CourseModel(
        id: '6ad5ab0078fb3739ae6931b1',
        name: 'Data Science & Machine Learning',
        fee: 30000,
        duration: '6 Months',
        status: 'active',
      ),
      CourseModel(
        id: '6ad5ab0078fb3739ae6931b2',
        name: 'Digital Marketing Pro',
        fee: 15000,
        duration: '3 Months',
        status: 'active',
      ),
      CourseModel(
        id: '6ad5ab0078fb3739ae6931b3',
        name: 'Flutter & Mobile App Development',
        fee: 20000,
        duration: '4 Months',
        status: 'active',
      ),
      CourseModel(
        id: '6adaee88eb2425770324ad24',
        name: 'Cyber Security',
        fee: 20000,
        duration: '3 Months',
        status: 'active',
      ),
      CourseModel(
        id: '6ae5a250a84a31d3fc5a4277',
        name: 'Flutter',
        fee: 20000,
        duration: '4 Months',
        status: 'active',
      ),
      CourseModel(
        id: '6ae5a250a84a31d3fc5a4278',
        name: 'Full Stack Development',
        fee: 25000,
        duration: '6 Months',
        status: 'active',
      ),
      CourseModel(
        id: '6ae5a250a84a31d3fc5a4279',
        name: 'Digital Marketing',
        fee: 15000,
        duration: '3 Months',
        status: 'active',
      ),
      CourseModel(
        id: '6ae5a250a84a31d3fc5a427a',
        name: 'Data Science Pro',
        fee: 35000,
        duration: '6 Months',
        status: 'active',
      ),
    ];
  }

  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> get districts => _districts;
  bool _isLoadingDistricts = false;
  bool get isLoadingDistricts => _isLoadingDistricts;

  List<ZoneModel> _zones = [];
  List<ZoneModel> get zones => _zones;
  bool _isLoadingZones = false;
  bool get isLoadingZones => _isLoadingZones;

  List<DistrictModel> _districtsList = [];
  List<DistrictModel> get districtsList => _districtsList;

  Future<void> fetchZones({bool isRefresh = false}) async {
    if (_isLoadingZones) return;
    if (!isRefresh && _zones.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    if (_zones.isEmpty) {
      final cachedStr = prefs.getString('cached_zones');
      if (cachedStr != null) {
        try {
          final decoded = jsonDecode(cachedStr);
          if (decoded is List) {
            _zones = decoded
                .whereType<Map>()
                .map((e) => ZoneModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            notifyListeners();
          }
        } catch (_) {}
      }
    }

    _isLoadingZones = true;
    notifyListeners();
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.zones);
      if (response.data != null) {
        dynamic raw = response.data;
        if (raw is Map && raw.containsKey('data')) {
          raw = raw['data'];
        }
        if (raw is List && raw.isNotEmpty) {
          _zones = raw
              .whereType<Map>()
              .map((e) => ZoneModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          await prefs.setString(
            'cached_zones',
            jsonEncode(_zones.map((e) => e.toJson()).toList()),
          );
        }
      }
    } catch (e) {
      debugPrint('[fetchZones] API call error: $e');
    } finally {
      if (_zones.isEmpty) {
        _zones = _getDefaultZones();
      }
      _isLoadingZones = false;
      notifyListeners();
    }
  }

  List<ZoneModel> _getDefaultZones() {
    return const [
      ZoneModel(
        id: '6724a1b2c3d4e5f607182901',
        name: 'Central Zone',
        description:
            'Central Kerala regional zone (Ernakulam, Idukki, Thrissur, Palakkad, Malappuram)',
      ),
      ZoneModel(
        id: '6724a1b2c3d4e5f607182902',
        name: 'North Zone',
        description:
            'North Kerala regional zone (Kozhikode, Wayanad, Kannur, Kasaragod)',
      ),
      ZoneModel(
        id: '6724a1b2c3d4e5f607182903',
        name: 'South Zone',
        description:
            'South Kerala regional zone (TVM, Kollam, Alappuzha, Pathanamthitta, Kottayam)',
      ),
    ];
  }

  Future<void> fetchDistricts({bool isRefresh = false}) async {
    if (_isLoadingDistricts) return;
    if (!isRefresh && _districtsList.isNotEmpty && _districts.isNotEmpty)
      return;

    final prefs = await SharedPreferences.getInstance();
    if (_districtsList.isEmpty) {
      final cachedStr = prefs.getString('cached_districts_list');
      if (cachedStr != null) {
        try {
          final decoded = jsonDecode(cachedStr);
          if (decoded is List) {
            _districtsList = decoded
                .whereType<Map>()
                .map(
                  (e) => DistrictModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
            _districts = _districtsList.map((d) => d.toJson()).toList();
            notifyListeners();
          }
        } catch (_) {}
      }
    }

    _isLoadingDistricts = true;
    notifyListeners();
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.districts);
      if (response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        final List<dynamic> list;
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['districts'] is List) {
          list = rawData['districts'] as List<dynamic>;
        } else {
          list = [];
        }

        if (list.isNotEmpty) {
          _districtsList = list
              .whereType<Map>()
              .map((d) => DistrictModel.fromJson(Map<String, dynamic>.from(d)))
              .toList();
          _districts = _districtsList.map((d) => d.toJson()).toList();
          await prefs.setString(
            'cached_districts_list',
            jsonEncode(_districtsList.map((e) => e.toJson()).toList()),
          );
        }
      }
    } catch (e) {
      debugPrint('[fetchDistricts] API call error: $e');
    } finally {
      if (_districtsList.isEmpty) {
        _districtsList = _getDefaultDistricts();
        _districts = _districtsList.map((d) => d.toJson()).toList();
      }
      _isLoadingDistricts = false;
      notifyListeners();
    }
  }

  List<DistrictModel> _getDefaultDistricts() {
    return const [
      DistrictModel(
        id: '6724b1b2c3d4e5f607182910',
        name: 'Thiruvananthapuram',
        zone: 'South Zone',
      ),
      DistrictModel(
        id: '6724b1b2c3d4e5f607182911',
        name: 'Kollam',
        zone: 'South Zone',
      ),
      DistrictModel(
        id: '6724b1b2c3d4e5f607182912',
        name: 'Pathanamthitta',
        zone: 'South Zone',
      ),
      DistrictModel(
        id: '6724b1b2c3d4e5f607182913',
        name: 'Alappuzha',
        zone: 'South Zone',
      ),
      DistrictModel(
        id: '6724b1b2c3d4e5f607182914',
        name: 'Kottayam',
        zone: 'South Zone',
      ),
      DistrictModel(
        id: '6724b1b2c3d4e5f607182915',
        name: 'Idukki',
        zone: 'Central Zone',
      ),
      DistrictModel(
        id: '6724b1b2c3d4e5f607182916',
        name: 'Ernakulam',
        zone: 'Central Zone',
      ),
      DistrictModel(
        id: '6724b1b2c3d4e5f607182917',
        name: 'Thrissur',
        zone: 'Central Zone',
      ),
      DistrictModel(
        id: '6724b1b2c3d4e5f607182918',
        name: 'Palakkad',
        zone: 'Central Zone',
      ),
      DistrictModel(
        id: '6724b1b2c3d4e5f607182919',
        name: 'Malappuram',
        zone: 'Central Zone',
      ),
      DistrictModel(
        id: '6724b1b2c3d4e5f607182920',
        name: 'Kozhikode',
        zone: 'North Zone',
      ),
      DistrictModel(
        id: '6724b1b2c3d4e5f607182921',
        name: 'Wayanad',
        zone: 'North Zone',
      ),
      DistrictModel(
        id: '6724b1b2c3d4e5f607182922',
        name: 'Kannur',
        zone: 'North Zone',
      ),
      DistrictModel(
        id: '6724b1b2c3d4e5f607182923',
        name: 'Kasaragod',
        zone: 'North Zone',
      ),
    ];
  }

  List<String> get zoneNames {
    if (_zones.isNotEmpty) {
      return _zones.map((z) => z.name).toSet().toList();
    }
    return ['Central Zone', 'North Zone', 'South Zone'];
  }

  List<String> getDistrictNamesByZone(String? zoneName) {
    if (zoneName != null && zoneName.isNotEmpty) {
      final matched = _districtsList
          .where(
            (d) => d.zone.toLowerCase().trim() == zoneName.toLowerCase().trim(),
          )
          .map((d) => d.name)
          .toSet()
          .toList();
      if (matched.isNotEmpty) return matched;
      if (zoneName.contains('South')) {
        return [
          'Thiruvananthapuram',
          'Kollam',
          'Pathanamthitta',
          'Alappuzha',
          'Kottayam',
        ];
      } else if (zoneName.contains('North')) {
        return ['Kozhikode', 'Wayanad', 'Kannur', 'Kasaragod'];
      } else if (zoneName.contains('Central')) {
        return ['Ernakulam', 'Idukki', 'Thrissur', 'Palakkad', 'Malappuram'];
      }
    }
    return allDistrictNames;
  }

  List<String> get allDistrictNames {
    if (_districtsList.isNotEmpty) {
      return _districtsList.map((d) => d.name).toSet().toList();
    }
    return [
      'Thiruvananthapuram',
      'Kollam',
      'Pathanamthitta',
      'Alappuzha',
      'Kottayam',
      'Idukki',
      'Ernakulam',
      'Thrissur',
      'Palakkad',
      'Malappuram',
      'Kozhikode',
      'Wayanad',
      'Kannur',
      'Kasaragod',
    ];
  }

  Future<void> fetchHierarchyFilters({bool isRefresh = false}) async {
    if (_isLoadingHierarchyFilters) return;
    if (!isRefresh && _hierarchyDistricts.isNotEmpty) return;
    _isLoadingHierarchyFilters = true;
    notifyListeners();
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.hierarchyFilters,
      );
      if (response.data != null && response.data['success'] == true) {
        final Map<String, dynamic> data =
            response.data['data'] is Map<String, dynamic>
            ? response.data['data'] as Map<String, dynamic>
            : {};

        final rawDistricts = data['districts'];
        final List<dynamic> districtsList = (rawDistricts is List<dynamic>)
            ? rawDistricts
            : [];
        _hierarchyDistricts = districtsList
            .whereType<Map>()
            .map((d) => Map<String, dynamic>.from(d))
            .toList();

        final rawTeams = data['teams'];
        final List<dynamic> teamsList = (rawTeams is List<dynamic>)
            ? rawTeams
            : [];
        _hierarchyTeams = teamsList
            .whereType<Map>()
            .map((t) => Map<String, dynamic>.from(t))
            .toList();

        final rawEmployees = data['employees'];
        final Map<String, dynamic> employeesMap = (rawEmployees is Map)
            ? Map<String, dynamic>.from(rawEmployees)
            : {};

        if (employeesMap['BDE'] is List) {
          final List<dynamic> bdeList = employeesMap['BDE'] as List;
          _hierarchyBdes = bdeList
              .whereType<Map>()
              .map((b) => Map<String, dynamic>.from(b))
              .toList();
        } else {
          _hierarchyBdes = [];
        }

        if (employeesMap['BDM'] is List) {
          final List<dynamic> bdmList = employeesMap['BDM'] as List;
          _hierarchyBdms = bdmList
              .whereType<Map>()
              .map((b) => Map<String, dynamic>.from(b))
              .toList();
        } else {
          _hierarchyBdms = [];
        }

        if (employeesMap['ASM'] is List) {
          final List<dynamic> asmList = employeesMap['ASM'] as List;
          _hierarchyAsms = asmList
              .whereType<Map>()
              .map((a) => Map<String, dynamic>.from(a))
              .toList();
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
    final zoneName = currentUser.zone ?? '';
    final teamName = currentUser.team ?? '';

    final actualLeadId = lead.actualLeadId;
    final leadId = actualLeadId.isNotEmpty ? actualLeadId : 'LD-${lead.id}';

    // Map API follow-ups to FollowUpItem
    final apiFollowUps =
        lead.followups?.map((f) {
          String formattedDate = f.followupDate;
          try {
            final parsed = DateTime.parse(f.followupDate);
            formattedDate = DateFormat('dd MMM yyyy').format(parsed);
          } catch (_) {
            // Fallback to original
          }
          return FollowUpItem(
            dateTime: formattedDate,
            remark: f.notes ?? '',
            attachment: f.attachment,
          );
        }).toList() ??
        [];

    // API already scopes results via Bearer token; use session values as fallback.
    final effectiveStudentId =
        (lead.studentId != null && lead.studentId!.trim().isNotEmpty)
        ? lead.studentId!.trim()
        : 'STU-${actualLeadId.isNotEmpty ? actualLeadId.replaceAll("LD-", "").replaceAll("LD_", "") : lead.id}';

    return TaskModel(
      id: leadId,
      leadId: actualLeadId.isNotEmpty ? actualLeadId : leadId,
      studentId: effectiveStudentId,
      studentName: lead.name,
      location: lead.address,
      course: lead.interestedCourse?.isNotEmpty == true
          ? lead.interestedCourse!
          : (lead.course?.name ?? ''),
      description: lead.notes,
      assignedDate: lead.createdAt,
      assignedBdeEmail: currentUser.email,
      team: teamName,
      district:
          lead.district?.name ??
          (lead.districtName ?? currentUser.district ?? ''),
      zone: zoneName,
      creatorEmail: currentUser.email,
      status: lead.isCompleted ? 'Completed' : 'Pending',
      leadStatus: lead.admissionStatus ?? lead.statusLabel,
      followUps: apiFollowUps,
      phone: lead.phone,
      email: lead.email,
      whatsappNumber: lead.whatsappNumber,
      place: lead.place,
      age: lead.age,
      qualification: lead.qualification,
      collegeName: lead.collegeName,
      currentYear: lead.currentYear,
      interestedTopic: lead.interestedTopic,
      interestedCourse: lead.interestedCourse,
      leadSource: lead.leadSource,
      admissionStatus: lead.admissionStatus,
      employee: lead.employee,
    );
  }

  /// // Fetches pending leads (status=1) and populates [tasks].
  Future<void> fetchLeads({
    int status = 1,
    int? employeeId,
    int? teamId,
    int? districtId,
    bool isRefresh = false,
  }) async {
    if (_isLoadingLeads) return;
    if (!isRefresh &&
        _tasks.isNotEmpty &&
        employeeId == null &&
        teamId == null &&
        districtId == null)
      return;
    _isLoadingLeads = true;
    notifyListeners();
    try {
      final Map<String, dynamic> queryParams = {'status': status};
      final activeEmployeeId =
          employeeId ?? _selectedBdeId ?? _selectedBdmId ?? _selectedAsmId;
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
      if (response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        dynamic leadsPayload = rawData;
        if (rawData is Map && rawData.containsKey('leads')) {
          leadsPayload = rawData['leads'];
        }

        final leadsPage = LeadsPage.fromJson(leadsPayload);
        final allMapped = leadsPage.data.map(_mapLead).toList();
        _tasks = allMapped.where((t) => t.status == 'Pending').toList();
        debugPrint(
          '[fetchLeads] status=1, employee_id=$activeEmployeeId, team_id=$activeTeamId, district_id=$activeDistrictId → ${_tasks.length} pending leads loaded',
        );
      }
    } catch (e, st) {
      debugPrint('[fetchLeads] ERROR: $e\n$st');
    } finally {
      _isLoadingLeads = false;
      notifyListeners();
    }
  }

  /// Fetches completed leads (status=4 and status=5) and populates [completedTasks].
  Future<void> fetchCompletedLeads({
    int? employeeId,
    int? teamId,
    int? districtId,
    bool isRefresh = false,
  }) async {
    if (_isLoadingCompletedLeads) return;
    if (!isRefresh &&
        _completedTasks.isNotEmpty &&
        employeeId == null &&
        teamId == null &&
        districtId == null)
      return;
    _isLoadingCompletedLeads = true;
    notifyListeners();
    try {
      final Map<String, dynamic> queryParams4 = {'status': 4};
      final Map<String, dynamic> queryParams5 = {'status': 5};
      final activeEmployeeId =
          employeeId ?? _selectedBdeId ?? _selectedBdmId ?? _selectedAsmId;
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
        if (response.data != null) {
          dynamic rawData = response.data;
          if (rawData is Map && rawData.containsKey('data')) {
            rawData = rawData['data'];
          }
          dynamic leadsPayload = rawData;
          if (rawData is Map && rawData.containsKey('leads')) {
            leadsPayload = rawData['leads'];
          }

          final leadsPage = LeadsPage.fromJson(leadsPayload);
          combined.addAll(leadsPage.data.map(_mapLead));
        }
      }
      _completedTasks = combined.where((t) => t.status == 'Completed').toList();
      debugPrint(
        '[fetchCompletedLeads] status=4,5, employee_id=$activeEmployeeId, team_id=$activeTeamId, district_id=$activeDistrictId → ${_completedTasks.length} completed leads loaded',
      );
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
    String? whatsappNumber,
    required String email,
    required String address,
    String? place,
    String? districtName,
    int? districtId,
    int? age,
    String? qualification,
    String? collegeName,
    String? currentYear,
    String? interestedTopic,
    String? interestedCourseName,
    int? courseId,
    String? leadSourceName,
    int? source,
    String? admissionStatus,
    int? status,
    String? employeeName,
    int? assignedEmployeeId,
    required String notes,
  }) async {
    _isSubmittingTask = true;
    notifyListeners();
    try {
      // Map course_id back to name if not provided
      final courseName =
          (interestedCourseName != null && interestedCourseName.isNotEmpty)
          ? interestedCourseName
          : (courseId != null
                ? (_courses
                          .firstWhere(
                            (c) => c['id'] == courseId,
                            orElse: () => {
                              'name': 'Full-Stack Web Development',
                            },
                          )['name']
                          ?.toString() ??
                      'Full-Stack Web Development')
                : 'Full-Stack Web Development');

      // Map district_id back to name if not provided
      final district = (districtName != null && districtName.isNotEmpty)
          ? districtName
          : (districtId != null
                ? (_districts
                          .firstWhere(
                            (d) => d['id'] == districtId,
                            orElse: () => {'name': 'Ernakulam'},
                          )['name']
                          ?.toString() ??
                      'Ernakulam')
                : 'Ernakulam');

      // Resolve lead source string
      final String resolvedLeadSource =
          (leadSourceName != null && leadSourceName.isNotEmpty)
          ? leadSourceName
          : (source == 1
                ? 'Cold Call'
                : source == 2
                ? 'Referral'
                : source == 3
                ? 'Website'
                : source == 4
                ? 'Advertisement'
                : source == 5
                ? 'Campus Drive / College Seminar'
                : 'Campus Drive / College Seminar');

      // Resolve admission status
      final String resolvedAdmissionStatus =
          (admissionStatus != null && admissionStatus.isNotEmpty)
          ? admissionStatus
          : (status == 1
                ? 'New'
                : status == 4
                ? 'Admitted'
                : 'Closed');

      // Resolve employee name
      final String resolvedEmployee =
          (employeeName != null && employeeName.isNotEmpty)
          ? employeeName
          : (AuthProvider.instance.session.name.isNotEmpty
                ? AuthProvider.instance.session.name
                : (UserProfileProvider.instance.state.data?.name ?? ''));

      final payload = {
        'name': name,
        'phone': phone,
        'whatsapp_number': (whatsappNumber != null && whatsappNumber.isNotEmpty)
            ? whatsappNumber
            : phone,
        'email': email,
        'address': address,
        'place': (place != null && place.isNotEmpty) ? place : address,
        'district': district,
        if (districtId != null && districtId > 0) 'district_id': districtId,
        'age': age ?? 0,
        'qualification': qualification ?? '',
        'college_name': collegeName ?? '',
        'current_year': currentYear ?? '',
        'interested_topic': interestedTopic ?? '',
        'interested_course': courseName,
        if (courseId != null && courseId > 0) 'course_id': courseId,
        'lead_source': resolvedLeadSource,
        if (source != null && source > 0) 'source': source,
        'admission_status': resolvedAdmissionStatus,
        'status': status ?? 1,
        if (resolvedEmployee.isNotEmpty) 'employee': resolvedEmployee,
        if (assignedEmployeeId != null && assignedEmployeeId > 0)
          'assigned_employee_id': assignedEmployeeId,
        'notes': notes,
      };

      final response = await ApiClient.instance.post(
        ApiEndpoints.createLead,
        data: payload,
      );

      if (response.data != null &&
          (response.data['success'] == true ||
              response.statusCode == 200 ||
              response.statusCode == 201)) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        Map<String, dynamic> leadData = {};
        if (rawData is Map &&
            rawData.containsKey('lead') &&
            rawData['lead'] is Map) {
          leadData = Map<String, dynamic>.from(rawData['lead'] as Map);
        } else if (rawData is Map) {
          leadData = Map<String, dynamic>.from(rawData);
        }

        final rawLeadId = (leadData['lead_id'] ?? leadData['leadId'])
            ?.toString()
            .trim();
        final actualId = (rawLeadId != null && rawLeadId.isNotEmpty)
            ? (rawLeadId.startsWith('LD_')
                  ? 'LD-${rawLeadId.substring(3)}'
                  : rawLeadId)
            : 'LD-${leadData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';

        // Add to local list to reflect in UI immediately
        final newLead = TaskModel(
          id: actualId,
          leadId: actualId,
          studentId:
              leadData['student_id']?.toString() ??
              'STU-${actualId.replaceAll("LD-", "").replaceAll("LD_", "")}',
          studentName: name,
          location: address,
          course: courseName,
          description: notes,
          assignedDate: DateTime.now(),
          assignedBdeEmail: AuthProvider.instance.session.email,
          team: AuthProvider.instance.session.team ?? 'Ernakulam Team A',
          district: district,
          zone: AuthProvider.instance.session.zone ?? 'Central Zone',
          creatorEmail: AuthProvider.instance.session.email,
          status: 'Pending',
          leadStatus: resolvedAdmissionStatus,
          phone: phone,
          email: email,
          whatsappNumber: (whatsappNumber != null && whatsappNumber.isNotEmpty)
              ? whatsappNumber
              : phone,
          place: (place != null && place.isNotEmpty) ? place : address,
          age: age,
          qualification: qualification,
          collegeName: collegeName,
          currentYear: currentYear,
          interestedTopic: interestedTopic,
          interestedCourse: courseName,
          leadSource: resolvedLeadSource,
          admissionStatus: resolvedAdmissionStatus,
          employee: resolvedEmployee,
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

  /// Upload or register an Institution/School contact
  /// POST /institutes
  /// Body: {
  ///   "institute_name": "...",
  ///   "person_name": "...",
  ///   "position": "...",
  ///   "phone": "..."
  /// }
  Future<Map<String, dynamic>> createInstitute({
    required String instituteName,
    required String personName,
    required String position,
    required String phone,
  }) async {
    try {
      final payload = {
        'institute_name': instituteName.trim(),
        'person_name': personName.trim(),
        'position': position.trim(),
        'phone': phone.trim(),
      };

      final response = await ApiClient.instance.post(
        ApiEndpoints.institutes,
        data: payload,
      );

      if (response.data != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final data = response.data;
        final String message = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Institution details uploaded successfully!';
        return {'success': true, 'message': message, 'data': data};
      }
      return {
        'success': false,
        'message': response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Failed to upload institution details.',
      };
    } catch (e) {
      debugPrint('[createInstitute] Error: $e');
      return {
        'success': false,
        'message': 'Failed to upload institution details: $e',
      };
    }
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
    final formattedFrom = DateFormat(
      "yyyy-MM-dd'T'HH:mm:ss",
    ).format(startDateTime);
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
    _walletApprovalRequests = [];
    _walletApprovalSummary = null;
    notifyListeners();
  }
}
