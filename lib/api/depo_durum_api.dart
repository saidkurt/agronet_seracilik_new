import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agronet/const/string.dart';
import 'package:agronet/models/depo_durum_model.dart';

class DepoDurumApi {
  Future<List<DepoDurumModel>> depoDurumGetir(int depo) async {
    final url = "${App.outsideurl}/Depo/Durum/$depo";
    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}");
    }

    final decoded = jsonDecode(res.body);
    
    if (decoded is! List) return [];

    return decoded
        .map((e) => DepoDurumModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}