import 'package:agronet/page/Bitki_yerleri.dart';
import 'package:agronet/page/Depodurumraporu.dart';
import 'package:agronet/page/PaletlemeRaporu.dart';
import 'package:agronet/page/barkod_kontrol.dart';
import 'package:agronet/page/beyaz_sinek_giris_page.dart';
import 'package:agronet/page/hasat_raporu.dart';
import 'package:agronet/page/iskontrol/konrol_home.dart';
import 'package:agronet/page/paketleme.dart';
import 'package:agronet/page/paketleme_raporu.dart';
import 'package:agronet/page/personel_anlik_durum.dart';
import 'package:agronet/page/tuta_giris.dart';
import 'package:agronet/page/tuta_rapor.dart';
import 'package:agronet/widget/profile_header.dart';
import 'package:flutter/material.dart';
import 'package:agronet/models/login_user_model.dart';

class HomeMenuPage extends StatelessWidget {
  final LoginUserModel user;
  const HomeMenuPage({super.key, required this.user});

  static const accent = Color(0xFF1E6F5C);

  // Rol label: senin öncelik kuralına göre
  String _roleLabel() {
    if (user.yonetimraporlarigorebilir) return "Yönetici";
    if (user.danismanraporlari) return "Danışman";
    if (user.kontrolcuraporlarigorebilir) return "Kontrol";
    if (user.depopaketleme || user.deporaporlarinigorebilir) return "Depo";
    if (user.seraraporlarigorebilir) return "Seracı";
    final t = (user.tip ?? "").trim();
    return t.isEmpty ? "Kullanıcı" : t;
  }

  @override
  Widget build(BuildContext context) {
    // Yazı büyütme yüzünden bozulmasın
    final ts = MediaQuery.textScalerOf(context);
    final safeScaler = ts.clamp(maxScaleFactor: 1.10);

    final operasyonItems = <_MenuItem>[
     
      _MenuItem(
  title: "Kontrol",
  icon: Icons.fact_check_rounded,
  visible: true,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KontrolPage(
          personelKodu: user.kullanicikodu ?? "",
          personelAdi: user.kullaniciadi ?? "",
        ),
      ),
    );
  },
),
  
          _MenuItem(
        title: "Tuta Sayımı",
      icon: Icons.bug_report_rounded,
        visible: true,
       onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  TutaGirisPage(personelKodu: user.kullanicikodu ?? " ")));
        },
        ),
        _MenuItem(
  title: "Beyaz Sinek Sayımı",
  icon: Icons.pest_control_rounded,
  visible: true,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BeyazSinekGirisPage(
          personelKodu: user.kullanicikodu ?? "",
        ),
      ),
    );
  },
),
    ];

    final depoItems = <_MenuItem>[
      _MenuItem(
        title: "Paketleme",
        icon: Icons.inventory_2_rounded,
        visible: true,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  Paketleme(personelkodu: user.kullanicikodu ?? "",personelAdi: user.kullaniciadi ?? "",)));
        },
      ),
       _MenuItem(
        title: "Barkod Kontrol",
        icon: Icons.qr_code_scanner_rounded,
        visible: true,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  KoliBarkodPage()));
        },
      )
    ];

    final raporItems = <_MenuItem>[
       _MenuItem(
        title: "Paletleme Raporu",
        icon: Icons.qr_code_scanner_rounded,
        visible:true,
             onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  PaletlemeRaporPage()));
        },
      ),
      _MenuItem(
        title: "Paketleme Raporları",
        icon: Icons.receipt_long_rounded,
        visible: true,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  PaketlemeRaporPage()));
        },
      ),
        _MenuItem(
        title: "Hasat Raporu",
        icon: Icons.qr_code_scanner_rounded,
        visible: true,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  HasatRaporuDetayliPage()));
        },
      ),
         _MenuItem(
        title: "Tuta Raporu",
        icon: Icons.bug_report_outlined,
        visible: true,
             onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  TutaRaporPage()));
        },
      ),
        
      _MenuItem(
        title: "Personel Anlık Durum",
        icon: Icons.person_3_outlined,
        visible: true,
            onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PersonelAnlikDurumPage()),
  );
},
      ),
      _MenuItem(
        title: "Depo Durum Raporu",
        icon: Icons.warehouse_rounded,
        visible:true,
            onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  DepodurumRaporu(personeladi: user.kullaniciadi ?? "",)));
        },
      ),
    ];

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: safeScaler),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        appBar: AppBar(
          title: const Text("Agronet Seracılık A.Ş"),
          centerTitle: true,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
          children: [
            ProfileCard(
              user: user,
              role: _roleLabel(),
            ),
            const SizedBox(height: 14),

            _SectionRow(
              title: "Operasyon",
              items: operasyonItems.where((e) => e.visible).toList(),
            ),
            const SizedBox(height: 14),

            _SectionRow(
              title: "Depo",
              items: depoItems.where((e) => e.visible).toList(),
            ),
            const SizedBox(height: 14),

            _SectionRow(
              title: "Raporlar",
              items: raporItems.where((e) => e.visible).toList(),
            ),
          ],
        ),
      ),
    );
  }
}



class _SectionRow extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _SectionRow({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık: küçük + sağda
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.black.withOpacity(.55),
                letterSpacing: .2,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Yatay kayan menü
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 2),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                // Kartların biraz daha "kaydırılabilir" hissettirmesi için genişliği sabit
                return SizedBox(
                  width: 168,
                  child: _MenuCard(item: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  static const accent = Colors.green;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFFF7F7F9),
          border: Border.all(color: Colors.black.withOpacity(.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // üst satır: icon + ok
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: accent.withOpacity(.92)),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: Colors.black.withOpacity(.35)),
              ],
            ),
            const SizedBox(height: 10),

            // başlık: geniş alan + 2 satır düzgün
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.black.withOpacity(.86),
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _MenuItem {
  final String title;
  final IconData icon;
  final bool visible;
  final VoidCallback onTap;

  _MenuItem({
    required this.title,
    required this.icon,
    required this.visible,
    required this.onTap,
  });
}