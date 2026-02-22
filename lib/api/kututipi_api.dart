import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class KutuTipApi {
  KutuTipApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// GET: /Serapaket/Kutu
  ///
  /// Model yoksa en güvenlisi:
  /// List<Map<String, dynamic>> döndürmek
  Future<List<Map<String, dynamic>>> kutuTipleri() async {
    final Uri uri = Uri.parse('${App.localurl}/Serapaket/Kutu');

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Kutu tipleri alınamadı. '
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
      throw Exception('KutuTipApi.kutuTipleri hata: $e');
    }
  }
}
