import 'package:agronet/api/serabarkodislistesi_api.dart';
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
  final String? isimsoyisim;
  final String? bileklikno;
  final bool? seraci;
  final bool? deporaporlarinigorebilir;
  final bool? kontrolcu;
  final bool? yonetici;
  final bool? danismanraporlari;
  final String? personelkodu;
  final String? tip;
  final bool? depopaketleme;


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
  // -------------------- Existing helpers (UNCHANGED) --------------------
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
                  message ??
                      (App().drawerPageString["progressDialogmessage"] ??
                          "Lütfen bekleyin..."),
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
          title: Center(
              child: Text(msg, style: const TextStyle(color: Colors.white))),
        );
      },
    );
  }

  // -------------------- New UI helpers (Drawer only) --------------------

  String _roleLabel() {
    if ((widget.yonetici ?? false)) return "Yönetici";
    if ((widget.danismanraporlari ?? false)) return "Danışman";
    if ((widget.kontrolcu ?? false)) return "Kontrol";
    if ((widget.depopaketleme ?? false) ||
        (widget.deporaporlarinigorebilir ?? false)) return "Depo";
    if ((widget.seraci ?? false)) return "Seracı";
    final t = (widget.tip ?? "").trim();
    return t.isEmpty ? "Kullanıcı" : t;
  }

  Widget _miniPill(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.brown.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.brown.shade700),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerHeader() {
    final name = (widget.isimsoyisim ?? "").trim();
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : "A";
    final tipText = (widget.tip ?? "").trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0x11000000), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.brown.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.brown.shade200),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.brown.shade800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? "Kullanıcı" : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  tipText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _miniPill(_roleLabel(), icon: Icons.verified_user_outlined),
                    if ((widget.personelkodu ?? "").trim().isNotEmpty)
                      _miniPill("Personel: ${widget.personelkodu}",
                          icon: Icons.badge_outlined),
                    if ((widget.bileklikno ?? "").trim().isNotEmpty)
                      _miniPill("Bileklik: ${widget.bileklikno}",
                          icon: Icons.watch_outlined),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
          color: Colors.black.withOpacity(0.45),
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool visible = true,
    bool active = false,
  }) {
    if (!visible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Material(
        color: active ? Colors.brown.shade50 : Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.brown.shade100),
                  ),
                  child: Icon(icon, color: Colors.brown.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.black.withOpacity(0.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _softDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 1,
        color: Colors.black.withOpacity(0.06),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // “aktif sayfa” istiyorsan burada route’a göre aktifleştirebilirsin.
    // Şimdilik hepsi false (kırmasın diye).
    const bool activeNone = false;

    return Scaffold(
      appBar:AppBar(
  title: const Text("Agronet Seracılık A.Ş"),
  centerTitle: true,
),
      body: GirisSayfaMerkez(
        tip: widget.tip ?? "",
        bileklik: widget.bileklikno ?? "",
        yonetici: (widget.yonetici ?? false) ||
            (widget.danismanraporlari ?? false) ||
            (widget.kontrolcu ?? false),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: ListView(
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            children: <Widget>[
              _drawerHeader(),

              // -------------------- OPERASYON --------------------
              _sectionTitle("Operasyon"),

              _drawerItem(
                icon: App().drawerPageIcon["paketleme"] ?? Icons.inventory_2_outlined,
                title: App().drawerPageString["paketlemeDrawerPageTitle"] ?? "Paketleme",
                visible: (widget.deporaporlarinigorebilir ?? false) ||
                    (widget.yonetici ?? false) ||
                    (widget.depopaketleme ?? false),
                active: activeNone,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          Paketleme(personelkodu: widget.personelkodu ?? ""),
                    ),
                  );
                },
              ),

                 _drawerItem(
                icon: Icons.spa_outlined,
                title: App().drawerPageString["bitkiOlcumGiris"] ?? "Bitki Ölçüm Girişi",
                visible: (widget.yonetici ?? false) || (widget.danismanraporlari ?? false),
                active: activeNone,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BitkiOlcumSahaSayfa(personelKodu: widget.personelkodu ?? ""),
                    ),
                  );
                },
              ),

              _drawerItem(
                icon: App().drawerPageIcon["kutuEkle"] ?? Icons.add_box_outlined,
                title: App().drawerPageString["kutuekleDrawerTitle"] ?? "Kutu Ekle",
                visible: (widget.tip == "Hasat ekip") || (widget.yonetici ?? false),
                active: activeNone,
                onTap: () async {
                  _showLoading("Kontrol ediliyor...");
                  try {
                    seraBarkoDIsListesi =
                        await SeraBarkodListesiApi().seraBarkodListesi(
                      personelKodu: widget.personelkodu ?? "",
                    );
                    _hideLoading();

                    if (!mounted) return;

                    if (seraBarkoDIsListesi.isEmpty) {
                      await _toastDialog(
                        App().drawerPageString["kutuekleShowMessage"] ??
                            "Kayıt bulunamadı",
                        seconds: 2,
                      );
                      return;
                    }

                    // Not: Sen burada devamında ne açıyorsan aynı şekilde ekleyebilirsin.
                    // Şu an senin attığın kodda bu kısım zaten yarım kalıyordu.
                  } catch (e) {
                    _hideLoading();
                    await _toastDialog("Hata: $e", seconds: 2);
                  }
                },
              ),

              _softDivider(),

              // -------------------- RAPORLAR --------------------
              _sectionTitle("Raporlar"),

              _drawerItem(
                icon: Icons.corporate_fare_outlined,
                title: App().drawerPageString["paletlemeRaporuPageTitle"] ?? "Paletleme Raporu",
                visible: (widget.yonetici ?? false) || (widget.danismanraporlari ?? false),
                active: activeNone,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PaletlemeRaporPage()),
                  );
                },
              ),

           

              _drawerItem(
                icon: Icons.receipt_long_outlined,
                title: App().drawerPageString["paketlemeRapor"] ?? "Paketleme Raporu",
                visible: (widget.yonetici ?? false) || (widget.danismanraporlari ?? false),
                active: activeNone,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PaketlemeRaporPage()),
                  );
                },
              ),

              _drawerItem(
                icon: App().drawerPageIcon["depoDurumu"] ?? Icons.warehouse_outlined,
                title: App().drawerPageString["depoDurumRaporuPageTitle"] ?? "Depo Durum Raporu",
                visible: (widget.yonetici ?? false) || (widget.deporaporlarinigorebilir ?? false),
                active: activeNone,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DepodurumRaporu(personelkodu: widget.personelkodu ?? ""),
                    ),
                  );
                },
              ),

              _softDivider(),

              // -------------------- PERSONEL --------------------
              _sectionTitle("Personel"),

              _drawerItem(
                icon: App().drawerPageIcon["mesaiDurumu"] ?? Icons.timer_outlined,
                title: App().drawerPageString["mesaiDurumuPageTitle"] ?? "Mesai Durumu",
                visible: (widget.seraci ?? false) ||
                    (widget.kontrolcu ?? false) ||
                    (widget.deporaporlarinigorebilir ?? false),
                active: activeNone,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PersonelMesai(
                        bileklikno_1: widget.bileklikno ?? "",
                      ),
                    ),
                  );
                },
              ),

              _drawerItem(
                icon: App().drawerPageIcon["personelBilgileri"] ?? Icons.people_alt_outlined,
                title: App().drawerPageString["personelBilgileriPageTitle"] ?? "Personel Bilgileri",
                visible: widget.yonetici ?? false,
                active: activeNone,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PersonelBilgileri(personelId: widget.personelkodu ?? ""),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}