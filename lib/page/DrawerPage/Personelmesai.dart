import 'package:agronet/api/personelmesai_api.dart';
import 'package:agronet/comp/appbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class PersonelMesai extends StatefulWidget {
  final String bileklikno_1;
  const PersonelMesai({Key? key, required this.bileklikno_1}) : super(key: key);

  @override
  State<PersonelMesai> createState() => _PersonelMesaiState();
}

class _PersonelMesaiState extends State<PersonelMesai> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Personel Mesai Raporu"),
  centerTitle: true,
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
                          child: Center(child: Text("Hata: $_error")),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ElevatedButton.icon(
                            onPressed: _getir,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Tekrar dene"),
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
    final monthEnd = DateTime(latest.year, latest.month + 1, 0); // ayın son günü

    // ✅ Sadece bu ayın 1’inden itibaren (o ayın kayıtları)
    final monthRows = data.where((r) {
      final d = _parseDate(r["tarih"]);
      return !d.isBefore(monthStart) && !d.isAfter(monthEnd);
    }).toList();

    // ✅ Prim Puan = ayın 1’inden itibaren toplam puan
    final primPuan = _sumPuan(monthRows);

    // ✅ Haftaları ayın 1’ine göre grupla (1-7, 8-14, ...)
    final weeks = _groupByMonthWeek(monthRows);

    return ListView.builder(
      key: const ValueKey("content"),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: weeks.length + 1, // +1: üstte Prim kartı
      itemBuilder: (context, i) {
        // 0. item: Prim Puan kartı
        if (i == 0) {
          final monthTitle = intl.DateFormat("MMMM yyyy", "tr_TR").format(monthStart);

          return Card(
            margin: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Prim Puan ($monthTitle)",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text("Ayın 1’inden itibaren"),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(40), // elips
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
            ),
          );
        }

        final week = weeks[i - 1];

        final totalPuan = _sumPuan(week.rows);
        final headerTitle = "${_fmtDate(week.start)} - ${_fmtDate(week.end)}";
        final headerSub = "Toplam puan: ${totalPuan.toStringAsFixed(0)}  •  ${week.rows.length} gün";

        // Haftanın içi eski->yeni
        final sortedRows = [...week.rows]
          ..sort((a, b) => _parseDate(a["tarih"]).compareTo(_parseDate(b["tarih"])));

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ExpansionTile(
            initiallyExpanded: i == 1,
            title: Text(headerTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(headerSub),
            children: [
              const Divider(height: 1),
              ...sortedRows.map((row) => _dayTile(row)).toList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ------------------ Gün Satırı (ListTile) ------------------

  Widget _dayTile(Map<String, dynamic> row) {
    final date = _parseDate(row["tarih"]);
    final dayName = intl.DateFormat("EEEE", "tr_TR").format(date);
    final dateText = _fmtDate(date);

    final sureText = _safe(row["sure"]);
    final puanText = _safe(row["puan"]);

    final subtitle = "Süre: ${sureText.isEmpty ? '-' : sureText}   •   Puan: ${puanText.isEmpty ? '-' : puanText}";

    return ListTile(
      dense: true,
      title: Text("$dayName • $dateText"),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showDayDetail(row),
    );
  }

  // ------------------ Detay Popup ------------------

  void _showDayDetail(Map<String, dynamic> row) {
    final date = _parseDate(row["tarih"]);
    final title =
        "${intl.DateFormat("dd.MM.yyyy").format(date)} • ${intl.DateFormat("EEEE", "tr_TR").format(date)}";

    String v(String key) => _safe(row[key]).isEmpty ? "-" : _safe(row[key]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              _detailRow("Tesis Giriş", v("tesisgiriszamani")),
              _detailRow("Tesis Çıkış", v("tesiscikiszamani")),
              const Divider(height: 18),
              _detailRow("Süre", v("sure")),
              _detailRow("Puan", v("puan")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Kapat"),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 5,
            child: Text(value, textAlign: TextAlign.right),
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
      final weekIndex = ((d.day - 1) ~/ 7); // 0:1-7, 1:8-14 ...

      final startDay = 1 + (weekIndex * 7);
      final start = DateTime(d.year, d.month, startDay);

      final lastDayOfMonth = DateTime(d.year, d.month + 1, 0).day;
      final endDay = (startDay + 6) > lastDayOfMonth ? lastDayOfMonth : (startDay + 6);
      final end = DateTime(d.year, d.month, endDay);

      final key = "${d.year}-${d.month.toString().padLeft(2, '0')}-$weekIndex";
      map.putIfAbsent(key, () => []);
      map[key]!.add(row);
    }

    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a)); // en yeni blok üstte

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

  // ------------------ Yardımcılar ------------------

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

    return Card(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
            const Divider(height: 1),
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
      ),
    );
  }
}