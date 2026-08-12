import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class IsListesiApi {
  IsListesiApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// GET: /Sera/Islistesi
  ///
  /// Model yoksa: List<Map<String,dynamic>> döndürmek en temiz yol.
  Future<List<Map<String, dynamic>>> seraIsListesi() async {
    final Uri uri = Uri.parse('${App.insideurl}/Sera/Islistesi');

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Sera iş listesi alınamadı. '
          'Status: ${response.statusCode} Body: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Beklenen JSON liste değil: ${response.body}');
      }

      return decoded
          .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
          .toList();
    } catch (e) {
      throw Exception('seraIsListesi API hatası: $e');
    }
  }
}
