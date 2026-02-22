import 'package:flutter/material.dart';

class Resim2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [Colors.black, Colors.white],
        begin: Alignment.bottomCenter,
        end: Alignment.center,
      ).createShader(bounds),
      child: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
          image: AssetImage("assets/2.jpg"),
          fit: BoxFit.cover,
        )),
      ),
    );
  }
}

class Resim5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [Colors.white, Colors.white],
        begin: Alignment.bottomCenter,
        end: Alignment.center,
      ).createShader(bounds),
      child: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
          image: AssetImage("assets/5.jpg"),
          fit: BoxFit.cover,
        )),
      ),
    );
  }
}
