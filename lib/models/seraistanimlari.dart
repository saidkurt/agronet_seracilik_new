class SeraIsTanimlari {
  final String kod;
  final String isim;

  const SeraIsTanimlari({
    required this.kod,
    required this.isim,
  });

  factory SeraIsTanimlari.fromJson(Map<String, dynamic> json) {
    return SeraIsTanimlari(
      kod: json['kod'] as String? ?? '',
      isim: json['isim'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kod': kod,
      'isim': isim,
    };
  }
}
