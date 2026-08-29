import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../models/task_model.dart';
import '../../providers/operations_provider.dart';
import '../../utils/helpers.dart';
import 'components/create_lead_sheet.dart';
import 'components/follow_up_sheet.dart';
import 'components/task_card.dart';
import 'components/task_details_sheet.dart';

class BdeTaskView extends StatefulWidget {
  final dynamic user;

  const BdeTaskView({
    super.key,
    required this.user,
  });

  @override
  State<BdeTaskView> createState() => _BdeTaskViewState();
}

class _BdeTaskViewState extends State<BdeTaskView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _completedLeadsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);

    // Initial fetch of pending leads
    OperationsProvider.instance.fetchLeads(status: 1, isRefresh: true);

    _tabController.addListener(() {
      if (_tabController.index == 1 && !_completedLeadsLoaded) {
        _completedLeadsLoaded = true;
        OperationsProvider.instance.fetchCompletedLeads(isRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshLeads() async {
    if (_tabController.index == 0) {
      await OperationsProvider.instance.fetchLeads(status: 1, isRefresh: true);
      _completedLeadsLoaded = false;
    } else {
      await OperationsProvider.instance.fetchCompletedLeads(isRefresh: true);
    }
  }

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

      await _refreshLeads();
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

  List<TaskModel> _getFilteredTasks(List<TaskModel> rawTasks) {
    final query = OperationsProvider.instance.taskSearchQuery.toLowerCase();
    if (query.isEmpty) return rawTasks;

    return rawTasks.where((task) {
      return task.studentName.toLowerCase().contains(query) ||
          task.id.toLowerCase().contains(query);
    }).toList();
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final task = list[index];

          return TaskCard(
            task: task,
            isPending: isPending,
            userRole: 'BDE',
            onFollowUpPressed: () {
              showFollowUpBottomSheet(
                context,
                task,
                userRole: 'BDE',
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
                onSubmitVisitReport: ({required remarks, required leadStatus}) async {
                  await _submitVisitReport(
                    task: task,
                    leadStatus: leadStatus,
                    remarks: remarks,
                    proofPath: 'N/A',
                    followUpDate: null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchContainer(OperationsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
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
                  _buildSearchContainer(provider),
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
      floatingActionButton: FloatingActionButton.extended(
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
        onPressed: () {
          showCreateLeadBottomSheet(
            context,
            onCreated: () {
              OperationsProvider.instance.fetchLeads(status: 1, isRefresh: true);
            },
          );
        },
      ),
    );
  }
}
