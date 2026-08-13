import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:agronet/const/string.dart';
import 'package:agronet/models/personel_listesi_model.dart';

class PersonelListesiApi {
  /// GET: /PersonelBilgileri/Liste
  Future<List<PersonelListesiModel>> personelListesiGetir() async {
    final url = "${App.insideurl}/PersonelBilgileri/Liste";

    final res = await http.get(
      Uri.parse(url),
    );

    if (res.statusCode != 200) {
      throw Exception(
        "HTTP ${res.statusCode}: ${res.body}",
      );
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .map(
          (e) => PersonelListesiModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }
}