import 'package:flutter/material.dart';

import 'package:agronet/models/login_user_model.dart';
import 'package:agronet/page/depo_talep_onay.dart';
import 'package:agronet/page/Homepage/home_page.dart';
import 'package:agronet/page/talep_detay_page.dart';

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

    // Uygulama tamamen kapalıyken bildirime basılırsa
    // OneSignal listener HomeMenu oluşmadan önce çalışabilir.
    //
    // Kullanıcı yüklendikten sonra bekleyen bildirim yeniden açılır.
    Future.delayed(
      const Duration(
        milliseconds: 350,
      ),
      _bekleyenBildirimiAc,
    );
  }

  static void kullaniciyiTemizle() {
    _aktifUser = null;
    _bekleyenBildirim = null;
  }

  // ============================================================
  // ONESIGNAL CLICK
  // ============================================================

  static void bildirimTiklandi(
    Map<String, dynamic>? data,
  ) {
    if (data == null ||
        data.isEmpty) {
      return;
    }

    debugPrint(
      'Bildirim tıklandı: $data',
    );

    _bekleyenBildirim =
        Map<String, dynamic>.from(
      data,
    );

    _bekleyenBildirimiAc();
  }

  // ============================================================
  // BİLDİRİMİ AÇ
  // ============================================================

  static void _bekleyenBildirimiAc() {
    final data =
        _bekleyenBildirim;

    final user =
        _aktifUser;

    if (data == null ||
        user == null) {
      return;
    }

    final navigator =
        navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    // ==========================================================
    // BİLDİRİM TÜRÜ
    // ==========================================================

    final tur =
        data['tur']
                ?.toString()
                .trim()
                .toUpperCase() ??
            '';

    // ==========================================================
    // EVRAK BİLGİLERİ
    // ==========================================================

    final seri =
        data['seri']
                ?.toString()
                .trim() ??
            '';

    final sira =
        int.tryParse(
              data['sira']
                      ?.toString()
                      .trim() ??
                  '',
            ) ??
            0;

    if (seri.isEmpty ||
        sira <= 0) {
      debugPrint(
        'Bildirim evrak bilgisi geçersiz: '
        '$seri-$sira',
      );

      _bekleyenBildirim =
          null;

      return;
    }

    // ==========================================================
    // KULLANICI / OTURUM BİLGİLERİ
    // ==========================================================

    final kullaniciKodu =
        user.depoKullaniciKodu.trim();

    final oturumId =
        user.oturumId ?? 0;

    final token =
        user.token?.trim() ?? '';

    // ==========================================================
    // 1) YENİ DEPO TALEBİ
    //
    // ESKİ DAVRANIŞ AYNEN KALIR.
    //
    // Yeni talep bildirimi:
    //
    // DEPO_TALEP
    //      ↓
    // DepoTalepOnayPage
    //
    // Kullanıcı talebi direkt onaylayabilir.
    // ==========================================================

    if (tur == 'DEPO_TALEP') {
      if (kullaniciKodu.isEmpty ||
          oturumId <= 0 ||
          token.isEmpty) {
        debugPrint(
          'Depo talep bildirimi açılamadı: '
          'oturum bilgisi eksik.',
        );

        // Oturum henüz oluşmamış olabilir.
        // Bekleyen bildirimi silmiyoruz.
        // kullaniciAyarla tekrar çağrılınca yeniden denenecek.
        return;
      }

      debugPrint(
        'Depo talep onay ekranı açılıyor: '
        '$seri-$sira',
      );

      // Aynı bildirim ikinci kez açılmasın.
      _bekleyenBildirim =
          null;

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

      return;
    }

    // ==========================================================
    // 2) TALEP TAMAMEN ONAYLANDI
    //
    // Yeni davranış:
    //
    // DEPO_TALEP_ONAYLANDI
    //      ↓
    // Ana Sayfa
    //      ↓
    // TalepDetayPage
    //
    // TalepDetayPage'den geri basılırsa
    // direkt Ana Sayfa gelir.
    // ==========================================================

    if (tur ==
        'DEPO_TALEP_ONAYLANDI') {
      debugPrint(
        'Onaylanan talep detay ekranı açılıyor: '
        '$seri-$sira',
      );

      // Aynı bildirim ikinci kez açılmasın.
      _bekleyenBildirim =
          null;

      // ========================================================
      // ÖNCE NAVIGATION STACK'İ TEMİZLE
      //
      // Sadece HomeMenu bırak.
      // ========================================================

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              HomeMenuPage(
            user: user,
          ),
        ),
        (route) => false,
      );

      // ========================================================
      // HomeMenu route'u yerleştikten sonra TalepDetay aç.
      //
      // Stack:
      //
      // HomeMenu
      //    ↓
      // TalepDetayPage
      //
      // Geri = HomeMenu
      // ========================================================

      Future.delayed(
        const Duration(
          milliseconds: 150,
        ),
        () {
          final nav =
              navigatorKey.currentState;

          if (nav == null) {
            return;
          }

          nav.push(
            MaterialPageRoute(
              builder: (_) =>
                  TalepDetayPage(
                seri:
                    seri,

                sira:
                    sira,
              ),
            ),
          );
        },
      );

      return;
    }

    // ==========================================================
    // DESTEKLENMEYEN BİLDİRİM
    // ==========================================================

    debugPrint(
      'Desteklenmeyen bildirim türü: $tur',
    );

    _bekleyenBildirim =
        null;
  }
}