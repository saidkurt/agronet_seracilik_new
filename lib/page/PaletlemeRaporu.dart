import 'package:agronet/api/palet_detay_api.dart';
import 'package:agronet/api/paletleme_post_api.dart';
import 'package:agronet/api/paletleme_rapor.dart';
import 'package:agronet/api/etiket_tekrar_paletleme.dart';

import 'package:agronet/models/paletleme_rapor_model.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PaletlemeRaporPage extends StatefulWidget {
  const PaletlemeRaporPage({
    super.key,
  });

  @override
  State<PaletlemeRaporPage> createState() =>
      _PaletlemeRaporPageState();
}

class _PaletlemeRaporPageState
    extends State<PaletlemeRaporPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  final PaletlemeRaporApi _api =
      const PaletlemeRaporApi();

  final SerapaketApi _serapaketApi =
      SerapaketApi();

  final TextEditingController _searchCtrl =
      TextEditingController();

  DateTime _ilkTarih = DateTime.now();
  DateTime _sonTarih = DateTime.now();

  bool _loading = false;
  bool _sortDesc = true;

  String? _selectedUrun;
  String? _error;

  List<PaletlemeRaporModel> _items = [];

  final DateFormat _df =
      DateFormat('dd.MM.yyyy');

  final DateFormat _tf =
      DateFormat('HH:mm');

  String? _printingPalet;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _getir();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // ÜRÜNLER
  // ============================================================

  List<String> get _urunAdlari {
    final set = <String>{};

    for (final item in _items) {
      final isim =
          (item.urunAdi ?? '').trim();

      if (isim.isNotEmpty &&
          isim.toLowerCase() != 'null') {
        set.add(isim);
      }
    }

    final list = set.toList()
      ..sort();

    return list;
  }

  // ============================================================
  // TARİH
  // ============================================================

  Future<void> _pickDate({
    required bool isIlk,
  }) async {
    final initial =
        isIlk ? _ilkTarih : _sonTarih;

    final picked =
        await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(
        DateTime.now().year - 2,
      ),
      lastDate: DateTime(
        DateTime.now().year + 1,
      ),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isIlk) {
        _ilkTarih = picked;

        if (_sonTarih.isBefore(
          _ilkTarih,
        )) {
          _sonTarih = _ilkTarih;
        }
      } else {
        _sonTarih = picked;

        if (_sonTarih.isBefore(
          _ilkTarih,
        )) {
          _ilkTarih = _sonTarih;
        }
      }
    });
  }

  // ============================================================
  // GETİR
  // ============================================================

  Future<void> _getir() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data =
          await _api.paletlemeGetir(
        _ilkTarih,
        _sonTarih,
      );

      if (!mounted) return;

      setState(() {
        _items = data;

        if (_selectedUrun != null &&
            !_urunAdlari.contains(
              _selectedUrun,
            )) {
          _selectedUrun = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            )
            .trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // PALET SİL
  // ============================================================

  Future<void> _paletSil(
    String paletKodu,
  ) async {
    final bool? ok =
        await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
          title: const Text(
            'Palet Sil',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '$paletKodu paleti silinsin mi?',
            style: const TextStyle(
              fontSize: 11.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  ctx,
                  false,
                );
              },
              child: const Text(
                'VAZGEÇ',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Colors.red.shade700,
              ),
              onPressed: () {
                Navigator.pop(
                  ctx,
                  true,
                );
              },
              child: const Text(
                'SİL',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _serapaketApi.paletSil(
        paletkodu: paletKodu,
      );

      if (!mounted) return;

      _snack(
        'Palet silindi.',
      );

      await _getir();
    } catch (e) {
      if (!mounted) return;

      _snack(
        'Silme hatası: $e',
        hata: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // ETİKET
  // ============================================================

  Future<void> _etiketCikar(
    String paletKodu,
  ) async {
    final p = paletKodu.trim();

    if (p.isEmpty) return;
    if (_printingPalet != null) return;

    setState(() {
      _printingPalet = p;
      _error = null;
    });

    try {
      final api = PaletlemeApi();

      await api.paletEtiketiTekrar(
        paletkodu: p,
        cihazadi: 'Kiosk 1',
      );

      if (!mounted) return;

      _snack(
        'Etiket çıkarıldı.',
      );
    } catch (e) {
      if (!mounted) return;

      _snack(
        'Etiket çıkarma hatası: $e',
        hata: true,
      );

      setState(() {
        _error =
            'Etiket çıkarma hatası: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _printingPalet = null;
        });
      }
    }
  }

  // ============================================================
  // FİLTRE
  // ============================================================

  List<PaletlemeRaporModel> get _filtered {
    var list =
        List<PaletlemeRaporModel>.from(
      _items,
    );

    if (_selectedUrun != null) {
      list = list.where(
        (x) =>
            (x.urunAdi ?? '').trim() ==
            _selectedUrun,
      ).toList();
    }

    list.sort(
      (a, b) {
        final da =
            a.olusmaZamani ??
                DateTime.fromMillisecondsSinceEpoch(
                    0);

        final db =
            b.olusmaZamani ??
                DateTime.fromMillisecondsSinceEpoch(
                    0);

        final sonuc =
            da.compareTo(db);

        return _sortDesc
            ? -sonuc
            : sonuc;
      },
    );

    return list;
  }

  int get _paletAdet =>
      _filtered.length;

  int get _kutuToplam {
    return _filtered.fold<int>(
      0,
      (sum, x) =>
          sum + (x.kutuSayisi ?? 0),
    );
  }

  int get _netToplam {
    return _filtered.fold<int>(
      0,
      (sum, x) =>
          sum + (x.netKg?.round() ?? 0),
    );
  }

  int get _brutToplam {
    return _filtered.fold<int>(
      0,
      (sum, x) =>
          sum + (x.brutKg?.round() ?? 0),
    );
  }

  // ============================================================
  // MESAJ
  // ============================================================

  void _snack(
    String mesaj, {
    bool hata = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              hata
                  ? Colors.red.shade700
                  : accent,
          content: Text(
            mesaj,
            style: const TextStyle(
              fontSize: 11,
            ),
          ),
        ),
      );
  }

  // ============================================================
  // QR BUL
  // ============================================================

  Future<void>
      _qrOkuVeDetayGoster() async {
    String? paletKodu;

    final picked =
        await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _QrOrManualSheet(
          onManual: (value) {
            Navigator.pop(
              ctx,
              value,
            );
          },
          onScan: () {
            Navigator.pop(
              ctx,
              '__SCAN__',
            );
          },
        );
      },
    );

    if (picked == null) {
      return;
    }

    if (picked == '__SCAN__') {
      paletKodu =
          await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const _QrScanPage(),
        ),
      );
    } else {
      paletKodu = picked;
    }

    if (paletKodu == null ||
        paletKodu.trim().isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final detay =
          await PaletDetayApi()
              .paletDetayGetir(
        paletkodu:
            paletKodu.trim(),
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      await _showPaletDetaySheet(
        detay,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _snack(
        'Detay alınamadı: $e',
        hata: true,
      );
    }
  }

  // ============================================================
  // PALET DETAY SHEET
  // ============================================================

  Future<void> _showPaletDetaySheet(
    PaletlemeRaporModel detay,
  ) async {
    final palet =
        (detay.paletKodu ?? '')
            .trim();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height:
              MediaQuery.of(ctx)
                      .size
                      .height *
                  .62,
          decoration: const BoxDecoration(
            color: bg,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(
                  height: 8,
                ),

                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius:
                        BorderRadius.circular(
                            99),
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    10,
                    8,
                    10,
                    6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 29,
                        height: 29,
                        decoration:
                            BoxDecoration(
                          color: accent
                              .withOpacity(.09),
                          borderRadius:
                              BorderRadius.circular(
                                  8),
                        ),
                        child: const Icon(
                          Icons
                              .qr_code_2_rounded,
                          color: accent,
                          size: 17,
                        ),
                      ),

                      const SizedBox(
                        width: 7,
                      ),

                      const Expanded(
                        child: Text(
                          'Palet Detayı',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),

                      IconButton(
                        visualDensity:
                            VisualDensity.compact,
                        onPressed: () {
                          Navigator.pop(
                            ctx,
                          );
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child:
                      SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      10,
                      0,
                      10,
                      8,
                    ),
                    child: _PaletDetayCard(
                      detay: detay,
                    ),
                  ),
                ),

                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.fromLTRB(
                    8,
                    6,
                    8,
                    6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child:
                              OutlinedButton(
                            onPressed: () {
                              Navigator.pop(
                                ctx,
                              );
                            },
                            style:
                                OutlinedButton
                                    .styleFrom(
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        9),
                              ),
                            ),
                            child:
                                const Text(
                              'VAZGEÇ',
                              style: TextStyle(
                                fontSize:
                                    10,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 6,
                      ),

                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child:
                              FilledButton.icon(
                            style:
                                FilledButton
                                    .styleFrom(
                              backgroundColor:
                                  Colors.red
                                      .shade700,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        9),
                              ),
                            ),
                            icon:
                                const Icon(
                              Icons
                                  .delete_outline_rounded,
                              size: 17,
                            ),
                            label:
                                const Text(
                              'SİL',
                              style: TextStyle(
                                fontSize:
                                    10,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                            onPressed:
                                palet.isEmpty
                                    ? null
                                    : () async {
                                        Navigator.pop(
                                          ctx,
                                        );

                                        await _paletSil(
                                          palet,
                                        );
                                      },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final list = _filtered;

    final scaler =
        MediaQuery.textScalerOf(context)
            .clamp(
      maxScaleFactor: 1.06,
    );

    return MediaQuery(
      data:
          MediaQuery.of(context)
              .copyWith(
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
            'Paletleme Raporu',
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
          actions: [
            IconButton(
              tooltip:
                  'QR ile palet bul',
              visualDensity:
                  VisualDensity.compact,
              icon: const Icon(
                Icons
                    .qr_code_scanner_rounded,
                size: 20,
              ),
              onPressed:
                  _loading
                      ? null
                      : _qrOkuVeDetayGoster,
            ),

            IconButton(
              tooltip: _sortDesc
                  ? 'Yeni → Eski'
                  : 'Eski → Yeni',
              visualDensity:
                  VisualDensity.compact,
              icon: Icon(
                _sortDesc
                    ? Icons
                        .south_rounded
                    : Icons
                        .north_rounded,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _sortDesc =
                      !_sortDesc;
                });
              },
            ),
          ],
        ),

        // ========================================================
        // BODY
        // ========================================================

        body: Column(
          children: [
            _ustPanel(),

            Expanded(
              child: _loading
                  ? _loadingListesi()
                  : _error != null
                      ? _hataGorunumu()
                      : list.isEmpty
                          ? _bosGorunum()
                          : RefreshIndicator(
                              color: accent,
                              onRefresh:
                                  _getir,
                              child:
                                  ListView.separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(
                                  9,
                                  6,
                                  9,
                                  14,
                                ),
                                itemCount:
                                    list.length,
                                separatorBuilder:
                                    (_, __) =>
                                        const SizedBox(
                                  height:
                                      6,
                                ),
                                itemBuilder:
                                    (context,
                                        index) {
                                  final item =
                                      list[
                                          index];

                                  final palet =
                                      (item.paletKodu ??
                                              '')
                                          .trim();

                                  return _PaletCard(
                                    item:
                                        item,
                                    timeFormatter:
                                        _tf,
                                    dateFormatter:
                                        _df,
                                    onDelete: palet
                                            .isEmpty
                                        ? null
                                        : () =>
                                            _paletSil(
                                              palet,
                                            ),
                                    onPrint: palet
                                            .isEmpty
                                        ? null
                                        : () =>
                                            _etiketCikar(
                                              palet,
                                            ),
                                    printing:
                                        _printingPalet ==
                                            palet,
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ÜST PANEL
  // ============================================================

  Widget _ustPanel() {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        9,
        7,
        9,
        7,
      ),
      child: Column(
        children: [
          // TARİH + GETİR
          Row(
            children: [
              Expanded(
                child: _DateBox(
                  label: 'İlk',
                  value:
                      _df.format(
                    _ilkTarih,
                  ),
                  onTap: () {
                    _pickDate(
                      isIlk: true,
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 5,
              ),

              Expanded(
                child: _DateBox(
                  label: 'Son',
                  value:
                      _df.format(
                    _sonTarih,
                  ),
                  onTap: () {
                    _pickDate(
                      isIlk: false,
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 5,
              ),

              SizedBox(
                width: 74,
                height: 42,
                child:
                    FilledButton(
                  onPressed:
                      _loading
                          ? null
                          : _getir,
                  style:
                      FilledButton
                          .styleFrom(
                    backgroundColor:
                        accent,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 5,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              9),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text(
                          'GETİR',
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
            ],
          ),

          const SizedBox(
            height: 6,
          ),

          // KPI 4 TANE TEK SATIR
          Row(
            children: [
              Expanded(
                child: _KpiBox(
                  title: 'Palet',
                  value:
                      '$_paletAdet',
                  icon: Icons
                      .inventory_2_outlined,
                ),
              ),

              const SizedBox(
                width: 4,
              ),

              Expanded(
                child: _KpiBox(
                  title: 'Kutu',
                  value:
                      '$_kutuToplam',
                  icon: Icons
                      .all_inbox_rounded,
                ),
              ),

              const SizedBox(
                width: 4,
              ),

              Expanded(
                child: _KpiBox(
                  title: 'Net',
                  value:
                      '$_netToplam',
                  icon:
                      Icons.scale_rounded,
                ),
              ),

              const SizedBox(
                width: 4,
              ),

              Expanded(
                child: _KpiBox(
                  title: 'Brüt',
                  value:
                      '$_brutToplam',
                  icon: Icons
                      .monitor_weight_outlined,
                ),
              ),
            ],
          ),

          if (_urunAdlari.isNotEmpty) ...[
            const SizedBox(
              height: 6,
            ),

            SizedBox(
              height: 33,
              child: ListView(
                scrollDirection:
                    Axis.horizontal,
                children: [
                  _UrunChip(
                    text: 'Tümü',
                    selected:
                        _selectedUrun ==
                            null,
                    onTap: () {
                      setState(() {
                        _selectedUrun =
                            null;
                      });
                    },
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  ..._urunAdlari.map(
                    (urun) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          right: 5,
                        ),
                        child:
                            _UrunChip(
                          text: urun,
                          selected:
                              _selectedUrun ==
                                  urun,
                          onTap: () {
                            setState(() {
                              _selectedUrun =
                                  urun;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // LOADING / HATA / BOŞ
  // ============================================================

  Widget _loadingListesi() {
    return ListView.separated(
      padding:
          const EdgeInsets.fromLTRB(
        9,
        6,
        9,
        14,
      ),
      itemCount: 7,
      separatorBuilder:
          (_, __) =>
              const SizedBox(
        height: 6,
      ),
      itemBuilder:
          (_, __) =>
              const _SkeletonCard(),
    );
  }

  Widget _hataGorunumu() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.all(10),
      children: [
        _ErrorBox(
          text: _error!,
        ),
      ],
    );
  }

  Widget _bosGorunum() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(
          height: 115,
        ),
        Icon(
          Icons
              .inventory_2_outlined,
          size: 46,
          color:
              Colors.black26,
        ),
        SizedBox(
          height: 8,
        ),
        Text(
          'Kayıt bulunamadı',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color:
                Colors.black45,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TARİH
// ============================================================================

class _DateBox
    extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(9),
      child: Container(
        height: 42,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 7,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(0xFFF7F7F9),
          borderRadius:
              BorderRadius.circular(9),
          border: Border.all(
            color:
                Colors.black.withOpacity(.05),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons
                  .calendar_month_rounded,
              size: 16,
              color: accent,
            ),

            const SizedBox(
              width: 5,
            ),

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                        const TextStyle(
                      fontSize:
                          7.8,
                      color:
                          Colors.black38,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize:
                          10.5,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// KPI
// ============================================================================

class _KpiBox
    extends StatelessWidget {
  const _KpiBox({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 48,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF7F7F9),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color:
              Colors.black.withOpacity(.04),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: accent,
          ),

          const SizedBox(
            width: 4,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit:
                      BoxFit.scaleDown,
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    value,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 7.8,
                    color:
                        Colors.black45,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PALET KART
// ============================================================================

class _PaletCard
    extends StatelessWidget {
  const _PaletCard({
    required this.item,
    required this.timeFormatter,
    required this.dateFormatter,
    this.onDelete,
    this.onPrint,
    this.printing = false,
  });

  final PaletlemeRaporModel item;
  final DateFormat timeFormatter;
  final DateFormat dateFormatter;

  final VoidCallback? onDelete;
  final VoidCallback? onPrint;

  final bool printing;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(
    BuildContext context,
  ) {
    final dt =
        item.olusmaZamani;

    final dateStr =
        dt == null
            ? '-'
            : dateFormatter.format(dt);

    final timeStr =
        dt == null
            ? '-'
            : timeFormatter.format(dt);

    final musteri =
        (item.musteri ?? '').trim();

    final yuklenmedi =
        musteri.toLowerCase() ==
            'yüklenmedi';

    final net =
        (item.netKg ?? 0)
            .toStringAsFixed(2);

    final brut =
        (item.brutKg ?? 0)
            .toStringAsFixed(2);

    final ort =
        (item.paletOrtalamasi ?? 0)
            .toStringAsFixed(2);

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        9,
        7,
        7,
        7,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color:
              Colors.black.withOpacity(.055),
        ),
      ),
      child: Column(
        children: [
          // ÜST
          Row(
            children: [
              Container(
                width: 33,
                height: 33,
                decoration:
                    BoxDecoration(
                  color:
                      accent.withOpacity(.09),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons
                      .inventory_2_outlined,
                  color: accent,
                  size: 18,
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.paletKodu ??
                          '-',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    Text(
                      '$dateStr  $timeStr',
                      style:
                          const TextStyle(
                        fontSize: 9,
                        color:
                            Colors.black45,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                visualDensity:
                    VisualDensity.compact,
                padding:
                    EdgeInsets.zero,
                constraints:
                    const BoxConstraints(
                  minWidth: 30,
                  minHeight: 30,
                ),
                tooltip: 'Sil',
                onPressed:
                    onDelete,
                icon: Icon(
                  Icons
                      .delete_outline_rounded,
                  size: 18,
                  color:
                      Colors.red.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 5,
          ),

          Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              '${item.urunKodu ?? ''}  ${item.urunAdi ?? ''}'
                  .trim(),
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 10.5,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          // DURUM + ETİKET
          Row(
            children: [
              SizedBox(
                height: 31,
                child:
                    FilledButton.icon(
                  style:
                      FilledButton
                          .styleFrom(
                    backgroundColor:
                        accent,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 8,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              7),
                    ),
                  ),
                  onPressed:
                      onPrint,
                  icon: printing
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .print_rounded,
                          size: 14,
                        ),
                  label: const Text(
                    'ETİKET',
                    style:
                        TextStyle(
                      fontSize: 8.8,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              if (yuklenmedi)
                const _StatusBox(
                  text:
                      'Yüklenmedi',
                  color:
                      Colors.red,
                )
              else
                _StatusBox(
                  text:
                      musteri.isEmpty
                          ? '-'
                          : musteri,
                  color:
                      accent,
                ),
            ],
          ),

          const SizedBox(
            height: 6,
          ),

          Container(
            height: 46,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF7F7F9,
              ),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      _PaletMiniValue(
                    title: 'Kutu',
                    value:
                        '${item.kutuSayisi ?? 0}',
                  ),
                ),

                _dikeyCizgi(),

                Expanded(
                  child:
                      _PaletMiniValue(
                    title: 'Ort.',
                    value:
                        ort,
                  ),
                ),

                _dikeyCizgi(),

                Expanded(
                  child:
                      _PaletMiniValue(
                    title: 'Boş',
                    value:
                        (item.paletBosAgirligi ??
                                0)
                            .toStringAsFixed(
                                2),
                  ),
                ),

                _dikeyCizgi(),

                Expanded(
                  child:
                      _PaletMiniValue(
                    title: 'Net',
                    value: net,
                    highlighted:
                        true,
                  ),
                ),

                _dikeyCizgi(),

                Expanded(
                  child:
                      _PaletMiniValue(
                    title: 'Brüt',
                    value: brut,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dikeyCizgi() {
    return Container(
      width: 1,
      height: 27,
      color:
          Colors.black.withOpacity(.05),
    );
  }
}

class _PaletMiniValue
    extends StatelessWidget {
  const _PaletMiniValue({
    required this.title,
    required this.value,
    this.highlighted = false,
  });

  final String title;
  final String value;
  final bool highlighted;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Text(
          title,
          style:
              const TextStyle(
            fontSize: 7.5,
            color:
                Colors.black38,
          ),
        ),

        const SizedBox(
          height: 1,
        ),

        FittedBox(
          fit:
              BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 9.5,
              color: highlighted
                  ? accent
                  : Colors.black87,
              fontWeight:
                  highlighted
                      ? FontWeight.w900
                      : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DURUM
// ============================================================================

class _StatusBox
    extends StatelessWidget {
  const _StatusBox({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      constraints:
          const BoxConstraints(
        maxWidth: 160,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(.08),
        borderRadius:
            BorderRadius.circular(6),
        border: Border.all(
          color:
              color.withOpacity(.18),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 8.5,
          color: color,
          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }
}

// ============================================================================
// ÜRÜN FİLTRE
// ============================================================================

class _UrunChip
    extends StatelessWidget {
  const _UrunChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(7),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        alignment:
            Alignment.center,
        decoration:
            BoxDecoration(
          color: selected
              ? accent.withOpacity(.10)
              : const Color(
                  0xFFF7F7F9,
                ),
          borderRadius:
              BorderRadius.circular(7),
          border: Border.all(
            color: selected
                ? accent.withOpacity(.28)
                : Colors.black
                    .withOpacity(.045),
          ),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons
                    .check_rounded,
                size: 13,
                color: accent,
              ),

              const SizedBox(
                width: 3,
              ),
            ],

            ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 155,
              ),
              child: Text(
                text,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    TextStyle(
                  fontSize: 9,
                  color: selected
                      ? accent
                      : Colors.black54,
                  fontWeight:
                      selected
                          ? FontWeight.w900
                          : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ERROR
// ============================================================================

class _ErrorBox
    extends StatelessWidget {
  const _ErrorBox({
    required this.text,
  });

  final String text;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(9),
      decoration:
          BoxDecoration(
        color:
            Colors.red.withOpacity(.05),
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              Colors.red.withOpacity(.18),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons
                .error_outline_rounded,
            size: 17,
            color: Colors.red,
          ),

          const SizedBox(
            width: 6,
          ),

          Expanded(
            child: Text(
              text,
              style:
                  const TextStyle(
                fontSize: 9.5,
                color:
                    Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SKELETON
// ============================================================================

class _SkeletonCard
    extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 151,
      padding:
          const EdgeInsets.all(9),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color:
              Colors.black.withOpacity(.04),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _bar(
                w: 130,
                h: 12,
              ),

              const Spacer(),

              _bar(
                w: 70,
                h: 9,
              ),
            ],
          ),

          const SizedBox(
            height: 9,
          ),

          _bar(
            w: 220,
            h: 9,
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [
              _bar(
                w: 60,
                h: 28,
              ),

              const Spacer(),

              _bar(
                w: 90,
                h: 24,
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          _bar(
            w: double.infinity,
            h: 46,
          ),
        ],
      ),
    );
  }

  Widget _bar({
    required double w,
    required double h,
  }) {
    return Container(
      width: w,
      height: h,
      decoration:
          BoxDecoration(
        color:
            Colors.black.withOpacity(.06),
        borderRadius:
            BorderRadius.circular(6),
      ),
    );
  }
}

// ============================================================================
// PALET DETAY CARD
// ============================================================================

class _PaletDetayCard
    extends StatelessWidget {
  const _PaletDetayCard({
    required this.detay,
  });

  final PaletlemeRaporModel detay;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(
    BuildContext context,
  ) {
    final dt =
        detay.olusmaZamani;

    final dtStr =
        dt == null
            ? '-'
            : DateFormat(
                'dd.MM.yyyy  HH:mm',
              ).format(dt);

    final urun =
        (detay.urunAdi ?? '').trim();

    final urunKodu =
        (detay.urunKodu ?? '').trim();

    final palet =
        (detay.paletKodu ?? '').trim();

    final kutu =
        '${detay.kutuSayisi ?? 0}';

    final bos =
        (detay.paletBosAgirligi ?? 0)
            .toStringAsFixed(2);

    final net =
        (detay.netKg ?? 0)
            .toStringAsFixed(2);

    final brut =
        (detay.brutKg ?? 0)
            .toStringAsFixed(2);

    final ort =
        (detay.paletOrtalamasi ?? 0)
            .toStringAsFixed(2);

    return Container(
      padding:
          const EdgeInsets.all(10),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color:
              Colors.black.withOpacity(.05),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            palet.isEmpty
                ? '-'
                : palet,
            style:
                const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 2,
          ),

          Text(
            dtStr,
            style:
                const TextStyle(
              fontSize: 9.5,
              color:
                  Colors.black45,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            urun.isEmpty
                ? (urunKodu.isEmpty
                    ? '-'
                    : urunKodu)
                : '$urunKodu  $urun',
            style:
                const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Container(
            height: 48,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF7F7F9,
              ),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      _PaletMiniValue(
                    title: 'Kutu',
                    value: kutu,
                  ),
                ),
                Expanded(
                  child:
                      _PaletMiniValue(
                    title: 'Boş',
                    value: bos,
                  ),
                ),
                Expanded(
                  child:
                      _PaletMiniValue(
                    title: 'Ort.',
                    value: ort,
                  ),
                ),
                Expanded(
                  child:
                      _PaletMiniValue(
                    title: 'Net',
                    value: net,
                    highlighted:
                        true,
                  ),
                ),
                Expanded(
                  child:
                      _PaletMiniValue(
                    title: 'Brüt',
                    value: brut,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// QR / MANUEL
// ============================================================================

class _QrOrManualSheet
    extends StatefulWidget {
  const _QrOrManualSheet({
    required this.onManual,
    required this.onScan,
  });

  final ValueChanged<String>
      onManual;

  final VoidCallback onScan;

  @override
  State<_QrOrManualSheet>
      createState() =>
          _QrOrManualSheetState();
}

class _QrOrManualSheetState
    extends State<_QrOrManualSheet> {
  static const Color accent =
      Color(0xFF1E6F5C);

  final TextEditingController _ctrl =
      TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        10,
        8,
        10,
        MediaQuery.of(context)
                .viewInsets
                .bottom +
            10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6F8),
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration:
                  BoxDecoration(
                color:
                    Colors.black12,
                borderRadius:
                    BorderRadius.circular(
                        99),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Row(
              children: [
                Icon(
                  Icons
                      .qr_code_scanner_rounded,
                  size: 19,
                  color: accent,
                ),
                SizedBox(
                  width: 6,
                ),
                Text(
                  'Palet Kodu',
                  style:
                      TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            SizedBox(
              height: 45,
              child: TextField(
                controller:
                    _ctrl,
                autofocus: true,
                textInputAction:
                    TextInputAction.done,
                onSubmitted:
                    (value) {
                  final v =
                      value.trim();

                  if (v.isNotEmpty) {
                    widget.onManual(
                      v,
                    );
                  }
                },
                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                ),
                decoration:
                    InputDecoration(
                  hintText:
                      'P260221009 gibi...',
                  hintStyle:
                      const TextStyle(
                    fontSize: 10.5,
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  isDense: true,
                  prefixIcon:
                      const Icon(
                    Icons
                        .inventory_2_outlined,
                    size: 18,
                    color: accent,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            9),
                    borderSide:
                        BorderSide.none,
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            9),
                    borderSide:
                        BorderSide(
                      color: Colors
                          .black
                          .withOpacity(
                              .055),
                    ),
                  ),
                  focusedBorder:
                      const OutlineInputBorder(
                    borderRadius:
                        BorderRadius.all(
                      Radius.circular(
                          9),
                    ),
                    borderSide:
                        BorderSide(
                      color: accent,
                      width: 1.3,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          widget.onScan,
                      icon:
                          const Icon(
                        Icons
                            .qr_code_scanner_rounded,
                        size: 17,
                      ),
                      label:
                          const Text(
                        'TARA',
                        style:
                            TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            accent,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  9),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 6,
                ),

                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 42,
                    child:
                        FilledButton.icon(
                      onPressed: () {
                        final value =
                            _ctrl.text
                                .trim();

                        if (value
                            .isEmpty) {
                          return;
                        }

                        widget.onManual(
                          value,
                        );
                      },
                      icon:
                          const Icon(
                        Icons
                            .check_rounded,
                        size: 17,
                      ),
                      label:
                          const Text(
                        'KODU KULLAN',
                        style:
                            TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      style:
                          FilledButton.styleFrom(
                        backgroundColor:
                            accent,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  9),
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
    );
  }
}

// ============================================================================
// QR SCAN
// ============================================================================

class _QrScanPage
    extends StatefulWidget {
  const _QrScanPage();

  @override
  State<_QrScanPage>
      createState() =>
          _QrScanPageState();
}

class _QrScanPageState
    extends State<_QrScanPage> {
  bool _done = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.black,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text(
          'QR Oku',
          style: TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        backgroundColor:
            Colors.black,
        foregroundColor:
            Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect:
                (capture) {
              if (_done) {
                return;
              }

              final barcodes =
                  capture.barcodes;

              if (barcodes
                  .isEmpty) {
                return;
              }

              final code =
                  (barcodes.first
                              .rawValue ??
                          '')
                      .trim();

              if (code.isEmpty) {
                return;
              }

              _done = true;

              Navigator.pop(
                context,
                code,
              );
            },
          ),

          Align(
            alignment:
                Alignment.center,
            child: Container(
              width: 220,
              height: 220,
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                        16),
                border:
                    Border.all(
                  color:
                      Colors.white,
                  width: 2.5,
                ),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.black
                    .withOpacity(.55),
                borderRadius:
                    BorderRadius.circular(
                        9),
              ),
              child: const Text(
                'Palet QR / barkodunu okutun',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      Colors.white,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}