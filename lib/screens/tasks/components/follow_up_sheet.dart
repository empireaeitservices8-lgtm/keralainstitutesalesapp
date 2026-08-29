import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/colors.dart';
import '../../../models/task_model.dart';
import '../../../providers/operations_provider.dart';
import '../../../utils/helpers.dart';

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
  var currentTask = task;

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  final remarkController = TextEditingController();
  bool isSaving = false;
  bool showForm = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final hasFollowUp =
              currentTask.followUps != null &&
              currentTask.followUps!.isNotEmpty;
          final formattedSelectedDate = DateFormat('dd MMM yyyy').format(selectedDate);
          final formattedSelectedTime = selectedTime.format(context);

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
                        'LEAD FOLLOW-UP • ${currentTask.id}',
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
                                          Icons.access_time_rounded,
                                          color: AppColors.textSecondary,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.dateTime,
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
                                selectedDate = DateTime.now();
                                selectedTime = TimeOfDay.now();
                                remarkController.clear();
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
                            color: AppColors.textSecondary,
                            fontSize: 10,
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
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Follow-up Date',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgInput,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.06),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_month_outlined,
                                        size: 16,
                                        color: AppColors.accentTeal,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        formattedSelectedDate,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
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
                              const Text(
                                'Follow-up Time',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
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
                                  if (pickedTime != null) {
                                    setSheetState(() {
                                      selectedTime = pickedTime;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgInput,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.06),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 16,
                                        color: AppColors.accentTeal,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        formattedSelectedTime,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                    const SizedBox(height: 16),

                    const Text(
                      'Follow-up Remark',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: remarkController,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g., Parent is visiting campus tomorrow for details...',
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

                                  setSheetState(() {
                                    isSaving = true;
                                  });

                                  final combinedDateTime = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    selectedTime.hour,
                                    selectedTime.minute,
                                  );

                                  // Show loading progress dialog
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
                                          CircularProgressIndicator(
                                            color: AppColors.accentTeal,
                                          ),
                                          SizedBox(width: 20),
                                          Expanded(
                                            child: Text(
                                              'Saving follow-up details...',
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );

                                  try {
                                    await OperationsProvider.instance.saveFollowUp(
                                      currentTask.id,
                                      combinedDateTime,
                                      remark,
                                    );

                                    if (context.mounted) {
                                      Navigator.popUntil(
                                        context,
                                        (route) => route is! PopupRoute,
                                      );
                                    }

                                    // Refresh lists
                                    await onSaved();
                                  } catch (e) {
                                    if (context.mounted) {
                                      Navigator.pop(context); // Close loading dialog
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
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Save Follow-up Details',
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
