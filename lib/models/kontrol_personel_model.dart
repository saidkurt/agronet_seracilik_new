class KontrolPersonelModel {
  final String personelKodu;
  final String personelAdi;
  final int adet;
  final int aktifKontrolDurumu;
  final String grup;

  const KontrolPersonelModel({
    required this.personelKodu,
    required this.personelAdi,
    required this.adet,
    required this.aktifKontrolDurumu,
    required this.grup,
  });

  factory KontrolPersonelModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return KontrolPersonelModel(
      personelKodu:
          (json['PersonelKodu'] ??
                  json['personelKodu'] ??
                  '')
              .toString(),

      personelAdi:
          (json['PersonelAdi'] ??
                  json['personelAdi'] ??
                  '')
              .toString(),

      adet: int.tryParse(
            (json['Adet'] ??
                    json['adet'] ??
                    0)
                .toString(),
          ) ??
          0,

      aktifKontrolDurumu: int.tryParse(
            (json['AktifKontrolDurumu'] ??
                    json['aktifKontrolDurumu'] ??
                    0)
                .toString(),
          ) ??
          0,

      grup:
          (json['Grup'] ??
                  json['grup'] ??
                  '')
              .toString(),
    );
  }
}
