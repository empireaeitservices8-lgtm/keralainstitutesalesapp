import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_container.dart';
import '../utils/validators.dart';
import '../utils/helpers.dart';
import 'dashboard_screen.dart';

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
  
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle Email & Password Login
  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await AuthProvider.instance.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      _rememberMe,
    );

    if (success && mounted) {
      UiHelpers.showSnackBar(context, 'Login Successful!', Colors.greenAccent, textColor: Colors.black87);
      _navigateToDashboard();
    } else if (mounted) {
      UiHelpers.showSnackBar(
        context,
        'Invalid Credentials. Use a valid email and >= 6 char password.',
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

  // Quick Switch / Developer Roles Switcher Sheet
  void _showQuickDemoLoginSheet() {
    final List<Map<String, String>> demoAccounts = [
      {
        'role': 'MD',
        'title': 'MD (Managing Director / Super Admin)',
        'email': 'md@keralainstitute.org',
        'desc': 'Unrestricted access, state-wide analytics, user control.',
        'icon': '👑',
      },
      {
        'role': 'ZM',
        'title': 'ZM (Zonal Sales Manager - Central Zone)',
        'email': 'zm.central@keralainstitute.org',
        'desc': 'Central Zone overview (5 districts), district filters.',
        'icon': '🗺️',
      },
      {
        'role': 'ASM',
        'title': 'ASM (Area Sales Manager - Ernakulam)',
        'email': 'asm.ernakulam@keralainstitute.org',
        'desc': 'District Head, view all teams under Ernakulam.',
        'icon': '🏢',
      },
      {
        'role': 'BDM',
        'title': 'BDM (Team Leader - Ernakulam Team A)',
        'email': 'bdm.ernakulam.a@keralainstitute.org',
        'desc': 'Manage BDEs in Team A, Bulk Upload & Assign Leads.',
        'icon': '👥',
      },
      {
        'role': 'BDE',
        'title': 'BDE (Sales Executive - Ernakulam A1)',
        'email': 'bde.ernakulam.a1@keralainstitute.org',
        'desc': 'Ground executive, view/update self leads, check-in, EOD.',
        'icon': '🏃',
      },
    ];

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
                      'Demo Quick Sign-In',
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
                const SizedBox(height: 8),
                const Text(
                  'Select a preconfigured user profile to test role-specific dashboards, permissions, and zonal scopes.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: demoAccounts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final acc = demoAccounts[index];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _emailController.text = acc['email']!;
                          _passwordController.text = 'password123';
                          _handleEmailLogin();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Text(acc['icon']!, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      acc['title']!,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      acc['desc']!,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
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
                                          keyboardType: TextInputType.emailAddress,
                                          decoration: InputDecoration(
                                            labelText: 'Email Address',
                                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.accentTeal),
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
                                          validator: Validators.validateEmail,
                                        ),
                                        const SizedBox(height: 18),
                                        TextFormField(
                                          controller: _passwordController,
                                          style: const TextStyle(color: AppColors.textPrimary),
                                          obscureText: _obscurePassword,
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.accentTeal),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                color: AppColors.textSecondary,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword = !_obscurePassword;
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
                                                    value: _rememberMe,
                                                    activeColor: AppColors.accentTeal,
                                                    checkColor: Colors.white,
                                                    side: const BorderSide(color: AppColors.textSecondary),
                                                    onChanged: (val) {
                                                      setState(() {
                                                        _rememberMe = val ?? true;
                                                      });
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
                                        const SizedBox(height: 16),
                                        Center(
                                          child: TextButton.icon(
                                            onPressed: _showQuickDemoLoginSheet,
                                            icon: const Icon(Icons.supervisor_account_rounded, color: AppColors.accentTeal, size: 18),
                                            label: const Text(
                                              'Quick Demo Sign-In / Role Switcher',
                                              style: TextStyle(
                                                color: AppColors.accentTeal,
                                                fontSize: 13,
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
