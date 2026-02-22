class DepoDurumModel {
  final String? stokKodu;
  final String? stokAdi;
  final double? miktar;
  final String? birim;

  DepoDurumModel({this.stokKodu, this.stokAdi, this.miktar, this.birim});

  factory DepoDurumModel.fromJson(Map<String, dynamic> json) {
    return DepoDurumModel(
      stokKodu: json["StokKodu"]?.toString(),
      stokAdi: json["StokAdi"]?.toString(),
      miktar: (json["Miktar"] is num)
          ? (json["Miktar"] as num).toDouble()
          : double.tryParse(json["Miktar"]?.toString() ?? ""),
      birim: json["Birim"]?.toString(),
    );
  }
}