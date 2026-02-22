class SeraBarkod {
  final int id;
  final String createdate;
  final int createuser;
  final int yil;
  final int hafta;
  final String personelkodu;
  final String bolumkodu;
  final String tunel;
  final String koridor;
  final String iskodu;
  final int isseviyesi;
  final int isno;
  final String tarih;
  final int durum;
  final bool iptal;
  final double puan;
  final int bagliisemriid;
  final int tekrarsayisi;
  final String tamamlanmazamani;

  const SeraBarkod({
    required this.id,
    required this.createdate,
    required this.createuser,
    required this.yil,
    required this.hafta,
    required this.personelkodu,
    required this.bolumkodu,
    required this.tunel,
    required this.koridor,
    required this.iskodu,
    required this.isseviyesi,
    required this.isno,
    required this.tarih,
    required this.durum,
    required this.iptal,
    required this.puan,
    required this.bagliisemriid,
    required this.tekrarsayisi,
    required this.tamamlanmazamani,
  });

  // ---------- Helperlar ----------
  static String _s(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return '';
    return s;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static bool _b(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v.toString() == '1') return true;
    if (v.toString() == '0') return false;
    return v.toString().toLowerCase() == 'true';
  }

  factory SeraBarkod.fromJson(Map<String, dynamic> json) {
    return SeraBarkod(
      id: _i(json['id']),
      createdate: _s(json['createdate']),
      createuser: _i(json['createuser']),
      yil: _i(json['yil']),
      hafta: _i(json['hafta']),
      personelkodu: _s(json['personelkodu']),
      bolumkodu: _s(json['bolumkodu']),
      tunel: _s(json['tunel']),
      koridor: _s(json['koridor']),
      iskodu: _s(json['iskodu']),
      isseviyesi: _i(json['isseviyesi']),
      isno: _i(json['isno']),
      tarih: _s(json['tarih']),
      durum: _i(json['durum']),
      iptal: _b(json['iptal']),
      puan: _d(json['puan']),
      bagliisemriid: _i(json['bagliisemriid']),
      tekrarsayisi: _i(json['tekrarsayisi']),
      tamamlanmazamani: _s(json['tamamlanmazamani']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdate': createdate,
        'createuser': createuser,
        'yil': yil,
        'hafta': hafta,
        'personelkodu': personelkodu,
        'bolumkodu': bolumkodu,
        'tunel': tunel,
        'koridor': koridor,
        'iskodu': iskodu,
        'isseviyesi': isseviyesi,
        'isno': isno,
        'tarih': tarih,
        'durum': durum,
        'iptal': iptal,
        'puan': puan,
        'bagliisemriid': bagliisemriid,
        'tekrarsayisi': tekrarsayisi,
        'tamamlanmazamani': tamamlanmazamani,
      };
}
