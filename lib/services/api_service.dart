import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:blink_app/models/transaction.dart';
import 'package:blink_app/services/storage_service.dart';

class ApiService {
  final String baseUrl =
      'https://5000-idx-blinkbackend2-1731939610309.cluster-fnjdffmttjhy2qqdugh3yehhs2.cloudworkstations.dev';
  final StorageService _storageService;

  ApiService(this._storageService);

  Future<List<Transaction>> fetchAllTransactions() async {
    List<Transaction> allTransactions = [];
    int page = 1;
    bool hasMorePages = true;

    while (hasMorePages) {
      try {
        final response = await _fetchTransactionsPage(page);
        if (response['success'] == true) {
          final transactions = (response['data']['transactions'] as List)
              .map((json) => Transaction.fromJson(json))
              .toList();
          allTransactions.addAll(transactions);

          final pagination = response['data']['pagination'];
          if (page >= pagination['totalPages']) {
            hasMorePages = false;
          } else {
            page++;
          }
        } else {
          throw Exception('Failed to fetch transactions: ${response['error']}');
        }
      } catch (e) {
        throw Exception('Error fetching transactions: $e');
      }
    }

    return allTransactions;
  }

  Future<Map<String, dynamic>> _fetchTransactionsPage(int page) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/plaid/all-transactions?page=$page&pageSize=100'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please log in again');
    } else {
      throw Exception('Failed to load transactions: ${response.statusCode}');
    }
  }

  // Add more API methods here as needed, e.g., for other endpoints or data types
}
