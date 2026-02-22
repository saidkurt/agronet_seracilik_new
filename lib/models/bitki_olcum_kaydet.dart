class BitkiOlcumKaydetModel {
  DateTime? tarih;
  String? sera;
  String? vana;
  int? createuser;
  String? tip;
  String? deger;
  int bildirildi = 0;

  BitkiOlcumKaydetModel();

  Map<String, dynamic> toJson() {
    return {
      "tarih": tarih != null ? _yyyyMmDd(tarih!) : null,
      "sera": sera,
      "vana": vana,
      "createuser": createuser,
      "tip": tip,
      "deger": deger,
      "bildirildi": bildirildi,
    };
  }

  static String _yyyyMmDd(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${d.year}-${two(d.month)}-${two(d.day)}";
  }
}
