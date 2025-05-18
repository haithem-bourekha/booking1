import 'package:dio/dio.dart';
import '../models/task.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class TaskService {
  final ApiService _apiService;

  TaskService(this._apiService);

  Future<List<Task>> getTasks() async {
    try {
      final response = await _apiService.get(tasksEndpoint);
      print('Réponse de /api/tasks/: ${response.data}');
      if (response.data is List) {
        return (response.data as List).map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception('Réponse inattendue: pas une liste de tâches');
      }
    } on DioError catch (e) {
      print('Erreur DioError: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Erreur de récupération des tâches');
    }
  }

  Future<void> createTask({
    required int reservationId,
    required int roomId,
    required int serviceId,
    required String dateService,
    String? heureService,
  }) async {
    try {
      print('Création de la tâche avec: reservationId=$reservationId, roomId=$roomId, '
          'serviceId=$serviceId, dateService=$dateService, heureService=$heureService');
      await _apiService.post(
        tasksEndpoint,
        data: {
          'reservation_id': reservationId,
          'room_id': roomId,
          'service_id': serviceId,
          'date_service': dateService,
          'heure_service': heureService,
        },
      );
      print('Tâche créée avec succès');
    } on DioError catch (e) {
      print('Erreur DioError lors de la création: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Erreur de création de la tâche');
    }
  }

  Future<void> updateTask(int id, String etat, {String? dateService}) async {
    try {
      print('Mise à jour de la tâche $id avec etat=$etat, dateService=$dateService');
      final data = {'etat': etat};
      if (dateService != null) {
        data['date_service'] = dateService;
      }
      final response = await _apiService.patch(
        '$tasksEndpoint$id/',
        data: data,
      );
      print('Réponse de la mise à jour: ${response.data}');
    } on DioError catch (e) {
      print('Erreur DioError lors de la mise à jour: ${e.response?.data}');
      throw Exception(e.response?.data['detail'] ?? 'Erreur lors de la mise à jour');
    } catch (e) {
      print('Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<void> cancelTask(int id) async {
    try {
      print('Annulation de la tâche $id');
      final response = await _apiService.post(
        '$tasksEndpoint$id/cancel/',
        data: {}, // Empty payload, as CancelTaskView sets etat to 'annulee'
      );
      print('Réponse de l\'annulation: ${response.data}');
    } on DioError catch (e) {
      print('Erreur DioError lors de l\'annulation: ${e.response?.data}');
      throw Exception(e.response?.data['detail'] ?? 'Erreur lors de l\'annulation');
    } catch (e) {
      print('Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }
}