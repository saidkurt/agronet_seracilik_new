import 'package:agronet/api/kututipi_api.dart';
import 'package:agronet/api/palet_tipi.dart';
import 'package:agronet/api/serabarkodislistesi_api.dart';
import 'package:agronet/api/stok_adlari_api.dart';
import 'package:agronet/comp/appbar.dart';
import 'package:agronet/const/string.dart';
import 'package:agronet/page/DrawerPage/BitkiOlcumGiris/Bitki_yerleri.dart';
import 'package:agronet/page/DrawerPage/Depodurumraporu.dart';

import 'package:agronet/page/DrawerPage/PaletlemeRaporu.dart';
import 'package:agronet/page/DrawerPage/Personelmesai.dart';
import 'package:agronet/page/DrawerPage/paketleme.dart';
import 'package:agronet/page/DrawerPage/paketleme_raporu.dart';
import 'package:agronet/page/DrawerPage/personelbilgileri.dart';
import 'package:agronet/page/HomePage/AnasayfaView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class DrawerPageView extends StatefulWidget {
  final String ? isimsoyisim;
  final String ? bileklikno;
  final bool ? seraci;
  final bool ? deporaporlarinigorebilir;
  final bool ? kontrolcu;
  final bool ? yonetici;
  final bool ? danismanraporlari;
  final String  ?personelkodu;
  final String ? tip;
  final bool ? depopaketleme;

  const DrawerPageView({
    super.key,
     this.isimsoyisim,
     this.bileklikno,
     this.seraci,
     this.deporaporlarinigorebilir,
     this.kontrolcu,
     this.yonetici,
     this.danismanraporlari,
     this.tip,
     this.depopaketleme,
     this.personelkodu,
  });

  @override
  State<DrawerPageView> createState() => _DrawerPageViewState();
}

List seraBarkoDIsListesi = [];

class _DrawerPageViewState extends State<DrawerPageView> {
  void _showLoading([String? message]) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: Colors.brown.shade500,
          content: Row(
            children: [
              const SpinKitCircle(color: Colors.white, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message ?? (App().drawerPageString["progressDialogmessage"] ?? "Lütfen bekleyin..."),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _hideLoading() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _toastDialog(String msg, {int seconds = 2}) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        Future.delayed(Duration(seconds: seconds), () {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        });
        return AlertDialog(
          backgroundColor: Colors.brown.withOpacity(0.9),
          title: Center(child: Text(msg, style: const TextStyle(color: Colors.white))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBarCustomAppBar(context),
      body: GirisSayfaMerkez(
        tip: widget.tip ?? "",
        bileklik: widget.bileklikno ?? "",
        yonetici: (widget.yonetici ?? false) || (widget.danismanraporlari ?? false) || (widget.kontrolcu ?? false),
      ),
      drawer: Drawer(
        child: ListView(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown.shade500, Colors.black],
                  stops: const [0.5, 1.0],
                ),
              ),
              height: MediaQuery.of(context).size.height / 4.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isimsoyisim ?? "",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.tip ?? "",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.65)),
                  ),
                ],
              ),
            ),

            // Paketleme
            Visibility(
              visible: (widget.deporaporlarinigorebilir ?? false) || (widget.yonetici ?? false) || (widget.depopaketleme ?? false),
              child: ListTile(
                leading: Icon(App().drawerPageIcon["paketleme"], color: Colors.brown.shade500),
                title: Text(App().drawerPageString["paketlemeDrawerPageTitle"] ?? "Paketleme"),
                onTap: ()  {
                   Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Paketleme(personelkodu: widget.personelkodu ?? "")),
                    );
                },
              ),
            ),

            // Kutu Ekle  ✅ visible düzeltildi
            Visibility(
              visible: (widget.tip == "Hasat ekip") || (widget.yonetici ?? false),
              child: ListTile(
                leading: Icon(App().drawerPageIcon["kutuEkle"], color: Colors.brown.shade500),
                title: Text(App().drawerPageString["kutuekleDrawerTitle"] ?? "Kutu Ekle"),
                onTap: () async {
                  _showLoading("Kontrol ediliyor...");
                  try {
                    seraBarkoDIsListesi = await SeraBarkodListesiApi().seraBarkodListesi(personelKodu: widget.personelkodu ?? "");
                    _hideLoading();

                    if (!mounted) return;

                    if (seraBarkoDIsListesi.isEmpty) {
                      await _toastDialog(App().drawerPageString["kutuekleShowMessage"] ?? "Kayıt bulunamadı", seconds: 2);
                      return;
                    }

            
                  } catch (e) {
                    _hideLoading();
                    await _toastDialog("Hata: $e", seconds: 2);
                  }
                },
              ),
            ),

            // Personel Bilgileri
            Visibility(
              visible: widget.yonetici ??  false,
              child: ListTile(
                title: Text(App().drawerPageString["personelBilgileriPageTitle"] ?? "Personel Bilgileri"),
                leading: Icon(App().drawerPageIcon["personelBilgileri"], color: Colors.brown.shade500),
                onTap: () async {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PersonelBilgileri(personelId: widget.personelkodu ?? "")));
                },
              ),
            ),

            // Paletleme Raporu
            Visibility(
              visible: (widget.yonetici ?? false) || (widget.danismanraporlari ?? false),
              child: ListTile(
                title: Text(App().drawerPageString["paletlemeRaporuPageTitle"] ?? "Paletleme Raporu"),
                leading: Icon(Icons.corporate_fare_outlined, color: Colors.brown.shade500),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) =>PaletlemeRaporPage()),
                  );
                },
              ),
            ),
               Visibility(
              visible: (widget.yonetici ?? false) || (widget.danismanraporlari ?? false),
              child: ListTile(
                title: Text(App().drawerPageString["bitkiOlcumGiris"] ?? "Paletleme Raporu"),
                leading: Icon(Icons.corporate_fare_outlined, color: Colors.brown.shade500),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BitkiOlcumSahaSayfa(personelKodu: widget.personelkodu ?? "")),
                  );
                },
              ),
            ),
                   Visibility(
              visible: (widget.yonetici ?? false) || (widget.danismanraporlari ?? false),
              child: ListTile(
                title: Text(App().drawerPageString["paketlemeRapor"] ?? "Paletleme Raporu"),
                leading: Icon(Icons.corporate_fare_outlined, color: Colors.brown.shade500),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) =>PaketlemeRaporPage()),
                  );
                },
              ),
            ),





            // Mesai Durumu
            Visibility(
              visible: (widget.seraci ?? false) ||
         (widget.kontrolcu ?? false) ||
         (widget.deporaporlarinigorebilir ?? false),

              child: ListTile(
                title: Text(App().drawerPageString["mesaiDurumuPageTitle"] ?? "Mesai Durumu"),
                leading: Icon(App().drawerPageIcon["mesaiDurumu"], color: Colors.brown.shade500),
                onTap: ()  {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PersonelMesai(bileklikno_1: widget.bileklikno ?? "")));
                },
              ),
            ),

            // Kutu Bilgileri
          
            // Depo Durum Raporu
            Visibility(
              visible: (widget.yonetici ?? false) || (widget.deporaporlarinigorebilir ?? false),
              child: ListTile(
                title: Text(App().drawerPageString["depoDurumRaporuPageTitle"] ?? "Depo Durum Raporu"),
                leading: Icon(App().drawerPageIcon["depoDurumu"], color: Colors.brown.shade500),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DepodurumRaporu(personelkodu: widget.personelkodu ?? ""),
                    ),
                  );
                },
              ),
            ),

            // Dilek ve Şikayet
          

            // Mesaj Gönder
            
          ],
        ),
      ),
    );
  }
}
