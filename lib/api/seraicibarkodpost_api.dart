import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class SeraIciBarkodPostApi {
  SeraIciBarkodPostApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// POST: /SeraBarkod/Kayit
  ///
  /// Body (JSON):
  /// {
  ///   "mobilesemriid": 123,
  ///   "barkod": "...."
  /// }
  ///
  /// API string döndürüyorsa String olarak döner.
  Future<String> barkodKaydet({
    required int isEmriId,
    required String barkod,
  }) async {
    final Uri uri = Uri.parse('${App.outsideurl}/SeraBarkod/Kayit');

    final payload = <String, dynamic>{
      'mobilesemriid': isEmriId,
      'barkod': barkod,
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
          'Barkod kayıt başarısız. '
          'Status: ${response.statusCode} Body: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);

      // API bazen direkt string, bazen map döndürebilir:
      if (decoded is String) return decoded;
      if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'].toString();
      }
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'].toString();
      }

      return decoded.toString();
    } catch (e) {
      throw Exception('SeraIciBarkodPostApi.barkodKaydet hata: $e');
    }
  }
}
