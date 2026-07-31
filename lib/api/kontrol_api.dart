import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/kontrol_detay_model.dart';
import 'package:agronet/models/kontrol_is_model.dart';
import 'package:agronet/models/kontrol_personel_model.dart';
import 'package:http/http.dart' as http;

class KontrolApi {
  static final String _base = App.outsideurl;

  // GET: /Kontrol/Personeller/{kontrolEdenPersonelKodu}
  static Future<List<KontrolPersonelModel>> personelleriGetir(
    String kontrolEdenPersonelKodu,
  ) async {
    final kod = kontrolEdenPersonelKodu.trim();

    if (kod.isEmpty) {
      return const [];
    }

    final uri = Uri.parse(
      '$_base/Kontrol/Personeller/${Uri.encodeComponent(kod)}',
    );

    final response = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
          },
        )
        .timeout(
          const Duration(seconds: 12),
        );

    if (response.statusCode == 404) {
      return const [];
    }

    if (!_basariliMi(response.statusCode)) {
      throw Exception(
        _hataMesajiGetir(response),
      );
    }

    final decoded = _jsonCoz(response);

    if (decoded is! List) {
      throw Exception(
        'Kontrol personelleri beklenen formatta gelmedi.',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(KontrolPersonelModel.fromJson)
        .toList();
  }

  // GET: /Kontrol/Isler/{kontrolEden}/{kontrolEdilen}
  static Future<List<KontrolIsModel>> kontrolIsleriniGetir({
    required String kontrolEdenPersonelKodu,
    required String kontrolEdilenPersonelKodu,
  }) async {
    final kontrolEden =
        kontrolEdenPersonelKodu.trim();

    final kontrolEdilen =
        kontrolEdilenPersonelKodu.trim();

    if (kontrolEden.isEmpty ||
        kontrolEdilen.isEmpty) {
      return const [];
    }

    final uri = Uri.parse(
      '$_base/Kontrol/Isler/'
      '${Uri.encodeComponent(kontrolEden)}/'
      '${Uri.encodeComponent(kontrolEdilen)}',
    );

    final response = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
          },
        )
        .timeout(
          const Duration(seconds: 12),
        );

    if (response.statusCode == 404) {
      return const [];
    }

    if (!_basariliMi(response.statusCode)) {
      throw Exception(
        _hataMesajiGetir(response),
      );
    }

    final decoded = _jsonCoz(response);

    if (decoded is! List) {
      throw Exception(
        'Kontrol işleri beklenen formatta gelmedi.',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(KontrolIsModel.fromJson)
        .toList();
  }

  // GET: /Kontrol/Detay/{kontrolIsId}
  static Future<KontrolDetayModel> detayGetir({
    required int kontrolIsId,
  }) async {
    if (kontrolIsId <= 0) {
      throw Exception(
        'Geçersiz kontrol işi.',
      );
    }

    final uri = Uri.parse(
      '$_base/Kontrol/Detay/$kontrolIsId',
    );

    final response = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
          },
        )
        .timeout(
          const Duration(seconds: 12),
        );

    if (!_basariliMi(response.statusCode)) {
      throw Exception(
        _hataMesajiGetir(response),
      );
    }

    final decoded = _jsonCoz(response);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Kontrol detayı beklenen formatta gelmedi.',
      );
    }

    return KontrolDetayModel.fromJson(
      decoded,
    );
  }

  // POST: /Kontrol/DurumDegistir
  static Future<String> durumDegistir(
    int kontrolIsId, {
    String araSebebi = '',
  }) async {
    return _postIslem(
      '/Kontrol/DurumDegistir',
      {
        'KontrolIsId': kontrolIsId,
        'AraSebebi': araSebebi,
      },
    );
  }

  // POST: /Kontrol/Bitir
  // Kontrol işi puanla birlikte tamamlanır.
  static Future<String> bitir({
    required int kontrolIsId,
    required int puan,
  }) async {
    if (kontrolIsId <= 0) {
      throw Exception(
        'Geçersiz kontrol işi.',
      );
    }

    if (puan < 1 || puan > 10) {
      throw Exception(
        'Puan 1 ile 10 arasında olmalıdır.',
      );
    }

    return _postIslem(
      '/Kontrol/Bitir',
      {
        'KontrolIsId': kontrolIsId,
        'Puan': puan,
      },
    );
  }

  // POST: /Kontrol/TekrarEt
  static Future<String> tekrarEt(
    int kontrolIsId,
  ) async {
    return _postIslem(
      '/Kontrol/TekrarEt',
      {
        'KontrolIsId': kontrolIsId,
        'AraSebebi': '',
      },
    );
  }

  static Future<String> _postIslem(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse(
      '$_base$endpoint',
    );

    final response = await http
        .post(
          uri,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 12),
        );

    if (!_basariliMi(response.statusCode)) {
      throw Exception(
        _hataMesajiGetir(response),
      );
    }

    if (response.bodyBytes.isEmpty) {
      return 'İşlem tamamlandı.';
    }

    final decoded = _jsonCoz(response);

    if (decoded is Map<String, dynamic>) {
      return decoded['Mesaj']?.toString() ??
          decoded['Message']?.toString() ??
          'İşlem tamamlandı.';
    }

    if (decoded is String &&
        decoded.trim().isNotEmpty) {
      return decoded;
    }

    return 'İşlem tamamlandı.';
  }

  static bool _basariliMi(
    int statusCode,
  ) {
    return statusCode >= 200 &&
        statusCode < 300;
  }

  static dynamic _jsonCoz(
    http.Response response,
  ) {
    final metin = utf8.decode(
      response.bodyBytes,
    );

    if (metin.trim().isEmpty) {
      return null;
    }

    return jsonDecode(metin);
  }

  static String _hataMesajiGetir(
    http.Response response,
  ) {
    try {
      final decoded = _jsonCoz(response);

      if (decoded is Map<String, dynamic>) {
        return decoded['Message']?.toString() ??
            decoded['Mesaj']?.toString() ??
            decoded['message']?.toString() ??
            'HTTP ${response.statusCode}';
      }

      if (decoded != null) {
        return decoded.toString();
      }

      return 'HTTP ${response.statusCode}';
    } catch (_) {
      final metin = utf8.decode(
        response.bodyBytes,
        allowMalformed: true,
      );

      if (metin.trim().isNotEmpty) {
        return metin;
      }

      return 'HTTP ${response.statusCode}';
    }
  }
}