import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _handleGoogleSignIn(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sign in failed. Please try again.'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const c = AppColors.dark;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: c.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.primary.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(Icons.rocket_launch_rounded, size: 64, color: c.primary),
              ),
              const SizedBox(height: 32),

              Text('CreatorOS',
                style: TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w900,
                  color: c.textPrimary, letterSpacing: -1,
                )),
              const SizedBox(height: 12),
              Text('The Ultimate Hub for Modern Creators',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: c.textSecondary)),

              const Spacer(flex: 1),

              // Sign In Button
              if (authProvider.isLoading)
                CircularProgressIndicator(color: c.primary)
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleGoogleSignIn(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          child: const Icon(Icons.g_mobiledata, color: Colors.blue, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Text('Continue with Google',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              Text('By continuing, you agree to our Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: c.textSecondary.withOpacity(0.6))),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
