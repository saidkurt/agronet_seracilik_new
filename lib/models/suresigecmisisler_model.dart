class SuresiGecmisler {
  final String personeladi;
  final String bolum;
  final String tunel;
  final String koridor;
  final String iss;
  final String planlanantarih;
  final String durum;

  const SuresiGecmisler({
    required this.personeladi,
    required this.bolum,
    required this.tunel,
    required this.koridor,
    required this.iss,
    required this.planlanantarih,
    required this.durum,
  });

  // ---------- Helper ----------
  static String _s(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return '';
    return s;
  }

  factory SuresiGecmisler.fromJson(Map<String, dynamic> json) {
    return SuresiGecmisler(
      personeladi: _s(json['Personel']),
      bolum: _s(json['Bölüm']),
      tunel: _s(json['Tunel']),
      koridor: _s(json['Koridor']),
      iss: _s(json['İş']),
      planlanantarih: _s(json['Planlanan Tarih']),
      durum: _s(json['Durum']),
    );
  }

  Map<String, dynamic> toJson() => {
        'Personel': personeladi,
        'Bölüm': bolum,
        'Tunel': tunel,
        'Koridor': koridor,
        'İş': iss,
        'Planlanan Tarih': planlanantarih,
        'Durum': durum,
      };
}
