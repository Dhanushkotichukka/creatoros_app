import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Steps: 0 = enter email, 1 = enter OTP + new password
  int _step = 0;
  final _emailCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  String? _userId;
  String? _resetToken;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your email address.', isError: true);
      return;
    }
    final authProvider = context.read<AuthProvider>();
    final userId = await authProvider.forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    if (authProvider.errorMessage != null) {
      _showSnack(authProvider.errorMessage!, isError: true);
      return;
    }
    _userId = userId;
    // Navigate to OTP screen — it returns true if OTP valid + resetToken obtained
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => OtpVerificationScreen(
        userId: userId ?? '',
        email: _emailCtrl.text.trim(),
        type: 'reset_password',
      )),
    );
    if (!mounted) return;
    if (result == true) {
      // OTP was verified — get reset token from provider
      setState(() => _step = 1);
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordCtrl.text.length < 8) {
      _showSnack('Password must be at least 8 characters.', isError: true);
      return;
    }
    if (_resetToken == null) {
      _showSnack('Session expired. Please try again.', isError: true);
      return;
    }
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(resetToken: _resetToken!, newPassword: _newPasswordCtrl.text);
    if (!mounted) return;
    if (success) {
      _showSnack('Password reset successfully!');
      Navigator.pop(context);
    } else {
      _showSnack(authProvider.errorMessage ?? 'Failed to reset password.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    const c = AppColors.dark;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: c.primary.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(Icons.lock_reset_outlined, color: c.primary, size: 36),
            ),
            const SizedBox(height: 24),

            Text(
              _step == 0 ? 'Forgot Password?' : 'Set New Password',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: c.textPrimary, letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            Text(
              _step == 0
                  ? 'Enter your email address and we\'ll send you a 6-digit reset code.'
                  : 'Enter your new password below.',
              style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 36),

            if (_step == 0) ...[
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: c.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: TextStyle(color: c.textSecondary),
                  prefixIcon: Icon(Icons.email_outlined, color: c.textSecondary, size: 20),
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: isLoading ? null : _sendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  disabledBackgroundColor: c.primary.withOpacity(0.5),
                ),
                child: isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Reset Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ] else ...[
              TextFormField(
                controller: _newPasswordCtrl,
                obscureText: _obscurePassword,
                style: TextStyle(color: c.textPrimary),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: c.textSecondary),
                  prefixIcon: Icon(Icons.lock_outline, color: c.textSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: c.textSecondary),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  disabledBackgroundColor: c.primary.withOpacity(0.5),
                ),
                child: isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
