class PaletlemeRaporModel {
  final DateTime? olusmaZamani;
  final String? urunKodu;
  final String? urunAdi;
  final String? paletKodu;
  final double? paletBosAgirligi;
  final int? kutuSayisi;
  final double? netKg;
  final double? brutKg;
  final double? paletOrtalamasi;
  final String? musteri;

  PaletlemeRaporModel({
    required this.olusmaZamani,
    required this.urunKodu,
    required this.urunAdi,
    required this.paletKodu,
    required this.paletBosAgirligi,
    required this.kutuSayisi,
    required this.netKg,
    required this.brutKg,
    required this.paletOrtalamasi,
    required this.musteri,
  });

  factory PaletlemeRaporModel.fromJson(Map<String, dynamic> json) {
    double? toDbl(dynamic v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    int? toInt(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));

    return PaletlemeRaporModel(
      olusmaZamani: json["OlusmaZamani"] == null
          ? null
          : DateTime.tryParse(json["OlusmaZamani"].toString()),
      urunKodu: json["UrunKodu"]?.toString(),
      urunAdi: json["UrunAdi"]?.toString(),
      paletKodu: json["PaletKodu"]?.toString(),
      paletBosAgirligi: toDbl(json["PaletBosAgirligi"]),
      kutuSayisi: toInt(json["KutuSayisi"]),
      netKg: toDbl(json["NetKg"]),
      brutKg: toDbl(json["BrutKg"]),
      paletOrtalamasi: toDbl(json["PaletOrtalamasi"]),
      musteri: json["Musteri"]?.toString(),
    );
  }
}