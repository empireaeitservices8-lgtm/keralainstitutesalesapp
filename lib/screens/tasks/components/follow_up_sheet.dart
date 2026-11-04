import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../api/api_endpoints.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/colors.dart';
import '../../../models/task_model.dart';
import '../../../providers/operations_provider.dart';
import '../../../utils/helpers.dart';
import 'create_lead_sheet.dart';

const List<String> kFollowUpLeadSources = [
  'College Visit',
  'Campus Drive / College Seminar',
  'Cold Call',
  'Referral',
  'Website',
  'Advertisement',
  'Social Media (Instagram/LinkedIn)',
  'Walk-in / Direct Visit',
  'Other',
];

const List<String> kStudentInterestOptions = [
  'Hot',
  'Warm',
  'Cold',
];

const List<String> kAdmissionStatusOptions = [
  'Follow Uped',
  'Interested',
  'Admitted',
  'New',
];

const List<String> kPaymentVerificationOptions = [
  'Pending',
  'Verified',
  'Unverified',
];

String _formatFollowUpDateOnly(String raw) {
  if (raw.isEmpty) return '';
  if (raw.contains(',')) {
    final parts = raw.split(',');
    if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
      return parts[0].trim();
    }
  }
  try {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return DateFormat('dd MMM yyyy').format(parsed.toLocal());
    }
  } catch (_) {}
  return raw;
}

String _getOrdinal(int index) {
  final n = index + 1;
  if (n >= 11 && n <= 13) {
    return '${n}th';
  }
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
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

void showFollowUpBottomSheet(
  BuildContext context,
  TaskModel task, {
  required String userRole,
  required Future<void> Function() onSaved,
}) {
  final liveTask = OperationsProvider.instance.tasks.where((t) =>
      t.id == task.id ||
      (t.leadId != null && t.leadId == task.leadId) ||
      t.leadIdentifier == task.leadIdentifier
  ).firstOrNull ?? task;
  var currentTask = liveTask;

  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  final remarkController = TextEditingController();
  final defaultStudentId = (currentTask.studentId != null && currentTask.studentId!.trim().isNotEmpty)
      ? currentTask.studentId!.trim()
      : ((task.studentId != null && task.studentId!.trim().isNotEmpty)
          ? task.studentId!.trim()
          : 'STU-${currentTask.leadIdentifier.replaceAll("LD-", "").replaceAll("LD_", "")}');
  final studentIdController = TextEditingController(text: defaultStudentId);

  final defaultCourse = currentTask.course.isNotEmpty
      ? currentTask.course
      : (currentTask.interestedCourse != null && currentTask.interestedCourse!.isNotEmpty
          ? currentTask.interestedCourse!
          : 'Full-Stack Web Development');
  final courseController = TextEditingController(text: defaultCourse);

  String selectedLeadSource = (currentTask.leadSource != null && currentTask.leadSource!.isNotEmpty)
      ? currentTask.leadSource!
      : 'College Visit';
  String selectedInterest = 'Warm';
  String selectedAdmissionStatus = 'Follow Uped';
  String selectedPaymentVerification = 'Pending';

  bool isSaving = false;
  bool showForm = false;
  String? selectedProofPath;

  OperationsProvider.instance.fetchCourses();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final hasFollowUp =
              currentTask.followUps != null &&
              currentTask.followUps!.isNotEmpty;

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
                        'LEAD FOLLOW-UP • ${currentTask.leadIdentifier}',
                        style: const TextStyle(
                          color: AppColors.accentTeal,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          currentTask.leadStatus.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentTask.studentName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (currentTask.phone != null &&
                          currentTask.phone!.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.phone_in_talk_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () async {
                              final phoneUrl = Uri.parse('tel:${currentTask.phone}');
                              if (await canLaunchUrl(phoneUrl)) {
                                await launchUrl(phoneUrl);
                              } else {
                                if (context.mounted) {
                                  UiHelpers.showSnackBar(
                                    context,
                                    'Could not launch phone call to ${currentTask.phone}',
                                    Colors.red,
                                  );
                                }
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 32),

                  if (defaultStudentId.isNotEmpty) ...[
                    _buildMetaRow(
                      'Student ID',
                      defaultStudentId,
                      Icons.badge_outlined,
                    ),
                    const SizedBox(height: 8),
                  ],

                  _buildMetaRow(
                    'Course Interest',
                    currentTask.course,
                    Icons.school_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    'Address / Location',
                    currentTask.location,
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    'Assigned Date',
                    DateFormat('dd MMM yyyy').format(currentTask.assignedDate),
                    Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    'Manager Notes',
                    currentTask.description,
                    Icons.assignment_outlined,
                  ),

                  const Divider(color: Color(0xFFE2E8F0), height: 32),

                  if (!showForm) ...[
                    const Text(
                      'FOLLOW-UP HISTORY',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (currentTask.followUps == null ||
                        currentTask.followUps!.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No follow-up history available.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentTask.followUps?.length ?? 0,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = currentTask.followUps![index];
                          final ordinal = _getOrdinal(index);
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.accentTeal.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.accentTeal.withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$ordinal Follow-up',
                                      style: const TextStyle(
                                        color: AppColors.accentTeal,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          color: AppColors.textSecondary,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatFollowUpDateOnly(item.dateTime),
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (item.remark.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    item.remark,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    if (userRole == 'BDE') ...[
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
                            onPressed: () {
                              setSheetState(() {
                                showForm = true;
                              });
                            },
                            icon: const Icon(
                              Icons.add_alarm_rounded,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Add Follow Up',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SCHEDULE NEW FOLLOW-UP',
                          style: TextStyle(
                            color: AppColors.accentTeal,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        if (hasFollowUp)
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                showForm = false;
                              });
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 1. Lead Source
                    _buildFormLabel('LEAD SOURCE *'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: kFollowUpLeadSources.contains(selectedLeadSource)
                              ? selectedLeadSource
                              : kFollowUpLeadSources.first,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          items: kFollowUpLeadSources.map((source) {
                            return DropdownMenuItem<String>(
                              value: source,
                              child: Text(source),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                selectedLeadSource = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Student Interest Level
                    _buildFormLabel('STUDENT INTEREST *'),
                    const SizedBox(height: 6),
                    Row(
                      children: kStudentInterestOptions.map((interest) {
                        final isSelected = selectedInterest == interest;
                        Color activeColor;
                        IconData iconData;
                        switch (interest) {
                          case 'Hot':
                            activeColor = Colors.red;
                            iconData = Icons.local_fire_department_rounded;
                            break;
                          case 'Warm':
                            activeColor = Colors.orange;
                            iconData = Icons.wb_sunny_rounded;
                            break;
                          default:
                            activeColor = Colors.blue;
                            iconData = Icons.ac_unit_rounded;
                        }

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () {
                                setSheetState(() {
                                  selectedInterest = interest;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? activeColor.withValues(alpha: 0.12)
                                      : AppColors.bgInput,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? activeColor
                                        : Colors.black.withValues(alpha: 0.06),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      iconData,
                                      size: 15,
                                      color: isSelected
                                          ? activeColor
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      interest,
                                      style: TextStyle(
                                        color: isSelected
                                            ? activeColor
                                            : AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // 3. Next Follow-up Date
                    _buildFormLabel('NEXT FOLLOW-UP DATE *'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.accentTeal,
                                  onPrimary: Colors.white,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setSheetState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                              color: AppColors.accentTeal,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('yyyy-MM-dd').format(selectedDate),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit_calendar_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Course (with search / selector modal)
                    _buildFormLabel('COURSE *'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        _showFollowUpCoursePicker(
                          context,
                          currentCourse: courseController.text,
                          onSelected: (name) {
                            setSheetState(() {
                              courseController.text = name;
                            });
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: IgnorePointer(
                        child: TextField(
                          controller: courseController,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.school_outlined,
                              size: 18,
                              color: AppColors.accentTeal,
                            ),
                            suffixIcon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                            ),
                            hintText: 'Select course',
                            filled: true,
                            fillColor: AppColors.bgInput,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.accentTeal,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. Student ID (blank by default)
                    _buildFormLabel('STUDENT ID'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: studentIdController,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          size: 18,
                          color: AppColors.accentTeal,
                        ),
                        hintText: 'e.g. STU-1001',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.accentTeal,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 6. Admission Status
                    _buildFormLabel('ADMISSION STATUS *'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: kAdmissionStatusOptions.contains(selectedAdmissionStatus)
                              ? selectedAdmissionStatus
                              : kAdmissionStatusOptions.first,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          items: kAdmissionStatusOptions.map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                selectedAdmissionStatus = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 7. Payment Verification
                    _buildFormLabel('PAYMENT VERIFICATION *'),
                    const SizedBox(height: 6),
                    Row(
                      children: kPaymentVerificationOptions.map((opt) {
                        final isSelected = selectedPaymentVerification == opt;
                        Color activeColor;
                        IconData iconData;
                        switch (opt) {
                          case 'Verified':
                            activeColor = Colors.green;
                            iconData = Icons.check_circle_rounded;
                            break;
                          case 'Pending':
                            activeColor = Colors.orange;
                            iconData = Icons.access_time_filled_rounded;
                            break;
                          default:
                            activeColor = Colors.red;
                            iconData = Icons.cancel_rounded;
                        }

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () {
                                setSheetState(() {
                                  selectedPaymentVerification = opt;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? activeColor.withValues(alpha: 0.12)
                                      : AppColors.bgInput,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? activeColor
                                        : Colors.black.withValues(alpha: 0.06),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      iconData,
                                      size: 14,
                                      color: isSelected
                                          ? activeColor
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      opt,
                                      style: TextStyle(
                                        color: isSelected
                                            ? activeColor
                                            : AppColors.textPrimary,
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // 8. Remarks
                    _buildFormLabel('REMARKS *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: remarkController,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Visited the college, interested in the MERN batch',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        contentPadding: const EdgeInsets.all(12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.accentTeal,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Button
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
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final remark = remarkController.text.trim();
                                  if (remark.isEmpty) {
                                    UiHelpers.showSnackBar(
                                      context,
                                      'Please fill in the follow-up remark!',
                                      Colors.orange,
                                    );
                                    return;
                                  }

                                  final course = courseController.text.trim();
                                  if (course.isEmpty) {
                                    UiHelpers.showSnackBar(
                                      context,
                                      'Please select a course!',
                                      Colors.orange,
                                    );
                                    return;
                                  }

                                  setSheetState(() {
                                    isSaving = true;
                                  });

                                  final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

                                  try {
                                    await OperationsProvider.instance.saveFollowUp(
                                      leadId: currentTask.leadIdentifier,
                                      actualLeadId: currentTask.leadId,
                                      leadSource: selectedLeadSource,
                                      studentInterest: selectedInterest,
                                      nextFollowupDate: formattedDate,
                                      remarks: remark,
                                      admissionStatus: selectedAdmissionStatus,
                                      paymentVerification: selectedPaymentVerification,
                                      studentId: studentIdController.text.trim(),
                                      course: course,
                                    );

                                    if (sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop(); // Close sheet
                                    }
                                    if (context.mounted) {
                                      UiHelpers.showSnackBar(
                                        context,
                                        'Follow-up recorded successfully for ${currentTask.studentName}!',
                                        Colors.green,
                                      );
                                    }

                                    // Refresh lists
                                    await onSaved();
                                  } catch (e) {
                                    if (context.mounted) {
                                      UiHelpers.showSnackBar(
                                        context,
                                        'Failed to save follow-up: $e',
                                        Colors.red,
                                      );
                                      setSheetState(() {
                                        isSaving = false;
                                      });
                                    }
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                ),
                          label: Text(
                            isSaving
                                ? 'Saving Follow-up...'
                                : 'Save Follow-up Details',
                            style: const TextStyle(
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

Widget _buildFormLabel(String label) {
  return Text(
    label,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
    ),
  );
}

void _showFollowUpCoursePicker(
  BuildContext context, {
  required String currentCourse,
  required Function(String) onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalCtx) {
      final searchController = TextEditingController();
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final serverCourses = OperationsProvider.instance.courses;
          final Set<String> allCourses = {
            ...kPopularCourses,
            ...serverCourses.map((c) => c['name']?.toString() ?? '').where((s) => s.isNotEmpty),
          };

          final query = searchController.text.trim().toLowerCase();
          final filteredCourses = allCourses
              .where((c) => c.toLowerCase().contains(query))
              .toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(modalCtx).size.height * 0.75,
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
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
                const SizedBox(height: 16),
                const Text(
                  'SELECT COURSE',
                  style: TextStyle(
                    color: AppColors.accentTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  onChanged: (_) => setModalState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    hintText: 'Search course name...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.bgInput,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredCourses.length,
                    separatorBuilder: (_, _) => const Divider(
                      color: Color(0xFFF1F5F9),
                      height: 1,
                    ),
                    itemBuilder: (_, index) {
                      final name = filteredCourses[index];
                      final isSelected = name.toLowerCase() == currentCourse.toLowerCase();
                      final match = OperationsProvider.instance.findCourseByName(name);

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.accentTeal : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: match != null && (match.fee > 0 || match.duration.isNotEmpty)
                            ? Text(
                                'Fee: ₹${match.fee} • Duration: ${match.duration}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : null,
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.accentTeal,
                                size: 20,
                              )
                            : const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                                size: 18,
                              ),
                        onTap: () {
                          onSelected(name);
                          Navigator.pop(modalCtx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


Widget _buildFollowUpAttachmentThumbnail(
  BuildContext context,
  String path,
  String label,
) {
  return GestureDetector(
    onTap: () => _showFollowUpImageDialog(context, path, label),
    child: Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 140),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: _buildUniversalFollowUpImage(path, fit: BoxFit.cover),
      ),
    ),
  );
}

Widget _buildUniversalFollowUpImage(String path, {BoxFit fit = BoxFit.cover}) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return const SizedBox.shrink();

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return Image.network(
      trimmed,
      fit: fit,
      errorBuilder: (_, __, ___) => _buildFollowUpImageError(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentTeal),
          ),
        );
      },
    );
  }

  try {
    final file = File(trimmed);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFollowUpImageError(),
      );
    }
  } catch (_) {}

  if (trimmed.startsWith('/') || trimmed.startsWith('storage') || trimmed.startsWith('uploads')) {
    final clean = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    final fullUrl = '${ApiEndpoints.baseUrl.replaceAll('/api', '')}/$clean';
    return Image.network(
      fullUrl,
      fit: fit,
      errorBuilder: (_, __, ___) => _buildFollowUpImageError(),
    );
  }

  return Image.file(
    File(trimmed),
    fit: fit,
    errorBuilder: (_, __, ___) => _buildFollowUpImageError(),
  );
}

Widget _buildFollowUpImageError() {
  return Container(
    height: 80,
    color: Colors.grey.shade100,
    alignment: Alignment.center,
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image, size: 24, color: Colors.grey),
        SizedBox(height: 4),
        Text('Unable to preview photo', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ],
    ),
  );
}

void _showFollowUpImageDialog(BuildContext context, String path, String label) {
  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                maxWidth: MediaQuery.of(ctx).size.width * 0.90,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildUniversalFollowUpImage(path, fit: BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 4,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black87, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildAttachmentPicker({
  required BuildContext context,
  required String? selectedPath,
  required ValueChanged<String> onPicked,
  required VoidCallback onRemoved,
}) {
  if (selectedPath != null && selectedPath.isNotEmpty) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentTeal.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 50,
              height: 50,
              child: _buildUniversalFollowUpImage(selectedPath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attachment Selected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  selectedPath.split('/').last.split('\\').last,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
            onPressed: onRemoved,
          ),
        ],
      ),
    );
  }

  return Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(color: AppColors.accentTeal.withOpacity(0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.accentTeal),
          label: const Text(
            'Camera',
            style: TextStyle(fontSize: 12, color: AppColors.accentTeal, fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            try {
              final picker = ImagePicker();
              final xfile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
              if (xfile != null) onPicked(xfile.path);
            } catch (e) {
              UiHelpers.showSnackBar(context, 'Failed to open camera: $e', Colors.red);
            }
          },
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(color: AppColors.accentTeal.withOpacity(0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.photo_library_outlined, size: 16, color: AppColors.accentTeal),
          label: const Text(
            'Gallery',
            style: TextStyle(fontSize: 12, color: AppColors.accentTeal, fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            try {
              final picker = ImagePicker();
              final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
              if (xfile != null) onPicked(xfile.path);
            } catch (e) {
              UiHelpers.showSnackBar(context, 'Failed to pick image: $e', Colors.red);
            }
          },
        ),
      ),
    ],
  );
}