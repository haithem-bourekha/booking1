import 'package:dio/dio.dart';
import '../models/service.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class ServiceService {
  final ApiService _apiService;

  ServiceService(this._apiService);

  Future<List<Service>> getServices() async {
    try {
      final response = await _apiService.get(servicesEndpoint);
      print('Réponse de /api/services/services/: ${response.data}');
      if (response.data is List) {
        return (response.data as List)
            .map((json) => Service.fromJson(json))
            .toList();
      } else {
        print('Erreur: Réponse inattendue, pas une liste');
        throw Exception('La réponse de l\'API n\'est pas une liste de services');
      }
    } on DioError catch (e) {
      print('Erreur DioError: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Erreur de récupération des services');
    } catch (e) {
      print('Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }
}