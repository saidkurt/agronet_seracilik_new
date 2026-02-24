import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:agronet/api/personelmesai_api.dart';
import 'package:agronet/page/Personelmesai.dart'; // sende yol farklıysa düzelt

class MesaiPrimPuanWidget extends StatefulWidget {
  final String bileklikId;

  /// Profil kartına gömmek için: küçük, tek satır + chip gibi.
  const MesaiPrimPuanWidget({super.key, required this.bileklikId});

  @override
  State<MesaiPrimPuanWidget> createState() => _MesaiPrimPuanWidgetState();
}

class _MesaiPrimPuanWidgetState extends State<MesaiPrimPuanWidget> {
  bool _loading = false;
  String? _error;
  double? _primPuan; // ayın 1’inden itibaren toplam
  DateTime? _monthStart; // hangi ayı baz aldık (en yeni kaydın ayı)

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await PersonelMesaiApi().mesaiDurumu(bileklikid: widget.bileklikId);
      if (!mounted) return;

      final data = List<Map<String, dynamic>>.from(res);

      if (data.isEmpty) {
        setState(() {
          _primPuan = 0;
          _monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
        });
        return;
      }

      // en yeni gün en üstte
      data.sort((a, b) => _parseDate(b["tarih"]).compareTo(_parseDate(a["tarih"])));

      final latest = _parseDate(data.first["tarih"]);
      final monthStart = DateTime(latest.year, latest.month, 1);
      final monthEnd = DateTime(latest.year, latest.month + 1, 0);

      final monthRows = data.where((r) {
        final d = _parseDate(r["tarih"]);
        return !d.isBefore(monthStart) && !d.isAfter(monthEnd);
      }).toList();

      final prim = _sumPuan(monthRows);

      setState(() {
        _primPuan = prim;
        _monthStart = monthStart;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime(1900, 1, 1);
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime(1900, 1, 1);
    }
  }

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

  void _goDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonelMesai(bileklikno_1: widget.bileklikId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthTitle = (_monthStart == null)
        ? ""
        : intl.DateFormat("MMMM yyyy", "tr_TR").format(_monthStart!);

    // Skeleton
    if (_loading) {
      return _PrimChipSkeleton(onTap: _goDetail);
    }

    // Error (tıklanınca retry)
    if (_error != null) {
      return _PrimChip(
        title: "Mesai / Prim",
        subtitle: "Yüklenemedi • dokun yenile",
        valueText: "!",
        valueBg: Colors.black.withOpacity(.12),
        valueFg: Colors.black.withOpacity(.55),
        onTap: _fetch,
      );
    }

    final val = (_primPuan ?? 0).toStringAsFixed(0);

    return _PrimChip(
      title: "Prim Puan",
      subtitle: monthTitle.isEmpty ? "Ayın 1’inden itibaren" : "$monthTitle • Ayın 1’inden",
      valueText: val,
      valueBg: const Color(0xFF1E6F5C).withOpacity(.14),
      valueFg: const Color(0xFF1E6F5C),
      onTap: _goDetail,
    );
  }
}

class _PrimChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final String valueText;
  final Color valueBg;
  final Color valueFg;
  final VoidCallback onTap;

  const _PrimChip({
    required this.title,
    required this.subtitle,
    required this.valueText,
    required this.valueBg,
    required this.valueFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black.withOpacity(.80),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(.50),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: valueBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                valueText,
                style: TextStyle(
                  color: valueFg,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: Colors.black.withOpacity(.35)),
          ],
        ),
      ),
    );
  }
}

class _PrimChipSkeleton extends StatelessWidget {
  final VoidCallback onTap;
  const _PrimChipSkeleton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget bar({double w = 140, double h = 12}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withOpacity(0.06),
          ),
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(w: 120, h: 12),
                  const SizedBox(height: 8),
                  bar(w: 190, h: 12),
                ],
              ),
            ),
            Container(
              width: 54,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}