import 'package:agronet/page/LoginPage/LoginPageView.dart';
import 'package:agronet/services/update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: const Locale('tr', 'TR'),
              supportedLocales: const [
                Locale('tr', 'TR'),
                Locale('en', 'US'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              initialRoute: '/',
              routes: {
                '/login': (context) => const LoginPageView(),
              },
              theme: ThemeData(
                fontFamily: "Montserrat",
                primarySwatch: Colors.blue,
                visualDensity: VisualDensity.adaptivePlatformDensity,
                unselectedWidgetColor: Colors.grey,
              ),

              home: const StartupPage(),
            );
          },
        );
      },
    );
  }
}

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Önce cihazı SQL'e kaydet / son görülme ve sürümü güncelle
      await UpdateService.cihazKaydet();

      if (!mounted) return;

      // Sonra yeni sürüm var mı kontrol et
      await UpdateService.guncellemeKontrolEt(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const LoginPageView();
  }
}