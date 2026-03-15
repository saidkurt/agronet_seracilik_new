import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/gunlukpalet_model.dart';
import 'package:http/http.dart' as http;

class GunlukPaletApi {
  GunlukPaletApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// GET: /Serapaket/GunlukPalet
  Future<List<GunlukPalet>> gunlukPaletler() async {
    final Uri uri = Uri.parse('${App.localurl}/Serapaket/GunlukPalet');

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Günlük paletler alınamadı. '
          'Status: ${response.statusCode} Body: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Beklenen JSON liste değil: ${response.body}');
      }

      return decoded
          .map((e) => GunlukPalet.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception('gunlukPaletler API hatası: $e');
    }
  }
}
