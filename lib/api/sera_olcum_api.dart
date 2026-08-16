import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/sera_olcum_model.dart';
import 'package:http/http.dart' as http;

class SeraOlcumApi {
  SeraOlcumApi({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  // ============================================================
  // EKRAN
  // GET /SeraOlcum/Ekran?tarih=2026-08-14
  // ============================================================

 Future<SeraOlcumEkranModel> ekranGetir({
  required DateTime tarih,
  required String personelKodu,
}) async {
  final uri = Uri.parse(
    '${App.outsideurl}/SeraOlcum/Ekran',
  ).replace(
    queryParameters: {
      'tarih': _yyyyMmDd(tarih),
      'personelKodu': personelKodu,
    },
  );

  final response = await _client.get(
    uri,
    headers: const {
      'Accept': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Ölçüm ekranı alınamadı. '
      'Status: ${response.statusCode} '
      'Body: ${response.body}',
    );
  }

  final decoded = jsonDecode(response.body);

  if (decoded is! Map) {
    throw Exception(
      'Geçersiz sunucu cevabı.',
    );
  }

  final json = Map<String, dynamic>.from(decoded);

  if (json['success'] == false) {
    throw Exception(
      json['message']?.toString() ??
          'Ölçüm ekranı alınamadı.',
    );
  }

  return SeraOlcumEkranModel.fromJson(json);
}
  // ============================================================
  // TARİHLER
  // GET /SeraOlcum/Tarihler
  // ============================================================

  Future<List<SeraOlcumTarihModel>>
      tarihleriGetir() async {
    final uri = Uri.parse(
      '${App.outsideurl}/SeraOlcum/Tarihler',
    );

    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Ölçüm tarihleri alınamadı. '
        'Status: ${response.statusCode} '
        'Body: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Geçersiz sunucu cevabı.',
      );
    }

    final json = Map<String, dynamic>.from(decoded);

    if (json['success'] == false) {
      throw Exception(
        json['message']?.toString() ??
            'Ölçüm tarihleri alınamadı.',
      );
    }

    final liste = json['tarihler'];

    if (liste is! List) {
      return [];
    }

    return liste
        .whereType<Map>()
        .map(
          (e) => SeraOlcumTarihModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  // ============================================================
  // KAYDET
  // POST /SeraOlcum/Kaydet
  // ============================================================

  Future<void> kaydet({
    required SeraOlcumKaydetModel model,
  }) async {
    final uri = Uri.parse(
      '${App.outsideurl}/SeraOlcum/Kaydet',
    );

    final response = await _client.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(
        model.toJson(),
      ),
    );

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode != 200) {
      String mesaj =
          'Ölçümler kaydedilemedi.';

      if (decoded is Map &&
          decoded['message'] != null) {
        mesaj =
            decoded['message'].toString();
      }

      throw Exception(
        '$mesaj '
        'Status: ${response.statusCode}',
      );
    }

    if (decoded is Map &&
        decoded['success'] == false) {
      throw Exception(
        decoded['message']?.toString() ??
            'Ölçümler kaydedilemedi.',
      );
    }
  }

  // ============================================================
  // SİL
  // DELETE /SeraOlcum/Sil?tarih=2026-08-14
  // ============================================================

  Future<void> sil({
    required DateTime tarih,
  }) async {
    final uri = Uri.parse(
      '${App.outsideurl}/SeraOlcum/Sil',
    ).replace(
      queryParameters: {
        'tarih': _yyyyMmDd(tarih),
      },
    );

    final response = await _client.delete(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode != 200) {
      String mesaj =
          'Ölçümler silinemedi.';

      if (decoded is Map &&
          decoded['message'] != null) {
        mesaj =
            decoded['message'].toString();
      }

      throw Exception(
        '$mesaj '
        'Status: ${response.statusCode}',
      );
    }

    if (decoded is Map &&
        decoded['success'] == false) {
      throw Exception(
        decoded['message']?.toString() ??
            'Ölçümler silinemedi.',
      );
    }
  }

  void dispose() {
    _client.close();
  }

  String _yyyyMmDd(DateTime tarih) {
    String iki(int value) {
      return value
          .toString()
          .padLeft(2, '0');
    }

    return '${tarih.year}-'
        '${iki(tarih.month)}-'
        '${iki(tarih.day)}';
  }
}