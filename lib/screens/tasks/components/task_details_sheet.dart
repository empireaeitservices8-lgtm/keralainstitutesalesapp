import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/colors.dart';
import '../../../models/task_model.dart';
import 'close_lead_sheet.dart';

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

Widget _buildInfoTile(String label, String value, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.bgInput,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 15, color: AppColors.accentTeal),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildPairRow(Widget left, Widget? right) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        if (right != null) ...[
          const SizedBox(width: 8),
          Expanded(child: right),
        ],
      ],
    ),
  );
}

Widget _buildFullTile(String label, String value, IconData icon) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 15, color: AppColors.accentTeal),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        color: AppColors.accentTeal,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    ),
  );
}

void showTaskDetailsBottomSheet(
  BuildContext context,
  TaskModel task,
  dynamic user, {
  Future<void> Function({
    required String remarks,
    required String leadStatus,
  })? onSubmitVisitReport,
}) {
  final bool isCompleted = task.status == 'Completed';
  final formattedAssignedDate = DateFormat('dd MMM yyyy').format(task.assignedDate);

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
                        'LEAD VISIT FILE • ${task.leadIdentifier}',
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

                  // SECTION 1: Contact Details
                  _buildSectionHeader('CONTACT & LOCATION'),
                  if (task.studentId != null && task.studentId!.trim().isNotEmpty)
                    _buildFullTile('Student ID', task.studentId!.trim(), Icons.badge_outlined),
                  _buildPairRow(
                    _buildInfoTile('Phone', (task.phone != null && task.phone!.isNotEmpty) ? task.phone! : '-', Icons.phone_outlined),
                    _buildInfoTile('WhatsApp', (task.whatsappNumber != null && task.whatsappNumber!.isNotEmpty) ? task.whatsappNumber! : ((task.phone != null && task.phone!.isNotEmpty) ? task.phone! : '-'), Icons.chat_bubble_outline),
                  ),
                  _buildPairRow(
                    _buildInfoTile('Email', (task.email != null && task.email!.isNotEmpty) ? task.email! : '-', Icons.alternate_email_outlined),
                    _buildInfoTile('Place', (task.place != null && task.place!.isNotEmpty) ? task.place! : (task.district.isNotEmpty ? task.district : '-'), Icons.place_outlined),
                  ),
                  _buildFullTile('Location Visit Address', task.location, Icons.location_on_outlined),

                  // SECTION 2: Academic & Course Preferences
                  _buildSectionHeader('ACADEMIC & COURSE PROFILE'),
                  _buildPairRow(
                    _buildInfoTile('Qualification', (task.qualification != null && task.qualification!.isNotEmpty) ? task.qualification! : '-', Icons.history_edu_outlined),
                    _buildInfoTile('Current Year', (task.currentYear != null && task.currentYear!.isNotEmpty) ? task.currentYear! : '-', Icons.timeline_outlined),
                  ),
                  _buildPairRow(
                    _buildInfoTile('College / Institute', (task.collegeName != null && task.collegeName!.isNotEmpty) ? task.collegeName! : '-', Icons.account_balance_outlined),
                    _buildInfoTile('Age', (task.age != null && task.age! > 0) ? '${task.age} yrs' : '-', Icons.person_outline),
                  ),
                  _buildPairRow(
                    _buildInfoTile('Interested Course', task.course.isNotEmpty ? task.course : (task.interestedCourse ?? '-'), Icons.school_outlined),
                    _buildInfoTile('Interested Topic', (task.interestedTopic != null && task.interestedTopic!.isNotEmpty) ? task.interestedTopic! : '-', Icons.lightbulb_outline),
                  ),

                  // SECTION 3: Assignment & Source
                  _buildSectionHeader('ASSIGNMENT & SOURCE'),
                  _buildPairRow(
                    _buildInfoTile('Lead Source', (task.leadSource != null && task.leadSource!.isNotEmpty) ? task.leadSource! : '-', Icons.source_outlined),
                    _buildInfoTile('Assigned On', formattedAssignedDate, Icons.calendar_today_outlined),
                  ),
                  _buildPairRow(
                    _buildInfoTile('Assigned BDE', task.assignedBdeEmail, Icons.email_outlined),
                    _buildInfoTile('Territory', '${task.zone} / ${task.district}', Icons.public_outlined),
                  ),
                  if (task.description.isNotEmpty)
                    _buildFullTile('Manager Directive / Notes', task.description, Icons.assignment_outlined),
                  if (isCompleted)
                    _buildFullTile('Lead Status', task.leadStatus, Icons.info_outline_rounded),
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
                              color: AppColors.accentTeal.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context); // Close details sheet
                            showCloseLeadSheet(context, task);
                          },
                          icon: const Icon(
                            Icons.assignment_turned_in_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Submit Visit Report & Close Lead',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
