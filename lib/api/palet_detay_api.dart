import 'dart:convert';
import 'package:agronet/const/string.dart'; // App.outsideurl
import 'package:agronet/models/paletleme_rapor_model.dart';
import 'package:http/http.dart' as http;

class PaletDetayApi {
  const PaletDetayApi();

  Future<PaletlemeRaporModel> paletDetayGetir({
    required String paletkodu,
  }) async {
    final uri = Uri.parse('${App.outsideurl}/Palet/Detay/$paletkodu');

    try {
      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Palet detay alınamadı. Status: ${response.statusCode} Body: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Beklenen JSON obje değil: ${response.body}');
      }

      return PaletlemeRaporModel.fromJson(decoded);
    } catch (e) {
      throw Exception('PaletDetay API hatası: $e');
    }
  }
}