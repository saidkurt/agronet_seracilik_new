class GunlukPalet {
  final String olusmaZamani;
  final String paletKodu;
  final String paletBosAgirlik;
  final String toplamKutuSayisi;
  final String toplamNetKg;
  final String toplamBrutKg;

  const GunlukPalet({
    required this.olusmaZamani,
    required this.paletKodu,
    required this.paletBosAgirlik,
    required this.toplamKutuSayisi,
    required this.toplamNetKg,
    required this.toplamBrutKg,
  });

  factory GunlukPalet.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();

    return GunlukPalet(
      olusmaZamani: s(json['Olusma Zamani']),
      paletKodu: s(json['paletkodu']),
      paletBosAgirlik: s(json['paletbosagirlik']),
      toplamKutuSayisi: s(json['toplamkutusayisi']),
      toplamNetKg: s(json['toplamnetkg']),
      toplamBrutKg: s(json['toplambrutkg']),
    );
  }

  Map<String, dynamic> toJson() => {
        'Olusma Zamani': olusmaZamani,
        'paletkodu': paletKodu,
        'paletbosagirlik': paletBosAgirlik,
        'toplamkutusayisi': toplamKutuSayisi,
        'toplamnetkg': toplamNetKg,
        'toplambrutkg': toplamBrutKg,
      };
}
