import 'package:agronet/api/kututipi_api.dart';
import 'package:agronet/api/palet_tipi.dart';
import 'package:agronet/api/paletleme_post_api.dart';
import 'package:agronet/api/stok_adlari_api.dart';
import 'package:agronet/page/PaletlemeRaporu.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Paketleme extends StatefulWidget {
  final String personelkodu;
  final String personelAdi;

  const Paketleme({
    super.key,
    required this.personelkodu,
    required this.personelAdi,
  });

  @override
  State<Paketleme> createState() =>
      _PaketlemeState();
}

class _PaketlemeState extends State<Paketleme> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _dialogOpen = false;

  // ============================================================
  // SEÇİMLER
  // ============================================================

  String kiosksecimi = "Kiosk 1";
  String stokkodu = "152.1.001";
  String kutukodu = "K06";
  String paletkodu = "PALET 1";

  // ============================================================
  // INPUTLAR
  // ============================================================

  final paletbosagirlik = TextEditingController();
  final kutusayisi = TextEditingController();
  final toplamkg = TextEditingController();

  // ============================================================
  // DROPDOWN
  // ============================================================

  List stokadlari = [];
  List kututipi = [];
  List palet_tipi = [];

  bool _dropdownsReady = false;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    paletbosagirlik.dispose();
    kutusayisi.dispose();
    toplamkg.dispose();

    super.dispose();
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(bool value) {
    if (!mounted) return;

    setState(() {
      _loading = value;
    });
  }

  Future<void> _showLoadingDialog() async {
    if (!mounted || _dialogOpen) return;

    _dialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (!mounted) return;

    if (_dialogOpen &&
        Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    _dialogOpen = false;
  }

  // ============================================================
  // LİSTELER
  // ============================================================

  Future<void> _loadDropdowns() async {
    try {
      final s =
          await StokAdlariApi().stokAdlari();

      final k =
          await KutuTipApi().kutuTipleri();

      final p =
          await PaletTipApi().paletTipleri();

      if (!mounted) return;

      setState(() {
        stokadlari = s;
        kututipi = k;
        palet_tipi = p;

        if (stokadlari.isNotEmpty &&
            !stokadlari.any(
              (e) =>
                  e['sto_kod'] == stokkodu,
            )) {
          stokkodu =
              stokadlari.first['sto_kod'];
        }

        if (kututipi.isNotEmpty &&
            !kututipi.any(
              (e) =>
                  e['kod'] == kutukodu,
            )) {
          kutukodu =
              kututipi.first['kod'];
        }

        if (palet_tipi.isNotEmpty &&
            !palet_tipi.any(
              (e) =>
                  e['pak_kod'] ==
                  paletkodu,
            )) {
          paletkodu =
              palet_tipi.first['pak_kod'];
        }

        _dropdownsReady = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _dropdownsReady = true;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Listeler alınamadı. İnterneti kontrol edin.",
          ),
        ),
      );
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _dec({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      labelStyle: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),

      hintStyle: const TextStyle(
        fontSize: 11,
        color: Colors.black38,
      ),

      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              size: 18,
              color: accent,
            ),

      filled: true,
      fillColor: const Color(0xFFF7F7F9),

      isDense: true,

      contentPadding:
          const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 10,
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),
        borderSide: BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),
        borderSide: BorderSide(
          color:
              Colors.black.withOpacity(.055),
        ),
      ),

      focusedBorder:
          const OutlineInputBorder(
        borderRadius:
            BorderRadius.all(
          Radius.circular(9),
        ),
        borderSide: BorderSide(
          color: accent,
          width: 1.3,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),
        borderSide: BorderSide(
          color: Colors.red.shade400,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 1.3,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        10,
        9,
        10,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color:
              Colors.black.withOpacity(.05),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      accent.withOpacity(.09),
                  borderRadius:
                      BorderRadius.circular(7),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 16,
                ),
              ),

              const SizedBox(width: 7),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // KAYDET
  // ============================================================

  Future<void> _kaydet() async {
    if (!_dropdownsReady) return;

    FocusScope.of(context).unfocus();

    final valid =
        _formKey.currentState?.validate() ??
            false;

    if (!valid) return;

    _setLoading(true);

    await _showLoadingDialog();

    try {
      await PaletlemeApi().paletGonder(
        personelkodu:
            widget.personelkodu,
        paletbos:
            paletbosagirlik.text.trim(),
        kututipi: kutukodu,
        kutuadedi:
            kutusayisi.text.trim(),
        toplamagirlik:
            toplamkg.text.trim(),
        palettipi: paletkodu,
        cihazadi: kiosksecimi,
        stokkodu: stokkodu,
      );

      _hideLoadingDialog();
      _setLoading(false);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          Future.delayed(
            const Duration(
              milliseconds: 750,
            ),
            () {
              if (Navigator.of(context)
                  .canPop()) {
                Navigator.of(context)
                    .pop(true);
              }
            },
          );

          return AlertDialog(
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
            title: const Text(
              "Kaydedildi",
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            content: Text(
              "$paletkodu oluşturuldu",
              style: const TextStyle(
                fontSize: 11.5,
              ),
            ),
          );
        },
      );

      paletbosagirlik.clear();
      kutusayisi.clear();
      toplamkg.clear();
    } catch (e) {
      _hideLoadingDialog();
      _setLoading(false);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Hata: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // PALETLERİ GÖR
  // ============================================================

  Future<void> _paletleriGor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PaletlemeRaporPage(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final w =
        MediaQuery.of(context).size.width;

    final scaler =
        MediaQuery.textScalerOf(context)
            .clamp(
      maxScaleFactor: 1.06,
    );

    return MediaQuery(
      data:
          MediaQuery.of(context).copyWith(
        textScaler: scaler,
      ),
      child: Scaffold(
        backgroundColor: bg,

        // ========================================================
        // APP BAR
        // ========================================================

        appBar: AppBar(
          toolbarHeight: 48,
          title: const Text(
            "Paketleme",
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor:
              Colors.white,
          surfaceTintColor:
              Colors.white,
          foregroundColor:
              Colors.black87,
        ),

        // ========================================================
        // BODY
        // ========================================================

        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(
                maxWidth:
                    w > 560 ? 560 : w,
              ),
              child:
                  SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  10,
                  9,
                  10,
                  16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      // ==========================================
                      // PERSONEL
                      // ==========================================

                      _personelBilgisi(),

                      const SizedBox(
                        height: 7,
                      ),

                      // ==========================================
                      // KİOSK
                      // ==========================================

                      _sectionCard(
                        title:
                            "Cihaz / Kiosk",
                        icon: Icons
                            .devices_rounded,
                        children: [
                          DropdownButtonFormField<
                              String>(
                            value:
                                kiosksecimi,
                            isExpanded: true,
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color:
                                  Colors.black87,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                            decoration:
                                _dec(
                              label:
                                  "Kiosk",
                              hint:
                                  "Cihaz seçin",
                              icon: Icons
                                  .devices_rounded,
                            ),
                            items:
                                const [
                              DropdownMenuItem(
                                value:
                                    "Kiosk 1",
                                child: Text(
                                  "Kiosk 1",
                                ),
                              ),
                              DropdownMenuItem(
                                value:
                                    "Kiosk 2",
                                child: Text(
                                  "Kiosk 2",
                                ),
                              ),
                            ],
                            onChanged:
                                (value) {
                              setState(() {
                                kiosksecimi =
                                    value ??
                                        "Kiosk 1";
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      // ==========================================
                      // AĞIRLIK / ADET
                      // ==========================================

                      _sectionCard(
                        title:
                            "Ağırlık / Adet",
                        icon:
                            Icons.scale_rounded,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child:
                                    TextFormField(
                                  controller:
                                      paletbosagirlik,
                                  keyboardType:
                                      const TextInputType
                                          .numberWithOptions(
                                    decimal:
                                        true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter
                                        .allow(
                                      RegExp(
                                        r"[0-9\.,]",
                                      ),
                                    ),
                                  ],
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        12.5,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                  decoration:
                                      _dec(
                                    label:
                                        "Palet Boş",
                                    hint:
                                        "18,5",
                                    icon: Icons
                                        .line_weight_rounded,
                                  ),
                                  validator:
                                      (value) {
                                    if (value ==
                                            null ||
                                        value
                                            .trim()
                                            .isEmpty) {
                                      return "Boş olamaz";
                                    }

                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(
                                width: 7,
                              ),

                              Expanded(
                                child:
                                    TextFormField(
                                  controller:
                                      kutusayisi,
                                  keyboardType:
                                      TextInputType
                                          .number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter
                                        .digitsOnly,
                                  ],
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        12.5,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                  decoration:
                                      _dec(
                                    label:
                                        "Kutu Sayısı",
                                    hint:
                                        "60",
                                    icon: Icons
                                        .inventory_2_rounded,
                                  ),
                                  validator:
                                      (value) {
                                    if (value ==
                                            null ||
                                        value
                                            .trim()
                                            .isEmpty) {
                                      return "Boş olamaz";
                                    }

                                    final n =
                                        int.tryParse(
                                      value.trim(),
                                    );

                                    if (n ==
                                            null ||
                                        n <=
                                            0) {
                                      return "Geçersiz";
                                    }

                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          TextFormField(
                            controller:
                                toplamkg,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .allow(
                                RegExp(
                                  r"[0-9\.,]",
                                ),
                              ),
                            ],
                            style:
                                const TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                            decoration:
                                _dec(
                              label:
                                  "Toplam Kg",
                              hint:
                                  "Örn: 480,0",
                              icon: Icons
                                  .monitor_weight_rounded,
                            ),
                            validator:
                                (value) {
                              if (value ==
                                      null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return "Boş olamaz";
                              }

                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      // ==========================================
                      // SEÇİMLER
                      // ==========================================

                      _sectionCard(
                        title:
                            "Seçimler",
                        icon:
                            Icons.tune_rounded,
                        children: [
                          if (!_dropdownsReady)
                            const SizedBox(
                              height: 50,
                              child: Center(
                                child:
                                    CircularProgressIndicator(),
                              ),
                            )
                          else ...[
                            DropdownButtonFormField<
                                String>(
                              value:
                                  stokkodu,
                              isExpanded:
                                  true,
                              style:
                                  const TextStyle(
                                fontSize:
                                    12,
                                color: Colors
                                    .black87,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                              decoration:
                                  _dec(
                                label:
                                    "Ürün",
                                hint:
                                    "Ürün seçin",
                                icon: Icons
                                    .local_florist_rounded,
                              ),
                              selectedItemBuilder:
                                  (context) {
                                return stokadlari
                                    .map<Widget>(
                                  (item) {
                                    final text =
                                        "${item['sto_kisa_ismi']}";

                                    return Align(
                                      alignment:
                                          Alignment.centerLeft,
                                      child:
                                          Text(
                                        text,
                                        maxLines:
                                            1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ).toList();
                              },
                              items: stokadlari
                                  .map<
                                      DropdownMenuItem<
                                          String>>(
                                (item) {
                                  final text =
                                      "${item['sto_kisa_ismi']}";

                                  return DropdownMenuItem<
                                      String>(
                                    value: item[
                                        'sto_kod'],
                                    child: Text(
                                      text,
                                      maxLines:
                                          1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ).toList(),
                              onChanged:
                                  (value) {
                                setState(() {
                                  stokkodu =
                                      value ??
                                          stokkodu;
                                });
                              },
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            Row(
                              children: [
                                Expanded(
                                  child:
                                      DropdownButtonFormField<
                                          String>(
                                    value:
                                        kutukodu,
                                    isExpanded:
                                        true,
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          12,
                                      color:
                                          Colors.black87,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                    decoration:
                                        _dec(
                                      label:
                                          "Kutu Tipi",
                                      hint:
                                          "Kutu seçin",
                                      icon: Icons
                                          .all_inbox_rounded,
                                    ),
                                    selectedItemBuilder:
                                        (context) {
                                      return kututipi
                                          .map<
                                              Widget>(
                                        (item) {
                                          final text =
                                              "${item['isim']}";

                                          return Align(
                                            alignment:
                                                Alignment.centerLeft,
                                            child:
                                                Text(
                                              text,
                                              maxLines:
                                                  1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          );
                                        },
                                      ).toList();
                                    },
                                    items:
                                        kututipi
                                            .map<
                                                DropdownMenuItem<String>>(
                                      (item) {
                                        final text =
                                            "${item['isim']}";

                                        return DropdownMenuItem<
                                            String>(
                                          value:
                                              item['kod'],
                                          child:
                                              Text(
                                            text,
                                            maxLines:
                                                1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        );
                                      },
                                    ).toList(),
                                    onChanged:
                                        (value) {
                                      setState(() {
                                        kutukodu =
                                            value ??
                                                kutukodu;
                                      });
                                    },
                                  ),
                                ),

                                const SizedBox(
                                  width: 7,
                                ),

                                Expanded(
                                  child:
                                      DropdownButtonFormField<
                                          String>(
                                    value:
                                        paletkodu,
                                    isExpanded:
                                        true,
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          12,
                                      color:
                                          Colors.black87,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                    decoration:
                                        _dec(
                                      label:
                                          "Palet Tipi",
                                      hint:
                                          "Palet seçin",
                                      icon: Icons
                                          .view_module_rounded,
                                    ),
                                    selectedItemBuilder:
                                        (context) {
                                      return palet_tipi
                                          .map<
                                              Widget>(
                                        (item) {
                                          final text =
                                              "${item['pak_ismi']}";

                                          return Align(
                                            alignment:
                                                Alignment.centerLeft,
                                            child:
                                                Text(
                                              text,
                                              maxLines:
                                                  1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          );
                                        },
                                      ).toList();
                                    },
                                    items:
                                        palet_tipi
                                            .map<
                                                DropdownMenuItem<String>>(
                                      (item) {
                                        final text =
                                            "${item['pak_ismi']}";

                                        return DropdownMenuItem<
                                            String>(
                                          value: item[
                                              'pak_kod'],
                                          child:
                                              Text(
                                            text,
                                            maxLines:
                                                1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        );
                                      },
                                    ).toList(),
                                    onChanged:
                                        (value) {
                                      setState(() {
                                        paletkodu =
                                            value ??
                                                paletkodu;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(
                        height: 9,
                      ),

                      // ==========================================
                      // BUTONLAR
                      // ==========================================

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child:
                                SizedBox(
                              height: 44,
                              child:
                                  FilledButton.icon(
                                onPressed:
                                    _loading
                                        ? null
                                        : _kaydet,
                                style:
                                    FilledButton
                                        .styleFrom(
                                  backgroundColor:
                                      accent,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            9),
                                  ),
                                ),
                                icon:
                                    _loading
                                        ? const SizedBox(
                                            width:
                                                15,
                                            height:
                                                15,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth:
                                                  2,
                                              color:
                                                  Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.save_rounded,
                                            size:
                                                17,
                                          ),
                                label:
                                    Text(
                                  _loading
                                      ? 'KAYDEDİLİYOR'
                                      : 'KAYDET',
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        10.5,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 7,
                          ),

                          Expanded(
                            child:
                                SizedBox(
                              height: 44,
                              child:
                                  OutlinedButton.icon(
                                onPressed:
                                    _loading
                                        ? null
                                        : _paletleriGor,
                                style:
                                    OutlinedButton
                                        .styleFrom(
                                  foregroundColor:
                                      Colors.black87,
                                  side:
                                      BorderSide(
                                    color: Colors
                                        .black
                                        .withOpacity(
                                            .12),
                                  ),
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            9),
                                  ),
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        5,
                                  ),
                                ),
                                icon:
                                    const Icon(
                                  Icons
                                      .list_alt_rounded,
                                  size: 16,
                                ),
                                label:
                                    const Text(
                                  "PALETLER",
                                  style:
                                      TextStyle(
                                    fontSize:
                                        9.5,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PERSONEL
  // ============================================================

  Widget _personelBilgisi() {
    return Container(
      height: 47,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color:
              Colors.black.withOpacity(.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color:
                  accent.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: accent,
              size: 18,
            ),
          ),

          const SizedBox(width: 8),

          const Text(
            'Personel',
            style: TextStyle(
              fontSize: 9.5,
              color: Colors.black45,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            child: Text(
              widget.personelAdi,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}