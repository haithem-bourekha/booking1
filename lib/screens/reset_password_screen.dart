import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ApiService()));

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String username;
  final String email;

  const ResetPasswordScreen({super.key, required this.username, required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _error;

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context);
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() {
        _error = l10n.translate('passwords_do_not_match') ?? 'Passwords do not match';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _error = l10n.translate('password_too_short') ?? 'Password must be at least 8 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(widget.username, widget.email, password);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('password_reset_success') ?? 'Password reset successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      setState(() {
        _error = '${l10n.translate('error') ?? 'Error'}: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                SvgPicture.asset(
                  'assets/images/reset_password.svg',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.translate('reset_password') ?? 'Reset Password',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.translate('enter_new_password') ?? 'Enter your new password to continue',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('new_password') ?? 'New Password',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 245, 245, 245),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) =>
                      value == null || value.isEmpty ? l10n.translate('field_required') ?? 'Field required' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('confirm_password') ?? 'Confirm Password',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 245, 245, 245),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                  ),
                  obscureText: !_isConfirmPasswordVisible,
                  validator: (value) =>
                      value == null || value.isEmpty ? l10n.translate('field_required') ?? 'Field required' : null,
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                CustomButton(
                  text: l10n.translate('reset_password') ?? 'Reset Password',
                  onPressed: _resetPassword,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    l10n.translate('back_to_login') ?? 'Back to Login',
                    style: const TextStyle(color: Color.fromARGB(255, 73, 129, 249)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}