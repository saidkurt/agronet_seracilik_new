import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:agronet/const/string.dart';
import 'package:agronet/models/mobil_yetki_model.dart';

class MobilYetkiApi {
  /// Tüm personel tiplerini ve menü bazlı yetkilerini getirir.
  ///
  /// GET: /Sistem/MobilYetkiler
  Future<List<MobilYetkiModel>> yetkileriGetir() async {
    final url = "${App.insideurl}/Sistem/MobilYetkiler";

    final res = await http.get(
      Uri.parse(url),
    );

    if (res.statusCode != 200) {
      throw Exception(
        "HTTP ${res.statusCode}: ${res.body}",
      );
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .map(
          (e) => MobilYetkiModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  /// Seçilen personel tipinin tüm mobil menü yetkilerini kaydeder.
  ///
  /// POST: /Sistem/MobilYetkiler/Kaydet
  ///
  /// Body:
  /// {
  ///   "personeltipid": 17,
  ///   "menuler": [
  ///     {
  ///       "menuid": 1,
  ///       "yetkili": true
  ///     }
  ///   ]
  /// }
  Future<void> yetkileriKaydet({
    required int personelTipId,
    required List<MobilYetkiModel> menuler,
  }) async {
    final url =
        "${App.insideurl}/Sistem/MobilYetkiler/Kaydet";

    final body = {
      "personeltipid": personelTipId,
      "menuler": menuler
          .map(
            (e) => e.toKaydetJson(),
          )
          .toList(),
    };

    final res = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception(
        "HTTP ${res.statusCode}: ${res.body}",
      );
    }

    if (res.body.trim().isEmpty) {
      return;
    }

    final decoded = jsonDecode(res.body);

    if (decoded is Map) {
      final data =
          Map<String, dynamic>.from(decoded);

      final basarili =
          data["basarili"] ??
              data["Basarili"];

      if (basarili == false) {
        throw Exception(
          data["mesaj"]?.toString() ??
              data["Mesaj"]?.toString() ??
              "Yetkiler kaydedilemedi.",
        );
      }
    }
  }
}