import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class PersonelBilgileriApi {
  PersonelBilgileriApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// GET: /PersonelBilgileri/PersonelId/{personelId}
  ///
  /// API liste dönüyorsa:
  /// List<Map<String,dynamic>>
  Future<List<Map<String, dynamic>>> personelBilgileri({
    required String personelId,
  }) async {
    final Uri uri =
        Uri.parse('${App.localurl}/PersonelBilgileri/PersonelId');

    try {
      final http.Response response = await _client.get(uri);
      print(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          'Personel bilgileri alınamadı. '
          'Status: ${response.statusCode} Body: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      // Bazı API'ler tek obje döndürebilir, onu da tolere edelim:
      if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
            .toList();
      }

      if (decoded is Map) {
        return [(decoded).cast<String, dynamic>()];
      }

      throw Exception('Beklenen JSON list/map değil: ${response.body}');
    } catch (e) {
      throw Exception('PersonelBilgileriApi.personelBilgileri hata: $e');
    }
  }
}
