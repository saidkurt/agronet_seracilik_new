import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/bitenisler_model.dart';
import 'package:http/http.dart' as http;

class BitenislerApi {
  const BitenislerApi();

  Future<List<Bitenisler>> personelBitenisler(String personelAdi) async {
    final String baseUrl = '${App.localurl}/Personel/Toplam';
    final Uri uri = Uri.parse('$baseUrl/$personelAdi');

    final http.Response response = await http.get(uri);

    if (response.statusCode != 200) {
      // İstersen burada loglayabilirsin
      throw Exception(
        'Personel bitenisler alınamadı. '
        'Status: ${response.statusCode}, Body: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Beklenen JSON liste değil: ${response.body}');
    }

    return decoded
        .map((e) => Bitenisler.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
