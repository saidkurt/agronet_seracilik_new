class LoginUserModel {
  final String? kullanicikodu;
  final String? sifre;
  final String? prosiskodu;
  final String? bileklikid;
  final int? tipid;

  final bool seraraporlarigorebilir;
  final bool kontrolcuraporlarigorebilir;
  final bool yonetimraporlarigorebilir;
  final bool deporaporlarinigorebilir;
  final bool danismanraporlari;
  final bool depopaketleme;

  final String? kullaniciadi;
  final String? tip;

  /// MikroDesktop.dbo.BSR_KULLANICILAR.id
  final int? bsrUserId;

  /// Mikro hareketlerinde kullanılan ERP kullanıcı numarası
  final int? erpUserNo;

  /// MikroDesktop.dbo.BSR_KULLANICILAR.kod
  /// Depo backend'ine KullaniciKodu olarak gönderilecek.
  final String? bsrKullaniciKodu;

  /// Mobil girişte oluşturulan BSR_OTURUM.id
  final int? oturumId;

  /// Mobil girişte oluşturulan BSR_OTURUM.token
  final String? token;

  const LoginUserModel({
    this.kullanicikodu,
    this.sifre,
    this.prosiskodu,
    this.bileklikid,
    this.tipid,
    this.seraraporlarigorebilir = false,
    this.kontrolcuraporlarigorebilir = false,
    this.yonetimraporlarigorebilir = false,
    this.deporaporlarinigorebilir = false,
    this.danismanraporlari = false,
    this.depopaketleme = false,
    this.kullaniciadi,
    this.tip,
    this.bsrUserId,
    this.erpUserNo,
    this.bsrKullaniciKodu,
    this.oturumId,
    this.token,
  });

  factory LoginUserModel.fromJson(Map<String, dynamic> json) {
    return LoginUserModel(
      kullanicikodu: _toString(
        json['kullanicikodu'] ?? json['KullaniciKodu'],
      ),
      sifre: _toString(
        json['sifre'] ?? json['Sifre'],
      ),
      prosiskodu: _toString(
        json['prosiskodu'] ?? json['ProsisKodu'],
      ),
      bileklikid: _toString(
        json['bileklikid'] ?? json['BileklikId'],
      ),
      tipid: _toInt(
        json['tipid'] ?? json['TipId'],
      ),

      seraraporlarigorebilir: _toBool(
        json['seraraporlarigorebilir'] ??
            json['SeraRaporlariGorebilir'],
      ),
      kontrolcuraporlarigorebilir: _toBool(
        json['kontrolcuraporlarigorebilir'] ??
            json['KontrolcuRaporlariGorebilir'],
      ),
      yonetimraporlarigorebilir: _toBool(
        json['yonetimraporlarigorebilir'] ??
            json['YonetimRaporlariGorebilir'],
      ),
      deporaporlarinigorebilir: _toBool(
        json['deporaporlarinigorebilir'] ??
            json['DepoRaporlariniGorebilir'],
      ),
      danismanraporlari: _toBool(
        json['danismanraporlari'] ??
            json['DanismanRaporlari'],
      ),
      depopaketleme: _toBool(
        json['depopaketleme'] ??
            json['DepoPaketleme'],
      ),

      kullaniciadi: _toString(
        json['kullaniciadi'] ?? json['KullaniciAdi'],
      ),
      tip: _toString(
        json['tip'] ?? json['Tip'],
      ),

      bsrUserId: _toInt(
        json['bsruserid'] ?? json['BsrUserId'],
      ),
      erpUserNo: _toInt(
        json['erpuserno'] ?? json['ErpUserNo'],
      ),
      bsrKullaniciKodu: _toString(
        json['bsKullaniciKodu'] ??
            json['bskullanicikodu'] ??
            json['BsrKullaniciKodu'],
      ),
      oturumId: _toInt(
        json['oturumid'] ?? json['OturumId'],
      ),
      token: _toString(
        json['token'] ?? json['Token'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kullanicikodu': kullanicikodu,
      'sifre': sifre,
      'prosiskodu': prosiskodu,
      'bileklikid': bileklikid,
      'tipid': tipid,
      'seraraporlarigorebilir': seraraporlarigorebilir,
      'kontrolcuraporlarigorebilir':
          kontrolcuraporlarigorebilir,
      'yonetimraporlarigorebilir':
          yonetimraporlarigorebilir,
      'deporaporlarinigorebilir':
          deporaporlarinigorebilir,
      'danismanraporlari': danismanraporlari,
      'depopaketleme': depopaketleme,
      'kullaniciadi': kullaniciadi,
      'tip': tip,
      'bsruserid': bsrUserId,
      'erpuserno': erpUserNo,
      'bsKullaniciKodu': bsrKullaniciKodu,
      'oturumid': oturumId,
      'token': token,
    };
  }

  /// Depo işlemlerinde kullanılacak gerçek Mikro kullanıcı kodu.
  String get depoKullaniciKodu {
    final bsrKod = bsrKullaniciKodu?.trim() ?? '';

    if (bsrKod.isNotEmpty) {
      return bsrKod;
    }

    return prosiskodu?.trim() ?? '';
  }

  bool get oturumGecerli {
    return (oturumId ?? 0) > 0 &&
        (token?.trim().isNotEmpty ?? false);
  }
}

String? _toString(dynamic value) {
  if (value == null) return null;

  final text = value.toString();

  return text.isEmpty ? null : text;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString().trim());
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value.toString().trim().toLowerCase();

  return text == '1' ||
      text == 'true' ||
      text == 'evet' ||
      text == 'yes';
}