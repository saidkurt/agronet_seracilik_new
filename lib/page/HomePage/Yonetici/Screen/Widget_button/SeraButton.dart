
import 'package:agronet/api/seraistanimlari.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SeraButton extends StatelessWidget {
  final String title; // "1.SERA"
  final String route; // "/sera1anaekran"

  const SeraButton({
    super.key,
    required this.title,
    required this.route,
  });

  void _showLoading(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.brown.shade500.withOpacity(0.95),
        content: Row(
          children: const [
            SpinKitCircle(color: Colors.white, size: 34),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Lütfen Bekleyin..",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _hideLoading(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        _showLoading(context);
        try {
          await SeraIsTanimlariApi().getSeraIsTanimlari(); // iş listesi çek
          // debug:
          // print(seraislistesi);

          _hideLoading(context);
          Navigator.pushNamed(context, route);
        } catch (e) {
          _hideLoading(context);
          _showError(context, "İş listesi alınamadı: $e");
        }
      },
      child: Container(
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          gradient: LinearGradient(
            colors: <Color>[Colors.brown.shade500, Colors.black12],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(fontSize: 65, color: Colors.white),
        ),
        height: MediaQuery.of(context).size.height / 9,
        width: MediaQuery.of(context).size.longestSide / 2.5,
      ),
    );
  }
}

// ---- Kullanım kolaylığı için hazır 4 buton ----

class Sera1Button extends StatelessWidget {
  const Sera1Button({super.key});

  @override
  Widget build(BuildContext context) {
    return const SeraButton(title: "1.SERA", route: "/sera1anaekran");
  }
}

class Sera2Button extends StatelessWidget {
  const Sera2Button({super.key});

  @override
  Widget build(BuildContext context) {
    return const SeraButton(title: "2.SERA", route: "/sera2anaekran");
  }
}

class Sera3Button extends StatelessWidget {
  const Sera3Button({super.key});

  @override
  Widget build(BuildContext context) {
    return const SeraButton(title: "3.SERA", route: "/sera3anaekran");
  }
}

class Sera4Button extends StatelessWidget {
  const Sera4Button({super.key});

  @override
  Widget build(BuildContext context) {
    return const SeraButton(title: "4.SERA", route: "/sera4anaekran");
  }
}
