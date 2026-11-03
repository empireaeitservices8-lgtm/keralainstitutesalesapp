import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../providers/home_provider.dart';
import '../../../providers/operations_provider.dart';
import '../../../utils/helpers.dart';
import '../../../api/exceptions/api_exception.dart';

const List<String> kKeralaDistricts = [
  'Alappuzha',
  'Ernakulam',
  'Idukki',
  'Kannur',
  'Kasaragod',
  'Kollam',
  'Kottayam',
  'Kozhikode',
  'Malappuram',
  'Palakkad',
  'Pathanamthitta',
  'Thiruvananthapuram',
  'Thrissur',
  'Wayanad',
];

const List<String> kQualifications = [
  'B.Tech Computer Science',
  'BCA',
  'B.Sc Computer Science',
  'MCA',
  'B.Tech (Other Branches)',
  'Diploma in CS / IT',
  'Diploma (Other Branches)',
  'B.Com',
  'BBA',
  'BA / B.Sc (General)',
  'M.Tech / M.Sc',
  'Plus Two / 12th',
  'Other',
];

const List<String> kPopularCourses = [
  'Full-Stack Web Development',
  'MERN Stack & Next.js',
  'Python, Django & Data Science',
  'Flutter & Mobile App Development',
  'UI/UX Design & Frontend',
  'Artificial Intelligence & Machine Learning',
  'Cyber Security & Ethical Hacking',
  'Digital Marketing & SEO',
];

const List<String> kLeadSources = [
  'Campus Drive / College Seminar',
  'Cold Call',
  'Referral',
  'Website',
  'Advertisement',
  'Social Media (Instagram/LinkedIn)',
  'Walk-in / Direct Visit',
  'Other',
];

const List<String> kAdmissionStatuses = [
  'New',
  'Interested',
  'Follow-up Required',
  'Admitted',
  'Closed',
];

void _showCoursePickerSheet(
  BuildContext context, {
  required String currentCourse,
  required void Function(String name, int? id) onSelected,
}) {
  OperationsProvider.instance.fetchCourses();

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
                  'SELECT INTERESTED COURSE',
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
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                    hintText: 'Search course name...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.bgInput,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    separatorBuilder: (_, _) => const Divider(color: Color(0xFFF1F5F9), height: 1),
                    itemBuilder: (_, index) {
                      final name = filteredCourses[index];
                      final isSelected = name.toLowerCase() == currentCourse.toLowerCase();

                      final matchingServer = serverCourses.firstWhere(
                        (c) => c['name']?.toString().toLowerCase() == name.toLowerCase(),
                        orElse: () => {},
                      );
                      final int? serverId = matchingServer['id'] != null ? UiHelpers.parseInt(matchingServer['id']) : null;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.accentTeal : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: matchingServer.isNotEmpty &&
                                (matchingServer['fee'] != null || matchingServer['duration'] != null)
                            ? Text(
                                'Fee: ₹${matchingServer['fee']} • Duration: ${matchingServer['duration']}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : null,
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.accentTeal, size: 20)
                            : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                        onTap: () {
                          onSelected(name, serverId);
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

void showCreateLeadBottomSheet(
  BuildContext context, {
  required VoidCallback onCreated,
}) {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final whatsappController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final placeController = TextEditingController();
  final ageController = TextEditingController();
  final customQualificationController = TextEditingController();
  final collegeController = TextEditingController();
  final currentYearController = TextEditingController();
  final interestedTopicController = TextEditingController();
  final customCourseController = TextEditingController();
  final notesController = TextEditingController(text: 'Interested in weekend batch');

  String selectedDistrict = 'Ernakulam';
  int? selectedDistrictId;

  String selectedQualification = 'B.Tech Computer Science';

  String selectedCourse = 'Full-Stack Web Development';
  int? selectedCourseId;
  bool isCustomCourse = false;

  String selectedLeadSource = 'Campus Drive / College Seminar';
  String selectedAdmissionStatus = 'New';

  Widget buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.accentTeal),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.accentTeal,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return Column(
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
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.bgInput,
            suffixIcon: suffixIcon,
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

  Widget buildChipSelector({
    required List<String> options,
    required String? currentValue,
    required void Function(String) onSelect,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isSelected = opt.toLowerCase() == (currentValue ?? '').toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 8),
            child: ChoiceChip(
              label: Text(
                opt,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.accentTeal,
              backgroundColor: AppColors.bgInput,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              onSelected: (_) => onSelect(opt),
            ),
          );
        }).toList(),
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          // Combine standard Kerala districts with any server districts
          final Set<String> districtSet = {
            ...kKeralaDistricts,
            ...OperationsProvider.instance.districts
                .map((d) => d['name']?.toString() ?? '')
                .where((s) => s.isNotEmpty),
          };
          final List<String> districtOptions = districtSet.toList()..sort();
          if (!districtOptions.contains(selectedDistrict)) {
            districtOptions.insert(0, selectedDistrict);
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.92,
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
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
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CREATE NEW STUDENT LEAD',
                            style: TextStyle(
                              color: AppColors.accentTeal,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Complete the lead profile matching the LMS system.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // -----------------------------------------------------------
                  // SECTION 1: Contact Information (Personal)
                  // -----------------------------------------------------------
                  buildSectionHeader('CONTACT INFORMATION', Icons.person_outline_rounded),
                  buildField(
                    controller: nameController,
                    label: 'STUDENT FULL NAME *',
                    hintText: 'e.g., Rahul Krishna',
                  ),
                  buildField(
                    controller: phoneController,
                    label: 'PHONE NUMBER *',
                    hintText: 'e.g., 9847123456',
                    keyboardType: TextInputType.phone,
                    onChanged: (val) {
                      if (whatsappController.text.isEmpty) {
                        setSheetState(() {
                          whatsappController.text = val;
                        });
                      }
                    },
                  ),
                  buildField(
                    controller: whatsappController,
                    label: 'WHATSAPP NUMBER',
                    hintText: 'e.g., 9847123456',
                    keyboardType: TextInputType.phone,
                    suffixIcon: Tooltip(
                      message: 'Copy from Phone',
                      child: TextButton.icon(
                        onPressed: () {
                          setSheetState(() {
                            whatsappController.text = phoneController.text.trim();
                          });
                        },
                        icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.accentTeal),
                        label: const Text(
                          'Same',
                          style: TextStyle(fontSize: 11, color: AppColors.accentTeal, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  buildField(
                    controller: emailController,
                    label: 'EMAIL ADDRESS',
                    hintText: 'e.g., rahul@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  // -----------------------------------------------------------
                  // SECTION 2: Location Details
                  // -----------------------------------------------------------
                  buildSectionHeader('LOCATION DETAILS', Icons.location_on_outlined),
                  buildField(
                    controller: addressController,
                    label: 'STREET ADDRESS *',
                    hintText: 'e.g., MG Road',
                  ),
                  buildField(
                    controller: placeController,
                    label: 'PLACE / LOCALITY',
                    hintText: 'e.g., Edappally, Kochi',
                  ),

                  // District as Dropdown
                  const Text(
                    'DISTRICT *',
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
                      child: DropdownButton<String>(
                        value: districtOptions.contains(selectedDistrict) ? selectedDistrict : districtOptions.first,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.accentTeal, size: 26),
                        onChanged: (val) {
                          if (val != null) {
                            final matchingServer = OperationsProvider.instance.districts.firstWhere(
                              (d) => d['name']?.toString().toLowerCase() == val.toLowerCase(),
                              orElse: () => {},
                            );
                            setSheetState(() {
                              selectedDistrict = val;
                              selectedDistrictId = matchingServer['id'] != null ? UiHelpers.parseInt(matchingServer['id']) : null;
                            });
                          }
                        },
                        items: districtOptions.map((dist) {
                          return DropdownMenuItem<String>(
                            value: dist,
                            child: Text(
                              dist,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // -----------------------------------------------------------
                  // SECTION 3: Academic Background
                  // -----------------------------------------------------------
                  buildSectionHeader('ACADEMIC BACKGROUND', Icons.school_outlined),

                  // Age (Typing only, no selecting)
                  buildField(
                    controller: ageController,
                    label: 'AGE',
                    hintText: 'e.g., 22',
                    keyboardType: TextInputType.number,
                  ),

                  // Qualification as Dropdown
                  const Text(
                    'QUALIFICATION',
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
                      child: DropdownButton<String>(
                        value: kQualifications.contains(selectedQualification) ? selectedQualification : kQualifications.first,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.accentTeal, size: 26),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedQualification = val);
                          }
                        },
                        items: kQualifications.map((q) {
                          return DropdownMenuItem<String>(
                            value: q,
                            child: Text(
                              q,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (selectedQualification == 'Other') ...[
                    const SizedBox(height: 10),
                    buildField(
                      controller: customQualificationController,
                      label: 'SPECIFY QUALIFICATION',
                      hintText: 'e.g., B.Tech Mechanical Engineering',
                    ),
                  ] else
                    const SizedBox(height: 12),

                  buildField(
                    controller: collegeController,
                    label: 'COLLEGE / INSTITUTION NAME',
                    hintText: 'e.g., Model Engineering College',
                  ),

                  // Current Year (Typing only, no selecting)
                  buildField(
                    controller: currentYearController,
                    label: 'CURRENT YEAR / STATUS',
                    hintText: 'e.g., Final Year',
                  ),

                  // -----------------------------------------------------------
                  // SECTION 4: Course & Topic Preferences
                  // -----------------------------------------------------------
                  buildSectionHeader('COURSE & TOPIC PREFERENCES', Icons.auto_stories_outlined),
                  const Text(
                    'INTERESTED COURSE *',
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
                      currentCourse: selectedCourse,
                      onSelected: (courseName, courseId) {
                        setSheetState(() {
                          selectedCourse = courseName;
                          selectedCourseId = courseId;
                          isCustomCourse = false;
                        });
                      },
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              selectedCourse.isEmpty ? 'Select Interested Course' : selectedCourse,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 24,
                            color: AppColors.accentTeal,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  buildChipSelector(
                    options: const [
                      'Full-Stack Web Development',
                      'MERN Stack & Next.js',
                      'Python, Django & Data Science',
                      'Flutter & Mobile App Development',
                      'UI/UX Design & Frontend',
                    ],
                    currentValue: selectedCourse,
                    onSelect: (c) => setSheetState(() {
                      selectedCourse = c;
                      isCustomCourse = false;
                    }),
                  ),

                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setSheetState(() {
                            isCustomCourse = !isCustomCourse;
                            if (isCustomCourse) {
                              customCourseController.text = selectedCourse;
                            }
                          });
                        },
                        icon: Icon(
                          isCustomCourse ? Icons.check_box_rounded : Icons.edit_note_rounded,
                          size: 16,
                          color: AppColors.accentTeal,
                        ),
                        label: Text(
                          isCustomCourse ? 'Use Course Selector' : 'Enter Custom Course Name',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.accentTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isCustomCourse) ...[
                    buildField(
                      controller: customCourseController,
                      label: 'CUSTOM COURSE NAME',
                      hintText: 'e.g., Full-Stack Web Development',
                      onChanged: (val) {
                        selectedCourse = val;
                      },
                    ),
                  ],

                  buildField(
                    controller: interestedTopicController,
                    label: 'INTERESTED TOPIC / SKILLS',
                    hintText: 'e.g., MERN Stack & Next.js',
                  ),

                  // -----------------------------------------------------------
                  // SECTION 5: Lead Source & Admission Status
                  // -----------------------------------------------------------
                  buildSectionHeader('SOURCE & ADMISSION STATUS', Icons.campaign_outlined),

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
                      child: DropdownButton<String>(
                        value: selectedLeadSource,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedLeadSource = val);
                          }
                        },
                        items: kLeadSources.map((source) {
                          return DropdownMenuItem<String>(
                            value: source,
                            child: Text(
                              source,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'ADMISSION STATUS',
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
                      child: DropdownButton<String>(
                        value: selectedAdmissionStatus,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedAdmissionStatus = val);
                          }
                        },
                        items: kAdmissionStatuses.map((st) {
                          return DropdownMenuItem<String>(
                            value: st,
                            child: Text(
                              st,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // -----------------------------------------------------------
                  // SECTION 6: Notes / Requirements
                  // -----------------------------------------------------------
                  buildSectionHeader('ADDITIONAL NOTES', Icons.note_alt_outlined),
                  buildField(
                    controller: notesController,
                    label: 'LEAD NOTES / REQUIREMENTS',
                    hintText: 'e.g., Interested in weekend batch',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 18),

                  // -----------------------------------------------------------
                  // Submit Button
                  // -----------------------------------------------------------
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
                          final whatsapp = whatsappController.text.trim().isNotEmpty
                              ? whatsappController.text.trim()
                              : phone;
                          final email = emailController.text.trim();
                          final address = addressController.text.trim();
                          final place = placeController.text.trim().isNotEmpty
                              ? placeController.text.trim()
                              : address;
                          final age = int.tryParse(ageController.text.trim());
                          final qualification = selectedQualification == 'Other' && customQualificationController.text.trim().isNotEmpty
                              ? customQualificationController.text.trim()
                              : selectedQualification;
                          final collegeName = collegeController.text.trim();
                          final currentYear = currentYearController.text.trim();
                          final interestedTopic = interestedTopicController.text.trim();
                          final finalCourse = isCustomCourse && customCourseController.text.trim().isNotEmpty
                              ? customCourseController.text.trim()
                              : selectedCourse;
                          final notes = notesController.text.trim();

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
                              'Please enter an address!',
                              Colors.orange,
                            );
                            return;
                          }
                          if (selectedDistrict.isEmpty) {
                            UiHelpers.showSnackBar(
                              sheetContext,
                              'Please select a district!',
                              Colors.orange,
                            );
                            return;
                          }
                          if (finalCourse.isEmpty) {
                            UiHelpers.showSnackBar(
                              sheetContext,
                              'Please select or enter an interested course!',
                              Colors.orange,
                            );
                            return;
                          }

                          final int employeeDbId =
                              HomeProvider.instance.state.data?.user.id ?? 1;

                          final messenger = ScaffoldMessenger.of(context);

                          Navigator.pop(sheetContext); // Close bottom sheet

                          bool isDialogShowing = true;
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
                                      'Creating lead in LMS...',
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
                              whatsappNumber: whatsapp,
                              email: email.isNotEmpty ? email : 'no-email@example.com',
                              address: address,
                              place: place,
                              districtName: selectedDistrict,
                              districtId: selectedDistrictId,
                              age: age,
                              qualification: qualification,
                              collegeName: collegeName,
                              currentYear: currentYear,
                              interestedTopic: interestedTopic,
                              interestedCourseName: finalCourse,
                              courseId: selectedCourseId,
                              leadSourceName: selectedLeadSource,
                              source: 5,
                              admissionStatus: selectedAdmissionStatus,
                              status: 1,
                              assignedEmployeeId: employeeDbId,
                              notes: notes,
                            );

                            if (isDialogShowing && context.mounted) {
                              Navigator.of(context).pop(); // Close dialog
                              isDialogShowing = false;
                            }

                            if (success) {
                              UiHelpers.showMessengerSnackBar(
                                messenger,
                                'Lead "$name" created successfully in LMS!',
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
                          'Create Lead',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
