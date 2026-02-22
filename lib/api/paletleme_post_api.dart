import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class PaletlemeApi {
  PaletlemeApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// POST: /Serapaket/Paletleme
  ///
  /// Body:
  /// {
  ///   "personelkodu": "...",
  ///   "paletbosagirligi": "...",
  ///   "kututipi": "...",
  ///   "kutuadedi": "...",
  ///   "toplamagirlik": "...",
  ///   "palettipi": "...",
  ///   "cihazadi": "...",
  ///   "urunkodu": "..."
  /// }
  ///
  /// API string (palet kodu vb.) döndürüyorsa String olarak return eder.
  Future<String> paletGonder({
    required String personelkodu,
    required String paletbos,
    required String kututipi,
    required String kutuadedi,
    required String toplamagirlik,
    required String palettipi,
    required String cihazadi,
    required String stokkodu,
  }) async {
    final Uri uri = Uri.parse('${App.localurl}/Serapaket/Paletleme');

    final payload = <String, dynamic>{
      'personelkodu': personelkodu,
      'paletbosagirligi': paletbos,
      'kututipi': kututipi,
      'kutuadedi': kutuadedi,
      'toplamagirlik': toplamagirlik,
      'palettipi': palettipi,
      'cihazadi': cihazadi,
      'urunkodu': stokkodu,
    };

    try {
      final http.Response response = await _client.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
        },
        body: payload,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Palet gönderme başarısız. '
          'Status: ${response.statusCode} Body: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);

      // API bazen direkt string, bazen {data:""} döndürebilir
      if (decoded is String) return decoded;
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'].toString();
      }

      return decoded.toString();
    } catch (e) {
      throw Exception('PaletlemeApi.paletGonder hata: $e');
    }
  }
}
