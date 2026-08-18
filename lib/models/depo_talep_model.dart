class DepoTalepEvrakModel {
  final String? seri;
  final int? sira;
  final String? evrakNo;
  final DateTime? tarih;
  final int? kaynakDepoNo;
  final String? kaynakDepo;
  final int? hedefDepoNo;
  final String? hedefDepo;
  final int? kalemSayisi;

  // YENİ
  final String? olusturanProsisKodu;
  final String? olusturanAdi;

  const DepoTalepEvrakModel({
    this.seri,
    this.sira,
    this.evrakNo,
    this.tarih,
    this.kaynakDepoNo,
    this.kaynakDepo,
    this.hedefDepoNo,
    this.hedefDepo,
    this.kalemSayisi,
    this.olusturanProsisKodu,
    this.olusturanAdi,
  });

  factory DepoTalepEvrakModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DepoTalepEvrakModel(
      seri:
          json['Seri']?.toString() ??
          json['seri']?.toString(),

      sira: _toInt(
        json['Sira'] ?? json['sira'],
      ),

      evrakNo:
          json['EvrakNo']?.toString() ??
          json['evrakNo']?.toString(),

      tarih: _toDateTime(
        json['Tarih'] ?? json['tarih'],
      ),

      kaynakDepoNo: _toInt(
        json['KaynakDepoNo'] ??
            json['kaynakDepoNo'],
      ),

      kaynakDepo:
          json['KaynakDepo']?.toString() ??
          json['kaynakDepo']?.toString(),

      hedefDepoNo: _toInt(
        json['HedefDepoNo'] ??
            json['hedefDepoNo'],
      ),

      hedefDepo:
          json['HedefDepo']?.toString() ??
          json['hedefDepo']?.toString(),

      kalemSayisi: _toInt(
        json['KalemSayisi'] ??
            json['kalemSayisi'],
      ),

      // YENİ
      olusturanProsisKodu:
          json['OlusturanProsisKodu']
                  ?.toString() ??
              json['olusturanProsisKodu']
                  ?.toString(),

      olusturanAdi:
          json['OlusturanAdi']
                  ?.toString() ??
              json['olusturanAdi']
                  ?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Seri': seri,
      'Sira': sira,
      'EvrakNo': evrakNo,
      'Tarih': tarih?.toIso8601String(),
      'KaynakDepoNo': kaynakDepoNo,
      'KaynakDepo': kaynakDepo,
      'HedefDepoNo': hedefDepoNo,
      'HedefDepo': hedefDepo,
      'KalemSayisi': kalemSayisi,

      // YENİ
      'OlusturanProsisKodu':
          olusturanProsisKodu,

      'OlusturanAdi':
          olusturanAdi,
    };
  }
}

// ============================================================
// BİLDİRİMDEN AÇILAN DEPO TALEP DETAYI
// GET /Depo/TalepBildirimDetay
//
// Bu model normal Depo Talep Onay ekranından bağımsızdır.
// Bildirime tıklanınca açılan salt-okunur detay ekranında kullanılır.
// ============================================================

class DepoTalepBildirimDetayModel {
  final String seri;
  final int sira;
  final String evrakNo;

  final DateTime? tarih;

  final int kaynakDepoNo;
  final String kaynakDepo;

  final int hedefDepoNo;
  final String hedefDepo;

  final String olusturanProsisKodu;
  final String olusturanAdi;

  final String sonOnaylayanProsisKodu;
  final String sonOnaylayanAdi;

  final DateTime? sonOnayTarihi;

  final bool tamamlandi;
  final DateTime? tamamlanmaTarihi;

  final String durum;

  final List<DepoTalepBildirimKalemModel> kalemler;

  const DepoTalepBildirimDetayModel({
    required this.seri,
    required this.sira,
    required this.evrakNo,
    required this.tarih,
    required this.kaynakDepoNo,
    required this.kaynakDepo,
    required this.hedefDepoNo,
    required this.hedefDepo,
    required this.olusturanProsisKodu,
    required this.olusturanAdi,
    required this.sonOnaylayanProsisKodu,
    required this.sonOnaylayanAdi,
    required this.sonOnayTarihi,
    required this.tamamlandi,
    required this.tamamlanmaTarihi,
    required this.durum,
    required this.kalemler,
  });

  factory DepoTalepBildirimDetayModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawKalemler =
        json['Kalemler'] ??
        json['kalemler'];

    final List<DepoTalepBildirimKalemModel>
        kalemListesi = [];

    if (rawKalemler is List) {
      for (final item in rawKalemler) {
        if (item is Map) {
          kalemListesi.add(
            DepoTalepBildirimKalemModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return DepoTalepBildirimDetayModel(
      seri:
          (json['Seri'] ??
                  json['seri'] ??
                  '')
              .toString()
              .trim(),

      sira:
          _toInt(
            json['Sira'] ??
                json['sira'],
          ) ??
          0,

      evrakNo:
          (json['EvrakNo'] ??
                  json['evrakNo'] ??
                  '')
              .toString()
              .trim(),

      tarih: _toDateTime(
        json['Tarih'] ??
            json['tarih'],
      ),

      kaynakDepoNo:
          _toInt(
            json['KaynakDepoNo'] ??
                json['kaynakDepoNo'],
          ) ??
          0,

      kaynakDepo:
          (json['KaynakDepo'] ??
                  json['kaynakDepo'] ??
                  '')
              .toString()
              .trim(),

      hedefDepoNo:
          _toInt(
            json['HedefDepoNo'] ??
                json['hedefDepoNo'],
          ) ??
          0,

      hedefDepo:
          (json['HedefDepo'] ??
                  json['hedefDepo'] ??
                  '')
              .toString()
              .trim(),

      olusturanProsisKodu:
          (json['OlusturanProsisKodu'] ??
                  json['olusturanProsisKodu'] ??
                  '')
              .toString()
              .trim(),

      olusturanAdi:
          (json['OlusturanAdi'] ??
                  json['olusturanAdi'] ??
                  '')
              .toString()
              .trim(),

      sonOnaylayanProsisKodu:
          (json['SonOnaylayanProsisKodu'] ??
                  json['sonOnaylayanProsisKodu'] ??
                  '')
              .toString()
              .trim(),

      sonOnaylayanAdi:
          (json['SonOnaylayanAdi'] ??
                  json['sonOnaylayanAdi'] ??
                  '')
              .toString()
              .trim(),

      sonOnayTarihi: _toDateTime(
        json['SonOnayTarihi'] ??
            json['sonOnayTarihi'],
      ),

      tamamlandi:
          _toBool(
            json['Tamamlandi'] ??
                json['tamamlandi'],
          ) ??
          false,

      tamamlanmaTarihi: _toDateTime(
        json['TamamlanmaTarihi'] ??
            json['tamamlanmaTarihi'],
      ),

      durum:
          (json['Durum'] ??
                  json['durum'] ??
                  '')
              .toString()
              .trim()
              .toUpperCase(),

      kalemler: kalemListesi,
    );
  }

  // ==========================================================
  // EKRANDA KULLANILABİLECEK KOLAYLIK ALANLARI
  // ==========================================================

  bool get onaylandi =>
      durum == 'ONAYLANDI';

  bool get kismiOnay =>
      durum == 'KISMI_ONAY';

  bool get iptal =>
      durum == 'IPTAL';

  bool get bekliyor =>
      durum == 'BEKLIYOR';

  String get gorunenEvrakNo {
    if (evrakNo.trim().isNotEmpty) {
      return evrakNo.trim();
    }

    if (seri.trim().isNotEmpty) {
      return '$seri-$sira';
    }

    return sira.toString();
  }
}


// ============================================================
// BİLDİRİM DETAYI - KALEM
// ============================================================

class DepoTalepBildirimKalemModel {
  final String guid;

  final String stokKodu;
  final String stokAdi;

  final double talepMiktari;
  final double teslimMiktari;
  final double kalanMiktar;

  final String birim;

  final bool kapatildi;

  final String durum;

  const DepoTalepBildirimKalemModel({
    required this.guid,
    required this.stokKodu,
    required this.stokAdi,
    required this.talepMiktari,
    required this.teslimMiktari,
    required this.kalanMiktar,
    required this.birim,
    required this.kapatildi,
    required this.durum,
  });

  factory DepoTalepBildirimKalemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DepoTalepBildirimKalemModel(
      guid:
          (json['Guid'] ??
                  json['guid'] ??
                  '')
              .toString()
              .trim(),

      stokKodu:
          (json['StokKodu'] ??
                  json['stokKodu'] ??
                  '')
              .toString()
              .trim(),

      stokAdi:
          (json['StokAdi'] ??
                  json['stokAdi'] ??
                  '')
              .toString()
              .trim(),

      talepMiktari:
          _toDouble(
            json['TalepMiktari'] ??
                json['talepMiktari'],
          ) ??
          0,

      teslimMiktari:
          _toDouble(
            json['TeslimMiktari'] ??
                json['teslimMiktari'],
          ) ??
          0,

      kalanMiktar:
          _toDouble(
            json['KalanMiktar'] ??
                json['kalanMiktar'],
          ) ??
          0,

      birim:
          (json['Birim'] ??
                  json['birim'] ??
                  '')
              .toString()
              .trim(),

      kapatildi:
          _toBool(
            json['Kapatildi'] ??
                json['kapatildi'],
          ) ??
          false,

      durum:
          (json['Durum'] ??
                  json['durum'] ??
                  '')
              .toString()
              .trim()
              .toUpperCase(),
    );
  }

  bool get onaylandi =>
      durum == 'ONAYLANDI';

  bool get kismiOnay =>
      durum == 'KISMI_ONAY';

  bool get iptal =>
      durum == 'IPTAL';

  bool get bekliyor =>
      durum == 'BEKLIYOR';
}

class DepoTalepDetayModel {
  final String? seri;
  final int? sira;
  final String? evrakNo;
  final DateTime? tarih;
  final int? kaynakDepoNo;
  final String? kaynakDepo;
  final int? hedefDepoNo;
  final String? hedefDepo;

  // YENİ
  final String? olusturanProsisKodu;
  final String? olusturanAdi;

  final List<DepoTalepKalemModel>? kalemler;

  const DepoTalepDetayModel({
    this.seri,
    this.sira,
    this.evrakNo,
    this.tarih,
    this.kaynakDepoNo,
    this.kaynakDepo,
    this.hedefDepoNo,
    this.hedefDepo,

    // YENİ
    this.olusturanProsisKodu,
    this.olusturanAdi,

    this.kalemler,
  });

  factory DepoTalepDetayModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawKalemler =
        json['Kalemler'] ??
        json['kalemler'];

    return DepoTalepDetayModel(
      seri:
          json['Seri']?.toString() ??
          json['seri']?.toString(),

      sira: _toInt(
        json['Sira'] ?? json['sira'],
      ),

      evrakNo:
          json['EvrakNo']?.toString() ??
          json['evrakNo']?.toString(),

      tarih: _toDateTime(
        json['Tarih'] ?? json['tarih'],
      ),

      kaynakDepoNo: _toInt(
        json['KaynakDepoNo'] ??
            json['kaynakDepoNo'],
      ),

      kaynakDepo:
          json['KaynakDepo']?.toString() ??
          json['kaynakDepo']?.toString(),

      hedefDepoNo: _toInt(
        json['HedefDepoNo'] ??
            json['hedefDepoNo'],
      ),

      hedefDepo:
          json['HedefDepo']?.toString() ??
          json['hedefDepo']?.toString(),

      // YENİ
      olusturanProsisKodu:
          json['OlusturanProsisKodu']
                  ?.toString() ??
              json['olusturanProsisKodu']
                  ?.toString(),

      olusturanAdi:
          json['OlusturanAdi']
                  ?.toString() ??
              json['olusturanAdi']
                  ?.toString(),

      kalemler: rawKalemler is List
          ? rawKalemler
              .whereType<Map>()
              .map(
                (item) =>
                    DepoTalepKalemModel.fromJson(
                  Map<String, dynamic>.from(
                    item,
                  ),
                ),
              )
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Seri': seri,
      'Sira': sira,
      'EvrakNo': evrakNo,
      'Tarih': tarih?.toIso8601String(),
      'KaynakDepoNo': kaynakDepoNo,
      'KaynakDepo': kaynakDepo,
      'HedefDepoNo': hedefDepoNo,
      'HedefDepo': hedefDepo,

      // YENİ
      'OlusturanProsisKodu':
          olusturanProsisKodu,

      'OlusturanAdi':
          olusturanAdi,

      'Kalemler':
          kalemler
              ?.map((e) => e.toJson())
              .toList(),
    };
  }
}

class DepoTalepKalemModel {
  final String? guid;
  final String? stokKodu;
  final String? stokAdi;
  final double? talepMiktari;
  final double? teslimMiktari;
  final double? kalanMiktar;
  final String? birim;

  const DepoTalepKalemModel({
    this.guid,
    this.stokKodu,
    this.stokAdi,
    this.talepMiktari,
    this.teslimMiktari,
    this.kalanMiktar,
    this.birim,
  });

  factory DepoTalepKalemModel.fromJson(Map<String, dynamic> json) {
    return DepoTalepKalemModel(
      guid: json['Guid']?.toString() ?? json['guid']?.toString(),
      stokKodu:
          json['StokKodu']?.toString() ??
          json['stokKodu']?.toString(),
      stokAdi:
          json['StokAdi']?.toString() ??
          json['stokAdi']?.toString(),
      talepMiktari: _toDouble(
        json['TalepMiktari'] ?? json['talepMiktari'],
      ),
      teslimMiktari: _toDouble(
        json['TeslimMiktari'] ?? json['teslimMiktari'],
      ),
      kalanMiktar: _toDouble(
        json['KalanMiktar'] ?? json['kalanMiktar'],
      ),
      birim: json['Birim']?.toString() ?? json['birim']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Guid': guid,
      'StokKodu': stokKodu,
      'StokAdi': stokAdi,
      'TalepMiktari': talepMiktari,
      'TeslimMiktari': teslimMiktari,
      'KalanMiktar': kalanMiktar,
      'Birim': birim,
    };
  }
}

class DepoTalepOnayRequestModel {
  final String? seri;
  final int? sira;
  final String? kullaniciKodu;
  final int? oturumId;
  final String? token;
  final List<DepoTalepOnayKalemModel>? kalemler;

  const DepoTalepOnayRequestModel({
    this.seri,
    this.sira,
    this.kullaniciKodu,
    this.oturumId,
    this.token,
    this.kalemler,
  });

  factory DepoTalepOnayRequestModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawKalemler = json['Kalemler'] ?? json['kalemler'];

    return DepoTalepOnayRequestModel(
      seri: json['Seri']?.toString() ?? json['seri']?.toString(),
      sira: _toInt(json['Sira'] ?? json['sira']),
      kullaniciKodu:
          json['KullaniciKodu']?.toString() ??
          json['kullaniciKodu']?.toString(),
      oturumId: _toInt(
        json['OturumId'] ?? json['oturumId'],
      ),
      token:
          json['Token']?.toString() ??
          json['token']?.toString(),
      kalemler: rawKalemler is List
          ? rawKalemler
              .whereType<Map>()
              .map(
                (e) => DepoTalepOnayKalemModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Seri': seri,
      'Sira': sira,
      'KullaniciKodu': kullaniciKodu,
      'OturumId': oturumId,
      'Token': token,
      'Kalemler': kalemler?.map((e) => e.toJson()).toList(),
    };
  }
}

class DepoTalepOnayKalemModel {
  final String? guid;
  final double? kabulMiktar;

  const DepoTalepOnayKalemModel({
    this.guid,
    this.kabulMiktar,
  });

  factory DepoTalepOnayKalemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DepoTalepOnayKalemModel(
      guid: json['Guid']?.toString() ?? json['guid']?.toString(),
      kabulMiktar: _toDouble(
        json['KabulMiktar'] ?? json['kabulMiktar'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Guid': guid,
      'KabulMiktar': kabulMiktar,
    };
  }
}

class DepoTalepKapatRequestModel {
  final String? seri;
  final int? sira;
  final String? kullaniciKodu;
  final int? oturumId;
  final String? token;

  const DepoTalepKapatRequestModel({
    this.seri,
    this.sira,
    this.kullaniciKodu,
    this.oturumId,
    this.token,
  });

  factory DepoTalepKapatRequestModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DepoTalepKapatRequestModel(
      seri: json['Seri']?.toString() ?? json['seri']?.toString(),
      sira: _toInt(json['Sira'] ?? json['sira']),
      kullaniciKodu:
          json['KullaniciKodu']?.toString() ??
          json['kullaniciKodu']?.toString(),
      oturumId: _toInt(
        json['OturumId'] ?? json['oturumId'],
      ),
      token:
          json['Token']?.toString() ??
          json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Seri': seri,
      'Sira': sira,
      'KullaniciKodu': kullaniciKodu,
      'OturumId': oturumId,
      'Token': token,
    };
  }
}

class DepoIslemSonucModel {
  final bool? basarili;
  final String? mesaj;
  final String? evrakSeri;
  final int? evrakSira;
  final int? etkilenenSatir;

  const DepoIslemSonucModel({
    this.basarili,
    this.mesaj,
    this.evrakSeri,
    this.evrakSira,
    this.etkilenenSatir,
  });

  factory DepoIslemSonucModel.fromJson(Map<String, dynamic> json) {
    return DepoIslemSonucModel(
      basarili: _toBool(
        json['Basarili'] ?? json['basarili'],
      ),
      mesaj:
          json['Mesaj']?.toString() ??
          json['mesaj']?.toString(),
      evrakSeri:
          json['EvrakSeri']?.toString() ??
          json['evrakSeri']?.toString(),
      evrakSira: _toInt(
        json['EvrakSira'] ?? json['evrakSira'],
      ),
      etkilenenSatir: _toInt(
        json['EtkilenenSatir'] ?? json['etkilenenSatir'],
      ),
    );
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();

  return double.tryParse(
    value.toString().replaceAll(',', '.'),
  );
}

bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;

  final text = value.toString().toLowerCase().trim();

  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;

  return null;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  return DateTime.tryParse(value.toString());
}