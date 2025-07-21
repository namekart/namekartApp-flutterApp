// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../storageClasses/DBdetails.dart';

class ApiService {
  final String _baseUrl = 'https://amp2-1.politesky-7d4012d0.westus.azurecontainerapps.io/callback/nkapp'; // **UPDATE THIS TO YOUR SERVER URL**

  Future<List<DBdetails>> fetchBiddingList(String api) async {
    final String url = '$_baseUrl$api';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),  // empty JSON object
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => DBdetails.fromJson(json)).toList();
      } else {
        print('Failed to load bidding list: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load bidding list');
      }
    } catch (e) {
      print('Error fetching bidding list: $e');
      throw Exception('Error fetching bidding list: $e');
    }
  }
}