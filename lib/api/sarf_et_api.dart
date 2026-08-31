import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/sarf_et_model.dart';
import 'package:http/http.dart' as http;

class SarfEtApi {
  SarfEtApi({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  // ============================================================
  // DEPOLAR
  //
  // GET:
  // /Depo/SarfDepolar
  // ============================================================

  Future<List<SarfDepoModel>> depolar() async {
    final base = Uri.parse(
      App.outsideurl,
    );

    final uri = base.replace(
      pathSegments: [
        ...base.pathSegments.where(
          (e) => e.isNotEmpty,
        ),
        'Depo',
        'SarfDepolar',
      ],
    );

    final response = await _client.get(
      uri,
      headers: _headers(),
    );

    final data = _decode(
      response,
    );

    if (data is! List) {
      throw Exception(
        'Depo listesi geçersiz döndü.',
      );
    }

    return data
        .whereType<Map>()
        .map(
          (e) => SarfDepoModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  // ============================================================
  // STOK GETİR
  //
  // GET:
  // /Depo/SarfStokGetir
  //
  // Örnek:
  // /Depo/SarfStokGetir
  // ?stokKodu=150.03.039
  // &depo=3
  // &tarih=2026-08-23
  // ============================================================

  Future<SarfStokModel> stokGetir({
    required String stokKodu,
    required int depoNo,
    required DateTime tarih,
  }) async {
    final kod = stokKodu.trim();

    if (kod.isEmpty) {
      throw Exception(
        'Stok kodu boş.',
      );
    }

    if (depoNo <= 0) {
      throw Exception(
        'Depo geçersiz.',
      );
    }

    final base = Uri.parse(
      App.outsideurl,
    );

    final uri = base.replace(
      pathSegments: [
        ...base.pathSegments.where(
          (e) => e.isNotEmpty,
        ),
        'Depo',
        'SarfStokGetir',
      ],
      queryParameters: {
        'stokKodu': kod,
        'depo': depoNo.toString(),
        'tarih': _sarfDateOnly(tarih),
      },
    );

    final response = await _client.get(
      uri,
      headers: _headers(),
    );

    final data = _decode(
      response,
    );

    if (data is! Map) {
      throw Exception(
        'Stok bilgisi geçersiz döndü.',
      );
    }

    return SarfStokModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  // ============================================================
  // DEPOMDAKİ ÜRÜNLERİ GETİR
  //
  // GET:
  // /Depo/SarfDepodakiler
  //
  // Örnek:
  // /Depo/SarfDepodakiler
  // ?depo=3
  // &tarih=2026-08-23
  // ============================================================

  Future<List<SarfStokModel>> depodakiler({
    required int depoNo,
    required DateTime tarih,
  }) async {
    if (depoNo <= 0) {
      throw Exception(
        'Depo geçersiz.',
      );
    }

    final base = Uri.parse(
      App.outsideurl,
    );

    final uri = base.replace(
      pathSegments: [
        ...base.pathSegments.where(
          (e) => e.isNotEmpty,
        ),
        'Depo',
        'SarfDepodakiler',
      ],
      queryParameters: {
        'depo': depoNo.toString(),
        'tarih': _sarfDateOnly(tarih),
      },
    );

    final response = await _client.get(
      uri,
      headers: _headers(),
    );

    final data = _decode(
      response,
    );

    if (data is! List) {
      throw Exception(
        'Depo stok listesi geçersiz döndü.',
      );
    }

    return data
        .whereType<Map>()
        .map(
          (e) => SarfStokModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  // ============================================================
  // SARF KAYDET
  //
  // POST:
  // /Depo/SarfKaydet
  //
  // SMS ONAYI YOK.
  // ============================================================

  Future<SarfKaydetSonucModel> kaydet({
    required SarfKaydetRequestModel request,
  }) async {
    if (request.depoNo <= 0) {
      throw Exception(
        'Depo seçilmedi.',
      );
    }

    if (request.kullaniciKodu.trim().isEmpty) {
      throw Exception(
        'Kullanıcı kodu boş.',
      );
    }

    if (request.oturumId <= 0) {
      throw Exception(
        'Oturum bilgisi geçersiz.',
      );
    }

    if (request.token.trim().isEmpty) {
      throw Exception(
        'Token bilgisi boş.',
      );
    }

    if (request.kalemler.isEmpty) {
      throw Exception(
        'Kaydedilecek ürün bulunamadı.',
      );
    }

    final base = Uri.parse(
      App.outsideurl,
    );

    final uri = base.replace(
      pathSegments: [
        ...base.pathSegments.where(
          (e) => e.isNotEmpty,
        ),
        'Depo',
        'SarfKaydet',
      ],
    );

    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode(
        request.toJson(),
      ),
    );

    final data = _decode(
      response,
    );

    if (data is! Map) {
      throw Exception(
        'Sarf kayıt sonucu geçersiz döndü.',
      );
    }

    return SarfKaydetSonucModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  // ============================================================
  // HTTP HEADERS
  // ============================================================

  Map<String, String> _headers() {
    return const {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
  }

  // ============================================================
  // RESPONSE DECODE
  // ============================================================

  dynamic _decode(
    http.Response response,
  ) {
    dynamic data;

    try {
      if (response.bodyBytes.isEmpty) {
        data = null;
      } else {
        final body = utf8.decode(
          response.bodyBytes,
        );

        if (body.trim().isEmpty) {
          data = null;
        } else {
          data = jsonDecode(body);
        }
      }
    } catch (_) {
      try {
        data = utf8.decode(
          response.bodyBytes,
        );
      } catch (_) {
        data = response.body;
      }
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    String message =
        'İşlem başarısız (${response.statusCode}).';

    if (data is Map) {
      final map =
          Map<String, dynamic>.from(data);

      final gelenMesaj =
          map['Message'] ??
          map['message'] ??
          map['Mesaj'] ??
          map['mesaj'] ??
          map['ExceptionMessage'] ??
          map['exceptionMessage'];

      final txt = _sarfToString(
        gelenMesaj,
      ).trim();

      if (txt.isNotEmpty) {
        message = txt;
      }
    } else if (data is String) {
      final txt = data.trim();

      if (txt.isNotEmpty) {
        message = txt;
      }
    }

    throw Exception(message);
  }
}

// ============================================================
// YARDIMCI FONKSİYONLAR
//
// Bunlar bu API dosyasına ait.
// Model dosyasındaki private fonksiyonlara bağımlı değil.
// ============================================================

String _sarfDateOnly(
  DateTime value,
) {
  final year =
      value.year.toString().padLeft(4, '0');

  final month =
      value.month.toString().padLeft(2, '0');

  final day =
      value.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}

String _sarfToString(
  dynamic value,
) {
  if (value == null) {
    return '';
  }

  return value.toString();
}