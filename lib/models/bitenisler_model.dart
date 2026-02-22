class Bitenisler {
  final String personeladi;
  final String tip;
  final String tunel;
  final String koridor;
  final String yapilanis;
  final String bitiszamani;

  const Bitenisler({
    required this.personeladi,
    required this.tip,
    required this.tunel,
    required this.koridor,
    required this.yapilanis,
    required this.bitiszamani,
  });

  factory Bitenisler.fromJson(Map<String, dynamic> json) {
    String _s(dynamic v) => (v ?? '').toString();

    return Bitenisler(
      personeladi: _s(json['Ad Soyad']),
      tip: _s(json['tip']),
      tunel: _s(json['tunel']),
      koridor: _s(json['koridor']),
      yapilanis: _s(json['Yapılan İş']),
      bitiszamani: _s(json['Bitis Zamanı']),
    );
  }

  Map<String, dynamic> toJson() => {
        'Ad Soyad': personeladi,
        'tip': tip,
        'tunel': tunel,
        'koridor': koridor,
        'Yapılan İş': yapilanis,
        'Bitis Zamanı': bitiszamani,
      };
}
