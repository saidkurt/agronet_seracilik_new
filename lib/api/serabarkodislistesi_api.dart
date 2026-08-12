import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/serabarkodislistesi_model.dart';
import 'package:http/http.dart' as http;

class SeraBarkodListesiApi {
  SeraBarkodListesiApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// GET: /SeraBarkod/IsListesi/{personelKodu}
  Future<List<SeraBarkod>> seraBarkodListesi({
    required String personelKodu,
  }) async {
    final Uri uri =
        Uri.parse('${App.insideurl}/SeraBarkod/IsListesi/$personelKodu');

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Sera barkod listesi alınamadı. '
          'Status: ${response.statusCode} Body: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Beklenen JSON liste değil: ${response.body}');
      }

      return decoded
          .map<SeraBarkod>(
            (e) => SeraBarkod.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('SeraBarkodListesiApi hata: $e');
    }
  }
}
