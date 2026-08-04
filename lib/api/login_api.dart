import 'dart:convert';

import 'package:agronet/const/string.dart';
import 'package:agronet/models/login_user_model.dart';
import 'package:http/http.dart' as http;

class LoginApi {
  const LoginApi();

  /// Telefon backend'e 10 haneli olarak gönderilir:
  /// 5xxxxxxxxx
  Future<List<LoginUserModel>> girisTel({
    required String telefon,
    required String sifre,
  }) async {
    final temizTelefon = _telefonTemizle(telefon);
    final temizSifre = sifre.trim();

    if (temizTelefon.length != 10 ||
        !temizTelefon.startsWith('5')) {
      throw Exception('Telefon numarası geçersiz.');
    }

    if (temizSifre.isEmpty) {
      throw Exception('Şifre boş olamaz.');
    }

    final base = App.outsideurl.endsWith('/')
        ? App.outsideurl.substring(
            0,
            App.outsideurl.length - 1,
          )
        : App.outsideurl;

    final uri = Uri.parse(
      '$base/Sistem/GirisTel/'
      '${Uri.encodeComponent(temizTelefon)}/'
      '${Uri.encodeComponent(temizSifre)}',
    );

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_hataMesajiGetir(response));
    }

    if (response.body.trim().isEmpty) {
      throw Exception('Sunucudan boş cevap geldi.');
    }

    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Giriş cevabı geçerli JSON değil: ${response.body}',
      );
    }

    if (decoded is! List) {
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);

        throw Exception(
          map['mesaj']?.toString() ??
              map['Mesaj']?.toString() ??
              'Giriş cevabı geçersiz.',
        );
      }

      throw Exception(
        'Beklenen giriş cevabı liste değil.',
      );
    }

    final kullanicilar = decoded
        .whereType<Map>()
        .map(
          (item) => LoginUserModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    if (kullanicilar.isEmpty) {
      throw Exception('Kullanıcı bulunamadı.');
    }

    final kullanici = kullanicilar.first;

    if ((kullanici.erpUserNo ?? 0) <= 0) {
      throw Exception(
        'Kullanıcının ERP kullanıcı numarası tanımlı değil.',
      );
    }

    if (!kullanici.oturumGecerli) {
      throw Exception(
        'Mobil oturum bilgisi oluşturulamadı.',
      );
    }

    return kullanicilar;
  }

  /// Kullanıcı uygulamadan çıkış yaptığında çağrılır.
  Future<bool> cikis({
    required int oturumId,
    required String token,
  }) async {
    if (oturumId <= 0 || token.trim().isEmpty) {
      return false;
    }

    final base = App.outsideurl.endsWith('/')
        ? App.outsideurl.substring(
            0,
            App.outsideurl.length - 1,
          )
        : App.outsideurl;

    final uri = Uri.parse('$base/Sistem/Cikis');

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'OturumId': oturumId,
        'Token': token,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_hataMesajiGetir(response));
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      return false;
    }

    final map = Map<String, dynamic>.from(decoded);

    return _toBool(
      map['basarili'] ?? map['Basarili'],
    );
  }

  static String _telefonTemizle(String telefon) {
    var digits = telefon.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.startsWith('90') && digits.length >= 12) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }

    return digits;
  }

  static String _hataMesajiGetir(http.Response response) {
    final varsayilan = 'HTTP ${response.statusCode}';

    if (response.body.trim().isEmpty) {
      return varsayilan;
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
            varsayilan;
      }

      return '$varsayilan: $decoded';
    } catch (_) {
      return '$varsayilan: ${response.body}';
    }
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value.toString().trim().toLowerCase();

    return text == '1' ||
        text == 'true' ||
        text == 'evet' ||
        text == 'yes';
  }
}