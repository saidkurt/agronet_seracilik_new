import 'dart:convert';
import 'dart:typed_data';

class OperasyonOzet {
  final String personelKodu;
  final String personelAdi;
  final String dil;
  final int bekleyen;
  final int aktif;
  final int araVerilen;
  final int tekrar;

  const OperasyonOzet({
    required this.personelKodu,
    required this.personelAdi,
    required this.dil,
    required this.bekleyen,
    required this.aktif,
    required this.araVerilen,
    required this.tekrar,
  });

  factory OperasyonOzet.fromJson(Map<String, dynamic> json) {
    return OperasyonOzet(
      personelKodu: _string(json, 'PersonelKodu'),
      personelAdi: _string(json, 'PersonelAdi'),
      dil: _string(json, 'Dil'),
      bekleyen: _int(json, 'Bekleyen'),
      aktif: _int(json, 'Aktif'),
      araVerilen: _int(json, 'AraVerilen'),
      tekrar: _int(json, 'Tekrar'),
    );
  }
}

class BekleyenGruplar {
  final int oncelikli;
  final int haftalik;

  const BekleyenGruplar({
    required this.oncelikli,
    required this.haftalik,
  });

  factory BekleyenGruplar.fromJson(Map<String, dynamic> json) {
    return BekleyenGruplar(
      oncelikli: _int(json, 'Oncelikli'),
      haftalik: _int(json, 'Haftalik'),
    );
  }
}

class OperasyonSecim {
  final String kod;
  final String isim;
  final int adet;
  final int isSeviyesi;
  final Uint8List? resim;

  const OperasyonSecim({
    required this.kod,
    required this.isim,
    required this.adet,
    required this.isSeviyesi,
    this.resim,
  });

  factory OperasyonSecim.fromJson(Map<String, dynamic> json) {
    return OperasyonSecim(
      kod: _string(json, 'Kod'),
      isim: _string(json, 'Isim'),
      adet: _int(json, 'Adet'),
      isSeviyesi: _int(json, 'IsSeviyesi'),
      resim: _bytes(json, 'Resim'),
    );
  }
}

class OperasyonTunel {
  final String tunel;
  final String yon;
  final int adet;
  final DateTime? sonYapilmaTarihi;

  const OperasyonTunel({
    required this.tunel,
    required this.yon,
    required this.adet,
    this.sonYapilmaTarihi,
  });

  factory OperasyonTunel.fromJson(Map<String, dynamic> json) {
    return OperasyonTunel(
      tunel: _string(json, 'Tunel'),
      yon: _string(json, 'Yon'),
      adet: _int(json, 'Adet'),
      sonYapilmaTarihi: _date(json, 'SonYapilmaTarihi'),
    );
  }
}

class OperasyonKoridor {
  final int isEmriId;
  final String tunel;
  final String koridor;
  final DateTime? sonYapilmaTarihi;

  const OperasyonKoridor({
    required this.isEmriId,
    required this.tunel,
    required this.koridor,
    this.sonYapilmaTarihi,
  });

  factory OperasyonKoridor.fromJson(Map<String, dynamic> json) {
    return OperasyonKoridor(
      isEmriId: _int(json, 'IsEmriId'),
      tunel: _string(json, 'Tunel'),
      koridor: _string(json, 'Koridor'),
      sonYapilmaTarihi: _date(json, 'SonYapilmaTarihi'),
    );
  }
}

class OperasyonIs {
  final int isEmriId;
  final String isKodu;
  final String isAdi;
  final Uint8List? resim;
  final String bolumKodu;
  final String tunel;
  final String koridor;
  final int durum;
  final String durumAdi;

  const OperasyonIs({
    required this.isEmriId,
    required this.isKodu,
    required this.isAdi,
    this.resim,
    required this.bolumKodu,
    required this.tunel,
    required this.koridor,
    required this.durum,
    required this.durumAdi,
  });

  factory OperasyonIs.fromJson(Map<String, dynamic> json) {
    return OperasyonIs(
      isEmriId: _int(json, 'IsEmriId'),
      isKodu: _string(json, 'IsKodu'),
      isAdi: _string(json, 'IsAdi'),
      resim: _bytes(json, 'Resim'),
      bolumKodu: _string(json, 'BolumKodu'),
      tunel: _string(json, 'Tunel'),
      koridor: _string(json, 'Koridor'),
      durum: _int(json, 'Durum'),
      durumAdi: _string(json, 'DurumAdi'),
    );
  }
}

class OperasyonDetay {
  final int isEmriId;
  final String personelKodu;
  final String personelAdi;
  final String dil;
  final String isKodu;
  final String isAdi;
  final Uint8List? resim;
  final String bolumKodu;
  final String tunel;
  final String koridor;
  final int isSeviyesi;
  final DateTime? tarih;
  final int durum;
  final String durumAdi;
  final int aktifSaniye;
  final int araSaniye;
  final int toplamSaniye;
  final int ortalamaSaniye;
  final int azamiSaniye;
  final int minimumSaniye;
  final int maxEtiketAdedi;
  final int eklenenKutuSayisi;
  final bool bitkiSokumu;

  const OperasyonDetay({
    required this.isEmriId,
    required this.personelKodu,
    required this.personelAdi,
    required this.dil,
    required this.isKodu,
    required this.isAdi,
    this.resim,
    required this.bolumKodu,
    required this.tunel,
    required this.koridor,
    required this.isSeviyesi,
    this.tarih,
    required this.durum,
    required this.durumAdi,
    required this.aktifSaniye,
    required this.araSaniye,
    required this.toplamSaniye,
    required this.ortalamaSaniye,
    required this.azamiSaniye,
    required this.minimumSaniye,
    required this.maxEtiketAdedi,
    required this.eklenenKutuSayisi,
    required this.bitkiSokumu,
  });

  factory OperasyonDetay.fromJson(Map<String, dynamic> json) {
    return OperasyonDetay(
      isEmriId: _int(json, 'IsEmriId'),
      personelKodu: _string(json, 'PersonelKodu'),
      personelAdi: _string(json, 'PersonelAdi'),
      dil: _string(json, 'Dil'),
      isKodu: _string(json, 'IsKodu'),
      isAdi: _string(json, 'IsAdi'),
      resim: _bytes(json, 'Resim'),
      bolumKodu: _string(json, 'BolumKodu'),
      tunel: _string(json, 'Tunel'),
      koridor: _string(json, 'Koridor'),
      isSeviyesi: _int(json, 'IsSeviyesi'),
      tarih: _date(json, 'Tarih'),
      durum: _int(json, 'Durum'),
      durumAdi: _string(json, 'DurumAdi'),
      aktifSaniye: _int(json, 'AktifSaniye'),
      araSaniye: _int(json, 'AraSaniye'),
      toplamSaniye: _int(json, 'ToplamSaniye'),
      ortalamaSaniye: _int(json, 'OrtalamaSaniye'),
      azamiSaniye: _int(json, 'AzamiSaniye'),
      minimumSaniye: _int(json, 'MinimumSaniye'),
      maxEtiketAdedi: _int(json, 'MaxEtiketAdedi'),
      eklenenKutuSayisi: _int(json, 'EklenenKutuSayisi'),
      bitkiSokumu: _bool(json, 'BitkiSokumu'),
    );
  }
}

class OperasyonKodIsim {
  final String kod;
  final String isim;

  const OperasyonKodIsim({
    required this.kod,
    required this.isim,
  });

  factory OperasyonKodIsim.fromJson(Map<String, dynamic> json) {
    return OperasyonKodIsim(
      kod: _string(json, 'Kod'),
      isim: _string(json, 'Isim'),
    );
  }
}

class OperasyonKutu {
  final String barkod;

  const OperasyonKutu({required this.barkod});

  factory OperasyonKutu.fromJson(Map<String, dynamic> json) {
    return OperasyonKutu(barkod: _string(json, 'Barkod'));
  }
}

class OperasyonApiSonuc {
  final bool basarili;
  final String mesaj;
  final int durum;
  final int adet;
  final bool zatenKayitli;

  const OperasyonApiSonuc({
    required this.basarili,
    required this.mesaj,
    required this.durum,
    required this.adet,
    required this.zatenKayitli,
  });

  factory OperasyonApiSonuc.fromJson(Map<String, dynamic> json) {
    return OperasyonApiSonuc(
      basarili: _bool(json, 'Basarili'),
      mesaj: _string(json, 'Mesaj'),
      durum: _int(json, 'Durum'),
      adet: _int(json, 'Adet'),
      zatenKayitli: _bool(json, 'ZatenKayitli'),
    );
  }
}

dynamic _value(Map<String, dynamic> json, String key) {
  final aranan = key.toLowerCase();

  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == aranan) return entry.value;
  }

  return null;
}

String _string(Map<String, dynamic> json, String key) {
  return _value(json, key)?.toString().trim() ?? '';
}

int _int(Map<String, dynamic> json, String key) {
  final value = _value(json, key);
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(Map<String, dynamic> json, String key) {
  final value = _value(json, key);
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase() ?? '';
  return text == 'true' || text == '1' || text == 'evet';
}

DateTime? _date(Map<String, dynamic> json, String key) {
  final text = _string(json, key);
  return text.isEmpty ? null : DateTime.tryParse(text);
}

Uint8List? _bytes(Map<String, dynamic> json, String key) {
  final value = _value(json, key);
  if (value == null) return null;
  if (value is Uint8List) return value;
  if (value is List<int>) return Uint8List.fromList(value);

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  try {
    return base64Decode(text);
  } catch (_) {
    return null;
  }
}
