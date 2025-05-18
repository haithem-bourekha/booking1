import 'package:dio/dio.dart';
import '../models/user.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  Future<User> login(String username, String password) async {
    try {
      final response = await _apiService.post(
        loginEndpoint,
        data: {'username': username, 'password': password},
      );
      await _apiService.saveTokens(
        response.data['access'],
        response.data['refresh'],
      );
      return User.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Erreur de connexion');
    }
  }

  Future<User> signup({
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
      final response = await _apiService.post(
        signupEndpoint,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'nom': nom,
          'prenom': prenom,
          'phone': phone,
          'address': address,
          'id_nationale': idNationale,
          'role': 'client',
        },
      );
      await _apiService.saveTokens(
        response.data['access'],
        response.data['refresh'],
      );
      return User.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Erreur d\'inscription');
    }
  }

  Future<User> getProfile() async {
    try {
      final response = await _apiService.get(profileEndpoint);
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Erreur de récupération du profil');
    }
  }

  Future<User> updateProfile({
    String? username,
    String? email,
    String? nom,
    String? prenom,
    String? phone,
    String? address,
    String? idNationale,
    String? photo,
  }) async {
    try {
      final response = await _apiService.put(
        profileEndpoint,
        data: {
          'username': username,
          'email': email,
          'nom': nom,
          'prenom': prenom,
          'phone': phone,
          'address': address,
          'id_nationale': idNationale,
          'photo': photo,
        },
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Erreur de mise à jour du profil');
    }
  }

  Future<void> logout() async {
    await _apiService.clearTokens();
  }

  Future<void> forgotPasswordStep1(String username) async {
    try {
      final response = await _apiService.post(
        forgotPasswordStep1Endpoint,
        data: {'username': username},
      );
      if (response.data['email_required'] != true) {
        throw Exception('Unexpected response');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Erreur lors de la vérification du username');
    }
  }

  Future<void> forgotPasswordStep2(String username, String email) async {
    try {
      final response = await _apiService.post(
        forgotPasswordStep2Endpoint,
        data: {'username': username, 'email': email},
      );
      if (response.data['code_required'] != true) {
        throw Exception('Unexpected response');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Erreur lors de l\'envoi du code');
    }
  }

  Future<void> verifyResetCode(String username, String email, String code) async {
    try {
      final response = await _apiService.post(
        verifyResetCodeEndpoint,
        data: {'username': username, 'email': email, 'code': code},
      );
      if (response.data['message'] != 'Code vérifié avec succès. Entrez un nouveau mot de passe.') {
        throw Exception('Unexpected response');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Erreur lors de la vérification du code');
    }
  }

  Future<void> resetPassword(String username, String email, String newPassword) async {
    try {
      final response = await _apiService.post(
        resetPasswordEndpoint, // Nouvelle constante à ajouter
        data: {'username': username, 'email': email, 'new_password': newPassword},
      );
      if (response.data['message'] != 'Mot de passe réinitialisé avec succès.') {
        throw Exception('Unexpected response');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Erreur lors de la réinitialisation du mot de passe');
    }
  }
}