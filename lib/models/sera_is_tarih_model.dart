class DonguHaftaModel {
  final int yil;
  final int hafta;
  final String tarih;

  DonguHaftaModel({
    required this.yil,
    required this.hafta,
    required this.tarih,
  });

  factory DonguHaftaModel.fromJson(Map<String, dynamic> json) {
    return DonguHaftaModel(
      yil: int.tryParse(json['yil']?.toString() ?? '0') ?? 0,
      hafta: int.tryParse(json['hafta']?.toString() ?? '0') ?? 0,
      tarih: json['tarih']?.toString() ?? '',
    );
  }
}


// ============================================================
// BÖLÜM
// ============================================================

class DonguBolumModel {
  final String kod;
  final String isim;

  DonguBolumModel({
    required this.kod,
    required this.isim,
  });

  factory DonguBolumModel.fromJson(Map<String, dynamic> json) {
    return DonguBolumModel(
      kod: json['kod']?.toString() ?? '',
      isim: json['isim']?.toString() ?? '',
    );
  }
}


// ============================================================
// İŞ
// ============================================================

class DonguIsModel {
  final String kod;
  final String isim;
  final int aktifAdet;

  DonguIsModel({
    required this.kod,
    required this.isim,
    required this.aktifAdet,
  });

  factory DonguIsModel.fromJson(Map<String, dynamic> json) {
    return DonguIsModel(
      kod: json['kod']?.toString() ?? '',
      isim: json['isim']?.toString() ?? '',
      aktifAdet:
          int.tryParse(json['aktifAdet']?.toString() ?? '0') ?? 0,
    );
  }
}


// ============================================================
// PERSONEL
// ============================================================

class DonguPersonelModel {
  final String kod;
  final String isim;
  final String grup;

  DonguPersonelModel({
    required this.kod,
    required this.isim,
    required this.grup,
  });

  factory DonguPersonelModel.fromJson(Map<String, dynamic> json) {
    return DonguPersonelModel(
      kod: json['kod']?.toString() ?? '',
      isim: json['isim']?.toString() ?? '',
      grup: json['grup']?.toString() ?? '',
    );
  }
}


// ============================================================
// NORMAL DÖNGÜ LİSTESİ
// ============================================================

class DonguListeModel {
  bool sec;

  final String tunel;
  final String koridor;
  final int isEmriId;
  final String personelAdi;
  final String tarih;
  final double sure;
  final String durum;
  final bool dongusuKacti;

  DonguListeModel({
    required this.sec,
    required this.tunel,
    required this.koridor,
    required this.isEmriId,
    required this.personelAdi,
    required this.tarih,
    required this.sure,
    required this.durum,
    required this.dongusuKacti,
  });

  factory DonguListeModel.fromJson(Map<String, dynamic> json) {
    return DonguListeModel(
      sec: _donguBool(json['Seç']),
      tunel: json['Tünel']?.toString() ?? '',
      koridor: json['Koridor']?.toString() ?? '',

      isEmriId:
          int.tryParse(
            json['İş Emri Id']?.toString() ?? '0',
          ) ??
          0,

      personelAdi:
          json['Personel Adı']?.toString() ?? '',

      tarih:
          json['Tarih']?.toString() ?? '',

      sure:
          double.tryParse(
            json['Süre']
                    ?.toString()
                    .replaceAll(',', '.') ??
                '0',
          ) ??
          0,

      durum:
          json['Durum']?.toString() ?? '',

      dongusuKacti:
          _donguBool(json['Döngüsü Kaçtı']),
    );
  }
}


// ============================================================
// TABLO GÖSTER - HÜCRE
// ============================================================

class DonguTabloHucreModel {
  final String text;
  final String durum;
  final bool dongusuKacti;
  final String renk;

  DonguTabloHucreModel({
    required this.text,
    required this.durum,
    required this.dongusuKacti,
    required this.renk,
  });

  factory DonguTabloHucreModel.fromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return DonguTabloHucreModel.bos();
    }

    return DonguTabloHucreModel(
      text: json['text']?.toString() ?? '-',
      durum: json['durum']?.toString() ?? '',
      dongusuKacti:
          _donguBool(json['dongusuKacti']),
      renk: json['renk']?.toString() ?? 'bos',
    );
  }

  factory DonguTabloHucreModel.bos() {
    return DonguTabloHucreModel(
      text: '-',
      durum: '',
      dongusuKacti: false,
      renk: 'bos',
    );
  }
}


// ============================================================
// TABLO GÖSTER - SATIR
// ============================================================

class DonguTabloModel {
  final String sira;

  // KUZEY
  final DonguTabloHucreModel ka;
  final DonguTabloHucreModel kb;
  final DonguTabloHucreModel kc;
  final DonguTabloHucreModel kd;
  final DonguTabloHucreModel ke;
  final DonguTabloHucreModel kf;

  // GÜNEY
  final DonguTabloHucreModel ga;
  final DonguTabloHucreModel gb;
  final DonguTabloHucreModel gc;
  final DonguTabloHucreModel gd;
  final DonguTabloHucreModel ge;
  final DonguTabloHucreModel gf;

  DonguTabloModel({
    required this.sira,
    required this.ka,
    required this.kb,
    required this.kc,
    required this.kd,
    required this.ke,
    required this.kf,
    required this.ga,
    required this.gb,
    required this.gc,
    required this.gd,
    required this.ge,
    required this.gf,
  });

  factory DonguTabloModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DonguTabloModel(
      sira: json['sira']?.toString() ?? '',

      // KUZEY
      ka: DonguTabloHucreModel.fromJson(
        _mapGetir(json['ka']),
      ),

      kb: DonguTabloHucreModel.fromJson(
        _mapGetir(json['kb']),
      ),

      kc: DonguTabloHucreModel.fromJson(
        _mapGetir(json['kc']),
      ),

      kd: DonguTabloHucreModel.fromJson(
        _mapGetir(json['kd']),
      ),

      ke: DonguTabloHucreModel.fromJson(
        _mapGetir(json['ke']),
      ),

      kf: DonguTabloHucreModel.fromJson(
        _mapGetir(json['kf']),
      ),

      // GÜNEY
      ga: DonguTabloHucreModel.fromJson(
        _mapGetir(json['ga']),
      ),

      gb: DonguTabloHucreModel.fromJson(
        _mapGetir(json['gb']),
      ),

      gc: DonguTabloHucreModel.fromJson(
        _mapGetir(json['gc']),
      ),

      gd: DonguTabloHucreModel.fromJson(
        _mapGetir(json['gd']),
      ),

      ge: DonguTabloHucreModel.fromJson(
        _mapGetir(json['ge']),
      ),

      gf: DonguTabloHucreModel.fromJson(
        _mapGetir(json['gf']),
      ),
    );
  }
}


// ============================================================
// PERSONEL DEĞİŞTİRME İSTEĞİ
// ============================================================

class DonguPersonelDegistirModel {
  final List<int> isEmriIdleri;
  final String yeniPersonelKodu;
  final int kullaniciId;

  DonguPersonelDegistirModel({
    required this.isEmriIdleri,
    required this.yeniPersonelKodu,
    required this.kullaniciId,
  });

  Map<String, dynamic> toJson() {
    return {
      'isEmriIdleri': isEmriIdleri,
      'yeniPersonelKodu': yeniPersonelKodu,
      'kullaniciId': kullaniciId,
    };
  }
}


// ============================================================
// PERSONEL DEĞİŞTİRME CEVABI
// ============================================================

class DonguPersonelDegistirSonucModel {
  final bool basarili;
  final String mesaj;
  final int degisen;
  final int tamamlanmis;
  final int bulunamadi;
  final String yeniPersonelKodu;
  final List<DonguYeniKayitModel> kayitlar;

  DonguPersonelDegistirSonucModel({
    required this.basarili,
    required this.mesaj,
    required this.degisen,
    required this.tamamlanmis,
    required this.bulunamadi,
    required this.yeniPersonelKodu,
    required this.kayitlar,
  });

  factory DonguPersonelDegistirSonucModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final kayitListesi =
        json['kayitlar'] as List<dynamic>? ?? [];

    return DonguPersonelDegistirSonucModel(
      basarili:
          _donguBool(json['basarili']),

      mesaj:
          json['mesaj']?.toString() ?? '',

      degisen:
          int.tryParse(
            json['degisen']?.toString() ?? '0',
          ) ??
          0,

      tamamlanmis:
          int.tryParse(
            json['tamamlanmis']?.toString() ?? '0',
          ) ??
          0,

      bulunamadi:
          int.tryParse(
            json['bulunamadi']?.toString() ?? '0',
          ) ??
          0,

      yeniPersonelKodu:
          json['yeniPersonelKodu']?.toString() ?? '',

      kayitlar: kayitListesi
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => DonguYeniKayitModel.fromJson(e),
          )
          .toList(),
    );
  }
}


// ============================================================
// PERSONEL DEĞİŞTİRMEDE OLUŞAN YENİ KAYIT
// ============================================================

class DonguYeniKayitModel {
  final int eskiId;
  final int yeniId;

  DonguYeniKayitModel({
    required this.eskiId,
    required this.yeniId,
  });

  factory DonguYeniKayitModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DonguYeniKayitModel(
      eskiId:
          int.tryParse(
            json['eskiId']?.toString() ?? '0',
          ) ??
          0,

      yeniId:
          int.tryParse(
            json['yeniId']?.toString() ?? '0',
          ) ??
          0,
    );
  }
}


// ============================================================
// YARDIMCI METOTLAR
// ============================================================

bool _donguBool(dynamic value) {
  if (value == null) {
    return false;
  }

  if (value is bool) {
    return value;
  }

  if (value is int) {
    return value == 1;
  }

  final String text =
      value.toString().trim().toLowerCase();

  return text == 'true' ||
      text == '1' ||
      text == 'evet';
}


Map<String, dynamic>? _mapGetir(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return null;
}