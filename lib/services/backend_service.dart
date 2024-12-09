import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendService {
  final String baseUrl = dotenv.env['BACKEND_URL']!;

  Future<String?> createLinkToken(String jwtToken, String userId) async {
    final url = Uri.parse('$baseUrl/api/plaid/create_link_token');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        return data['link_token'];
      } else {
        throw Exception(data['error']);
      }
    } else {
      throw Exception('Failed to create Link Token');
    }
  }

  Future<void> exchangePublicToken(
      String jwtToken, String publicToken, String userId) async {
    final url = Uri.parse('$baseUrl/api/plaid/exchange_public_token');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({
        'publicToken': publicToken,
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!data['success']) {
        throw Exception(data['error']);
      }
    } else {
      throw Exception('Failed to exchange Public Token');
    }
  }
}
