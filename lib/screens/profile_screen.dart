import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/user_profile_model.dart';
import '../providers/auth_provider.dart';
import '../providers/operations_provider.dart';
import '../providers/user_profile_provider.dart';
import 'login_screen.dart';
import 'training_videos_screen.dart';
// import 'leave_screen.dart';
import 'attendance_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const String path = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logging out...',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Row(
          children: [
            CircularProgressIndicator(color: AppColors.accentTeal),
            SizedBox(width: 20),
            Text(
              'Ending active session...',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1500));
    await AuthProvider.instance.logout();

    if (mounted) {
      Navigator.pop(context); // Dismiss dialog
      Navigator.pushReplacementNamed(context, LoginScreen.path);
    }
  }

  Future<void> _handleDeleteAccount() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text(
                'Delete Account?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'This action is permanent. Deleting your account will clear all biometric databases, cached leads data, and local session files.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                navigator.pop(); // Close confirm dialog

                // Show deleting progress
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    content: const Row(
                      children: [
                        CircularProgressIndicator(color: Colors.red),
                        SizedBox(width: 20),
                        Text(
                          'Permanently deleting account...',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                final res = await AuthProvider.instance.deleteAccount();

                if (mounted) {
                  navigator.pop(); // Close deleting dialog
                  if (res['success'] == true) {
                    navigator.pushNamedAndRemoveUntil(
                      LoginScreen.path,
                      (route) => false,
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text(
                          res['message']?.toString() ??
                              'Account has been permanently deleted.',
                        ),
                      ),
                    );
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text(
                          res['message']?.toString() ??
                              'Failed to delete account. Please try again.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Delete Permanently',
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

  Widget _buildSettingsSection() {
    return Container(
      width: double.infinity,
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
              child: Container(color: AppColors.accentCyan),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RESOURCES & ACTIONS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 28),

                  // Action Row: Attendance History
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AttendanceHistoryScreen.path,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.history_rounded,
                                color: AppColors.accentTeal,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Attendance Sign-in History',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),

                  // Action Row: Training Videos
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrainingVideosScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.folder_open_rounded,
                                color: Colors.amber,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Training Videos',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),

                  // Action Row: Help Center
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Support console is currently running in offline backup mode.',
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.help_outline_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Help & Support Center',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),

                  // Action Row: Delete Account
                  InkWell(
                    onTap: _handleDeleteAccount,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.delete_forever_rounded,
                                color: Colors.red.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Delete Account Permanently',
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.red.shade300,
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
      ),
    );
  }

  /*
  Widget _buildLeaveSection(OperationsProvider provider, UserProfileModel profile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, LeaveScreen.path),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(color: Colors.blue),
              ),
              // Padding(
              //   padding: const EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 18),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //         children: [
              //           const Text(
              //             'LEAVE MANAGEMENT',
              //             style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              //           ),
              //           const Icon(
              //             Icons.chevron_right_rounded,
              //             color: AppColors.textSecondary,
              //             size: 20,
              //           ),
              //         ],
              //       ),
              //       const SizedBox(height: 6),
              //       const Text(
              //         'Apply for leaves and view your leave application history.',
              //         style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    final auth = AuthProvider.instance;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MY PROFILE & TRAINING',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: UserProfileProvider.instance,
        builder: (context, _) {
          final profileState = UserProfileProvider.instance.state;

          if (profileState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
              ),
            );
          }

          if (profileState.isError && profileState.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profileState.message ?? 'Failed to load profile.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => UserProfileProvider.instance
                          .fetchUserProfile(isRefresh: true),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentTeal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile =
              profileState.data ??
              UserProfileModel(
                name: auth.session.name.isNotEmpty
                    ? auth.session.name
                    : 'Guest User',
                designation: _getRoleDisplay(auth.session.role),
                email: auth.session.email.isNotEmpty
                    ? auth.session.email
                    : 'sales@keralainstitute.in',
                contactNumber: '+91 94460 12345',
                employeeId: _getEmployeeId(auth.session.role),
                leaveBalances: LeaveBalances(casual: 5, medical: 5, earned: 0),
              );

          return Container(
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
                  // final provider = OperationsProvider.instance;

                  return RefreshIndicator(
                    color: AppColors.accentTeal,
                    onRefresh: () async {
                      await UserProfileProvider.instance.fetchUserProfile(
                        isRefresh: true,
                      );
                      await OperationsProvider.instance.loadOperationsData(
                        isRefresh: true,
                      );
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Premium Profile Intro Header Card (Gradient Design)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.accentGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentTeal.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -20,
                                    bottom: -20,
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 130,
                                      color: Colors.white.withOpacity(0.06),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 26,
                                    ),
                                    child: Column(
                                      children: [
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.25,
                                                ),
                                                width: 3,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              radius: 36,
                                              backgroundColor: Colors.white,
                                              child: const Icon(
                                                Icons.person_rounded,
                                                color: AppColors.accentTeal,
                                                size: 40,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          profile.name,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: Text(
                                            profile.designation.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                        if (auth.session.role != 'MD') ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            _getScopeDisplay(auth.session),
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.85,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Detail Section A: Personal Details
                          _buildInfoSection('Personal details', [
                            _buildInfoRow('Email Address', profile.email),
                            _buildInfoRow(
                              'Contact Number',
                              profile.contactNumber,
                            ),
                            _buildInfoRow('Employee ID', profile.employeeId),
                            _buildInfoRow('Designation', profile.designation),
                          ]),
                          const SizedBox(height: 10),

                          // Leave Management Section
                          // _buildLeaveSection(provider, profile),
                          // const SizedBox(height: 20),

                          // Detail Section C: Settings & Account Actions
                          _buildSettingsSection(),
                          if (auth.session.role == 'MD') ...[
                            const SizedBox(height: 20),
                            _buildMdUserControlSection(),
                          ],
                          const SizedBox(height: 28),

                          // Log out Button
                          ListenableBuilder(
                            listenable: AuthProvider.instance,
                            builder: (context, _) {
                              final auth = AuthProvider.instance;
                              final isLoggingOut = auth.isLoggingOut;
                              return SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    foregroundColor: Colors.red,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.red.shade100,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Log Out Session',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: isLoggingOut
                                      ? null
                                      : _handleLogout,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(
    String heading,
    List<Widget> children, {
    Color leftBorderColor = AppColors.accentTeal,
  }) {
    return Container(
      width: double.infinity,
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
              child: Container(color: leftBorderColor),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 28),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplay(String role) {
    switch (role) {
      case 'MD':
        return 'MANAGING DIRECTOR / SUPER ADMIN';
      case 'ZM':
        return 'ZONAL SALES MANAGER';
      case 'ASM':
        return 'AREA SALES MANAGER (DISTRICT HEAD)';
      case 'BDM':
        return 'BUSINESS DEVELOPMENT MANAGER (TEAM LEADER)';
      case 'BDE':
      default:
        return 'BUSINESS DEVELOPMENT EXECUTIVE';
    }
  }

  String _getScopeDisplay(dynamic session) {
    final List<String> parts = [];
    if (session.zone != null && session.zone!.isNotEmpty) {
      parts.add(session.zone!);
    }
    if (session.district != null && session.district!.isNotEmpty) {
      parts.add(session.district!);
    }
    if (session.team != null && session.team!.isNotEmpty) {
      parts.add(session.team!);
    }
    return parts.join(' • ');
  }

  String _getEmployeeId(String role) {
    switch (role) {
      case 'MD':
        return 'KIS-2026-MD01';
      case 'ZM':
        return 'KIS-2026-ZM04';
      case 'ASM':
        return 'KIS-2026-ASM12';
      case 'BDM':
        return 'KIS-2026-TL34';
      case 'BDE':
      default:
        return 'KIS-2026-BDE89';
    }
  }

  Widget _buildMdUserControlSection() {
    final List<Map<String, String>> users = [
      {'name': 'Dr. K. Kurian', 'role': 'MD', 'scope': 'State-wide'},
      {
        'name': 'Alex Varghese',
        'role': 'SM',
        'scope': 'Kerala State Operations',
      },
      {'name': 'Thomas Mathew', 'role': 'ZM', 'scope': 'South Zone'},
      {'name': 'Sandhya Nair', 'role': 'ZM', 'scope': 'Central Zone'},
      {'name': 'Raghesh Pillai', 'role': 'ZM', 'scope': 'North Zone'},
      {'name': 'Anjali Krishna', 'role': 'ASM', 'scope': 'Ernakulam District'},
      {'name': 'Deepak S.', 'role': 'BDM', 'scope': 'Ernakulam Team A'},
      {
        'name': 'Rahul R. V.',
        'role': 'BDE',
        'scope': 'Ernakulam Team A, BDE 1',
      },
    ];

    return Container(
      width: double.infinity,
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
              child: Container(color: Colors.orange),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'USER CONTROLS & ADMINISTRATION',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 28),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final u = users[index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u['name']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                u['scope']!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              u['role']!,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
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
    );
  }
}
