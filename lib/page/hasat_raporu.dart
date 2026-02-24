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
  State<HasatRaporuDetayliPage> createState() => _HasatRaporuDetayliPageState();
}

class _HasatRaporuDetayliPageState extends State<HasatRaporuDetayliPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF6F7F9);

  final _api = HasatApi();

  DateTime _ilk = DateTime.now();
  DateTime _son = DateTime.now();
  final NumberFormat _nf = NumberFormat.decimalPattern('tr_TR');

String _fmtInt(num? v) => _nf.format((v ?? 0).round());


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

  void _setTodayLocal() {
    final n = DateTime.now();
    _ilk = DateTime(n.year, n.month, n.day);
    _son = DateTime(n.year, n.month, n.day);
  }

  Future<void> _setTodayAndFetch() async {
    setState(_setTodayLocal);
    await _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      final data = await _api.getHasatRaporuDetayli(_ilk, _son);
      if (!mounted) return;
      setState(() => _rows = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  double get _sumBrut => _rows.fold(0.0, (p, e) => p + (e.brutKg ?? 0));
  double get _sumNet => _rows.fold(0.0, (p, e) => p + (e.netKg ?? 0));
  double get _sumDara => _rows.fold(0.0, (p, e) => p + (e.dara ?? 0));

  String _groupTitle(HasatGroupBy g) {
    switch (g) {
      case HasatGroupBy.tunel:
        return "Tünel";
      case HasatGroupBy.bolum:
        return "Bölüm";
      case HasatGroupBy.isitma:
        return "Isıtma Sektörü";
      case HasatGroupBy.sulama:
        return "Sulama Sektörü";
      case HasatGroupBy.yon:
        return "Tünel Yönü";
      case HasatGroupBy.kutuTipi:
        return "Kutu Tipi";
      case HasatGroupBy.urunTipi:
        return "Ürün Tipi";
      case HasatGroupBy.toplayan:
        return "Toplayan Personel";
      case HasatGroupBy.okutan:
        return "Okutan Personel";
      case HasatGroupBy.paketleyen:
        return "Paketleyen Personel";
    }
  }

  String _groupKey(HasatRaporuDetayModel r) {
    switch (_groupBy) {
      case HasatGroupBy.tunel:
        return r.tunel ?? "-";
      case HasatGroupBy.bolum:
        return r.bolum ?? "-";
      case HasatGroupBy.isitma:
        return r.isitmaSektoru ?? "-";
      case HasatGroupBy.sulama:
        return r.sulamaSektoru ?? "-";
      case HasatGroupBy.yon:
        return r.tunelYonu ?? "-";
      case HasatGroupBy.kutuTipi:
        return r.kutuTipi ?? "-";
      case HasatGroupBy.urunTipi:
        return r.urunTipi ?? "-";
      case HasatGroupBy.toplayan:
        return r.toplayanPersonel ?? "-";
      case HasatGroupBy.okutan:
        return r.okutanPersonel ?? "-";
      case HasatGroupBy.paketleyen:
        return r.paketleyenPersonel ?? "-";
    }
  }

  Map<String, List<HasatRaporuDetayModel>> get _grouped {
    final m = <String, List<HasatRaporuDetayModel>>{};
    for (final r in _rows) {
      final k = _groupKey(r);
      (m[k] ??= []).add(r);
    }
    return m;
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _ilk, end: _son),
      helpText: "Tarih Aralığı Seç",
    );
    if (picked == null) return;

    setState(() {
      _ilk = DateTime(picked.start.year, picked.start.month, picked.start.day);
      _son = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });

    await _fetch();
  }

  // ----------------------------
  // BottomSheet: GroupBy seçimi
  // ----------------------------
  void _openGroupBySheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.pivot_table_chart_outlined, color: accent),
                    SizedBox(width: 8),
                    Text(
                      "Filtre Seç",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: HasatGroupBy.values.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (_, i) {
                      final g = HasatGroupBy.values[i];
                      final selected = g == _groupBy;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                        title: Text(
                          _groupTitle(g),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        trailing: selected ? const Icon(Icons.check_circle, color: accent) : null,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _groupBy = g);
                          Navigator.pop(context);
                        },
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

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Hasat Raporu"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: _loading ? null : _fetch,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _topBar(),
            const SizedBox(height: 10),
           _loading ? const _KpiSkeletonRow() : _kpiRow(),
            const SizedBox(height: 10),
            _groupByPickerTile(),
            const SizedBox(height: 8),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _pickRange,
              child: _card(
                child: Row(
                  children: [
                    _iconBadge(Icons.date_range),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${_fmtDate(_ilk)}  →  ${_fmtDate(_son)}",
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(child: _KpiCard(title: "Brüt KG", value: _sumBrut)),
          const SizedBox(width: 8),
          Expanded(child: _KpiCard(title: "Net KG", value: _sumNet)),
          const SizedBox(width: 8),
          Expanded(child: _KpiCard(title: "Dara", value: _sumDara)),
        ],
      ),
    );
  }

  Widget _groupByPickerTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _openGroupBySheet,
        child: _card(
          child: Row(
            children: [
              _iconBadge(Icons.pivot_table_chart_outlined),
              const SizedBox(width: 10),
              const Text("Filtre", style: TextStyle(color: Colors.black54)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _groupTitle(_groupBy),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
         
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const _HasatSkeleton();

    if (_err != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_err!, textAlign: TextAlign.center),
        ),
      );
    }

    if (_rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.inventory_2_outlined, size: 44, color: Colors.grey),
            SizedBox(height: 10),
            Text("Kayıt yok"),
          ],
        ),
      );
    }

    final groups = _grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final key = groups[i].key;
        final items = groups[i].value;

        final brut = items.fold(0.0, (p, e) => p + (e.brutKg ?? 0));
        final net = items.fold(0.0, (p, e) => p + (e.netKg ?? 0));
        final dara = items.fold(0.0, (p, e) => p + (e.dara ?? 0));

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openGroup(key, items),
          child: _card(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.folder_open, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(key,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(
                        "Net ${_fmtInt(net)} • Brüt ${_fmtInt(brut)} • Dara ${_fmtInt(dara)}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------
  // BottomSheet: Grup detay listesi
  // ----------------------------
  void _openGroup(String key, List<HasatRaporuDetayModel> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          builder: (context, controller) {
            final brut = items.fold(0.0, (p, e) => p + (e.brutKg ?? 0));
            final net = items.fold(0.0, (p, e) => p + (e.netKg ?? 0));

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          key,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                       "Net ${_fmtInt(net)}",
                          style: const TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                         "Brüt ${_fmtInt(brut)}",
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = items[i];
                      final title = r.kutuTipi ?? "-";
                      final dateStr = r.toplamaTarihi != null ? _fmtDate(r.toplamaTarihi!) : "-";
                      final sub = "${r.toplayanPersonel ?? "-"} • ${r.tunel ?? "-"} • $dateStr";

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _openRow(r),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(.10),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.qr_code_2, color: accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text(sub, style: const TextStyle(color: Colors.black54)),
                                  ],
                                ),
                              ),
                              Text(
                                (r.netKg ?? 0).toStringAsFixed(2),
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ----------------------------
  // BottomSheet: Satır detay
  // ----------------------------
  void _openRow(HasatRaporuDetayModel r) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailHeader("Detay"),
                  const SizedBox(height: 8),

                  _InfoRow("Toplayan", r.toplayanPersonel),
                  _InfoRow("Toplanma Tarihi", r.toplamaTarihi != null ? _fmtDate(r.toplamaTarihi!) : null),
                  _InfoRow("Bölüm", r.bolum),
                  _InfoRow("Tünel", r.tunel),
                  _InfoRow("Isıtma", r.isitmaSektoru),
                  _InfoRow("Sulama", r.sulamaSektoru),
                  _InfoRow("Yön", r.tunelYonu),
                  _InfoRow("Kutu Tipi", r.kutuTipi),
                  _InfoRow("Ürün Tipi", r.urunTipi),
                  _InfoRow("Okutan", r.okutanPersonel),
                  _InfoRow("Paketleyen", r.paketleyenPersonel),
                  _InfoRow("Paketleme Tarihi", r.paketlemeTarihi != null ? _fmtDate(r.paketlemeTarihi!) : null),

                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _miniKpi("Brüt", r.brutKg ?? 0)),
                      const SizedBox(width: 8),
                      Expanded(child: _miniKpi("Net", r.netKg ?? 0)),
                      const SizedBox(width: 8),
                      Expanded(child: _miniKpi("Dara", r.dara ?? 0)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InfoRow("Personel Tipi", r.personelTipi),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _miniKpi(String t, num v) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        color: const Color(0xFFF6F7F9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(NumberFormat.decimalPattern('tr_TR').format(v.round()), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _detailHeader(String title) {
    return Row(
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
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
      ),
      child: child,
    );
  }

  Widget _iconBadge(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withOpacity(.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: accent, size: 18),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final double value;
  const _KpiCard({required this.title, required this.value});

  static const Color accent = Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            NumberFormat.decimalPattern('tr_TR').format(value.round()),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String k;
  final String? v;
  const _InfoRow(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(k, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              v ?? "-",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _HasatSkeleton extends StatelessWidget {
  const _HasatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        children: const [
          _SkeletonGroupCard(),
          SizedBox(height: 10),
          _SkeletonGroupCard(),
          SizedBox(height: 10),
          _SkeletonGroupCard(),
          SizedBox(height: 10),
          _SkeletonGroupCard(),
          SizedBox(height: 10),
          _SkeletonGroupCard(),
        ],
      ),
    );
  }
}

class _SkeletonGroupCard extends StatelessWidget {
  const _SkeletonGroupCard();

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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // sol ikon kutusu
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withOpacity(0.06),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(w: 180, h: 14),
                const SizedBox(height: 10),
                bar(w: 260, h: 12),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.black.withOpacity(0.06),
            ),
          ),
        ],
      ),
    );
  }
}
class _KpiSkeletonRow extends StatelessWidget {
  const _KpiSkeletonRow();

  @override
  Widget build(BuildContext context) {
    Widget kpi() => Expanded(
          child: Container(
            height: 76,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black12),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sk(70, 12),
                const SizedBox(height: 10),
                _sk(90, 18),
              ],
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          kpi(),
          const SizedBox(width: 8),
          kpi(),
          const SizedBox(width: 8),
          kpi(),
        ],
      ),
    );
  }

  static Widget _sk(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black.withOpacity(0.06),
        ),
      );
}