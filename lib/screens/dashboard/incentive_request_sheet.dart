import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/operations_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/wallet_approval_request_model.dart';
import '../../utils/helpers.dart';

void showIncentiveRequestSheet(BuildContext context, {double? currentBalance}) {
  final formKey = GlobalKey<FormState>();

  final amountController = TextEditingController();
  final upiController = TextEditingController();
  final bankNameController = TextEditingController();
  final accountNumController = TextEditingController();
  final ifscController = TextEditingController();
  final remarksController = TextEditingController();

  bool isSubmitting = false;
  final balance =
      currentBalance ??
      WalletProvider.instance.state.data?.balance ??
      HomeProvider.instance.state.data?.walletBalance.toDouble() ??
      0.0;

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
                    // Pull notch
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0F766E,
                                ).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.payments_rounded,
                                color: Color(0xFF0F766E),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Incentive Withdrawal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Submit claim',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Balance Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF042F2E), Color(0xFF0F766E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Available Incentive Balance',
                                style: TextStyle(
                                  color: Color(0xFF99F6E4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '\u20B9${NumberFormat('#,##,###').format(balance.toInt())}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // Container(
                          //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          //   decoration: BoxDecoration(
                          //     color: Colors.white.withOpacity(0.15),
                          //     borderRadius: BorderRadius.circular(20),
                          //   ),
                          //   child: const Row(
                          //     mainAxisSize: MainAxisSize.min,
                          //     children: [
                          //       Icon(Icons.verified_user_rounded, color: Colors.tealAccent, size: 14),
                          //       SizedBox(width: 4),
                          //       Text(
                          //         'ASM Verified',
                          //         style: TextStyle(
                          //           color: Colors.white,
                          //           fontSize: 11,
                          //           fontWeight: FontWeight.bold,
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Amount input
                    const Text(
                      'Withdrawal Amount (₹) *',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '3000',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.normal,
                        ),
                        prefixIcon: const Icon(
                          Icons.currency_rupee_rounded,
                          color: Color(0xFF0F766E),
                          size: 20,
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
                            color: Color(0xFFE2E8F0),
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
                          return 'Please enter withdrawal amount';
                        }
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Please enter a valid positive amount';
                        }
                        if (balance > 0 && parsed > balance) {
                          return 'Amount exceeds available balance (₹${balance.toInt()})';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Payment details divider
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'PAYMENT DETAILS',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // UPI ID
                    const Text(
                      'UPI ID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: upiController,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. rahul@okaxis',
                        prefixIcon: const Icon(
                          Icons.alternate_email_rounded,
                          color: Color(0xFF0F766E),
                          size: 18,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
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

                    const SizedBox(height: 12),

                    // Bank Details (Bank Name & Account Number)
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bank Name',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: bankNameController,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'e.g. State Bank of India',
                                  prefixIcon: const Icon(
                                    Icons.account_balance_rounded,
                                    color: Color(0xFF0F766E),
                                    size: 18,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 11,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
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
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'IFSC Code',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: ifscController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'SBIN0001234',
                                  prefixIcon: const Icon(
                                    Icons.pin_rounded,
                                    color: Color(0xFF0F766E),
                                    size: 18,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 11,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
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
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Account Number
                    const Text(
                      'Account Number',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: accountNumController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 123456789012',
                        prefixIcon: const Icon(
                          Icons.credit_card_rounded,
                          color: Color(0xFF0F766E),
                          size: 18,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
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

                    // Remarks
                    const Text(
                      'Remarks / Purpose *',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: remarksController,
                      maxLines: 2,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Incentive withdrawal',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(
                            Icons.notes_rounded,
                            color: Color(0xFF0F766E),
                            size: 20,
                          ),
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
                            color: Color(0xFFE2E8F0),
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
                          return 'Please enter remarks for this request';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                setModalState(() => isSubmitting = true);
                                final amt = double.parse(
                                  amountController.text.trim(),
                                );
                                final remarks = remarksController.text.trim();
                                final upi = upiController.text.trim();
                                final bank = bankNameController.text.trim();
                                final acc = accountNumController.text.trim();
                                final ifsc = ifscController.text.trim();

                                try {
                                  final result = await WalletProvider.instance
                                      .submitWithdraw(
                                        amount: amt,
                                        remarks: remarks,
                                        upiId: upi.isNotEmpty ? upi : null,
                                        bankName: bank.isNotEmpty ? bank : null,
                                        accountNumber: acc.isNotEmpty
                                            ? acc
                                            : null,
                                        ifscCode: ifsc.isNotEmpty ? ifsc : null,
                                      );

                                  if (result.success) {
                                    // Also insert into OperationsProvider wallet requests so ASM sees it immediately
                                    final session =
                                        AuthProvider.instance.session;
                                    OperationsProvider.instance
                                        .addWalletApprovalRequest(
                                          WalletApprovalRequestItem(
                                            id: result.requestId!,
                                            requestId: result.requestId!,
                                            employee: session.name,
                                            employeeId: session.email,
                                            designation: "ASM",
                                            team:
                                                session.team != null &&
                                                    session.team
                                                        .toString()
                                                        .isNotEmpty
                                                ? session.team.toString()
                                                : 'Kerala Team',
                                            asmName: result.asmName,
                                            amount: amt,
                                            availableBalance:
                                                result.remainingBalance ?? 0,
                                            status: result.status!,
                                            statusLabel: result.status!,
                                            remarks: remarks,
                                            approvalHistory: [
                                              WalletApprovalStage(
                                                stage: 'Step 1 - Submit',
                                                actionBy: session.name,
                                                role: 'ASM',
                                                action: 'SUBMITTED',
                                                actionAt: DateTime.now()
                                                    .toIso8601String(),
                                                remarks: remarks,
                                              ),
                                            ],
                                            createdAt: DateTime.now()
                                                .toIso8601String(),
                                          ),
                                        );

                                    // Refresh HomeProvider
                                    HomeProvider.instance.fetchHomeData(
                                      isRefresh: true,
                                    );

                                    setModalState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      _showSuccessDialog(context, result);
                                    }
                                  } else {
                                    setModalState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      UiHelpers.showSnackBar(
                                        context,
                                        result.message,
                                        Colors.redAccent,
                                      );
                                    }
                                  }
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  String msg = e.toString();
                                  if (msg.contains('ApiException:')) {
                                    msg = msg
                                        .replaceAll(
                                          RegExp(r'ApiException:\s*\[\d+\]\s*'),
                                          '',
                                        )
                                        .trim();
                                  }
                                  if (context.mounted) {
                                    UiHelpers.showSnackBar(
                                      context,
                                      msg,
                                      Colors.redAccent,
                                    );
                                  }
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          isSubmitting ? 'Submitting Claim...' : 'Submit',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

void _showSuccessDialog(BuildContext context, WithdrawResult result) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Request Submitted Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    if (result.requestId != null)
                      _buildInfoRow('Request ID', result.requestId!),
                    const Divider(height: 14, color: Color(0xFFE2E8F0)),
                    _buildInfoRow(
                      'Amount',
                      '\u20B9${result.amount?.toInt() ?? 0}',
                    ),
                    const Divider(height: 14, color: Color(0xFFE2E8F0)),
                    _buildInfoRow(
                      'Status',
                      result.status ?? 'Submitted ',
                      isBadge: true,
                    ),
                    if (result.asmName != null &&
                        result.asmName!.isNotEmpty) ...[
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildInfoRow('Assigned', result.asmName!),
                    ],
                    if (result.remainingBalance != null) ...[
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildInfoRow(
                        'Remaining Balance',
                        '\u20B9${NumberFormat('#,##,###').format(result.remainingBalance!.toInt())}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildInfoRow(String label, String value, {bool isBadge = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      if (isBadge)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF92400E),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        )
      else
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
    ],
  );
}
