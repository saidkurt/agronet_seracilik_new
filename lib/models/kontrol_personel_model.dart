class KontrolPersonelModel {
  final String personelKodu;
  final String personelAdi;
  final int adet;
  final String grup;

  const KontrolPersonelModel({
    required this.personelKodu,
    required this.personelAdi,
    required this.adet,
    required this.grup,
  });

  factory KontrolPersonelModel.fromJson(Map<String, dynamic> json) {
    return KontrolPersonelModel(
      personelKodu: (json['PersonelKodu'] ?? '').toString(),
      personelAdi: (json['PersonelAdi'] ?? '').toString(),
      adet: int.tryParse((json['Adet'] ?? 0).toString()) ?? 0,
      grup: (json['Grup'] ?? '').toString(),
    );
  }
}