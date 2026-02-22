class SeraIsTanimlari {
  final String? durum;
  final String? isAdi;
  final String? isKodu;
  // ihtiyacın olan alanları ekle

  SeraIsTanimlari({
    this.durum,
    this.isAdi,
    this.isKodu,
  });

  factory SeraIsTanimlari.fromJson(Map<String, dynamic> json) {
    return SeraIsTanimlari(
      durum: json['durum']?.toString(),
      isAdi: json['isadi']?.toString(),
      isKodu: json['iskodu']?.toString(),
    );
  }
}
