import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/wallet_approval_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/operations_provider.dart';
import '../../utils/helpers.dart';

class RequestsApprovalsScreen extends StatefulWidget {
  static const String path = '/requests-approvals';
  const RequestsApprovalsScreen({super.key});

  @override
  State<RequestsApprovalsScreen> createState() =>
      _RequestsApprovalsScreenState();
}

class _RequestsApprovalsScreenState extends State<RequestsApprovalsScreen> {
  String _selectedFilter =
      'All'; // 'All', 'Pending', 'Approved', 'Paid', 'Rejected'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (OperationsProvider.instance.walletApprovalRequests.isEmpty) {
      OperationsProvider.instance.fetchWalletApprovalRequests();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthProvider.instance.session;
    final isAsm =
        user.role.toUpperCase() == 'ASM' ||
        user.role.toLowerCase().contains('area');
    final isSm =
        !isAsm &&
        (user.role.toUpperCase() == 'SM' ||
            user.role.toLowerCase().contains('sales manager'));
    final isAccounts =
        user.role.toUpperCase() == 'ACCOUNTS' ||
        user.role.toUpperCase() == 'ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Requests & Approvals',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'BDE & Regional Incentive Payout Workflow',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF0F766E),
              size: 22,
            ),
            tooltip: 'Refresh Requests',
            onPressed: () {
              OperationsProvider.instance.fetchWalletApprovalRequests(
                isRefresh: true,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: OperationsProvider.instance,
        builder: (context, _) {
          final provider = OperationsProvider.instance;
          final allRequests = provider.walletApprovalRequests;
          final summary =
              provider.walletApprovalSummary ??
              WalletApprovalSummary(
                total: allRequests.length,
                pending: allRequests.where((r) => r.isPending).length,
                approved: allRequests.where((r) => r.isApproved).length,
                paid: allRequests.where((r) => r.isPaid).length,
                rejected: allRequests.where((r) => r.isRejected).length,
                pendingAmount: allRequests
                    .where((r) => r.isPending)
                    .fold<num>(0, (sum, r) => sum + r.amount),
              );

          // Apply Filter
          List<WalletApprovalRequestItem> filtered = allRequests.where((r) {
            if (_selectedFilter == 'Pending') return r.isPending;
            if (_selectedFilter == 'Approved')
              return r.isApproved ||
                  r.status.toLowerCase().contains('forwarded to accounts');
            if (_selectedFilter == 'Paid') return r.isPaid;
            if (_selectedFilter == 'Rejected') return r.isRejected;
            return true;
          }).toList();

          // Apply Search
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            filtered = filtered.where((r) {
              return r.employee.toLowerCase().contains(q) ||
                  r.employeeId.toLowerCase().contains(q) ||
                  r.requestId.toLowerCase().contains(q) ||
                  r.team.toLowerCase().contains(q) ||
                  (r.asmName?.toLowerCase().contains(q) ?? false);
            }).toList();
          }

          return RefreshIndicator(
            color: const Color(0xFF0F766E),
            onRefresh: () async {
              await provider.fetchWalletApprovalRequests(isRefresh: true);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // 1. Summary Metrics Banner
                _buildSummaryBanner(summary),
                const SizedBox(height: 14),

                // 2. Search Box
                _buildSearchField(),
                const SizedBox(height: 12),

                // 3. Status Filters
                _buildFilterChips(summary),
                const SizedBox(height: 14),

                if (provider.isLoadingWalletRequests)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                      child: LinearProgressIndicator(
                        minHeight: 2.5,
                        color: Color(0xFF0F766E),
                        backgroundColor: Color(0xFFCCFBF1),
                      ),
                    ),
                  ),

                // 4. Requests List
                if (provider.isLoadingWalletRequests && allRequests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  _buildEmptyState()
                else
                  ...filtered.map(
                    (item) => _buildRequestCard(
                      context,
                      item: item,
                      provider: provider,
                      isAsm: isAsm,
                      isSm: isSm,
                      isAccounts: isAccounts,
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // Summary Metrics Banner
  Widget _buildSummaryBanner(WalletApprovalSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF2DD4BF),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'INCENTIVE PAYOUT PIPELINE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  'Pending: ${summary.formattedPendingAmount}',
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMetricItem('TOTAL', '${summary.total}', Colors.white),
              _buildMetricDivider(),
              _buildMetricItem(
                'PENDING',
                '${summary.pending}',
                const Color(0xFFF59E0B),
              ),
              _buildMetricDivider(),
              _buildMetricItem(
                'APPROVED',
                '${summary.approved}',
                const Color(0xFF38BDF8),
              ),
              _buildMetricDivider(),
              _buildMetricItem(
                'PAID',
                '${summary.paid}',
                const Color(0xFF4ADE80),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 26,
      color: Colors.white.withOpacity(0.15),
    );
  }

  // Search Field
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by employee, BDE ID, Request ID...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF64748B),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // Filter Chips
  Widget _buildFilterChips(WalletApprovalSummary summary) {
    final filters = [
      {'label': 'All', 'count': summary.total},
      {'label': 'Pending', 'count': summary.pending},
      {'label': 'Approved', 'count': summary.approved},
      {'label': 'Paid', 'count': summary.paid},
      {'label': 'Rejected', 'count': summary.rejected},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final label = f['label'] as String;
          final count = f['count'] as int;
          final isSelected = _selectedFilter == label;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$label ($count)'),
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF0F766E),
              backgroundColor: Colors.white,
              elevation: isSelected ? 1 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0F766E)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = label;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 38,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Requests Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'No payout requests match "$_searchQuery".'
                : 'There are no $_selectedFilter requests at this time.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // Request Card
  Widget _buildRequestCard(
    BuildContext context, {
    required WalletApprovalRequestItem item,
    required OperationsProvider provider,
    required bool isAsm,
    required bool isSm,
    required bool isAccounts,
  }) {
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;

    if (item.isPaid) {
      statusBgColor = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF15803D);
      statusIcon = Icons.check_circle_rounded;
    } else if (item.isApproved) {
      statusBgColor = const Color(0xFFE0F2FE);
      statusTextColor = const Color(0xFF0284C7);
      statusIcon = Icons.verified_rounded;
    } else if (item.isForwardedToSm) {
      statusBgColor = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFD97706);
      statusIcon = Icons.forward_to_inbox_rounded;
    } else if (item.isRejected) {
      statusBgColor = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFDC2626);
      statusIcon = Icons.cancel_rounded;
    } else {
      statusBgColor = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFD97706);
      statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.requestId,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F766E),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.team,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 12, color: statusTextColor),
                      const SizedBox(width: 4),
                      Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: statusTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Employee Details & Requested Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.employee,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${item.employeeId})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.designation,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (item.asmName != null &&
                              item.asmName!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.supervisor_account_rounded,
                                  size: 14,
                                  color: Color(0xFF0F766E),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ASM: ${item.asmName} (${item.asmId ?? ''})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'REQUESTED',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          item.formattedAmount,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Bal: ${item.formattedBalance}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Remarks box if any
                if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.comment_outlined,
                          size: 15,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.remarks!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF334155),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Approval History Timeline
                if (item.approvalHistory.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildHistoryAccordion(item.approvalHistory),
                ],

                // Action Buttons
                const SizedBox(height: 14),
                _buildActionButtons(
                  context,
                  item: item,
                  provider: provider,
                  isAsm: isAsm,
                  isSm: isSm,
                  isAccounts: isAccounts,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Approval History Timeline
  Widget _buildHistoryAccordion(List<WalletApprovalStage> history) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 14, color: Color(0xFF475569)),
              SizedBox(width: 6),
              Text(
                'APPROVAL AUDIT TRAIL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...history.map((stage) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F766E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              stage.stage,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 7),
                            if (stage.actionAt != null)
                              Text(
                                _formatDate(stage.actionAt!),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                        if (stage.remarks != null && stage.remarks!.isNotEmpty)
                          Text(
                            '${stage.actionBy}: "${stage.remarks}"',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF475569),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  // Action Buttons
  Widget _buildActionButtons(
    BuildContext context, {
    required WalletApprovalRequestItem item,
    required OperationsProvider provider,
    required bool isAsm,
    required bool isSm,
    required bool isAccounts,
  }) {
    // If already paid or rejected
    if (item.isPaid || item.isRejected) {
      return const SizedBox.shrink();
    }

    // ASM Action: Forward to SM
    if (isAsm && item.isPending && !item.isForwardedToSm) {
      return SizedBox(
        width: double.infinity,
        height: 42,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.forward_to_inbox_rounded, size: 18),
          label: const Text(
            'Verify & Forward to SM',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _showForwardDialog(
            context,
            title: 'Forward to State Sales Manager',
            subtitle:
                'Forward ${item.employee}\'s request of ${item.formattedAmount} to SM for approval.',
            defaultNotes: 'ASM verified admissions & recommended.',
            onConfirm: (notes) async {
              final ok = await provider.forwardWalletRequestToSm(
                item.id,
                remarks: notes,
              );
              if (context.mounted) {
                if (ok) {
                  UiHelpers.showSnackBar(
                    context,
                    'Request forwarded to SM!',
                    Colors.green,
                  );
                } else {
                  UiHelpers.showSnackBar(
                    context,
                    'Failed to forward request',
                    Colors.redAccent,
                  );
                }
              }
            },
          ),
        ),
      );
    }

    // SM Action: Forward to Accounts
    if (isSm && item.isPending) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text(
                  'Forward to Accounts',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showForwardDialog(
                  context,
                  title: 'Forward to Accounts Team',
                  subtitle:
                      'Approve & forward ${item.employee}\'s payout of ${item.formattedAmount} to Accounts for disbursement.',
                  defaultNotes:
                      'Verified admissions and eligibility. Forwarded to Accounts for sanction.',
                  onConfirm: (notes) async {
                    final ok = await provider.forwardWalletRequestToAccounts(
                      item.requestId.isNotEmpty ? item.requestId : item.id,
                      remarks: notes,
                    );
                    if (context.mounted) {
                      if (ok) {
                        UiHelpers.showSnackBar(
                          context,
                          'Withdrawal request status updated to "Forwarded to Accounts".',
                          Colors.green,
                        );
                      } else {
                        UiHelpers.showSnackBar(
                          context,
                          'Failed to forward request to Accounts',
                          Colors.redAccent,
                        );
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Accounts / Admin Action: Disburse Payment
    if (isAccounts && !item.isPaid) {
      return SizedBox(
        width: double.infinity,
        height: 42,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF15803D),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.payments_rounded, size: 18),
          label: const Text(
            'Disburse Payout with UTR',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          onPressed: () =>
              _showDisburseDialog(context, item: item, provider: provider),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showForwardDialog(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String defaultNotes,
    required Function(String notes) onConfirm,
  }) {
    final notesCtrl = TextEditingController(text: defaultNotes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes / Remarks',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm(notesCtrl.text.trim());
            },
            child: const Text(
              'Confirm & Forward',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDisburseDialog(
    BuildContext context, {
    required WalletApprovalRequestItem item,
    required OperationsProvider provider,
  }) {
    final utrCtrl = TextEditingController(
      text:
          'UTR${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}',
    );
    final notesCtrl = TextEditingController(
      text: 'Disbursed to ${item.employee}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Disburse Incentive Payout',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disburse ${item.formattedAmount} to ${item.employee} (${item.employeeId}).',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: utrCtrl,
              decoration: InputDecoration(
                labelText: 'Bank UTR / Transaction ID *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                labelText: 'Disbursement Notes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final utr = utrCtrl.text.trim();
              if (utr.isEmpty) {
                UiHelpers.showSnackBar(
                  context,
                  'Please enter UTR / Transaction ID',
                  Colors.redAccent,
                );
                return;
              }
              Navigator.pop(ctx);
              final ok = await provider.disburseWalletRequest(
                item.id,
                transactionId: utr,
                notes: notesCtrl.text.trim(),
              );
              if (context.mounted) {
                if (ok) {
                  UiHelpers.showSnackBar(
                    context,
                    'Payout disbursed successfully with UTR $utr!',
                    Colors.green,
                  );
                } else {
                  UiHelpers.showSnackBar(
                    context,
                    'Failed to disburse payout',
                    Colors.redAccent,
                  );
                }
              }
            },
            child: const Text(
              'Confirm Disbursement',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
