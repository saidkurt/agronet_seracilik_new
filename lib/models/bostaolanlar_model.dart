class BostaOlanlar {
  final String personeladi;
  final String bolum;

  const BostaOlanlar({
    required this.personeladi,
    required this.bolum,
  });

  factory BostaOlanlar.fromJson(Map<String, dynamic> json) {
    String _s(dynamic v) => (v ?? '').toString();

    return BostaOlanlar(
      personeladi: _s(json['Personel Adı']),
      bolum: _s(json['Bölüm']),
    );
  }

  Map<String, dynamic> toJson() => {
        'Personel Adı': personeladi,
        'Bölüm': bolum,
      };
}
