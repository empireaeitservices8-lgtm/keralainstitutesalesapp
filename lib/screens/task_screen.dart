import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keralainstitutesalesapp/providers/home_provider.dart';
import '../constants/colors.dart';
import '../models/task_model.dart';
import '../providers/operations_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/helpers.dart';

class TaskScreen extends StatefulWidget {
  static const String path = '/tasks';
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _completedLeadsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Listen for tab changes — load completed leads (status=4,5) lazily on first switch
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_completedLeadsLoaded) {
        _completedLeadsLoaded = true;
        OperationsProvider.instance.fetchCompletedLeads();
      }
    });
  }

  void _triggerFilterReload({int? employeeId, int? teamId, int? districtId}) {
    final provider = OperationsProvider.instance;
    if (_tabController.index == 0) {
      provider.fetchLeads(
        status: 1,
        employeeId: employeeId,
        teamId: teamId,
        districtId: districtId,
      );
      _completedLeadsLoaded = false;
    } else {
      provider.fetchCompletedLeads(
        employeeId: employeeId,
        teamId: teamId,
        districtId: districtId,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Handle visit status reporting with progress logs (BDE Flow)
  Future<void> _submitVisitReport({
    required TaskModel task,
    required String leadStatus,
    required String remarks,
    required String proofPath,
    String? followUpDate,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Row(
          children: [
            CircularProgressIndicator(color: AppColors.accentTeal),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'Syncing Lead Status & Proof documents...',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      await OperationsProvider.instance.updateTaskStatus(
        task.id,
        'Completed',
        leadStatus: leadStatus,
        remarks: remarks,
        proof: proofPath,
        followUpDate: followUpDate,
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss syncing dialog
        UiHelpers.showSnackBar(
          context,
          'Lead status updated successfully for ${task.studentName}!',
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss syncing dialog
        UiHelpers.showSnackBar(
          context,
          'Failed to update lead: ${e.toString()}',
          Colors.red,
        );
      }
    }
  }

  // Open Bulk Upload Bottom Sheet (Management Flow - CSV Upload)
  void _showBulkUploadBottomSheet(dynamic bdmUser) {
    File? selectedFile;
    String? fileSizeStr;

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
                    const Text(
                      'BULK LEAD IMPORT',
                      style: TextStyle(
                        color: AppColors.accentTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select a CSV file containing your student leads to import them in bulk.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // File picker container
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.any,
                          );
                          if (result != null &&
                              result.files.single.path != null) {
                            final path = result.files.single.path!;
                            if (!path.toLowerCase().endsWith('.csv')) {
                              UiHelpers.showSnackBar(
                                context,
                                'Please select a valid CSV file (.csv)',
                                Colors.orangeAccent,
                              );
                              return;
                            }
                            final file = File(path);
                            final bytes = await file.length();
                            final kb = bytes / 1024;
                            final sizeStr = kb > 1024
                                ? '${(kb / 1024).toStringAsFixed(2)} MB'
                                : '${kb.toStringAsFixed(1)} KB';
                            setSheetState(() {
                              selectedFile = file;
                              fileSizeStr = sizeStr;
                            });
                          }
                        } catch (e) {
                          UiHelpers.showSnackBar(
                            context,
                            'Error picking file: $e',
                            Colors.red,
                          );
                        }
                      },
                      child: selectedFile == null
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 36,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bgInput,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.accentTeal.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 44,
                                    color: AppColors.accentTeal,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Tap to choose CSV file',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Supports standard CSV with student list',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.accentTeal.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.accentTeal.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentTeal.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.insert_drive_file_rounded,
                                      color: AppColors.accentTeal,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedFile!.path
                                              .split(RegExp(r'[/\\]'))
                                              .last,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          fileSizeStr ?? '',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel_outlined,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      setSheetState(() {
                                        selectedFile = null;
                                        fileSizeStr = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 30),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: selectedFile == null
                                ? [Colors.grey.shade400, Colors.grey.shade400]
                                : AppColors.accentGradient,
                          ),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: selectedFile == null
                              ? null
                              : () async {
                                  // Show progress dialog
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (dialogContext) =>
                                        const AlertDialog(
                                          backgroundColor: Colors.white,
                                          content: Row(
                                            children: [
                                              CircularProgressIndicator(
                                                color: AppColors.accentTeal,
                                              ),
                                              SizedBox(width: 20),
                                              Text(
                                                'Uploading & processing file...',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                  );

                                  try {
                                    final result = await OperationsProvider
                                        .instance
                                        .importLeads(selectedFile!);

                                    // Pop the progress dialog
                                    Navigator.pop(context);
                                    // Pop the bottom sheet
                                    Navigator.pop(context);

                                    if (mounted) {
                                      if (result != null && result.success) {
                                        UiHelpers.showSnackBar(
                                          context,
                                          result.message.isNotEmpty
                                              ? result.message
                                              : 'File uploaded successfully!',
                                          Colors.green,
                                        );
                                        // Refresh the leads list on success
                                        OperationsProvider.instance.fetchLeads(
                                          status: 1,
                                        );
                                      } else {
                                        UiHelpers.showSnackBar(
                                          context,
                                          result?.message ??
                                              'Failed to import leads.',
                                          Colors.redAccent,
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    // Pop progress dialog
                                    Navigator.pop(context);
                                    if (mounted) {
                                      UiHelpers.showSnackBar(
                                        context,
                                        'Error uploading file: $e',
                                        Colors.redAccent,
                                      );
                                    }
                                  }
                                },
                          child: const Text(
                            'Process & Import Leads',
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

  void _showCoursePickerSheet(
    BuildContext context,
    StateSetter parentSetState,
    void Function(int) onSelected,
  ) {
    // Start fetching courses immediately in the background
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
    // Start fetching districts immediately in the background
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

  // Open BDE Single Lead Creation Sheet (Self-created leads flow)
  void _showBdeCreateLeadBottomSheet(dynamic bdeUser) {
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
                        context,
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
                                                (d) =>
                                                    d['id'] ==
                                                    selectedDistrictId,
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
                        context,
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
                                                (c) =>
                                                    c['id'] == selectedCourseId,
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
                                context,
                                'Please enter a student name!',
                                Colors.orange,
                              );
                              return;
                            }
                            if (phone.isEmpty) {
                              UiHelpers.showSnackBar(
                                context,
                                'Please enter a phone number!',
                                Colors.orange,
                              );
                              return;
                            }
                            if (address.isEmpty) {
                              UiHelpers.showSnackBar(
                                context,
                                'Please enter a visit address!',
                                Colors.orange,
                              );
                              return;
                            }
                            if (selectedDistrictId == null) {
                              UiHelpers.showSnackBar(
                                context,
                                'Please select a visit district!',
                                Colors.orange,
                              );
                              return;
                            }
                            if (selectedCourseId == null) {
                              UiHelpers.showSnackBar(
                                context,
                                'Please select a course scheme!',
                                Colors.orange,
                              );
                              return;
                            }

                            // Fetch logged-in user database ID from HomeProvider dashboard data
                            final int employeeDbId =
                                HomeProvider.instance.state.data?.user.id ?? 1;

                            Navigator.pop(context); // Close the bottom sheet

                            bool isDialogShowing = false;
                            isDialogShowing = true;
                            showDialog(
                              context: this.context,
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

                            final success = await OperationsProvider.instance
                                .createLeadOnServer(
                                  name: name,
                                  phone: phone,
                                  email: email.isNotEmpty
                                      ? email
                                      : 'no-email@example.com',
                                  address: address,
                                  districtId: selectedDistrictId!,
                                  courseId: selectedCourseId!,
                                  source: selectedSourceId,
                                  status: 1,
                                  assignedEmployeeId: employeeDbId,
                                  notes: descController.text.trim(),
                                );

                            if (isDialogShowing && mounted) {
                              Navigator.of(this.context).pop();
                              isDialogShowing = false;
                            }

                            if (success) {
                              if (mounted) {
                                UiHelpers.showSnackBar(
                                  this.context,
                                  'Lead created successfully on server!',
                                  Colors.green,
                                );
                              }
                            } else {
                              if (mounted) {
                                UiHelpers.showSnackBar(
                                  this.context,
                                  'Failed to create lead. Please check your connection and try again.',
                                  Colors.red,
                                );
                              }
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

  // Filter Tasks list locally for search and headers
  List<TaskModel> _getFilteredTasks(List<TaskModel> rawTasks) {
    var list = rawTasks;
    final provider = OperationsProvider.instance;

    if (provider.taskSearchQuery.isNotEmpty) {
      list = list
          .where(
            (t) => t.studentName.toLowerCase().contains(
              provider.taskSearchQuery.toLowerCase(),
            ),
          )
          .toList();
    }
    // Skip local BDE filter if server-side filtering (by selectedBdeId) is active
    if (provider.selectedBdeId == null &&
        provider.selectedBdeEmail != null &&
        provider.selectedBdeEmail != 'All BDEs') {
      list = list
          .where(
            (t) => t.assignedBdeEmail.toLowerCase().contains(
              provider.selectedBdeEmail!.toLowerCase(),
            ),
          )
          .toList();
    }
    // Skip local Team filter if server-side filtering (by selectedTeamId) is active
    if (provider.selectedTeamId == null &&
        provider.selectedTeam != null &&
        provider.selectedTeam != 'All Teams') {
      list = list.where((t) => t.team == provider.selectedTeam).toList();
    }
    // Skip local District filter if server-side filtering (by selectedDistrictId) is active
    if (provider.selectedDistrictId == null &&
        provider.selectedDistrict != null &&
        provider.selectedDistrict != 'All Districts') {
      list = list
          .where((t) => t.district == provider.selectedDistrict)
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthProvider.instance,
      builder: (context, _) {
        final user = AuthProvider.instance.session;

        return Scaffold(
          backgroundColor: AppColors.primaryDark,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'STUDENT LEADS & VISITS',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: AppColors.accentGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentTeal.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  tabs: const [
                    Tab(text: 'ASSIGNED VISITS'),
                    Tab(text: 'CLOSED'),
                  ],
                ),
              ),
            ),
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

                  // rawTasks returns _tasks directly (no role-filter/session guard),
                  // which is correct since the API is already Bearer-token scoped.
                  final pendingLeads = _getFilteredTasks(provider.rawTasks);
                  final completedLeads = _getFilteredTasks(
                    provider.completedTasks,
                  );

                  return Column(
                    children: [
                      // Search & Filter header bar
                      _buildSearchAndFilters(provider, user),

                      // Loading indicator banner
                      if (provider.isLoadingLeads ||
                          provider.isLoadingCompletedLeads)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: AppColors.accentTeal.withOpacity(0.08),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accentTeal,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Syncing leads from server...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.accentTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTaskList(
                              pendingLeads,
                              isPending: true,
                              isLoading: provider.isLoadingLeads,
                              onRefresh: () => provider.fetchLeads(status: 1),
                            ),
                            _buildTaskList(
                              completedLeads,
                              isPending: false,
                              isLoading: provider.isLoadingCompletedLeads,
                              onRefresh: () => provider.fetchCompletedLeads(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          floatingActionButton:
              (user.role == 'BDM' ||
                  user.role == 'MD' ||
                  user.role == 'ZM' ||
                  user.role == 'ASM')
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.accentTeal,
                  icon: const Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Bulk Upload',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _showBulkUploadBottomSheet(user),
                )
              : user.role == 'BDE'
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.accentTeal,
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Create Lead',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _showBdeCreateLeadBottomSheet(user),
                )
              : null,
        );
      },
    );
  }

  // Build local search and filters row
  Widget _buildSearchAndFilters(OperationsProvider provider, dynamic user) {
    // Dynamically limit filter options based on user role and hierarchy filters API
    final String defaultBdeLabel = user.role == 'ASM' ? 'All BDMs' : 'All BDEs';
    final List<String> bdeOptions = [defaultBdeLabel];
    final List<String> teamOptions = ['All Teams'];
    final List<String> districtOptions = ['All Districts'];

    final List<String> asmOptions = ['All ASMs'];
    final List<String> bdmOptions = ['All BDMs'];

    if (provider.hierarchyAsms.isNotEmpty) {
      asmOptions.addAll(
        provider.hierarchyAsms.map((a) => a['name'] as String).toSet(),
      );
    }
    if (provider.hierarchyBdms.isNotEmpty) {
      bdmOptions.addAll(
        provider.hierarchyBdms.map((b) => b['name'] as String).toSet(),
      );
    }

    final bool useBdmList = user.role == 'ASM';
    final employeeList = useBdmList ? provider.hierarchyBdms : provider.hierarchyBdes;

    if (employeeList.isNotEmpty) {
      bdeOptions.addAll(
        employeeList.map((b) => b['name'] as String).toSet(),
      );
    } else {
      if (user.role == 'MD') {
        bdeOptions.addAll(
          provider.rawTasks.map((t) => t.assignedBdeEmail).toSet(),
        );
      } else if (user.role == 'ZM') {
        final zonalTasks = provider.rawTasks
            .where((t) => t.zone == user.zone)
            .toList();
        bdeOptions.addAll(zonalTasks.map((t) => t.assignedBdeEmail).toSet());
      } else if (user.role == 'ASM') {
        final districtTasks = provider.rawTasks
            .where((t) => t.district == user.district)
            .toList();
        bdeOptions.addAll(districtTasks.map((t) => t.assignedBdeEmail).toSet());
      } else if (user.role == 'BDM') {
        final teamTasks = provider.rawTasks
            .where((t) => t.team == user.team)
            .toList();
        bdeOptions.addAll(teamTasks.map((t) => t.assignedBdeEmail).toSet());
      }
    }

    if (provider.hierarchyTeams.isNotEmpty) {
      teamOptions.addAll(
        provider.hierarchyTeams.map((t) => t['name'] as String).toSet(),
      );
    } else {
      if (user.role == 'MD') {
        teamOptions.addAll(provider.rawTasks.map((t) => t.team).toSet());
      } else if (user.role == 'ZM') {
        final zonalTasks = provider.rawTasks
            .where((t) => t.zone == user.zone)
            .toList();
        teamOptions.addAll(zonalTasks.map((t) => t.team).toSet());
      } else if (user.role == 'ASM') {
        final districtTasks = provider.rawTasks
            .where((t) => t.district == user.district)
            .toList();
        teamOptions.addAll(districtTasks.map((t) => t.team).toSet());
      }
    }

    if (provider.hierarchyDistricts.isNotEmpty) {
      districtOptions.addAll(
        provider.hierarchyDistricts.map((d) => d['name'] as String).toSet(),
      );
    } else {
      if (user.role == 'MD') {
        districtOptions.addAll(
          provider.rawTasks.map((t) => t.district).toSet(),
        );
      } else if (user.role == 'ZM') {
        final zonalTasks = provider.rawTasks
            .where((t) => t.zone == user.zone)
            .toList();
        districtOptions.addAll(zonalTasks.map((t) => t.district).toSet());
      }
    }

    final bool showBdeFilter = user.role != 'BDE';
    final bool showTeamFilter =
        user.role == 'MD' || user.role == 'ZM' || user.role == 'ASM';
    final bool showDistrictFilter = user.role == 'MD' || user.role == 'ZM';

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Search Input
          TextField(
            onChanged: (val) {
              provider.setTaskSearchQuery(val);
            },
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search leads by student name...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.accentTeal,
                size: 18,
              ),
              filled: true,
              fillColor: AppColors.bgInput,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          if (user.role == 'ZM') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: asmOptions.firstWhere(
                          (opt) => opt.toLowerCase() == provider.selectedAsmEmail?.toLowerCase(),
                          orElse: () => 'All ASMs',
                        ),
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        items: asmOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          int? asmId;
                          if (val != null && val != 'All ASMs') {
                            final asm = provider.hierarchyAsms.firstWhere(
                              (a) => a['name']?.toString().toLowerCase() == val.toLowerCase(),
                              orElse: () => <String, dynamic>{},
                            );
                            asmId = asm['id'] as int?;
                          }
                          provider.setSelectedAsm(val == 'All ASMs' ? null : val, asmId);
                          _triggerFilterReload(employeeId: asmId);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: teamOptions.contains(provider.selectedTeam)
                            ? provider.selectedTeam
                            : 'All Teams',
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        items: teamOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          int? teamId;
                          if (val != null && val != 'All Teams') {
                            final team = provider.hierarchyTeams.firstWhere(
                              (t) => t['name']?.toString().toLowerCase() == val.toLowerCase(),
                              orElse: () => <String, dynamic>{},
                            );
                            teamId = team['id'] as int?;
                          }
                          provider.setSelectedTeam(val == 'All Teams' ? null : val, teamId);
                          _triggerFilterReload(teamId: teamId);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: districtOptions.contains(provider.selectedDistrict)
                            ? provider.selectedDistrict
                            : 'All Districts',
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        items: districtOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          int? districtId;
                          if (val != null && val != 'All Districts') {
                            final dist = provider.hierarchyDistricts.firstWhere(
                              (d) => d['name']?.toString().toLowerCase() == val.toLowerCase(),
                              orElse: () => <String, dynamic>{},
                            );
                            districtId = dist['id'] as int?;
                          }
                          provider.setSelectedDistrict(val == 'All Districts' ? null : val, districtId);
                          _triggerFilterReload(districtId: districtId);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (showBdeFilter || showTeamFilter) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (showBdeFilter)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: bdeOptions.firstWhere(
                              (opt) => opt.toLowerCase() == provider.selectedBdeEmail?.toLowerCase(),
                              orElse: () => defaultBdeLabel,
                            ),
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            items: bdeOptions.map((String value) {
                              String displayName = value;
                              if (value != defaultBdeLabel && value.contains('@')) {
                                displayName = value
                                    .split('@')
                                    .first
                                    .toUpperCase();
                              } else if (value != defaultBdeLabel) {
                                displayName = value.toUpperCase();
                              }
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(displayName),
                              );
                            }).toList(),
                            onChanged: (val) {
                              int? employeeId;
                              if (val != null && val != defaultBdeLabel) {
                                final employee = employeeList
                                    .firstWhere(
                                      (b) => b['name']?.toString().toLowerCase() == val.toLowerCase(),
                                      orElse: () => <String, dynamic>{},
                                    );
                                employeeId = employee['id'] as int?;
                              }

                              provider.setSelectedBde(
                                val == defaultBdeLabel ? null : val,
                                employeeId,
                              );

                              _triggerFilterReload(employeeId: employeeId);
                            },
                          ),
                        ),
                      ),
                    ),
                  if (showBdeFilter && showTeamFilter) const SizedBox(width: 8),
                  if (showTeamFilter)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: teamOptions.contains(provider.selectedTeam)
                                ? provider.selectedTeam
                                : 'All Teams',
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            items: teamOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (val) {
                              int? teamId;
                              if (val != null && val != 'All Teams') {
                                final team = provider.hierarchyTeams.firstWhere(
                                  (t) => t['name']?.toString().toLowerCase() == val.toLowerCase(),
                                  orElse: () => <String, dynamic>{},
                                );
                                teamId = team['id'] as int?;
                              }

                              provider.setSelectedTeam(
                                val == 'All Teams' ? null : val,
                                teamId,
                              );

                              _triggerFilterReload(teamId: teamId);
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (showDistrictFilter) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value:
                              districtOptions.contains(provider.selectedDistrict)
                              ? provider.selectedDistrict
                              : 'All Districts',
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          items: districtOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (val) {
                            int? districtId;
                            if (val != null && val != 'All Districts') {
                              final dist = provider.hierarchyDistricts.firstWhere(
                                (d) => d['name']?.toString().toLowerCase() == val.toLowerCase(),
                                orElse: () => <String, dynamic>{},
                              );
                              districtId = dist['id'] as int?;
                            }
                            provider.setSelectedDistrict(
                              val == 'All Districts' ? null : val,
                              districtId,
                            );
                            _triggerFilterReload(districtId: districtId);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTaskList(
    List<TaskModel> list, {
    required bool isPending,
    required bool isLoading,
    required Future<void> Function() onRefresh,
  }) {
    if (list.isEmpty && isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentTeal),
      );
    }

    if (list.isEmpty && !isLoading) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.accentTeal,
        child: ListView(
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPending
                          ? Icons.verified_rounded
                          : Icons.folder_shared_rounded,
                      color: AppColors.textSecondary.withOpacity(0.2),
                      size: 64,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No Student Leads match criteria.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pull down to refresh',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.accentTeal,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final task = list[index];
          final formattedDate = DateFormat(
            'dd MMM yyyy',
          ).format(task.assignedDate);

          final Color statusColor = isPending
              ? AppColors.accentCyan
              : _getLeadStatusColor(task.leadStatus);

          return GestureDetector(
            onTap: () => _showTaskDetailsBottomSheet(task),
            child: Container(
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
                      child: Container(color: statusColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 18,
                        right: 16,
                        top: 16,
                        bottom: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentTeal.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  task.id,
                                  style: const TextStyle(
                                    color: AppColors.accentTeal,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'Assigned: $formattedDate',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            task.studentName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Course: ${task.course}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${task.location} (${task.district})',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Management attribution badge
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'BDE: ${task.assignedBdeEmail.split('@').first.toUpperCase()} (${task.team})',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          const Divider(color: Color(0xFFE2E8F0), height: 28),
                          if (isPending) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: const LinearGradient(
                                      colors: AppColors.accentGradient,
                                    ),
                                  ),
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () =>
                                        _showTaskDetailsBottomSheet(task),
                                    icon: const Icon(
                                      Icons.assignment_outlined,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      (AuthProvider.instance.session.role ==
                                              'BDE')
                                          ? 'Report Visit'
                                          : 'View File',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getLeadStatusColor(
                                      task.leadStatus,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    task.leadStatus.toUpperCase(),
                                    style: TextStyle(
                                      color: _getLeadStatusColor(
                                        task.leadStatus,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.verified_user_rounded,
                                      color: Colors.green,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Synced to Cloud',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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

  void _showTaskDetailsBottomSheet(TaskModel task) {
    final bool isCompleted = task.status == 'Completed';
    final user = AuthProvider.instance.session;

    final formattedAssignedDate = DateFormat(
      'dd MMM yyyy',
    ).format(task.assignedDate);
    final formattedCompletedDate = task.completedDate != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(task.completedDate!)
        : 'N/A';

    final remarksController = TextEditingController(text: task.remarks ?? '');
    String selectedLeadStatus = isCompleted ? task.leadStatus : 'Interested';
    String? proofPath = isCompleted ? task.completionProofPath : null;
    String selectedFollowUpDate =
        task.followUpDate ??
        DateFormat(
          'dd MMM yyyy',
        ).format(DateTime.now().add(const Duration(days: 2)));
    bool isUploadingProof = false;
    bool _isSubmitting = false;

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
                              color: _getLeadStatusColor(
                                task.leadStatus,
                              ).withOpacity(0.1),
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
                          hintText:
                              'e.g., Parent requested fee split options, positive response.',
                          hintStyle: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: AppColors.bgInput,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            // ignore: deprecated_member_use
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
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    if (remarksController.text.trim().isEmpty) {
                                      UiHelpers.showSnackBar(
                                        context,
                                        'Please fill in visit remarks!',
                                        Colors.orange,
                                      );
                                      return;
                                    }
                                    setSheetState(() {
                                      _isSubmitting = true;
                                    });
                                    Navigator.pop(context);
                                    _submitVisitReport(
                                      task: task,
                                      leadStatus: 'Closed',
                                      remarks: remarksController.text.trim(),
                                      proofPath: 'N/A',
                                      followUpDate: null,
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

  Widget _buildMetaRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
