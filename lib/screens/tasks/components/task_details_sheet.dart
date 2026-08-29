import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/colors.dart';
import '../../../models/task_model.dart';
import '../../../utils/helpers.dart';

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

Widget _buildMetaRow(String label, String value, IconData icon) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

void showTaskDetailsBottomSheet(
  BuildContext context,
  TaskModel task,
  dynamic user, {
  required Future<void> Function({
    required String remarks,
    required String leadStatus,
  }) onSubmitVisitReport,
}) {
  final bool isCompleted = task.status == 'Completed';
  final formattedAssignedDate = DateFormat('dd MMM yyyy').format(task.assignedDate);

  final remarksController = TextEditingController(text: task.remarks ?? '');
  bool isSubmitting = false;

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
                        style: const TextStyle(
                          color: AppColors.accentTeal,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task.studentName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 32),

                  _buildMetaRow(
                    'Location Visit Address',
                    task.location,
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    'Assigned On Date',
                    formattedAssignedDate,
                    Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    'Manager Directive',
                    task.description,
                    Icons.assignment_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    'Assigned BDE Email',
                    task.assignedBdeEmail,
                    Icons.email_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    'Territory',
                    '${task.zone} / ${task.district}',
                    Icons.public_outlined,
                  ),
                  if (isCompleted) ...[
                    const SizedBox(height: 8),
                    _buildMetaRow(
                      'Lead Status',
                      task.leadStatus,
                      Icons.info_outline_rounded,
                    ),
                  ],
                  if (isCompleted) ...[
                    const Divider(color: Color(0xFFE2E8F0), height: 32),
                    const Text(
                      'VISIT REMARKS & LOGS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.remarks ?? 'No remarks provided.',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else if (user.role != 'BDE') ...[
                    const Divider(color: Color(0xFFE2E8F0), height: 32),
                    const Text(
                      'VISIT DISPATCH STATUS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
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
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    const Divider(color: Color(0xFFE2E8F0), height: 32),

                    const Text(
                      'VISIT REMARKS / DISCUSSION NOTE',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: remarksController,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g., Parent requested fee split options, positive response.',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.accentTeal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: AppColors.accentGradient,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentTeal.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (remarksController.text.trim().isEmpty) {
                                    UiHelpers.showSnackBar(
                                      context,
                                      'Please fill in visit remarks!',
                                      Colors.orange,
                                    );
                                    return;
                                  }
                                  setSheetState(() {
                                    isSubmitting = true;
                                  });
                                  Navigator.pop(context); // Close details sheet
                                  await onSubmitVisitReport(
                                    remarks: remarksController.text.trim(),
                                    leadStatus: 'Closed',
                                  );
                                },
                          icon: const Icon(
                            Icons.cloud_done_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Submit Visit Report & Sync',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
