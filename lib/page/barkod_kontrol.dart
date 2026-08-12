import 'package:agronet/api/barkod_kontrol_api.dart';
import 'package:agronet/models/barkod_kontrol_model.dart';
import 'package:agronet/widget/shimmer.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class KoliBarkodPage extends StatefulWidget {
  const KoliBarkodPage({
    super.key,
  });

  @override
  State<KoliBarkodPage> createState() =>
      _KoliBarkodPageState();
}

class _KoliBarkodPageState
    extends State<KoliBarkodPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  final TextEditingController _ctrl =
      TextEditingController();

  bool _loading = false;

  String? _error;

  List<KoliBarkodModel> _items = const [];

  final DateFormat _fmt =
      DateFormat(
    "dd.MM.yyyy  HH:mm",
  );

  @override
  void dispose() {
    _ctrl.dispose();

    super.dispose();
  }

  // ============================================================
  // ARA
  // ============================================================

  Future<void> _ara() async {
    final barkod =
        _ctrl.text.trim();

    if (barkod.isEmpty) {
      _mesajGoster(
        'Barkod giriniz.',
        hata: true,
      );

      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _loading = true;

      _error = null;

      _items = const [];
    });

    try {
      final list =
          await KoliBarkodApi.getir(
        barkod,
      );

      if (!mounted) return;

      setState(() {
        _items = list;
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
  // TEMİZLE
  // ============================================================

  void _temizle() {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _ctrl.clear();

      _items = const [];

      _error = null;
    });
  }

  // ============================================================
  // MESAJ
  // ============================================================

  void _mesajGoster(
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
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
          elevation: 0,
          backgroundColor:
              Colors.white,
          surfaceTintColor:
              Colors.white,
          foregroundColor:
              Colors.black87,
          centerTitle: true,
          title: const Text(
            'Koli Barkod Sorgu',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          actions: [
            if (_ctrl.text.isNotEmpty ||
                _items.isNotEmpty)
              IconButton(
                tooltip: 'Temizle',
                visualDensity:
                    VisualDensity.compact,
                onPressed:
                    _loading
                        ? null
                        : _temizle,
                icon: const Icon(
                  Icons
                      .cleaning_services_outlined,
                  size: 20,
                ),
              ),
          ],
        ),

        // ========================================================
        // BODY
        // ========================================================

        body: SafeArea(
          child: Column(
            children: [
              _aramaAlani(),

              Expanded(
                child: _icerik(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ARAMA ALANI
  // ============================================================

  Widget _aramaAlani() {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: TextField(
                    controller: _ctrl,
                    enabled:
                        !_loading,
                    textInputAction:
                        TextInputAction
                            .search,
                    onSubmitted:
                        (_) => _ara(),
                    onChanged: (_) {
                      setState(() {});
                    },
                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                    ),
                    decoration:
                        InputDecoration(
                      labelText:
                          'Koli Barkodu',
                      hintText:
                          'Örn: AG04852',

                      labelStyle:
                          const TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                            FontWeight.w700,
                      ),

                      hintStyle:
                          const TextStyle(
                        fontSize: 11,
                        color:
                            Colors.black38,
                      ),

                      prefixIcon:
                          const Icon(
                        Icons
                            .qr_code_2_rounded,
                        size: 19,
                        color: accent,
                      ),

                      suffixIcon:
                          _ctrl.text.isEmpty
                              ? null
                              : IconButton(
                                  visualDensity:
                                      VisualDensity.compact,
                                  onPressed:
                                      _loading
                                          ? null
                                          : () {
                                              setState(() {
                                                _ctrl.clear();
                                              });
                                            },
                                  icon:
                                      const Icon(
                                    Icons.close_rounded,
                                    size:
                                        17,
                                  ),
                                ),

                      filled: true,
                      fillColor:
                          const Color(
                        0xFFF7F7F9,
                      ),

                      isDense: true,

                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 11,
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
              ),

              const SizedBox(
                width: 7,
              ),

              SizedBox(
                width: 86,
                height: 46,
                child:
                    FilledButton.icon(
                  onPressed:
                      _loading
                          ? null
                          : _ara,
                  style:
                      FilledButton
                          .styleFrom(
                    elevation: 0,
                    backgroundColor:
                        accent,
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 6,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              9),
                    ),
                  ),
                  icon: _loading
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
                      : const Icon(
                          Icons
                              .search_rounded,
                          size: 17,
                        ),
                  label: const Text(
                    'ARA',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 7,
          ),

          Row(
            children: [
              const Icon(
                Icons
                    .history_rounded,
                size: 15,
                color:
                    Colors.black38,
              ),

              const SizedBox(
                width: 5,
              ),

              const Text(
                'Son Kayıtlar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const Spacer(),

              Text(
                _loading
                    ? 'Yükleniyor...'
                    : '${_items.length} kayıt',
                style:
                    const TextStyle(
                  fontSize: 9.5,
                  color:
                      Colors.black45,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // İÇERİK
  // ============================================================

  Widget _icerik() {
    if (_loading) {
      return ListView.separated(
        padding:
            const EdgeInsets.fromLTRB(
          10,
          7,
          10,
          14,
        ),
        itemCount: 6,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          height: 6,
        ),
        itemBuilder:
            (_, __) =>
                const _ShimmerSkeletonCard(),
      );
    }

    if (_error != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          10,
          7,
          10,
          14,
        ),
        children: [
          _ErrorCard(
            message: _error!,
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return const _EmptyView();
    }

    return ListView.separated(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        10,
        7,
        10,
        14,
      ),
      itemCount:
          _items.length,
      separatorBuilder:
          (_, __) =>
              const SizedBox(
        height: 6,
      ),
      itemBuilder:
          (context, index) {
        final item =
            _items[index];

        final tarih =
            item.tartimZamani == null
                ? '-'
                : _fmt.format(
                    item.tartimZamani!,
                  );

        final personel =
            (item.personel ?? '')
                    .trim()
                    .isEmpty
                ? '-'
                : item.personel!;

        final bolum =
            (item.bolum ?? '')
                    .trim()
                    .isEmpty
                ? '-'
                : item.bolum!;

        final tunel =
            (item.tunel ?? '')
                    .trim()
                    .isEmpty
                ? '-'
                : item.tunel!;

        return _ResultCard(
          dt: tarih,
          personel: personel,
          bolum: bolum,
          tunel: tunel,
        );
      },
    );
  }
}

// ============================================================================
// SONUÇ KARTI
// ============================================================================

class _ResultCard extends StatelessWidget {
  final String dt;
  final String personel;
  final String bolum;
  final String tunel;

  static const Color accent =
      Color(0xFF1E6F5C);

  const _ResultCard({
    required this.dt,
    required this.personel,
    required this.bolum,
    required this.tunel,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 74,
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
      child: Row(
        children: [
          Container(
            width: 5,
            decoration:
                const BoxDecoration(
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

          const SizedBox(
            width: 9,
          ),

          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(
              color:
                  accent.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons
                  .inventory_2_outlined,
              color: accent,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  personel,
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

                const SizedBox(
                  height: 3,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons
                          .schedule_rounded,
                      size: 12,
                      color:
                          Colors.black38,
                    ),

                    const SizedBox(
                      width: 3,
                    ),

                    Expanded(
                      child: Text(
                        dt,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 9.5,
                          color:
                              Colors.black45,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 3,
                ),

                Row(
                  children: [
                    _miniBilgi(
                      Icons
                          .grid_view_rounded,
                      bolum,
                    ),

                    const SizedBox(
                      width: 9,
                    ),

                    _miniBilgi(
                      Icons
                          .view_column_outlined,
                      tunel,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color:
                Colors.black26,
          ),

          const SizedBox(
            width: 6,
          ),
        ],
      ),
    );
  }

  Widget _miniBilgi(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 11,
          color: accent,
        ),

        const SizedBox(
          width: 3,
        ),

        Text(
          text,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            fontSize: 9,
            color:
                Colors.black54,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BOŞ EKRAN
// ============================================================================

class _EmptyView
    extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(
          height: 115,
        ),

        Icon(
          Icons
              .qr_code_scanner_rounded,
          size: 48,
          color:
              Colors.black26,
        ),

        SizedBox(
          height: 9,
        ),

        Text(
          'Barkod sorgulayın',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w900,
            color:
                Colors.black54,
          ),
        ),

        SizedBox(
          height: 3,
        ),

        Text(
          'Koli barkodunu girip Ara butonuna basın.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color:
                Colors.black38,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// HATA
// ============================================================================

class _ErrorCard
    extends StatelessWidget {
  final String message;

  const _ErrorCard({
    required this.message,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(10),
      decoration:
          BoxDecoration(
        color:
            Colors.red.withOpacity(.05),
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color:
              Colors.red.withOpacity(.18),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration:
                BoxDecoration(
              color:
                  Colors.red.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons
                  .error_outline_rounded,
              color: Colors.red,
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
                const Text(
                  'Sorgu Hatası',
                  style:
                      TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  message,
                  style:
                      const TextStyle(
                    fontSize: 9.5,
                    color:
                        Colors.black54,
                    height: 1.25,
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
// SHIMMER
// ============================================================================

class _ShimmerSkeletonCard
    extends StatelessWidget {
  const _ShimmerSkeletonCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    final card =
        Container(
      height: 74,
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
      child: Row(
        children: [
          const SizedBox(
            width: 9,
          ),

          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(
              color: Colors.black
                  .withOpacity(.06),
              borderRadius:
                  BorderRadius.circular(9),
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _bar(
                  w: 150,
                  h: 10,
                ),

                const SizedBox(
                  height: 7,
                ),

                _bar(
                  w: 110,
                  h: 8,
                ),

                const SizedBox(
                  height: 7,
                ),

                Row(
                  children: [
                    _bar(
                      w: 55,
                      h: 8,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    _bar(
                      w: 55,
                      h: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Shimmer(
      child: card,
    );
  }

  static Widget _bar({
    double w = 140,
    double h = 10,
  }) {
    return Container(
      width: w,
      height: h,
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(6),
        color: Colors.black
            .withOpacity(.06),
      ),
    );
  }
}