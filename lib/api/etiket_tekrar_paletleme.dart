import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class SerapaketApi {
  SerapaketApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String _asString(dynamic decoded) {
    if (decoded == null) return '';
    if (decoded is String) return decoded;
    if (decoded is num || decoded is bool) return decoded.toString();

    if (decoded is Map) {
      if (decoded.containsKey('data')) {
        return decoded['data']?.toString() ?? '';
      }
      if (decoded.containsKey('message')) {
        return decoded['message']?.toString() ?? '';
      }
      if (decoded.containsKey('result')) {
        return decoded['result']?.toString() ?? '';
      }
    }
    return decoded.toString();
  }

  /// POST: /Serapaket/PaletEtiketi
  Future<String> paletEtiketiTekrar({
    required String paletkodu,
    required String cihazadi,
  }) async {
    final Uri uri =
        Uri.parse('${App.insideurl}/Serapaket/PaletEtiketi');

    try {
      final http.Response response = await _client.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type':
              'application/x-www-form-urlencoded; charset=utf-8',
        },
        body: {
          'cihazadi': cihazadi,
          'paletkodu': paletkodu,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'PaletEtiketiTekrar başarısız. '
          'Status: ${response.statusCode} Body: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      return _asString(decoded);
    } catch (e) {
      throw Exception('paletEtiketiTekrar hata: $e');
    }
  }

  /// POST: /Serapaket/PaletSil
  Future<String> paletSil({
    required String paletkodu,
  }) async {
    final Uri uri =
        Uri.parse('${App.insideurl}/Serapaket/PaletSil');

    try {
      final http.Response response = await _client.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type':
              'application/x-www-form-urlencoded; charset=utf-8',
        },
        body: {
          'paletkodu': paletkodu,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'PaletSil başarısız. '
          'Status: ${response.statusCode} Body: ${response.body}',
        );
      }


      final decoded = jsonDecode(response.body);
      return _asString(decoded);
    } catch (e) {
      throw Exception('paletSil hata: $e');
    }
  }
}
