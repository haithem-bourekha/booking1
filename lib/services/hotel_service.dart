import 'package:dio/dio.dart';
import '../models/hotel.dart';
import '../models/comment.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class HotelService {
    final ApiService _apiService;

    HotelService(this._apiService);

    Future<List<Hotel>> getHotels() async {
        try {
            final response = await _apiService.get(hotelsEndpoint);
            print('Réponse des hôtels : ${response.data}');
            return (response.data as List).map((json) => Hotel.fromJson(json)).toList();
        } on DioError catch (e) {
            print('Erreur Dio lors de la récupération des hôtels : ${e.response?.data}');
            throw Exception(e.response?.data.toString() ?? 'Erreur de récupération des hôtels');
        }
    }

    Future<List<Comment>> getComments(int hotelId) async {
        try {
            final url = commentsEndpoint.replaceFirst('%s', hotelId.toString());
            print('URL de la requête : $url');
            final response = await _apiService.get(url);
            print('Réponse des commentaires : ${response.data}');
            return (response.data as List).map((json) => Comment.fromJson(json)).toList();
        } on DioError catch (e) {
            print('Erreur Dio lors de la récupération des commentaires : ${e.response?.data}');
            throw Exception(e.response?.data.toString() ?? 'Erreur de récupération des commentaires');
        }
    }

    Future<int> getReviewCount(int hotelId) async {
        final comments = await getComments(hotelId);
        return comments.length;
    }

    Future<void> addComment(int hotelId, Comment comment) async {
        try {
            await _apiService.post(
                commentsEndpoint.replaceFirst('%s', hotelId.toString()),
                data: {
                    'rating': comment.rating,
                    'text': comment.text,
                    'hotel': comment.hotel,
                },
            );
        } on DioError catch (e) {
            throw Exception(e.response?.data.toString() ?? 'Erreur lors de l\'ajout du commentaire');
        }
    }

    Future<void> editComment(int hotelId, int commentId, Comment comment) async {
        try {
            await _apiService.put(
                '${commentsEndpoint.replaceFirst('%s', hotelId.toString())}$commentId/',
                data: {
                    'rating': comment.rating,
                    'text': comment.text,
                    'hotel': comment.hotel,
                },
            );
        } on DioError catch (e) {
            throw Exception(e.response?.data.toString() ?? 'Erreur lors de la modification du commentaire');
        }
    }

    Future<void> deleteComment(int hotelId, int commentId) async {
        try {
            await _apiService.delete(
                '${commentsEndpoint.replaceFirst('%s', hotelId.toString())}$commentId/',
            );
        } on DioError catch (e) {
            throw Exception(e.response?.data.toString() ?? 'Erreur lors de la suppression du commentaire');
        }
    }

    Future<void> addAdminResponse(int hotelId, int commentId, String response) async {
        try {
            await _apiService.put(
                '${commentsEndpoint.replaceFirst('%s', hotelId.toString())}$commentId/',
                data: {
                    'admin_response': response,
                },
            );
        } on DioError catch (e) {
            throw Exception(e.response?.data.toString() ?? 'Erreur lors de l\'ajout de la réponse admin');
        }
    }

    Future<void> deletePhoto(int hotelId, int photoId) async {
        try {
            await _apiService.delete('$hotelsEndpoint$hotelId/photos/$photoId/');
        } on DioError catch (e) {
            throw Exception(e.response?.data.toString() ?? 'Erreur lors de la suppression de la photo');
        }
    }
}