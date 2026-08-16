class DepoTalepDepoModel {
  final int depoNo;
  final String depoAdi;

  const DepoTalepDepoModel({
    required this.depoNo,
    required this.depoAdi,
  });

  factory DepoTalepDepoModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DepoTalepDepoModel(
      depoNo: _toInt(
        json['DepoNo'] ?? json['depoNo'],
      ),
      depoAdi: _toString(
        json['DepoAdi'] ?? json['depoAdi'],
      ),
    );
  }
}

// ============================================================
// STOK ARAMA
// ============================================================

class DepoTalepStokModel {
  final String stokKodu;
  final String stokAdi;
  final double depodakiMiktar;
  final String birim;

  const DepoTalepStokModel({
    required this.stokKodu,
    required this.stokAdi,
    required this.depodakiMiktar,
    required this.birim,
  });

  factory DepoTalepStokModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DepoTalepStokModel(
      stokKodu: _toString(
        json['StokKodu'] ?? json['stokKodu'],
      ),
      stokAdi: _toString(
        json['StokAdi'] ?? json['stokAdi'],
      ),
      depodakiMiktar: _toDouble(
        json['DepodakiMiktar'] ??
            json['depodakiMiktar'],
      ),
      birim: _toString(
        json['Birim'] ?? json['birim'],
      ),
    );
  }
}

// ============================================================
// MOBİLDE SEÇİLEN / EKLENEN TALEP SATIRI
// Bu model sadece Flutter ekranında kullanılabilir.
// ============================================================

class DepoTalepGirisKalemModel {
  final String stokKodu;
  final String stokAdi;
  final double miktar;
  final String birim;
  final double depodakiMiktar;

  const DepoTalepGirisKalemModel({
    required this.stokKodu,
    required this.stokAdi,
    required this.miktar,
    required this.birim,
    required this.depodakiMiktar,
  });

  DepoTalepGirisKalemModel copyWith({
    String? stokKodu,
    String? stokAdi,
    double? miktar,
    String? birim,
    double? depodakiMiktar,
  }) {
    return DepoTalepGirisKalemModel(
      stokKodu: stokKodu ?? this.stokKodu,
      stokAdi: stokAdi ?? this.stokAdi,
      miktar: miktar ?? this.miktar,
      birim: birim ?? this.birim,
      depodakiMiktar:
          depodakiMiktar ?? this.depodakiMiktar,
    );
  }
}

// ============================================================
// KAYDET KALEMİ
// POST /Depo/TalepKaydet içindeki Kalemler
// ============================================================

class DepoTalepKaydetKalemModel {
  final String stokKodu;
  final double miktar;

  const DepoTalepKaydetKalemModel({
    required this.stokKodu,
    required this.miktar,
  });

  Map<String, dynamic> toJson() {
    return {
      'StokKodu': stokKodu,
      'Miktar': miktar,
    };
  }
}
class DepoTalepDepolarModel {
  final DepoTalepDepoModel? kaynakDepo;
  final List<DepoTalepDepoModel> hedefDepolar;

  const DepoTalepDepolarModel({
    required this.kaynakDepo,
    required this.hedefDepolar,
  });

  factory DepoTalepDepolarModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final kaynakJson =
        json['KaynakDepo'] ?? json['kaynakDepo'];

    final hedefJson =
        json['HedefDepolar'] ?? json['hedefDepolar'];

    DepoTalepDepoModel? kaynak;

    if (kaynakJson is Map) {
      kaynak = DepoTalepDepoModel.fromJson(
        Map<String, dynamic>.from(kaynakJson),
      );
    }

    final List<DepoTalepDepoModel> hedefler = [];

    if (hedefJson is List) {
      for (final item in hedefJson) {
        if (item is Map) {
          hedefler.add(
            DepoTalepDepoModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return DepoTalepDepolarModel(
      kaynakDepo: kaynak,
      hedefDepolar: hedefler,
    );
  }
}

// ============================================================
// TALEP KAYDET REQUEST
// ============================================================

class DepoTalepKaydetModel {
  final int kaynakDepoNo;
  final int hedefDepoNo;

  final String kullaniciKodu;
  final int oturumId;
  final String token;

  final List<DepoTalepKaydetKalemModel> kalemler;

  const DepoTalepKaydetModel({
    required this.kaynakDepoNo,
    required this.hedefDepoNo,
    required this.kullaniciKodu,
    required this.oturumId,
    required this.token,
    required this.kalemler,
  });

  Map<String, dynamic> toJson() {
    return {
      'KaynakDepoNo': kaynakDepoNo,
      'HedefDepoNo': hedefDepoNo,
      'KullaniciKodu': kullaniciKodu,
      'OturumId': oturumId,
      'Token': token,
      'Kalemler':
          kalemler.map((e) => e.toJson()).toList(),
    };
  }
}

// ============================================================
// KAYDET SONUCU
// Backend IslemSonucDto
// ============================================================

class DepoTalepIslemSonucModel {
  final bool basarili;
  final String mesaj;
  final String evrakSeri;
  final int evrakSira;
  final int etkilenenSatir;

  const DepoTalepIslemSonucModel({
    required this.basarili,
    required this.mesaj,
    required this.evrakSeri,
    required this.evrakSira,
    required this.etkilenenSatir,
  });

  factory DepoTalepIslemSonucModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DepoTalepIslemSonucModel(
      basarili: _toBool(
        json['Basarili'] ?? json['basarili'],
      ),
      mesaj: _toString(
        json['Mesaj'] ?? json['mesaj'],
      ),
      evrakSeri: _toString(
        json['EvrakSeri'] ?? json['evrakSeri'],
      ),
      evrakSira: _toInt(
        json['EvrakSira'] ?? json['evrakSira'],
      ),
      etkilenenSatir: _toInt(
        json['EtkilenenSatir'] ??
            json['etkilenenSatir'],
      ),
    );
  }

  String get evrakNo {
    if (evrakSeri.trim().isEmpty) {
      return evrakSira.toString();
    }

    return '$evrakSeri-$evrakSira';
  }
}

// ============================================================
// HELPERS
// ============================================================

String _toString(dynamic value) {
  if (value == null) return '';

  return value.toString().trim();
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
        value?.toString() ?? '',
      ) ??
      0;
}

double _toDouble(dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  final text = value
      ?.toString()
      .trim()
      .replaceAll(',', '.');

  return double.tryParse(text ?? '') ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final text =
      value?.toString().trim().toLowerCase();

  return text == 'true' ||
      text == '1' ||
      text == 'yes';
}