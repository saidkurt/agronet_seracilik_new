class MobilYetkiModel {
  final int personeltipid;
  final String tip;

  final int menuid;
  final String kod;
  final String baslik;
  final String grup;
  final int sira;

  bool yetkili;

  MobilYetkiModel({
    required this.personeltipid,
    required this.tip,
    required this.menuid,
    required this.kod,
    required this.baslik,
    required this.grup,
    required this.sira,
    this.yetkili = false,
  });

  factory MobilYetkiModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return MobilYetkiModel(
      personeltipid: _toInt(
        json['personeltipid'] ??
            json['PersonelTipId'],
      ),

      tip: _toString(
        json['tip'] ??
            json['Tip'],
      ),

      menuid: _toInt(
        json['menuid'] ??
            json['MenuId'],
      ),

      kod: _toString(
        json['kod'] ??
            json['Kod'],
      ),

      baslik: _toString(
        json['baslik'] ??
            json['Baslik'],
      ),

      grup: _toString(
        json['grup'] ??
            json['Grup'],
      ),

      sira: _toInt(
        json['sira'] ??
            json['Sira'],
      ),

      yetkili: _toBool(
        json['yetkili'] ??
            json['Yetkili'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personeltipid': personeltipid,
      'menuid': menuid,
      'kod': kod,
      'baslik': baslik,
      'grup': grup,
      'sira': sira,
      'yetkili': yetkili,
    };
  }

  Map<String, dynamic> toKaydetJson() {
    return {
      'menuid': menuid,
      'yetkili': yetkili,
    };
  }
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
        value.toString().trim(),
      ) ??
      0;
}

String _toString(dynamic value) {
  if (value == null) {
    return '';
  }

  return value.toString().trim();
}

bool _toBool(dynamic value) {
  if (value == null) {
    return false;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final text =
      value.toString().trim().toLowerCase();

  return text == '1' ||
      text == 'true' ||
      text == 'evet' ||
      text == 'yes';
}