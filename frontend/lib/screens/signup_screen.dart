import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import 'otp_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  int _passwordStrength = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  int _calcStrength(String p) {
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#\$&*~%^]'))) s++;
    return s;
  }

  Color _strengthColor(int s) {
    if (s <= 1) return Colors.red;
    if (s == 2) return Colors.orange;
    if (s == 3) return Colors.yellow;
    return Colors.green;
  }

  String _strengthLabel(int s) {
    if (s <= 1) return 'Weak';
    if (s == 2) return 'Fair';
    if (s == 3) return 'Good';
    return 'Strong';
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final userId = await authProvider.signUpWithEmail(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (userId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OtpVerificationScreen(
          userId: userId,
          email: _emailCtrl.text.trim(),
          type: 'verify_email',
        )),
      );
    } else if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage!), backgroundColor: Colors.red.shade800),
      );
    }
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Create Account', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: c.textPrimary, letterSpacing: -1)),
              const SizedBox(height: 8),
              Text('Join CreatorOS and start creating', style: TextStyle(fontSize: 15, color: c.textSecondary)),
              const SizedBox(height: 36),

              // Name
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(color: c.textPrimary),
                decoration: _inputDecoration(c, 'Full Name', Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                style: TextStyle(color: c.textPrimary),
                onChanged: (v) => setState(() => _passwordStrength = _calcStrength(v)),
                decoration: _inputDecoration(c, 'Password', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: c.textSecondary),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 8) return 'Password must be at least 8 characters';
                  return null;
                },
              ),

              // Strength indicator
              if (_passwordCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(children: [
                  ...List.generate(4, (i) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i < _passwordStrength ? _strengthColor(_passwordStrength) : c.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                  const SizedBox(width: 8),
                  Text(_strengthLabel(_passwordStrength),
                      style: TextStyle(color: _strengthColor(_passwordStrength), fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ],

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: isLoading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  disabledBackgroundColor: c.primary.withOpacity(0.5),
                ),
                child: isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),

              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account? ', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('Sign In', style: TextStyle(color: c.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
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
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 2)),
  );
}
