import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/depo_talep.dart';
import 'package:agronet/models/depo_talep_model.dart';
import 'package:http/http.dart' as http;

class DepoTalepApi {
  static final String _base = App.outsideurl;

  // ============================================================
  // TALEP OLUŞTURMA - DEPOLAR
  // GET /Depo/TalepDepolar
  // ============================================================

 Future<DepoTalepDepolarModel> talepDepolariGetir({
  required String personelKodu,
}) async {
  final uri = Uri.parse(
    '$_base/Depo/TalepDepolar',
  ).replace(
    queryParameters: {
      'personelKodu': personelKodu.trim(),
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
      _hataMesajiGetir(response),
    );
  }

  final decoded = jsonDecode(response.body);

  if (decoded is! Map) {
    throw Exception(
      'Depo listesi cevabı geçersiz.',
    );
  }

  return DepoTalepDepolarModel.fromJson(
    Map<String, dynamic>.from(decoded),
  );
}

  // ============================================================
  // TALEP OLUŞTURMA - STOK ARA
  // GET /Depo/TalepStokAra
  //
  // depo                = kaynak depo
  // arama               = stok kodu / stok adı
  // sadeceDepodaOlanlar = true/false
  // ============================================================

  Future<List<DepoTalepStokModel>> talepStokAra({
    required int depoNo,
    String arama = '',
    bool sadeceDepodaOlanlar = true,
  }) async {
    final uri = Uri.parse(
      '$_base/Depo/TalepStokAra',
    ).replace(
      queryParameters: {
        'depo': depoNo.toString(),
        'arama': arama.trim(),
        'sadeceDepodaOlanlar':
            sadeceDepodaOlanlar.toString(),
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
        _hataMesajiGetir(response),
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (e) => DepoTalepStokModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  // ============================================================
  // TALEP OLUŞTURMA - KAYDET
  // POST /Depo/TalepKaydet
  // ============================================================


  

  Future<DepoTalepIslemSonucModel> talepKaydet(
    DepoTalepKaydetModel model,
  ) async {
    final uri = Uri.parse(
      '$_base/Depo/TalepKaydet',
    );

    final requestBody = jsonEncode(
      model.toJson(),
    );

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type':
            'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: requestBody,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _hataMesajiGetir(response),
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Talep kayıt cevabı geçersiz.',
      );
    }

    final sonuc =
        DepoTalepIslemSonucModel.fromJson(
      Map<String, dynamic>.from(decoded),
    );

    if (!sonuc.basarili) {
      throw Exception(
        sonuc.mesaj.isEmpty
            ? 'Depo talebi kaydedilemedi.'
            : sonuc.mesaj,
      );
    }

    return sonuc;
  }

  // ============================================================
  // AÇIK TALEP EVRAKLARI
  // GET /Depo/TalepEvraklari
  // ============================================================

  Future<List<DepoTalepEvrakModel>>
      talepEvraklariGetir() async {
    final uri = Uri.parse(
      '$_base/Depo/TalepEvraklari',
    );

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        _hataMesajiGetir(response),
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (e) => DepoTalepEvrakModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  // ============================================================
  // EVRAK DETAY
  // GET /Depo/TalepDetay
  // ============================================================

  Future<DepoTalepDetayModel?> talepDetayGetir({
    required String seri,
    required int sira,
  }) async {
    final uri = Uri.parse(
      '$_base/Depo/TalepDetay',
    ).replace(
      queryParameters: {
        'seri': seri,
        'sira': sira.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception(
        _hataMesajiGetir(response),
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Evrak detay cevabı geçersiz.',
      );
    }

    return DepoTalepDetayModel.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  // ============================================================
  // TALEBİ ONAYLA
  // POST /Depo/TalepOnayla
  // ============================================================

  Future<DepoIslemSonucModel> talepOnayla(
    DepoTalepOnayRequestModel model,
  ) async {
    final uri = Uri.parse(
      '$_base/Depo/TalepOnayla',
    );

    final requestBody = jsonEncode(
      model.toJson(),
    );

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type':
            'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: requestBody,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _hataMesajiGetir(response),
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Onaylama cevabı geçersiz.',
      );
    }

    return DepoIslemSonucModel.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  // ============================================================
  // KALANI KAPAT
  // POST /Depo/TalepKalaniKapat
  // ============================================================

  Future<DepoIslemSonucModel> talepKalaniKapat(
    DepoTalepKapatRequestModel model,
  ) async {
    final uri = Uri.parse(
      '$_base/Depo/TalepKalaniKapat',
    );

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type':
            'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(
        model.toJson(),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _hataMesajiGetir(response),
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Kalanı kapatma cevabı geçersiz.',
      );
    }

    return DepoIslemSonucModel.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  // ============================================================
  // HATA MESAJI
  // ============================================================

  static String _hataMesajiGetir(
    http.Response response,
  ) {
    final varsayilanMesaj =
        'HTTP ${response.statusCode}';

    if (response.body.trim().isEmpty) {
      return varsayilanMesaj;
    }

    try {
      final decoded =
          jsonDecode(response.body);

      if (decoded is Map) {
        final map =
            Map<String, dynamic>.from(
          decoded,
        );

        return map['mesaj']?.toString() ??
            map['Mesaj']?.toString() ??
            map['message']?.toString() ??
            map['Message']?.toString() ??
            map['ExceptionMessage']
                ?.toString() ??
            '$varsayilanMesaj: ${response.body}';
      }

      return '$varsayilanMesaj: $decoded';
    } catch (_) {
      return '$varsayilanMesaj: ${response.body}';
    }
  }
    // ============================================================
  // BİLDİRİMDEN AÇILAN TALEP DETAYI
  // GET /Depo/TalepBildirimDetay
  //
  // Açık / tamamlanmış / iptal edilmiş fişi göstermek için.
  // Normal TalepDetay ekranından bağımsızdır.
  // ============================================================

  Future<DepoTalepBildirimDetayModel?>
      talepBildirimDetayGetir({
    required String seri,
    required int sira,
  }) async {
    final temizSeri = seri.trim();

    if (temizSeri.isEmpty) {
      throw Exception(
        'Evrak seri bilgisi boş.',
      );
    }

    if (sira <= 0) {
      throw Exception(
        'Evrak sıra numarası geçersiz.',
      );
    }

    final uri = Uri.parse(
      '$_base/Depo/TalepBildirimDetay',
    ).replace(
      queryParameters: {
        'seri': temizSeri,
        'sira': sira.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception(
        _hataMesajiGetir(response),
      );
    }

    if (response.body.trim().isEmpty) {
      throw Exception(
        'Talep detay cevabı boş.',
      );
    }

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Talep bildirim detay cevabı geçersiz.',
      );
    }

    return DepoTalepBildirimDetayModel.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }
}