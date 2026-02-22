import 'package:agronet/page/HomePage/YoneticiOlmayan/AnasayfaView.dart';
import 'package:flutter/material.dart';

import 'GirissayfaView.dart';

class GirisSayfaMerkez extends StatelessWidget {
  final bool? yonetici;
  final bool? danisman;
  final bool? kontrol;
  final String bileklik;
  final String tip;

  const GirisSayfaMerkez({
    super.key,
    required this.bileklik,
    required this.tip,
    this.yonetici,
    this.danisman,
    this.kontrol,
  });

  @override
  Widget build(BuildContext context) {
    final isYetkili =
        (yonetici == true) || (danisman == true) || (kontrol == true);

    return isYetkili
        ?  GirisSayfaView()
        : AnasayfaView(tip: tip, bileklikno_1: bileklik);
  }
}
