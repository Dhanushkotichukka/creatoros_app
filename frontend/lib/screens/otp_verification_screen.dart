import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String type; // 'verify_email' or 'reset_password'

  const OtpVerificationScreen({
    super.key,
    required this.userId,
    required this.email,
    this.type = 'verify_email',
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsLeft = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) {
      _showSnack('Please enter the 6-digit code.', isError: true);
      return;
    }
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(
      userId: widget.userId,
      otp: _otp,
      type: widget.type,
    );
    if (!mounted) return;

    if (success) {
      if (widget.type == 'verify_email') {
        // Logged in — AuthGate will route to home automatically
        _showSnack('Email verified! Welcome to CreatorOS 🎉');
      } else {
        // reset_password — return the resetToken to caller
        Navigator.pop(context, authProvider.errorMessage == null);
      }
    } else {
      _showSnack(authProvider.errorMessage ?? 'Invalid OTP.', isError: true);
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.resendOtp(userId: widget.userId, type: widget.type);
    if (!mounted) return;
    if (ok) {
      _showSnack('New code sent to ${widget.email}');
      _startTimer();
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    } else {
      _showSnack(authProvider.errorMessage ?? 'Failed to resend code.', isError: true);
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
            // Icon
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: c.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mark_email_read_outlined, color: c.primary, size: 36),
            ),
            const SizedBox(height: 24),

            Text(
              widget.type == 'verify_email' ? 'Verify Email' : 'Enter Reset Code',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: c.textPrimary, letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.5),
                children: [
                  const TextSpan(text: 'Enter the 6-digit code sent to\n'),
                  TextSpan(text: widget.email, style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // OTP Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => SizedBox(
                width: 48,
                height: 56,
                child: TextFormField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: c.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.primary, width: 2)),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus();
                    if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
                  },
                ),
              )),
            ),

            const SizedBox(height: 36),

            ElevatedButton(
              onPressed: isLoading ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                disabledBackgroundColor: c.primary.withOpacity(0.5),
              ),
              child: isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),

            const SizedBox(height: 24),

            // Resend
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Didn\'t receive the code? ', style: TextStyle(color: c.textSecondary, fontSize: 14)),
              GestureDetector(
                onTap: _canResend ? _resend : null,
                child: Text(
                  _canResend ? 'Resend' : 'Resend in ${_secondsLeft}s',
                  style: TextStyle(
                    color: _canResend ? c.primary : c.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
