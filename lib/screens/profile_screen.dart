import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../models/training_video_model.dart';
import '../providers/auth_provider.dart';
import '../providers/operations_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const String path = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;
  bool _notificationsEnabled = true;
  bool _autoSync = true;

  @override
  void initState() {
    super.initState();
    OperationsProvider.instance.loadOperationsData();
  }

  // Launch YouTube video tutorial link
  Future<void> _launchYouTubeVideo(TrainingVideoModel video) async {
    final Uri url = Uri.parse(video.videoUrl);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Could not open training link: ${video.videoUrl}'),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text(
                'Delete Account?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'This action is permanent. Deleting your account will clear all biometric databases, cached leads data, and local session files.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    content: const Row(
                      children: [
                        CircularProgressIndicator(color: Colors.red),
                        SizedBox(width: 20),
                        Text('Purging user account databases...', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      ],
                    ),
                  ),
                );

                await Future.delayed(const Duration(milliseconds: 1500));
                await AuthProvider.instance.logout();
                
                if (mounted) {
                  navigator.pop(); // Close deleting dialog
                  navigator.pushReplacementNamed(LoginScreen.path);
                  messenger.showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.redAccent,
                      content: Text('Account has been deleted successfully.'),
                    ),
                  );
                }
              },
              child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              child: Container(
                color: AppColors.accentCyan,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SETTINGS & PREFERENCES',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 28),
                  
                  // Switch Row: Notifications
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary, size: 20),
                          SizedBox(width: 12),
                          Text('Push Notifications', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Switch(
                        value: _notificationsEnabled,
                        activeColor: AppColors.accentTeal,
                        onChanged: (val) {
                          setState(() {
                            _notificationsEnabled = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  
                  // Switch Row: Auto Sync
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sync_rounded, color: AppColors.textSecondary, size: 20),
                          SizedBox(width: 12),
                          Text('Background Sync', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Switch(
                        value: _autoSync,
                        activeColor: AppColors.accentTeal,
                        onChanged: (val) {
                          setState(() {
                            _autoSync = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),

                  // Action Row: Change Password
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset link sent to registered email address.')),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lock_open_rounded, color: AppColors.textSecondary, size: 20),
                              SizedBox(width: 12),
                              Text('Change Account Password', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),

                  // Action Row: Help Center
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support console is currently running in offline backup mode.')),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.help_outline_rounded, color: AppColors.textSecondary, size: 20),
                              SizedBox(width: 12),
                              Text('Help & Support Center', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
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
                              Icon(Icons.delete_forever_rounded, color: Colors.red.shade400, size: 20),
                              const SizedBox(width: 12),
                              Text('Delete Account Permanently', style: TextStyle(color: Colors.red.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.red.shade300),
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

  // Show dialog to apply for leave
  void _showApplyLeaveDialog(OperationsProvider provider) {
    String leaveType = 'Casual Leave';
    DateTime fromDate = DateTime.now().add(const Duration(days: 1));
    DateTime toDate = DateTime.now().add(const Duration(days: 1));
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.add_moderator_rounded, color: AppColors.accentTeal),
                  SizedBox(width: 8),
                  Text('Apply for Leave', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leave Type Dropdown
                    const Text('LEAVE TYPE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: leaveType,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                leaveType = val;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'Casual Leave', child: Text('Casual Leave', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'Medical Leave', child: Text('Medical Leave', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'Earned Leave', child: Text('Earned Leave', style: TextStyle(fontSize: 13))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date Selectors
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('FROM DATE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final pick = await showDatePicker(
                                    context: context,
                                    initialDate: fromDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 90)),
                                  );
                                  if (pick != null) {
                                    setDialogState(() {
                                      fromDate = pick;
                                      if (toDate.isBefore(fromDate)) {
                                        toDate = fromDate;
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat('dd MMM').format(fromDate), style: const TextStyle(fontSize: 12)),
                                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.accentTeal),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TO DATE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final pick = await showDatePicker(
                                    context: context,
                                    initialDate: toDate,
                                    firstDate: fromDate,
                                    lastDate: DateTime.now().add(const Duration(days: 90)),
                                  );
                                  if (pick != null) {
                                    setDialogState(() {
                                      toDate = pick;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat('dd MMM').format(toDate), style: const TextStyle(fontSize: 12)),
                                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.accentTeal),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Reason Text Field
                    const Text('REASON FOR LEAVE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g., Personal errand, doctor visit',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(backgroundColor: Colors.orange, content: Text('Please state the reason for applying leave.')),
                      );
                      return;
                    }

                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    final success = await provider.applyLeave(leaveType, fromDate, toDate, reasonController.text);
                    
                    if (mounted) {
                      navigator.pop(); // Close apply dialog
                      if (success) {
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            content: Text('Applied for $leaveType successfully!'),
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.redAccent,
                            content: Text('Failed: Insufficient Leave Balance.'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Submit Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLeaveSection(OperationsProvider provider) {
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
              child: Container(
                color: Colors.blue,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LEAVE BALANCES & HR MODULE',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 28),
                  
                  // Balances grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLeaveBalanceItem('Casual', provider.leaveBalanceCasual, Colors.blue),
                      _buildLeaveBalanceItem('Medical', provider.leaveBalanceMedical, Colors.orange),
                      _buildLeaveBalanceItem('Earned', provider.leaveBalanceEarned, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentTeal.withOpacity(0.08),
                        foregroundColor: AppColors.accentTeal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: AppColors.accentTeal.withOpacity(0.2)),
                        ),
                      ),
                      icon: const Icon(Icons.add_moderator_rounded, size: 16),
                      label: const Text('Apply for Leave', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _showApplyLeaveDialog(provider),
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

  Widget _buildLeaveBalanceItem(String type, int days, Color accentColor) {
    return Column(
      children: [
        Text(
          type.toUpperCase(),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withOpacity(0.12)),
          ),
          child: Text(
            '$days',
            style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Days Left',
          style: TextStyle(color: AppColors.textMuted, fontSize: 8),
        ),
      ],
    );
  }

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
              final videos = provider.trainingVideos;

              return SingleChildScrollView(
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
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                              child: Column(
                                children: [
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withOpacity(0.25), width: 3),
                                      ),
                                      child: CircleAvatar(
                                        radius: 36,
                                        backgroundColor: Colors.white,
                                        child: const Icon(Icons.person_rounded, color: AppColors.accentTeal, size: 40),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    auth.session.name.isNotEmpty 
                                        ? auth.session.name 
                                        : 'Guest User',
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
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      _getRoleDisplay(auth.session.role),
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
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ]
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
                      _buildInfoRow('Email Address', auth.session.email.isEmpty ? 'sales@keralainstitute.in' : auth.session.email),
                      _buildInfoRow('Contact Number', '+91 94460 12345'),
                      _buildInfoRow('Employee ID', _getEmployeeId(auth.session.role)),
                      _buildInfoRow('Designation', _getRoleDisplay(auth.session.role)),
                    ]),
                    const SizedBox(height: 20),

                    // Detail Section B: Course Training Videos
                    _buildTrainingSection(videos),
                    const SizedBox(height: 20),

                    // Leave Management Section
                    _buildLeaveSection(provider),
                    const SizedBox(height: 20),

                    // Detail Section C: Settings & Account Actions
                    _buildSettingsSection(),
                    if (auth.session.role == 'MD') ...[
                      const SizedBox(height: 20),
                      _buildMdUserControlSection(),
                    ],
                    const SizedBox(height: 28),

                    // Log out Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.red.shade100),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Log Out Session', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _isLoggingOut ? null : _handleLogout,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingSection(List<TrainingVideoModel> videos) {
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
              child: Container(
                color: Colors.amber,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COURSE TRAINING & SALES DIRECTIVES',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 28),
                  
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: videos.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return GestureDetector(
                        onTap: () => _launchYouTubeVideo(video),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Folder Icon Badge
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.folder_open_rounded,
                                  color: Colors.amber.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          video.id,
                                          style: const TextStyle(color: AppColors.accentTeal, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (video.difficulty == 'Beginner' ? Colors.blue : Colors.orange).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            video.difficulty.toUpperCase(),
                                            style: TextStyle(
                                              color: video.difficulty == 'Beginner' ? Colors.blue.shade700 : Colors.orange.shade800,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      video.title,
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      video.description,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.schedule, size: 12, color: Colors.grey.shade400),
                                        const SizedBox(width: 4),
                                        Text(
                                          video.duration,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildInfoSection(String heading, List<Widget> children, {Color leftBorderColor = AppColors.accentTeal}) {
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
              child: Container(
                color: leftBorderColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading.toUpperCase(),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
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
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
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
      {'name': 'Thomas Mathew', 'role': 'ZM', 'scope': 'South Zone'},
      {'name': 'Sandhya Nair', 'role': 'ZM', 'scope': 'Central Zone'},
      {'name': 'Raghesh Pillai', 'role': 'ZM', 'scope': 'North Zone'},
      {'name': 'Anjali Krishna', 'role': 'ASM', 'scope': 'Ernakulam District'},
      {'name': 'Deepak S.', 'role': 'BDM', 'scope': 'Ernakulam Team A'},
      {'name': 'Rahul R. V.', 'role': 'BDE', 'scope': 'Ernakulam Team A, BDE 1'},
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
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 28),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final u = users[index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u['name']!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 12)),
                              Text(u['scope']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              u['role']!,
                              style: const TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold),
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
