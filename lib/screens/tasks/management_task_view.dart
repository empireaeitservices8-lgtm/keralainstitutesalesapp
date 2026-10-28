import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/task_model.dart';
import '../../providers/operations_provider.dart';
import '../../utils/helpers.dart';
import 'components/bulk_upload_sheet.dart';
import 'components/follow_up_sheet.dart';
import 'components/task_card.dart';
import 'components/task_details_sheet.dart';
import 'components/upload_institute_sheet.dart';

class ManagementTaskView extends StatefulWidget {
  final dynamic user;

  const ManagementTaskView({
    super.key,
    required this.user,
  });

  @override
  State<ManagementTaskView> createState() => _ManagementTaskViewState();
}

class _ManagementTaskViewState extends State<ManagementTaskView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _completedLeadsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);

    final provider = OperationsProvider.instance;
    // Load lists if they are empty
    if (provider.rawTasks.isEmpty && !provider.isLoadingLeads) {
      provider.fetchLeads(status: 1);
    }

    _tabController.addListener(() {
      if (_tabController.index == 1 && !_completedLeadsLoaded) {
        _completedLeadsLoaded = true;
        provider.fetchCompletedLeads();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _refreshLeads() async {
    final provider = OperationsProvider.instance;
    final activeEmployeeId = provider.selectedBdeId ?? provider.selectedBdmId ?? provider.selectedAsmId;
    
    if (_tabController.index == 0) {
      await provider.fetchLeads(
        status: 1,
        employeeId: activeEmployeeId,
        teamId: provider.selectedTeamId,
        districtId: provider.selectedDistrictId,
        isRefresh: true,
      );
      _completedLeadsLoaded = false;
    } else {
      await provider.fetchCompletedLeads(
        employeeId: activeEmployeeId,
        teamId: provider.selectedTeamId,
        districtId: provider.selectedDistrictId,
        isRefresh: true,
      );
    }
  }

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
    
    if (provider.selectedBdeId == null &&
        provider.selectedBdeEmail != null &&
        provider.selectedBdeEmail != 'All BDEs' &&
        provider.selectedBdeEmail != 'All BDMs') {
      list = list
          .where(
            (t) => t.assignedBdeEmail.toLowerCase().contains(
                  provider.selectedBdeEmail!.toLowerCase(),
                ),
          )
          .toList();
    }

    if (provider.selectedTeamId == null &&
        provider.selectedTeam != null &&
        provider.selectedTeam != 'All Teams') {
      list = list.where((t) => t.team == provider.selectedTeam).toList();
    }

    if (provider.selectedDistrictId == null &&
        provider.selectedDistrict != null &&
        provider.selectedDistrict != 'All Districts') {
      list = list
          .where((t) => t.district == provider.selectedDistrict)
          .toList();
    }
    return list;
  }

  Widget _buildTaskList(
    List<TaskModel> list, {
    required bool isPending,
    required bool isLoading,
  }) {
    if (list.isEmpty && isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentTeal),
      );
    }

    if (list.isEmpty && !isLoading) {
      return RefreshIndicator(
        onRefresh: _refreshLeads,
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
      onRefresh: _refreshLeads,
      color: AppColors.accentTeal,
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 96),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final task = list[index];

          return TaskCard(
            task: task,
            isPending: isPending,
            userRole: widget.user.role,
            onFollowUpPressed: () {
              showFollowUpBottomSheet(
                context,
                task,
                userRole: widget.user.role,
                onSaved: () async {
                  await _refreshLeads();
                },
              );
            },
            onDetailsPressed: () {
              showTaskDetailsBottomSheet(
                context,
                task,
                widget.user,
                onSubmitVisitReport: ({required remarks, required leadStatus}) async {}, // No BDE reporting action for managers
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(OperationsProvider provider) {
    final user = widget.user;
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
    final employeeList = useBdmList
        ? provider.hierarchyBdms
        : provider.hierarchyBdes;

    if (employeeList.isNotEmpty) {
      bdeOptions.addAll(employeeList.map((b) => b['name'] as String).toSet());
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
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
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
                          (opt) =>
                              opt.toLowerCase() ==
                              provider.selectedAsmEmail?.toLowerCase(),
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
                              (a) =>
                                  a['name']?.toString().toLowerCase() ==
                                  val.toLowerCase(),
                              orElse: () => <String, dynamic>{},
                            );
                            asmId = UiHelpers.parseIntNullable(asm['id']);
                          }
                          provider.setSelectedAsm(
                            val == 'All ASMs' ? null : val,
                            asmId,
                          );
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
                              (t) =>
                                  t['name']?.toString().toLowerCase() ==
                                  val.toLowerCase(),
                              orElse: () => <String, dynamic>{},
                            );
                            teamId = UiHelpers.parseIntNullable(team['id']);
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
                              (d) =>
                                  d['name']?.toString().toLowerCase() ==
                                  val.toLowerCase(),
                              orElse: () => <String, dynamic>{},
                            );
                            districtId = UiHelpers.parseIntNullable(dist['id']);
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
                              (opt) =>
                                  opt.toLowerCase() ==
                                  provider.selectedBdeEmail?.toLowerCase(),
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
                              if (value != defaultBdeLabel &&
                                  value.contains('@')) {
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
                                final employee = employeeList.firstWhere(
                                  (b) =>
                                      b['name']?.toString().toLowerCase() ==
                                      val.toLowerCase(),
                                  orElse: () => <String, dynamic>{},
                                );
                                employeeId = UiHelpers.parseIntNullable(employee['id']);
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
                                  (t) =>
                                      t['name']?.toString().toLowerCase() ==
                                      val.toLowerCase(),
                                  orElse: () => <String, dynamic>{},
                                );
                                teamId = UiHelpers.parseIntNullable(team['id']);
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
                              districtOptions.contains(
                                provider.selectedDistrict,
                              )
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
                              final dist = provider.hierarchyDistricts
                                  .firstWhere(
                                    (d) =>
                                        d['name']?.toString().toLowerCase() ==
                                        val.toLowerCase(),
                                    orElse: () => <String, dynamic>{},
                                  );
                              districtId = UiHelpers.parseIntNullable(dist['id']);
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

  @override
  Widget build(BuildContext context) {
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
              final pendingLeads = _getFilteredTasks(provider.rawTasks);
              final completedLeads = _getFilteredTasks(provider.completedTasks);

              return Column(
                children: [
                  _buildSearchAndFilters(provider),
                  if (provider.isLoadingLeads || provider.isLoadingCompletedLeads)
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
                          SizedBox(width: 8),
                          Text(
                            'Refreshing leads...',
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
                        ),
                        _buildTaskList(
                          completedLeads,
                          isPending: false,
                          isLoading: provider.isLoadingCompletedLeads,
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
      floatingActionButton: widget.user.role == 'ASM'
          ? FloatingActionButton.extended(
              heroTag: 'upload_institute_fab',
              backgroundColor: AppColors.accentTeal,
              elevation: 4,
              icon: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Upload School / Institute',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              onPressed: () {
                showUploadInstituteBottomSheet(
                  context,
                  onSuccess: () async {
                    await _refreshLeads();
                  },
                );
              },
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'upload_institute_fab',
                  backgroundColor: const Color(0xFF0F172A),
                  elevation: 4,
                  icon: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Upload School / Institute',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  onPressed: () {
                    showUploadInstituteBottomSheet(
                      context,
                      onSuccess: () async {
                        await _refreshLeads();
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'bulk_upload_leads_fab',
                  backgroundColor: AppColors.accentTeal,
                  elevation: 4,
                  icon: const Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Bulk Upload',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  onPressed: () {
                    showBulkUploadBottomSheet(
                      context,
                      onUploaded: () async {
                        await _refreshLeads();
                      },
                    );
                  },
                ),
              ],
            ),
    );
  }
}
