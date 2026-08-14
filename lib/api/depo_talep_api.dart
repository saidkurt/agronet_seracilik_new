import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/depo_talep_model.dart';
import 'package:http/http.dart' as http;

class DepoTalepApi {
  static final String _base = App.outsideurl;

  /// Açık talep evrakları
  Future<List<DepoTalepEvrakModel>> talepEvraklariGetir() async {
    final uri = Uri.parse('$_base/Depo/TalepEvraklari');

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_hataMesajiGetir(response));
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (e) => DepoTalepEvrakModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  /// Evrak detayı
  Future<DepoTalepDetayModel?> talepDetayGetir({
    required String seri,
    required int sira,
  }) async {
    final uri = Uri.parse(
      '$_base/Depo/TalepDetay',
    ).replace(
      queryParameters: {
        'seri': seri,
        'sira': sira.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception(_hataMesajiGetir(response));
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Evrak detay cevabı geçersiz.');
    }

    return DepoTalepDetayModel.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  /// Talebi onayla
  Future<DepoIslemSonucModel> talepOnayla(
    DepoTalepOnayRequestModel model,
  ) async {
    final uri = Uri.parse('$_base/Depo/TalepOnayla');

    final requestBody = jsonEncode(model.toJson());

    // Geçici kontrol için açabilirsin:
    // debugPrint('Talep onay isteği: $requestBody');

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: requestBody,
    );

    if (response.statusCode != 200) {
      throw Exception(_hataMesajiGetir(response));
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Onaylama cevabı geçersiz.');
    }

    return DepoIslemSonucModel.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  /// Kalanı kapat
  Future<DepoIslemSonucModel> talepKalaniKapat(
    DepoTalepKapatRequestModel model,
  ) async {
    final uri = Uri.parse('$_base/Depo/TalepKalaniKapat');

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(model.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(_hataMesajiGetir(response));
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Kalanı kapatma cevabı geçersiz.');
    }

    return DepoIslemSonucModel.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  static String _hataMesajiGetir(http.Response response) {
    final varsayilanMesaj = 'HTTP ${response.statusCode}';

    if (response.body.trim().isEmpty) {
      return varsayilanMesaj;
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);

        return map['mesaj']?.toString() ??
            map['Mesaj']?.toString() ??
            map['message']?.toString() ??
            map['Message']?.toString() ??
            map['ExceptionMessage']?.toString() ??
            '$varsayilanMesaj: ${response.body}';
      }

      return '$varsayilanMesaj: $decoded';
    } catch (_) {
      return '$varsayilanMesaj: ${response.body}';
    }
  }
}