import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/utils/ui_utils.dart';
import 'package:mobile/widgets/brand_logo.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Focus nodes for stabilizing selection
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => _onFocusChange(_nameFocus, _nameController));
    _emailFocus.addListener(() => _onFocusChange(_emailFocus, _emailController));
    _phoneFocus.addListener(() => _onFocusChange(_phoneFocus, _phoneController));
    _passwordFocus.addListener(() => _onFocusChange(_passwordFocus, _passwordController));
    _confirmPasswordFocus.addListener(() => _onFocusChange(_confirmPasswordFocus, _confirmPasswordController));
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final newUser = await _authService.registerUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text,
          saveToFirestore: false, // Defer until vehicle is added
        );
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/add-vehicle',
            arguments: newUser,
          );
        }
      } catch (e) {
        if (mounted) {
          UIUtils.showSnackBar(context, UIUtils.getFriendlyErrorMessage(e), isError: true);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isFirstLogin = await authProvider.signInWithGoogle();
      if (mounted) {
        if (isFirstLogin) {
          Navigator.pushReplacementNamed(context, '/add-vehicle');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showSnackBar(context, UIUtils.getFriendlyErrorMessage(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // Logo section
                  const Center(
                    child: Column(
                      children: [
                        BrandLogo(size: 80),
                        SizedBox(height: 12),
                         Text(
                          'SmartPark',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        Text(
                          'Your Parking Solution',
                          style: TextStyle(color: Color.fromARGB(255, 112, 112, 112)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Register to get started',
                    style: TextStyle(color: Color.fromARGB(255, 112, 112, 112)),
                  ),

                  const SizedBox(height: 24),

                  // Full Name
                  _buildLabel('Full Name'),
                  _buildTextField(
                    keyName: 'nameField',
                    hint: 'Enter full name',
                    icon: Icons.person,
                    controller: _nameController,
                    focusNode: _nameFocus,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty ? 'Name is required' : null,
                  ),

                  const SizedBox(height: 17),

                  // Email
                  _buildLabel('Email'),
                  _buildTextField(
                    keyName: 'emailField',
                    hint: 'Enter email address',
                    icon: Icons.email,
                    controller: _emailController,
                    focusNode: _emailFocus,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 17),

                  // Phone Number
                  _buildLabel('Phone Number'),
                  _buildTextField(
                    keyName: 'phoneField',
                    hint: '0771234567',
                    icon: Icons.phone,
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                        return 'Enter exactly 10 digits';
                       }
                      return null;
                    },
                  ),

                  const SizedBox(height: 17),

                  // Password
                  _buildLabel('Password'),
                  _buildTextField(
                    keyName: 'passwordField',
                    hint: 'Password',
                    icon: Icons.lock,
                    obscure: _obscurePassword,
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    textInputAction: TextInputAction.next,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF6E6D74),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Password is required';
                      if (value.length < 8) return 'Password must be at least 8 characters';
                      if (!RegExp(
                        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$',
                      ).hasMatch(value)) {
                        return 'Include at least one a-z, A-Z, and number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 17),

                  // Confirm Password
                  _buildLabel('Confirm Password'),
                  _buildTextField(
                    keyName: 'confirmPasswordField',
                    hint: 'Confirm Password',
                    icon: Icons.lock,
                    obscure: _obscureConfirmPassword,
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _register(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF6E6D74),
                      ),
                      onPressed:
                          () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Confirm password is required';
                      }
                      if (value != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Register button
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  const Center(child: Text('OR')),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: Image.network(
                      'https://developers.google.com/identity/images/g-logo.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.g_mobiledata, color: Colors.blue, size: 30);
                      },
                    ),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Color.fromARGB(255, 112, 112, 112)),
                      foregroundColor: AppColors.primaryColor,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Already have account
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Already have an account? '),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/signIn'),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Label widget
  static Widget _buildLabel(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 9),
      ],
    );
  }

  // TextField widget
  static Widget _buildTextField({
    required String hint,
    required IconData icon,
    String? keyName,
    bool obscure = false,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      key: keyName != null ? ValueKey(keyName) : null,
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(color: Colors.black),
      onTap: () {
        // Delay ensures we catch the selection after the tap is processed
        Future.delayed(const Duration(milliseconds: 100), () {
          if (controller != null && !controller.selection.isCollapsed) {
            controller.selection = TextSelection.collapsed(
              offset: controller.selection.extentOffset,
            );
          }
        });
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.inputBackground,
        prefixIcon: Icon(icon, color: const Color(0xFF6E6D74)),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6E6D74)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      validator: validator,
    );
  }
}
