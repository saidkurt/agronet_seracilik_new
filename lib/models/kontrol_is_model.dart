class KontrolIsModel {
  final int id;
  final String isAdi;
  final String personel;
  final String tunel;
  final String koridor;
  final int siraSayisi;
  final DateTime? tarih;

  // Kontrol işinin durumu
  final int kontrolDurum;
  final String kontrolDurumAdi;

  // Bağlı asıl işin puanı
  final int puan;

  const KontrolIsModel({
    required this.id,
    required this.isAdi,
    required this.personel,
    required this.tunel,
    required this.koridor,
    required this.siraSayisi,
    required this.tarih,
    required this.kontrolDurum,
    required this.kontrolDurumAdi,
    required this.puan,
  });

  factory KontrolIsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final tarihText =
        (json['Tarih'] ?? '').toString();

    return KontrolIsModel(
      id: int.tryParse(
            (json['Id'] ?? 0).toString(),
          ) ??
          0,

      isAdi:
          (json['IsAdi'] ?? '').toString(),

      personel:
          (json['Personel'] ?? '').toString(),

      tunel:
          (json['Tunel'] ?? '').toString(),

      koridor:
          (json['Koridor'] ?? '').toString(),

      siraSayisi: int.tryParse(
            (json['SiraSayisi'] ?? 1).toString(),
          ) ??
          1,

      tarih: tarihText.isEmpty
          ? null
          : DateTime.tryParse(tarihText),

      kontrolDurum: int.tryParse(
            (json['KontrolDurum'] ?? 0)
                .toString(),
          ) ??
          0,

      kontrolDurumAdi:
          (json['KontrolDurumAdi'] ??
                  'Bekliyor')
              .toString(),

      puan: int.tryParse(
            (json['Puan'] ?? 0).toString(),
          ) ??
          0,
    );
  }
}