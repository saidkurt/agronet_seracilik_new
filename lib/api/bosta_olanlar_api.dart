import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/bostaolanlar_model.dart';
import 'package:http/http.dart' as http;

class BostaOlanlarApi {
  const BostaOlanlarApi();

  Future<List<BostaOlanlar>> personelBos() async {
    final String baseUrl = '${App.insideurl}/Bos/Giris';
    final Uri uri = Uri.parse('$baseUrl/X');

    try {
      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Bos personel alınamadı. Status: ${response.statusCode}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Beklenen JSON liste değil: ${response.body}');
      }

      return decoded
          .map((e) => BostaOlanlar.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Bos personel API hatası: $e');
    }
  }
}
