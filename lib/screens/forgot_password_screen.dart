import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_container.dart';
import '../utils/helpers.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const String path = '/forgot-password';
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final employeeId = _employeeIdController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final result = await AuthProvider.instance.forgotPassword(
      employeeId: employeeId,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      UiHelpers.showSnackBar(
        context,
        result['message']?.toString() ?? 'Password updated successfully! Please login.',
        Colors.greenAccent,
        textColor: Colors.black87,
      );
      Navigator.pop(context);
    } else {
      UiHelpers.showSnackBar(
        context,
        result['message']?.toString() ?? 'Failed to reset password. Please check your details.',
        Colors.redAccent,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background blur circles
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentTeal.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentCyan.withOpacity(0.08),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top App Bar with back button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                          tooltip: 'Back to Login',
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Back to Login',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Icon & Titles
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentTeal.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.accentTeal.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.lock_reset_rounded,
                                    size: 38,
                                    color: AppColors.accentTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Reset Password',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Enter your Employee ID, set your new password, and confirm to update your account.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Form Card
                              GlassContainer(
                                padding: const EdgeInsets.all(22),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Employee ID
                                      TextFormField(
                                        controller: _employeeIdController,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        keyboardType: TextInputType.text,
                                        textCapitalization: TextCapitalization.characters,
                                        decoration: InputDecoration(
                                          labelText: 'Employee ID',
                                          hintText: 'e.g. ASM001',
                                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                          prefixIcon: const Icon(
                                            Icons.badge_outlined,
                                            color: AppColors.accentTeal,
                                          ),
                                          filled: true,
                                          fillColor: AppColors.bgInput,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.accentTeal,
                                              width: 1.5,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(color: Colors.redAccent),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                          ),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'Please enter your Employee ID';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 18),

                                      // New Password
                                      TextFormField(
                                        controller: _newPasswordController,
                                        obscureText: _obscureNewPassword,
                                        style: const TextStyle(color: AppColors.textPrimary),
                                        decoration: InputDecoration(
                                          labelText: 'New Password',
                                          hintText: 'Enter new password',
                                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                          prefixIcon: const Icon(
                                            Icons.lock_outline_rounded,
                                            color: AppColors.accentTeal,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureNewPassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: AppColors.textSecondary,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureNewPassword = !_obscureNewPassword;
                                              });
                                            },
                                          ),
                                          filled: true,
                                          fillColor: AppColors.bgInput,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.accentTeal,
                                              width: 1.5,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(color: Colors.redAccent),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                          ),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Please enter a new password';
                                          }
                                          if (val.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 18),

                                      // Confirm Password
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: _obscureConfirmPassword,
                                        style: const TextStyle(color: AppColors.textPrimary),
                                        decoration: InputDecoration(
                                          labelText: 'Confirm Password',
                                          hintText: 'Re-enter new password',
                                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                          prefixIcon: const Icon(
                                            Icons.lock_clock_outlined,
                                            color: AppColors.accentTeal,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: AppColors.textSecondary,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureConfirmPassword = !_obscureConfirmPassword;
                                              });
                                            },
                                          ),
                                          filled: true,
                                          fillColor: AppColors.bgInput,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.accentTeal,
                                              width: 1.5,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(color: Colors.redAccent),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                          ),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Please confirm your new password';
                                          }
                                          if (val != _newPasswordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 26),

                                      // Submit Button
                                      Container(
                                        height: 52,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: const LinearGradient(
                                            colors: AppColors.accentGradient,
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.accentTeal.withOpacity(0.3),
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
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          onPressed: _isSubmitting ? null : _handleSubmit,
                                          child: _isSubmitting
                                              ? const SizedBox(
                                                  height: 22,
                                                  width: 22,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Submit',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

