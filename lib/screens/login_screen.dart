import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../l10n/app_localizations.dart';
import 'signup_screen.dart';
import 'employee_home_screen.dart';
import 'client_home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _isPasswordVisible = false; // Added for password visibility toggle

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        print('Tentative de connexion avec email: ${_emailController.text}');
        await ref.read(authProvider.notifier).login(
              _emailController.text,
              _passwordController.text,
            );
        final user = ref.read(authProvider);
        print('Utilisateur connecté: ${user?.username}, rôle: ${user?.role}');
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => user.role == 'employee'
                  ? const EmployeeHomeScreen()
                  : const ClientHomeScreen(),
            ),
          );
        } else {
          setState(() {
            _error = 'Utilisateur non chargé après connexion';
          });
        }
      } catch (e) {
        print('Erreur de connexion: $e');
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/login.svg',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.translate('sign_in') ?? 'Sign in',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.translate('welcome_login') ?? 'Hi Welcome! Continue to login',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.translate('username') ?? 'UserName',
                  filled: true,
                  fillColor: const Color.fromARGB(255, 245, 245, 245),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? l10n.translate('field_required') ?? 'Champ requis' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.translate('password') ?? 'Password',
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
                    value!.isEmpty ? l10n.translate('field_required') ?? 'Champ requis' : null,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    l10n.translate('forgot_password') ?? 'Forgot Password',
                    style: const TextStyle(color: Color.fromARGB(255, 73, 164, 245)),
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
                text: l10n.translate('sign_in') ?? 'Sign in',
                onPressed: _login,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(l10n.translate('or_sign_in_with') ?? 'Or Sign in with'),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.g_mobiledata, color: Colors.black, size: 40),
                  SizedBox(width: 20),
                  Icon(Icons.facebook, color: Colors.blue, size: 40),
                  SizedBox(width: 20),
                  Icon(Icons.apple, color: Colors.black, size: 40),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                child: Text(
                  l10n.translate('dont_have_account') ?? 'Don\'t have an account? Sign up',
                  style: const TextStyle(color: Color.fromARGB(255, 78, 136, 245)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}