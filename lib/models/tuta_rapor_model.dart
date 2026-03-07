class TutaRaporModel {
  final DateTime? tarih;
  final int deger1;
  final int deger2;
  final int deger3;
  final int deger4;
  final int deger5;
  final int deger6;
  final int deger7;
  final int deger8;
  final int deger9;
  final int deger10;
  final int deger11;
  final int deger12;
  final int deger13;
  final int deger14;
  final int deger15;
  final int deger16;

  const TutaRaporModel({
    this.tarih,
    this.deger1 = 0,
    this.deger2 = 0,
    this.deger3 = 0,
    this.deger4 = 0,
    this.deger5 = 0,
    this.deger6 = 0,
    this.deger7 = 0,
    this.deger8 = 0,
    this.deger9 = 0,
    this.deger10 = 0,
    this.deger11 = 0,
    this.deger12 = 0,
    this.deger13 = 0,
    this.deger14 = 0,
    this.deger15 = 0,
    this.deger16 = 0,
  });

  factory TutaRaporModel.fromJson(Map<String, dynamic> json) {
    return TutaRaporModel(
      tarih: DateTime.tryParse((json['tarih'] ?? '').toString()),
      deger1: _toInt(json['deger1']),
      deger2: _toInt(json['deger2']),
      deger3: _toInt(json['deger3']),
      deger4: _toInt(json['deger4']),
      deger5: _toInt(json['deger5']),
      deger6: _toInt(json['deger6']),
      deger7: _toInt(json['deger7']),
      deger8: _toInt(json['deger8']),
      deger9: _toInt(json['deger9']),
      deger10: _toInt(json['deger10']),
      deger11: _toInt(json['deger11']),
      deger12: _toInt(json['deger12']),
      deger13: _toInt(json['deger13']),
      deger14: _toInt(json['deger14']),
      deger15: _toInt(json['deger15']),
      deger16: _toInt(json['deger16']),
    );
  }

  int degerGetir(int no) {
    switch (no) {
      case 1:
        return deger1;
      case 2:
        return deger2;
      case 3:
        return deger3;
      case 4:
        return deger4;
      case 5:
        return deger5;
      case 6:
        return deger6;
      case 7:
        return deger7;
      case 8:
        return deger8;
      case 9:
        return deger9;
      case 10:
        return deger10;
      case 11:
        return deger11;
      case 12:
        return deger12;
      case 13:
        return deger13;
      case 14:
        return deger14;
      case 15:
        return deger15;
      case 16:
        return deger16;
      default:
        return 0;
    }
  }

  int get toplam =>
      deger1 +
      deger2 +
      deger3 +
      deger4 +
      deger5 +
      deger6 +
      deger7 +
      deger8 +
      deger9 +
      deger10 +
      deger11 +
      deger12 +
      deger13 +
      deger14 +
      deger15 +
      deger16;

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

class TutaIsimlerModel {
  final String isim1;
  final String isim2;
  final String isim3;
  final String isim4;
  final String isim5;
  final String isim6;
  final String isim7;
  final String isim8;
  final String isim9;
  final String isim10;
  final String isim11;
  final String isim12;
  final String isim13;
  final String isim14;
  final String isim15;
  final String isim16;

  const TutaIsimlerModel({
    this.isim1 = '',
    this.isim2 = '',
    this.isim3 = '',
    this.isim4 = '',
    this.isim5 = '',
    this.isim6 = '',
    this.isim7 = '',
    this.isim8 = '',
    this.isim9 = '',
    this.isim10 = '',
    this.isim11 = '',
    this.isim12 = '',
    this.isim13 = '',
    this.isim14 = '',
    this.isim15 = '',
    this.isim16 = '',
  });

  factory TutaIsimlerModel.fromJson(Map<String, dynamic> json) {
    return TutaIsimlerModel(
      isim1: (json['isim1'] ?? '').toString(),
      isim2: (json['isim2'] ?? '').toString(),
      isim3: (json['isim3'] ?? '').toString(),
      isim4: (json['isim4'] ?? '').toString(),
      isim5: (json['isim5'] ?? '').toString(),
      isim6: (json['isim6'] ?? '').toString(),
      isim7: (json['isim7'] ?? '').toString(),
      isim8: (json['isim8'] ?? '').toString(),
      isim9: (json['isim9'] ?? '').toString(),
      isim10: (json['isim10'] ?? '').toString(),
      isim11: (json['isim11'] ?? '').toString(),
      isim12: (json['isim12'] ?? '').toString(),
      isim13: (json['isim13'] ?? '').toString(),
      isim14: (json['isim14'] ?? '').toString(),
      isim15: (json['isim15'] ?? '').toString(),
      isim16: (json['isim16'] ?? '').toString(),
    );
  }

  String isimGetir(int no) {
    switch (no) {
      case 1:
        return isim1;
      case 2:
        return isim2;
      case 3:
        return isim3;
      case 4:
        return isim4;
      case 5:
        return isim5;
      case 6:
        return isim6;
      case 7:
        return isim7;
      case 8:
        return isim8;
      case 9:
        return isim9;
      case 10:
        return isim10;
      case 11:
        return isim11;
      case 12:
        return isim12;
      case 13:
        return isim13;
      case 14:
        return isim14;
      case 15:
        return isim15;
      case 16:
        return isim16;
      default:
        return '';
    }
  }
}

class TutaSeraDataModel {
  final String sera;
  final TutaIsimlerModel isimler;
  final List<TutaRaporModel> rapor;

  const TutaSeraDataModel({
    required this.sera,
    required this.isimler,
    required this.rapor,
  });
}

class TutaToplamModel {
  final String sera;
  final DateTime? tarih;
  final int toplam;

  const TutaToplamModel({
    this.sera = '',
    this.tarih,
    this.toplam = 0,
  });

  factory TutaToplamModel.fromJson(Map<String, dynamic> json) {
    return TutaToplamModel(
      sera: (json['sera'] ?? '').toString(),
      tarih: DateTime.tryParse((json['tarih'] ?? '').toString()),
      toplam: _toInt(json['toplam']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}