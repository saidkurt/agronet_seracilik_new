import 'package:agronet/api/personelmesai_api.dart';
import 'package:agronet/widget/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class PersonelMesai extends StatefulWidget {
  final String bileklikno_1;

  const PersonelMesai({
    Key? key,
    required this.bileklikno_1,
  }) : super(key: key);

  @override
  State<PersonelMesai> createState() =>
      _PersonelMesaiState();
}

class _PersonelMesaiState extends State<PersonelMesai> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    _getir();
  }

  // ============================================================
  // VERİ
  // ============================================================

  Future<void> _getir() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await PersonelMesaiApi().mesaiDurumu(
        bileklikid: widget.bileklikno_1,
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
            'Personel Mesai Raporu',
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

        body: RefreshIndicator(
          color: accent,
          onRefresh: _getir,
          child: AnimatedSwitcher(
            duration:
                const Duration(milliseconds: 180),
            child: _loading
                ? const _LoadingView(
                    key: ValueKey('loading'),
                  )
                : _error != null
                    ? _errorView()
                    : _buildContent(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HATA
  // ============================================================

  Widget _errorView() {
    return ListView(
      key: const ValueKey('error'),
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        14,
      ),
      children: [
        const SizedBox(height: 80),

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(.05),
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
                decoration: BoxDecoration(
                  color:
                      Colors.red.withOpacity(.09),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 18,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Veriler alınamadı',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _error ?? '-',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      height: 34,
                      child: FilledButton.icon(
                        onPressed: _getir,
                        style:
                            FilledButton.styleFrom(
                          backgroundColor:
                              accent,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 15,
                        ),
                        label: const Text(
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
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    final data =
        List<Map<String, dynamic>>.from(_data);

    if (data.isEmpty) {
      return ListView(
        key: const ValueKey('empty'),
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 110),
          Icon(
            Icons.schedule_outlined,
            size: 46,
            color: Colors.black26,
          ),
          SizedBox(height: 8),
          Text(
            'Mesai kaydı bulunamadı',
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

    // En yeni gün üstte.
    data.sort(
      (a, b) => _parseDate(
        b['tarih'],
      ).compareTo(
        _parseDate(
          a['tarih'],
        ),
      ),
    );

    // En yeni kaydın ayı.
    final latest =
        _parseDate(data.first['tarih']);

    final monthStart = DateTime(
      latest.year,
      latest.month,
      1,
    );

    final monthEnd = DateTime(
      latest.year,
      latest.month + 1,
      0,
    );

    final monthRows = data.where(
      (row) {
        final d =
            _parseDate(row['tarih']);

        return !d.isBefore(monthStart) &&
            !d.isAfter(monthEnd);
      },
    ).toList();

    final primPuan =
        _sumPuan(monthRows);

    final weeks =
        _groupByMonthWeek(monthRows);

    final monthTitle =
        intl.DateFormat(
      'MMMM yyyy',
      'tr_TR',
    ).format(monthStart);

    return ListView(
      key: const ValueKey('content'),
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        9,
        7,
        9,
        14,
      ),
      children: [
        _ustBilgi(
          monthTitle,
          monthRows.length,
        ),

        const SizedBox(height: 6),

        _primCard(
          monthTitle,
          primPuan,
        ),

        const SizedBox(height: 6),

        for (int i = 0;
            i < weeks.length;
            i++) ...[
          _buildWeekCard(
            week: weeks[i],
            initiallyExpanded: i == 0,
          ),

          if (i != weeks.length - 1)
            const SizedBox(height: 6),
        ],
      ],
    );
  }

  // ============================================================
  // ÜST BİLGİ
  // ============================================================

  Widget _ustBilgi(
    String monthTitle,
    int dayCount,
  ) {
    return Container(
      height: 48,
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

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bileklik',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: Colors.black38,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                Text(
                  widget.bileklikno_1,
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

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF7F7F9),
              borderRadius:
                  BorderRadius.circular(7),
            ),
            child: Text(
              '$monthTitle • $dayCount gün',
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8.5,
                color: Colors.black54,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRİM KARTI
  // ============================================================

  Widget _primCard(
    String monthTitle,
    double primPuan,
  ) {
    return Container(
      height: 68,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  accent.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: accent,
              size: 21,
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
                const Text(
                  'Prim Puan',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '$monthTitle • Ayın 1\'inden itibaren',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black45,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            constraints:
                const BoxConstraints(
              minWidth: 60,
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color:
                  accent.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(8),
              border: Border.all(
                color:
                    accent.withOpacity(.15),
              ),
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Text(
                  'PUAN',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.black38,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                Text(
                  primPuan
                      .toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 15,
                    color: accent,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HAFTA
  // ============================================================

  Widget _buildWeekCard({
    required _WeekGroup week,
    bool initiallyExpanded = false,
  }) {
    final totalPuan =
        _sumPuan(week.rows);

    final title =
        '${_fmtDate(week.start)} - ${_fmtDate(week.end)}';

    final sortedRows =
        [...week.rows]
          ..sort(
            (a, b) =>
                _parseDate(
                  a['tarih'],
                ).compareTo(
                  _parseDate(
                    b['tarih'],
                  ),
                ),
          );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color:
              Colors.black.withOpacity(.05),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor:
              Colors.transparent,
          visualDensity:
              VisualDensity.compact,
        ),
        child: ExpansionTile(
          initiallyExpanded:
              initiallyExpanded,
          dense: true,

          shape:
              const Border(),

          collapsedShape:
              const Border(),

          tilePadding:
              const EdgeInsets.fromLTRB(
            9,
            3,
            7,
            3,
          ),

          childrenPadding:
              const EdgeInsets.fromLTRB(
            7,
            0,
            7,
            7,
          ),

          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  accent.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_view_week_rounded,
              color: accent,
              size: 18,
            ),
          ),

          title: Text(
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

          subtitle: Text(
            '${week.rows.length} gün • '
            '${totalPuan.toStringAsFixed(0)} puan',
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.8,
              color: Colors.black45,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          children: [
            for (final row in sortedRows)
              _dayTile(row),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GÜN SATIRI
  // ============================================================

  Widget _dayTile(
    Map<String, dynamic> row,
  ) {
    final date =
        _parseDate(row['tarih']);

    final dayName =
        intl.DateFormat(
      'EEEE',
      'tr_TR',
    ).format(date);

    final sure =
        _safe(row['sure']);

    final puan =
        _safe(row['puan']);

    return Padding(
      padding:
          const EdgeInsets.only(
        top: 4,
      ),
      child: Material(
        color:
            const Color(0xFFF7F7F9),
        borderRadius:
            BorderRadius.circular(8),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(8),
          onTap: () {
            _showDayDetail(row);
          },
          child: Container(
            padding:
                const EdgeInsets.fromLTRB(
              7,
              5,
              6,
              5,
            ),
            child: Row(
              children: [
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color:
                        Colors.white,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: accent,
                    size: 17,
                  ),
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$dayName • ${_fmtDate(date)}',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          _miniDeger(
                            'Süre',
                            sure.isEmpty
                                ? '-'
                                : sure,
                          ),

                          const SizedBox(width: 5),

                          _miniDeger(
                            'Puan',
                            puan.isEmpty
                                ? '-'
                                : puan,
                            highlighted: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniDeger(
    String label,
    String value, {
    bool highlighted = false,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? accent.withOpacity(.08)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(6),
        border: Border.all(
          color: highlighted
              ? accent.withOpacity(.14)
              : Colors.black.withOpacity(.04),
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 8.5,
          color: highlighted
              ? accent
              : Colors.black54,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // GÜN DETAY
  // ============================================================

  void _showDayDetail(
    Map<String, dynamic> row,
  ) {
    final date =
        _parseDate(row['tarih']);

    final title =
        '${intl.DateFormat('dd.MM.yyyy').format(date)}'
        ' • '
        '${intl.DateFormat('EEEE', 'tr_TR').format(date)}';

    String v(String key) {
      final value =
          _safe(row[key]);

      return value.isEmpty
          ? '-'
          : value;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: bg,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          padding:
              const EdgeInsets.fromLTRB(
            10,
            8,
            10,
            10,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius:
                      BorderRadius.circular(99),
                ),
              ),

              const SizedBox(height: 8),

              Container(
                height: 45,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                            BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: accent,
                        size: 17,
                      ),
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              _detailRow(
                'Tesis Giriş',
                v('tesisgiriszamani'),
              ),

              _detailRow(
                'Tesis Çıkış',
                v('tesiscikiszamani'),
              ),

              _detailRow(
                'Süre',
                v('sure'),
              ),

              _detailRow(
                'Puan',
                v('puan'),
                highlighted: true,
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 42,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      sheetContext,
                    );
                  },
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        accent,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'KAPAT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool highlighted = false,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 4,
      ),
      padding:
          const EdgeInsets.symmetric(
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
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                color: Colors.black45,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10.5,
              color: highlighted
                  ? accent
                  : Colors.black87,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PUAN
  // ============================================================

  double _sumPuan(
    List<Map<String, dynamic>> rows,
  ) {
    double total = 0;

    for (final row in rows) {
      final value =
          row['puan'];

      if (value == null) {
        continue;
      }

      if (value is num) {
        total += value.toDouble();
        continue;
      }

      final text =
          value.toString().trim();

      if (text.isEmpty ||
          text == 'null' ||
          text == '-') {
        continue;
      }

      total += double.tryParse(
            text.replaceAll(',', '.'),
          ) ??
          0;
    }

    return total;
  }

  // ============================================================
  // HAFTA GRUPLAMA
  // ============================================================

  List<_WeekGroup> _groupByMonthWeek(
    List<Map<String, dynamic>> data,
  ) {
    final map =
        <String, List<Map<String, dynamic>>>{};

    for (final row in data) {
      final d =
          _parseDate(row['tarih']);

      final weekIndex =
          ((d.day - 1) ~/ 7);

      final key =
          '${d.year}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '$weekIndex';

      map.putIfAbsent(
        key,
        () => [],
      );

      map[key]!.add(row);
    }

    final keys =
        map.keys.toList()
          ..sort(
            (a, b) =>
                b.compareTo(a),
          );

    return keys.map(
      (key) {
        final parts =
            key.split('-');

        final year =
            int.parse(parts[0]);

        final month =
            int.parse(parts[1]);

        final weekIndex =
            int.parse(parts[2]);

        final startDay =
            1 + (weekIndex * 7);

        final start = DateTime(
          year,
          month,
          startDay,
        );

        final lastDay =
            DateTime(
          year,
          month + 1,
          0,
        ).day;

        final endDay =
            (startDay + 6) > lastDay
                ? lastDay
                : startDay + 6;

        final end = DateTime(
          year,
          month,
          endDay,
        );

        return _WeekGroup(
          start: start,
          end: end,
          rows: map[key]!,
        );
      },
    ).toList();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  DateTime _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return DateTime(
        1900,
        1,
        1,
      );
    }

    try {
      return DateTime.parse(
        value.toString(),
      );
    } catch (_) {
      return DateTime(
        1900,
        1,
        1,
      );
    }
  }

  String _fmtDate(
    DateTime date,
  ) {
    return intl.DateFormat(
      'dd.MM.yyyy',
    ).format(date);
  }

  String _safe(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    final text =
        value.toString();

    if (text == 'null') {
      return '';
    }

    return text;
  }
}

// ============================================================================
// WEEK MODEL
// ============================================================================

class _WeekGroup {
  final DateTime start;
  final DateTime end;
  final List<Map<String, dynamic>> rows;

  _WeekGroup({
    required this.start,
    required this.end,
    required this.rows,
  });
}

// ============================================================================
// LOADING
// ============================================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          9,
          7,
          9,
          14,
        ),
        children: const [
          _SkeletonInfo(),

          SizedBox(height: 6),

          _SkeletonPrim(),

          SizedBox(height: 6),

          _SkeletonWeek(),

          SizedBox(height: 6),

          _SkeletonWeek(),

          SizedBox(height: 6),

          _SkeletonWeek(),
        ],
      ),
    );
  }
}

class _SkeletonInfo extends StatelessWidget {
  const _SkeletonInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      decoration: _skeletonDecoration(),
      child: Row(
        children: [
          _block(
            31,
            31,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _block(
                  45,
                  7,
                ),
                const SizedBox(height: 5),
                _block(
                  110,
                  9,
                ),
              ],
            ),
          ),

          _block(
            90,
            24,
          ),
        ],
      ),
    );
  }
}

class _SkeletonPrim extends StatelessWidget {
  const _SkeletonPrim();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: _skeletonDecoration(),
      child: Row(
        children: [
          _block(
            38,
            38,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _block(
                  90,
                  11,
                ),

                const SizedBox(height: 7),

                _block(
                  150,
                  8,
                ),
              ],
            ),
          ),

          _block(
            62,
            40,
          ),
        ],
      ),
    );
  }
}

class _SkeletonWeek extends StatelessWidget {
  const _SkeletonWeek();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      decoration: _skeletonDecoration(),
      child: Row(
        children: [
          _block(
            32,
            32,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _block(
                  145,
                  10,
                ),

                const SizedBox(height: 7),

                _block(
                  100,
                  8,
                ),
              ],
            ),
          ),

          _block(
            18,
            18,
          ),
        ],
      ),
    );
  }
}

BoxDecoration _skeletonDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius:
        BorderRadius.circular(10),
    border: Border.all(
      color:
          Colors.black.withOpacity(.04),
    ),
  );
}

Widget _block(
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