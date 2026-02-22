class Job {
  final String id;
  final String tarih;
  final String adsoyad;
  final String mesaj;
  final String durum;
  final String kime;
  final String cevap;

  const Job({
    required this.id,
    required this.tarih,
    required this.adsoyad,
    required this.mesaj,
    required this.durum,
    required this.kime,
    required this.cevap,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();

    return Job(
      id: s(json['id']),
      tarih: s(json['Tarih']),
      adsoyad: s(json['Ad Soyad']),
      mesaj: s(json['Mesaj']),
      durum: s(json['Durum']),
      kime: s(json['Kime']),
      cevap: s(json['Cevap']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'Tarih': tarih,
        'Ad Soyad': adsoyad,
        'Mesaj': mesaj,
        'Durum': durum,
        'Kime': kime,
        'Cevap': cevap,
      };
}
