class OlcumTipleriModel {
  int? id;
  String? isim;
  String? verigirisTipi;
  int? manuelGiris;
  int? bildir;

  OlcumTipleriModel({
    this.id,
    this.isim,
    this.verigirisTipi,
    this.manuelGiris,
    this.bildir,
  });

  factory OlcumTipleriModel.fromJson(Map<String, dynamic> json) {
    return OlcumTipleriModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),

      isim: json['isim']?.toString(),

      verigirisTipi: json['verigirisTipi']?.toString(),

      manuelGiris: json['manuelGiris'] is int
          ? json['manuelGiris']
          : int.tryParse(json['manuelGiris']?.toString() ?? ''),

      bildir: json['bildir'] is int
          ? json['bildir']
          : int.tryParse(json['bildir']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isim': isim,
      'verigirisTipi': verigirisTipi,
      'manuelGiris': manuelGiris,
      'bildir': bildir,
    };
  }
}
