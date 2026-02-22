import 'package:agronet/page/LoginPage/Resim.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'Yonetici/Screen/Widget_button/SeraButton.dart';

class GirisSayfaView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Resim2(),
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.longestSide,
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height / 8,
                ),
                Sera1Button(),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 13,
                ),
                Sera2Button(),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 13,
                ),
                Sera3Button(),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 13,
                ),
                Sera4Button(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
