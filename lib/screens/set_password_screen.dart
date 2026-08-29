import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_container.dart';
import '../utils/validators.dart';
import '../utils/helpers.dart';
import 'dashboard/dashboard_screen.dart';

class SetPasswordScreen extends StatefulWidget {
  static const String path = '/set-password';
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = AuthProvider.instance;
    final success = await authProvider.changePassword(_passwordController.text);

    if (success && mounted) {
      UiHelpers.showSnackBar(
        context,
        'Password updated successfully!',
        Colors.greenAccent,
        textColor: Colors.black87,
      );
      Navigator.pushReplacementNamed(context, DashboardScreen.path);
    } else if (mounted) {
      UiHelpers.showSnackBar(
        context,
        'Failed to set password. Please try again.',
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
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentTeal.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentCyan.withOpacity(0.08),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/kide_logo_icon.png',
                                height: 75,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 16),
                              Image.asset(
                                'assets/images/kide_logo_text.png',
                                height: 36,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
                        ListenableBuilder(
                          listenable: AuthProvider.instance,
                          builder: (context, _) {
                            final authProvider = AuthProvider.instance;
                            final bool isButtonLoading = authProvider.isLoading;

                            return GlassContainer(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Set New Password',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Your account requires a password change. Please set a new secure password.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    TextFormField(
                                      controller: _passwordController,
                                      style: const TextStyle(color: AppColors.textPrimary),
                                      obscureText: authProvider.obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: 'New Password',
                                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.accentTeal),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            authProvider.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: AppColors.textSecondary,
                                          ),
                                          onPressed: () {
                                            authProvider.toggleObscurePassword();
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
                                          borderSide: const BorderSide(color: AppColors.accentTeal, width: 1.5),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.redAccent),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.redAccent),
                                        ),
                                      ),
                                      validator: Validators.validatePassword,
                                    ),
                                    const SizedBox(height: 18),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      style: const TextStyle(color: AppColors.textPrimary),
                                      obscureText: authProvider.obscureConfirmPassword,
                                      decoration: InputDecoration(
                                        labelText: 'Re-enter Password',
                                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                                        prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.accentTeal),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            authProvider.obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: AppColors.textSecondary,
                                          ),
                                          onPressed: () {
                                            authProvider.toggleObscureConfirmPassword();
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
                                          borderSide: const BorderSide(color: AppColors.accentTeal, width: 1.5),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.redAccent),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.redAccent),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please re-enter password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
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
                                            color: AppColors.accentTeal.withOpacity(0.25),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          )
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
                                        onPressed: isButtonLoading ? null : _handleSubmit,
                                        child: isButtonLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : const Text(
                                                'Enter',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
    );
  }
}
