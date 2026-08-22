class SeraKontrolRaporModel {
  final bool success;
  final String bolum;
  final String ilkTarih;
  final String sonTarih;
  final int kayitSayisi;
  final List<SeraKontrolKolonModel> columns;
  final List<Map<String, dynamic>> rows;

  const SeraKontrolRaporModel({
    required this.success,
    required this.bolum,
    required this.ilkTarih,
    required this.sonTarih,
    required this.kayitSayisi,
    required this.columns,
    required this.rows,
  });

  factory SeraKontrolRaporModel.fromJson(Map<String, dynamic> json) {
    return SeraKontrolRaporModel(
      success: _toBool(json['success']),
      bolum: _toString(json['bolum']),
      ilkTarih: _toString(json['ilkTarih']),
      sonTarih: _toString(json['sonTarih']),
      kayitSayisi: _toInt(json['kayitSayisi']),
      columns: (json['columns'] as List? ?? [])
          .whereType<Map>()
          .map(
            (e) => SeraKontrolKolonModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      rows: (json['rows'] as List? ?? [])
          .whereType<Map>()
          .map(
            (e) => Map<String, dynamic>.from(e),
          )
          .toList(),
    );
  }
}

class SeraKontrolKolonModel {
  final String name;
  final String type;
  final bool numeric;

  const SeraKontrolKolonModel({
    required this.name,
    required this.type,
    required this.numeric,
  });

  factory SeraKontrolKolonModel.fromJson(Map<String, dynamic> json) {
    return SeraKontrolKolonModel(
      name: _toString(json['name']),
      type: _toString(json['type']),
      numeric: _toBool(json['numeric']),
    );
  }

  bool get integer => type == 'integer';

  bool get number => type == 'number';

  bool get date => type == 'date';

  bool get boolean => type == 'boolean';

  bool get string => type == 'string';

  /// SUM / AVG / MIN / MAX yapılabilir mi?
  bool get hesaplanabilir => numeric;
}


// ============================================================
// HELPERS
// ============================================================

String _toString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

int _toInt(dynamic value) {
  if (value == null) return 0;

  if (value is int) return value;

  if (value is num) return value.toInt();

  return int.tryParse(value.toString()) ?? 0;
}

bool _toBool(dynamic value) {
  if (value == null) return false;

  if (value is bool) return value;

  if (value is num) return value != 0;

  final s = value.toString().toLowerCase().trim();

  return s == 'true' ||
      s == '1' ||
      s == 'yes' ||
      s == 'evet';
}

class SeraKontrolBolumModel {
  final String kod;
  final String isim;

  const SeraKontrolBolumModel({
    required this.kod,
    required this.isim,
  });

  factory SeraKontrolBolumModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SeraKontrolBolumModel(
      kod: json['kod']?.toString() ?? '',
      isim: json['isim']?.toString() ?? '',
    );
  }

  String get baslik {
    if (isim.trim().isEmpty) {
      return kod;
    }

    return '$kod-$isim';
  }

  @override
  String toString() => baslik;
}