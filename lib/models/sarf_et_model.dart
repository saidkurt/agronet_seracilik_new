class SarfDepoModel {
  final int depoNo;
  final String depoAdi;

  const SarfDepoModel({
    required this.depoNo,
    required this.depoAdi,
  });

  factory SarfDepoModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SarfDepoModel(
      depoNo: _toInt(
        json['DepoNo'] ?? json['depoNo'],
      ),
      depoAdi: _toString(
        json['DepoAdi'] ?? json['depoAdi'],
      ),
    );
  }
}

class SarfStokModel {
  final String stokKodu;
  final String stokAdi;
  final double depodakiMiktar;
  final String birim;

  const SarfStokModel({
    required this.stokKodu,
    required this.stokAdi,
    required this.depodakiMiktar,
    required this.birim,
  });

  factory SarfStokModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SarfStokModel(
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

class SarfKaydetKalemModel {
  final String stokKodu;
  final double miktar;

  const SarfKaydetKalemModel({
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

class SarfKaydetRequestModel {
  final int depoNo;
  final DateTime tarih;
  final String aciklama;

  final String kullaniciKodu;
  final int oturumId;
  final String token;

  final List<SarfKaydetKalemModel> kalemler;

  const SarfKaydetRequestModel({
    required this.depoNo,
    required this.tarih,
    required this.aciklama,
    required this.kullaniciKodu,
    required this.oturumId,
    required this.token,
    required this.kalemler,
  });

  Map<String, dynamic> toJson() {
    return {
      'DepoNo': depoNo,
      'Tarih': _dateOnly(tarih),
      'Aciklama': aciklama,
      'KullaniciKodu': kullaniciKodu,
      'OturumId': oturumId,
      'Token': token,
      'Kalemler':
          kalemler.map((e) => e.toJson()).toList(),
    };
  }
}

class SarfKaydetSonucModel {
  final bool basarili;
  final String mesaj;
  final String evrakSeri;
  final int evrakSira;
  final int etkilenenSatir;

  const SarfKaydetSonucModel({
    required this.basarili,
    required this.mesaj,
    required this.evrakSeri,
    required this.evrakSira,
    required this.etkilenenSatir,
  });

  factory SarfKaydetSonucModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SarfKaydetSonucModel(
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
}

String _dateOnly(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');

  return '$y-$m-$d';
}

String _toString(dynamic value) {
  return value?.toString() ?? '';
}

int _toInt(dynamic value) {
  if (value is int) return value;

  return int.tryParse(
        value?.toString() ?? '',
      ) ??
      0;
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
        value
                ?.toString()
                .replaceAll(',', '.') ??
            '',
      ) ??
      0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;

  if (value is num) {
    return value != 0;
  }

  final x = value?.toString().toLowerCase();

  return x == 'true' || x == '1';
}