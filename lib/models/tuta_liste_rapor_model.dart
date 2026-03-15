class TutaListeRaporResponse {
  final List<TutaListeRowModel> rapor;
  final List<TutaIsimlerModel> isimler;
  final List<TutaTunelModel> tuneller;

  const TutaListeRaporResponse({
    required this.rapor,
    required this.isimler,
    required this.tuneller,
  });

  factory TutaListeRaporResponse.fromJson(Map<String, dynamic> json) {
    return TutaListeRaporResponse(
      rapor: (json['rapor'] as List? ?? [])
          .map((e) => TutaListeRowModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isimler: (json['isimler'] as List? ?? [])
          .map((e) => TutaIsimlerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      tuneller: (json['tuneller'] as List? ?? [])
          .map((e) => TutaTunelModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TutaListeRowModel {
  final DateTime? tarih;
  final String sera;
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
  final int toplam;
  final String ilac;

  const TutaListeRowModel({
    required this.tarih,
    required this.sera,
    required this.deger1,
    required this.deger2,
    required this.deger3,
    required this.deger4,
    required this.deger5,
    required this.deger6,
    required this.deger7,
    required this.deger8,
    required this.deger9,
    required this.deger10,
    required this.deger11,
    required this.deger12,
    required this.deger13,
    required this.deger14,
    required this.deger15,
    required this.deger16,
    required this.toplam,
    required this.ilac,
  });

  factory TutaListeRowModel.fromJson(Map<String, dynamic> json) {
    return TutaListeRowModel(
      tarih: DateTime.tryParse(json['tarih']?.toString() ?? ''),
      sera: json['sera']?.toString() ?? '',
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
      toplam: _toInt(json['toplam']),
      ilac: json['ilac']?.toString() ?? '',
    );
  }

  int getDegerByIndex(int index) {
    switch (index) {
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
    required this.isim1,
    required this.isim2,
    required this.isim3,
    required this.isim4,
    required this.isim5,
    required this.isim6,
    required this.isim7,
    required this.isim8,
    required this.isim9,
    required this.isim10,
    required this.isim11,
    required this.isim12,
    required this.isim13,
    required this.isim14,
    required this.isim15,
    required this.isim16,
  });

  factory TutaIsimlerModel.fromJson(Map<String, dynamic> json) {
    return TutaIsimlerModel(
      isim1: json['isim1']?.toString() ?? '',
      isim2: json['isim2']?.toString() ?? '',
      isim3: json['isim3']?.toString() ?? '',
      isim4: json['isim4']?.toString() ?? '',
      isim5: json['isim5']?.toString() ?? '',
      isim6: json['isim6']?.toString() ?? '',
      isim7: json['isim7']?.toString() ?? '',
      isim8: json['isim8']?.toString() ?? '',
      isim9: json['isim9']?.toString() ?? '',
      isim10: json['isim10']?.toString() ?? '',
      isim11: json['isim11']?.toString() ?? '',
      isim12: json['isim12']?.toString() ?? '',
      isim13: json['isim13']?.toString() ?? '',
      isim14: json['isim14']?.toString() ?? '',
      isim15: json['isim15']?.toString() ?? '',
      isim16: json['isim16']?.toString() ?? '',
    );
  }

  String getIsimByIndex(int index) {
    switch (index) {
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

  List<String> get aktifIsimler {
    return [
      isim1,
      isim2,
      isim3,
      isim4,
      isim5,
      isim6,
      isim7,
      isim8,
      isim9,
      isim10,
      isim11,
      isim12,
      isim13,
      isim14,
      isim15,
      isim16,
    ].where((e) => e.trim().isNotEmpty).toList();
  }
}

class TutaTunelModel {
  final String kod;
  final String yon;
  final String tunel;

  const TutaTunelModel({
    required this.kod,
    required this.yon,
    required this.tunel,
  });

  factory TutaTunelModel.fromJson(Map<String, dynamic> json) {
    return TutaTunelModel(
      kod: json['kod']?.toString() ?? '',
      yon: json['yon']?.toString() ?? '',
      tunel: json['tunel']?.toString() ?? '',
    );
  }

  String get caption {
    if (tunel.isNotEmpty) return tunel;
    return '$yon$kod';
  }

  int get degerIndex {
    if (tunel.length >= 5) {
      final raw = tunel.substring(1); // örn: K01 / G05 mantığına göre değilse fallback var
      final match = RegExp(r'(\d+)$').firstMatch(raw);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '') ?? 0;
      }
    }
    return 0;
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}