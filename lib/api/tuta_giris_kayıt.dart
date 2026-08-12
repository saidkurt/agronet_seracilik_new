import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

import '../models/tuta_giris_model.dart';

class TutaGirisApi {
  const TutaGirisApi();

  static final String _baseUrl = App.insideurl;

  Future<TutaGirisResponseModel> tutaGirisGetir({
    required DateTime tarih,
    required String personelKodu,
  }) async {
    final tarihText = _formatDate(tarih);

    final uri = Uri.parse(
      '$_baseUrl/Sera/TutaGiris/'
      '$tarihText/'
      '${Uri.encodeComponent(personelKodu)}',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Tuta giriş cevabı beklenen formatta değil.',
        );
      }

      return TutaGirisResponseModel.fromJson(decoded);
    }

    throw Exception(
      'Tuta giriş verileri alınamadı. '
      'Kod: ${response.statusCode} '
      'Mesaj: ${response.body}',
    );
  }

  Future<SonucModel> tutaGirisKaydet({
    required DateTime tarih,
    required String personelKodu,
    required List<TutaRowModel> rows,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/Sera/TutaGirisKaydet',
    );

    final requestModel = TutaKaydetRequestModel(
      tarih: tarih,
      personelKodu: personelKodu,
      rows: rows,
    );

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(requestModel.toJson()),
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Tuta kayıt cevabı beklenen formatta değil.',
        );
      }

      return SonucModel.fromJson(decoded);
    }

    throw Exception(
      'Tuta giriş kaydı yapılamadı. '
      'Kod: ${response.statusCode} '
      'Mesaj: ${response.body}',
    );
  }

  String _formatDate(DateTime date) {
    final yil = date.year.toString().padLeft(4, '0');
    final ay = date.month.toString().padLeft(2, '0');
    final gun = date.day.toString().padLeft(2, '0');

    return '$yil-$ay-$gun';
  }
}
