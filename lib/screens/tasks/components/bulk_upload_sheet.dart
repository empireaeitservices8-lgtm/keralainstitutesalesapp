import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../constants/colors.dart';
import '../../../models/lead_import_response.dart';
import '../../../providers/operations_provider.dart';
import '../../../utils/helpers.dart';

void showBulkUploadBottomSheet(
  BuildContext context, {
  required Future<void> Function() onUploaded,
}) {
  File? selectedFile;
  String? fileSizeStr;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
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
                              sheetContext,
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
                          sheetContext,
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
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (dialogContext) => const AlertDialog(
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

                                  if (context.mounted) {
                                    Navigator.pop(context); // Pop dialog
                                    Navigator.pop(context); // Pop bottom sheet
                                  }

                                  if (result != null && result.success) {
                                    if (context.mounted) {
                                      UiHelpers.showSnackBar(
                                        context,
                                        result.message.isNotEmpty
                                            ? result.message
                                            : 'File uploaded successfully!',
                                        Colors.green,
                                      );
                                    }
                                    await onUploaded();
                                  } else {
                                    if (context.mounted) {
                                      UiHelpers.showSnackBar(
                                        context,
                                        result?.message ??
                                            'Failed to import leads.',
                                        Colors.redAccent,
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    Navigator.pop(context); // Pop dialog
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
