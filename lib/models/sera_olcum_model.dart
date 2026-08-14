class SeraOlcumEkranModel {
  final bool success;
  final String tarih;
  final List<String> tipler;
  final List<SeraOlcumYerModel> yerler;

  const SeraOlcumEkranModel({
    required this.success,
    required this.tarih,
    required this.tipler,
    required this.yerler,
  });

  factory SeraOlcumEkranModel.fromJson(Map<String, dynamic> json) {
    return SeraOlcumEkranModel(
      success: _toBool(json['success']),
      tarih: _toString(json['tarih']),
      tipler: (json['tipler'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      yerler: (json['yerler'] as List? ?? [])
          .whereType<Map>()
          .map(
            (e) => SeraOlcumYerModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

class SeraOlcumYerModel {
  final String sera;
  final String vana;
  final List<SeraOlcumModel> olcumler;

  const SeraOlcumYerModel({
    required this.sera,
    required this.vana,
    required this.olcumler,
  });

  factory SeraOlcumYerModel.fromJson(Map<String, dynamic> json) {
    return SeraOlcumYerModel(
      sera: _toString(json['sera']),
      vana: _toString(json['vana']),
      olcumler: (json['olcumler'] as List? ?? [])
          .whereType<Map>()
          .map(
            (e) => SeraOlcumModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

class SeraOlcumModel {
  final String tip;
  final double? deger;
  final String veriGirisTipi;
  final List<SeraOlcumDetayModel> detaylar;

  const SeraOlcumModel({
    required this.tip,
    required this.deger,
    required this.veriGirisTipi,
    required this.detaylar,
  });

  factory SeraOlcumModel.fromJson(Map<String, dynamic> json) {
    return SeraOlcumModel(
      tip: _toString(json['tip']),
      deger: _toDoubleNullable(json['deger']),
      veriGirisTipi: _toString(json['veriGirisTipi']),
      detaylar: (json['detaylar'] as List? ?? [])
          .whereType<Map>()
          .map(
            (e) => SeraOlcumDetayModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

class SeraOlcumDetayModel {
  final int satirNo;
  final double deger;

  const SeraOlcumDetayModel({
    required this.satirNo,
    required this.deger,
  });

  factory SeraOlcumDetayModel.fromJson(Map<String, dynamic> json) {
    return SeraOlcumDetayModel(
      satirNo: _toInt(json['satirNo']),
      deger: _toDouble(json['deger']),
    );
  }
}

class SeraOlcumTarihModel {
  final String tarih;
  final String tarihText;

  const SeraOlcumTarihModel({
    required this.tarih,
    required this.tarihText,
  });

  factory SeraOlcumTarihModel.fromJson(Map<String, dynamic> json) {
    return SeraOlcumTarihModel(
      tarih: _toString(json['tarih']),
      tarihText: _toString(json['tarihText']),
    );
  }
}

class SeraOlcumKaydetModel {
  final DateTime tarih;
  final String kullaniciKodu;
  final List<SeraOlcumKaydetDetayModel> olcumler;

  const SeraOlcumKaydetModel({
    required this.tarih,
    required this.kullaniciKodu,
    required this.olcumler,
  });

  Map<String, dynamic> toJson() {
    return {
      'tarih': _yyyyMmDd(tarih),
      'kullaniciKodu': kullaniciKodu,
      'olcumler': olcumler.map((e) => e.toJson()).toList(),
    };
  }
}

class SeraOlcumKaydetDetayModel {
  final String sera;
  final String vana;
  final String tip;
  final double? deger;
  final String? veriGirisTipi;
  final List<double> detaylar;

  const SeraOlcumKaydetDetayModel({
    required this.sera,
    required this.vana,
    required this.tip,
    this.deger,
    this.veriGirisTipi,
    this.detaylar = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'sera': sera,
      'vana': vana,
      'tip': tip,
      'deger': deger,
      'veriGirisTipi': veriGirisTipi,
      'detaylar': detaylar,
    };
  }
}

String _toString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

bool _toBool(dynamic value) {
  if (value is bool) return value;

  if (value is num) {
    return value != 0;
  }

  final text = value?.toString().toLowerCase().trim();

  return text == 'true' ||
      text == '1' ||
      text == 'yes';
}

int _toInt(dynamic value) {
  if (value is int) return value;

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
        value?.toString().replaceAll(',', '.') ?? '',
      ) ??
      0;
}

double? _toDoubleNullable(dynamic value) {
  if (value == null) return null;

  if (value is double) return value;

  if (value is num) {
    return value.toDouble();
  }

  final text = value.toString().trim();

  if (text.isEmpty) return null;

  return double.tryParse(
    text.replaceAll(',', '.'),
  );
}

String _yyyyMmDd(DateTime tarih) {
  String iki(int value) {
    return value.toString().padLeft(2, '0');
  }

  return '${tarih.year}-'
      '${iki(tarih.month)}-'
      '${iki(tarih.day)}';
}