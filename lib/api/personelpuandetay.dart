import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class PersonelPuanDetayApi {
  PersonelPuanDetayApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// GET: /Sera/PerformansDetay/{bileklikId}/{tip}
  ///
  /// Eski kodda base url sabit:
  /// http://88.248.170.183:2626
  ///
  /// Eğer bu endpoint App.insideurl altında değilse:
  /// baseUrlOverride ile ver.
  Future<List<Map<String, dynamic>>> personelPuanDetay({
    required String bileklikId,
    required String tip,
    String? baseUrlOverride,
  }) async {
    final base = baseUrlOverride ?? App.insideurl;
    final Uri uri = Uri.parse('$base/Sera/PerformansDetay/$bileklikId/$tip');

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Performans detay alınamadı. '
          'Status: ${response.statusCode} Body: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      // API liste dönüyorsa
      if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
            .toList();
      }

      // Tek obje dönüyorsa
      if (decoded is Map) {
        return [(decoded).cast<String, dynamic>()];
      }

      throw Exception('Beklenen JSON list/map değil: ${response.body}');
    } catch (e) {
      throw Exception('PersonelPuanDetayApi hata: $e');
    }
  }
}
