import 'package:agronet/page/DrawerPage/Depodurumraporu.dart';
import 'package:agronet/page/DrawerPage/PaletlemeRaporu.dart';
import 'package:agronet/page/DrawerPage/paketleme.dart';
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
        title: "Hızlı İş Tanım",
        icon: Icons.flash_on_rounded,
        visible: true,
        onTap: () {
          // TODO: Navigator.push(...)
        },
      ),
      _MenuItem(
        title: "Ölçüm Giriş",
        icon: Icons.straighten_rounded,
        visible: true,
        onTap: () {},
      ),
      _MenuItem(
        title: "Arıza Giriş",
        icon: Icons.report_gmailerrorred_rounded,
        visible: true,
        onTap: () {},
      ),
    ];

    final depoItems = <_MenuItem>[
      _MenuItem(
        title: "Paketleme",
        icon: Icons.inventory_2_rounded,
        visible: user.depopaketleme,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  Paketleme(personelkodu: user.kullanicikodu ?? "")));
        },
      ),
      _MenuItem(
        title: "Depo Talep",
        icon: Icons.playlist_add_check_circle_rounded,
        visible: true,
        onTap: () {},
      ),
   
    ];

    final raporItems = <_MenuItem>[
      _MenuItem(
        title: "Paketleme Raporları",
        icon: Icons.receipt_long_rounded,
        visible: user.deporaporlarinigorebilir || user.yonetimraporlarigorebilir,
        onTap: () {},
      ),
      _MenuItem(
        title: "Sera Raporları",
        icon: Icons.spa_rounded,
        visible: user.seraraporlarigorebilir || user.yonetimraporlarigorebilir,
        onTap: () {},
      ),
         _MenuItem(
        title: "Paletleme Raporu",
        icon: Icons.qr_code_scanner_rounded,
        visible: user.deporaporlarinigorebilir || user.depopaketleme,
             onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  PaletlemeRaporPage()));
        },
      ),
      _MenuItem(
        title: "Depo Durum Raporu",
        icon: Icons.warehouse_rounded,
        visible: user.deporaporlarinigorebilir,
            onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  DepodurumRaporu(personelkodu: user.kullanicikodu ?? "",)));
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
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFFF7F7F9),
          border: Border.all(color: Colors.black.withOpacity(.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withOpacity(.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: accent.withOpacity(.92)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withOpacity(.86),
                  height: 1.1,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.black.withOpacity(.35)),
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