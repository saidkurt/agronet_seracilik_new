import 'dart:convert';
import 'package:agronet/const/string.dart';
import 'package:agronet/models/olcum_tipleri.dart';
import 'package:http/http.dart' as http;

class OlcumTipleriApi {
  const OlcumTipleriApi();

  Future<List<OlcumTipleriModel>> getir() async {
    final String baseUrl = "${App.localurl}/Sera/OlcumTipleri";
    final Uri uri = Uri.parse(baseUrl);

    try {
      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          "Ölçüm tipleri alınamadı. Status: ${response.statusCode}",
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception("Beklenen JSON liste değil: ${response.body}");
      }

      return decoded
          .map((e) => OlcumTipleriModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("OlcumTipleri API hatası: $e");
    }
  }
}
