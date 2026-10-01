import 'package:flutter/material.dart';
import 'package:agronet/api/personelmesai_api.dart';
import 'package:agronet/page/Personelmesai.dart';

class MesaiPrimPuanWidget extends StatefulWidget {
  final String bileklikId;

  /// true ise AppBar için sadece "87 PUAN" gibi kompakt görünür.
  final bool compact;

  const MesaiPrimPuanWidget({
    super.key,
    required this.bileklikId,
    this.compact = false,
  });

  @override
  State<MesaiPrimPuanWidget> createState() => _MesaiPrimPuanWidgetState();
}

class _MesaiPrimPuanWidgetState extends State<MesaiPrimPuanWidget> {
  bool _loading = false;
  String? _error;
  double? _primPuan;

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
      final res = await PersonelMesaiApi().mesaiDurumu(
        bileklikid: widget.bileklikId,
      );

      if (!mounted) return;

      final data = List<Map<String, dynamic>>.from(res);

      if (data.isEmpty) {
        setState(() {
          _primPuan = 0;
        });
        return;
      }

      data.sort(
        (a, b) =>
            _parseDate(b["tarih"]).compareTo(_parseDate(a["tarih"])),
      );

      final latest = _parseDate(data.first["tarih"]);

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

      final monthRows = data.where((r) {
        final d = _parseDate(r["tarih"]);

        return !d.isBefore(monthStart) &&
            !d.isAfter(monthEnd);
      }).toList();

      final prim = _sumPuan(monthRows);

      setState(() {
        _primPuan = prim;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  DateTime _parseDate(dynamic v) {
    if (v == null) {
      return DateTime(1900, 1, 1);
    }

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

      if (s.isEmpty || s == "null" || s == "-") {
        continue;
      }

      final normalized = s.replaceAll(",", ".");

      total += double.tryParse(normalized) ?? 0;
    }

    return total;
  }

  void _goDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonelMesai(
          bileklikno_1: widget.bileklikId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompact();
    }

    return _buildNormal();
  }

  Widget _buildCompact() {
    if (_loading) {
      return const SizedBox(
        width: 64,
        height: 28,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF1E6F5C),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return InkWell(
        onTap: _fetch,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.refresh_rounded,
            size: 17,
            color: Colors.redAccent,
          ),
        ),
      );
    }

    final val = (_primPuan ?? 0).toStringAsFixed(0);

    return InkWell(
      onTap: _goDetail,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1E6F5C).withOpacity(.10),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: const Color(0xFF1E6F5C).withOpacity(.12),
          ),
        ),
        child: Text(
          '$val PUAN',
          maxLines: 1,
          style: const TextStyle(
            color: Color(0xFF1E6F5C),
            fontSize: 10.5,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildNormal() {
    if (_loading) {
      return _PrimChipSkeleton(
        onTap: _goDetail,
      );
    }

    if (_error != null) {
      return _PrimChip(
        title: "Prim Puan",
        valueText: "!",
        valueBg: Colors.black.withOpacity(.12),
        valueFg: Colors.black.withOpacity(.55),
        onTap: _fetch,
      );
    }

    final val = (_primPuan ?? 0).toStringAsFixed(0);

    return _PrimChip(
      title: "Prim Puan",
      valueText: val,
      valueBg: const Color(0xFF1E6F5C).withOpacity(.14),
      valueFg: const Color(0xFF1E6F5C),
      onTap: _goDetail,
    );
  }
}

class _PrimChip extends StatelessWidget {
  final String title;
  final String valueText;
  final Color valueBg;
  final Color valueFg;
  final VoidCallback onTap;

  const _PrimChip({
    required this.title,
    required this.valueText,
    required this.valueBg,
    required this.valueFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black.withOpacity(.06),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(.72),
                ),
              ),
            ),

            const SizedBox(width: 8),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: valueBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                valueText,
                style: TextStyle(
                  color: valueFg,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimChipSkeleton extends StatelessWidget {
  final VoidCallback onTap;

  const _PrimChipSkeleton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black.withOpacity(.06),
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.black.withOpacity(.20),
            ),
          ),
        ),
      ),
    );
  }
}