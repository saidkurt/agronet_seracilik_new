class SeraIsTarihModel {
  final bool? sec; // "Seç"
  final String? tunel; // "Tünel"
  final String? koridor; // "Koridor"
  final String? tarih; // "Tarih" (örn: 12/01/2026)
  final String? personelKodu; // "Personel Kodu"
  final String? personelAdi; // "Personel Adı"
  final String? durum; // "Durum"
  final int? isEmriId; // "İş Emri Id"
  final int? sonIsEmriId; // "Son İş Emri Id"
  final int? sure; // "Süre"
  final bool? dongusuKacti; // "Döngüsü Kaçtı"

  const SeraIsTarihModel({
    this.sec,
    this.tunel,
    this.koridor,
    this.tarih,
    this.personelKodu,
    this.personelAdi,
    this.durum,
    this.isEmriId,
    this.sonIsEmriId,
    this.sure,
    this.dongusuKacti,
  });

  /// Güvenli parse (int/bool/string karışık gelirse de toparlar)
  factory SeraIsTarihModel.fromJson(Map<String, dynamic> json) {
    return SeraIsTarihModel(
      sec: _asBool(json['Seç']),
      tunel: json['Tünel']?.toString(),
      koridor: json['Koridor']?.toString(),
      tarih: json['Tarih']?.toString(),
      personelKodu: json['Personel Kodu']?.toString(),
      personelAdi: json['Personel Adı']?.toString(),
      durum: json['Durum']?.toString(),
      isEmriId: _asInt(json['İş Emri Id']),
      sonIsEmriId: _asInt(json['Son İş Emri Id']),
      sure: _asInt(json['Süre']),
      dongusuKacti: _asBool(json['Döngüsü Kaçtı']),
    );
  }

  Map<String, dynamic> toJson() => {
        'Seç': sec,
        'Tünel': tunel,
        'Koridor': koridor,
        'Tarih': tarih,
        'Personel Kodu': personelKodu,
        'Personel Adı': personelAdi,
        'Durum': durum,
        'İş Emri Id': isEmriId,
        'Son İş Emri Id': sonIsEmriId,
        'Süre': sure,
        'Döngüsü Kaçtı': dongusuKacti,
      };

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    final s = v.toString().trim();
    return int.tryParse(s);
  }

  static bool? _asBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'evet') return true;
    if (s == 'false' || s == '0' || s == 'hayır' || s == 'hayir') return false;
    return null;
  }
}
