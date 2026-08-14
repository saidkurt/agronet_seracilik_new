import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/sera_is_tarih_model.dart';
import 'package:http/http.dart' as http;

class SeraIsTarihleriApi {
  SeraIsTarihleriApi({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  // ============================================================
  // BASE URI
  // ============================================================

  Uri _uri(List<String> pathSegments) {
    final base = Uri.parse(App.outsideurl);

    return base.replace(
      pathSegments: [
        ...base.pathSegments.where((e) => e.isNotEmpty),
        ...pathSegments,
      ],
    );
  }

  // ============================================================
  // RESPONSE KONTROL
  // ============================================================

  dynamic _decodeResponse(
    http.Response response,
    Uri uri,
  ) {
    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'API Hatası\n'
        'Status: ${response.statusCode}\n'
        'URL: $uri\n'
        'Body: ${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      return null;
    }

    return jsonDecode(response.body);
  }

  // ============================================================
  // MEVCUT HAFTA
  //
  // GET:
  // /Sera/DonguMevcutHafta
  // ============================================================

  Future<DonguHaftaModel> mevcutHafta() async {
    final uri = _uri([
      'Sera',
      'DonguMevcutHafta',
    ]);

    try {
      final response = await _client.get(uri);

      final decoded = _decodeResponse(
        response,
        uri,
      );

      if (decoded is! Map) {
        throw Exception(
          'Mevcut hafta cevabı Map değil.',
        );
      }

      return DonguHaftaModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (e) {
      throw Exception(
        'Mevcut hafta alınamadı: $e',
      );
    }
  }

  // ============================================================
  // BÖLÜMLER
  //
  // GET:
  // /Sera/DonguBolumler/{personelKodu}
  // ============================================================

  Future<List<DonguBolumModel>> bolumler({
    required String personelKodu,
  }) async {
    final uri = _uri([
      'Sera',
      'DonguBolumler',
      personelKodu,
    ]);

    try {
      final response = await _client.get(uri);

      final decoded = _decodeResponse(
        response,
        uri,
      );

      if (decoded is! List) {
        throw Exception(
          'Bölüm cevabı List değil.',
        );
      }

      return decoded
          .map(
            (e) => DonguBolumModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(
        'Bölümler alınamadı: $e',
      );
    }
  }

  // ============================================================
  // İŞLER
  //
  // GET:
  // /Sera/DonguIsler/{personelKodu}/{bolumKodu}
  // ============================================================

Future<List<DonguIsModel>> isler({
  required String personelKodu,
  required String bolumKodu,
}) async {
  final String url =
      '${App.outsideurl}/Sera/DonguIsler/'
      '${Uri.encodeComponent(personelKodu.trim())}/'
      '${Uri.encodeComponent(bolumKodu.trim())}/';

  final Uri uri = Uri.parse(url);

  try {
    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'İş listesi alınamadı.\n'
        'Status: ${response.statusCode}\n'
        'URL: $uri\n'
        'Body: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception(
        'İş listesi beklenen formatta değil.\n'
        'Body: ${response.body}',
      );
    }

    return decoded
        .map(
          (e) => DonguIsModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  } catch (e) {
    throw Exception('İş listesi alınamadı: $e');
  }
}

  // ============================================================
  // NORMAL DÖNGÜ LİSTESİ
  //
  // GET:
  // /Sera/DonguListe/{bolum}/{iskodu}/{yil}/{hafta}/{tamamlananlar}
  //
  // tamamlananlar:
  // false -> 0
  // true  -> 1
  // ============================================================

  Future<List<DonguListeModel>> donguListe({
    required String bolum,
    required String isKodu,
    required int yil,
    required int hafta,
    bool tamamlananlar = false,
  }) async {
    final uri = _uri([
      'Sera',
      'DonguListe',
      bolum,
      isKodu,
      yil.toString(),
      hafta.toString(),
      tamamlananlar ? '1' : '0',
    ]);

    try {
      final response = await _client.get(uri);

      final decoded = _decodeResponse(
        response,
        uri,
      );

      if (decoded is! List) {
        throw Exception(
          'Döngü listesi cevabı List değil.',
        );
      }

      return decoded
          .map(
            (e) => DonguListeModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(
        'Döngü listesi alınamadı: $e',
      );
    }
  }

  // ============================================================
  // TABLO GÖSTER
  //
  // GET:
  // /Sera/DonguTablo/{bolum}/{iskodu}/{yil}/{hafta}
  // ============================================================

  Future<List<DonguTabloModel>> donguTablo({
    required String bolum,
    required String isKodu,
    required int yil,
    required int hafta,
  }) async {
    final uri = _uri([
      'Sera',
      'DonguTablo',
      bolum,
      isKodu,
      yil.toString(),
      hafta.toString(),
    ]);

    try {
      final response = await _client.get(uri);

      final decoded = _decodeResponse(
        response,
        uri,
      );

      if (decoded is! List) {
        throw Exception(
          'Döngü tablo cevabı List değil.',
        );
      }

      return decoded
          .map(
            (e) => DonguTabloModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(
        'Döngü tablosu alınamadı: $e',
      );
    }
  }

  // ============================================================
  // PERSONELLER
  //
  // GET:
  // /Sera/DonguPersoneller
  // ============================================================

  Future<List<DonguPersonelModel>> personeller() async {
    final uri = _uri([
      'Sera',
      'DonguPersoneller',
    ]);

    try {
      final response = await _client.get(uri);

      final decoded = _decodeResponse(
        response,
        uri,
      );

      if (decoded is! List) {
        throw Exception(
          'Personel cevabı List değil.',
        );
      }

      return decoded
          .map(
            (e) => DonguPersonelModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(
        'Personeller alınamadı: $e',
      );
    }
  }

  // ============================================================
  // PERSONEL DEĞİŞTİR
  //
  // POST:
  // /Sera/DonguPersonelDegistir
  // ============================================================

  Future<DonguPersonelDegistirSonucModel>
      personelDegistir({
    required List<int> isEmriIdleri,
    required String yeniPersonelKodu,
    required int kullaniciId,
  }) async {
    if (isEmriIdleri.isEmpty) {
      throw Exception(
        'Personeli değiştirilecek iş seçilmedi.',
      );
    }

    if (yeniPersonelKodu.trim().isEmpty) {
      throw Exception(
        'Yeni personel seçilmedi.',
      );
    }

    final uri = _uri([
      'Sera',
      'DonguPersonelDegistir',
    ]);

    final model = DonguPersonelDegistirModel(
      isEmriIdleri: isEmriIdleri,
      yeniPersonelKodu: yeniPersonelKodu,
      kullaniciId: kullaniciId,
    );

    try {
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

      final decoded = _decodeResponse(
        response,
        uri,
      );

      if (decoded is! Map) {
        throw Exception(
          'Personel değiştirme cevabı Map değil.',
        );
      }

      return DonguPersonelDegistirSonucModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (e) {
      throw Exception(
        'Personel değiştirilemedi: $e',
      );
    }
  }

  // ============================================================
  // CLIENT KAPAT
  // ============================================================

  void dispose() {
    _client.close();
  }
}