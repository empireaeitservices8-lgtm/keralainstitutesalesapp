import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../models/task_model.dart';
import '../../../providers/operations_provider.dart';
import '../../../utils/helpers.dart';
import 'create_lead_sheet.dart';

/// Bottom sheet to collect admission and payment details before calling
/// POST /api/leads/{id}/close
///
/// Payload expected:
/// {
///   "student_id": "STU-1001",
///   "course": "Full-Stack Web Development",
///   "payment": 25000,
///   "payment_verification": "Verified",
///   "remarks": "Admission confirmed, fee paid"
/// }
void showCloseLeadSheet(
  BuildContext context,
  TaskModel task, {
  String? initialRemarks,
  VoidCallback? onClosed,
}) {
  final defaultCourse = task.course.trim().isNotEmpty
      ? task.course.trim()
      : (task.interestedCourse != null && task.interestedCourse!.trim().isNotEmpty
          ? task.interestedCourse!.trim()
          : 'Full-Stack Web Development');

  final defaultRemarks = (initialRemarks != null && initialRemarks.trim().isNotEmpty)
      ? initialRemarks.trim()
      : (task.remarks != null && task.remarks!.trim().isNotEmpty
          ? task.remarks!.trim()
          : 'Admission confirmed, fee paid');

  final studentIdController = TextEditingController();
  final courseController = TextEditingController(text: defaultCourse);
  final paymentController = TextEditingController();
  final remarksController = TextEditingController(text: defaultRemarks);

  String selectedVerification = 'Verified';
  const verificationOptions = ['Verified', 'Pending', 'Unverified'];

  bool isSubmitting = false;

  // Pre-fetch server courses for selection
  OperationsProvider.instance.fetchCourses();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.90,
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: bottomInset + 20,
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
                  // Handle
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

                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  size: 14,
                                  color: AppColors.accentTeal,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'CLOSE LEAD • ${task.id}',
                                  style: const TextStyle(
                                    color: AppColors.accentTeal,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title & Description
                  const Text(
                    'Admission & Lead Close Form',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fill in the admission details below to close this lead on the server.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Student summary banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.accentTeal.withValues(alpha: 0.15),
                          child: Text(
                            task.studentName.isNotEmpty
                                ? task.studentName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              color: AppColors.accentTeal,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.studentName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${task.district.isNotEmpty ? task.district : "Kerala"} • ${task.phone ?? "No phone"}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Field 1: Student ID
                  _buildFieldLabel('STUDENT ID / ADMISSION NO *'),
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
                        size: 20,
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
                  const SizedBox(height: 16),

                  // Field 2: Course Name (with selector modal)
                  _buildFieldLabel('ADMITTED COURSE *'),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      _showCourseSelectModal(
                        ctx,
                        currentCourse: courseController.text,
                        onSelected: (selectedName) {
                          setSheetState(() {
                            courseController.text = selectedName;
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
                            size: 20,
                            color: AppColors.accentTeal,
                          ),
                          suffixIcon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                          ),
                          hintText: 'Select or enter course',
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
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Field 3: Payment Amount
                  _buildFieldLabel('PAYMENT AMOUNT (₹) *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: paymentController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.currency_rupee_rounded,
                        size: 20,
                        color: AppColors.accentTeal,
                      ),
                      hintText: 'e.g. 25000',
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
                  const SizedBox(height: 16),

                  // Field 4: Payment Verification Status
                  _buildFieldLabel('PAYMENT VERIFICATION *'),
                  const SizedBox(height: 8),
                  Row(
                    children: verificationOptions.map((opt) {
                      final isSelected = selectedVerification == opt;
                      Color activeColor;
                      switch (opt) {
                        case 'Verified':
                          activeColor = Colors.green;
                          break;
                        case 'Pending':
                          activeColor = Colors.orange;
                          break;
                        default:
                          activeColor = Colors.red;
                      }

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () {
                              setSheetState(() {
                                selectedVerification = opt;
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
                              child: Column(
                                children: [
                                  Icon(
                                    opt == 'Verified'
                                        ? Icons.check_circle_rounded
                                        : opt == 'Pending'
                                            ? Icons.access_time_filled_rounded
                                            : Icons.cancel_rounded,
                                    size: 16,
                                    color: isSelected
                                        ? activeColor
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    opt,
                                    style: TextStyle(
                                      color: isSelected
                                          ? activeColor
                                          : AppColors.textPrimary,
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
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
                  const SizedBox(height: 16),

                  // Field 5: Remarks
                  _buildFieldLabel('VISIT / CLOSING REMARKS *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: remarksController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 38),
                        child: Icon(
                          Icons.notes_rounded,
                          size: 20,
                          color: AppColors.accentTeal,
                        ),
                      ),
                      hintText: 'e.g. Admission confirmed, fee paid',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final studentId = studentIdController.text.trim();
                                final course = courseController.text.trim();
                                final paymentStr = paymentController.text.trim();
                                final remarks = remarksController.text.trim();

                                if (studentId.isEmpty) {
                                  UiHelpers.showSnackBar(
                                    sheetContext,
                                    'Please provide Student ID (e.g. STU-1001)',
                                    Colors.orange,
                                  );
                                  return;
                                }

                                if (course.isEmpty) {
                                  UiHelpers.showSnackBar(
                                    sheetContext,
                                    'Please select or enter the admitted course!',
                                    Colors.orange,
                                  );
                                  return;
                                }

                                final payment = num.tryParse(paymentStr.replaceAll(',', ''));
                                if (payment == null || payment < 0) {
                                  UiHelpers.showSnackBar(
                                    sheetContext,
                                    'Please enter a valid payment amount!',
                                    Colors.orange,
                                  );
                                  return;
                                }

                                if (remarks.isEmpty) {
                                  UiHelpers.showSnackBar(
                                    sheetContext,
                                    'Please enter closing remarks!',
                                    Colors.orange,
                                  );
                                  return;
                                }

                                setSheetState(() {
                                  isSubmitting = true;
                                });

                                try {
                                  await OperationsProvider.instance.closeLead(
                                    id: task.id,
                                    studentId: studentId,
                                    course: course,
                                    payment: payment,
                                    paymentVerification: selectedVerification,
                                    remarks: remarks,
                                  );

                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext); // Close sheet
                                    UiHelpers.showSnackBar(
                                      context,
                                      'Admission confirmed & lead closed successfully for ${task.studentName}!',
                                      Colors.green,
                                    );
                                  }

                                  onClosed?.call();
                                } catch (e) {
                                  if (sheetContext.mounted) {
                                    setSheetState(() {
                                      isSubmitting = false;
                                    });
                                    UiHelpers.showSnackBar(
                                      sheetContext,
                                      'Failed to close lead: ${e.toString()}',
                                      Colors.red,
                                    );
                                  }
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                              ),
                        label: Text(
                          isSubmitting
                              ? 'Closing Lead...'
                              : 'Confirm Admission & Close Lead',
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
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildFieldLabel(String label) {
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

void _showCourseSelectModal(
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
                  'SELECT ADMITTED COURSE',
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
