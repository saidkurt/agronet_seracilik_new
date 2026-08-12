import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:agronet/const/string.dart';
import 'package:agronet/models/paletleme_rapor_model.dart';

class PaletlemeRaporApi {
  const PaletlemeRaporApi();

  Future<List<PaletlemeRaporModel>> paletlemeGetir(
    DateTime ilkTarih,
    DateTime sonTarih,
  ) async {
    final String baseUrl = '${App.insideurl}/Palet/Paletleme';

    String fmt(DateTime d) =>
        "${d.year.toString().padLeft(4, '0')}"
        "${d.month.toString().padLeft(2, '0')}"
        "${d.day.toString().padLeft(2, '0')}";

    final String t1 = fmt(ilkTarih);
    final String t2 = fmt(sonTarih);

    final Uri uri = Uri.parse("$baseUrl/$t1/$t2");

    try {
      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Paletleme raporu alınamadı. Status: ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Beklenen JSON liste değil: ${response.body}');
      }

      return decoded
          .map((e) => PaletlemeRaporModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Paletleme API hatası: $e');
    }
  }
}