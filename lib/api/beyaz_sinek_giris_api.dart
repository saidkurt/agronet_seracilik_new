import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;

import '../models/beyaz_sinek_giris_model.dart';

class BeyazSinekGirisApi {
  const BeyazSinekGirisApi();

  static final String _baseUrl = App.insideurl;

  Future<BeyazSinekGirisResponseModel> beyazSinekGirisGetir({
    required DateTime tarih,
    required String personelKodu,
  }) async {
    final tarihText = _formatDate(tarih);

    final uri = Uri.parse(
      '$_baseUrl/Sera/BeyazSinekGiris/'
      '$tarihText/'
      '${Uri.encodeComponent(personelKodu)}',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Beyaz sinek giriş cevabı beklenen formatta değil.',
        );
      }

      return BeyazSinekGirisResponseModel.fromJson(decoded);
    }

    throw Exception(
      'Beyaz sinek giriş verileri alınamadı. '
      'Kod: ${response.statusCode} '
      'Mesaj: ${response.body}',
    );
  }

  Future<SonucModel> beyazSinekGirisKaydet({
    required DateTime tarih,
    required String personelKodu,
    required List<BeyazSinekRowModel> rows,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/Sera/BeyazSinekGirisKaydet',
    );

    final requestModel = BeyazSinekKaydetRequestModel(
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
          'Beyaz sinek kayıt cevabı beklenen formatta değil.',
        );
      }

      return SonucModel.fromJson(decoded);
    }

    throw Exception(
      'Beyaz sinek giriş kaydı yapılamadı. '
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