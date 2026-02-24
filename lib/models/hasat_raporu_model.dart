class HasatRaporuDetayModel {
  final String? toplayanPersonel;
  final DateTime? toplamaTarihi;
  final String? toplamaAy;
  final int? toplamaHafta;
  final int? toplamaGun;

  final String? bolum;
  final String? tunel;
  final String? isitmaSektoru;
  final String? sulamaSektoru;
  final String? tunelYonu;

  final String? kutuTipi;
  final String? urunTipi;

  final String? okutanPersonel;
  final String? paketleyenPersonel;

  final DateTime? paketlemeTarihi;
  final String? paketlemeAy;
  final int? paketlemeHafta;
  final int? paketlemeGun;

  final double? brutKg;
  final double? netKg;
  final double? dara;

  final String? personelTipi;

  HasatRaporuDetayModel({
    this.toplayanPersonel,
    this.toplamaTarihi,
    this.toplamaAy,
    this.toplamaHafta,
    this.toplamaGun,
    this.bolum,
    this.tunel,
    this.isitmaSektoru,
    this.sulamaSektoru,
    this.tunelYonu,
    this.kutuTipi,
    this.urunTipi,
    this.okutanPersonel,
    this.paketleyenPersonel,
    this.paketlemeTarihi,
    this.paketlemeAy,
    this.paketlemeHafta,
    this.paketlemeGun,
    this.brutKg,
    this.netKg,
    this.dara,
    this.personelTipi,
  });

  factory HasatRaporuDetayModel.fromJson(Map<String, dynamic> json) {
    return HasatRaporuDetayModel(
      toplayanPersonel: json["ToplayanPersonel"],
      toplamaTarihi: json["ToplanmaTarihi"] != null
          ? DateTime.tryParse(json["ToplanmaTarihi"])
          : null,
      toplamaAy: json["ToplamaAy"],
      toplamaHafta: json["ToplamaHafta"],
      toplamaGun: json["ToplamaGun"],
      bolum: json["Bolum"],
      tunel: json["Tunel"],
      isitmaSektoru: json["IsitmaSektoru"],
      sulamaSektoru: json["SulamaSektoru"],
      tunelYonu: json["TunelYonu"],
      kutuTipi: json["KutuTipi"],
      urunTipi: json["UrunTipi"],
      okutanPersonel: json["OkutanPersonel"],
      paketleyenPersonel: json["PaketleyenPersonel"],
      paketlemeTarihi: json["PaketlemeTarihi"] != null
          ? DateTime.tryParse(json["PaketlemeTarihi"])
          : null,
      paketlemeAy: json["PaketlemeAy"],
      paketlemeHafta: json["PaketlemeHafta"],
      paketlemeGun: json["PaketlemeGun"],
      brutKg: (json["BrutKg"] as num?)?.toDouble(),
      netKg: (json["NetKg"] as num?)?.toDouble(),
      dara: (json["Dara"] as num?)?.toDouble(),
      personelTipi: json["PersonelTipi"],
    );
  }

  Map<String, dynamic> toJson() => {
        "ToplayanPersonel": toplayanPersonel,
        "ToplanmaTarihi": toplamaTarihi?.toIso8601String(),
        "ToplamaAy": toplamaAy,
        "ToplamaHafta": toplamaHafta,
        "ToplamaGun": toplamaGun,
        "Bolum": bolum,
        "Tunel": tunel,
        "IsitmaSektoru": isitmaSektoru,
        "SulamaSektoru": sulamaSektoru,
        "TunelYonu": tunelYonu,
        "KutuTipi": kutuTipi,
        "UrunTipi": urunTipi,
        "OkutanPersonel": okutanPersonel,
        "PaketleyenPersonel": paketleyenPersonel,
        "PaketlemeTarihi": paketlemeTarihi?.toIso8601String(),
        "PaketlemeAy": paketlemeAy,
        "PaketlemeHafta": paketlemeHafta,
        "PaketlemeGun": paketlemeGun,
        "BrutKg": brutKg,
        "NetKg": netKg,
        "Dara": dara,
        "PersonelTipi": personelTipi,
      };
}