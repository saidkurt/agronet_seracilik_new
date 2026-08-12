import 'dart:convert';
import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class PersonelMesaiApi {
  final http.Client _client = http.Client();

  Future<List<Map<String, dynamic>>> mesaiDurumu({
    required String bileklikid,
  }) async {
    // 🔥 Direk insideurl kullanıyoruz
    final Uri uri =
        Uri.parse("${App.insideurl}/Mesai/MesaiDurumu/$bileklikid");

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
            "Mesai durumu alınamadı. Status: ${response.statusCode}");
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>(
                (e) => (e as Map).cast<String, dynamic>())
            .toList();
      }

      if (decoded is Map) {
        return [(decoded).cast<String, dynamic>()];
      }

      throw Exception("Beklenen JSON list/map değil");
    } catch (e) {
      throw Exception("PersonelMesaiApi hata: $e");
    }
  }
}
