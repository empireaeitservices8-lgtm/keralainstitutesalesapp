import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/user_profile_model.dart';
import '../api/exceptions/api_exception.dart';
import '../providers/operations_provider.dart';
import '../providers/user_profile_provider.dart';

class LeaveScreen extends StatefulWidget {
  static const String path = '/leave';
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch latest leaves list and balances from API when screen is opened
    OperationsProvider.instance.fetchLeaves(isRefresh: false);
  }

  // Show dialog to apply for leave
  void _showApplyLeaveDialog(
    OperationsProvider provider,
    UserProfileModel profile,
  ) {
    String leaveType = 'Casual Leave';
    DateTime fromDate = DateTime.now().add(const Duration(days: 1));
    DateTime toDate = DateTime.now().add(const Duration(days: 1));
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.add_moderator_rounded,
                    color: AppColors.accentTeal,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Apply for Leave',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Date Selectors
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FROM DATE',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final pick = await showDatePicker(
                                    context: context,
                                    initialDate: fromDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 90),
                                    ),
                                  );
                                  if (pick != null) {
                                    setDialogState(() {
                                      fromDate = pick;
                                      if (toDate.isBefore(fromDate)) {
                                        toDate = fromDate;
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM').format(fromDate),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: AppColors.accentTeal,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TO DATE',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final pick = await showDatePicker(
                                    context: context,
                                    initialDate: toDate,
                                    firstDate: fromDate,
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 90),
                                    ),
                                  );
                                  if (pick != null) {
                                    setDialogState(() {
                                      toDate = pick;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM').format(toDate),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: AppColors.accentTeal,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Reason Text Field
                    const Text(
                      'REASON FOR LEAVE',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g., Personal errand, doctor visit',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (isSubmitting) return;
                          setDialogState(() {
                            isSubmitting = true;
                          });

                          if (reasonController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.orange,
                                content: Text(
                                  'Please state the reason for applying leave.',
                                ),
                              ),
                            );
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            return;
                          }

                          // Check for existing overlapping leaves (pending or approved)
                          final overlaps = provider.leaves.any((leave) {
                            if (leave.status == 'Rejected') return false;

                            final startA = fromDate;
                            final endA = toDate;
                            final startB = leave.fromDate;
                            final endB = leave.toDate;

                            final dayStartA = DateTime(
                              startA.year,
                              startA.month,
                              startA.day,
                            );
                            final dayEndA = DateTime(
                              endA.year,
                              endA.month,
                              endA.day,
                            );
                            final dayStartB = DateTime(
                              startB.year,
                              startB.month,
                              startB.day,
                            );
                            final dayEndB = DateTime(
                              endB.year,
                              endB.month,
                              endB.day,
                            );

                            return (dayStartA.isBefore(dayEndB) ||
                                    dayStartA.isAtSameMomentAs(dayEndB)) &&
                                (dayStartB.isBefore(dayEndA) ||
                                    dayStartB.isAtSameMomentAs(dayEndA));
                          });

                          if (overlaps) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.orange,
                                content: Text(
                                  'You already have a pending or approved leave during these dates.',
                                ),
                              ),
                            );
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            return;
                          }

                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          // Pop the dialog immediately
                          navigator.pop();

                          try {
                            final success = await provider.applyLeave(
                              leaveType,
                              fromDate,
                              toDate,
                              reasonController.text,
                            );

                            if (success) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text('Leave applied successfully!'),
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  content: Text(
                                    'Failed to apply. Insufficient leave balance.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            String userMessage =
                                'An error occurred. Please try again.';
                            if (e is ApiException) {
                              userMessage = e.message.replaceAll(
                                'Validation Error: ',
                                '',
                              );
                            } else {
                              userMessage = e.toString();
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.redAccent,
                                content: Text(userMessage),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserProfileProvider.instance,
      builder: (context, _) {
        final profileState = UserProfileProvider.instance.state;

        final profile =
            profileState.data ??
            UserProfileModel(
              name: 'Guest User',
              designation: 'BDE',
              email: '',
              contactNumber: '',
              employeeId: '',
              leaveBalances: LeaveBalances(casual: 0, medical: 0, earned: 0),
            );

        return ListenableBuilder(
          listenable: OperationsProvider.instance,
          builder: (context, _) {
            final provider = OperationsProvider.instance;
            final list = provider.leaves;

            return Scaffold(
              backgroundColor: AppColors.primaryDark,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: AppColors.textPrimary),
                title: const Text(
                  'MY LEAVE APPLICATIONS',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                centerTitle: true,
              ),
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: AppColors.accentTeal,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Apply Leave',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  final totalLeave =
                      profile.leaveBalances.casual +
                      profile.leaveBalances.medical +
                      profile.leaveBalances.earned;
                  if (totalLeave <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text(
                          "You don't have any leave balance remaining.",
                        ),
                      ),
                    );
                    return;
                  }
                  _showApplyLeaveDialog(provider, profile);
                },
              ),
              body: RefreshIndicator(
                color: AppColors.accentTeal,
                onRefresh: () async {
                  await UserProfileProvider.instance.fetchUserProfile(
                    isRefresh: true,
                  );
                  await OperationsProvider.instance.loadOperationsData(
                    isRefresh: true,
                  );
                },
                child: Column(
                  children: [
                    // Premium Leave Balances Header Card
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildHeaderBalanceItem(
                                'Casual',
                                profile.leaveBalances.casual,
                                Colors.blue,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFFE2E8F0),
                              ),
                              _buildHeaderBalanceItem(
                                'Medical',
                                profile.leaveBalances.medical,
                                Colors.orange,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFFE2E8F0),
                              ),
                              _buildHeaderBalanceItem(
                                'Earned',
                                profile.leaveBalances.earned,
                                Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Leaves list area
                    Expanded(
                      child: list.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    'No leave applications found.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 80,
                              ),
                              itemCount: list.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final leave = list[index];
                                final formattedAppliedDate = DateFormat(
                                  'dd MMM yyyy',
                                ).format(leave.appliedDate);
                                final formattedFrom = DateFormat(
                                  'dd MMM',
                                ).format(leave.fromDate);
                                final formattedTo = DateFormat(
                                  'dd MMM yyyy',
                                ).format(leave.toDate);
                                final durationDays =
                                    leave.toDate
                                        .difference(leave.fromDate)
                                        .inDays +
                                    1;

                                Color statusColor = Colors.orange;
                                if (leave.status == 'Approved') {
                                  statusColor = Colors.teal;
                                } else if (leave.status == 'Rejected') {
                                  statusColor = Colors.redAccent;
                                }

                                Color typeColor = Colors.blue;
                                if (leave.leaveType == 'Medical Leave') {
                                  typeColor = Colors.orange;
                                } else if (leave.leaveType == 'Earned Leave') {
                                  typeColor = Colors.purple;
                                }

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.01),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: typeColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  leave.leaveType.toUpperCase(),
                                                  style: TextStyle(
                                                    color: typeColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(
                                                  0.08,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                leave.status.toUpperCase(),
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          '$formattedFrom - $formattedTo ($durationDays ${durationDays == 1 ? 'day' : 'days'})',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          leave.reason,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Divider(
                                          color: Color(0xFFE2E8F0),
                                          height: 24,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Applied on: $formattedAppliedDate',
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                            Text(
                                              'ID: ${leave.id}',
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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

  Widget _buildHeaderBalanceItem(String title, int days, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$days',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Days Left',
          style: TextStyle(color: AppColors.textMuted, fontSize: 8),
        ),
      ],
    );
  }
}
