import 'dart:convert';
import 'package:agronet/const/string.dart';
import 'package:agronet/models/bitki_olcum_kaydet.dart';
import 'package:http/http.dart' as http;

class BitkiOlcumKaydetApi {
  BitkiOlcumKaydetApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  /// POST: /Sera/OlcumKaydet
  Future<void> kaydet(BitkiOlcumKaydetModel dto) async {
    final Uri uri = Uri.parse("${App.insideurl}/Sera/OlcumKaydet");

    try {
      final res = await _client.post(
        uri,
        headers: const {"Content-Type": "application/json"},
        body: jsonEncode(dto.toJson()),
      );

      if (res.statusCode != 200) {
        throw Exception("Kayıt başarısız. Status: ${res.statusCode} Body: ${res.body}");
      }

      // Backend bazen {success:false} döndürebilir → kontrol edelim
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded["success"] == false) {
        throw Exception(decoded["message"] ?? "Kayıt başarısız");
      }
    } catch (e) {
      throw Exception("OlcumKaydet API hatası: $e");
    }
  }
}
