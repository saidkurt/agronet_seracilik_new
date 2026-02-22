class LoginUserModel {
  final String? kullanicikodu;
  final String? sifre;
  final String? prosiskodu;
  final String? bileklikid;

  final bool seraraporlarigorebilir;
  final bool kontrolcuraporlarigorebilir;
  final bool yonetimraporlarigorebilir;
  final bool deporaporlarinigorebilir;
  final bool danismanraporlari;
  final bool depopaketleme;

  final String? kullaniciadi;
  final String? tip;

  const LoginUserModel({
    required this.kullanicikodu,
    required this.sifre,
    required this.prosiskodu,
    required this.bileklikid,
    required this.seraraporlarigorebilir,
    required this.kontrolcuraporlarigorebilir,
    required this.yonetimraporlarigorebilir,
    required this.deporaporlarinigorebilir,
    required this.danismanraporlari,
    required this.depopaketleme,
    required this.kullaniciadi,
    required this.tip,
  });

  static bool _b(dynamic v) {
    // SQL’den bazen 0/1, bazen true/false, bazen "0"/"1" gelebiliyor
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    return s == "1" || s == "true" || s == "evet" || s == "yes";
  }

  factory LoginUserModel.fromJson(Map<String, dynamic> json) {
    return LoginUserModel(
      kullanicikodu: json["kullanicikodu"]?.toString(),
      sifre: json["sifre"]?.toString(),
      prosiskodu: json["prosiskodu"]?.toString(),
      bileklikid: json["bileklikid"]?.toString(),

      seraraporlarigorebilir: _b(json["seraraporlarigorebilir"]),
      kontrolcuraporlarigorebilir: _b(json["kontrolcuraporlarigorebilir"]),
      yonetimraporlarigorebilir: _b(json["yonetimraporlarigorebilir"]),
      deporaporlarinigorebilir: _b(json["deporaporlarinigorebilir"]),
      danismanraporlari: _b(json["danismanraporlari"]),
      depopaketleme: _b(json["depopaketleme"]),

      kullaniciadi: json["kullaniciadi"]?.toString(),
      tip: json["tip"]?.toString(),
    );
  }
}