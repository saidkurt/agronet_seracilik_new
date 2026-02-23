

import 'package:agronet/page/LoginPage/LoginPageView.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

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
              '/login': (context) => LoginPageView(),
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
