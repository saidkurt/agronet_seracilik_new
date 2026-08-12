import 'dart:convert';
import 'package:agronet/const/string.dart';
import 'package:agronet/models/sera_is_tarih_model.dart';
import 'package:http/http.dart' as http;

class SeraIsTarihleriApi {
  SeraIsTarihleriApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// GET: /Sera/IsTarih/{bolum}/{isKodu}/{yil}/{hafta}/{deger}
  ///
  /// Not: bolum/isKodu/deger gibi segmentleri encode ediyoruz.
  Future<List<SeraIsTarihModel>> isTarihleri({
    required String bolum,
    required String isKodu,
    required int hafta,
    required String deger,
    int? yil,
  }) async {
    final int year = yil ?? DateTime.now().year;

    final base = Uri.parse(App.insideurl);
    

    final segments = [
      ...base.pathSegments.where((s) => s.isNotEmpty),
      'Sera',
      'IsTarih',
      Uri.encodeComponent(bolum),
      Uri.encodeComponent(isKodu),
      year.toString(),
      hafta.toString(),
      Uri.encodeComponent(deger),
    ];

    final Uri uri = base.replace(pathSegments: segments);

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'İş tarihleri alınamadı. Status: ${response.statusCode}\n'
          'URL: $uri\n'
          'Body: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((e) => SeraIsTarihModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }

      if (decoded is Map) {
        return [
          SeraIsTarihModel.fromJson(
            Map<String, dynamic>.from(decoded),
          )
        ];
      }

      throw Exception(
        'Beklenen JSON List/Map değil.\nURL: $uri\nBody: ${response.body}',
      );
    } catch (e) {
      throw Exception('SeraIsTarihleriApi.isTarihleri hata: $e');
    }
  }
}
