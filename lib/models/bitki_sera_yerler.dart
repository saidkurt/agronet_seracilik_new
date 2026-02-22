class SeraYerModel {
  String? sera;
  List<String>? yerler;

  SeraYerModel({
    this.sera,
    this.yerler,
  });

  /// JSON -> Model
  factory SeraYerModel.fromJson(Map<String, dynamic> json) {
    return SeraYerModel(
      sera: json['sera']?.toString(),
      yerler: json['yerler'] != null
          ? List<String>.from(json['yerler'])
          : null,
    );
  }

  /// Model -> JSON
  Map<String, dynamic> toJson() {
    return {
      "sera": sera,
      "yerler": yerler,
    };
  }
}
