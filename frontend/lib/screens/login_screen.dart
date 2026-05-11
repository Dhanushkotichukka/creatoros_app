import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _webRedirecting = false;
  bool _showEmailForm = false;
  bool _obscurePassword = true;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleGoogleSignIn(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    if (kIsWeb) {
      setState(() => _webRedirecting = true);
      await authProvider.signInWithGoogle();
      if (mounted) setState(() => _webRedirecting = false);
      return;
    }
    final success = await authProvider.signInWithGoogle();
    if (!success && context.mounted && authProvider.errorMessage != null) {
      _showError(authProvider.errorMessage!);
    }
  }

  Future<void> _handleEmailSignIn(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.signInWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;

    if (authProvider.errorMessage != null) {
      final err = authProvider.errorMessage!;
      // If account not verified, send to OTP screen
      if (err.contains('not verified') || err.contains('EMAIL_NOT_VERIFIED')) {
        _showError('Please verify your email first. A new code has been sent.');
      } else {
        _showError(err);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
    );
  }

  @override
  Widget build(BuildContext context) {
    const c = AppColors.dark;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Logo + Glow
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withOpacity(0.5),
                        blurRadius: 50,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Image.asset('assets/images/logo.png', width: 110, height: 110, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 28),

                Text('CreatorOS',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: c.textPrimary, letterSpacing: -1)),
                const SizedBox(height: 8),
                Text('The Ultimate Hub for Modern Creators',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: c.textSecondary)),

                const SizedBox(height: 40),

                if (authProvider.isLoading || _webRedirecting)
                  Column(children: [
                    CircularProgressIndicator(color: c.primary),
                    const SizedBox(height: 16),
                    Text(
                      _webRedirecting ? 'Redirecting to Google...' : 'Signing you in...',
                      style: TextStyle(color: c.textSecondary, fontSize: 14),
                    ),
                  ])
                else ...[
                  // Google Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleGoogleSignIn(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 4,
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 24, height: 24,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          child: const Icon(Icons.g_mobiledata, color: Colors.blue, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Text('Continue with Google',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(children: [
                    Expanded(child: Divider(color: c.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(color: c.textSecondary, fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: c.border)),
                  ]),

                  const SizedBox(height: 20),

                  // Toggle email form
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _showEmailForm ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showEmailForm = true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.primary,
                          side: BorderSide(color: c.primary),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Sign in with Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    secondChild: _buildEmailForm(c),
                  ),

                  const SizedBox(height: 20),

                  // Sign up link
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("Don't have an account? ", style: TextStyle(color: c.textSecondary, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                      child: Text('Sign Up', style: TextStyle(color: c.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ],

                const SizedBox(height: 24),
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: c.textSecondary.withOpacity(0.6)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(AppColors c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Email
      TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(color: c.textPrimary),
        decoration: _inputDecoration(c, 'Email', Icons.email_outlined),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Email is required';
          if (!v.contains('@')) return 'Enter a valid email';
          return null;
        },
      ),
      const SizedBox(height: 14),

      // Password
      TextFormField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        style: TextStyle(color: c.textPrimary),
        decoration: _inputDecoration(c, 'Password', Icons.lock_outlined).copyWith(
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: c.textSecondary),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Password is required';
          return null;
        },
      ),

      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
          child: Text('Forgot Password?', style: TextStyle(color: c.primary, fontSize: 13)),
        ),
      ),

      const SizedBox(height: 4),

      ElevatedButton(
        onPressed: () => _handleEmailSignIn(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    ]);
  }

  InputDecoration _inputDecoration(AppColors c, String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: c.textSecondary),
    prefixIcon: Icon(icon, color: c.textSecondary, size: 20),
    filled: true,
    fillColor: c.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.primary, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)),
  );
}
