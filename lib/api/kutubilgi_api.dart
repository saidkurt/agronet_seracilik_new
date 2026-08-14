import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class KutuBilgiApi {
  KutuBilgiApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// GET: /Kantar/Qr/{barkod}
  ///
  /// Model yoksa en güvenlisi:
  /// List<Map<String,dynamic>> dönmek
  Future<List<Map<String, dynamic>>> qrBilgi(String barkod) async {
    final Uri uri = Uri.parse('${App.outsideurl}/Kantar/Qr/$barkod');

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'QR bilgi alınamadı. '
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
      throw Exception('KutuBilgiApi.qrBilgi hata: $e');
    }
  }
}
