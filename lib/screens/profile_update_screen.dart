import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'dart:io';

class ProfileUpdateScreen extends ConsumerStatefulWidget {
  const ProfileUpdateScreen({Key? key}) : super(key: key);

  @override
  _ProfileUpdateScreenState createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends ConsumerState<ProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _idNationaleController;
  late TextEditingController _passwordController;
  XFile? _photo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider);
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _nomController = TextEditingController(text: user?.nom ?? '');
    _prenomController = TextEditingController(text: user?.prenom ?? '');
    _idNationaleController = TextEditingController(text: user?.idNationale ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _idNationaleController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photo = pickedFile;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).updateProfile(
        username: _usernameController.text,
        email: _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        nom: _nomController.text.isEmpty ? null : _nomController.text,
        prenom: _prenomController.text.isEmpty ? null : _prenomController.text,
        idNationale: ref.read(authProvider)?.role == 'client' && _idNationaleController.text.isNotEmpty
            ? _idNationaleController.text
            : null,
        newPassword: _passwordController.text.isEmpty ? null : _passwordController.text,
        photo: _photo,
        service: null,
        poste: null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mettre à jour'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0), // Reduced padding
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Nom d\'utilisateur'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Requis' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Requis' : !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)
                          ? 'Email invalide'
                          : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Adresse'),
                ),
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                ),
                if (user?.role == 'client')
                  TextFormField(
                    controller: _idNationaleController,
                    decoration: const InputDecoration(labelText: 'ID National'),
                  ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Nouveau mot de passe (optionnel)'),
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                _photo != null
                    ? Image.file(File(_photo!.path), height: 80, width: 80)
                    : user?.photo != null
                        ? Image.network(user!.photo!, height: 80, width: 80)
                        : const Icon(Icons.person, size: 80),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Choisir photo'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Mettre à jour'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}