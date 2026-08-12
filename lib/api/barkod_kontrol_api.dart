import 'dart:convert';
import 'package:agronet/const/string.dart';
import 'package:agronet/models/barkod_kontrol_model.dart';
import 'package:http/http.dart' as http;

class KoliBarkodApi {
  // ✅ Senin sunucu (istersen burayı const String.baseUrl'dan da aldırırız)
  static final String _base = App.insideurl;

  // GET: /Qr/Koli/{barkod}  -> JSON ARRAY
  static Future<List<KoliBarkodModel>> getir(String barkod) async {
    final b = barkod.trim();
    if (b.isEmpty) return const [];

    final uri = Uri.parse('$_base/Qr/Koli/$b');

    try {
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 404) return const [];
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final decoded = jsonDecode(res.body);

      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(KoliBarkodModel.fromJson)
            .toList();
      }

      // Beklenen liste değilse boş dön
      return const [];
    } catch (e) {
      // İstersen burada log atarız
      // debugPrint('KoliBarkodApi.hata: $e');
      rethrow;
    }
  }
}