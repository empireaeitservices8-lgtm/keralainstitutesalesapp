import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/eod_model.dart';
import '../providers/operations_provider.dart';
import '../utils/helpers.dart';

class EodScreen extends StatefulWidget {
  static const String path = '/eod';
  const EodScreen({super.key});

  @override
  State<EodScreen> createState() => _EodScreenState();
}

class _EodScreenState extends State<EodScreen> {
  final _remarksController = TextEditingController();
  final _summaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    OperationsProvider.instance.loadOperationsData();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitEod() async {
    if (_remarksController.text.trim().isEmpty || _summaryController.text.trim().isEmpty) {
      UiHelpers.showSnackBar(context, 'Please fill in both remarks and daily summary.', Colors.orangeAccent);
      return;
    }

    await OperationsProvider.instance.submitEodReport(
      _remarksController.text.trim(),
      _summaryController.text.trim(),
    );

    if (mounted) {
      UiHelpers.showSnackBar(context, 'EOD Report Submitted Successfully!', Colors.greenAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text(
          'END OF DAY (EOD) REPORT',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
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
              final eod = provider.todayEod;

              // Pre-calculated stats from provider visit logs
              final totalVisits = provider.completedVisitsCount;
              final pending = provider.pendingVisitsCount;
              final leads = totalVisits;
              final followups = provider.beatPlans.where((v) => v.isVisited && v.followUpDate != null && v.followUpDate!.isNotEmpty).length;

              if (eod.isSubmitted) {
                return _buildSubmittedView(provider, eod);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading Info
                    const Text(
                      'Daily Summary Prefill',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Stats are automatically aggregated from today\'s operations.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Grid stats
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.6,
                      children: [
                        _buildStatBlock('Visits Completed', '$totalVisits Done', Colors.green.shade700),
                        _buildStatBlock('Pending Schedule', '$pending Left', Colors.orange.shade800),
                        _buildStatBlock('Student Leads Engaged', '$leads Created', AppColors.accentTeal),
                        _buildStatBlock('Follow-ups Locked', '$followups Scheduled', Colors.teal.shade600),
                      ],
                    ),

                    const Divider(color: Color(0xFFE2E8F0), height: 40),

                    // Report Form Input
                    const Text(
                      'Daily Work Summary Remarks',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _remarksController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Enter general counseling and admission field remarks...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentTeal),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Daily Summary Logs',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _summaryController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe details of student counseling, college drives, and document collection...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentTeal),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: AppColors.accentGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: provider.isSubmittingEod ? null : _handleSubmitEod,
                        child: provider.isSubmittingEod
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text(
                                'Submit EOD Report',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatBlock(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedView(OperationsProvider provider, EodModel report) {
    final timeStr = DateFormat('hh:mm a').format(report.submissionTime);
    final dateStr = DateFormat('dd MMM yyyy').format(report.submissionTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.12),
                  ),
                  child: const Icon(Icons.cloud_done, color: Colors.green, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  'End of Day Sync Complete',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'EOD Report was submitted on $dateStr at $timeStr.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const Divider(color: Color(0xFFE2E8F0), height: 32),
                
                _buildReportRow('Customer Visits Logged', '${report.totalVisits} Outlets'),
                const SizedBox(height: 8),
                _buildReportRow('Orders Created', '${report.leadsCreated} Bookings'),
                const SizedBox(height: 8),
                _buildReportRow('Follow-ups Scheduled', '${report.followUpsScheduled} Tasks'),
                const SizedBox(height: 8),
                _buildReportRow('Pending Visits Left', '${report.pendingVisits} Outlets'),
                
                const Divider(color: Color(0xFFE2E8F0), height: 32),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('General Remarks:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(report.remarks, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 16),
                      const Text('Daily Summary Log:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(report.dailySummary, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 40),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent.withOpacity(0.8)),
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Reset EOD Progress (For Demo)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: () async {
              await provider.resetOperations();
              if (mounted) {
                UiHelpers.showSnackBar(context, 'EOD report state reset!', Colors.redAccent);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
