import 'package:agronet/page/Bitki_yerleri.dart';
import 'package:agronet/page/Depodurumraporu.dart';
import 'package:agronet/page/PaletlemeRaporu.dart';
import 'package:agronet/page/barkod_kontrol.dart';
import 'package:agronet/page/beyaz_sinek_giris_page.dart';
import 'package:agronet/page/depo_talep_fis.dart';
import 'package:agronet/page/depo_talep_onay.dart';
import 'package:agronet/page/hasat_raporu.dart';
import 'package:agronet/page/iskontrol/konrol_home.dart';
import 'package:agronet/page/operasyon/operasyon_panel.dart';
import 'package:agronet/page/mobil_menu_yetki_page.dart';
import 'package:agronet/page/paketleme.dart';
import 'package:agronet/page/paketleme_raporu.dart';
import 'package:agronet/page/personel_anlik_durum.dart';
import 'package:agronet/page/personel_listesi_page.dart';
import 'package:agronet/page/sarf_et_page.dart';
import 'package:agronet/page/sera_is_tarihleri.dart';
import 'package:agronet/page/sera_kontrol_rapor.dart';
import 'package:agronet/page/seraa_olcum_giris.dart';
import 'package:agronet/page/tuta_giris.dart';
import 'package:agronet/page/tuta_rapor.dart';
import 'package:agronet/services/bildirim_navigation_service.dart';
import 'package:agronet/services/update_service.dart';
import 'package:agronet/widget/profile_header.dart';

import 'package:flutter/material.dart';
import 'package:agronet/models/login_user_model.dart';

import 'package:onesignal_flutter/onesignal_flutter.dart';

class HomeMenuPage extends StatefulWidget {
  final LoginUserModel user;

  const HomeMenuPage({
    super.key,
    required this.user,
  });

  @override
  State<HomeMenuPage> createState() =>
      _HomeMenuPageState();
}

class _HomeMenuPageState extends State<HomeMenuPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color background = Color(0xFFF5F6F8);

  int _seciliMenu = 0;

  LoginUserModel get user => widget.user;

  // ============================================================
  // INIT
  // ============================================================

@override
void initState() {
  super.initState();

  BildirimNavigationService.kullaniciAyarla(
    user,
  );

  _oneSignalKullaniciBagla();

  WidgetsBinding.instance.addPostFrameCallback(
    (_) {
      _guncellemeKontrolEt();
    },
  );
}
Future<void> _guncellemeKontrolEt() async {
  try {
    await UpdateService.cihazKaydet(
      personelKodu: user.bsrKullaniciKodu,
    );
  } catch (e) {
    debugPrint(
      'Cihaz kayıt hatası: $e',
    );
  }

  if (!mounted) return;

  try {
    await UpdateService.guncellemeKontrolEt(
      context,
    );
  } catch (e) {
    debugPrint(
      'Güncelleme kontrol hatası: $e',
    );
  }
}
  // ============================================================
  // ONESIGNAL KULLANICI BAĞLAMA
  // ============================================================

 Future<void> _oneSignalKullaniciBagla() async {
  final prosisKodu =
      (user.prosiskodu ?? '').trim();

  if (prosisKodu.isEmpty) {
    debugPrint(
      'OneSignal: ProsisKodu boş. Kullanıcı bağlanmadı.',
    );
    return;
  }

  try {
    await OneSignal.login(
      prosisKodu,
    );

    debugPrint(
      'OneSignal kullanıcı bağlandı: $prosisKodu',
    );
  } catch (e) {
    debugPrint(
      'OneSignal kullanıcı bağlama hatası: $e',
    );
  }
}

  // ============================================================
  // ROL
  // ============================================================

  String _roleLabel() {
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
        visible: user.yetkisiVar("KONTROL"),
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
        title: "Ölçüm Giriş",
        icon: Icons.monitor_weight_outlined,
        visible: user.yetkisiVar("OLCUM_GIRIS"),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SeraOlcumGirisSayfa(
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
        visible:
            user.yetkisiVar("DONGU_KONTROL"),
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
        visible:
            user.yetkisiVar("TUTA_SAYIMI"),
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
        visible:
            user.yetkisiVar("BITKI_OLCUM"),
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
        visible:
            user.yetkisiVar("BEYAZ_SINEK"),
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
        visible: user.yetkisiVar("PAKETLEME"),
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
  title: "Depo Talep Fişi",
  icon: Icons.playlist_add_rounded,
  visible: user.yetkisiVar("DEPO_TALEP_FISI"),
  onTap: () {
    // Mobil oturum kontrolü
    if (!user.oturumGecerli) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Mobil oturum bilgisi bulunamadı. "
            "Tekrar giriş yapın.",
          ),
        ),
      );
      return;
    }

    // ========================================================
    // ÖNEMLİ:
    // Burada artık depoKullaniciKodu kullanılmıyor.
    // Gerçek Prosis personel kodu kullanılıyor.
    //
    // Örnek:
    // P0024
    // P0036
    // P0160
    // ========================================================

    final kullaniciKodu =
        (user.prosiskodu ?? '').trim();

    if (kullaniciKodu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Prosis kullanıcı kodu bulunamadı. "
            "Tekrar giriş yapın.",
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepoTalepFisiPage(
          kullaniciKodu: kullaniciKodu,
          oturumId: user.oturumId ?? 0,
          token: user.token ?? '',
        ),
      ),
    );
  },
),

_MenuItem(
  title: "Sarf Et",
  icon: Icons.remove_shopping_cart_rounded,
  visible: user.yetkisiVar("SARF_ET"),
  onTap: () {
    if (!user.oturumGecerli) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Mobil oturum bilgisi bulunamadı. "
            "Tekrar giriş yapın.",
          ),
        ),
      );
      return;
    }

    final kullaniciKodu =
        (user.prosiskodu ?? '').trim();

    if (kullaniciKodu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Prosis kullanıcı kodu bulunamadı. "
            "Tekrar giriş yapın.",
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SarfEtPage(
          kullaniciKodu: kullaniciKodu,
          oturumId: user.oturumId ?? 0,
          token: user.token ?? '',
        ),
      ),
    );
  },
),

_MenuItem(
  title: "Depo Talep Onay",
  icon: Icons.fact_check_rounded,
  visible: user.yetkisiVar("DEPO_TALEP"),
  onTap: () {
    // Mobil oturum kontrolü
    if (!user.oturumGecerli) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Mobil oturum bilgisi bulunamadı. "
            "Tekrar giriş yapın.",
          ),
        ),
      );
      return;
    }

    // ========================================================
    // Onay işlemlerinde de gerçek Prosis kodu gönderiliyor.
    // ========================================================

    final kullaniciKodu =
        (user.prosiskodu ?? '').trim();

    if (kullaniciKodu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Prosis kullanıcı kodu bulunamadı. "
            "Tekrar giriş yapın.",
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepoTalepOnayPage(
          kullaniciKodu: kullaniciKodu,
          oturumId: user.oturumId ?? 0,
          token: user.token ?? '',
        ),
      ),
    );
  },
),
      _MenuItem(
        title: "Barkod Kontrol",
        icon:
            Icons.qr_code_scanner_rounded,
        visible:
            user.yetkisiVar("BARKOD_KONTROL"),
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
        visible:
            user.yetkisiVar("PALETLEME_RAPORU"),
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
        visible:
            user.yetkisiVar("PAKETLEME_RAPORU"),
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
  title: "Sera Kontrol Raporu",
  icon: Icons.fact_check_outlined,
  visible:
      user.yetkisiVar("SERA_KONTROL_RAPORU"),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SeraKontrolRaporuPage(
        ),
      ),
    );
  },
),

      _MenuItem(
        title: "Hasat Raporu",
        icon: Icons.agriculture_rounded,
        visible:
            user.yetkisiVar("HASAT_RAPORU"),
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
        visible:
            user.yetkisiVar("TUTA_RAPORU"),
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
        visible:
            user.yetkisiVar("PERSONEL_ANLIK"),
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
        visible:
            user.yetkisiVar("DEPO_DURUM_RAPORU"),
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

    // ============================================================
    // YÖNETİM
    // ============================================================

    final yonetimItems = <_MenuItem>[
      _MenuItem(
        title: "Mobil Yetki",
        icon:
            Icons.admin_panel_settings_rounded,
        visible:
            user.yetkisiVar("MOBIL_YETKI"),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const MobilMenuYetkiPage(),
            ),
          );
        },
      ),

      _MenuItem(
        title: "Personel Listesi",
        icon: Icons.groups_rounded,
        visible:
            user.yetkisiVar("PERSONEL_LISTESI"),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const PersonelListesiPage(),
            ),
          );
        },
      ),
    ];

    return MediaQuery(
      data:
          MediaQuery.of(context).copyWith(
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
              fontWeight:
                  FontWeight.w900,
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

            if (OperasyonPanel.seraPersoneliMi(user))
              OperasyonPanel(user: user)
            else
              Builder(
                builder: (context) {
                final bolumler = <_MenuSection>[
                  _MenuSection(
                    title: 'Operasyon',
                    icon: Icons.settings_suggest_outlined,
                    items: operasyonItems.where((e) => e.visible).toList(),
                  ),
                  _MenuSection(
                    title: 'Depo',
                    icon: Icons.warehouse_outlined,
                    items: depoItems.where((e) => e.visible).toList(),
                  ),
                  _MenuSection(
                    title: 'Raporlar',
                    icon: Icons.analytics_outlined,
                    items: raporItems.where((e) => e.visible).toList(),
                  ),
                  _MenuSection(
                    title: 'Yönetim',
                    icon: Icons.admin_panel_settings_outlined,
                    items: yonetimItems.where((e) => e.visible).toList(),
                  ),
                ].where((e) => e.items.isNotEmpty).toList();

                if (bolumler.isEmpty) {
                  return const SizedBox.shrink();
                }

                final aktifIndex =
                    _seciliMenu >= bolumler.length ? 0 : _seciliMenu;
                final aktif = bolumler[aktifIndex];

                return Column(
                  children: [
                    _MenuTabs(
                      sections: bolumler,
                      selectedIndex: aktifIndex,
                      onChanged: (index) {
                        setState(() {
                          _seciliMenu = index;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _MenuGridSection(section: aktif),
                  ],
                );
                },
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

class _MenuSection {
  final String title;
  final IconData icon;
  final List<_MenuItem> items;

  const _MenuSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class _MenuTabs extends StatelessWidget {
  final List<_MenuSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _MenuTabs({
    required this.sections,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const Color accent = Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.black.withOpacity(.05),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < sections.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: i == sections.length - 1 ? 0 : 3,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 42,
                    decoration: BoxDecoration(
                      color: selectedIndex == i
                          ? accent.withOpacity(.11)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          sections[i].icon,
                          size: 17,
                          color: selectedIndex == i
                              ? accent
                              : Colors.black45,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sections[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8.8,
                            fontWeight: FontWeight.w900,
                            color: selectedIndex == i
                                ? accent
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuGridSection extends StatelessWidget {
  final _MenuSection section;

  const _MenuGridSection({
    required this.section,
  });

  static const Color accent = Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.black.withOpacity(.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.08),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  section.icon,
                  size: 14,
                  color: accent,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withOpacity(.65),
                ),
              ),
              const Spacer(),
              Text(
                '${section.items.length} menü',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.black.withOpacity(.30),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 7.0;
              final columns = constraints.maxWidth >= 600 ? 4 : 3;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in section.items)
                    SizedBox(
                      width: width,
                      height: 76,
                      child: _MenuCard(item: item),
                    ),
                ],
              );
            },
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
      color: const Color(0xFFF7F9F8),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 7, 5, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: Colors.black.withOpacity(.045),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  item.icon,
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withOpacity(.80),
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