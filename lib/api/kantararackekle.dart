import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class KantarApi {
  KantarApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// POST: /Kantar/kayit
  /// Body JSON:
  /// {
  ///  "adsoyad": "...",
  ///  "plaka": "...",
  ///  "telefon": "...",
  ///  "user": "...",
  ///  "bos": 0,
  ///  "brut": 0,
  ///  "tcno": "..."
  /// }
  ///
  /// Başarılıysa true döner, değilse exception fırlatır.
  Future<bool> kantarKaydet({
    required String adsoyad,
    required String tel,
    required String plaka,
    required int bosagirlik,
    required String user,
    required int doluagirlik,
    required String tckimlik,
  }) async {
    final Uri uri = Uri.parse('${App.localurl}/Kantar/kayit');

    final payload = <String, dynamic>{
      'adsoyad': adsoyad,
      'plaka': plaka,
      'telefon': tel,
      'user': user,
      'bos': bosagirlik,
      'brut': doluagirlik,
      'tcno': tckimlik,
    };

    try {
      final http.Response response = await _client.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Kantar kaydet başarısız. '
          'Status: ${response.statusCode} Body: ${response.body}',
        );
      }

      return true;
    } catch (e) {
      throw Exception('KantarApi.kaydet hata: $e');
    }
  }

  /// GET: /Kantar/Bilgi
  ///
  /// Model yoksa en temiz dönüş: List<Map<String,dynamic>>
  Future<List<Map<String, dynamic>>> kantariceri() async {
    final Uri uri = Uri.parse('${App.outsideurl}/Kantar/Bilgi');

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Kantar bilgi alınamadı. '
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
      throw Exception('KantarApi.bilgi hata: $e');
    }
  }
}
