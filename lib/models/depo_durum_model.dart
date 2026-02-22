class DepoDurumModel {
  final String? stokKodu;
  final String? stokAdi;
  final double? miktar;
  final String? birim;

  DepoDurumModel({this.stokKodu, this.stokAdi, this.miktar, this.birim});

  factory DepoDurumModel.fromJson(Map<String, dynamic> json) {
    return DepoDurumModel(
      stokKodu: json["Stok Kodu"]?.toString(),
      stokAdi: json["Stok Adı"]?.toString(),
      miktar: (json["Miktar"] is num)
          ? (json["Miktar"] as num).toDouble()
          : double.tryParse(json["Miktar"]?.toString() ?? ""),
      birim: json["Birim"]?.toString(),
    );
  }
}