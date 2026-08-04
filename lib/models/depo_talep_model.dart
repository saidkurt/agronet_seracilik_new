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
  });

  factory DepoTalepEvrakModel.fromJson(Map<String, dynamic> json) {
    return DepoTalepEvrakModel(
      seri: json['Seri']?.toString() ?? json['seri']?.toString(),
      sira: _toInt(json['Sira'] ?? json['sira']),
      evrakNo: json['EvrakNo']?.toString() ?? json['evrakNo']?.toString(),
      tarih: _toDateTime(json['Tarih'] ?? json['tarih']),
      kaynakDepoNo: _toInt(
        json['KaynakDepoNo'] ?? json['kaynakDepoNo'],
      ),
      kaynakDepo:
          json['KaynakDepo']?.toString() ??
          json['kaynakDepo']?.toString(),
      hedefDepoNo: _toInt(
        json['HedefDepoNo'] ?? json['hedefDepoNo'],
      ),
      hedefDepo:
          json['HedefDepo']?.toString() ??
          json['hedefDepo']?.toString(),
      kalemSayisi: _toInt(
        json['KalemSayisi'] ?? json['kalemSayisi'],
      ),
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
    };
  }
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
    this.kalemler,
  });

  factory DepoTalepDetayModel.fromJson(Map<String, dynamic> json) {
    final rawKalemler = json['Kalemler'] ?? json['kalemler'];

    return DepoTalepDetayModel(
      seri: json['Seri']?.toString() ?? json['seri']?.toString(),
      sira: _toInt(json['Sira'] ?? json['sira']),
      evrakNo: json['EvrakNo']?.toString() ?? json['evrakNo']?.toString(),
      tarih: _toDateTime(json['Tarih'] ?? json['tarih']),
      kaynakDepoNo: _toInt(
        json['KaynakDepoNo'] ?? json['kaynakDepoNo'],
      ),
      kaynakDepo:
          json['KaynakDepo']?.toString() ??
          json['kaynakDepo']?.toString(),
      hedefDepoNo: _toInt(
        json['HedefDepoNo'] ?? json['hedefDepoNo'],
      ),
      hedefDepo:
          json['HedefDepo']?.toString() ??
          json['hedefDepo']?.toString(),
      kalemler: rawKalemler is List
          ? rawKalemler
                .whereType<Map>()
                .map(
                  (item) => DepoTalepKalemModel.fromJson(
                    Map<String, dynamic>.from(item),
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
      'Kalemler': kalemler?.map((e) => e.toJson()).toList(),
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