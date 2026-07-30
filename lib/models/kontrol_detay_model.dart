class KontrolDetayModel {
  final int kontrolIsId;
  final int asilIsId;

  // Ekranda gösterilecek asıl iş durumu
  final int asilDurum;
  final String asilDurumAdi;

  // Başla / ara ver / devam et / bitir
  // butonlarını yönetecek kontrol iş durumu
  final int kontrolDurum;
  final String kontrolDurumAdi;

  final String personel;
  final String gorev;
  final String tunel;
  final String koridor;

  final DateTime? baslangic;

  // Asıl iş süreleri
  final int aktifSaniye;
  final int molaSaniye;
  final int hedefSaniye;
  final int azamiSaniye;

  // Kontrol işinin süreleri
  final int kontrolCalisilanSaniye;
  final int kontrolAraSaniye;
  final int kontrolToplamSaniye;

  final int tekrarSayisi;
  final double puan;

  final String kontrolPersonelKodu;

  const KontrolDetayModel({
    required this.kontrolIsId,
    required this.asilIsId,
    required this.asilDurum,
    required this.asilDurumAdi,
    required this.kontrolDurum,
    required this.kontrolDurumAdi,
    required this.personel,
    required this.gorev,
    required this.tunel,
    required this.koridor,
    required this.baslangic,
    required this.aktifSaniye,
    required this.molaSaniye,
    required this.hedefSaniye,
    required this.azamiSaniye,
    required this.kontrolCalisilanSaniye,
    required this.kontrolAraSaniye,
    required this.kontrolToplamSaniye,
    required this.tekrarSayisi,
    required this.puan,
    required this.kontrolPersonelKodu,
  });

  factory KontrolDetayModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return KontrolDetayModel(
      kontrolIsId: _toInt(
        json['KontrolIsId'],
      ),

      asilIsId: _toInt(
        json['AsilIsId'],
      ),

      asilDurum: _toInt(
        json['AsilDurum'],
      ),

      asilDurumAdi:
          json['AsilDurumAdi']?.toString() ?? '',

      kontrolDurum: _toInt(
        json['KontrolDurum'],
      ),

      kontrolDurumAdi:
          json['KontrolDurumAdi']?.toString() ?? '',

      personel:
          json['Personel']?.toString() ?? '',

      gorev:
          json['Gorev']?.toString() ?? '',

      tunel:
          json['Tunel']?.toString() ?? '',

      koridor:
          json['Koridor']?.toString() ?? '',

      baslangic: _toDateTime(
        json['Baslangic'],
      ),

      aktifSaniye: _toInt(
        json['AktifSaniye'],
      ),

      molaSaniye: _toInt(
        json['MolaSaniye'],
      ),

      hedefSaniye: _toInt(
        json['HedefSaniye'],
      ),

      azamiSaniye: _toInt(
        json['AzamiSaniye'],
      ),

      kontrolCalisilanSaniye: _toInt(
        json['KontrolCalisilanSaniye'],
      ),

      kontrolAraSaniye: _toInt(
        json['KontrolAraSaniye'],
      ),

      kontrolToplamSaniye: _toInt(
        json['KontrolToplamSaniye'],
      ),

      tekrarSayisi: _toInt(
        json['TekrarSayisi'],
      ),

      puan: _toDouble(
        json['Puan'],
      ),

      kontrolPersonelKodu:
          json['KontrolPersonelKodu']
                  ?.toString() ??
              '',
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value == null) return null;

    return DateTime.tryParse(
      value.toString(),
    );
  }
}