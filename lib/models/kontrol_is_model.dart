class KontrolIsModel {
  final int id;

  // Bağlı asıl iş bilgileri
  final int asilIsId;
  final String asilKoridor;

  final String isAdi;
  final String personel;
  final String tunel;

  // Kontrol işinin tekil sırası: A, B, C...
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
    required this.asilIsId,
    required this.asilKoridor,
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
        (json['Tarih'] ?? json['tarih'] ?? '').toString();

    return KontrolIsModel(
      id: int.tryParse(
            (json['Id'] ?? json['id'] ?? 0).toString(),
          ) ??
          0,

      asilIsId: int.tryParse(
            (json['AsilIsId'] ??
                    json['asilIsId'] ??
                    0)
                .toString(),
          ) ??
          0,

      asilKoridor:
          (json['AsilKoridor'] ??
                  json['asilKoridor'] ??
                  '')
              .toString(),

      isAdi:
          (json['IsAdi'] ?? json['isAdi'] ?? '')
              .toString(),

      personel:
          (json['Personel'] ??
                  json['personel'] ??
                  '')
              .toString(),

      tunel:
          (json['Tunel'] ?? json['tunel'] ?? '')
              .toString(),

      koridor:
          (json['Koridor'] ??
                  json['koridor'] ??
                  '')
              .toString(),

      siraSayisi: int.tryParse(
            (json['SiraSayisi'] ??
                    json['siraSayisi'] ??
                    1)
                .toString(),
          ) ??
          1,

      tarih: tarihText.isEmpty
          ? null
          : DateTime.tryParse(tarihText),

      kontrolDurum: int.tryParse(
            (json['KontrolDurum'] ??
                    json['kontrolDurum'] ??
                    0)
                .toString(),
          ) ??
          0,

      kontrolDurumAdi:
          (json['KontrolDurumAdi'] ??
                  json['kontrolDurumAdi'] ??
                  'Bekliyor')
              .toString(),

      puan: int.tryParse(
            (json['Puan'] ?? json['puan'] ?? 0)
                .toString(),
          ) ??
          0,
    );
  }
}
