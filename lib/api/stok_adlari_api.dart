import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class StokAdlariApi {
  StokAdlariApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// GET: /Serapaket/Stokadi
  ///
  /// API genelde List döndürüyor (string veya map listesi olabilir).
  /// Şimdilik dynamic list dönüyorum; istersen model yaparız.
  Future<List<dynamic>> stokAdlari() async {
    final Uri uri = Uri.parse('${App.outsideurl}/Serapaket/Stokadi');

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Stok adları alınamadı. '
          'Status: ${response.statusCode} Body: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Beklenen JSON liste değil: ${response.body}');
      }

      return decoded;
    } catch (e) {
      throw Exception('StokAdlariApi.stokAdlari hata: $e');
    }
  }
}
