import 'dart:async';

import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_page_route.dart';
import '../home/home_screen.dart';
import '../splash/splash_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.role,
  });

  final String email;
  final String role;

  static const routeName = '/verify-email';

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authRepository = AuthRepository();

  bool _isChecking = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();

    _autoCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkVerified(silent: true),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  void _showSnack(String message, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _goHome() {
    _autoCheckTimer?.cancel();
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(page: HomeScreen(role: widget.role)),
      (route) => false,
    );
  }

  Future<void> _checkVerified({bool silent = false}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final verified = await _authRepository.isEmailVerified();
      if (!mounted) return;
      if (verified) {
        _goHome();
        return;
      }
      if (!silent) {
        _showSnack('Still not verified — check your inbox for the link.',
            success: false);
      }
    } catch (e) {
      if (!silent && mounted) {
        _showSnack(_authRepository.messageForError(e), success: false);
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await _authRepository.sendEmailVerification();
      if (!mounted) return;
      _showSnack('Verification email sent to ${widget.email}.', success: true);
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      _showSnack(_authRepository.messageForError(e), success: false);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown -= 1;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _signOut() async {
    await _authRepository.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(page: const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.softGreen,
                child: const Icon(Icons.mark_email_unread_outlined,
                    color: AppColors.mainGreen, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Verify your email',
                  style: AppTextStyles.headingLarge.copyWith(fontSize: 25)),
              const SizedBox(height: 8),
              Text(
                'We sent a verification link to ${widget.email}. '
                'Tap the link, then come back here — we\'ll pick it up '
                'automatically, or you can tap Continue.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isChecking ? null : () => _checkVerified(),
                  child: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('I\'ve Verified — Continue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed:
                      (_isResending || _resendCooldown > 0) ? null : _resend,
                  child: Text(
                    _resendCooldown > 0
                        ? 'Resend Email (${_resendCooldown}s)'
                        : 'Resend Email',
                    style: AppTextStyles.bodyRegular
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _signOut,
                  child: Text(
                    'Sign out',
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: AppColors.autumnRust,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
