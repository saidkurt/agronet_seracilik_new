import 'package:agronet/page/HomePage/GirisSayfaDrawer.dart';
import 'package:agronet/page/HomePage/Yonetici/Screen/sera2anaekran.dart';
import 'package:agronet/page/HomePage/Yonetici/Screen/sera3anaekran.dart';
import 'package:agronet/page/HomePage/Yonetici/Screen/sera4anaekran.dart';
import 'package:agronet/page/LoginPage/LoginPageView.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'page/HomePage/Yonetici/Screen/sera1anaekran.dart';

Future<void> main() async {
  runApp(MyApp());  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(builder: (context, orientation) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/girissayfa': (context) => DrawerPageView(),
              '/anasayfa': (context) => LoginPageView(),
              '/sera1anaekran': (contex) => Sera1AnaEkran(),
              '/sera2anaekran': (contex) => Sera2AnaEkran(),
              '/sera3anaekran': (contex) => Sera3AnaEkran(),
              '/sera4anaekran': (contex) => Sera4AnaEkran(),
            },
            theme: ThemeData(
              fontFamily: "Montserrat",
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              unselectedWidgetColor: Colors.grey,
            ),
            home: LoginPageView(),
          );
        });
      },
    );
  }
}
