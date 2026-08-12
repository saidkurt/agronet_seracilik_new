import 'package:agronet/page/Bitki_yerleri.dart';
import 'package:agronet/page/Depodurumraporu.dart';
import 'package:agronet/page/PaletlemeRaporu.dart';
import 'package:agronet/page/barkod_kontrol.dart';
import 'package:agronet/page/beyaz_sinek_giris_page.dart';
import 'package:agronet/page/depo_talep_onay.dart';
import 'package:agronet/page/hasat_raporu.dart';
import 'package:agronet/page/iskontrol/konrol_home.dart';
import 'package:agronet/page/paketleme.dart';
import 'package:agronet/page/paketleme_raporu.dart';
import 'package:agronet/page/personel_anlik_durum.dart';
import 'package:agronet/page/sera_is_tarihleri.dart';
import 'package:agronet/page/tuta_giris.dart';
import 'package:agronet/page/tuta_rapor.dart';
import 'package:agronet/widget/profile_header.dart';

import 'package:flutter/material.dart';
import 'package:agronet/models/login_user_model.dart';

class HomeMenuPage extends StatelessWidget {
  final LoginUserModel user;

  const HomeMenuPage({
    super.key,
    required this.user,
  });

  static const Color accent = Color(0xFF1E6F5C);
  static const Color background = Color(0xFFF5F6F8);

  String _roleLabel() {
    if (user.yonetimraporlarigorebilir) {
      return "Yönetici";
    }

    if (user.danismanraporlari) {
      return "Danışman";
    }

    if (user.kontrolcuraporlarigorebilir) {
      return "Kontrol";
    }

    if (user.depopaketleme ||
        user.deporaporlarinigorebilir) {
      return "Depo";
    }

    if (user.seraraporlarigorebilir) {
      return "Seracı";
    }

    final t = (user.tip ?? "").trim();

    return t.isEmpty
        ? "Kullanıcı"
        : t;
  }

  @override
  Widget build(BuildContext context) {
    final ts = MediaQuery.textScalerOf(context);

    final safeScaler = ts.clamp(
      maxScaleFactor: 1.06,
    );

    // ============================================================
    // OPERASYON
    // ============================================================

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
                personelKodu:
                    user.kullanicikodu ?? "",
                personelAdi:
                    user.kullaniciadi ?? "",
              ),
            ),
          );
        },
      ),

      _MenuItem(
        title: "Döngü Kontrol",
        icon: Icons.repeat_rounded,
        visible: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DonguKontrolPage(
                personelKodu:
                    user.kullanicikodu ?? "",
                kullaniciId:
                    user.oturumId ?? 0,
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TutaGirisPage(
                personelKodu:
                    user.kullanicikodu ?? "",
              ),
            ),
          );
        },
      ),

      _MenuItem(
        title: "Bitki Ölçüm Giriş",
        icon: Icons.straighten_rounded,
        visible: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  BitkiOlcumSahaSayfa(
                personelKodu:
                    user.kullanicikodu ?? "",
                personelAdi:
                    user.kullaniciadi ?? "",
              ),
            ),
          );
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
              builder: (_) =>
                  BeyazSinekGirisPage(
                personelKodu:
                    user.kullanicikodu ?? "",
              ),
            ),
          );
        },
      ),
    ];

    // ============================================================
    // DEPO
    // ============================================================

    final depoItems = <_MenuItem>[
      _MenuItem(
        title: "Paketleme",
        icon: Icons.inventory_2_rounded,
        visible: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Paketleme(
                personelkodu:
                    user.kullanicikodu ?? "",
                personelAdi:
                    user.kullaniciadi ?? "",
              ),
            ),
          );
        },
      ),

      _MenuItem(
        title: "Depo Talep Onay",
        icon: Icons.fact_check_rounded,
        visible: true,
        onTap: () {
          if (!user.oturumGecerli) {
            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  "Mobil oturum bilgisi bulunamadı. Tekrar giriş yapın.",
                ),
              ),
            );

            return;
          }

          final kullaniciKodu =
              user.depoKullaniciKodu.trim();

          if (kullaniciKodu.isEmpty) {
            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  "Mikro kullanıcı kodu bulunamadı.",
                ),
              ),
            );

            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DepoTalepOnayPage(
                kullaniciKodu:
                    kullaniciKodu,
                oturumId:
                    user.oturumId ?? 0,
                token:
                    user.token ?? '',
              ),
            ),
          );
        },
      ),

      _MenuItem(
        title: "Barkod Kontrol",
        icon: Icons.qr_code_scanner_rounded,
        visible: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  KoliBarkodPage(),
            ),
          );
        },
      ),
    ];

    // ============================================================
    // RAPORLAR
    // ============================================================

    final raporItems = <_MenuItem>[
      _MenuItem(
        title: "Paletleme Raporu",
        icon: Icons.view_in_ar_rounded,
        visible: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PaletlemeRaporPage(),
            ),
          );
        },
      ),

      _MenuItem(
        title: "Paketleme Raporları",
        icon: Icons.receipt_long_rounded,
        visible: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PaketlemeRaporPage(),
            ),
          );
        },
      ),

      _MenuItem(
        title: "Hasat Raporu",
        icon: Icons.agriculture_rounded,
        visible: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  HasatRaporuDetayliPage(),
            ),
          );
        },
      ),

      _MenuItem(
        title: "Tuta Raporu",
        icon: Icons.bug_report_outlined,
        visible: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TutaRaporPage(),
            ),
          );
        },
      ),

      _MenuItem(
        title: "Personel Anlık Durum",
        icon: Icons.person_search_outlined,
        visible: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const PersonelAnlikDurumPage(),
            ),
          );
        },
      ),

      _MenuItem(
        title: "Depo Durum Raporu",
        icon: Icons.warehouse_rounded,
        visible: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DepodurumRaporu(
                personeladi:
                    user.kullaniciadi ?? "",
              ),
            ),
          );
        },
      ),
    ];

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: safeScaler,
      ),
      child: Scaffold(
        backgroundColor: background,

        // ========================================================
        // APP BAR
        // ========================================================

        appBar: AppBar(
          toolbarHeight: 48,
          title: const Text(
            "Agronet Seracılık A.Ş",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          elevation: 0,
        ),

        // ========================================================
        // BODY
        // ========================================================

        body: ListView(
          physics:
              const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            9,
            7,
            9,
            12,
          ),
          children: [
            // ====================================================
            // PROFİL
            // ====================================================

            ProfileCard(
              user: user,
              role: _roleLabel(),
            ),

            const SizedBox(height: 8),

            // ====================================================
            // OPERASYON
            // ====================================================

            _SectionRow(
              title: "Operasyon",
              icon:
                  Icons.settings_suggest_outlined,
              items: operasyonItems
                  .where((e) => e.visible)
                  .toList(),
            ),

            const SizedBox(height: 8),

            // ====================================================
            // DEPO
            // ====================================================

            _SectionRow(
              title: "Depo",
              icon: Icons.warehouse_outlined,
              items: depoItems
                  .where((e) => e.visible)
                  .toList(),
            ),

            const SizedBox(height: 8),

            // ====================================================
            // RAPORLAR
            // ====================================================

            _SectionRow(
              title: "Raporlar",
              icon:
                  Icons.analytics_outlined,
              items: raporItems
                  .where((e) => e.visible)
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BÖLÜM
// ============================================================================

class _SectionRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_MenuItem> items;

  const _SectionRow({
    required this.title,
    required this.icon,
    required this.items,
  });

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        9,
        7,
        9,
        8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color:
              Colors.black.withOpacity(.05),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          // ======================================================
          // BAŞLIK
          // ======================================================

          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color:
                      accent.withOpacity(.08),
                  borderRadius:
                      BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 13,
                  color: accent,
                ),
              ),

              const SizedBox(width: 6),

              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight:
                      FontWeight.w900,
                  color: Colors.black
                      .withOpacity(.57),
                ),
              ),

              const Spacer(),

              Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 9.5,
                  color: Colors.black
                      .withOpacity(.30),
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ======================================================
          // YATAY MENÜ
          // ======================================================

          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              physics:
                  const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) {
                return const SizedBox(
                  width: 6,
                );
              },
              itemBuilder:
                  (context, index) {
                return SizedBox(
                  width: 126,
                  child: _MenuCard(
                    item: items[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MENÜ KARTI
// ============================================================================

class _MenuCard extends StatelessWidget {
  final _MenuItem item;

  const _MenuCard({
    required this.item,
  });

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7F9),
      borderRadius:
          BorderRadius.circular(10),
      child: InkWell(
        onTap: item.onTap,
        borderRadius:
            BorderRadius.circular(10),
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            8,
            7,
            7,
            6,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(10),
            border: Border.all(
              color: Colors.black
                  .withOpacity(.045),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // ÜST
              // ==================================================

              Row(
                children: [
                  Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      color: accent
                          .withOpacity(.09),
                      borderRadius:
                          BorderRadius.circular(
                              7),
                    ),
                    child: Icon(
                      item.icon,
                      size: 14,
                      color: accent,
                    ),
                  ),

                  const Spacer(),

                  Icon(
                    Icons
                        .chevron_right_rounded,
                    size: 15,
                    color: Colors.black
                        .withOpacity(.25),
                  ),
                ],
              ),

              const Spacer(),

              // ==================================================
              // BAŞLIK
              // ==================================================

              Text(
                item.title,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.05,
                  fontWeight:
                      FontWeight.w900,
                  color: Colors.black
                      .withOpacity(.82),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MODEL
// ============================================================================

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