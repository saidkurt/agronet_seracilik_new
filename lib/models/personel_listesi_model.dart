class PersonelListesiModel {
  final String sicilNo;
  final String adSoyad;
  final String postaAdi;
  final String tip;
  final String telefon;
  final DateTime? iseGirisTarihi;
  final DateTime? istenCikisTarihi;
  final bool puantajaTabi;
  final bool mesaiAlir;

  const PersonelListesiModel({
    required this.sicilNo,
    required this.adSoyad,
    required this.postaAdi,
    required this.tip,
    required this.telefon,
    required this.iseGirisTarihi,
    required this.istenCikisTarihi,
    required this.puantajaTabi,
    required this.mesaiAlir,
  });

  factory PersonelListesiModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return PersonelListesiModel(
      sicilNo: _toString(
        json['sicilNo'] ??
            json['SicilNo'] ??
            json['SICILNO'],
      ),

      adSoyad: _toString(
        json['adSoyad'] ??
            json['AdSoyad'] ??
            json['adsoyad'],
      ),

      postaAdi: _toString(
        json['postaAdi'] ??
            json['PostaAdi'] ??
            json['postaadi'],
      ),

      tip: _toString(
        json['tip'] ??
            json['Tip'],
      ),

      telefon: _toString(
        json['telefon'] ??
            json['Telefon'],
      ),

      iseGirisTarihi: _toDateTime(
        json['iseGirisTarihi'] ??
            json['IseGirisTarihi'],
      ),

      istenCikisTarihi: _toDateTime(
        json['istenCikisTarihi'] ??
            json['IstenCikisTarihi'],
      ),

      puantajaTabi: _toBool(
        json['puantajaTabi'] ??
            json['PuantajaTabi'],
      ),

      mesaiAlir: _toBool(
        json['mesaiAlir'] ??
            json['MesaiAlir'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sicilNo': sicilNo,
      'adSoyad': adSoyad,
      'postaAdi': postaAdi,
      'tip': tip,
      'telefon': telefon,
      'iseGirisTarihi':
          iseGirisTarihi?.toIso8601String(),
      'istenCikisTarihi':
          istenCikisTarihi?.toIso8601String(),
      'puantajaTabi': puantajaTabi,
      'mesaiAlir': mesaiAlir,
    };
  }
}

String _toString(dynamic value) {
  if (value == null) return '';

  return value.toString().trim();
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();

  if (text.isEmpty) return null;

  return DateTime.tryParse(text);
}

bool _toBool(dynamic value) {
  if (value == null) return false;

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final text =
      value.toString().trim().toLowerCase();

  return text == '1' ||
      text == 'true' ||
      text == 'evet' ||
      text == 'yes';
}