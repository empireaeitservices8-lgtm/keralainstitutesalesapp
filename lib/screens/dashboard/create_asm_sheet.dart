import '../../models/home_dashboard_model.dart';
import '../../providers/home_provider.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../providers/operations_provider.dart';
import '../../utils/helpers.dart';

void showCreateAsmSheet(BuildContext context, {List<HomeTeamItem>? teams}) {
  // Ensure zones and districts are loaded from API
  if (OperationsProvider.instance.zones.isEmpty) {
    OperationsProvider.instance.fetchZones();
  }

  final List<HomeTeamItem> effectiveTeams = (teams != null && teams.isNotEmpty)
      ? teams
      : (HomeProvider.instance.state.data?.teams ?? const <HomeTeamItem>[]);

  final List<HomeTeamItem> fallbackTeams = const [
    HomeTeamItem(teamName: 'TVM', district: 'Thiruvananthapuram, Kollam'),
    HomeTeamItem(teamName: 'PTM', district: 'Pathanamthitta, Alappuzha'),
    HomeTeamItem(teamName: 'KTM', district: 'Kottayam, Idukki'),
    HomeTeamItem(teamName: 'EKM', district: 'Ernakulam'),
    HomeTeamItem(teamName: 'PKD', district: 'Thrissur, Palakkad'),
    HomeTeamItem(teamName: 'CLT', district: 'Malappuram, Kozhikode, Wayanad'),
    HomeTeamItem(teamName: 'KZD', district: 'Kannur, Kasaragod'),
    HomeTeamItem(
      teamName: 'Office Team',
      district: 'Direct Admissions, Re-admissions',
    ),
  ];

  final List<HomeTeamItem> finalTeams = effectiveTeams.isNotEmpty
      ? effectiveTeams
      : fallbackTeams;

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final asmIdController = TextEditingController();
  final salaryController = TextEditingController();
  final incentiveController = TextEditingController();
  final monthlyTargetController = TextEditingController();
  final dailyTargetController = TextEditingController();

  String? selectedZone;
  String? selectedTeamCode;
  bool isPasswordVisible = false;
  String? serverValidationMessage;
  bool isSubmitting = false;

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
                                  color: const Color(
                                    0xFF0F766E,
                                  ).withOpacity(0.12),
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
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 22),

                    if (serverValidationMessage != null &&
                        serverValidationMessage!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                serverValidationMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setModalState(
                                () => serverValidationMessage = null,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF991B1B),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

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
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                          color: Color(0xFF0F766E),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0F766E),
                            width: 1.5,
                          ),
                        ),
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
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          size: 20,
                          color: Color(0xFF0F766E),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0F766E),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter official email';
                        }
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
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
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          size: 20,
                          color: Color(0xFF0F766E),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0F766E),
                            width: 1.5,
                          ),
                        ),
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

                    // ASM ID
                    // TextFormField(
                    //   controller: asmIdController,
                    //   textInputAction: TextInputAction.next,
                    //   keyboardType: TextInputType.text,
                    //   decoration: InputDecoration(
                    //     labelText: 'ASM ID (optional)',
                    //     hintText: 'e.g. ASM004 (auto-assigned if blank)',
                    //     hintStyle: const TextStyle(
                    //       fontSize: 13,
                    //       color: Color(0xFF94A3B8),
                    //     ),
                    //     prefixIcon: const Icon(
                    //       Icons.badge_outlined,
                    //       size: 20,
                    //       color: Color(0xFF0F766E),
                    //     ),
                    //     filled: true,
                    //     fillColor: const Color(0xFFF8FAFC),
                    //     contentPadding: const EdgeInsets.symmetric(
                    //       horizontal: 14,
                    //       vertical: 14,
                    //     ),
                    //     border: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //       borderSide: const BorderSide(
                    //         color: Color(0xFFCBD5E1),
                    //       ),
                    //     ),
                    //     enabledBorder: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //       borderSide: const BorderSide(
                    //         color: Color(0xFFE2E8F0),
                    //       ),
                    //     ),
                    //     focusedBorder: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //       borderSide: const BorderSide(
                    //         color: Color(0xFF0F766E),
                    //         width: 1.5,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 12),

                    // Salary & Incentive (side by side)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 340;
                        Widget salaryField() => TextFormField(
                          controller: salaryController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Salary',
                            hintText: 'e.g. 25000',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.currency_rupee_rounded,
                              size: 20,
                              color: Color(0xFF0F766E),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0F766E),
                                width: 1.5,
                              ),
                            ),
                          ),
                        );
                        Widget incentiveField() => TextFormField(
                          controller: incentiveController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Incentive',
                            hintText: 'e.g. 1000',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.card_giftcard_rounded,
                              size: 20,
                              color: Color(0xFF0F766E),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0F766E),
                                width: 1.5,
                              ),
                            ),
                          ),
                        );
                        if (isCompact) {
                          return Column(
                            children: [
                              salaryField(),
                              const SizedBox(height: 12),
                              incentiveField(),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: salaryField()),
                            const SizedBox(width: 12),
                            Expanded(child: incentiveField()),
                          ],
                        );
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
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: Color(0xFF0F766E),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0F766E),
                            width: 1.5,
                          ),
                        ),
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
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.groups_outlined,
                          size: 20,
                          color: Color(0xFF0F766E),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0F766E),
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: finalTeams.map((team) {
                        return DropdownMenuItem<String>(
                          value: team.teamName,
                          child: Text(
                            team.dropdownDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return finalTeams.map((team) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              team.dropdownDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
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
                        setModalState(() {
                          selectedTeamCode = val;
                          if (val != null) {
                            selectedZone = OperationsProvider.instance
                                .getDefaultZoneForTeam(val);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 18),

                    // SECTION 3: Targets
                    _buildSectionHeader('3. PERFORMANCE TARGETS'),
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
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 45',
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.flag_outlined,
                                    size: 18,
                                    color: Color(0xFF0F766E),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 38,
                                    minHeight: 38,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0F766E),
                                      width: 1.5,
                                    ),
                                  ),
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
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 12',
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.today_outlined,
                                    size: 18,
                                    color: Color(0xFF0F766E),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 38,
                                    minHeight: 38,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0F766E),
                                      width: 1.5,
                                    ),
                                  ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  // Validate Form fields
                                  final isValid =
                                      formKey.currentState?.validate() ?? false;

                                  if (!isValid) {
                                    UiHelpers.showSnackBar(
                                      context,
                                      'Please fill in all required fields accurately.',
                                      Colors.redAccent,
                                    );
                                    return;
                                  }

                                  if (selectedTeamCode == null ||
                                      selectedTeamCode!.trim().isEmpty) {
                                    UiHelpers.showSnackBar(
                                      context,
                                      'Please select a Team Code.',
                                      Colors.redAccent,
                                    );
                                    return;
                                  }

                                  final name = nameController.text.trim();
                                  final email = emailController.text.trim();
                                  final phone = phoneController.text.trim();
                                  final password = passwordController.text
                                      .trim();
                                  final asmId = asmIdController.text.trim();
                                  final salary =
                                      int.tryParse(
                                        salaryController.text.trim(),
                                      ) ??
                                      0;
                                  final incentive =
                                      int.tryParse(
                                        incentiveController.text.trim(),
                                      ) ??
                                      0;
                                  final mTarget =
                                      int.tryParse(
                                        monthlyTargetController.text.trim(),
                                      ) ??
                                      45;
                                  final dTarget =
                                      int.tryParse(
                                        dailyTargetController.text.trim(),
                                      ) ??
                                      12;

                                  setModalState(() => isSubmitting = true);

                                  final res = await OperationsProvider.instance
                                      .createAsm(
                                        name: name,
                                        email: email,
                                        phone: phone,
                                        teamCode: selectedTeamCode!,
                                        password: password,
                                        zone: selectedZone,
                                        monthlyTarget: mTarget,
                                        dailyTarget: dTarget,
                                        asmId: asmId.isNotEmpty ? asmId : null,
                                        salary: salary,
                                        incentive: incentive,
                                      );

                                  if (ctx.mounted) {
                                    final bool success = res['success'] == true;
                                    final String message =
                                        res['message']?.toString() ??
                                        (success
                                            ? 'ASM $name created successfully!'
                                            : 'Failed to create ASM. Please try again.');

                                    if (success) {
                                      Navigator.pop(ctx);
                                      HomeProvider.instance.setCurrentIndex(0);
                                      UiHelpers.showSnackBar(
                                        context,
                                        message,
                                        Colors.green,
                                      );
                                    } else {
                                      setModalState(() {
                                        isSubmitting = false;
                                        serverValidationMessage = message;
                                      });
                                      UiHelpers.showToast(
                                        message,
                                        isError: true,
                                        context: ctx,
                                      );
                                    }
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Create Area Sales Manager',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
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
