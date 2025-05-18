import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/invoice.dart';
import 'api_service.dart';

class InvoiceService {
  final ApiService _apiService;

  InvoiceService(this._apiService);

  Future<List<Invoice>> getInvoices() async {
    try {
      final response = await _apiService.get(invoicesEndpoint);
      if (response.data is List) {
        return (response.data as List)
            .map((json) => Invoice.fromJson(json))
            .toList();
      } else {
        throw Exception('Invalid data format: Expected a list of invoices');
      }
    } on DioError catch (e) {
      print('Error fetching invoices: ${e.response?.data ?? e.message}');
      throw Exception(e.response?.data['error'] ?? 'Erreur lors de la récupération des factures');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<Map<String, dynamic>> payInvoice({
    required int invoiceId,
    required String paymentMethod,
    required String cardNumber,
    required String cardExpiry,
    required String cardCvc,
  }) async {
    try {
      final response = await _apiService.post(
        '$invoicesEndpoint$invoiceId/pay/',
        data: {
          'payment_method': paymentMethod,
          'card_number': cardNumber,
          'card_expiry': cardExpiry,
          'card_cvc': cardCvc,
        },
      );
      return response.data; // Retourne les données de la réponse
    } on DioError catch (e) {
      print('Payment error: ${e.response?.data ?? e.message}');
      throw Exception(e.response?.data['error'] ?? 'Erreur de paiement');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }
}