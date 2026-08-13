import 'package:flutter/material.dart';

import 'package:agronet/api/mobil_yetki_api.dart';
import 'package:agronet/models/mobil_yetki_model.dart';

class MobilMenuYetkiPage extends StatefulWidget {
  const MobilMenuYetkiPage({super.key});

  @override
  State<MobilMenuYetkiPage> createState() =>
      _MobilMenuYetkiPageState();
}

class _MobilMenuYetkiPageState extends State<MobilMenuYetkiPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color background = Color(0xFFF5F6F8);

  final MobilYetkiApi _api = MobilYetkiApi();

  bool _yukleniyor = true;
  bool _kaydediliyor = false;

  /// Backend'den gelen bütün kayıtlar.
  ///
  /// Her satır:
  /// Personel Tipi + Menü + Yetki
  List<MobilYetkiModel> _tumYetkiler = [];

  /// Dropdown'da göstereceğimiz personel tipleri.
  List<_PersonelTipItem> _personelTipleri = [];

  int? _seciliPersonelTipId;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  // ============================================================
  // YÜKLE
  // ============================================================

  Future<void> _yukle() async {
    try {
      setState(() {
        _yukleniyor = true;
      });

      final liste = await _api.yetkileriGetir();

      if (!mounted) return;

      final tipMap = <int, String>{};

      for (final item in liste) {
        if (item.personeltipid <= 0) {
          continue;
        }

        tipMap[item.personeltipid] = item.tip;
      }

      final tipler = tipMap.entries
          .map(
            (e) => _PersonelTipItem(
              id: e.key,
              tip: e.value,
            ),
          )
          .toList();

      tipler.sort(
        (a, b) => a.tip
            .toLowerCase()
            .compareTo(
              b.tip.toLowerCase(),
            ),
      );

      int? seciliId = _seciliPersonelTipId;

      if (tipler.isEmpty) {
        seciliId = null;
      } else {
        final mevcutHalaVar = seciliId != null &&
            tipler.any(
              (e) => e.id == seciliId,
            );

        if (!mevcutHalaVar) {
          seciliId = tipler.first.id;
        }
      }

      setState(() {
        _tumYetkiler = liste;
        _personelTipleri = tipler;
        _seciliPersonelTipId = seciliId;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _yukleniyor = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Yetkiler yüklenemedi: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // SEÇİLİ PERSONEL TİPİNİN MENÜLERİ
  // ============================================================

  List<MobilYetkiModel> get _seciliMenuler {
    final id = _seciliPersonelTipId;

    if (id == null) {
      return [];
    }

    final liste = _tumYetkiler
        .where(
          (e) => e.personeltipid == id,
        )
        .toList();

    liste.sort(
      (a, b) {
        final grupKarsilastirma =
            _grupSirasi(a.grup).compareTo(
          _grupSirasi(b.grup),
        );

        if (grupKarsilastirma != 0) {
          return grupKarsilastirma;
        }

        final siraKarsilastirma =
            a.sira.compareTo(b.sira);

        if (siraKarsilastirma != 0) {
          return siraKarsilastirma;
        }

        return a.menuid.compareTo(b.menuid);
      },
    );

    return liste;
  }

  // ============================================================
  // GRUPLAR
  // ============================================================

  List<String> get _seciliGruplar {
    final gruplar = <String>[];

    for (final menu in _seciliMenuler) {
      final grup = menu.grup.trim();

      if (grup.isEmpty) {
        continue;
      }

      if (!gruplar.contains(grup)) {
        gruplar.add(grup);
      }
    }

    gruplar.sort(
      (a, b) => _grupSirasi(a).compareTo(
        _grupSirasi(b),
      ),
    );

    return gruplar;
  }

  int _grupSirasi(String grup) {
    switch (grup.trim().toLowerCase()) {
      case "operasyon":
        return 1;

      case "depo":
        return 2;

      case "raporlar":
        return 3;

      case "yönetim":
      case "yonetim":
        return 4;

      default:
        return 99;
    }
  }

  IconData _grupIcon(String grup) {
    switch (grup.trim().toLowerCase()) {
      case "operasyon":
        return Icons.settings_suggest_outlined;

      case "depo":
        return Icons.warehouse_outlined;

      case "raporlar":
        return Icons.analytics_outlined;

      case "yönetim":
      case "yonetim":
        return Icons.admin_panel_settings_outlined;

      default:
        return Icons.apps_rounded;
    }
  }

  // ============================================================
  // KAYDET
  // ============================================================

  Future<void> _kaydet() async {
    final personelTipId =
        _seciliPersonelTipId;

    if (personelTipId == null) {
      return;
    }

    final menuler = _seciliMenuler;

    if (menuler.isEmpty) {
      return;
    }

    try {
      setState(() {
        _kaydediliyor = true;
      });

      await _api.yetkileriKaydet(
        personelTipId: personelTipId,
        menuler: menuler,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Yetkiler kaydedildi.",
          ),
        ),
      );

      await _yukle();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Kaydetme hatası: $e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _kaydediliyor = false;
        });
      }
    }
  }

  // ============================================================
  // SAYFA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        toolbarHeight: 46,
        title: const Text(
          "Mobil Yetki",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed:
                _yukleniyor ? null : _yukle,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 20,
            ),
          ),
        ],
      ),

      body: _yukleniyor
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _personelTipleri.isEmpty
              ? const Center(
                  child: Text(
                    "Personel tipi bulunamadı.",
                  ),
                )
              : Column(
                  children: [
                    _tipSecimAlani(),

                    const SizedBox(height: 6),

                    Expanded(
                      child: _yetkiAlani(),
                    ),
                  ],
                ),
    );
  }

  // ============================================================
  // PERSONEL TİPİ
  // ============================================================

  Widget _tipSecimAlani() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        8,
        5,
        8,
        5,
      ),

      child: DropdownButtonFormField<int>(
        value: _seciliPersonelTipId,

        isExpanded: true,
        isDense: true,

        menuMaxHeight: 280,

        // Flutter minimum dropdown yüksekliği
        itemHeight: 48,

        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 17,
          color: accent,
        ),

        decoration: InputDecoration(
          labelText: "Personel Tipi",

          labelStyle: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(.45),
          ),

          floatingLabelStyle:
              const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: accent,
          ),

          prefixIcon: const Icon(
            Icons.groups_rounded,
            size: 15,
            color: accent,
          ),

          prefixIconConstraints:
              const BoxConstraints(
            minWidth: 30,
            minHeight: 30,
          ),

          filled: true,
          fillColor:
              const Color(0xFFF7F7F9),

          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 5,
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(8),
            borderSide: BorderSide(
              color:
                  Colors.black.withOpacity(.05),
            ),
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(8),
            borderSide:
                const BorderSide(
              color: accent,
              width: .8,
            ),
          ),
        ),

        selectedItemBuilder: (context) {
          return _personelTipleri.map(
            (item) {
              return Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  item.tip,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w700,
                    height: 1,
                    color:
                        Colors.black87,
                  ),
                ),
              );
            },
          ).toList();
        },

        items: _personelTipleri.map(
          (item) {
            return DropdownMenuItem<int>(
              value: item.id,
              child: Text(
                item.tip,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontSize: 9.5,
                  fontWeight:
                      FontWeight.w500,
                  height: 1,
                  color:
                      Colors.black87,
                ),
              ),
            );
          },
        ).toList(),

        onChanged: (id) {
          if (id == null) {
            return;
          }

          setState(() {
            _seciliPersonelTipId = id;
          });
        },
      ),
    );
  }

  // ============================================================
  // YETKİLER
  // ============================================================

  Widget _yetkiAlani() {
    final menuler = _seciliMenuler;

    if (menuler.isEmpty) {
      return const Center(
        child: Text(
          "Bu personel tipi için menü bulunamadı.",
        ),
      );
    }

    final gruplar = _seciliGruplar;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.fromLTRB(
              9,
              0,
              9,
              12,
            ),
            itemCount: gruplar.length,
            itemBuilder: (
              context,
              index,
            ) {
              final grup =
                  gruplar[index];

              final grupMenuleri =
                  menuler
                      .where(
                        (e) =>
                            e.grup.trim() ==
                            grup,
                      )
                      .toList();

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 8,
                ),
                child: _section(
                  title: grup,
                  icon:
                      _grupIcon(grup),
                  children:
                      grupMenuleri.map(
                    (menu) {
                      return _yetkiSwitch(
                        title:
                            menu.baslik,
                        value:
                            menu.yetkili,
                        onChanged: (v) {
                          setState(() {
                            menu.yetkili =
                                v;
                          });
                        },
                      );
                    },
                  ).toList(),
                ),
              );
            },
          ),
        ),

        _kaydetButonu(),
      ],
    );
  }

  // ============================================================
  // BÖLÜM KARTI
  // ============================================================

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        9,
        8,
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
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration:
                    BoxDecoration(
                  color:
                      accent.withOpacity(.08),
                  borderRadius:
                      BorderRadius.circular(
                    7,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: accent,
                ),
              ),

              const SizedBox(width: 7),

              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w900,
                  color: Colors.black
                      .withOpacity(.62),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // SWITCH
  // ============================================================

  Widget _yetkiSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool>
        onChanged,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 5,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F7F9),
        borderRadius:
            BorderRadius.circular(10),
      ),

      child: SwitchListTile(
        dense: true,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 0,
        ),

        title: Text(
          title,
          style:
              const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        value: value,
        activeColor: accent,

        onChanged: onChanged,
      ),
    );
  }

  // ============================================================
  // KAYDET
  // ============================================================

  Widget _kaydetButonu() {
    return Container(
      width: double.infinity,
      color: Colors.white,

      padding: EdgeInsets.fromLTRB(
        10,
        8,
        10,
        8 +
            MediaQuery.of(context)
                .padding
                .bottom,
      ),

      child: SizedBox(
        height: 46,

        child: ElevatedButton.icon(
          onPressed:
              _kaydediliyor
                  ? null
                  : _kaydet,

          style:
              ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor:
                Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
          ),

          icon: _kaydediliyor
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.save_rounded,
                ),

          label: Text(
            _kaydediliyor
                ? "Kaydediliyor..."
                : "Yetkileri Kaydet",
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PERSONEL TİP DROPDOWN MODELİ
// ============================================================

class _PersonelTipItem {
  final int id;
  final String tip;

  const _PersonelTipItem({
    required this.id,
    required this.tip,
  });
}