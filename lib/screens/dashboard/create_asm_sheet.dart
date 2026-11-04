import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/zone_model.dart';
import '../../providers/operations_provider.dart';
import '../../utils/helpers.dart';

void showCreateAsmSheet(BuildContext context) {
  // Ensure zones and districts are loaded from API
  if (OperationsProvider.instance.zones.isEmpty) {
    OperationsProvider.instance.fetchZones();
  }
  if (OperationsProvider.instance.districtsList.isEmpty) {
    OperationsProvider.instance.fetchDistricts();
  }

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final monthlyTargetController = TextEditingController();
  final dailyTargetController = TextEditingController();

  String? selectedZone;
  String? selectedTeamCode;
  final Set<String> selectedDistricts = {};
  bool isPasswordVisible = false;
  bool isSubmitting = false;
  String? districtValidationError;

  final Map<String, String> defaultZoneTeamCode = {
    'South Zone': 'TVM',
    'Central Zone': 'EKM',
    'North Zone': 'CLT',
  };

  final List<String> allDistricts = OperationsProvider.instance.allDistrictNames;
  final List<String> availableZones = OperationsProvider.instance.zoneNames;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: keyboardPadding > 0 ? keyboardPadding + 16 : 24,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pull Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E).withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: Color(0xFF0F766E),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create New ASM',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Add Regional Area Sales Manager to Kerala Team',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 22),

                    // SECTION 1: Personal & Contact Info
                    _buildSectionHeader('1. PERSONAL & CONTACT DETAILS'),
                    const SizedBox(height: 10),

                    // Full Name
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.name,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'Enter full name (e.g. Bipin Joseph)',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF0F766E)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter ASM name';
                        }
                        if (val.trim().length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Official Email
                    TextFormField(
                      controller: emailController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: 'Official Email *',
                        hintText: 'e.g. bipin.tvm@kide.com',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFF0F766E)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter official email';
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(val.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Contact Number
                    TextFormField(
                      controller: phoneController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: 'Contact Number *',
                        hintText: 'e.g. +91 90000 00001 or 9000000001',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF0F766E)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter contact number';
                        }
                        final cleaned = val.replaceAll(RegExp(r'[\s\-\+]'), '');
                        if (cleaned.length < 10) {
                          return 'Enter a valid mobile number (min 10 digits)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // SECTION 2: Security & Team
                    _buildSectionHeader('2. SECURITY & TEAM CODE'),
                    const SizedBox(height: 10),

                    // Password with Show/Hide toggle
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: 'Initial Password *',
                        hintText: 'Enter password (min 6 characters)',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF0F766E)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            color: const Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please set an initial password';
                        }
                        if (val.trim().length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Team Code Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedTeamCode,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Team Code *',
                        hintText: 'Select Team Code',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.groups_outlined, size: 20, color: Color(0xFF0F766E)),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'TVM',
                          child: Text(
                            'TVM Team (Thiruvananthapuram & South)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'PTM',
                          child: Text(
                            'PTM Team (Pathanamthitta)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'KTM',
                          child: Text(
                            'KTM Team (Kottayam & Idukki)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'EKM',
                          child: Text(
                            'EKM Team (Ernakulam Hub)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'PKD',
                          child: Text(
                            'PKD Team (Palakkad & Thrissur)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'CLT',
                          child: Text(
                            'CLT Team (Kozhikode & Malappuram)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'KZD',
                          child: Text(
                            'KZD Team (Kannur, Wayanad & Kasaragod)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'OFFICE',
                          child: Text(
                            'OFFICE Team (Central Operations)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                      selectedItemBuilder: (BuildContext context) {
                        final labelMap = {
                          'TVM': 'TVM Team (Thiruvananthapuram & South)',
                          'PTM': 'PTM Team (Pathanamthitta)',
                          'KTM': 'KTM Team (Kottayam & Idukki)',
                          'EKM': 'EKM Team (Ernakulam Hub)',
                          'PKD': 'PKD Team (Palakkad & Thrissur)',
                          'CLT': 'CLT Team (Kozhikode & Malappuram)',
                          'KZD': 'KZD Team (Kannur, Wayanad & Kasaragod)',
                          'OFFICE': 'OFFICE Team (Central Operations)',
                        };
                        return [
                          'TVM', 'PTM', 'KTM', 'EKM', 'PKD', 'CLT', 'KZD', 'OFFICE'
                        ].map((code) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              labelMap[code] ?? code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                          );
                        }).toList();
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please select a team code';
                        }
                        return null;
                      },
                      onChanged: (val) {
                        setModalState(() => selectedTeamCode = val);
                      },
                    ),
                    const SizedBox(height: 18),

                    // SECTION 3: Territory & Jurisdiction
                    _buildSectionHeader('3. TERRITORY & JURISDICTION'),
                    const SizedBox(height: 10),

                    // Assigned Zone Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedZone,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Assigned Zone *',
                        hintText: 'Select Operational Zone',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.map_outlined, size: 20, color: Color(0xFF0F766E)),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                      ),
                      items: availableZones.map((zoneName) {
                        final desc = OperationsProvider.instance.zones
                            .firstWhere(
                              (z) => z.name == zoneName,
                              orElse: () => ZoneModel(id: '', name: zoneName),
                            )
                            .description;
                        return DropdownMenuItem(
                          value: zoneName,
                          child: Text(
                            desc.isNotEmpty ? '$zoneName ($desc)' : zoneName,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return availableZones.map((zoneName) {
                          final desc = OperationsProvider.instance.zones
                              .firstWhere(
                                (z) => z.name == zoneName,
                                orElse: () => ZoneModel(id: '', name: zoneName),
                              )
                              .description;
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              desc.isNotEmpty ? '$zoneName ($desc)' : zoneName,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList();
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please assign an operational zone';
                        }
                        return null;
                      },
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedZone = val;
                            if (selectedTeamCode == null || selectedTeamCode!.isEmpty) {
                              selectedTeamCode = defaultZoneTeamCode[val];
                            }
                            // Auto-populate default districts for this zone from API mapping
                            selectedDistricts.clear();
                            selectedDistricts.addAll(OperationsProvider.instance.getDistrictNamesByZone(val));
                            districtValidationError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // District Selection Helper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ASSIGNED DISTRICTS *',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (selectedZone != null)
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedDistricts.addAll(OperationsProvider.instance.getDistrictNamesByZone(selectedZone));
                                    districtValidationError = null;
                                  });
                                },
                                child: Text(
                                  'Select All $selectedZone',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                                ),
                              ),
                            if (selectedDistricts.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedDistricts.clear();
                                  });
                                },
                                child: const Text(
                                  'Clear All',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: allDistricts.map((dist) {
                        final isSel = selectedDistricts.contains(dist);
                        final isZoneMatch = selectedZone != null &&
                            OperationsProvider.instance.getDistrictNamesByZone(selectedZone).contains(dist);

                        return FilterChip(
                          label: Text(
                            dist,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isSel ? Colors.white : (isZoneMatch ? const Color(0xFF0F766E) : const Color(0xFF334155)),
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: const Color(0xFF0F766E),
                          backgroundColor: isZoneMatch ? const Color(0xFFF0FDFA) : const Color(0xFFF1F5F9),
                          checkmarkColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSel
                                  ? const Color(0xFF0F766E)
                                  : (isZoneMatch ? const Color(0xFF99F6E4) : const Color(0xFFCBD5E1)),
                            ),
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedDistricts.add(dist);
                                districtValidationError = null;
                              } else {
                                selectedDistricts.remove(dist);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (districtValidationError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        districtValidationError!,
                        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // SECTION 4: Targets
                    _buildSectionHeader('4. PERFORMANCE TARGETS'),
                    const SizedBox(height: 10),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 340;

                        Widget buildMonthlyField() {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Monthly Target (Leads) *',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: monthlyTargetController,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.number,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 45',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.flag_outlined, size: 18, color: Color(0xFF0F766E)),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Enter target';
                                  }
                                  final n = int.tryParse(val.trim());
                                  if (n == null || n <= 0) {
                                    return 'Must be > 0';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          );
                        }

                        Widget buildDailyField() {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Daily Target (Leads) *',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: dailyTargetController,
                                textInputAction: TextInputAction.done,
                                keyboardType: TextInputType.number,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 12',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.today_outlined, size: 18, color: Color(0xFF0F766E)),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Enter daily target';
                                  }
                                  final n = int.tryParse(val.trim());
                                  if (n == null || n <= 0) {
                                    return 'Must be > 0';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          );
                        }

                        if (isCompact) {
                          return Column(
                            children: [
                              buildMonthlyField(),
                              const SizedBox(height: 12),
                              buildDailyField(),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: buildMonthlyField()),
                            const SizedBox(width: 12),
                            Expanded(child: buildDailyField()),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF1E3A8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F766E).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  // Validate Form fields
                                  final isValid = formKey.currentState?.validate() ?? false;

                                  // Validate District selection
                                  if (selectedDistricts.isEmpty) {
                                    setModalState(() {
                                      districtValidationError = 'Please select at least one assigned district.';
                                    });
                                  } else {
                                    setModalState(() {
                                      districtValidationError = null;
                                    });
                                  }

                                  if (!isValid || selectedDistricts.isEmpty) {
                                    UiHelpers.showSnackBar(
                                      context,
                                      'Please fill in all required fields accurately.',
                                      Colors.redAccent,
                                    );
                                    return;
                                  }

                                  final name = nameController.text.trim();
                                  final email = emailController.text.trim();
                                  final phone = phoneController.text.trim();
                                  final password = passwordController.text.trim();
                                  final mTarget = int.parse(monthlyTargetController.text.trim());
                                  final dTarget = int.parse(dailyTargetController.text.trim());

                                  setModalState(() => isSubmitting = true);

                                  final success = await OperationsProvider.instance.createAsm(
                                    name: name,
                                    email: email,
                                    phone: phone,
                                    teamCode: selectedTeamCode!,
                                    password: password,
                                    zone: selectedZone!,
                                    districts: selectedDistricts.toList(),
                                    monthlyTarget: mTarget,
                                    dailyTarget: dTarget,
                                  );

                                  if (ctx.mounted) {
                                    if (success) {
                                      Navigator.pop(ctx);
                                      UiHelpers.showSnackBar(
                                        context,
                                        'ASM $name created & assigned to ${selectedDistricts.join(', ')}!',
                                        Colors.green,
                                      );
                                    } else {
                                      setModalState(() => isSubmitting = false);
                                      UiHelpers.showSnackBar(
                                        context,
                                        'Failed to create ASM. Please check credentials or network.',
                                        Colors.redAccent,
                                      );
                                    }
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Create Area Sales Manager',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
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
            ),
          );
        },
      );
    },
  );
}

Widget _buildSectionHeader(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      color: Color(0xFF64748B),
      letterSpacing: 0.6,
    ),
  );
}
