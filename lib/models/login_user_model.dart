class LoginUserModel {
  final String? kullanicikodu;
  final String? sifre;
  final String? prosiskodu;
  final String? bileklikid;
  final int? tipid;

  final String? kullaniciadi;
  final String? tip;

  /// Dinamik mobil menü yetkileri
  ///
  /// Örnek:
  /// [
  ///   "KONTROL",
  ///   "DONGU_KONTROL",
  ///   "PAKETLEME",
  ///   "MOBIL_YETKI"
  /// ]
  final List<String> yetkiler;

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
    this.kullaniciadi,
    this.tip,
    this.yetkiler = const [],
    this.bsrUserId,
    this.erpUserNo,
    this.bsrKullaniciKodu,
    this.oturumId,
    this.token,
  });

  factory LoginUserModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return LoginUserModel(
      kullanicikodu: _toString(
        json['kullanicikodu'] ??
            json['KullaniciKodu'],
      ),

      sifre: _toString(
        json['sifre'] ??
            json['Sifre'],
      ),

      prosiskodu: _toString(
        json['prosiskodu'] ??
            json['ProsisKodu'],
      ),

      bileklikid: _toString(
        json['bileklikid'] ??
            json['BileklikId'],
      ),

      tipid: _toInt(
        json['tipid'] ??
            json['TipId'],
      ),

      kullaniciadi: _toString(
        json['kullaniciadi'] ??
            json['KullaniciAdi'],
      ),

      tip: _toString(
        json['tip'] ??
            json['Tip'],
      ),

      yetkiler: _toStringList(
        json['yetkiler'] ??
            json['Yetkiler'],
      ),

      bsrUserId: _toInt(
        json['bsruserid'] ??
            json['BsrUserId'],
      ),

      erpUserNo: _toInt(
        json['erpuserno'] ??
            json['ErpUserNo'],
      ),

      bsrKullaniciKodu: _toString(
        json['bsKullaniciKodu'] ??
            json['bskullanicikodu'] ??
            json['BsrKullaniciKodu'],
      ),

      oturumId: _toInt(
        json['oturumid'] ??
            json['OturumId'],
      ),

      token: _toString(
        json['token'] ??
            json['Token'],
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

      'kullaniciadi': kullaniciadi,
      'tip': tip,

      'yetkiler': yetkiler,

      'bsruserid': bsrUserId,
      'erpuserno': erpUserNo,
      'bsKullaniciKodu': bsrKullaniciKodu,

      'oturumid': oturumId,
      'token': token,
    };
  }

  // ============================================================
  // YETKİ KONTROL
  // ============================================================

  bool yetkisiVar(String kod) {
    final aranan =
        kod.trim().toUpperCase();

    if (aranan.isEmpty) {
      return false;
    }

    return yetkiler.any(
      (e) =>
          e.trim().toUpperCase() ==
          aranan,
    );
  }

  // ============================================================
  // DEPO KULLANICI KODU
  // ============================================================

  String get depoKullaniciKodu {
    final bsrKod =
        bsrKullaniciKodu?.trim() ?? '';

    if (bsrKod.isNotEmpty) {
      return bsrKod;
    }

    return prosiskodu?.trim() ?? '';
  }

  // ============================================================
  // OTURUM
  // ============================================================

  bool get oturumGecerli {
    return (oturumId ?? 0) > 0 &&
        (token?.trim().isNotEmpty ?? false);
  }
}

// ============================================================
// HELPERS
// ============================================================

String? _toString(dynamic value) {
  if (value == null) return null;

  final text =
      value.toString().trim();

  return text.isEmpty
      ? null
      : text;
}

int? _toInt(dynamic value) {
  if (value == null) return null;

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value.toString().trim(),
  );
}

List<String> _toStringList(
  dynamic value,
) {
  if (value == null) {
    return const [];
  }

  if (value is List) {
    return value
        .where((e) => e != null)
        .map(
          (e) =>
              e.toString().trim(),
        )
        .where(
          (e) => e.isNotEmpty,
        )
        .toList();
  }

  return const [];
}