class PaketlemeRaporModel {
  final int? personelKod;
  final String personel;
  final int? salkimDomates;
  final int? ikinciKalite;
  final int? toplam;

  PaketlemeRaporModel({
    required this.personelKod,
    required this.personel,
    required this.salkimDomates,
    required this.ikinciKalite,
    required this.toplam,
  });

  factory PaketlemeRaporModel.fromJson(Map<String, dynamic> j) {
    int? asInt(dynamic v) => v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    return PaketlemeRaporModel(
      personelKod: asInt(j['PersonelKod']),
      personel: (j['Personel'] ?? '').toString(),
      salkimDomates: asInt(j['SalkimDomates']),
      ikinciKalite: asInt(j['IkinciKalite']),
      toplam: asInt(j['Toplam']),
    );
  }

  bool get isHataliBarkod => personelKod == null && personel.toLowerCase().contains('hatalı');
}