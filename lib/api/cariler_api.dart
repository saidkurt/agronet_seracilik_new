import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

class CarilerApi {
  const CarilerApi();

  /// API: GET {App.outsideurl}/Kantar/Cariler
  ///
  Future<List<Map<String, dynamic>>> cariler() async {
    final String url = '${App.outsideurl}/Kantar/Cariler';
    final Uri uri = Uri.parse(url);

    try {
      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Cariler alınamadı. Status: ${response.statusCode} Body: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Beklenen JSON liste değil: ${response.body}');
      }

      // Liste içindeki her elemanı Map'e çeviriyoruz
      return decoded
          .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
          .toList();
    } catch (e) {
      throw Exception('Cariler API hatası: $e');
    }
  }
}
