import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class PaletKayitApi {
  PaletKayitApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// POST: /Kantar/paletkayit
  /// JSON Body:
  /// {
  ///   "paletler": [...],
  ///   "id": "..."
  /// }
  ///
  /// Başarılı olursa true döner, değilse Exception fırlatır.
  Future<bool> paletKayit({
    required List<dynamic> paletler,
    required String id,
  }) async {
    final Uri uri = Uri.parse('${App.insideurl}/Kantar/paletkayit');

    final payload = <String, dynamic>{
      'paletler': paletler,
      'id': id,
    };

    try {
      final http.Response response = await _client.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Palet kayıt başarısız. '
          'Status: ${response.statusCode} Body: ${response.body}',
        );
      }

      return true;
    } catch (e) {
      throw Exception('PaletKayitApi.paletKayit hata: $e');
    }
  }
}
