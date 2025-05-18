import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';
import 'client_home_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _idNationaleController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _idNationaleController.dispose();
    super.dispose();
  }

  Future<void> _signup(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        await ref.read(authProvider.notifier).signup(
              username: _usernameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              nom: _nomController.text,
              prenom: _prenomController.text,
              phone: _phoneController.text,
              address: _addressController.text,
              idNationale: _idNationaleController.text,
            );
        final l10n = AppLocalizations.of(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.translate('welcome') ?? 'Bienvenue !'),
            content: Text(
              'Inscription réussie, ${l10n.translate('welcome') ?? 'Welcome'} ${_prenomController.text}!',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        setState(() {
          _error = e.toString();
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                SvgPicture.asset(
                  'assets/images/signup.svg',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.translate('sign_up') ?? 'Sign up',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.translate('welcome_signup') ?? 'Hi Welcome! Continue to signup',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
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
                  validator: (value) =>
                      value == null || value.isEmpty ? l10n.translate('field_required') ?? 'Field required' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
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
                  validator: (value) =>
                      value == null || !value.contains('@') ? l10n.translate('invalid_email') ?? 'Invalid email' : null,
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
                      value == null || value.length < 6
                          ? l10n.translate('password_too_short') ?? 'Password too short'
                          : null,
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nomController,
                        decoration: InputDecoration(
                          labelText: l10n.translate('nom') ?? 'Nom',
                          filled: true,
                          fillColor: const Color.fromARGB(255, 245, 245, 245),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _prenomController,
                        decoration: InputDecoration(
                          labelText: l10n.translate('prenom') ?? 'Prénom',
                          filled: true,
                          fillColor: const Color.fromARGB(255, 245, 245, 245),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('phone') ?? 'Téléphone',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 245, 245, 245),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('address') ?? 'Adresse',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 245, 245, 245),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _idNationaleController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('id_nationale') ?? 'ID Nationale',
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
                  text: l10n.translate('sign_up') ?? 'Sign up',
                  onPressed: () => _signup(context),
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
                    l10n.translate('already_have_account') ?? 'Already have an account? Login',
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