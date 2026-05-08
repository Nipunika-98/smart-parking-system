import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/utils/ui_utils.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _currentFocus.addListener(() => _onFocusChange(_currentFocus, _currentPasswordController));
    _newFocus.addListener(() => _onFocusChange(_newFocus, _newPasswordController));
    _confirmFocus.addListener(() => _onFocusChange(_confirmFocus, _confirmPasswordController));
  }

  void _onFocusChange(FocusNode node, TextEditingController controller) {
    if (node.hasFocus && controller.text.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!controller.selection.isCollapsed) {
          controller.selection = TextSelection.collapsed(
            offset: controller.selection.extentOffset,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.changePassword(
          _currentPasswordController.text,
          _newPasswordController.text,
        );
        if (mounted) {
          UIUtils.showSnackBar(
            context,
            'Password updated successfully',
            isError: false,
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = UIUtils.getFriendlyErrorMessage(e);
          if (errorMessage.toLowerCase().contains('password') || 
              errorMessage.toLowerCase().contains('credential')) {
            errorMessage = 'Please enter correct password';
          }
          UIUtils.showSnackBar(
            context,
            errorMessage,
            isError: true,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        elevation: 0,
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a new password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your new password must be different from previous used passwords.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              _buildPasswordField(
                keyName: 'currentPasswordField',
                label: 'Current Password',
                controller: _currentPasswordController,
                focusNode: _currentFocus,
                obscure: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                keyName: 'newPasswordField',
                label: 'New Password',
                controller: _newPasswordController,
                focusNode: _newFocus,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a new password';
                  if (value.length < 8) return 'Minimum 8 characters required';
                  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$').hasMatch(value)) {
                    return 'Must include a-z, A-Z, and numbers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                keyName: 'confirmPasswordField',
                label: 'Confirm New Password',
                controller: _confirmPasswordController,
                focusNode: _confirmFocus,
                obscure: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _updatePassword(),
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
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

  Widget _buildPasswordField({
    required String keyName,
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey(keyName),
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          autocorrect: false,
          enableSuggestions: false,
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (!controller.selection.isCollapsed) {
                controller.selection = TextSelection.collapsed(
                  offset: controller.selection.extentOffset,
                );
              }
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: onToggle,
            ),
          ),
          validator:
              validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your password';
                }
                return null;
              },
        ),
      ],
    );
  }
}
