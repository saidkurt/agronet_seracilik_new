import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/sistem_otp_model.dart';
import 'package:http/http.dart' as http;

class SistemOtpApi {
  const SistemOtpApi();

  static const _headers = <String, String>{
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  /// POST /Sistem/SifreUnuttum/OtpGonder
  /// body: { "telefon": "5445322545" }
  Future<OtpGonderResponse> otpGonder(String telefon) async {
    final Uri uri = Uri.parse('${App.localurl}/Sistem/SifreUnuttum/OtpGonder');

    final http.Response response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({"telefon": telefon}),
    );

    return _parseObject(
      response,
      (j) => OtpGonderResponse.fromJson(j),
      errPrefix: 'OtpGonder',
    );
  }

  /// POST /Sistem/SifreUnuttum/OtpDogrula
  /// body: { "otpRef": "GUID", "kod": "123456" }
  Future<OtpDogrulaResponse> otpDogrula({
    required String otpRef,
    required String kod,
  }) async {
    final Uri uri = Uri.parse('${App.localurl}/Sistem/SifreUnuttum/OtpDogrula');

    final http.Response response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        "otpRef": otpRef,
        "kod": kod,
      }),
    );

    return _parseObject(
      response,
      (j) => OtpDogrulaResponse.fromJson(j),
      errPrefix: 'OtpDogrula',
    );
  }

  /// POST /Sistem/SifreUnuttum/YeniSifre
  /// body: { "resetToken": "GUID", "yeniSifre": "1234" }
  Future<YeniSifreResponse> yeniSifreKaydet({
    required String resetToken,
    required String yeniSifre,
  }) async {
    final Uri uri = Uri.parse('${App.localurl}/Sistem/SifreUnuttum/YeniSifre');

    final http.Response response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        "resetToken": resetToken,
        "yeniSifre": yeniSifre,
      }),
    );

    return _parseObject(
      response,
      (j) => YeniSifreResponse.fromJson(j),
      errPrefix: 'YeniSifre',
    );
  }

  // -------------------------
  // Helpers (typed parser)
  // -------------------------
  T _parseObject<T>(
    http.Response response,
    T Function(Map<String, dynamic> j) mapper, {
    required String errPrefix,
  }) {
    final String body = utf8.decode(response.bodyBytes);

    if (response.statusCode != 200) {
      throw Exception('$errPrefix başarısız. Status: ${response.statusCode}, Body: $body');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw Exception('$errPrefix: JSON parse edilemedi. Body: $body');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('$errPrefix: Beklenen JSON obje değil. Body: $body');
    }

    return mapper(decoded);
  }
}