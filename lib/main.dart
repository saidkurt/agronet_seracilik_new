import 'package:agronet/api/login_api.dart';
import 'package:agronet/page/Homepage/home_page.dart';
import 'package:agronet/page/LoginPage/LoginPageView.dart';
import 'package:agronet/services/bildirim_navigation_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting(
    'tr_TR',
    null,
  );

  // ============================================================
  // ONESIGNAL
  // ============================================================

  OneSignal.Debug.setLogLevel(
    OSLogLevel.verbose,
  );

  OneSignal.initialize(
    'c6d12431-0a33-40dc-aa69-b39d9b780869',
  );

  // ============================================================
  // BİLDİRİME TIKLAMA
  // ============================================================

  OneSignal.Notifications.addClickListener(
    (event) {
      final data =
          event.notification.additionalData;

      debugPrint(
        'ONESIGNAL CLICK DATA: $data',
      );

      BildirimNavigationService
          .bildirimTiklandi(
        data,
      );
    },
  );

  await OneSignal.Notifications
      .requestPermission(
    true,
  );

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      navigatorKey:
          BildirimNavigationService
              .navigatorKey,

      debugShowCheckedModeBanner:
          false,

      locale:
          const Locale(
        'tr',
        'TR',
      ),

      supportedLocales: const [
        Locale(
          'tr',
          'TR',
        ),
        Locale(
          'en',
          'US',
        ),
      ],

      localizationsDelegates:
          const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routes: {
        '/login': (
          context,
        ) =>
            const LoginPageView(),
      },

      theme: ThemeData(
        fontFamily:
            "Montserrat",

        primarySwatch:
            Colors.blue,

        visualDensity:
            VisualDensity
                .adaptivePlatformDensity,

        unselectedWidgetColor:
            Colors.grey,
      ),

      home:
          const AuthGate(),
    );
  }
}

// ============================================================================
// AUTH GATE
// Native splash bittikten sonra sadece nereye gidileceğine karar verir.
// ============================================================================

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
  });

  @override
  State<AuthGate> createState() =>
      _AuthGateState();
}

class _AuthGateState
    extends State<AuthGate> {
  final LoginApi _api =
      const LoginApi();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        _kontrolEt();
      },
    );
  }

  Future<void> _kontrolEt() async {
    try {
      final prefs =
          await SharedPreferences
              .getInstance();

      final tel =
          prefs.getString('TEL') ??
              '';

      final sifre =
          prefs.getString('Sifre') ??
              '';

      // ========================================================
      // KAYITLI KULLANICI YOK
      // ========================================================

      if (tel.trim().isEmpty ||
          sifre.trim().isEmpty) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const LoginPageView(),
          ),
        );

        return;
      }

      // ========================================================
      // KAYITLI KULLANICI VAR
      // Backend yeni oturum/token oluştursun.
      // ========================================================

      final users =
          await _api.girisTel(
        telefon:
            tel.trim(),
        sifre:
            sifre.trim(),
      );

      if (!mounted) return;

      if (users.isEmpty) {
        await prefs.remove(
          'TEL',
        );

        await prefs.remove(
          'Sifre',
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const LoginPageView(),
          ),
        );

        return;
      }

      final user =
          users.first;

      // ========================================================
      // DİREKT ANA SAYFA
      // ========================================================

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HomeMenuPage(
            user: user,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'AuthGate giriş hatası: $e',
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginPageView(),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    // Buraya ayrıca splash koymuyoruz.
    // Native splash bittikten sonra çok kısa süre bu boş ekran kalabilir.
    return const Scaffold(
      backgroundColor:
          Colors.white,
    );
  }
}