import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../providers/attendance_provider.dart';
import '../utils/helpers.dart';
import 'dashboard/dashboard_screen.dart';

class CheckoutSuccessScreen extends StatelessWidget {
  static const String path = '/checkout-success';

  const CheckoutSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = AttendanceProvider.instance;
    final attendance = provider.currentAttendance;
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Success Animated Icon / Badge
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent.withOpacity(0.12),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Headings
                const Text(
                  'CHECK-OUT SUCCESSFUL',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your daily attendance check-out is synced.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Shift Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.schedule_rounded, color: AppColors.accentTeal, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'SHIFT LOG SUMMARY',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFFE2E8F0), height: 28),
                      _buildDetailRow('Employee Name', attendance.employeeName.isNotEmpty ? attendance.employeeName : 'SALES OFFICER'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Date Logged', dateFormat.format(attendance.checkInTime)),
                      const SizedBox(height: 12),
                      _buildDetailRow('Check-In Time', timeFormat.format(attendance.checkInTime)),
                      const SizedBox(height: 12),
                      _buildDetailRow('Check-Out Time', attendance.checkOutTime != null ? timeFormat.format(attendance.checkOutTime!) : '--:--'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Hours', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              UiHelpers.formatWorkingHours(
                                attendance.workingHours,
                                checkIn: attendance.checkInTime,
                                checkOut: attendance.checkOutTime,
                              ),
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Sync Metadata Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.dns_rounded, color: AppColors.accentTeal, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'CLOUD SYNC METADATA',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 10),
                                SizedBox(width: 4),
                                Text('SYNCHRONIZED', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFFE2E8F0), height: 28),
                      _buildDetailRow('Active Employee ID', attendance.employeeId.isNotEmpty ? attendance.employeeId : 'EMP_4096'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Sync Approval Status', (attendance.statusText ?? 'Approved').toUpperCase()),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Verification: Shift log completed and successfully archived in remote company attendance register.',
                          style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 10, height: 1.4),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Back to Dashboard Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: AppColors.accentGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentTeal.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          DashboardScreen.path,
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'Back to Dashboard',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            val,
            textAlign: TextAlign.end,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
