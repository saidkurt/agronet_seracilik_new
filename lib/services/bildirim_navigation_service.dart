import 'package:flutter/material.dart';

import 'package:agronet/models/login_user_model.dart';
import 'package:agronet/page/depo_talep_onay.dart';

class BildirimNavigationService {
  BildirimNavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static LoginUserModel? _aktifUser;

  static Map<String, dynamic>? _bekleyenBildirim;

  // ============================================================
  // AKTİF KULLANICI
  // ============================================================

  static void kullaniciAyarla(
    LoginUserModel user,
  ) {
    _aktifUser = user;

    // Uygulama kapalıyken bildirime basıldıysa
    // listener önce çalışmış olabilir.
    // HomeMenu açılınca bekleyen bildirimi aç.
    Future.delayed(
      const Duration(milliseconds: 300),
      _bekleyenBildirimiAc,
    );
  }

  static void kullaniciyiTemizle() {
    _aktifUser = null;
  }

  // ============================================================
  // ONESIGNAL CLICK
  // ============================================================

  static void bildirimTiklandi(
    Map<String, dynamic>? data,
  ) {
    if (data == null || data.isEmpty) {
      return;
    }

    debugPrint(
      'Bildirim tıklandı: $data',
    );

    _bekleyenBildirim =
        Map<String, dynamic>.from(data);

    _bekleyenBildirimiAc();
  }

  // ============================================================
  // BİLDİRİMİ AÇ
  // ============================================================

  static void _bekleyenBildirimiAc() {
    final data = _bekleyenBildirim;
    final user = _aktifUser;

    if (data == null || user == null) {
      return;
    }

    final navigator =
        navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    final tur =
        data['tur']?.toString().trim() ?? '';

    if (tur != 'DEPO_TALEP') {
      return;
    }

    final seri =
        data['seri']?.toString().trim() ?? '';

    final sira =
        int.tryParse(
          data['sira']?.toString() ?? '',
        ) ??
        0;

    if (seri.isEmpty || sira <= 0) {
      debugPrint(
        'Bildirim evrak bilgisi geçersiz: $seri-$sira',
      );

      _bekleyenBildirim = null;
      return;
    }

    final kullaniciKodu =
        user.depoKullaniciKodu.trim();

    final oturumId =
        user.oturumId ?? 0;

    final token =
        user.token?.trim() ?? '';

    if (kullaniciKodu.isEmpty ||
        oturumId <= 0 ||
        token.isEmpty) {
      debugPrint(
        'Bildirim açılamadı: oturum bilgisi eksik.',
      );

      return;
    }

    // Aynı bildirimi ikinci kez açma.
    _bekleyenBildirim = null;

    navigator.push(
      MaterialPageRoute(
        builder: (_) =>
            DepoTalepOnayPage(
          kullaniciKodu:
              kullaniciKodu,
          oturumId:
              oturumId,
          token:
              token,

          // Bildirimden gelen fiş
          ilkSeri:
              seri,
          ilkSira:
              sira,
        ),
      ),
    );
  }
}