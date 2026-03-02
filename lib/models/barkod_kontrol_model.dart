class KoliBarkodModel {
  final DateTime? tartimZamani;
  final String? personel;
  final String? bolum;
  final String? tunel;

  const KoliBarkodModel({
    this.tartimZamani,
    this.personel,
    this.bolum,
    this.tunel,
  });

  factory KoliBarkodModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return KoliBarkodModel(
      tartimZamani: parseDt(json['TartimZamani']),
      personel: json['Personel']?.toString(),
      bolum: json['Bolum']?.toString(),
      tunel: json['Tunel']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'TartimZamani': tartimZamani?.toIso8601String(),
        'Personel': personel,
        'Bolum': bolum,
        'Tunel': tunel,
      };
}