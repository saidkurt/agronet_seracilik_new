import 'dart:convert';
import 'package:agronet/const/string.dart';
import 'package:agronet/models/tuta_rapor_model.dart';
import 'package:http/http.dart' as http;


class TutaApi {
  final http.Client _client = http.Client();

  Future<List<TutaRaporModel>> raporGetir({
    required String sera,
    required DateTime ilkTarih,
    required DateTime sonTarih,
  }) async {
    final String ilk = _formatDate(ilkTarih);
    final String son = _formatDate(sonTarih);

    final Uri uri = Uri.parse(
      "${App.outsideurl}/Tuta/Rapor/$sera/$ilk/$son",
    );

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          "Tuta raporu alınamadı. Status: ${response.statusCode}",
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map<TutaRaporModel>(
              (e) => TutaRaporModel.fromJson(
                (e as Map).cast<String, dynamic>(),
              ),
            )
            .toList();
      }

      if (decoded is Map) {
        return [
          TutaRaporModel.fromJson(
            decoded.cast<String, dynamic>(),
          )
        ];
      }

      throw Exception("Beklenen JSON list/map değil");
    } catch (e) {
      throw Exception("TutaApi raporGetir hata: $e");
    }
  }

  Future<TutaIsimlerModel> isimleriGetir({
    required String sera,
  }) async {
    final Uri uri = Uri.parse("${App.outsideurl}/Tuta/Isimler/$sera");

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          "Tuta isimleri alınamadı. Status: ${response.statusCode}",
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is List) {
        if (decoded.isEmpty) return const TutaIsimlerModel();

        return TutaIsimlerModel.fromJson(
          (decoded.first as Map).cast<String, dynamic>(),
        );
      }

      if (decoded is Map) {
        return TutaIsimlerModel.fromJson(
          decoded.cast<String, dynamic>(),
        );
      }

      throw Exception("Beklenen JSON list/map değil");
    } catch (e) {
      throw Exception("TutaApi isimleriGetir hata: $e");
    }
  }

  Future<List<TutaToplamModel>> toplamGetir({
    required DateTime ilkTarih,
    required DateTime sonTarih,
  }) async {
    final String ilk = _formatDate(ilkTarih);
    final String son = _formatDate(sonTarih);

    final Uri uri = Uri.parse(
      "${App.outsideurl}/Tuta/Toplam/$ilk/$son",
    );

    try {
      final http.Response response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          "Toplam tuta alınamadı. Status: ${response.statusCode}",
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map<TutaToplamModel>(
              (e) => TutaToplamModel.fromJson(
                (e as Map).cast<String, dynamic>(),
              ),
            )
            .toList();
      }

      if (decoded is Map) {
        return [
          TutaToplamModel.fromJson(
            decoded.cast<String, dynamic>(),
          )
        ];
      }

      throw Exception("Beklenen JSON list/map değil");
    } catch (e) {
      throw Exception("TutaApi toplamGetir hata: $e");
    }
  }

  String _formatDate(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
