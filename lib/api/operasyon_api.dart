import 'dart:async';
import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/login_user_model.dart';
import 'package:agronet/models/operasyon_models.dart';
import 'package:http/http.dart' as http;

class OperasyonApi {
  final LoginUserModel user;
  final http.Client _client;

  OperasyonApi({
    required this.user,
    http.Client? client,
  }) : _client = client ?? http.Client();

  String get personelKodu {
    final bsrKod = user.bsrKullaniciKodu?.trim() ?? '';
    if (bsrKod.isNotEmpty) return bsrKod;
    return user.prosiskodu?.trim() ?? '';
  }

  void dispose() => _client.close();

  Future<OperasyonOzet> ozet() async {
    final json = await _getMap('Ozet');
    return OperasyonOzet.fromJson(json);
  }

  Future<BekleyenGruplar> bekleyenGruplar() async {
    final json = await _getMap('BekleyenGruplar');
    return BekleyenGruplar.fromJson(json);
  }

  Future<List<OperasyonSecim>> seralar(bool oncelikli) async {
    final list = await _getList(
      'Seralar',
      extra: {'oncelikli': oncelikli.toString()},
    );
    return list.map(OperasyonSecim.fromJson).toList();
  }

  Future<List<OperasyonSecim>> isler({
    required String bolumKodu,
    required bool oncelikli,
  }) async {
    final list = await _getList(
      'Isler',
      extra: {
        'bolumKodu': bolumKodu,
        'oncelikli': oncelikli.toString(),
      },
    );
    return list.map(OperasyonSecim.fromJson).toList();
  }

  Future<List<OperasyonTunel>> tuneller({
    required String bolumKodu,
    required String isKodu,
    required int isSeviyesi,
    required bool oncelikli,
  }) async {
    final list = await _getList(
      'Tuneller',
      extra: {
        'bolumKodu': bolumKodu,
        'isKodu': isKodu,
        'isSeviyesi': isSeviyesi.toString(),
        'oncelikli': oncelikli.toString(),
      },
    );
    return list.map(OperasyonTunel.fromJson).toList();
  }

  Future<List<OperasyonKoridor>> koridorlar({
    required String bolumKodu,
    required String isKodu,
    required int isSeviyesi,
    required String tunel,
    required bool oncelikli,
  }) async {
    final list = await _getList(
      'Koridorlar',
      extra: {
        'bolumKodu': bolumKodu,
        'isKodu': isKodu,
        'isSeviyesi': isSeviyesi.toString(),
        'tunel': tunel,
        'oncelikli': oncelikli.toString(),
      },
    );
    return list.map(OperasyonKoridor.fromJson).toList();
  }

  Future<List<OperasyonIs>> durumIsleri(int durum) async {
    final list = await _getList(
      'DurumIsleri',
      extra: {'durum': durum.toString()},
    );
    return list.map(OperasyonIs.fromJson).toList();
  }

  Future<OperasyonDetay> detay(int isEmriId) async {
    final json = await _getMap('Detay/$isEmriId');
    return OperasyonDetay.fromJson(json);
  }

  Future<List<OperasyonKodIsim>> araSebepleri() async {
    final list = await _getList('AraSebepleri');
    return list.map(OperasyonKodIsim.fromJson).toList();
  }

  Future<List<OperasyonKodIsim>> sokumNedenleri() async {
    final list = await _getList('SokumNedenleri');
    return list.map(OperasyonKodIsim.fromJson).toList();
  }

  Future<OperasyonApiSonuc> durumDegistir({
    required int isEmriId,
    String araSebebi = '',
  }) async {
    final json = await _post(
      'DurumDegistir',
      {
        'IsEmriId': isEmriId,
        'PersonelKodu': personelKodu,
        'AraSebebi': araSebebi,
        ..._oturumBody,
      },
    );
    return OperasyonApiSonuc.fromJson(json);
  }

  Future<OperasyonApiSonuc> bitir({
    required int isEmriId,
    int sokulenBitkiSayisi = 0,
    String sokumNedeni = '',
  }) async {
    final json = await _post(
      'Bitir',
      {
        'IsEmriId': isEmriId,
        'PersonelKodu': personelKodu,
        'SokulenBitkiSayisi': sokulenBitkiSayisi,
        'SokumNedeni': sokumNedeni,
        'BsrUserId': user.bsrUserId ?? 1,
        ..._oturumBody,
      },
    );
    return OperasyonApiSonuc.fromJson(json);
  }

  Future<List<OperasyonKutu>> kutular(int isEmriId) async {
    final list = await _getList('Kutular/$isEmriId');
    return list.map(OperasyonKutu.fromJson).toList();
  }

  Future<OperasyonApiSonuc> kutuEkle({
    required int isEmriId,
    required String barkod,
  }) async {
    return _kutuIslemi(
      endpoint: 'KutuEkle',
      isEmriId: isEmriId,
      barkod: barkod,
    );
  }

  Future<OperasyonApiSonuc> kutuCikar({
    required int isEmriId,
    required String barkod,
  }) async {
    return _kutuIslemi(
      endpoint: 'KutuCikar',
      isEmriId: isEmriId,
      barkod: barkod,
    );
  }

  Future<OperasyonApiSonuc> _kutuIslemi({
    required String endpoint,
    required int isEmriId,
    required String barkod,
  }) async {
    final json = await _post(
      endpoint,
      {
        'IsEmriId': isEmriId,
        'PersonelKodu': personelKodu,
        'Barkod': barkod,
        'BsrUserId': user.bsrUserId ?? 1,
        ..._oturumBody,
      },
    );
    return OperasyonApiSonuc.fromJson(json);
  }

  Map<String, Object> get _oturumBody => {
        'OturumId': user.oturumId ?? 0,
        'Token': user.token?.trim() ?? '',
      };

  Map<String, String> get _temelQuery => {
        'personelKodu': personelKodu,
        'oturumId': (user.oturumId ?? 0).toString(),
        'token': user.token?.trim() ?? '',
      };

  Future<Map<String, dynamic>> _getMap(
    String endpoint, {
    Map<String, String>? extra,
  }) async {
    final response = await _client
        .get(
          _uri(endpoint, {..._temelQuery, ...?extra}),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));

    final decoded = _decode(response);
    if (decoded is! Map) {
      throw const OperasyonApiException('Sunucu cevabı geçersiz.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<List<Map<String, dynamic>>> _getList(
    String endpoint, {
    Map<String, String>? extra,
  }) async {
    final response = await _client
        .get(
          _uri(endpoint, {..._temelQuery, ...?extra}),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));

    final decoded = _decode(response);
    if (decoded is! List) {
      throw const OperasyonApiException('Sunucu cevabı liste değil.');
    }

    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, Object?> body,
  ) async {
    final response = await _client
        .post(
          _uri(endpoint),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    final decoded = _decode(response);
    if (decoded is! Map) {
      throw const OperasyonApiException('Sunucu cevabı geçersiz.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  dynamic _decode(http.Response response) {
    dynamic decoded;

    try {
      decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);
    } catch (_) {
      throw OperasyonApiException(
        'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OperasyonApiException(
        _mesaj(decoded) ?? 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  Uri _uri(String endpoint, [Map<String, String>? query]) {
    final base = App.outsideurl.endsWith('/')
        ? App.outsideurl.substring(0, App.outsideurl.length - 1)
        : App.outsideurl;

    return Uri.parse('$base/Operasyon/$endpoint').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  String? _mesaj(dynamic decoded) {
    if (decoded is String && decoded.trim().isNotEmpty) return decoded.trim();
    if (decoded is! Map) return null;

    final map = Map<String, dynamic>.from(decoded);
    for (final key in const [
      'Mesaj',
      'mesaj',
      'Message',
      'message',
      'ExceptionMessage',
    ]) {
      final text = map[key]?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
  }
}

class OperasyonApiException implements Exception {
  final String message;
  final int? statusCode;

  const OperasyonApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
