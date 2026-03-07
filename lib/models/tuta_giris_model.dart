class TutaRowModel {
  final String sera;

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

  int deger1;
  int deger2;
  int deger3;
  int deger4;
  int deger5;
  int deger6;
  int deger7;
  int deger8;
  int deger9;
  int deger10;
  int deger11;
  int deger12;
  int deger13;
  int deger14;
  int deger15;
  int deger16;

  TutaRowModel({
    required this.sera,
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

  factory TutaRowModel.fromJson(Map<String, dynamic> json) {
    return TutaRowModel(
      sera: json['sera']?.toString() ?? '',
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

  Map<String, dynamic> toJson() {
    return {
      'sera': sera,
      'deger1': deger1,
      'deger2': deger2,
      'deger3': deger3,
      'deger4': deger4,
      'deger5': deger5,
      'deger6': deger6,
      'deger7': deger7,
      'deger8': deger8,
      'deger9': deger9,
      'deger10': deger10,
      'deger11': deger11,
      'deger12': deger12,
      'deger13': deger13,
      'deger14': deger14,
      'deger15': deger15,
      'deger16': deger16,
    };
  }

  TutaRowModel copyWith({
    String? sera,
    String? isim1,
    String? isim2,
    String? isim3,
    String? isim4,
    String? isim5,
    String? isim6,
    String? isim7,
    String? isim8,
    String? isim9,
    String? isim10,
    String? isim11,
    String? isim12,
    String? isim13,
    String? isim14,
    String? isim15,
    String? isim16,
    int? deger1,
    int? deger2,
    int? deger3,
    int? deger4,
    int? deger5,
    int? deger6,
    int? deger7,
    int? deger8,
    int? deger9,
    int? deger10,
    int? deger11,
    int? deger12,
    int? deger13,
    int? deger14,
    int? deger15,
    int? deger16,
  }) {
    return TutaRowModel(
      sera: sera ?? this.sera,
      isim1: isim1 ?? this.isim1,
      isim2: isim2 ?? this.isim2,
      isim3: isim3 ?? this.isim3,
      isim4: isim4 ?? this.isim4,
      isim5: isim5 ?? this.isim5,
      isim6: isim6 ?? this.isim6,
      isim7: isim7 ?? this.isim7,
      isim8: isim8 ?? this.isim8,
      isim9: isim9 ?? this.isim9,
      isim10: isim10 ?? this.isim10,
      isim11: isim11 ?? this.isim11,
      isim12: isim12 ?? this.isim12,
      isim13: isim13 ?? this.isim13,
      isim14: isim14 ?? this.isim14,
      isim15: isim15 ?? this.isim15,
      isim16: isim16 ?? this.isim16,
      deger1: deger1 ?? this.deger1,
      deger2: deger2 ?? this.deger2,
      deger3: deger3 ?? this.deger3,
      deger4: deger4 ?? this.deger4,
      deger5: deger5 ?? this.deger5,
      deger6: deger6 ?? this.deger6,
      deger7: deger7 ?? this.deger7,
      deger8: deger8 ?? this.deger8,
      deger9: deger9 ?? this.deger9,
      deger10: deger10 ?? this.deger10,
      deger11: deger11 ?? this.deger11,
      deger12: deger12 ?? this.deger12,
      deger13: deger13 ?? this.deger13,
      deger14: deger14 ?? this.deger14,
      deger15: deger15 ?? this.deger15,
      deger16: deger16 ?? this.deger16,
    );
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

  int get doluAlanSayisi {
    final values = [
      deger1,
      deger2,
      deger3,
      deger4,
      deger5,
      deger6,
      deger7,
      deger8,
      deger9,
      deger10,
      deger11,
      deger12,
      deger13,
      deger14,
      deger15,
      deger16,
    ];
    return values.where((e) => e > 0).length;
  }

  List<String> get isimler => [
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
      ];

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

class TutaGirisResponseModel {
  final DateTime? tarih;
  final List<TutaRowModel> rows;

  TutaGirisResponseModel({
    required this.tarih,
    required this.rows,
  });

  factory TutaGirisResponseModel.fromJson(Map<String, dynamic> json) {
    return TutaGirisResponseModel(
      tarih: json['tarih'] == null
          ? null
          : DateTime.tryParse(json['tarih'].toString()),
      rows: (json['rows'] as List?)
              ?.map((e) => TutaRowModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tarih': tarih?.toIso8601String(),
      'rows': rows.map((e) => e.toJson()).toList(),
    };
  }
}

class TutaKaydetRequestModel {
  final DateTime tarih;
  final List<TutaRowModel> rows;

  TutaKaydetRequestModel({
    required this.tarih,
    required this.rows,
  });

  Map<String, dynamic> toJson() {
    return {
      'tarih': tarih.toIso8601String(),
      'rows': rows.map((e) => e.toJson()).toList(),
    };
  }
}

class SonucModel {
  final bool durum;
  final String mesaj;

  SonucModel({
    required this.durum,
    required this.mesaj,
  });

  factory SonucModel.fromJson(Map<String, dynamic> json) {
    return SonucModel(
      durum: json['durum'] == true,
      mesaj: json['mesaj']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'durum': durum,
      'mesaj': mesaj,
    };
  }
}