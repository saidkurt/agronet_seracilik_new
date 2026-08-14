import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class PaletTipApi {
  PaletTipApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// GET: /Serapaket/Palet
  ///
  /// Model yoksa en stabil dönüş:
  /// List<Map<String, dynamic>>
  Future<List<Map<String, dynamic>>> paletTipleri() async {
    final Uri uri = Uri.parse('${App.outsideurl}/Serapaket/Palet');

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Palet tipleri alınamadı. '
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
      throw Exception('PaletTipApi.paletTipleri hata: $e');
    }
  }
}
