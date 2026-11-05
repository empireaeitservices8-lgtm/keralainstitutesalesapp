import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/asm_bde_model.dart';
import '../../models/task_model.dart';
import '../../models/wallet_approval_request_model.dart';
import '../../providers/operations_provider.dart';

class BdeDetailsScreen extends StatefulWidget {
  final AsmBdeModel bde;
  static const String path = '/bde-details';

  const BdeDetailsScreen({super.key, required this.bde});

  @override
  State<BdeDetailsScreen> createState() => _BdeDetailsScreenState();
}

class _BdeDetailsScreenState extends State<BdeDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch wallet approval requests from GET /api/wallet/requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OperationsProvider.instance.fetchWalletApprovalRequests(isRefresh: true);
    });
  }

  // Helper to copy text to clipboard
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F766E),
      ),
    );
  }

  // Call launcher
  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid contact number available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final Uri url = Uri.parse('tel:$cleaned');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not initiate call to $phoneNumber'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // WhatsApp launcher
  Future<void> _launchWhatsApp(String phoneNumber) async {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid contact number available for WhatsApp'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final formattedNumber =
        digitsOnly.length == 10 ? '91$digitsOnly' : digitsOnly;
    final Uri url = Uri.parse('https://wa.me/$formattedNumber');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Email launcher
  Future<void> _sendEmail(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email address available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final Uri url = Uri.parse('mailto:$email');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch email to $email'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Forward to SM confirmation dialog
  void _showForwardToSmDialog(
    BuildContext context, {
    required WalletApprovalRequestItem item,
    required OperationsProvider provider,
  }) {
    final notesCtrl = TextEditingController(
      text: 'ASM verified admissions & recommended.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.forward_to_inbox_rounded,
                color: Color(0xFF0F766E),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Forward to SM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forward withdrawal request ${item.requestId} (${item.formattedAmount}) for ${item.employee} to State Sales Manager (SM)?',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'ASM Recommendation / Remarks',
                hintText: 'Enter review notes...',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final notes = notesCtrl.text.trim();
              final ok = await provider.forwardWalletRequestToSm(
                item.id,
                remarks: notes.isNotEmpty
                    ? notes
                    : 'ASM verified admissions & recommended.',
              );
              if (mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Request ${item.requestId} successfully forwarded to SM!',
                      ),
                      backgroundColor: const Color(0xFF0F766E),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to forward request to SM'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OperationsProvider.instance,
      builder: (context, _) {
        final provider = OperationsProvider.instance;

        // Obtain latest data for this BDE from provider if available
        final bde = provider.asmBdes.firstWhere(
          (b) =>
              (b.id.isNotEmpty && b.id == widget.bde.id) ||
              (b.employeeId.isNotEmpty &&
                  b.employeeId.toLowerCase() ==
                      widget.bde.employeeId.toLowerCase()),
          orElse: () => widget.bde,
        );

        final bool isActive = bde.status.toLowerCase() == 'active';

        // Filter leads/tasks matching this BDE
        final assignedTasks = provider.rawTasks.where((t) {
          final matchEmail = bde.email.isNotEmpty &&
              t.assignedBdeEmail.toLowerCase() == bde.email.toLowerCase();
          final matchName = bde.name.isNotEmpty &&
              (t.employee?.toLowerCase() == bde.name.toLowerCase());
          final matchEmpId = bde.employeeId.isNotEmpty &&
              (t.employee?.toLowerCase() == bde.employeeId.toLowerCase());
          return matchEmail || matchName || matchEmpId;
        }).toList();

        // Filter wallet/incentive requests from /api/wallet/requests for this BDE
        final bdeWalletRequests = provider.walletApprovalRequests.where((r) {
          final matchEmpId = bde.employeeId.isNotEmpty &&
              r.employeeId.toLowerCase() == bde.employeeId.toLowerCase();
          final matchName = bde.name.isNotEmpty &&
              (r.employee.toLowerCase() == bde.name.toLowerCase() ||
                  r.employee.toLowerCase().contains(bde.name.toLowerCase()) ||
                  bde.name.toLowerCase().contains(r.employee.toLowerCase()));
          return matchEmpId || matchName;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bde.name.isNotEmpty ? bde.name : 'BDE Details',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  '${bde.employeeId} • ${bde.designation}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF0F766E),
                  size: 22,
                ),
                tooltip: 'Refresh BDE Details',
                onPressed: () async {
                  await provider.fetchAsmBdes(isRefresh: true);
                  await provider.fetchWalletApprovalRequests(isRefresh: true);
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.share_outlined,
                  color: Color(0xFF0F766E),
                  size: 20,
                ),
                tooltip: 'Share Profile Details',
                onPressed: () {
                  final shareText = '''
BDE Executive Profile:
Name: ${bde.name}
Employee ID: ${bde.employeeId}
Designation: ${bde.designation}
District: ${bde.district}
Zone: ${bde.zone}
Team: ${bde.team}
Reports To: ${bde.reportsTo}
Salary: ${bde.formattedSalary}
Incentive: ${bde.formattedIncentive}
Email: ${bde.email}
Phone: ${bde.contactNumber}
Total Leads: ${bde.totalLeads}
Admissions: ${bde.admissions}
Conversion Rate: ${bde.displayConversionRate}
Status: ${bde.status}
''';
                  _copyToClipboard(shareText, 'Executive details');
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: RefreshIndicator(
            color: const Color(0xFF0F766E),
            onRefresh: () async {
              await provider.fetchAsmBdes(isRefresh: true);
              await provider.fetchWalletApprovalRequests(isRefresh: true);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Executive Identity Card
                  _buildIdentityCard(bde, isActive),
                  const SizedBox(height: 16),

                  // 2. Performance & Conversion Metrics (total_leads, admissions, conversion_rate)
                  _buildPerformanceSection(bde),
                  const SizedBox(height: 16),

                  // 3. Compensation & Payouts (salary, incentive)
                  _buildCompensationSection(bde),
                  const SizedBox(height: 16),

                  // 4. INCENTIVE & WALLET REQUESTS (with "Forward to SM" button)
                  _buildWalletRequestsSection(bdeWalletRequests, provider),
                  const SizedBox(height: 16),

                  // 5. Organization, Zone & Territory Details
                  _buildSectionCard(
                    title: 'TERRITORY & REPORTING',
                    icon: Icons.account_tree_outlined,
                    children: [
                      _buildInfoRow(
                        icon: Icons.public_outlined,
                        label: 'Zone',
                        value: bde.zone.isNotEmpty ? bde.zone : 'Not Assigned',
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'District',
                        value: bde.district.isNotEmpty
                            ? bde.district
                            : 'Not Assigned',
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(
                        icon: Icons.groups_outlined,
                        label: 'Team',
                        value: bde.team.isNotEmpty ? bde.team : 'CLT Team',
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Designation',
                        value: bde.designation.isNotEmpty
                            ? bde.designation
                            : 'Business Development Executive',
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(
                        icon: Icons.supervisor_account_outlined,
                        label: 'Reports To',
                        value: bde.reportsTo.isNotEmpty
                            ? bde.reportsTo
                            : 'ASM001',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 6. Contact & System Details
                  _buildSectionCard(
                    title: 'CONTACT & SYSTEM DETAILS',
                    icon: Icons.contact_phone_outlined,
                    children: [
                      _buildActionInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        value:
                            bde.email.isNotEmpty ? bde.email : 'Not Provided',
                        actionIcon: Icons.send_outlined,
                        actionTooltip: 'Send Email',
                        onTapAction: bde.email.isNotEmpty
                            ? () => _sendEmail(bde.email)
                            : null,
                        onCopy: bde.email.isNotEmpty
                            ? () => _copyToClipboard(bde.email, 'Email address')
                            : null,
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildActionInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Contact Number',
                        value: bde.contactNumber.isNotEmpty
                            ? bde.contactNumber
                            : 'Not Provided',
                        actionIcon: Icons.call_outlined,
                        actionTooltip: 'Call BDE',
                        onTapAction: bde.contactNumber.isNotEmpty
                            ? () => _makePhoneCall(bde.contactNumber)
                            : null,
                        onCopy: bde.contactNumber.isNotEmpty
                            ? () => _copyToClipboard(
                                  bde.contactNumber,
                                  'Contact number',
                                )
                            : null,
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildActionInfoRow(
                        icon: Icons.credit_card_outlined,
                        label: 'Employee ID',
                        value: bde.employeeId.isNotEmpty
                            ? bde.employeeId
                            : 'Not Set',
                        onCopy: bde.employeeId.isNotEmpty
                            ? () => _copyToClipboard(
                                  bde.employeeId,
                                  'Employee ID',
                                )
                            : null,
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildActionInfoRow(
                        icon: Icons.fingerprint_outlined,
                        label: 'System ID',
                        value: bde.id.isNotEmpty ? bde.id : 'N/A',
                        onCopy: bde.id.isNotEmpty
                            ? () => _copyToClipboard(bde.id, 'System ID')
                            : null,
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Account Status',
                        value: bde.status.toUpperCase(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 7. Assigned Tasks / Leads
                  _buildTasksSection(assignedTasks),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Identity Header Card
  Widget _buildIdentityCard(AsmBdeModel bde, bool isActive) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF0F766E).withOpacity(0.12),
                  child: Text(
                    bde.name.isNotEmpty
                        ? bde.name.substring(0, 1).toUpperCase()
                        : 'B',
                    style: const TextStyle(
                      color: Color(0xFF0F766E),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bde.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFFECACA),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  bde.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bde.designation.isNotEmpty
                            ? bde.designation
                            : 'Business Development Executive',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bde.employeeId,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          if (bde.district.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDFA),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFCCFBF1),
                                ),
                              ),
                              child: Text(
                                bde.district,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ),
                          if (bde.zone.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: Text(
                                bde.zone,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          if (bde.team.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFE0E7FF),
                                ),
                              ),
                              child: Text(
                                bde.team,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4338CA),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildCommunicationButton(
                    icon: Icons.phone_rounded,
                    label: 'Call',
                    color: const Color(0xFF0F766E),
                    backgroundColor: const Color(0xFFF0FDFA),
                    onTap: () => _makePhoneCall(bde.contactNumber),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCommunicationButton(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF16A34A),
                    backgroundColor: const Color(0xFFF0FDF4),
                    onTap: () => _launchWhatsApp(bde.contactNumber),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCommunicationButton(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    color: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFEFF6FF),
                    onTap: () => _sendEmail(bde.email),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection(AsmBdeModel bde) {
    final double ratio = bde.totalLeads > 0
        ? (bde.admissions / bde.totalLeads).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 16,
                color: Color(0xFF0F766E),
              ),
              SizedBox(width: 6),
              Text(
                'PERFORMANCE METRICS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'TOTAL LEADS',
                  value: '${bde.totalLeads}',
                  icon: Icons.assignment_ind_outlined,
                  color: const Color(0xFF0F766E),
                  bgColor: const Color(0xFFF0FDFA),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'ADMISSIONS',
                  value: '${bde.admissions}',
                  icon: Icons.school_outlined,
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'CONVERSION',
                  value: bde.displayConversionRate,
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFF0FDF4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F766E)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Conversion Rate: ${bde.displayConversionRate}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                '${bde.admissions} / ${bde.totalLeads} Closed',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompensationSection(AsmBdeModel bde) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: Color(0xFF0F766E),
              ),
              SizedBox(width: 6),
              Text(
                'COMPENSATION & FINANCIALS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.monetization_on_outlined,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'BASE SALARY',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bde.formattedSalary,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Monthly fixed pay',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            size: 18,
                            color: Color(0xFF16A34A),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'INCENTIVE',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bde.formattedIncentive,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Performance bonus',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Incentive & Wallet Requests Section (GET /api/wallet/requests & POST /api/wallet/workflow)
  Widget _buildWalletRequestsSection(
    List<WalletApprovalRequestItem> requests,
    OperationsProvider provider,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 16,
                    color: Color(0xFF0F766E),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'INCENTIVE & WALLET REQUESTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${requests.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ],
              ),
              if (provider.isLoadingWalletRequests)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0F766E),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (requests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 32,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'No Withdrawal Requests',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'No wallet incentive requests found for this executive.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = requests[index];
                final statusStr = req.status.toLowerCase();
                final bool canForwardToSm =
                    statusStr.contains('submitted to asm') ||
                    req.status == 'Pending_ASM' ||
                    (req.isPending && !req.isForwardedToSm);

                Color statusBgColor = const Color(0xFFFEF3C7);
                Color statusTextColor = const Color(0xFFD97706);
                Color statusBorderColor = const Color(0xFFFDE68A);

                if (req.isPaid) {
                  statusBgColor = const Color(0xFFECFDF5);
                  statusTextColor = const Color(0xFF059669);
                  statusBorderColor = const Color(0xFFA7F3D0);
                } else if (statusStr.contains('accounts')) {
                  statusBgColor = const Color(0xFFEEF2FF);
                  statusTextColor = const Color(0xFF4338CA);
                  statusBorderColor = const Color(0xFFC7D2FE);
                } else if (req.isForwardedToSm) {
                  statusBgColor = const Color(0xFFEFF6FF);
                  statusTextColor = const Color(0xFF2563EB);
                  statusBorderColor = const Color(0xFFBFDBFE);
                }

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Request ID & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  req.requestId.isNotEmpty
                                      ? req.requestId
                                      : 'WDR-${req.id.substring(req.id.length > 4 ? req.id.length - 4 : 0)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                              if (req.createdAt != null &&
                                  req.createdAt!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  req.createdAt!.length > 10
                                      ? req.createdAt!.substring(0, 10)
                                      : req.createdAt!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusBorderColor),
                            ),
                            child: Text(
                              req.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: statusTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Amount & Balance Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WITHDRAWAL AMOUNT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                req.formattedAmount,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'WALLET BALANCE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                req.formattedBalance,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Remarks
                      if (req.remarks != null && req.remarks!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            'Remarks: ${req.remarks}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],

                      // Forward to SM Button or Status banner
                      const SizedBox(height: 12),
                      if (canForwardToSm)
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.forward_to_inbox_rounded,
                              size: 17,
                            ),
                            label: const Text(
                              'Forward to SM',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            onPressed: () => _showForwardToSmDialog(
                              context,
                              item: req,
                              provider: provider,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: statusBgColor.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusBorderColor.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                req.isPaid
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded,
                                size: 14,
                                color: statusTextColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                req.isPaid
                                    ? 'Incentive Disbursed & Settled'
                                    : req.isForwardedToSm
                                        ? 'Forwarded to SM • Awaiting Review'
                                        : 'In Review Queue • ${req.status}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF0F766E)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionInfoRow({
    required IconData icon,
    required String label,
    required String value,
    IconData? actionIcon,
    String? actionTooltip,
    VoidCallback? onTapAction,
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        if (actionIcon != null && onTapAction != null)
          IconButton(
            icon: Icon(actionIcon, size: 17, color: const Color(0xFF0F766E)),
            tooltip: actionTooltip,
            onPressed: onTapAction,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        if (onCopy != null)
          IconButton(
            icon: const Icon(
              Icons.copy_rounded,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
            tooltip: 'Copy',
            onPressed: onCopy,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }

  Widget _buildTasksSection(List<TaskModel> tasks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 16,
                color: Color(0xFF0F766E),
              ),
              const SizedBox(width: 6),
              const Text(
                'ASSIGNED LEADS & PIPELINE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tasks.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 32,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'No Local Leads Found',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'There are currently no matching leads cached for this BDE.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length > 5 ? 5 : tasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            const Color(0xFF0F766E).withOpacity(0.12),
                        child: Text(
                          task.studentName.isNotEmpty
                              ? task.studentName.substring(0, 1).toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.studentName,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${task.course} • ${task.location}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: task.leadStatus.toLowerCase() == 'closed'
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task.leadStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: task.leadStatus.toLowerCase() == 'closed'
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
