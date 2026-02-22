import 'dart:convert';
import 'package:agronet/const/string.dart';
import 'package:agronet/models/login_user_model.dart';
import 'package:http/http.dart' as http;

class LoginApi {
  const LoginApi();

  /// telefon: 505xxxxxxxx (10 hane) - backend'e bu gider
  Future<List<LoginUserModel>> girisTel({
    required String telefon,
    required String sifre,
  }) async {
    final uri = Uri.parse("${App.outsideurl}/Sistem/GirisTel/$telefon/$sifre/");

    final res = await http.get(uri, headers: {"Accept": "application/json"});

    if (res.statusCode != 200) {
      throw Exception("Login başarısız. Status: ${res.statusCode}, Body: ${res.body}");
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! List) {
      throw Exception("Beklenen JSON liste değil: ${res.body}");
    }

    return decoded
        .map((e) => LoginUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}