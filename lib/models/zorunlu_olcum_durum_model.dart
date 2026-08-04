class ZorunluOlcumDurumModel {
  final bool tamamlandi;
  final String? bitkiUzamasi;
  final String? tepeKalinligi;
  final String? sera;
  final String? bitkiKodu;

  const ZorunluOlcumDurumModel({
    required this.tamamlandi,
    this.bitkiUzamasi,
    this.tepeKalinligi,
    this.sera,
    this.bitkiKodu,
  });

  factory ZorunluOlcumDurumModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ZorunluOlcumDurumModel(
      tamamlandi: json['tamamlandi'] == true,
      bitkiUzamasi: json['bitkiUzamasi']?.toString(),
      tepeKalinligi: json['tepeKalinligi']?.toString(),
      sera: json['sera']?.toString(),
      bitkiKodu: json['bitkiKodu']?.toString(),
    );
  }
}

class OlcumDegerModel {
  final bool bulundu;
  final String? deger;

  const OlcumDegerModel({
    required this.bulundu,
    this.deger,
  });

  factory OlcumDegerModel.fromJson(Map<String, dynamic> json) {
    return OlcumDegerModel(
      bulundu: json['bulundu'] == true,
      deger: json['deger']?.toString(),
    );
  }
}