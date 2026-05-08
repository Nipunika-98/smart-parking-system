import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/utils/ui_utils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  final _emailFocus = FocusNode();
  bool _isLoading = false;

  Timer? _timer;
  int _countdownSeconds = 0;
  bool _isCooldownActive = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => _onFocusChange());
  }

  void _onFocusChange() {
    if (_emailFocus.hasFocus && _emailController.text.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_emailController.selection.isCollapsed) {
          _emailController.selection = TextSelection.collapsed(
            offset: _emailController.selection.extentOffset,
          );
        }
      });
    }
  }

  void _startCooldown() {
    setState(() {
      _isCooldownActive = true;
      _countdownSeconds = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds == 0) {
        setState(() {
          _isCooldownActive = false;
          timer.cancel();
        });
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      UIUtils.showSnackBar(context, 'Please enter your email address', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;

      _startCooldown();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Reset Link Sent', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text(
                'A password reset link has been sent to $email. Please check your inbox.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
      );
    } catch (e) {
      if (!mounted) return;
      UIUtils.showSnackBar(context, UIUtils.getFriendlyErrorMessage(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter the email address associated with your account and we\'ll send you a link to reset your password.',
              style: TextStyle(color: Color(0xFF6E6D74), fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 40),
            const Text(
              'Email Address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 9),
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.black),
              onTap: () {
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (!_emailController.selection.isCollapsed) {
                    _emailController.selection = TextSelection.collapsed(
                      offset: _emailController.selection.extentOffset,
                    );
                  }
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFF3F4F6),
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6E6D74)),
                hintText: 'Enter your email',
                hintStyle: const TextStyle(color: Color(0xFF6E6D74)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (_isLoading || _isCooldownActive) ? null : _sendResetLink,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                      : Text(
                        _isCooldownActive ? 'Resend Link in $_countdownSeconds' : 'Send Reset Link',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
            ),
            if (_isCooldownActive)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    'Didn\'t receive the email? Wait for the timer to resend.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
