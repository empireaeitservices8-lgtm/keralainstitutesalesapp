import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../providers/home_provider.dart';
import '../../../providers/operations_provider.dart';
import '../../../utils/helpers.dart';
import '../../../api/exceptions/api_exception.dart';

void _showCoursePickerSheet(
  BuildContext context,
  StateSetter parentSetState,
  void Function(int) onSelected,
) {
  OperationsProvider.instance.fetchCourses();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            const Text(
              'SELECT COURSE SCHEME',
              style: TextStyle(
                color: AppColors.accentTeal,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListenableBuilder(
                listenable: OperationsProvider.instance,
                builder: (context, _) {
                  final provider = OperationsProvider.instance;
                  if (provider.isLoadingCourses) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: CircularProgressIndicator(
                          color: AppColors.accentTeal,
                        ),
                      ),
                    );
                  }

                  final courses = provider.courses;
                  if (courses.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'No courses available from server.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: courses.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                    itemBuilder: (context, index) {
                      final c = courses[index];
                      final id = c['id'] as int;
                      final name = c['name'] as String;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () {
                          parentSetState(() {
                            onSelected(id);
                          });
                          Navigator.pop(context);
                        },
                      );
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
}

void _showDistrictPickerSheet(
  BuildContext context,
  StateSetter parentSetState,
  void Function(int) onSelected,
) {
  OperationsProvider.instance.fetchDistricts();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            const Text(
              'SELECT VISIT DISTRICT',
              style: TextStyle(
                color: AppColors.accentTeal,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListenableBuilder(
                listenable: OperationsProvider.instance,
                builder: (context, _) {
                  final provider = OperationsProvider.instance;
                  if (provider.isLoadingDistricts) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: CircularProgressIndicator(
                          color: AppColors.accentTeal,
                        ),
                      ),
                    );
                  }

                  final districts = provider.districts;
                  if (districts.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'No districts available from server.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: districts.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                    itemBuilder: (context, index) {
                      final d = districts[index];
                      final id = d['id'] as int;
                      final name = d['name'] as String;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () {
                          parentSetState(() {
                            onSelected(id);
                          });
                          Navigator.pop(context);
                        },
                      );
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
}

void showCreateLeadBottomSheet(
  BuildContext context, {
  required VoidCallback onCreated,
}) {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final descController = TextEditingController(
    text: 'Self-created lead by BDE.',
  );
  int? selectedCourseId;
  int selectedSourceId = 1;
  int? selectedDistrictId;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
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
                  const Text(
                    'CREATE NEW STUDENT LEAD',
                    style: TextStyle(
                      color: AppColors.accentTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  const Text(
                    'STUDENT FULL NAME',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., Harish Kumar',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.45),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppColors.bgInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Phone
                  const Text(
                    'PHONE NUMBER',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., 9876543210',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.45),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppColors.bgInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Email
                  const Text(
                    'EMAIL ADDRESS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., harish@example.com',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.45),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppColors.bgInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Address
                  const Text(
                    'VISIT ADDRESS / LOCATION',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: addressController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., Kakkanad Junction, Kochi',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.45),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppColors.bgInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'VISIT DISTRICT',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _showDistrictPickerSheet(
                      sheetContext,
                      setSheetState,
                      (districtId) {
                        selectedDistrictId = districtId;
                      },
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              selectedDistrictId == null
                                  ? 'Select a District'
                                  : (OperationsProvider.instance.districts
                                            .firstWhere(
                                              (d) => d['id'] == selectedDistrictId,
                                              orElse: () => {
                                                'name': 'Select a District',
                                              },
                                            )['name'] ??
                                        'Select a District'),
                              style: TextStyle(
                                fontSize: 13,
                                color: selectedDistrictId == null
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.map_outlined,
                            size: 18,
                            color: AppColors.accentTeal,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Course Dropdown
                  const Text(
                    'COURSE SCHEME',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _showCoursePickerSheet(
                      sheetContext,
                      setSheetState,
                      (courseId) {
                        selectedCourseId = courseId;
                      },
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              selectedCourseId == null
                                  ? 'Select a Course'
                                  : (OperationsProvider.instance.courses
                                            .firstWhere(
                                              (c) => c['id'] == selectedCourseId,
                                              orElse: () => {
                                                'name': 'Select a Course',
                                              },
                                            )['name'] ??
                                        'Select a Course'),
                              style: TextStyle(
                                fontSize: 13,
                                color: selectedCourseId == null
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.school_outlined,
                            size: 18,
                            color: AppColors.accentTeal,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Source Dropdown
                  const Text(
                    'LEAD SOURCE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedSourceId,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedSourceId = val);
                          }
                        },
                        items: const [
                          DropdownMenuItem<int>(
                            value: 1,
                            child: Text(
                              'Cold Call',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem<int>(
                            value: 2,
                            child: Text(
                              'Referral',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem<int>(
                            value: 3,
                            child: Text(
                              'Website',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem<int>(
                            value: 4,
                            child: Text(
                              'Advertisement',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem<int>(
                            value: 5,
                            child: Text(
                              'Other',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description / Notes
                  const Text(
                    'LEAD DESCRIPTION / NOTES',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bgInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: AppColors.accentGradient,
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();
                          final email = emailController.text.trim();
                          final address = addressController.text.trim();

                          if (name.isEmpty) {
                            UiHelpers.showSnackBar(
                              sheetContext,
                              'Please enter a student name!',
                              Colors.orange,
                            );
                            return;
                          }
                          if (phone.isEmpty) {
                            UiHelpers.showSnackBar(
                              sheetContext,
                              'Please enter a phone number!',
                              Colors.orange,
                            );
                            return;
                          }
                          if (address.isEmpty) {
                            UiHelpers.showSnackBar(
                              sheetContext,
                              'Please enter a visit address!',
                              Colors.orange,
                            );
                            return;
                          }
                          if (selectedDistrictId == null) {
                            UiHelpers.showSnackBar(
                              sheetContext,
                              'Please select a visit district!',
                              Colors.orange,
                            );
                            return;
                          }
                          if (selectedCourseId == null) {
                            UiHelpers.showSnackBar(
                              sheetContext,
                              'Please select a course scheme!',
                              Colors.orange,
                            );
                            return;
                          }

                          final int employeeDbId =
                              HomeProvider.instance.state.data?.user.id ?? 1;

                          final messenger = ScaffoldMessenger.of(context);

                          Navigator.pop(sheetContext); // Close the bottom sheet

                          bool isDialogShowing = false;
                          isDialogShowing = true;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) {
                              return const AlertDialog(
                                backgroundColor: Colors.white,
                                content: Row(
                                  children: [
                                    CircularProgressIndicator(
                                      color: AppColors.accentTeal,
                                    ),
                                    SizedBox(width: 20),
                                    Text(
                                      'Creating lead on server...',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ).then((_) => isDialogShowing = false);

                          try {
                            final success = await OperationsProvider.instance
                                .createLeadOnServer(
                              name: name,
                              phone: phone,
                              email: email.isNotEmpty ? email : 'no-email@example.com',
                              address: address,
                              districtId: selectedDistrictId!,
                              courseId: selectedCourseId!,
                              source: selectedSourceId,
                              status: 1,
                              assignedEmployeeId: employeeDbId,
                              notes: descController.text.trim(),
                            );

                            if (isDialogShowing && context.mounted) {
                              Navigator.of(context).pop(); // Close dialog
                              isDialogShowing = false;
                            }

                            if (success) {
                              UiHelpers.showMessengerSnackBar(
                                messenger,
                                'Lead created successfully on server!',
                                Colors.green,
                                textColor: Colors.white,
                              );
                              onCreated();
                            } else {
                              UiHelpers.showMessengerSnackBar(
                                messenger,
                                'Failed to create lead. Please check your connection and try again.',
                                Colors.red,
                                textColor: Colors.white,
                              );
                            }
                          } catch (e) {
                            if (isDialogShowing && context.mounted) {
                              Navigator.of(context).pop(); // Close dialog
                              isDialogShowing = false;
                            }
                            String userMessage = 'Failed to create lead. Please check your connection and try again.';
                            if (e is ApiException) {
                              userMessage = e.message.replaceAll('Validation Error: ', '');
                            }
                            UiHelpers.showMessengerSnackBar(
                              messenger,
                              userMessage,
                              Colors.red,
                              textColor: Colors.white,
                            );
                          }
                        },
                        child: const Text(
                          'Create Lead & Schedule Visit',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
