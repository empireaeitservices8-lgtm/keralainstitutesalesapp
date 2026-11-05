import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/colors.dart';
import '../../models/asm_bde_model.dart';
import '../../models/sm_payout_request_model.dart';
import '../../models/task_model.dart';
import '../../providers/operations_provider.dart';

class BdeDetailsScreen extends StatefulWidget {
  final AsmBdeModel bde;
  static const String path = '/bde-details';

  const BdeDetailsScreen({super.key, required this.bde});

  @override
  State<BdeDetailsScreen> createState() => _BdeDetailsScreenState();
}

class _BdeDetailsScreenState extends State<BdeDetailsScreen> {
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
    // Prepend India country code if length is 10 digits
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

  @override
  Widget build(BuildContext context) {
    final bde = widget.bde;
    final bool isActive = bde.status.toLowerCase() == 'active';

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
            const Text(
              'BDE Executive Profile',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              '${bde.employeeId} • ${bde.district.isNotEmpty ? bde.district : 'Regional Team'}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: OperationsProvider.instance,
        builder: (context, _) {
          final provider = OperationsProvider.instance;

          // Filter leads/tasks matching this BDE
          final assignedTasks = provider.rawTasks.where((t) {
            final matchEmail =
                bde.email.isNotEmpty &&
                t.assignedBdeEmail.toLowerCase() == bde.email.toLowerCase();
            final matchName =
                bde.name.isNotEmpty &&
                (t.employee?.toLowerCase() == bde.name.toLowerCase());
            final matchEmpId =
                bde.employeeId.isNotEmpty &&
                (t.employee?.toLowerCase() == bde.employeeId.toLowerCase());
            return matchEmail || matchName || matchEmpId;
          }).toList();

          // Filter payout/salary requests for this BDE
          final payoutRequests = provider.bdePayoutRequests.where((r) {
            final matchId =
                bde.employeeId.isNotEmpty &&
                r.employeeId.toLowerCase() == bde.employeeId.toLowerCase();
            final matchName =
                bde.name.isNotEmpty &&
                r.employeeName.toLowerCase().contains(bde.name.toLowerCase());
            return matchId || matchName;
          }).toList();

          return RefreshIndicator(
            color: const Color(0xFF0F766E),
            onRefresh: () async {
              await provider.fetchAsmBdes(isRefresh: true);
              // await provider.fetchBdePayoutRequests(isRefresh: true);
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

                  // 2. Performance & Conversion Metrics
                  _buildPerformanceSection(bde),
                  const SizedBox(height: 16),

                  // 3. Organization & Territory Details
                  _buildSectionCard(
                    title: 'TERRITORY & REPORTING',
                    icon: Icons.account_tree_outlined,
                    children: [
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Assigned District',
                        value: bde.district.isNotEmpty
                            ? bde.district
                            : 'Not Assigned',
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(
                        icon: Icons.groups_outlined,
                        label: 'Sales Team',
                        value: bde.team.isNotEmpty ? bde.team : 'Regional Team',
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
                            : 'Area Sales Manager (ASM)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Contact & Identity Information
                  _buildSectionCard(
                    title: 'CONTACT & SYSTEM DETAILS',
                    icon: Icons.contact_phone_outlined,
                    children: [
                      _buildActionInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        value: bde.email.isNotEmpty
                            ? bde.email
                            : 'Not Provided',
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
                        label: 'Phone Number',
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
                                'Phone number',
                              )
                            : null,
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildActionInfoRow(
                        icon: Icons.credit_card_outlined,
                        label: 'Employee Code',
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
                      if (bde.id.isNotEmpty && bde.id != bde.employeeId) ...[
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildActionInfoRow(
                          icon: Icons.fingerprint_outlined,
                          label: 'Internal System ID',
                          value: bde.id,
                          onCopy: () => _copyToClipboard(bde.id, 'System ID'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. Assigned Tasks / Leads
                  _buildTasksSection(assignedTasks),
                  const SizedBox(height: 16),

                  // 6. Payout & Approval Requests (if any)
                  if (payoutRequests.isNotEmpty) ...[
                    _buildPayoutSection(payoutRequests),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
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
                // Avatar
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
                // Name & Badges
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
                          // Status Badge
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
                      // Territory chip
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
            // Quick Action Buttons Row
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

  // Communication Pill Button
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

  // Performance Section
  Widget _buildPerformanceSection(AsmBdeModel bde) {
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
                  label: 'LEADS ASSIGNED',
                  value: '${bde.leadsAssigned}',
                  icon: Icons.assignment_ind_outlined,
                  color: const Color(0xFF0F766E),
                  bgColor: const Color(0xFFF0FDFA),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'ADMISSIONS',
                  value: '${bde.admissionsClosed}',
                  icon: Icons.school_outlined,
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'CONVERSION',
                  value: bde.conversionRate.isNotEmpty
                      ? bde.conversionRate
                      : '0%',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFF0FDF4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar representation
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: bde.leadsAssigned > 0
                  ? (bde.admissionsClosed / bde.leadsAssigned).clamp(0.0, 1.0)
                  : 0.0,
              minHeight: 7,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0F766E),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Conversion Success Rate: ${bde.conversionRate}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                '${bde.admissionsClosed} / ${bde.leadsAssigned} Leads',
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

  // Single Metric Tile
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

  // Generic Section Card Container
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

  // Simple Info Row
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

  // Info Row with Copy and Action Button
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

  // Tasks / Leads assigned to BDE
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
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
                        backgroundColor: const Color(
                          0xFF0F766E,
                        ).withOpacity(0.12),
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

  // Payout requests section
  Widget _buildPayoutSection(List<SmPayoutRequestModel> requests) {
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
                Icons.receipt_long_outlined,
                size: 16,
                color: Color(0xFF0F766E),
              ),
              const SizedBox(width: 6),
              const Text(
                'PAYOUT & FINANCIAL REQUESTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final req = requests[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${req.type} Request',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (req.month != null)
                          Text(
                            'Month: ${req.month}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          req.formattedAmount,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: req.isPaid
                                ? const Color(0xFFECFDF5)
                                : req.isPending
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req.status,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: req.isPaid
                                  ? const Color(0xFF059669)
                                  : req.isPending
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
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
