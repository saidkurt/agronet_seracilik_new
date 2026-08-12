import 'package:agronet/widget/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/hasat_raporu_api.dart';
import '../../models/hasat_raporu_model.dart';
import 'package:intl/intl.dart';

enum HasatGroupBy {
  tunel,
  bolum,
  isitma,
  sulama,
  yon,
  kutuTipi,
  urunTipi,
  toplayan,
  okutan,
  paketleyen,
}

class HasatRaporuDetayliPage extends StatefulWidget {
  const HasatRaporuDetayliPage({super.key});

  @override
  State<HasatRaporuDetayliPage> createState() =>
      _HasatRaporuDetayliPageState();
}

class _HasatRaporuDetayliPageState
    extends State<HasatRaporuDetayliPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  final _api = HasatApi();

  DateTime _ilk = DateTime.now();
  DateTime _son = DateTime.now();

  final NumberFormat _nf =
      NumberFormat.decimalPattern('tr_TR');

  bool _loading = false;
  String? _err;

  List<HasatRaporuDetayModel> _rows = [];

  HasatGroupBy _groupBy = HasatGroupBy.bolum;

  @override
  void initState() {
    super.initState();

    _setTodayLocal();
    _fetch();
  }

  // ============================================================
  // TARİH
  // ============================================================

  void _setTodayLocal() {
    final n = DateTime.now();

    _ilk = DateTime(
      n.year,
      n.month,
      n.day,
    );

    _son = DateTime(
      n.year,
      n.month,
      n.day,
    );
  }

  Future<void> _setTodayAndFetch() async {
    setState(_setTodayLocal);

    await _fetch();
  }

  Future<void> _pickRange() async {
    final picked =
        await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _ilk,
        end: _son,
      ),
      helpText: 'Tarih Aralığı Seç',
    );

    if (picked == null) return;

    setState(() {
      _ilk = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );

      _son = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
      );
    });

    await _fetch();
  }

  // ============================================================
  // VERİ
  // ============================================================

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      final data =
          await _api.getHasatRaporuDetayli(
        _ilk,
        _son,
      );

      if (!mounted) return;

      setState(() {
        _rows = data;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _err = e
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
  // FORMAT
  // ============================================================

  String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';
  }

  String _fmtInt(num? v) {
    return _nf.format(
      (v ?? 0).round(),
    );
  }

  // ============================================================
  // KPI
  // ============================================================

  double get _sumBrut {
    return _rows.fold(
      0.0,
      (p, e) => p + (e.brutKg ?? 0),
    );
  }

  double get _sumNet {
    return _rows.fold(
      0.0,
      (p, e) => p + (e.netKg ?? 0),
    );
  }

  double get _sumDara {
    return _rows.fold(
      0.0,
      (p, e) => p + (e.dara ?? 0),
    );
  }

  // ============================================================
  // GROUP
  // ============================================================

  String _groupTitle(
    HasatGroupBy g,
  ) {
    switch (g) {
      case HasatGroupBy.tunel:
        return 'Tünel';

      case HasatGroupBy.bolum:
        return 'Bölüm';

      case HasatGroupBy.isitma:
        return 'Isıtma Sektörü';

      case HasatGroupBy.sulama:
        return 'Sulama Sektörü';

      case HasatGroupBy.yon:
        return 'Tünel Yönü';

      case HasatGroupBy.kutuTipi:
        return 'Kutu Tipi';

      case HasatGroupBy.urunTipi:
        return 'Ürün Tipi';

      case HasatGroupBy.toplayan:
        return 'Toplayan Personel';

      case HasatGroupBy.okutan:
        return 'Okutan Personel';

      case HasatGroupBy.paketleyen:
        return 'Paketleyen Personel';
    }
  }

  String _groupKey(
    HasatRaporuDetayModel r,
  ) {
    switch (_groupBy) {
      case HasatGroupBy.tunel:
        return r.tunel ?? '-';

      case HasatGroupBy.bolum:
        return r.bolum ?? '-';

      case HasatGroupBy.isitma:
        return r.isitmaSektoru ?? '-';

      case HasatGroupBy.sulama:
        return r.sulamaSektoru ?? '-';

      case HasatGroupBy.yon:
        return r.tunelYonu ?? '-';

      case HasatGroupBy.kutuTipi:
        return r.kutuTipi ?? '-';

      case HasatGroupBy.urunTipi:
        return r.urunTipi ?? '-';

      case HasatGroupBy.toplayan:
        return r.toplayanPersonel ?? '-';

      case HasatGroupBy.okutan:
        return r.okutanPersonel ?? '-';

      case HasatGroupBy.paketleyen:
        return r.paketleyenPersonel ?? '-';
    }
  }

  Map<String, List<HasatRaporuDetayModel>>
      get _grouped {
    final map =
        <String, List<HasatRaporuDetayModel>>{};

    for (final row in _rows) {
      final key = _groupKey(row);

      (map[key] ??= []).add(row);
    }

    return map;
  }

  // ============================================================
  // GROUP SEÇ
  // ============================================================

  void _openGroupBySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height *
                    .72,
          ),
          decoration: const BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),

                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius:
                        BorderRadius.circular(99),
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
                        decoration: BoxDecoration(
                          color:
                              accent.withOpacity(.09),
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons
                              .pivot_table_chart_outlined,
                          size: 17,
                          color: accent,
                        ),
                      ),

                      const SizedBox(width: 7),

                      const Expanded(
                        child: Text(
                          'Gruplama Seç',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.fromLTRB(
                      9,
                      0,
                      9,
                      10,
                    ),
                    itemCount:
                        HasatGroupBy.values.length,
                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      height: 4,
                    ),
                    itemBuilder:
                        (_, index) {
                      final group =
                          HasatGroupBy.values[index];

                      final selected =
                          group == _groupBy;

                      return Material(
                        color: selected
                            ? accent.withOpacity(.08)
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(9),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(9),
                          onTap: () {
                            HapticFeedback
                                .selectionClick();

                            setState(() {
                              _groupBy = group;
                            });

                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 44,
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(9),
                              border: Border.all(
                                color: selected
                                    ? accent.withOpacity(.22)
                                    : Colors.black.withOpacity(.045),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _groupTitle(group),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: selected
                                          ? accent
                                          : Colors.black87,
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                                  ),
                                ),

                                if (selected)
                                  const Icon(
                                    Icons
                                        .check_circle_rounded,
                                    color: accent,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
            'Hasat Raporu',
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
              tooltip: 'Bugün',
              visualDensity: VisualDensity.compact,
              onPressed: _loading
                  ? null
                  : _setTodayAndFetch,
              icon: const Icon(
                Icons.today_rounded,
                size: 20,
              ),
            ),

            IconButton(
              tooltip: 'Yenile',
              visualDensity: VisualDensity.compact,
              onPressed:
                  _loading ? null : _fetch,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 20,
              ),
            ),
          ],
        ),

        body: SafeArea(
          child: Column(
            children: [
              _topPanel(),

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  9,
                  6,
                  9,
                  0,
                ),
                child: _loading
                    ? const _KpiSkeletonRow()
                    : _kpiRow(),
              ),

              const SizedBox(height: 6),

              _groupByPickerTile(),

              if (_err != null)
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    9,
                    6,
                    9,
                    0,
                  ),
                  child: _ErrorBox(
                    text: _err!,
                  ),
                ),

              Expanded(
                child: _body(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ÜST PANEL
  // ============================================================

  Widget _topPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        9,
        7,
        9,
        7,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(9),
        onTap:
            _loading ? null : _pickRange,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
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
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color:
                      accent.withOpacity(.09),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  size: 17,
                  color: accent,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tarih Aralığı',
                      style: TextStyle(
                        fontSize: 8.5,
                        color: Colors.black38,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_fmtDate(_ilk)}  →  ${_fmtDate(_son)}',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // KPI
  // ============================================================

  Widget _kpiRow() {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            title: 'Brüt KG',
            value: _sumBrut,
            icon:
                Icons.monitor_weight_outlined,
          ),
        ),

        const SizedBox(width: 5),

        Expanded(
          child: _KpiCard(
            title: 'Net KG',
            value: _sumNet,
            icon: Icons.scale_rounded,
          ),
        ),

        const SizedBox(width: 5),

        Expanded(
          child: _KpiCard(
            title: 'Dara',
            value: _sumDara,
            icon: Icons.remove_rounded,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GROUP TILE
  // ============================================================

  Widget _groupByPickerTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      child: Material(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(9),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(9),
          onTap: _openGroupBySheet,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
            ),
            decoration: BoxDecoration(
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color:
                        accent.withOpacity(.09),
                    borderRadius:
                        BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons
                        .pivot_table_chart_outlined,
                    size: 16,
                    color: accent,
                  ),
                ),

                const SizedBox(width: 7),

                const Text(
                  'Grupla',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.black45,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    _groupTitle(_groupBy),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),

                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _body() {
    if (_loading) {
      return const _HasatSkeleton();
    }

    if (_rows.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 110),
          Icon(
            Icons.inventory_2_outlined,
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
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      );
    }

    final groups =
        _grouped.entries.toList()
          ..sort(
            (a, b) =>
                a.key.compareTo(b.key),
          );

    return RefreshIndicator(
      color: accent,
      onRefresh: _fetch,
      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          9,
          7,
          9,
          14,
        ),
        itemCount: groups.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          height: 6,
        ),
        itemBuilder: (_, index) {
          final key = groups[index].key;
          final items =
              groups[index].value;

          final brut = items.fold(
            0.0,
            (p, e) =>
                p + (e.brutKg ?? 0),
          );

          final net = items.fold(
            0.0,
            (p, e) =>
                p + (e.netKg ?? 0),
          );

          final dara = items.fold(
            0.0,
            (p, e) =>
                p + (e.dara ?? 0),
          );

          return _GroupCard(
            title: key,
            count: items.length,
            net: _fmtInt(net),
            brut: _fmtInt(brut),
            dara: _fmtInt(dara),
            onTap: () {
              _openGroup(
                key,
                items,
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // GRUP DETAY
  // ============================================================

  void _openGroup(
    String key,
    List<HasatRaporuDetayModel> items,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (_) {
        final brut = items.fold(
          0.0,
          (p, e) =>
              p + (e.brutKg ?? 0),
        );

        final net = items.fold(
          0.0,
          (p, e) =>
              p + (e.netKg ?? 0),
        );

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .82,
          minChildSize: .45,
          maxChildSize: .95,
          builder:
              (context, controller) {
            return Container(
              decoration:
                  const BoxDecoration(
                color: bg,
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius:
                          BorderRadius.circular(99),
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      10,
                      8,
                      10,
                      7,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            key,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),

                        _SmallBadge(
                          text:
                              'Net ${_fmtInt(net)}',
                          accent: true,
                        ),

                        const SizedBox(width: 5),

                        _SmallBadge(
                          text:
                              'Brüt ${_fmtInt(brut)}',
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      padding:
                          const EdgeInsets.fromLTRB(
                        9,
                        0,
                        9,
                        12,
                      ),
                      itemCount: items.length,
                      separatorBuilder:
                          (_, __) =>
                              const SizedBox(
                        height: 5,
                      ),
                      itemBuilder:
                          (_, index) {
                        final row =
                            items[index];

                        final title =
                            row.kutuTipi ?? '-';

                        final dateStr =
                            row.toplamaTarihi != null
                                ? _fmtDate(
                                    row.toplamaTarihi!,
                                  )
                                : '-';

                        final sub =
                            '${row.toplayanPersonel ?? '-'}'
                            ' • ${row.tunel ?? '-'}'
                            ' • $dateStr';

                        return _GroupRowCard(
                          title: title,
                          subtitle: sub,
                          net:
                              (row.netKg ?? 0)
                                  .toStringAsFixed(2),
                          onTap: () {
                            _openRow(row);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // SATIR DETAY
  // ============================================================

  void _openRow(
    HasatRaporuDetayModel r,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (_) {
        return Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height *
                    .88,
          ),
          decoration:
              const BoxDecoration(
            color: bg,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(
                10,
                8,
                10,
                14,
              ),
              child: Column(
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

                  const SizedBox(height: 8),

                  _detailHeader(
                    'Hasat Detayı',
                  ),

                  const SizedBox(height: 7),

                  _InfoRow(
                    'Toplayan',
                    r.toplayanPersonel,
                  ),

                  _InfoRow(
                    'Toplanma Tarihi',
                    r.toplamaTarihi != null
                        ? _fmtDate(
                            r.toplamaTarihi!,
                          )
                        : null,
                  ),

                  _InfoRow(
                    'Bölüm',
                    r.bolum,
                  ),

                  _InfoRow(
                    'Tünel',
                    r.tunel,
                  ),

                  _InfoRow(
                    'Isıtma',
                    r.isitmaSektoru,
                  ),

                  _InfoRow(
                    'Sulama',
                    r.sulamaSektoru,
                  ),

                  _InfoRow(
                    'Yön',
                    r.tunelYonu,
                  ),

                  _InfoRow(
                    'Kutu Tipi',
                    r.kutuTipi,
                  ),

                  _InfoRow(
                    'Ürün Tipi',
                    r.urunTipi,
                  ),

                  _InfoRow(
                    'Okutan',
                    r.okutanPersonel,
                  ),

                  _InfoRow(
                    'Paketleyen',
                    r.paketleyenPersonel,
                  ),

                  _InfoRow(
                    'Paketleme Tarihi',
                    r.paketlemeTarihi != null
                        ? _fmtDate(
                            r.paketlemeTarihi!,
                          )
                        : null,
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      Expanded(
                        child: _miniKpi(
                          'Brüt',
                          r.brutKg ?? 0,
                        ),
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: _miniKpi(
                          'Net',
                          r.netKg ?? 0,
                          highlighted: true,
                        ),
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: _miniKpi(
                          'Dara',
                          r.dara ?? 0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  _InfoRow(
                    'Personel Tipi',
                    r.personelTipi,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailHeader(
    String title,
  ) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  accent.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: accent,
              size: 16,
            ),
          ),

          const SizedBox(width: 7),

          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniKpi(
    String title,
    num value, {
    bool highlighted = false,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF7F7F9,
        ),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color:
              Colors.black.withOpacity(.045),
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 8.5,
              color: Colors.black45,
            ),
          ),

          const SizedBox(height: 2),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _fmtInt(value),
              style: TextStyle(
                fontSize: 12.5,
                color: highlighted
                    ? accent
                    : Colors.black87,
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

// ============================================================================
// KPI CARD
// ============================================================================

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final double value;
  final IconData icon;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
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
            width: 27,
            height: 27,
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    NumberFormat
                            .decimalPattern(
                                'tr_TR')
                        .format(
                      value.round(),
                    ),
                    style: const TextStyle(
                      fontSize: 12.5,
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
// GROUP CARD
// ============================================================================

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.title,
    required this.count,
    required this.net,
    required this.brut,
    required this.dara,
    required this.onTap,
  });

  final String title;
  final int count;
  final String net;
  final String brut;
  final String dara;
  final VoidCallback onTap;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(10),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
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

              const SizedBox(width: 9),

              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      accent.withOpacity(.09),
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  color: accent,
                  size: 20,
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

                        Text(
                          '$count kayıt',
                          style: const TextStyle(
                            fontSize: 8.5,
                            color: Colors.black38,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        _InlineValue(
                          label: 'Net',
                          value: net,
                          highlighted: true,
                        ),

                        const SizedBox(width: 7),

                        _InlineValue(
                          label: 'Brüt',
                          value: brut,
                        ),

                        const SizedBox(width: 7),

                        _InlineValue(
                          label: 'Dara',
                          value: dara,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: Colors.black26,
              ),

              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// INLINE VALUE
// ============================================================================

class _InlineValue extends StatelessWidget {
  const _InlineValue({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label $value',
      style: TextStyle(
        fontSize: 9,
        color: highlighted
            ? accent
            : Colors.black54,
        fontWeight: highlighted
            ? FontWeight.w900
            : FontWeight.w700,
      ),
    );
  }
}

// ============================================================================
// GROUP DETAY SATIRI
// ============================================================================

class _GroupRowCard extends StatelessWidget {
  const _GroupRowCard({
    required this.title,
    required this.subtitle,
    required this.net,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String net;
  final VoidCallback onTap;

  static const Color accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(9),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          decoration: BoxDecoration(
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
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color:
                      accent.withOpacity(.09),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: accent,
                  size: 17,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8.8,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Net',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.black38,
                    ),
                  ),

                  Text(
                    net,
                    style: const TextStyle(
                      fontSize: 11,
                      color: accent,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 5),

              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// INFO ROW
// ============================================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow(
    this.keyText,
    this.value,
  );

  final String keyText;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      
      margin: const EdgeInsets.only(
        bottom: 4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color:
              Colors.black.withOpacity(.045),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              keyText,
              style: const TextStyle(
                fontSize: 9.5,
                color: Colors.black45,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              (value ?? '-').trim().isEmpty
                  ? '-'
                  : value!,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black87,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SMALL BADGE
// ============================================================================

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.text,
    this.accent = false,
  });

  final String text;
  final bool accent;

  static const Color green =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: accent
            ? green.withOpacity(.08)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(6),
        border: Border.all(
          color: accent
              ? green.withOpacity(.17)
              : Colors.black.withOpacity(.05),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.5,
          color: accent
              ? green
              : Colors.black54,
          fontWeight: FontWeight.w800,
        ),
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

class _HasatSkeleton extends StatelessWidget {
  const _HasatSkeleton();

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
        itemCount: 6,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          height: 6,
        ),
        itemBuilder: (_, __) {
          return const _SkeletonGroupCard();
        },
      ),
    );
  }
}

class _SkeletonGroupCard
    extends StatelessWidget {
  const _SkeletonGroupCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
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
          _sk(
            36,
            36,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _sk(
                  150,
                  11,
                ),

                const SizedBox(height: 8),

                _sk(
                  220,
                  9,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sk(
    double width,
    double height,
  ) {
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

// ============================================================================
// KPI SKELETON
// ============================================================================

class _KpiSkeletonRow
    extends StatelessWidget {
  const _KpiSkeletonRow();

  @override
  Widget build(BuildContext context) {
    Widget item() {
      return Expanded(
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(9),
            border: Border.all(
              color:
                  Colors.black.withOpacity(.04),
            ),
          ),
          child: Row(
            children: [
              _sk(
                27,
                27,
              ),

              const SizedBox(width: 5),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _sk(
                      48,
                      10,
                    ),

                    const SizedBox(height: 5),

                    _sk(
                      38,
                      7,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        item(),
        const SizedBox(width: 5),
        item(),
        const SizedBox(width: 5),
        item(),
      ],
    );
  }

  static Widget _sk(
    double width,
    double height,
  ) {
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