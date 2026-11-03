class ApiEndpoints {
  ApiEndpoints._();

  /// Change the base URL to target staging/production/local servers
  static const String baseUrl =
      //'https://kide-crm-backend-production-yszlaa.laravel.cloud/api';
      "https://lms-application-pi.vercel.app/api";

  /// Authentication
  static const String login = '/login';
  static const String logout = '/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String changePassword = '/set-password';

  /// Features (Placeholder endpoint maps, can be adapted/configured)
  static const String userProfile = '/profile';
  static const String attendance = '/attendance';
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';
  static const String attendanceStatus = '/attendance/status';
  static const String attendanceHistory = '/attendance/history';
  static const String operations = '/operations';
  static const String home = '/home';
  static const String walletBalance = '/wallet/balance';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String leaves = '/leaves';
  static const String applyLeave = '/leaves/apply';
  static const String designations = '/designations';
  static const String register = '/register';
  static const String courses = '/courses';
  static const String createLead = '/leads/create';
  static const String sources = '/sources';
  static const String zones = '/zones';
  static const String districts = '/districts';
  static const String leads = '/leads';
  static const String importLeads = '/leads/import';
  static const String hierarchyFilters = '/hierarchy/filters';
  static const String performanceTasks = '/tasks';
  static const String institutes = '/institutes';
  static const String smAsms = '/sm/asms';
  static const String smCreateAsm = '/sm/create-asm';
  static const String officeCreateTelecaller = '/office/create-telecaller';
  static const String officeTelecallers = '/office/telecallers';
  static const String salaryWorkflow = '/salary/workflow';
  static const String walletWorkflow = '/wallet/workflow';
  static const String salaryRequests = '/salary/requests';
  static const String walletRequests = '/wallet/requests';
  static const String asmCreateBde = '/asm/create-bde';
  static const String asmBdes = '/asm/bdes';
  static String asmBdeById(String id) => '/asm/bdes/$id';

  /// Returns the close endpoint for a specific lead: POST /leads/{id}/close
  static String closeLead(int id) => '/leads/$id/close';

  /// Returns the follow-up endpoint for a specific lead: POST /leads/{id}/followup
  static String followUpLead(int id) => '/leads/$id/followup';
}
