import 'package:agronet/const/string.dart';
import 'package:agronet/models/personelanlik_model.dart';
import 'package:dio/dio.dart';

class PersonelAnlikApi {
  PersonelAnlikApi({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// GET: /Personel/Bolum/{bolum}
  Future<List<PersonelAnlikDurum>> personelAnlikDurum(String bolum) async {
    final String url = '${App.outsideurl}/Personel/Bolum/$bolum/';

    try {
      final Response response = await _dio.get(url);

      if (response.statusCode != 200) {
        throw Exception(
          'Personel anlık durum alınamadı. '
          'Status: ${response.statusCode}',
        );
      }

      final data = response.data;

      if (data is! List) {
        throw Exception('Beklenen JSON liste değil: $data');
      }

      return data
          .map<PersonelAnlikDurum>(
            (e) => PersonelAnlikDurum.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('PersonelAnlikApi hata: $e');
    }
  }
}
