class PersonelAnlikDurum {
  final String personeladi;
  final String personeltipi;
  final String tunel;
  final String koridor;
  final String yapilanis;
  final String sonbaslangicsaati;
  final String aktifsure;

  const PersonelAnlikDurum({
    required this.personeladi,
    required this.personeltipi,
    required this.tunel,
    required this.koridor,
    required this.yapilanis,
    required this.sonbaslangicsaati,
    required this.aktifsure,
  });

  static String _s(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim();
    if (s.isEmpty) return '';
    if (s.toLowerCase() == 'null') return '';
    return s;
  }

  factory PersonelAnlikDurum.fromJson(Map<String, dynamic> json) {
    return PersonelAnlikDurum(
      personeladi: _s(json['Personel Adı']),
      personeltipi: _s(json['Personel Tipi']),
      tunel: _s(json['Tünel']),
      koridor: _s(json['Koridor']),
      yapilanis: _s(json['Yapılan İş']),
      sonbaslangicsaati: _s(json['Son Başlangıç Saati']),
      aktifsure: _s(json['Aktif Süre']),
    );
  }

  Map<String, dynamic> toJson() => {
        'Personel Adı': personeladi,
        'Personel Tipi': personeltipi,
        'Tünel': tunel,
        'Koridor': koridor,
        'Yapılan İş': yapilanis,
        'Son Başlangıç Saati': sonbaslangicsaati,
        'Aktif Süre': aktifsure,
      };
}
