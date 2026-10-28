import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/colors.dart';
import '../../../providers/operations_provider.dart';
import '../../../utils/helpers.dart';

void showUploadInstituteBottomSheet(
  BuildContext context, {
  VoidCallback? onSuccess,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _UploadInstituteSheet(onSuccess: onSuccess),
  );
}

class _UploadInstituteSheet extends StatefulWidget {
  final VoidCallback? onSuccess;

  const _UploadInstituteSheet({this.onSuccess});

  @override
  State<_UploadInstituteSheet> createState() => _UploadInstituteSheetState();
}

class _UploadInstituteSheetState extends State<_UploadInstituteSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Single Entry Controllers
  final _formKey = GlobalKey<FormState>();
  final _instituteNameController = TextEditingController();
  final _personNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmittingSingle = false;

  // Bulk CSV state
  File? _selectedCsvFile;
  String? _csvFileSizeStr;
  int _parsedRowCount = 0;
  List<Map<String, String>> _parsedInstitutes = [];
  bool _isProcessingCsv = false;
  String _csvProgressText = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _instituteNameController.dispose();
    _personNameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSingleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmittingSingle = true);

    try {
      final result = await OperationsProvider.instance.createInstitute(
        instituteName: _instituteNameController.text.trim(),
        personName: _personNameController.text.trim(),
        position: _positionController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isSubmittingSingle = false);

      if (result['success'] == true) {
        Navigator.pop(context);
        UiHelpers.showSnackBar(
          context,
          result['message'] ?? 'Institution details uploaded successfully!',
          Colors.green,
        );
        widget.onSuccess?.call();
      } else {
        UiHelpers.showSnackBar(
          context,
          result['message'] ?? 'Failed to upload institution details.',
          Colors.redAccent,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingSingle = false);
        UiHelpers.showSnackBar(
          context,
          'Error uploading institution: $e',
          Colors.redAccent,
        );
      }
    }
  }

  Future<void> _pickCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        if (!path.toLowerCase().endsWith('.csv')) {
          if (mounted) {
            UiHelpers.showSnackBar(
              context,
              'Please select a valid CSV file (.csv)',
              Colors.orangeAccent,
            );
          }
          return;
        }

        final file = File(path);
        final bytes = await file.length();
        final kb = bytes / 1024;
        final sizeStr = kb > 1024
            ? '${(kb / 1024).toStringAsFixed(2)} MB'
            : '${kb.toStringAsFixed(1)} KB';

        // Parse CSV
        final content = await file.readAsString();
        final lines = const LineSplitter().convert(content);
        if (lines.isEmpty) {
          if (mounted) {
            UiHelpers.showSnackBar(
              context,
              'Selected CSV file is empty.',
              Colors.orangeAccent,
            );
          }
          return;
        }

        // Header check
        final headerLine = lines.first.toLowerCase();
        final headers = headerLine.split(',').map((h) => h.trim().replaceAll('"', '')).toList();

        int idxInst = headers.indexWhere((h) => h.contains('institute') || h.contains('school') || h.contains('college'));
        int idxPerson = headers.indexWhere((h) => h.contains('person') || h.contains('name') || h.contains('contact'));
        int idxPos = headers.indexWhere((h) => h.contains('position') || h.contains('role') || h.contains('designation'));
        int idxPhone = headers.indexWhere((h) => h.contains('phone') || h.contains('mobile') || h.contains('number'));

        // Fallback to column index 0, 1, 2, 3 if headers not matched
        if (idxInst == -1 && headers.isNotEmpty) idxInst = 0;
        if (idxPerson == -1 && headers.length > 1) idxPerson = 1;
        if (idxPos == -1 && headers.length > 2) idxPos = 2;
        if (idxPhone == -1 && headers.length > 3) idxPhone = 3;

        final List<Map<String, String>> parsed = [];
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = line.split(',').map((c) => c.trim().replaceAll('"', '')).toList();
          if (cols.length < 2) continue;

          final instName = (idxInst >= 0 && idxInst < cols.length) ? cols[idxInst] : '';
          final personName = (idxPerson >= 0 && idxPerson < cols.length) ? cols[idxPerson] : '';
          final position = (idxPos >= 0 && idxPos < cols.length) ? cols[idxPos] : 'Principal';
          final phone = (idxPhone >= 0 && idxPhone < cols.length) ? cols[idxPhone] : '';

          if (instName.isNotEmpty || phone.isNotEmpty) {
            parsed.add({
              'institute_name': instName,
              'person_name': personName.isNotEmpty ? personName : 'Administration',
              'position': position.isNotEmpty ? position : 'Principal',
              'phone': phone,
            });
          }
        }

        setState(() {
          _selectedCsvFile = file;
          _csvFileSizeStr = sizeStr;
          _parsedInstitutes = parsed;
          _parsedRowCount = parsed.length;
        });
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showSnackBar(
          context,
          'Error reading CSV file: $e',
          Colors.redAccent,
        );
      }
    }
  }

  Future<void> _handleCsvBulkSubmit() async {
    if (_parsedInstitutes.isEmpty) return;

    setState(() {
      _isProcessingCsv = true;
      _csvProgressText = 'Starting upload of ${_parsedInstitutes.length} institutions...';
    });

    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < _parsedInstitutes.length; i++) {
      final item = _parsedInstitutes[i];
      if (!mounted) break;

      setState(() {
        _csvProgressText = 'Uploading ${i + 1} of ${_parsedInstitutes.length} (${item['institute_name']})...';
      });

      try {
        final res = await OperationsProvider.instance.createInstitute(
          instituteName: item['institute_name'] ?? '',
          personName: item['person_name'] ?? '',
          position: item['position'] ?? 'Principal',
          phone: item['phone'] ?? '',
        );

        if (res['success'] == true) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (_) {
        failCount++;
      }
    }

    if (!mounted) return;
    setState(() => _isProcessingCsv = false);

    Navigator.pop(context);
    UiHelpers.showSnackBar(
      context,
      'Batch complete: $successCount uploaded successfully${failCount > 0 ? ', $failCount failed' : ''}.',
      successCount > 0 ? Colors.green : Colors.redAccent,
    );
    widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.accentTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UPLOAD INSTITUTION / SCHOOL',
                      style: TextStyle(
                        color: AppColors.accentTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'School & Institute Contact Numbers',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tabs
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: AppColors.accentGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              tabs: const [
                Tab(text: 'Single Entry'),
                Tab(text: 'Bulk CSV Import'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab views
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSingleEntryView(),
                _buildBulkCsvView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Single Entry View ---
  Widget _buildSingleEntryView() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the institution or school details and contact person number.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // Institute Name
            _buildInputField(
              controller: _instituteNameController,
              label: 'INSTITUTE / SCHOOL NAME',
              hintText: 'e.g. XYZ College of Arts & Science / Govt HSS',
              icon: Icons.school_outlined,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter institute or school name';
                }
                return null;
              },
            ),

            // Contact Person Name
            _buildInputField(
              controller: _personNameController,
              label: 'CONTACT PERSON NAME',
              hintText: 'e.g. Dr. Rajesh Kumar / Principal',
              icon: Icons.person_outline_rounded,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter contact person name';
                }
                return null;
              },
            ),

            // Position / Role
            _buildInputField(
              controller: _positionController,
              label: 'POSITION / ROLE',
              hintText: 'e.g. Principal / Headmaster / HOD',
              icon: Icons.badge_outlined,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter position or role';
                }
                return null;
              },
            ),

            // Phone Number
            _buildInputField(
              controller: _phoneController,
              label: 'CONTACT PHONE NUMBER',
              hintText: 'e.g. 9847123456',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              prefixText: '+91 ',
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter phone number';
                }
                if (val.trim().length < 10) {
                  return 'Please enter a valid 10-digit phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 10),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSubmittingSingle ? null : _handleSingleSubmit,
                  child: _isSubmittingSingle
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Upload Institution Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Bulk CSV View ---
  Widget _buildBulkCsvView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Import multiple schools and institutions by uploading a CSV file.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // File picker box
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isProcessingCsv ? null : _pickCsvFile,
            child: _selectedCsvFile == null
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accentTeal.withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: AppColors.accentTeal,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Tap to choose Institutions CSV',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Columns: institute_name, person_name, position, phone',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accentTeal.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentTeal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.insert_drive_file_rounded,
                            color: AppColors.accentTeal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCsvFile!.path.split(RegExp(r'[/\\]')).last,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_csvFileSizeStr ?? ''} • $_parsedRowCount institutes detected',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.accentTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isProcessingCsv)
                          IconButton(
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedCsvFile = null;
                                _csvFileSizeStr = null;
                                _parsedInstitutes = [];
                                _parsedRowCount = 0;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
          ),

          if (_isProcessingCsv) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _csvProgressText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Upload button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: _selectedCsvFile == null || _isProcessingCsv
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
                onPressed: _selectedCsvFile == null || _isProcessingCsv
                    ? null
                    : _handleCsvBulkSubmit,
                child: Text(
                  _isProcessingCsv ? 'Processing...' : 'Upload $_parsedRowCount Institutions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            prefixIcon: Icon(icon, size: 18, color: AppColors.accentTeal),
            filled: true,
            fillColor: AppColors.bgInput,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
