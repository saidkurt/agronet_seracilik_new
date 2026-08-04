import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/bitki_sera_yerler.dart';
import 'package:agronet/models/zorunlu_olcum_durum_model.dart';
import 'package:http/http.dart' as http;

class BitkiSeraYerleriApi {
  const BitkiSeraYerleriApi();

  Future<List<SeraYerModel>> getir() async {
    final String baseUrl =
        '${App.outsideurl}/Sera/BitkiYerleri';

    final Uri uri = Uri.parse(baseUrl);

    try {
      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Bitki yerleri alınamadı. '
          'Status: ${response.statusCode}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'Beklenen JSON liste değil: ${response.body}',
        );
      }

      return decoded
          .map(
            (e) => SeraYerModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('BitkiYerleri API hatası: $e');
    }
  }

  Future<ZorunluOlcumDurumModel> zorunluOlcumDurumuGetir({
    required String bitkiKodu,
    required DateTime tarih,
  }) async {
    final kod = bitkiKodu.trim();

    if (kod.isEmpty) {
      throw Exception('Bitki kodu boş olamaz.');
    }

    final Uri uri = Uri.parse(
      '${App.outsideurl}/Sera/ZorunluOlcumDurum',
    ).replace(
      queryParameters: {
        'bitkiKodu': kod,
        'tarih': _yyyyMmDd(tarih),
      },
    );

    try {
      final http.Response response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Zorunlu ölçüm durumu alınamadı. '
          'Status: ${response.statusCode} '
          'Body: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Beklenen JSON nesnesi gelmedi: ${response.body}',
        );
      }

      if (decoded['success'] == false) {
        throw Exception(
          decoded['message']?.toString() ??
              'Zorunlu ölçüm durumu alınamadı.',
        );
      }

      return ZorunluOlcumDurumModel.fromJson(decoded);
    } catch (e) {
      throw Exception(
        'Zorunlu ölçüm durum API hatası: $e',
      );
    }
  }

  String _yyyyMmDd(DateTime tarih) {
    String ikiHane(int deger) =>
        deger.toString().padLeft(2, '0');

    return '${tarih.year}-'
        '${ikiHane(tarih.month)}-'
        '${ikiHane(tarih.day)}';
  }
  Future<OlcumDegerModel> olcumDegerGetir({
  required String bitkiKodu,
  required String tip,
  required DateTime tarih,
}) async {
  final uri = Uri.parse(
    '${App.outsideurl}/Sera/OlcumDegerGetir',
  ).replace(
    queryParameters: {
      'bitkiKodu': bitkiKodu.trim(),
      'tip': tip.trim(),
      'tarih': _yyyyMmDd(tarih),
    },
  );

  final response = await http.get(
    uri,
    headers: const {
      'Accept': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Ölçüm değeri alınamadı. '
      'Status: ${response.statusCode} Body: ${response.body}',
    );
  }

  final dynamic decoded = jsonDecode(response.body);

  if (decoded is! Map<String, dynamic>) {
    throw Exception('Beklenen JSON nesnesi gelmedi.');
  }

  if (decoded['success'] == false) {
    throw Exception(
      decoded['message']?.toString() ??
          'Ölçüm değeri alınamadı.',
    );
  }

  return OlcumDegerModel.fromJson(decoded);
}
}