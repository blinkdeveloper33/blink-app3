import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_category.dart';

class TransactionService {
  final http.Client client;
  final String baseUrl;

  TransactionService({http.Client? client})
      : client = client ?? http.Client(),
        baseUrl = dotenv.env['API_URL'] ??
            'https://1f33-12-162-124-34.ngrok-free.app';

  Future<void> updateTransactionCategory({
    required String transactionId,
    required TransactionCategory category,
  }) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/transactions/$transactionId/category'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['API_TOKEN']}',
        },
        body: jsonEncode({
          'category': category.toJson(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update transaction category');
      }
    } catch (e) {
      throw Exception('Error updating transaction category: $e');
    }
  }

  Future<List<TransactionCategory>> getCustomCategories() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/transactions/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['API_TOKEN']}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TransactionCategory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch custom categories');
      }
    } catch (e) {
      throw Exception('Error fetching custom categories: $e');
    }
  }

  Future<void> createCustomCategory(TransactionCategory category) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/transactions/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['API_TOKEN']}',
        },
        body: jsonEncode(category.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create custom category');
      }
    } catch (e) {
      throw Exception('Error creating custom category: $e');
    }
  }
}
