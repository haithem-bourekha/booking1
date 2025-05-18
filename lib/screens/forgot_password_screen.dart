import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/app_localizations.dart';
import 'reset_password_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ApiService()));

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  int _currentStep = 1; // 1: Username, 2: Email, 3: Code
  bool _isLoading = false;
  String? _error;

  Future<void> _verifyUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _error = AppLocalizations.of(context).translate('username_required') ?? 'Username required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.forgotPasswordStep1(username);
      setState(() {
        _currentStep = 2;
      });
    } catch (e) {
      setState(() {
        _error = '${AppLocalizations.of(context).translate('error') ?? 'Error'}: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendCode() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    if (username.isEmpty || email.isEmpty) {
      setState(() {
        _error = AppLocalizations.of(context).translate('username_email_required') ?? 'Username and email required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.forgotPasswordStep2(username, email);
      setState(() {
        _currentStep = 3;
      });
    } catch (e) {
      setState(() {
        _error = '${AppLocalizations.of(context).translate('error') ?? 'Error'}: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _error = AppLocalizations.of(context).translate('code_required') ?? 'Code required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyResetCode(username, email, code);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(username: username, email: email),
        ),
      );
    } catch (e) {
      setState(() {
        _error = '${AppLocalizations.of(context).translate('error') ?? 'Error'}: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              SvgPicture.asset(
                'assets/images/forgot_password.svg',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.translate('forgot_password') ?? 'Forgot Password',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.translate('recover_password') ?? 'Recover your password in a few steps',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              if (_currentStep == 1) ...[
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('username') ?? 'Username',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 245, 245, 245),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
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
                  text: l10n.translate('next') ?? 'Next',
                  onPressed: _verifyUsername,
                  isLoading: _isLoading,
                ),
              ] else if (_currentStep == 2) ...[
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('username') ?? 'Username',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 245, 245, 245),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('email') ?? 'Email',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 245, 245, 245),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
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
                  text: l10n.translate('send_code') ?? 'Send Code',
                  onPressed: _sendCode,
                  isLoading: _isLoading,
                ),
              ] else if (_currentStep == 3) ...[
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('username') ?? 'Username',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 245, 245, 245),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('email') ?? 'Email',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 245, 245, 245),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('enter_code') ?? 'Enter Code',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 245, 245, 245),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
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
                  text: l10n.translate('verify_code') ?? 'Verify Code',
                  onPressed: _verifyCode,
                  isLoading: _isLoading,
                ),
              ],
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
    );
  }
}