import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/sera_kontrol_rapor_model.dart';
import 'package:http/http.dart' as http;

class SeraKontrolRaporuApi {
  SeraKontrolRaporuApi({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  // ============================================================
  // BÖLÜMLER
  //
  // GET:
  // /SeraKontrolRaporu/Bolumler
  // ============================================================

  Future<List<SeraKontrolBolumModel>> bolumler() async {
    final base = Uri.parse(App.outsideurl);

    final uri = base.replace(
      pathSegments: [
        ...base.pathSegments.where((e) => e.isNotEmpty),
        'SeraKontrolRaporu',
        'Bolumler',
      ],
    );

    final response = await _client
        .get(uri)
        .timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Bölümler alınamadı. '
        'HTTP ${response.statusCode}\n'
        '${_responseMessage(response)}',
      );
    }

    final dynamic decoded = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    if (decoded is! Map) {
      throw Exception(
        'Bölüm listesi cevabı geçersiz.',
      );
    }

    final json = Map<String, dynamic>.from(decoded);

    if (!_toBool(json['success'])) {
      throw Exception(
        json['message']?.toString() ??
            json['mesaj']?.toString() ??
            'Bölümler alınamadı.',
      );
    }

    final data = json['data'];

    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map(
          (e) => SeraKontrolBolumModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  // ============================================================
  // RAPOR
  //
  // GET:
  // /SeraKontrolRaporu/Rapor
  // ?bolum=2
  // &ilkTarih=2026-08-18
  // &sonTarih=2026-08-18
  // ============================================================

  Future<SeraKontrolRaporModel> rapor({
    required String bolum,
    required DateTime ilkTarih,
    required DateTime sonTarih,
  }) async {
    final base = Uri.parse(App.outsideurl);

    final uri = base.replace(
      pathSegments: [
        ...base.pathSegments.where((e) => e.isNotEmpty),
        'SeraKontrolRaporu',
        'Rapor',
      ],
      queryParameters: {
        'bolum': bolum,
        'ilkTarih': _date(ilkTarih),
        'sonTarih': _date(sonTarih),
      },
    );

    final response = await _client
        .get(uri)
        .timeout(
          const Duration(minutes: 3),
        );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Sera kontrol raporu alınamadı. '
        'HTTP ${response.statusCode}\n'
        '${_responseMessage(response)}',
      );
    }

    final dynamic decoded = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    if (decoded is! Map) {
      throw Exception(
        'Sera kontrol raporu cevabı geçersiz.',
      );
    }

    final json = Map<String, dynamic>.from(decoded);

    if (!_toBool(json['success'])) {
      throw Exception(
        json['message']?.toString() ??
            json['mesaj']?.toString() ??
            'Sera kontrol raporu alınamadı.',
      );
    }

    return SeraKontrolRaporModel.fromJson(json);
  }

  void dispose() {
    _client.close();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String _date(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }

  static String _responseMessage(
    http.Response response,
  ) {
    try {
      final dynamic decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (decoded is Map) {
        return decoded['message']?.toString() ??
            decoded['mesaj']?.toString() ??
            decoded['ExceptionMessage']?.toString() ??
            '';
      }

      return decoded.toString();
    } catch (_) {
      return response.body;
    }
  }

  static bool _toBool(dynamic value) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final s = value
        .toString()
        .trim()
        .toLowerCase();

    return s == 'true' ||
        s == '1' ||
        s == 'yes' ||
        s == 'evet';
  }
}