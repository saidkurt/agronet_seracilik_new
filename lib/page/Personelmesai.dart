import 'package:agronet/api/personelmesai_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class PersonelMesai extends StatefulWidget {
  final String bileklikno_1;
  const PersonelMesai({Key? key, required this.bileklikno_1}) : super(key: key);

  @override
  State<PersonelMesai> createState() => _PersonelMesaiState();
}

class _PersonelMesaiState extends State<PersonelMesai> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF6F7F9);

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    _getir();
  }

  Future<void> _getir() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await PersonelMesaiApi().mesaiDurumu(bileklikid: widget.bileklikno_1);
      if (!mounted) return;
      setState(() => _data = res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Personel Mesai Raporu"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: _loading ? null : _getir,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _getir,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _loading
              ? ListView.builder(
                  key: const ValueKey("skeleton"),
                  padding: const EdgeInsets.only(bottom: 16, top: 10),
                  itemCount: 6,
                  itemBuilder: (_, i) {
                    if (i == 0) return const _SkeletonPrimCard();
                    return const _SkeletonWeekCard();
                  },
                )
              : _error != null
                  ? ListView(
                      key: const ValueKey("error"),
                      children: [
                        const SizedBox(height: 120),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(child: Text("Hata: $_error", textAlign: TextAlign.center)),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ElevatedButton.icon(
                            onPressed: _getir,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Tekrar dene"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final data = List<Map<String, dynamic>>.from(_data);
    if (data.isEmpty) {
      return ListView(
        key: const ValueKey("empty"),
        children: const [
          SizedBox(height: 140),
          Center(child: Text("Kayıt yok")),
        ],
      );
    }

    // en yeni gün en üstte
    data.sort((a, b) => _parseDate(b["tarih"]).compareTo(_parseDate(a["tarih"])));

    // ✅ Ay seçimi: en yeni kaydın ayı
    final latest = _parseDate(data.first["tarih"]);
    final monthStart = DateTime(latest.year, latest.month, 1);
    final monthEnd = DateTime(latest.year, latest.month + 1, 0);

    final monthRows = data.where((r) {
      final d = _parseDate(r["tarih"]);
      return !d.isBefore(monthStart) && !d.isAfter(monthEnd);
    }).toList();

    final primPuan = _sumPuan(monthRows);
    final weeks = _groupByMonthWeek(monthRows);

    final monthTitle = intl.DateFormat("MMMM yyyy", "tr_TR").format(monthStart);

    return ListView.builder(
      key: const ValueKey("content"),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: weeks.length + 2, // +1 prim +1 header chip
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: _topInfoChip(monthTitle, monthRows.length),
          );
        }

        if (i == 1) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: _primCard(monthTitle, primPuan),
          );
        }

        final week = weeks[i - 2];

        final totalPuan = _sumPuan(week.rows);
        final headerTitle = "${_fmtDate(week.start)} - ${_fmtDate(week.end)}";
        final headerSub = "Toplam puan: ${totalPuan.toStringAsFixed(0)}  •  ${week.rows.length} gün";

        final sortedRows = [...week.rows]
          ..sort((a, b) => _parseDate(a["tarih"]).compareTo(_parseDate(b["tarih"])));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: _weekCard(
            initiallyExpanded: i == 2,
            title: headerTitle,
            subtitle: headerSub,
            child: Column(
              children: [
                const SizedBox(height: 6),
                ...sortedRows.map((row) => _dayTile(row)).toList(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------ Üst mini chip ------------------

  Widget _topInfoChip(String monthTitle, int dayCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
   
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.badge, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Bileklik: ${widget.bileklikno_1}",
              style: const TextStyle(fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.05),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              "$monthTitle • $dayCount gün",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ Prim Kartı ------------------

  Widget _primCard(String monthTitle, double primPuan) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
  
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.stars_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Prim Puan",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  "$monthTitle • Ayın 1’inden itibaren",
                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              primPuan.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ Hafta Kartı ------------------

  Widget _weekCard({
    required String title,
    required String subtitle,
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
   
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_view_week, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
          children: [
            Divider(height: 1, color: Colors.grey.shade200),
            child,
          ],
        ),
      ),
    );
  }

  // ------------------ Gün Satırı ------------------

  Widget _dayTile(Map<String, dynamic> row) {
    final date = _parseDate(row["tarih"]);
    final dayName = intl.DateFormat("EEEE", "tr_TR").format(date);
    final dateText = _fmtDate(date);

    final sureText = _safe(row["sure"]);
    final puanText = _safe(row["puan"]);

    final sureVal = sureText.isEmpty ? "-" : sureText;
    final puanVal = puanText.isEmpty ? "-" : puanText;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showDayDetail(row),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(16),
     
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
  
              ),
              child: const Icon(Icons.access_time, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$dayName • $dateText",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill("Süre", sureVal),
                      _pill("Puan", puanVal),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withOpacity(0.10),
        border: Border.all(color: accent.withOpacity(0.20)),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }

  // ------------------ Detay: Modern BottomSheet ------------------

  void _showDayDetail(Map<String, dynamic> row) {
    final date = _parseDate(row["tarih"]);
    final title =
        "${intl.DateFormat("dd.MM.yyyy").format(date)} • ${intl.DateFormat("EEEE", "tr_TR").format(date)}";

    String v(String key) => _safe(row[key]).isEmpty ? "-" : _safe(row[key]);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.info_outline, color: accent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _detailRow("Tesis Giriş", v("tesisgiriszamani")),
                _detailRow("Tesis Çıkış", v("tesiscikiszamani")),
                Divider(height: 18, color: Colors.grey.shade200),
                _detailRow("Süre", v("sure")),
                _detailRow("Puan", v("puan")),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Kapat", style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 5,
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // ------------------ Puan Toplamı ------------------

  double _sumPuan(List<Map<String, dynamic>> rows) {
    double total = 0;
    for (final r in rows) {
      final v = r["puan"];
      if (v == null) continue;

      if (v is num) {
        total += v.toDouble();
        continue;
      }

      final s = v.toString().trim();
      if (s.isEmpty || s == "null" || s == "-") continue;

      final normalized = s.replaceAll(",", ".");
      total += double.tryParse(normalized) ?? 0;
    }
    return total;
  }

  // ✅ Ayın 1’ine göre “hafta” gruplama: 1-7, 8-14, 15-21, 22-28, 29-...
  List<_WeekGroup> _groupByMonthWeek(List<Map<String, dynamic>> data) {
    final Map<String, List<Map<String, dynamic>>> map = {};

    for (final row in data) {
      final d = _parseDate(row["tarih"]);
      final weekIndex = ((d.day - 1) ~/ 7);
      final key = "${d.year}-${d.month.toString().padLeft(2, '0')}-$weekIndex";
      map.putIfAbsent(key, () => []);
      map[key]!.add(row);
    }

    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    return keys.map((k) {
      final parts = k.split("-");
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final weekIndex = int.parse(parts[2]);

      final startDay = 1 + (weekIndex * 7);
      final start = DateTime(y, m, startDay);

      final lastDayOfMonth = DateTime(y, m + 1, 0).day;
      final endDay = (startDay + 6) > lastDayOfMonth ? lastDayOfMonth : (startDay + 6);
      final end = DateTime(y, m, endDay);

      return _WeekGroup(start: start, end: end, rows: map[k]!);
    }).toList();
  }

  // ------------------ Helpers ------------------

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime(1900, 1, 1);
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime(1900, 1, 1);
    }
  }

  String _fmtDate(DateTime d) => intl.DateFormat("dd.MM.yyyy").format(d);

  String _safe(dynamic v) {
    if (v == null) return "";
    final s = v.toString();
    if (s == "null") return "";
    return s;
  }
}

class _WeekGroup {
  final DateTime start;
  final DateTime end;
  final List<Map<String, dynamic>> rows;

  _WeekGroup({required this.start, required this.end, required this.rows});
}

// ------------------ Skeleton Widgets ------------------

class _SkeletonPrimCard extends StatelessWidget {
  const _SkeletonPrimCard();

  @override
  Widget build(BuildContext context) {
    Widget bar({double w = 160, double h = 12}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withOpacity(0.06),
          ),
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(w: 220, h: 16),
                const SizedBox(height: 8),
                bar(w: 140, h: 12),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonWeekCard extends StatelessWidget {
  const _SkeletonWeekCard();

  @override
  Widget build(BuildContext context) {
    Widget bar({double w = 160, double h = 12}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withOpacity(0.06),
          ),
        );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              bar(w: 190, h: 14),
              const Spacer(),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          bar(w: 240, h: 12),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          ...List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(w: 220, h: 12),
                        const SizedBox(height: 6),
                        bar(w: 160, h: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}