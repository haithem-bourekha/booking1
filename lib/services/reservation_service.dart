import 'package:dio/dio.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class ReservationService {
  final ApiService _apiService;

  ReservationService(this._apiService);

  Future<List<Reservation>> getReservations() async {
    try {
      final response = await _apiService.get(reservationsEndpoint);
      print('Réponse de /api/reservations/reservations/: ${response.data}');
      if (response.data is List) {
        return (response.data as List).map((json) => Reservation.fromJson(json)).toList();
      } else {
        print('Erreur: Réponse inattendue, pas une liste');
        throw Exception('La réponse de l\'API n\'est pas une liste de réservations');
      }
    } on DioError catch (e) {
      print('Erreur DioError: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Erreur de récupération des réservations');
    } catch (e) {
      print('Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<List<Room>> getAvailableRooms() async {
    try {
      final response = await _apiService.get(availableRoomsEndpoint);
      print('Réponse de /api/rooms/rooms/search/: ${response.data}');
      if (response.data is List) {
        return (response.data as List).map((json) => Room.fromJson(json)).toList();
      } else {
        print('Erreur: Réponse inattendue, pas une liste');
        throw Exception('La réponse de l\'API n\'est pas une liste de chambres disponibles');
      }
    } on DioError catch (e) {
      print('Erreur DioError: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Erreur de récupération des chambres disponibles');
    } catch (e) {
      print('Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<Response> createReservation({
    required int roomId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int nombreAdultes,
    required int nombreEnfants,
    required List<int> services,
    required Map<int, List<DateTime>> serviceDays,
  }) async {
    try {
      final response = await _apiService.post(
        reservationsEndpoint,
        data: {
          'room_id': roomId,
          'date_debut': checkInDate.toIso8601String().split('T')[0],
          'date_fin': checkOutDate.toIso8601String().split('T')[0],
          'nombre_adultes': nombreAdultes,
          'nombre_enfants': nombreEnfants,
          'services': services,
          'service_days': {
            for (var entry in serviceDays.entries)
              entry.key.toString(): entry.value.map((date) => date.toIso8601String().split('T')[0]).toList(),
          },
        },
      );
      print('Réponse de POST /api/reservations/reservations/: ${response.data}');
      return response;
    } on DioError catch (e) {
      print('Erreur DioError: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Erreur de création de la réservation');
    } catch (e) {
      print('Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<void> cancelReservation(int reservationId) async {
    try {
      print('Tentative d\'annulation de la réservation $reservationId');
      final response = await _apiService.post(
        '$reservationsEndpoint$reservationId/cancel/',
        data: {},
      );
      print('Réponse de l\'annulation: ${response.data}');
    } on DioError catch (e) {
      print('Erreur DioError lors de l\'annulation: ${e.response?.data}');
      if (e.response != null && e.response!.data is Map && e.response!.data.containsKey('detail')) {
        throw Exception(e.response!.data['detail']);
      }
      throw Exception('Erreur d\'annulation de la réservation');
    } catch (e) {
      print('Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<void> updateReservation(
    int id,
    {required DateTime checkInDate,
    required DateTime checkOutDate,
    required int nombreAdultes,
    required int nombreEnfants,
    required int roomTypeId,
  }) async {
    try {
      print('Mise à jour de la réservation $id avec: checkIn=$checkInDate, checkOut=$checkOutDate, '
          'adultes=$nombreAdultes, enfants=$nombreEnfants, roomTypeId=$roomTypeId');
      await _apiService.patch(
        '$reservationsEndpoint$id/',
        data: {
          'check_in_date': checkInDate.toIso8601String().split('T')[0],
          'check_out_date': checkOutDate.toIso8601String().split('T')[0],
          'nombre_adultes': nombreAdultes,
          'nombre_enfants': nombreEnfants,
          'room_id': roomTypeId,
        },
      );
      print('Réservation $id mise à jour avec succès');
    } on DioError catch (e) {
      print('Erreur DioError lors de la mise à jour: ${e.response?.data}');
      throw Exception(e.response?.data['detail'] ?? 'Erreur lors de la mise à jour');
    } catch (e) {
      print('Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }
}