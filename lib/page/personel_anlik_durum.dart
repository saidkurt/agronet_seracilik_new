import 'package:agronet/widget/shimmer.dart';
import 'package:flutter/material.dart';

import 'package:agronet/api/personelanlik_api.dart';
import 'package:agronet/models/personelanlik_model.dart';

class PersonelAnlikDurumPage extends StatefulWidget {
  const PersonelAnlikDurumPage({
    super.key,
  });

  @override
  State<PersonelAnlikDurumPage> createState() =>
      _PersonelAnlikDurumPageState();
}

class _PersonelAnlikDurumPageState
    extends State<PersonelAnlikDurumPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  bool _loading = false;
  String? _error;

  final _api = PersonelAnlikApi();

  List<PersonelAnlikDurum> _data = [];

  final List<String> _seraList = const [
    '1.SERA',
    '2.SERA',
    '3.SERA',
    '4.SERA',
    '5.SERA',
  ];

  String _selectedSera = '1.SERA';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _fetch(),
    );
  }

  // ============================================================
  // VERİ
  // ============================================================

  Future<void> _fetch() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res =
          await _api.personelAnlikDurum(
        _selectedSera,
      );

      if (!mounted) return;

      setState(() {
        _data = res;
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
  // SERA
  // ============================================================

  void _onSeraChanged(
    String? value,
  ) {
    if (value == null) return;

    if (value == _selectedSera) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _selectedSera = value;
      _data = [];
      _error = null;
    });

    _fetch();
  }

  // ============================================================
  // SAYILAR
  // ============================================================

  int get _personelSayisi =>
      _data.length;

  int get _aktifIsSayisi {
    return _data
        .where(
          (e) =>
              e.yapilanis.trim().isNotEmpty,
        )
        .length;
  }

  int get _tunelSayisi {
    final set = <String>{};

    for (final item in _data) {
      final tunel =
          item.tunel.trim();

      if (tunel.isNotEmpty) {
        set.add(tunel);
      }
    }

    return set.length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
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

        appBar: AppBar(
          toolbarHeight: 48,
          title: const Text(
            'Personel Anlık Durum',
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
              visualDensity:
                  VisualDensity.compact,
              onPressed:
                  _loading ? null : _fetch,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 20,
              ),
            ),
          ],
        ),

        body: Column(
          children: [
            _ustPanel(),

            Expanded(
              child: RefreshIndicator(
                color: accent,
                onRefresh: _fetch,
                child: _icerik(),
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
      padding: const EdgeInsets.fromLTRB(
        9,
        7,
        9,
        7,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF7F7F9),
                    borderRadius:
                        BorderRadius.circular(9),
                    border: Border.all(
                      color: Colors.black
                          .withOpacity(.05),
                    ),
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
                          Icons.spa_outlined,
                          size: 17,
                          color: accent,
                        ),
                      ),

                      const SizedBox(width: 7),

                      Expanded(
                        child:
                            DropdownButtonHideUnderline(
                          child:
                              DropdownButton<String>(
                            value:
                                _selectedSera,
                            isExpanded: true,
                            icon: const Icon(
                              Icons
                                  .keyboard_arrow_down_rounded,
                              size: 19,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 11.5,
                              color:
                                  Colors.black87,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                            items: _seraList
                                .map(
                                  (sera) =>
                                      DropdownMenuItem<
                                          String>(
                                    value: sera,
                                    child: Text(
                                      sera,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged:
                                _loading
                                    ? null
                                    : _onSeraChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: _SummaryBox(
                  title: 'Personel',
                  value:
                      '$_personelSayisi',
                  icon: Icons
                      .groups_2_outlined,
                ),
              ),

              const SizedBox(width: 5),

              Expanded(
                child: _SummaryBox(
                  title: 'Aktif İş',
                  value:
                      '$_aktifIsSayisi',
                  icon: Icons
                      .work_outline_rounded,
                ),
              ),

              const SizedBox(width: 5),

              Expanded(
                child: _SummaryBox(
                  title: 'Tünel',
                  value:
                      '$_tunelSayisi',
                  icon: Icons
                      .view_column_outlined,
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
      return const _SkeletonList();
    }

    if (_error != null) {
      return _buildError();
    }

    if (_data.isEmpty) {
      return _buildEmpty();
    }

    final list = [..._data]
      ..sort(
        (a, b) {
          final k1 =
              '${a.tunel}|${a.koridor}|${a.personeladi}'
                  .toLowerCase();

          final k2 =
              '${b.tunel}|${b.koridor}|${b.personeladi}'
                  .toLowerCase();

          return k1.compareTo(k2);
        },
      );

    return ListView.separated(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        9,
        7,
        9,
        14,
      ),
      itemCount: list.length,
      separatorBuilder:
          (_, __) =>
              const SizedBox(
        height: 6,
      ),
      itemBuilder:
          (context, index) {
        return _PersonelCard(
          item: list[index],
        );
      },
    );
  }

  // ============================================================
  // HATA
  // ============================================================

  Widget _buildError() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        14,
      ),
      children: [
        Container(
          padding:
              const EdgeInsets.all(10),
          decoration:
              BoxDecoration(
            color: Colors.red
                .withOpacity(.05),
            borderRadius:
                BorderRadius.circular(10),
            border: Border.all(
              color: Colors.red
                  .withOpacity(.18),
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
                  color: Colors.red
                      .withOpacity(.09),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons
                      .warning_amber_rounded,
                  size: 18,
                  color: Colors.red,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hata oluştu',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      _error ?? '-',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 7),

                    SizedBox(
                      height: 34,
                      child:
                          FilledButton.icon(
                        onPressed: _fetch,
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
                                    8),
                          ),
                        ),
                        icon: const Icon(
                          Icons
                              .refresh_rounded,
                          size: 15,
                        ),
                        label:
                            const Text(
                          'TEKRAR DENE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOŞ
  // ============================================================

  Widget _buildEmpty() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 110),

        Icon(
          Icons.groups_outlined,
          size: 48,
          color: Colors.black26,
        ),

        SizedBox(height: 9),

        Text(
          'Personel bulunamadı',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w900,
            color: Colors.black54,
          ),
        ),

        SizedBox(height: 3),

        Text(
          'Seçili serada aktif personel bulunmuyor.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.black38,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ÖZET
// ============================================================================

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
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
        color: const Color(
          0xFFF7F7F9,
        ),
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              Colors.black.withOpacity(.04),
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

          const SizedBox(width: 5),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: accent,
                    fontWeight:
                        FontWeight.w900,
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
  final PersonelAnlikDurum item;

  const _PersonelCard({
    required this.item,
  });

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    final title = _nz(
      item.personeladi,
    );

    final type =
        item.personeltipi.trim();

    final tunel =
        _nz(item.tunel);

    final koridor =
        _nz(item.koridor);

    final job =
        item.yapilanis.trim();

    final start =
        item.sonbaslangicsaati.trim();

    final active =
        item.aktifsure.trim();

    final hasJob =
        job.isNotEmpty;

    final statusColor = hasJob
        ? Colors.green.shade700
        : Colors.orange.shade700;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        8,
        7,
        7,
        7,
      ),
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
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Container(
            width: 5,
            height: 68,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius:
                  BorderRadius.circular(5),
            ),
          ),

          const SizedBox(width: 8),

          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  accent.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: Text(
              _initials(title),
              style: const TextStyle(
                fontSize: 10.5,
                color: accent,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),

                    if (type.isNotEmpty)
                      Container(
                        constraints:
                            const BoxConstraints(
                          maxWidth: 105,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration:
                            BoxDecoration(
                          color: accent
                              .withOpacity(.08),
                          borderRadius:
                              BorderRadius.circular(6),
                          border: Border.all(
                            color: accent
                                .withOpacity(.15),
                          ),
                        ),
                        child: Text(
                          type,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 8.5,
                            color: accent,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(
                      Icons
                          .view_column_outlined,
                      size: 12,
                      color: accent,
                    ),

                    const SizedBox(width: 3),

                    Expanded(
                      child: Text(
                        '$tunel  •  $koridor',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Colors.black45,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                if (job.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .work_outline_rounded,
                        size: 12,
                        color: accent,
                      ),

                      const SizedBox(width: 3),

                      Expanded(
                        child: Text(
                          job,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 5),

                Row(
                  children: [
                    if (start.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .play_circle_outline_rounded,
                              size: 11,
                              color: Colors.black38,
                            ),

                            const SizedBox(width: 3),

                            Expanded(
                              child: Text(
                                'Başlangıç: $start',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style:
                                    const TextStyle(
                                  fontSize: 8.8,
                                  color:
                                      Colors.black45,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Spacer(),

                    if (active.isNotEmpty)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration:
                            BoxDecoration(
                          color: statusColor
                              .withOpacity(.08),
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Icon(
                              Icons
                                  .timer_outlined,
                              size: 11,
                              color: statusColor,
                            ),

                            const SizedBox(width: 3),

                            Text(
                              active,
                              style: TextStyle(
                                fontSize: 8.8,
                                color: statusColor,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _nz(
    String value,
  ) {
    final t = value.trim();

    return t.isEmpty ? '-' : t;
  }

  static String _initials(
    String name,
  ) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((x) => x.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
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
          return const _SkeletonCard();
        },
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      decoration: BoxDecoration(
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
          _bar(
            width: 36,
            height: 36,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _bar(
                  width: 160,
                  height: 11,
                ),

                const SizedBox(height: 7),

                _bar(
                  width: 120,
                  height: 8,
                ),

                const SizedBox(height: 7),

                _bar(
                  width: 190,
                  height: 9,
                ),

                const SizedBox(height: 7),

                _bar(
                  width: 140,
                  height: 8,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          _bar(
            width: 55,
            height: 24,
          ),
        ],
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