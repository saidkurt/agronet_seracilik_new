import 'dart:convert';
import 'package:agronet/const/string.dart';
import 'package:agronet/models/bitki_sera_yerler.dart';
import 'package:http/http.dart' as http;

class BitkiSeraYerleriApi {
  const BitkiSeraYerleriApi();

  Future<List<SeraYerModel>> getir() async {

    final String baseUrl = "${App.localurl}/Sera/BitkiYerleri";
    final Uri uri = Uri.parse(baseUrl);

    try {

      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          "Bitki yerleri alınamadı. Status: ${response.statusCode}",
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception("Beklenen JSON liste değil: ${response.body}");
      }

      return decoded
          .map((e) => SeraYerModel.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e) {
      throw Exception("BitkiYerleri API hatası: $e");
    }
  }
}
