import 'dart:convert';
import 'package:agronet/const/string.dart';
import 'package:http/http.dart' as http;
import '../models/hasat_raporu_model.dart';

class HasatApi {
  static final String _baseUrl = App.outsideurl;

  String _yyyymmdd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y$m$day';
  }

  Future<List<HasatRaporuDetayModel>> getHasatRaporuDetayli(DateTime ilk, DateTime son) async {
    final base = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;

    final ilkYmd = _yyyymmdd(DateTime(ilk.year, ilk.month, ilk.day));
    final sonYmd = _yyyymmdd(DateTime(son.year, son.month, son.day));

    final uri = Uri.parse('$base/Hasat/HasatRaporuDetayli/Raporu/$ilkYmd/$sonYmd');

    final res = await http.get(uri, headers: {"Accept": "application/json"});

    if (res.statusCode != 200) {
      throw Exception("HasatRaporuDetayli hata: ${res.statusCode}  ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception("Beklenen List json değil: ${decoded.runtimeType}");
    }

    return decoded
        .map((e) => HasatRaporuDetayModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}