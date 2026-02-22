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
      appBar: AppBar(
        title: const Text('Paketleme Raporu'),
      ),
      body: Column(
        children: [
          // ÜST BAR: Tarihler + Getir
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: _DateChip(
                    label: 'İlk Tarih',
                    value: _fmt.format(_ilkTarih),
                    onTap: () => _pickDate(isIlk: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateChip(
                    label: 'Son Tarih',
                    value: _fmt.format(_sonTarih),
                    onTap: () => _pickDate(isIlk: false),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _getir,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Getir'),
                  ),
                ),
              ],
            ),
          ),

          // ÖZET KUTULAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Toplam',
                    value: toplam.toString(),
                    icon: Icons.summarize,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'Salkım',
                    value: salkim.toString(),
                    icon: Icons.local_florist,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: '2.Kalite',
                    value: ikinci.toString(),
                    icon: Icons.verified,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // HATA
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _ErrorBox(text: _error!),
            ),

          // LİSTE
          Expanded(
            child: _personelRows.isEmpty && !_loading
                ? const Center(
                    child: Text('Kayıt yok'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: _personelRows.length + (_hataliRow != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      // en alta hatalı barkod kartı
                      final int hataliIndex = _personelRows.length;
                      if (_hataliRow != null && index == hataliIndex) {
                        final h = _hataliRow!;
                        final hataliToplam = h.salkimDomates ?? 0;
                        return _HataliCard(count: hataliToplam);
                      }

                      final item = _personelRows[index];
                      return _PersonelCard(item: item);
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
        color: Colors.black.withOpacity(0.03),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
    final kod = item.personelKod?.toString() ?? '';
    final salkim = item.salkimDomates ?? 0;
    final ikinci = item.ikinciKalite ?? 0;
    final toplam = item.toplam ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          // Sol: Personel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.personel,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('Kod: $kod', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),

          // Sağ: Sayılar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                toplam.toString(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text('Salkım: $salkim', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              Text('2.Kalite: $ikinci', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ],
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