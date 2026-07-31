class BeyazSinekGirisResponseModel {
  final DateTime tarih;
  final List<BeyazSinekRowModel> rows;

  const BeyazSinekGirisResponseModel({
    required this.tarih,
    required this.rows,
  });

  factory BeyazSinekGirisResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawRows = json['rows'];

    return BeyazSinekGirisResponseModel(
      tarih: _parseDateTime(json['tarih']),
      rows: rawRows is List
          ? rawRows
              .whereType<Map>()
              .map(
                (item) => BeyazSinekRowModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : <BeyazSinekRowModel>[],
    );
  }
}

class BeyazSinekKaydetRequestModel {
  final DateTime tarih;
  final String personelKodu;
  final List<BeyazSinekRowModel> rows;

  const BeyazSinekKaydetRequestModel({
    required this.tarih,
    required this.personelKodu,
    required this.rows,
  });

  Map<String, dynamic> toJson() {
    return {
      'tarih': _formatDate(tarih),
      'personelKodu': personelKodu,
      'rows': rows.map((item) => item.toJson()).toList(),
    };
  }
}

class BeyazSinekAlanModel {
  final int index;
  final String isim;
  final int deger;
  final bool pasif;

  const BeyazSinekAlanModel({
    required this.index,
    required this.isim,
    required this.deger,
    required this.pasif,
  });
}

class BeyazSinekRowModel {
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

  final bool pasif1;
  final bool pasif2;
  final bool pasif3;
  final bool pasif4;
  final bool pasif5;
  final bool pasif6;
  final bool pasif7;
  final bool pasif8;
  final bool pasif9;
  final bool pasif10;
  final bool pasif11;
  final bool pasif12;
  final bool pasif13;
  final bool pasif14;
  final bool pasif15;
  final bool pasif16;

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

  const BeyazSinekRowModel({
    required this.sera,
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
    required this.pasif1,
    required this.pasif2,
    required this.pasif3,
    required this.pasif4,
    required this.pasif5,
    required this.pasif6,
    required this.pasif7,
    required this.pasif8,
    required this.pasif9,
    required this.pasif10,
    required this.pasif11,
    required this.pasif12,
    required this.pasif13,
    required this.pasif14,
    required this.pasif15,
    required this.pasif16,
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
  });

  factory BeyazSinekRowModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return BeyazSinekRowModel(
      sera: _stringValue(json['sera']),
      isim1: _stringValue(json['isim1']),
      isim2: _stringValue(json['isim2']),
      isim3: _stringValue(json['isim3']),
      isim4: _stringValue(json['isim4']),
      isim5: _stringValue(json['isim5']),
      isim6: _stringValue(json['isim6']),
      isim7: _stringValue(json['isim7']),
      isim8: _stringValue(json['isim8']),
      isim9: _stringValue(json['isim9']),
      isim10: _stringValue(json['isim10']),
      isim11: _stringValue(json['isim11']),
      isim12: _stringValue(json['isim12']),
      isim13: _stringValue(json['isim13']),
      isim14: _stringValue(json['isim14']),
      isim15: _stringValue(json['isim15']),
      isim16: _stringValue(json['isim16']),
      pasif1: _boolValue(json['pasif1']),
      pasif2: _boolValue(json['pasif2']),
      pasif3: _boolValue(json['pasif3']),
      pasif4: _boolValue(json['pasif4']),
      pasif5: _boolValue(json['pasif5']),
      pasif6: _boolValue(json['pasif6']),
      pasif7: _boolValue(json['pasif7']),
      pasif8: _boolValue(json['pasif8']),
      pasif9: _boolValue(json['pasif9']),
      pasif10: _boolValue(json['pasif10']),
      pasif11: _boolValue(json['pasif11']),
      pasif12: _boolValue(json['pasif12']),
      pasif13: _boolValue(json['pasif13']),
      pasif14: _boolValue(json['pasif14']),
      pasif15: _boolValue(json['pasif15']),
      pasif16: _boolValue(json['pasif16']),
      deger1: _intValue(json['deger1']),
      deger2: _intValue(json['deger2']),
      deger3: _intValue(json['deger3']),
      deger4: _intValue(json['deger4']),
      deger5: _intValue(json['deger5']),
      deger6: _intValue(json['deger6']),
      deger7: _intValue(json['deger7']),
      deger8: _intValue(json['deger8']),
      deger9: _intValue(json['deger9']),
      deger10: _intValue(json['deger10']),
      deger11: _intValue(json['deger11']),
      deger12: _intValue(json['deger12']),
      deger13: _intValue(json['deger13']),
      deger14: _intValue(json['deger14']),
      deger15: _intValue(json['deger15']),
      deger16: _intValue(json['deger16']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sera': sera,
      'isim1': isim1,
      'isim2': isim2,
      'isim3': isim3,
      'isim4': isim4,
      'isim5': isim5,
      'isim6': isim6,
      'isim7': isim7,
      'isim8': isim8,
      'isim9': isim9,
      'isim10': isim10,
      'isim11': isim11,
      'isim12': isim12,
      'isim13': isim13,
      'isim14': isim14,
      'isim15': isim15,
      'isim16': isim16,
      'pasif1': pasif1,
      'pasif2': pasif2,
      'pasif3': pasif3,
      'pasif4': pasif4,
      'pasif5': pasif5,
      'pasif6': pasif6,
      'pasif7': pasif7,
      'pasif8': pasif8,
      'pasif9': pasif9,
      'pasif10': pasif10,
      'pasif11': pasif11,
      'pasif12': pasif12,
      'pasif13': pasif13,
      'pasif14': pasif14,
      'pasif15': pasif15,
      'pasif16': pasif16,
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

  BeyazSinekRowModel copyWith({
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
    bool? pasif1,
    bool? pasif2,
    bool? pasif3,
    bool? pasif4,
    bool? pasif5,
    bool? pasif6,
    bool? pasif7,
    bool? pasif8,
    bool? pasif9,
    bool? pasif10,
    bool? pasif11,
    bool? pasif12,
    bool? pasif13,
    bool? pasif14,
    bool? pasif15,
    bool? pasif16,
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
    return BeyazSinekRowModel(
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
      pasif1: pasif1 ?? this.pasif1,
      pasif2: pasif2 ?? this.pasif2,
      pasif3: pasif3 ?? this.pasif3,
      pasif4: pasif4 ?? this.pasif4,
      pasif5: pasif5 ?? this.pasif5,
      pasif6: pasif6 ?? this.pasif6,
      pasif7: pasif7 ?? this.pasif7,
      pasif8: pasif8 ?? this.pasif8,
      pasif9: pasif9 ?? this.pasif9,
      pasif10: pasif10 ?? this.pasif10,
      pasif11: pasif11 ?? this.pasif11,
      pasif12: pasif12 ?? this.pasif12,
      pasif13: pasif13 ?? this.pasif13,
      pasif14: pasif14 ?? this.pasif14,
      pasif15: pasif15 ?? this.pasif15,
      pasif16: pasif16 ?? this.pasif16,
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

  List<String> get isimler => [
        isim1, isim2, isim3, isim4, isim5, isim6, isim7, isim8,
        isim9, isim10, isim11, isim12, isim13, isim14, isim15, isim16,
      ];

  List<bool> get pasifler => [
        pasif1, pasif2, pasif3, pasif4, pasif5, pasif6, pasif7, pasif8,
        pasif9, pasif10, pasif11, pasif12, pasif13, pasif14, pasif15, pasif16,
      ];

  List<int> get degerler => [
        deger1, deger2, deger3, deger4, deger5, deger6, deger7, deger8,
        deger9, deger10, deger11, deger12, deger13, deger14, deger15, deger16,
      ];

  List<BeyazSinekAlanModel> get aktifAlanlar {
    final sonuc = <BeyazSinekAlanModel>[];

    for (var i = 0; i < 16; i++) {
      final isim = isimler[i].trim();
      final pasif = pasifler[i];

      if (pasif || isim.isEmpty) continue;

      sonuc.add(
        BeyazSinekAlanModel(
          index: i,
          isim: isim,
          deger: degerler[i],
          pasif: pasif,
        ),
      );
    }

    return sonuc;
  }

  int get aktifAlanSayisi => aktifAlanlar.length;

  int get toplam {
    return aktifAlanlar.fold<int>(
      0,
      (toplam, alan) => toplam + alan.deger,
    );
  }

  int get doluAlanSayisi {
    return aktifAlanlar.where((alan) => alan.deger > 0).length;
  }
}

class SonucModel {
  final bool durum;
  final String mesaj;

  const SonucModel({
    required this.durum,
    required this.mesaj,
  });

  factory SonucModel.fromJson(Map<String, dynamic> json) {
    return SonucModel(
      durum: _boolValue(json['durum']),
      mesaj: _stringValue(json['mesaj']),
    );
  }
}

String _stringValue(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

int _intValue(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

bool _boolValue(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1';
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

String _formatDate(DateTime date) {
  final yil = date.year.toString().padLeft(4, '0');
  final ay = date.month.toString().padLeft(2, '0');
  final gun = date.day.toString().padLeft(2, '0');
  return '$yil-$ay-$gun';
}
