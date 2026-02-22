import 'dart:convert';
import 'package:agronet/api/personelpuandetay.dart';
import 'package:agronet/page/DrawerPage/puandetayidunku.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;

class AnasayfaView extends StatefulWidget {
  final String bileklikno_1;
  final String tip;

  const AnasayfaView({
    Key? key,
    required this.tip,
    required this.bileklikno_1,
  }) : super(key: key);

  @override
  State<AnasayfaView> createState() => _AnasayfaViewState();
}

class _AnasayfaViewState extends State<AnasayfaView> {
  double dunkupuan = 0.0;
  double buhaftakipuan = 0.0;
  double buaykipuan = 0.0;

  double dunkuhedef = 0.0;
  double buhaftakihedef = 0.0;
  double buaykihedef = 0.0;

  bool _loading = true;

  // API bazen sayıyı int/double/string gönderebilir -> hepsini double'a çeviriyoruz
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(',', '.');
    return double.tryParse(s) ?? 0.0;
  }

  Future<void> performansRaporu2(String bileklikid) async {
    setState(() => _loading = true);

    try {
      const baseUrl = 'http://88.248.170.183:2626/Sera/PerformansRaporu/';
      final response = await http.get(Uri.parse('$baseUrl$bileklikid'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        dynamic decoded = json.decode(response.body);

        // Senin eski kodda json iki kez decode ediliyordu.
        // Eğer API body içinde "json string" döndürüyorsa bunu da yakalıyoruz.
        if (decoded is String) {
          decoded = json.decode(decoded);
        }

        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);

          dunkupuan = _toDouble(map["dunkupuan"]);
          buhaftakipuan = _toDouble(map["buhaftakipuan"]);
          buaykipuan = _toDouble(map["buaykipuan"]);

          dunkuhedef = _toDouble(map["dunkuhedef"]);
          buhaftakihedef = _toDouble(map["buhaftakihedef"]);
          buaykihedef = _toDouble(map["buaykihedef"]);
        } else {
          // Beklenmeyen format
          dunkupuan = buhaftakipuan = buaykipuan = 0.0;
          dunkuhedef = buhaftakihedef = buaykihedef = 0.0;
        }
      } else {
        // HTTP hata
        dunkupuan = buhaftakipuan = buaykipuan = 0.0;
        dunkuhedef = buhaftakihedef = buaykihedef = 0.0;
        // İstersen hata mesajı göster:
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${response.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      // Network/parse hatası
      dunkupuan = buhaftakipuan = buaykipuan = 0.0;
      dunkuhedef = buhaftakihedef = buaykihedef = 0.0;
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> detayagit(String tip) async {
    _showLoadingDialog();

    try {
      await PersonelPuanDetayApi().personelPuanDetay(bileklikId: widget.bileklikno_1, tip: tip);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // loading kapat

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) =>  PuanDetayiDun()),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // loading kapat
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  void _showLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SpinKitCircle(color: Colors.brown),
              SizedBox(width: 16),
              Text('Lütfen Bekleyin..'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    performansRaporu2(widget.bileklikno_1);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: SpinKitCircle(color: Colors.brown.shade500),
      );
    }

    // Eğer API gerçekten "hedef=0" durumunda boş dönüyorsa, yine loader yerine bilgi göstermek daha doğru
    if (buaykihedef == 0 && buhaftakihedef == 0 && dunkuhedef == 0) {
      return Center(
        child: Text(
          'Veri bulunamadı.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _puanKart(
          context: context,
          baslikPuan: 'Dünkü Puan',
          puan: dunkupuan,
          baslikHedef: 'Dünkü Hedef',
          hedef: dunkuhedef,
          onDetay: () => detayagit('D'),
        ),
        _puanKart(
          context: context,
          baslikPuan: 'Bu Haftaki Puan',
          puan: buhaftakipuan,
          baslikHedef: 'Bu Haftaki Hedef',
          hedef: buhaftakihedef, // ✅ BUG FIX: eskiden buhaftakipuan yazıyordu
          onDetay: () => detayagit('H'),
        ),
        _puanKart(
          context: context,
          baslikPuan: 'Bu Ayki Puan',
          puan: buaykipuan,
          baslikHedef: 'Bu Ayki Hedef',
          hedef: buaykihedef,
          onDetay: () => detayagit('A'),
        ),
      ],
    );
  }

  Widget _puanKart({
    required BuildContext context,
    required String baslikPuan,
    required double puan,
    required String baslikHedef,
    required double hedef,
    required VoidCallback onDetay,
  }) {
    return Expanded(
      flex: 1,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$baslikPuan : ${puan.toInt()}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 30),
            Text(
              '$baslikHedef : ${hedef.toInt()}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade500,
              ),
              onPressed: onDetay,
              child: const Text(
                'Detaya Git',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
