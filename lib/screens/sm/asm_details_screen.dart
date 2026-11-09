import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/sm_asm_model.dart';
import '../../models/wallet_approval_request_model.dart';
import '../../providers/operations_provider.dart';
import '../../utils/helpers.dart';

class AsmDetailsScreen extends StatefulWidget {
  final SmAsmModel asm;
  static const String path = '/asm-details';

  const AsmDetailsScreen({super.key, required this.asm});

  @override
  State<AsmDetailsScreen> createState() => _AsmDetailsScreenState();
}

class _AsmDetailsScreenState extends State<AsmDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OperationsProvider.instance.fetchSmAsms(isRefresh: true);
      OperationsProvider.instance.fetchWalletApprovalRequests(isRefresh: true);
    });
  }

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
    final formattedNumber = digitsOnly.length == 10
        ? '91$digitsOnly'
        : digitsOnly;
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

  void _confirmDeleteAsm(BuildContext context, SmAsmModel asm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text(
              'Delete ASM Account?',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete account for ${asm.name} (${asm.employeeId})? This action cannot be undone.',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12.5,
            height: 1.4,
          ),
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
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close confirmation

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  content: const Row(
                    children: [
                      CircularProgressIndicator(color: Colors.red),
                      SizedBox(width: 20),
                      Text(
                        'Deleting ASM account...',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              final res = await OperationsProvider.instance
                  .deleteSubordinateAccount(asm.employeeId);

              if (context.mounted) {
                Navigator.pop(context); // Close loading dialog
                if (res['success'] == true) {
                  UiHelpers.showSnackBar(
                    context,
                    res['message']?.toString() ??
                        'Account ${asm.employeeId} deleted successfully.',
                    Colors.green,
                  );
                  Navigator.pop(context); // Go back to ASMs list
                } else {
                  UiHelpers.showSnackBar(
                    context,
                    res['message']?.toString() ?? 'Failed to delete account.',
                    Colors.redAccent,
                  );
                }
              }
            },
            child: const Text(
              'Delete Permanently',
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

  void _showForwardToAccountsDialog(
    BuildContext context, {
    required WalletApprovalRequestItem item,
    required OperationsProvider provider,
  }) {
    final notesCtrl = TextEditingController(
      text: 'SM approved & forwarded to Accounts.',
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
                'Forward to Accounts',
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
              'Forward withdrawal request ${item.requestId} (${item.formattedAmount}) for ${item.employee} to Accounts?',
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
                labelText: 'SM Recommendation / Remarks',
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
              final ok = await provider.forwardWalletRequestToAccounts(
                item.id,
                remarks: notes.isNotEmpty
                    ? notes
                    : 'SM approved & forwarded to Accounts.',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Request ${item.requestId} forwarded to Accounts!'
                          : 'Failed to forward request',
                    ),
                    backgroundColor: ok
                        ? const Color(0xFF0F766E)
                        : Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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

        final asm = provider.smAsms.firstWhere(
          (a) =>
              (a.id.isNotEmpty && a.id == widget.asm.id) ||
              (a.employeeId.isNotEmpty &&
                  a.employeeId.toLowerCase() ==
                      widget.asm.employeeId.toLowerCase()),
          orElse: () => widget.asm,
        );

        final bool isActive = asm.status.toLowerCase() == 'active';

        final asmWalletRequests = provider.walletApprovalRequests.where((r) {
          final matchEmpId =
              asm.employeeId.isNotEmpty &&
              (r.employeeId.toLowerCase() == asm.employeeId.toLowerCase() ||
                  (r.asmId?.toLowerCase() == asm.employeeId.toLowerCase()));
          final matchName =
              asm.name.isNotEmpty &&
              (r.employee.toLowerCase() == asm.name.toLowerCase() ||
                  (r.asmName?.toLowerCase() == asm.name.toLowerCase()));
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
                  asm.name.isNotEmpty ? asm.name : 'ASM Details',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  '${asm.employeeId.isNotEmpty ? asm.employeeId : "ASM"} • ${asm.designation.isNotEmpty ? asm.designation : "Area Sales Manager"}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF0F172A),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (val) {
                  if (val == 'delete') {
                    _confirmDeleteAsm(context, asm);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete Account',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            color: const Color(0xFF0F766E),
            onRefresh: () async {
              await provider.fetchSmAsms(isRefresh: true);
              await provider.fetchWalletApprovalRequests(isRefresh: true);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Identity Card
                  _buildIdentityCard(asm, isActive),
                  const SizedBox(height: 16),

                  // 2. Performance & Targets Section
                  _buildPerformanceSection(asm),
                  const SizedBox(height: 16),

                  // 3. Compensation & Financials Section
                  _buildCompensationSection(asm),
                  const SizedBox(height: 16),

                  // 4. Territory & Reporting Section
                  _buildSectionCard(
                    title: 'TERRITORY & REPORTING',
                    icon: Icons.account_tree_outlined,
                    children: [
                      _buildInfoRow(
                        icon: Icons.groups_outlined,
                        label: 'Team',
                        value: asm.team.isNotEmpty ? asm.team : 'Not Assigned',
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Districts',
                        value: asm.districtsDisplay,
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Designation',
                        value: asm.designation.isNotEmpty
                            ? asm.designation
                            : 'Area Sales Manager',
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(
                        icon: Icons.people_alt_outlined,
                        label: 'BDEs Under ASM',
                        value: '${asm.bdesCount} BDEs',
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(
                        icon: Icons.supervisor_account_outlined,
                        label: 'Reports To',
                        value: asm.reportsTo.isNotEmpty
                            ? asm.reportsTo
                            : 'State Sales Manager (SM)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. Contact & System Details
                  _buildSectionCard(
                    title: 'CONTACT & SYSTEM DETAILS',
                    icon: Icons.contact_phone_outlined,
                    children: [
                      _buildActionInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        value: asm.email.isNotEmpty
                            ? asm.email
                            : 'Not Provided',
                        actionIcon: Icons.send_outlined,
                        actionTooltip: 'Send Email',
                        onTapAction: asm.email.isNotEmpty
                            ? () => _sendEmail(asm.email)
                            : null,
                        onCopy: asm.email.isNotEmpty
                            ? () => _copyToClipboard(asm.email, 'Email address')
                            : null,
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildActionInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Contact Number',
                        value: asm.contactNumber.isNotEmpty
                            ? asm.contactNumber
                            : 'Not Provided',
                        actionIcon: Icons.call_outlined,
                        actionTooltip: 'Call ASM',
                        onTapAction: asm.contactNumber.isNotEmpty
                            ? () => _makePhoneCall(asm.contactNumber)
                            : null,
                        onCopy: asm.contactNumber.isNotEmpty
                            ? () => _copyToClipboard(
                                asm.contactNumber,
                                'Contact number',
                              )
                            : null,
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildActionInfoRow(
                        icon: Icons.credit_card_outlined,
                        label: 'Employee ID',
                        value: asm.employeeId.isNotEmpty
                            ? asm.employeeId
                            : 'Not Set',
                        onCopy: asm.employeeId.isNotEmpty
                            ? () => _copyToClipboard(
                                asm.employeeId,
                                'Employee ID',
                              )
                            : null,
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Account Status',
                        value: asm.status.toUpperCase(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 6. Wallet & Incentive Requests
                  _buildWalletRequestsSection(asmWalletRequests, provider),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentityCard(SmAsmModel asm, bool isActive) {
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
                    asm.name.isNotEmpty
                        ? asm.name.substring(0, 1).toUpperCase()
                        : 'A',
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
                              asm.name.isNotEmpty
                                  ? asm.name
                                  : 'Area Sales Manager',
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
                                  asm.status.toUpperCase(),
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
                        asm.designation.isNotEmpty
                            ? asm.designation
                            : 'Area Sales Manager',
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
                          if (asm.employeeId.isNotEmpty)
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
                                asm.employeeId,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          if (asm.team.isNotEmpty)
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
                                asm.team,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4338CA),
                                ),
                              ),
                            ),
                          if (asm.districts.isNotEmpty)
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
                                asm.districtsDisplay,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F766E),
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
                    onTap: () => _makePhoneCall(asm.contactNumber),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCommunicationButton(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF16A34A),
                    backgroundColor: const Color(0xFFF0FDF4),
                    onTap: () => _launchWhatsApp(asm.contactNumber),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCommunicationButton(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    color: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFEFF6FF),
                    onTap: () => _sendEmail(asm.email),
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

  void _showEditTargetsSheet(BuildContext context, SmAsmModel asm) {
    final dailyController = TextEditingController(
      text: asm.dailyTarget > 0 ? asm.dailyTarget.toString() : '',
    );
    final monthlyController = TextEditingController(
      text: asm.monthlyTarget > 0 ? asm.monthlyTarget.toString() : '',
    );
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: keyboardPadding > 0 ? keyboardPadding + 16 : 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle notch
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0F766E,
                                ).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.track_changes_rounded,
                                color: Color(0xFF0F766E),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Update ASM Targets',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '${asm.name} (${asm.code})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 22),

                    const Text(
                      'DAILY TARGET (LEADS) *',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: dailyController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'e.g. 4',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.today_rounded,
                          size: 20,
                          color: Color(0xFF0F766E),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
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
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'MONTHLY TARGET (LEADS) *',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: monthlyController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'e.g. 40',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: Color(0xFF2563EB),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
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
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final dVal =
                                    int.tryParse(dailyController.text.trim()) ??
                                    0;
                                final mVal =
                                    int.tryParse(
                                      monthlyController.text.trim(),
                                    ) ??
                                    0;

                                if (dVal <= 0 && mVal <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a valid daily or monthly target',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                setSheetState(() => isSaving = true);

                                final res = await OperationsProvider.instance
                                    .updateAsmTargets(
                                      employeeId: asm.employeeId.isNotEmpty
                                          ? asm.employeeId
                                          : asm.code,
                                      dailyTarget: dVal > 0 ? dVal : null,
                                      monthlyTarget: mVal > 0 ? mVal : null,
                                    );

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res['message']?.toString() ??
                                            'Targets updated!',
                                      ),
                                      backgroundColor: res['success'] == true
                                          ? const Color(0xFF0F766E)
                                          : Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Targets',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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

  Widget _buildPerformanceSection(SmAsmModel asm) {
    final double monthlyRatio = asm.monthlyTarget > 0
        ? (asm.monthlyAchieved / asm.monthlyTarget).clamp(0.0, 1.0)
        : 0.0;
    final double dailyRatio = asm.dailyTarget > 0
        ? (asm.dailyAchieved / asm.dailyTarget).clamp(0.0, 1.0)
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
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 16,
                color: Color(0xFF0F766E),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'PERFORMANCE & TARGETS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showEditTargetsSheet(context, asm),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF0F766E).withOpacity(0.25),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 12,
                        color: Color(0xFF0F766E),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Edit Targets',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'DAILY TARGET',
                  value: '${asm.dailyAchieved}/${asm.dailyTarget}',
                  icon: Icons.today_rounded,
                  color: const Color(0xFF0F766E),
                  bgColor: const Color(0xFFF0FDFA),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'MONTHLY TARGET',
                  value: '${asm.monthlyAchieved}/${asm.monthlyTarget}',
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'OVERALL LEADS',
                  value: '${asm.completedLeads}/${asm.totalLeads}',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFF0FDF4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Daily Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Progress (${asm.dailyPending} pending)',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                '${asm.dailyCompletionPercentage}%',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F766E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: dailyRatio,
              minHeight: 7,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0F766E),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Monthly Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Progress (${asm.monthlyPending} pending)',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                '${asm.monthlyCompletionPercentage}%',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: monthlyRatio,
              minHeight: 7,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompensationSection(SmAsmModel asm) {
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
                        asm.formattedSalary,
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
                        asm.formattedIncentive,
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
                    'No wallet incentive requests found for this ASM.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
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
                final bool canForwardToAccounts =
                    req.isForwardedToSm ||
                    req.status == 'Pending_SM' ||
                    (req.isPending && !statusStr.contains('accounts'));

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
                                  color: const Color(
                                    0xFF0F766E,
                                  ).withOpacity(0.1),
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
                      const SizedBox(height: 12),
                      if (canForwardToAccounts)
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
                              'Forward to Accounts',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            onPressed: () => _showForwardToAccountsDialog(
                              context,
                              item: req,
                              provider: provider,
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
              fontSize: 17,
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
}
