import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_container.dart';
import '../utils/validators.dart';
import '../utils/helpers.dart';
import 'dashboard/dashboard_screen.dart';
import 'set_password_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String path = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle Employee ID & Password Login
  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await AuthProvider.instance.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      AuthProvider.instance.rememberMe,
    );

    if (success && mounted) {
      if (AuthProvider.instance.requirePasswordChange) {
        UiHelpers.showSnackBar(
          context,
          'Password change required!',
          Colors.orangeAccent,
          textColor: Colors.black87,
        );
        Navigator.pushReplacementNamed(context, SetPasswordScreen.path);
      } else {
        UiHelpers.showSnackBar(context, 'Login Successful!', Colors.greenAccent, textColor: Colors.black87);
        _navigateToDashboard();
      }
    } else if (mounted) {
      UiHelpers.showSnackBar(
        context,
        'Invalid Credentials. Please enter a valid Employee ID and Password.',
        Colors.redAccent,
        textColor: Colors.white,
      );
    }
  }



  // Handle Forgot Password Popup
  void _showForgotPasswordDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Account Recovery',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Password resets are managed by the Regional IT Administration for security compliance. Please contact your system administrator to request a password reset or unlock your account.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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



  void _navigateToDashboard() {
    Navigator.pushReplacementNamed(
      context,
      DashboardScreen.path,
    );
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 60,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(),
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
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                AppStrings.loginInfo,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Uses AuthProvider and ListenableBuilder
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
                                        TextFormField(
                                          controller: _emailController,
                                          style: const TextStyle(color: AppColors.textPrimary),
                                          keyboardType: TextInputType.text,
                                          textCapitalization: TextCapitalization.characters,
                                          decoration: InputDecoration(
                                            labelText: 'Employee ID',
                                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                                            prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.accentTeal),
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
                                          validator: Validators.validateEmployeeId,
                                        ),
                                        const SizedBox(height: 18),
                                        TextFormField(
                                          controller: _passwordController,
                                          style: const TextStyle(color: AppColors.textPrimary),
                                          obscureText: authProvider.obscurePassword,
                                          decoration: InputDecoration(
                                            labelText: 'Password',
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
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: Checkbox(
                                                    value: authProvider.rememberMe,
                                                    activeColor: AppColors.accentTeal,
                                                    checkColor: Colors.white,
                                                    side: const BorderSide(color: AppColors.textSecondary),
                                                    onChanged: (val) {
                                                      authProvider.setRememberMe(val ?? true);
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Remember Me',
                                                  style: TextStyle(
                                                    color: AppColors.textPrimary,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TextButton(
                                              onPressed: _showForgotPasswordDialog,
                                              child: const Text(
                                                'Forgot Password?',
                                                style: TextStyle(
                                                  color: AppColors.accentTeal,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
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
                                            onPressed: isButtonLoading ? null : _handleEmailLogin,
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
                                                    'Secure Sign In',
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
                            const Spacer(),
                          ],
                        ),
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
  }
}
