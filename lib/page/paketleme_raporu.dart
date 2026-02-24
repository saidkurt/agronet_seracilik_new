import 'package:agronet/api/paketleme_rapor_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:agronet/models/paketleme_rapor_model.dart';

class PaketlemeRaporPage extends StatefulWidget {
  const PaketlemeRaporPage({super.key});

  @override
  State<PaketlemeRaporPage> createState() => _PaketlemeRaporPageState();
}

class _PaketlemeRaporPageState extends State<PaketlemeRaporPage> {
  final _api = const PaketlemeApi();

  DateTime _ilkTarih = DateTime.now();
  DateTime _sonTarih = DateTime.now();

  bool _loading = false;
  String? _error;
  List<PaketlemeRaporModel> _items = [];

  final _fmt = DateFormat('dd.MM.yyyy');

  Future<void> _pickDate({required bool isIlk}) async {
    final initial = isIlk ? _ilkTarih : _sonTarih;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked == null) return;

    setState(() {
      if (isIlk) {
        _ilkTarih = picked;
        if (_sonTarih.isBefore(_ilkTarih)) _sonTarih = _ilkTarih;
      } else {
        _sonTarih = picked;
        if (_sonTarih.isBefore(_ilkTarih)) _ilkTarih = _sonTarih;
      }
    });
  }

  Future<void> _getir() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.paketlemeGetir(_ilkTarih, _sonTarih);
      setState(() => _items = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  PaketlemeRaporModel? get _hataliRow {
    try {
      return _items.firstWhere((x) => (x.personelKod == null));
    } catch (_) {
      return null;
    }
  }

  List<PaketlemeRaporModel> get _personelRows =>
      _items.where((x) => x.personelKod != null).toList();

  int _sumInt(int? Function(PaketlemeRaporModel x) pick) {
    int s = 0;
    for (final x in _personelRows) {
      s += (pick(x) ?? 0);
    }
    return s;
  }

  @override
  void initState() {
    super.initState();
    _getir(); // sayfa açılınca otomatik bugünü getir
  }

  @override
  Widget build(BuildContext context) {
    final toplam = _sumInt((x) => x.toplam);
    final salkim = _sumInt((x) => x.salkimDomates);
    final ikinci = _sumInt((x) => x.ikinciKalite);

   return Scaffold(
  backgroundColor: const Color(0xFFF6F7F9),
  appBar: AppBar(
    title: const Text('Paketleme Raporu'),
    centerTitle: true,
  ),
  body: Column(
    children: [
      _TopPanel(
        loading: _loading,
        ilk: _ilkTarih,
        son: _sonTarih,
        fmt: _fmt,
        onPickIlk: () => _pickDate(isIlk: true),
        onPickSon: () => _pickDate(isIlk: false),
        onGetir: _getir,
      ),
      const SizedBox(height: 10),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(child: _SummaryCard(title: 'Toplam', value: toplam.toString(), icon: Icons.summarize)),
            const SizedBox(width: 8),
            Expanded(child: _SummaryCard(title: 'Salkım', value: salkim.toString(), icon: Icons.local_florist)),
            const SizedBox(width: 8),
            Expanded(child: _SummaryCard(title: '2.Kalite', value: ikinci.toString(), icon: Icons.verified)),
          ],
        ),
      ),

      const SizedBox(height: 8),

      if (_error != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _ErrorBox(text: _error!),
        ),

      Expanded(
        child: _loading
            ? const _SkeletonList()
            : _personelRows.isEmpty
                ? const Center(child: Text('Kayıt yok'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: _personelRows.length + (_hataliRow != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      final int hataliIndex = _personelRows.length;
                      if (_hataliRow != null && index == hataliIndex) {
                        final h = _hataliRow!;
                        final hataliToplam = h.salkimDomates ?? 0;
                        return _HataliCard(count: hataliToplam);
                      }
                      return _PersonelCard(item: _personelRows[index]);
                    },
                  ),
      ),
    ],
  ),
);
  }
}

// ----------------- UI WIDGETS -----------------

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label: $value',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 6),
            color: Color(0x11000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E6F5C)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),

                // ✅ tek satır + sığmazsa küçül
                SizedBox(
                  height: 22,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
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

class _PersonelCard extends StatelessWidget {
  const _PersonelCard({required this.item});

  final PaketlemeRaporModel item;

  @override
  Widget build(BuildContext context) {
    final kod = item.personelKod?.toString() ?? '-';
    final salkim = item.salkimDomates ?? 0;
    final ikinci = item.ikinciKalite ?? 0;
    final toplam = item.toplam ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 6),
            color: Color(0x0E000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item.personel).trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text('Kod: $kod', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _miniPill('Salkım', salkim.toString()),
                    _miniPill('2.Kalite', ikinci.toString()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // sağ: toplam büyük + tek satır garantili
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Toplam', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              SizedBox(
                width: 70,
                height: 28,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    toplam.toString(),
                    maxLines: 1,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF6F7F9),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _HataliCard extends StatelessWidget {
  const _HataliCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.red.withOpacity(0.06),
        border: Border.all(color: Colors.red.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Hatalı Barkod',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.red.withOpacity(0.06),
        border: Border.all(color: Colors.red.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}


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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 6),
              color: Color(0x11000000),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _DateChip(
                label: 'İlk',
                value: fmt.format(ilk),
                onTap: loading ? () {} : onPickIlk,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DateChip(
                label: 'Son',
                value: fmt.format(son),
                onTap: loading ? () {} : onPickSon,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: loading ? null : onGetir,
                icon: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label: const Text('Getir'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(w: 180, h: 14),
                  const SizedBox(height: 8),
                  bar(w: 120, h: 12),
                  const SizedBox(height: 10),
                  Row(
                    children: [bar(w: 90, h: 22), const SizedBox(width: 8), bar(w: 90, h: 22)],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [bar(w: 40, h: 10), const SizedBox(height: 6), bar(w: 60, h: 24)],
            ),
          ],
        ),
      ),
    );
  }
}