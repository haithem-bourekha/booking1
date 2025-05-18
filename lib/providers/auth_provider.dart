// auth_provider.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../constants/api_constants.dart';

class AuthNotifier extends StateNotifier<User?> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService(ApiService());

  AuthNotifier() : super(null);

  Future<void> login(String username, String password) async {
    try {
      final user = await _authService.login(username, password);
      state = user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> requestResetCode(String email) async {
    try {
      await _apiService.post('/forgot-password/', data: {'email': email});
    } catch (e) {
      throw Exception('Failed to send reset code: $e');
    }
  }

  Future<void> verifyResetCode(String email, String code, String newPassword) async {
    try {
      final response = await _apiService.post('/verify-reset-code/', data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      });
      final user = User.fromJson(response.data['user']);
      state = user;
    } catch (e) {
      throw Exception('Failed to verify reset code: $e');
    }
  }

  Future<void> resetPassword(String email, String newPassword) async {
    try {
      final response = await _apiService.post('/verify-reset-code/', data: {
        'email': email,
        'code': '',
        'new_password': newPassword,
      });
      final user = User.fromJson(response.data['user']);
      state = user;
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  Future<void> signup({
    required String username,
    required String email,
    required String password,
    String? nom,
    String? prenom,
    String? phone,
    String? address,
    String? idNationale,
  }) async {
    try {
      final user = await _authService.signup(
        username: username,
        email: email,
        password: password,
        nom: nom,
        prenom: prenom,
        phone: phone,
        address: address,
        idNationale: idNationale,
      );
      state = user;
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  Future<void> updateProfile({
    String? username,
    String? email,
    String? nom,
    String? prenom,
    String? phone,
    String? address,
    String? idNationale,
    String? newPassword,
    XFile? photo,
    int? service,
    int? poste,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (username != null && username.isNotEmpty) 'username': username,
        if (email != null && email.isNotEmpty) 'email': email,
        if (nom != null) 'nom': nom,
        if (prenom != null) 'prenom': prenom,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (idNationale != null) 'id_nationale': idNationale,
        if (newPassword != null && newPassword.isNotEmpty) 'password': newPassword,
        if (service != null) 'service': service,
        if (poste != null) 'poste': poste,
      });

      if (photo != null) {
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          formData.files.add(MapEntry(
            'photo',
            MultipartFile.fromBytes(
              bytes,
              filename: photo.name,
            ),
          ));
        } else {
          formData.files.add(MapEntry(
            'photo',
            await MultipartFile.fromFile(
              photo.path,
              filename: photo.name,
            ),
          ));
        }
      }

      print('Sending FormData fields: ${formData.fields}');
      print('Sending FormData files: ${formData.files}');

      final response = await _apiService.put(profileEndpoint, data: formData);
      print('Response data: ${response.data}');

      Map<String, dynamic> userJson = response.data;
      if (userJson.containsKey('user')) {
        userJson = userJson['user'];
      }

      if (userJson['id'] == null) {
        throw Exception('User ID is missing in the response');
      }

      final updatedUser = User.fromJson(userJson);
      state = updatedUser;
    } on DioException catch (e) {
      if (e.response != null) {
        print('Error response data: ${e.response?.data}');
        throw Exception('Failed to update profile: ${e.response?.data}');
      }
      throw Exception('Failed to update profile: $e');
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  void setUser(User user) {
    state = user;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});