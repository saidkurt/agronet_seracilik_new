import 'package:agronet/const/string.dart';
import 'package:flutter/material.dart';

AppBar buildAppBarCustomAppBar(
  BuildContext context, {
  String? title,
}) {
  return AppBar(
    actions: [
      PopupMenuButton(
        shape: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
          gapPadding: 3,
        ),
        color: Colors.brown.shade500,
        elevation: 5,
        padding: EdgeInsets.all(2),
        tooltip: 'Ayarlar',
        icon: Icon(
          Icons.settings,
          color: Colors.white,
        ),
        itemBuilder: (BuildContext bc) => [
          PopupMenuItem(
            child: ListTile(
              onTap: () => null,
              leading: Icon(Icons.vpn_key, color: Colors.white),
              title: Text(
                "Şifre Değiştir",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    ],
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.shade500, Colors.black],
          stops: [0.5, 1.0],
        ),
      ),
    ),
    backgroundColor: Colors.brown.shade500,
    title: Center(
      child: Text(
        title ?? App.appbarString, // 🔥 boşsa default başlık
      ),
    ),
  );
}
