import 'package:agronet/api/paketleme_rapor_api.dart';
import 'package:agronet/widget/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:agronet/models/paketleme_rapor_model.dart';

class PaketlemeRaporPage extends StatefulWidget {
  const PaketlemeRaporPage({super.key});

  @override
  State<PaketlemeRaporPage> createState() =>
      _PaketlemeRaporPageState();
}

class _PaketlemeRaporPageState
    extends State<PaketlemeRaporPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  final PaketlemeApi _api = const PaketlemeApi();

  DateTime _ilkTarih = DateTime.now();
  DateTime _sonTarih = DateTime.now();

  bool _loading = false;
  String? _error;

  List<PaketlemeRaporModel> _items = [];

  final DateFormat _fmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _getir();
  }

  // ============================================================
  // TARİH
  // ============================================================

  Future<void> _pickDate({
    required bool isIlk,
  }) async {
    final initial =
        isIlk ? _ilkTarih : _sonTarih;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(
        DateTime.now().year - 2,
      ),
      lastDate: DateTime(
        DateTime.now().year + 1,
      ),
    );

    if (picked == null) return;

    setState(() {
      if (isIlk) {
        _ilkTarih = picked;

        if (_sonTarih.isBefore(_ilkTarih)) {
          _sonTarih = _ilkTarih;
        }
      } else {
        _sonTarih = picked;

        if (_sonTarih.isBefore(_ilkTarih)) {
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
          await _api.paketlemeGetir(
        _ilkTarih,
        _sonTarih,
      );

      if (!mounted) return;

      setState(() {
        _items = data;
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
  // VERİLER
  // ============================================================

  PaketlemeRaporModel? get _hataliRow {
    try {
      return _items.firstWhere(
        (x) => x.personelKod == null,
      );
    } catch (_) {
      return null;
    }
  }

  List<PaketlemeRaporModel> get _personelRows {
    return _items
        .where(
          (x) => x.personelKod != null,
        )
        .toList();
  }

  int _sumInt(
    int? Function(PaketlemeRaporModel x) pick,
  ) {
    int toplam = 0;

    for (final item in _personelRows) {
      toplam += pick(item) ?? 0;
    }

    return toplam;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final toplam =
        _sumInt((x) => x.toplam);

    final salkim =
        _sumInt(
      (x) => x.salkimDomates,
    );

    final ikinci =
        _sumInt(
      (x) => x.ikinciKalite,
    );

    final scaler =
        MediaQuery.textScalerOf(context).clamp(
      maxScaleFactor: 1.06,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: scaler,
      ),
      child: Scaffold(
        backgroundColor: bg,

        // ======================================================
        // APP BAR
        // ======================================================

        appBar: AppBar(
          toolbarHeight: 48,
          title: const Text(
            'Paketleme Raporu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: Colors.black87,
          actions: [
            IconButton(
              tooltip: 'Yenile',
              visualDensity: VisualDensity.compact,
              onPressed:
                  _loading ? null : _getir,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 20,
              ),
            ),
          ],
        ),

        body: Column(
          children: [
            // ==================================================
            // ÜST PANEL
            // ==================================================

            _TopPanel(
              loading: _loading,
              ilk: _ilkTarih,
              son: _sonTarih,
              fmt: _fmt,
              onPickIlk: () {
                _pickDate(
                  isIlk: true,
                );
              },
              onPickSon: () {
                _pickDate(
                  isIlk: false,
                );
              },
              onGetir: _getir,
            ),

            // ==================================================
            // KPI
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                9,
                6,
                9,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Toplam',
                      value: '$toplam',
                      icon:
                          Icons.summarize_rounded,
                    ),
                  ),

                  const SizedBox(width: 5),

                  Expanded(
                    child: _SummaryCard(
                      title: 'Salkım',
                      value: '$salkim',
                      icon: Icons
                          .local_florist_rounded,
                    ),
                  ),

                  const SizedBox(width: 5),

                  Expanded(
                    child: _SummaryCard(
                      title: '2.Kalite',
                      value: '$ikinci',
                      icon:
                          Icons.verified_rounded,
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  9,
                  6,
                  9,
                  0,
                ),
                child: _ErrorBox(
                  text: _error!,
                ),
              ),

            // ==================================================
            // LİSTE
            // ==================================================

            Expanded(
              child: _loading
                  ? const _SkeletonList()
                  : _personelRows.isEmpty
                      ? _bosGorunum()
                      : RefreshIndicator(
                          color: accent,
                          onRefresh: _getir,
                          child:
                              ListView.separated(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(
                              9,
                              7,
                              9,
                              14,
                            ),
                            itemCount:
                                _personelRows.length +
                                    (_hataliRow !=
                                            null
                                        ? 1
                                        : 0),
                            separatorBuilder:
                                (_, __) =>
                                    const SizedBox(
                              height: 6,
                            ),
                            itemBuilder:
                                (context, index) {
                              final hataliIndex =
                                  _personelRows
                                      .length;

                              if (_hataliRow !=
                                      null &&
                                  index ==
                                      hataliIndex) {
                                return _HataliCard(
                                  count:
                                      _hataliRow!
                                              .salkimDomates ??
                                          0,
                                );
                              }

                              return _PersonelCard(
                                item:
                                    _personelRows[
                                        index],
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

  Widget _bosGorunum() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 115),
        Icon(
          Icons.analytics_outlined,
          size: 46,
          color: Colors.black26,
        ),
        SizedBox(height: 8),
        Text(
          'Kayıt bulunamadı',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black45,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ÜST PANEL
// ============================================================================

class _TopPanel extends StatelessWidget {
  const _TopPanel({
    required this.loading,
    required this.ilk,
    required this.son,
    required this.fmt,
    required this.onPickIlk,
    required this.onPickSon,
    required this.onGetir,
  });

  final bool loading;
  final DateTime ilk;
  final DateTime son;
  final DateFormat fmt;

  final VoidCallback onPickIlk;
  final VoidCallback onPickSon;
  final VoidCallback onGetir;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        9,
        7,
        9,
        7,
      ),
      child: Row(
        children: [
          Expanded(
            child: _DateBox(
              label: 'İlk',
              value: fmt.format(ilk),
              onTap:
                  loading ? null : onPickIlk,
            ),
          ),

          const SizedBox(width: 5),

          Expanded(
            child: _DateBox(
              label: 'Son',
              value: fmt.format(son),
              onTap:
                  loading ? null : onPickSon,
            ),
          ),

          const SizedBox(width: 5),

          SizedBox(
            width: 74,
            height: 42,
            child: FilledButton(
              onPressed:
                  loading ? null : onGetir,
              style:
                  FilledButton.styleFrom(
                backgroundColor: accent,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(9),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'GETİR',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TARİH
// ============================================================================

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(9),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFFF7F7F9,
          ),
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
              Icons.calendar_month_rounded,
              size: 16,
              color: accent,
            ),

            const SizedBox(width: 5),

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 7.8,
                      color: Colors.black38,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
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
// ÖZET
// ============================================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              Colors.black.withOpacity(.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color:
                  accent.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 15,
              color: accent,
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 13,
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
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.black45,
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
// PERSONEL KART
// ============================================================================

class _PersonelCard extends StatelessWidget {
  const _PersonelCard({
    required this.item,
  });

  final PaketlemeRaporModel item;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    final kod =
        item.personelKod?.toString() ?? '-';

    final salkim =
        item.salkimDomates ?? 0;

    final ikinci =
        item.ikinciKalite ?? 0;

    final toplam =
        item.toplam ?? 0;

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color:
              Colors.black.withOpacity(.055),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            decoration: const BoxDecoration(
              color: accent,
              borderRadius:
                  BorderRadius.only(
                topLeft:
                    Radius.circular(9),
                bottomLeft:
                    Radius.circular(9),
              ),
            ),
          ),

          const SizedBox(width: 9),

          Container(
            width: 36,
            height: 36,
            alignment:
                Alignment.center,
            decoration: BoxDecoration(
              color:
                  accent.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: Text(
              _basHarf(
                item.personel,
              ),
              style: const TextStyle(
                fontSize: 11,
                color: accent,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.personel.trim(),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Kod: $kod',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black45,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    _MiniValue(
                      label: 'Salkım',
                      value: '$salkim',
                    ),

                    const SizedBox(width: 5),

                    _MiniValue(
                      label: '2.Kalite',
                      value: '$ikinci',
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            width: 69,
            margin:
                const EdgeInsets.symmetric(
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF7F7F9),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Text(
                  'Toplam',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.black38,
                  ),
                ),

                const SizedBox(height: 2),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$toplam',
                    style: const TextStyle(
                      fontSize: 15,
                      color: accent,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),
        ],
      ),
    );
  }

  static String _basHarf(
    String personel,
  ) {
    final parcalar = personel
        .trim()
        .split(
          RegExp(r'\s+'),
        )
        .where(
          (x) => x.isNotEmpty,
        )
        .toList();

    if (parcalar.isEmpty) {
      return '?';
    }

    if (parcalar.length == 1) {
      return parcalar.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parcalar.first.substring(0, 1)}'
            '${parcalar.last.substring(0, 1)}'
        .toUpperCase();
  }
}

// ============================================================================
// MINI VALUE
// ============================================================================

class _MiniValue extends StatelessWidget {
  const _MiniValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color:
            accent.withOpacity(.07),
        borderRadius:
            BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 8.5,
          color: accent,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================================
// HATALI BARKOD
// ============================================================================

class _HataliCard extends StatelessWidget {
  const _HataliCard({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      decoration: BoxDecoration(
        color:
            Colors.red.withOpacity(.055),
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              Colors.red.withOpacity(.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color:
                  Colors.red.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 17,
            ),
          ),

          const SizedBox(width: 7),

          const Expanded(
            child: Text(
              'Hatalı Barkod',
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),

          Text(
            '$count',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.red,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ERROR
// ============================================================================

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
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
            Icons.error_outline_rounded,
            size: 17,
            color: Colors.red,
          ),

          const SizedBox(width: 6),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 9.5,
                color: Colors.black54,
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

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          9,
          7,
          9,
          14,
        ),
        itemCount: 7,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          height: 6,
        ),
        itemBuilder: (_, __) {
          return Container(
            height: 76,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(10),
              border: Border.all(
                color: Colors.black
                    .withOpacity(.04),
              ),
            ),
            child: Row(
              children: [
                _bar(
                  width: 36,
                  height: 36,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _bar(
                        width: 150,
                        height: 11,
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      _bar(
                        width: 80,
                        height: 8,
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      _bar(
                        width: 140,
                        height: 18,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                _bar(
                  width: 60,
                  height: 50,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _bar({
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color:
            Colors.black.withOpacity(.06),
        borderRadius:
            BorderRadius.circular(6),
      ),
    );
  }
}