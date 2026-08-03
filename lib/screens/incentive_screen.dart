import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../providers/operations_provider.dart';
import '../utils/helpers.dart';

class IncentiveScreen extends StatefulWidget {
  static const String path = '/incentives';
  const IncentiveScreen({super.key});

  @override
  State<IncentiveScreen> createState() => _IncentiveScreenState();
}

class _IncentiveScreenState extends State<IncentiveScreen> {

  @override
  void initState() {
    super.initState();
    OperationsProvider.instance.loadOperationsData();
  }

  void _openCreateIncentiveDialog() {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    String category = 'Sales Target';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Submit Incentive Claim',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: category,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Incentive Category',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.bgInput,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.accentTeal),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Sales Target', child: Text('Sales Target')),
                          DropdownMenuItem(value: 'New Client', child: Text('New Client')),
                          DropdownMenuItem(value: 'Route Bonus', child: Text('Route Bonus')),
                          DropdownMenuItem(value: 'High-Value Booking', child: Text('High-Value Booking')),
                          DropdownMenuItem(value: 'Promotional', child: Text('Promotional')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Amount Input
                      TextFormField(
                        controller: amountController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount (INR)',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          prefixText: '₹ ',
                          prefixStyle: const TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: AppColors.bgInput,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.accentTeal),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter amount';
                          }
                          final amt = double.tryParse(value);
                          if (amt == null || amt <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          
                          setDialogState(() => isSubmitting = true);
                          final amt = double.parse(amountController.text.trim());
                          
                          await OperationsProvider.instance.createIncentive(
                            category,
                            amt,
                            '',
                            null,
                          );
                          
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            Navigator.pop(context);
                            UiHelpers.showSnackBar(context, 'Incentive claim submitted successfully!', Colors.green);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Claim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'INCENTIVE MANAGEMENT',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: AppColors.accentGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentTeal.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          onPressed: _openCreateIncentiveDialog,
          child: const Icon(Icons.add_chart_rounded, size: 24, color: Colors.white),
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
              final list = provider.incentives;

              return Column(
                children: [
                  // Top Summary Card (Fintech Gradient Card with Trophy Watermark)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.accentGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentTeal.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Trophy watermark
                            Positioned(
                              right: -10,
                              bottom: -15,
                              child: Icon(
                                Icons.emoji_events_rounded,
                                size: 90,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTAL APPROVED & PAID INCENTIVES',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '₹ ${NumberFormat('#,##,###.00').format(provider.totalEarnedIncentives)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black12,
                                          offset: Offset(1, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: list.isEmpty
                        ? const Center(
                            child: Text(
                              'No Incentive claims found.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: list.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final incentive = list[index];
                              final formattedDate = DateFormat('dd MMM yyyy').format(incentive.date);
                              
                              Color statusColor = Colors.orange;
                              if (incentive.status == 'Approved') {
                                statusColor = Colors.teal;
                              } else if (incentive.status == 'Paid') {
                                statusColor = Colors.green;
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    children: [
                                      // Left status stripe indicator
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        bottom: 0,
                                        width: 4,
                                        child: Container(
                                          color: statusColor,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 18, right: 16, top: 16, bottom: 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: statusColor.withOpacity(0.08),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Icon(
                                                        incentive.category == 'Sales Target'
                                                            ? Icons.ads_click_rounded
                                                            : incentive.category == 'New Client'
                                                                ? Icons.person_add_alt_1_rounded
                                                                : incentive.category == 'Route Bonus'
                                                                    ? Icons.explore_rounded
                                                                    : incentive.category == 'High-Value Booking'
                                                                        ? Icons.auto_graph_rounded
                                                                        : Icons.campaign_rounded,
                                                        color: statusColor,
                                                        size: 18,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      incentive.category.toUpperCase(),
                                                      style: const TextStyle(
                                                        color: AppColors.textPrimary,
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.w800,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '₹ ${NumberFormat('#,##,###').format(incentive.amount)}',
                                                  style: const TextStyle(
                                                    color: AppColors.textPrimary,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              incentive.remarks.isEmpty ? 'No description provided' : incentive.remarks,
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
                                                height: 1.4,
                                              ),
                                            ),
                                            const Divider(color: Color(0xFFE2E8F0), height: 24),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withOpacity(0.09),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    incentive.status.toUpperCase(),
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
