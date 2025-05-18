import 'package:dio/dio.dart';
import '../models/room.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class RoomService {
  final ApiService _apiService;

  RoomService(this._apiService);

  Future<List<Room>> getRooms() async {
    try {
      final response = await _apiService.get(roomsEndpoint);
      print('Réponse de /api/rooms/rooms/: ${response.data}');
      if (response.data is List) {
        return (response.data as List).map((json) => Room.fromJson(json)).toList();
      } else {
        print('Erreur: Réponse inattendue, pas une liste');
        throw Exception('La réponse de l\'API n\'est pas une liste de chambres');
      }
    } on DioError catch (e) {
      print('Erreur DioError: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Erreur de récupération des chambres');
    } catch (e) {
      print('Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<List<Room>> getFavoriteRooms() async {
    try {
      final response = await _apiService.get(favoritesEndpoint);
      print('Réponse de /api/rooms/favorites/: ${response.data}');
      if (response.data is List) {
        return (response.data as List)
            .map((json) => Room.fromJson(json['room']))
            .toList();
      } else {
        print('Erreur: Réponse inattendue, pas une liste');
        throw Exception('La réponse de l\'API n\'est pas une liste de favoris');
      }
    } on DioError catch (e) {
      print('Erreur DioError: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Erreur de récupération des favoris');
    } catch (e) {
      print('Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<bool> isFavorite(int roomId) async {
    try {
      final response = await _apiService.get(favoritesEndpoint);
      if (response.data is List) {
        return (response.data as List)
            .any((json) => json['room']['id'] == roomId);
      }
      return false;
    } on DioError catch (e) {
      print('Erreur DioError: ${e.response?.data}');
      return false;
    } catch (e) {
      print('Erreur inattendue: $e');
      return false;
    }
  }

  Future<void> addFavorite(int roomId) async {
    try {
      await _apiService.post(favoritesEndpoint, data: {'room_id': roomId});
    } on DioError catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Erreur d\'ajout aux favoris');
    }
  }

  Future<void> removeFavorite(int roomId) async {
    try {
      await _apiService.delete('$favoritesEndpoint$roomId/');
    } on DioError catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Erreur de suppression du favori');
    }
  }

  // Vérifier la disponibilité d'une chambre pour des dates données
  Future<bool> checkAvailability(int roomId, DateTime checkIn, DateTime checkOut) async {
    try {
      final response = await _apiService.get(reservationsEndpoint);
      print('Réponse de /api/reservations/reservations/: ${response.data}');
      if (response.data is List) {
        final reservations = (response.data as List);
        for (var reservation in reservations) {
          if (reservation['room']['id'] == roomId) {
            final DateTime reservationCheckIn = DateTime.parse(reservation['date_debut']);
            final DateTime reservationCheckOut = DateTime.parse(reservation['date_fin']);

            // Si les dates se chevauchent, la chambre n'est pas disponible
            if (!(checkOut.isBefore(reservationCheckIn) || checkIn.isAfter(reservationCheckOut))) {
              return false;
            }
          }
        }
        return true;
      } else {
        throw Exception('La réponse de l\'API n\'est pas une liste de réservations');
      }
    } on DioError catch (e) {
      print('Erreur DioError: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Erreur de vérification de disponibilité');
    } catch (e) {
      print('Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Trouver d'autres chambres disponibles du même type
  Future<List<Room>> findAlternativeRooms(Room room, DateTime checkIn, DateTime checkOut, int adults, int children) async {
    try {
      final allRooms = await getRooms();
      final sameTypeRooms = allRooms.where((r) => r.type.nom == room.type.nom && r.id != room.id).toList();
      final List<Room> availableRooms = [];

      for (var alternativeRoom in sameTypeRooms) {
        // Vérifier la disponibilité pour les dates
        final isAvailable = await checkAvailability(alternativeRoom.id, checkIn, checkOut);
        // Vérifier la capacité
        final totalPeople = adults + children;
        final roomCapacity = alternativeRoom.type.maxAdulte + alternativeRoom.type.maxEnfant;

        if (isAvailable && totalPeople <= roomCapacity) {
          availableRooms.add(alternativeRoom);
        }
      }

      return availableRooms;
    } on DioError catch (e) {
      print('Erreur DioError: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Erreur de recherche de chambres alternatives');
    } catch (e) {
      print('Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }
}