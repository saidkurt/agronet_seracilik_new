  import 'dart:convert';
import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

import '../models/tuta_giris_model.dart';

class TutaGirisApi {
  const TutaGirisApi();

  static final String _baseUrl = App.outsideurl;

  Future<TutaGirisResponseModel> tutaGirisGetir(DateTime tarih) async {
    final tarihText = _formatDate(tarih);

    final uri = Uri.parse('$_baseUrl/Sera/TutaGiris/$tarihText');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return TutaGirisResponseModel.fromJson(jsonMap);
    }

    throw Exception('Tuta giriş verileri alınamadı. Kod: ${response.statusCode}');
  }

  Future<SonucModel> tutaGirisKaydet({
    required DateTime tarih,
    required List<TutaRowModel> rows,
  }) async {
    final uri = Uri.parse('$_baseUrl/Sera/TutaGirisKaydet');

    final body = TutaKaydetRequestModel(
      tarih: tarih,
      rows: rows,
    ).toJson();

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return SonucModel.fromJson(jsonMap);
    }

    throw Exception('Tuta giriş kaydı yapılamadı. Kod: ${response.statusCode}');
  }

  String _formatDate(DateTime date) {
    final yil = date.year.toString().padLeft(4, '0');
    final ay = date.month.toString().padLeft(2, '0');
    final gun = date.day.toString().padLeft(2, '0');
    return '$yil-$ay-$gun';
  }
}