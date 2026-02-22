import 'package:agronet/api/palet_detay_api.dart';
import 'package:agronet/api/paletleme_rapor.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:agronet/models/paletleme_rapor_model.dart';
import 'package:agronet/api/etiket_tekrar_paletleme.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // SerapaketApi burada

class PaletlemeRaporPage extends StatefulWidget {
  const PaletlemeRaporPage({super.key});

  @override
  State<PaletlemeRaporPage> createState() => _PaletlemeRaporPageState();
}

class _PaletlemeRaporPageState extends State<PaletlemeRaporPage> {
  final _api = const PaletlemeRaporApi();
  final _serapaketApi = SerapaketApi();
  final _searchCtrl = TextEditingController();

  DateTime _ilkTarih = DateTime.now();
  DateTime _sonTarih = DateTime.now();

  bool _loading = false;
  String? _selectedUrun;
  bool _sortDesc = true;
  String? _error;

  List<PaletlemeRaporModel> _items = [];
  String _query = "";

  final _df = DateFormat('dd.MM.yyyy');
  final _tf = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
    _getir();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

List<String> get _urunAdlari {
  final set = <String>{};

  for (final x in _items) {
    final s = (x.urunAdi ?? '').trim();
    if (s.isNotEmpty && s.toLowerCase() != 'null') set.add(s);
  }

  final list = set.toList()..sort(); // alfabetik
  return list;
}
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
      final data = await _api.paletlemeGetir(_ilkTarih, _sonTarih);
      setState(() => _items = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _paletSil(String paletKodu) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Palet Sil'),
        content: Text('$paletKodu paleti silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _serapaketApi.paletSil(paletkodu: paletKodu);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Palet silindi ✅')),
      );

      await _getir();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

List<PaletlemeRaporModel> get _filtered {
  var list = List<PaletlemeRaporModel>.from(_items);

  // ✅ sadece ürün adına göre seçim filtresi
  if (_selectedUrun != null) {
    list = list.where((x) => (x.urunAdi ?? '').trim() == _selectedUrun).toList();
  }

  // tarih sıralama
  list.sort((a, b) {
    final da = a.olusmaZamani ?? DateTime.fromMillisecondsSinceEpoch(0);
    final db = b.olusmaZamani ?? DateTime.fromMillisecondsSinceEpoch(0);
    final c = da.compareTo(db);
    return _sortDesc ? -c : c;
  });

  return list;
}

  int get _paletAdet => _filtered.length;
  int get _kutuToplam => _filtered.fold<int>(0, (s, x) => s + (x.kutuSayisi ?? 0));
int get _netToplam =>
    _filtered.fold<int>(0, (s, x) => s + (x.netKg?.round() ?? 0));

int get _brutToplam =>
    _filtered.fold<int>(0, (s, x) => s + (x.brutKg?.round() ?? 0));
Future<void> _qrOkuVeDetayGoster() async {
  String? paletKodu;

  // Emülatörde kamera yoksa manuel gir
  // İstersen bunu platforma göre de ayırırız, şimdilik direkt seçenek veriyorum.
final picked = await showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
  ),
  builder: (ctx) {
    final bottom = MediaQuery.of(ctx).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: _QrOrManualSheet(
        onManual: (v) => Navigator.pop(ctx, v),
        onScan: () => Navigator.pop(ctx, "__SCAN__"),
      ),
    );
  },
);

  if (picked == null) return;

  if (picked == "__SCAN__") {
    // gerçek cihazda kamera ile tara
    paletKodu = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QrScanPage()),
    );
  } else {
    // manuel girilen
    paletKodu = picked;
  }

  if (paletKodu == null || paletKodu.trim().isEmpty) return;

  setState(() => _loading = true);

  try {
    final detay = await PaletDetayApi().paletDetayGetir(paletkodu: paletKodu.trim());

    if (!mounted) return;
    setState(() => _loading = false);

    await _showPaletDetaySheet(detay);
  } catch (e) {
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detay alınamadı: $e')),
    );
  }
}
Future<void> _showPaletDetaySheet(PaletlemeRaporModel detay) async {
  final palet = (detay.paletKodu ?? '').trim();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true, // ✅ şart
    useSafeArea: true,        // ✅
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).viewInsets.bottom; // ✅ klavye yüksekliği

      return AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SizedBox(
            // ✅ Ekranın büyük kısmını kullan, klavye gelince de içerik kaysın
            height: MediaQuery.of(ctx).size.height * 0.55,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ İçerik scroll olsun (klavye gelince bu alan küçülür)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: _PaletDetayCard(detay: detay),
                  ),
                ),

                const Divider(height: 1),

                // ✅ Alt butonlar sabit kalsın
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Vazgeç'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Sil'),
                          onPressed: palet.isEmpty
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  await _paletSil(palet);
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      appBar: AppBar(
  title: const Text('Paletleme Raporu'),
  actions: [
    IconButton(
      tooltip: 'QR ile Palet Bul/Sil',
      icon: const Icon(Icons.qr_code_scanner),
      onPressed: _loading ? null : _qrOkuVeDetayGoster,
    ),
  ],
),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: _DateChip(
                    label: 'İlk',
                    value: _df.format(_ilkTarih),
                    onTap: () => _pickDate(isIlk: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateChip(
                    label: 'Son',
                    value: _df.format(_sonTarih),
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

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Padding(
  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
  child: SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _UrunChip(
          text: "Tümü",
          selected: _selectedUrun == null,
          onTap: () => setState(() => _selectedUrun = null),
        ),
        const SizedBox(width: 8),
        ..._urunAdlari.map((u) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _UrunChip(
                text: u,
                selected: _selectedUrun == u,
                onTap: () => setState(() => _selectedUrun = u),
              ),
            )),
      ],
    ),
  ),
),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Palet',
                    value: _paletAdet.toString(),
                    icon: Icons.inventory_2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'Kutu',
                    value: _kutuToplam.toString(),
                    icon: Icons.all_inbox,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'Net',
                    value: _netToplam.toString(),
                    icon: Icons.scale,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'Brüt',
                    value: _brutToplam.toString(),
                    icon: Icons.monitor_weight,
                  ),
                ),
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _loading
                  ? ListView.builder(
                      key: const ValueKey("loading"),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      itemCount: 8,
                      itemBuilder: (_, __) => const _SkeletonCard(),
                    )
                  : RefreshIndicator(
                      key: const ValueKey("list"),
                      onRefresh: _getir,
                      child: list.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 140),
                                Center(child: Text('Kayıt yok')),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final x = list[i];
                                final palet = x.paletKodu ?? "";
                                return _PaletCard(
                                  item: x,
                                  timeFormatter: _tf,
                                  dateFormatter: _df,
                                  onDelete: palet.isEmpty
                                      ? null
                                      : () => _paletSil(palet),
                                );
                              },
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- Widgets -----------------

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

class _StatCard extends StatelessWidget {
  const _StatCard({
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
      padding: const EdgeInsets.all(10),
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
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletCard extends StatelessWidget {
  const _PaletCard({
    required this.item,
    required this.timeFormatter,
    required this.dateFormatter,
    this.onDelete,
  });

  final PaletlemeRaporModel item;
  final DateFormat timeFormatter;
  final DateFormat dateFormatter;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final dt = item.olusmaZamani;
    final dateStr = dt == null ? "-" : dateFormatter.format(dt);
    final timeStr = dt == null ? "-" : timeFormatter.format(dt);

    final musteri = (item.musteri ?? "").trim();
    final yuklenmedi = musteri.toLowerCase() == "yüklenmedi";

    final net = (item.netKg ?? 0).toStringAsFixed(2);
    final brut = (item.brutKg ?? 0).toStringAsFixed(2);
    final ort = (item.paletOrtalamasi ?? 0).toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.paletKodu ?? "-",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '$dateStr  $timeStr',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Sil',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.urunKodu ?? ""}  ${item.urunAdi ?? ""}'.trim(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  musteri.isEmpty ? "-" : musteri,
                  style: TextStyle(
                    fontSize: 12,
                    color: yuklenmedi ? Colors.black87 : Colors.black54,
                    fontWeight: yuklenmedi ? FontWeight.w700 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (yuklenmedi)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.orange.withOpacity(0.12),
                    border: Border.all(color: Colors.orange.withOpacity(0.35)),
                  ),
                  child: const Text(
                    'Yüklenmedi',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          Row(
            children: [
              _MiniPill(label: 'Kutu', value: (item.kutuSayisi ?? 0).toString()),
              _MiniPill(label: 'Ort', value: ort),
              _MiniPill(label: 'Boş', value: (item.paletBosAgirligi ?? 0).toStringAsFixed(2)),
              Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Net: $net', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Brüt: $brut', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withOpacity(0.03),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    Widget bar({double w = 120, double h = 12}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withOpacity(0.06),
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              bar(w: 160, h: 16),
              const Spacer(),
              bar(w: 90, h: 12),
            ],
          ),
          const SizedBox(height: 10),
          bar(w: 240, h: 12),
          const SizedBox(height: 10),
          bar(w: 200, h: 12),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              bar(w: 90, h: 24),
              const SizedBox(width: 8),
              bar(w: 90, h: 24),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [bar(w: 70, h: 12), const SizedBox(height: 6), bar(w: 70, h: 12)],
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _QrScanPage extends StatefulWidget {
  const _QrScanPage();

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Oku')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_done) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final raw = barcodes.first.rawValue ?? '';
              final code = raw.trim();
              if (code.isEmpty) return;

              _done = true;
              Navigator.pop(context, code);
            },
          ),

          // küçük hedef çerçeve
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 22,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Palet QR/Barkod okutun…',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletDetayCard extends StatelessWidget {
  const _PaletDetayCard({required this.detay});
  final PaletlemeRaporModel detay;

  @override
  Widget build(BuildContext context) {
    final dt = detay.olusmaZamani;
    final dtStr = dt == null ? '-' : DateFormat('dd.MM.yyyy  HH:mm').format(dt);

    final urun = (detay.urunAdi ?? '').trim();
    final urunKodu = (detay.urunKodu ?? '').trim();
    final palet = (detay.paletKodu ?? '').trim();

    final kutu = (detay.kutuSayisi ?? 0).toString();
    final bos = (detay.paletBosAgirligi ?? 0).round().toString();
    final net = (detay.netKg ?? 0).round().toString();
    final brut = (detay.brutKg ?? 0).round().toString();
    final ort = (detay.paletOrtalamasi ?? 0).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            palet.isEmpty ? '-' : palet,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(dtStr, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 10),

          Text(
            urun.isEmpty ? (urunKodu.isEmpty ? '-' : urunKodu) : '$urunKodu  $urun',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(label: 'Kutu', value: kutu),
              _MiniPill(label: 'Boş', value: bos),
              _MiniPill(label: 'Ort', value: ort),
              _MiniPill(label: 'Net', value: net),
              _MiniPill(label: 'Brüt', value: brut),
            ],
          ),
        ],
      ),
    );
  }
}

class _QrOrManualSheet extends StatefulWidget {
  const _QrOrManualSheet({
    required this.onManual,
    required this.onScan,
  });

  final ValueChanged<String> onManual;
  final VoidCallback onScan;

  @override
  State<_QrOrManualSheet> createState() => _QrOrManualSheetState();
}

class _QrOrManualSheetState extends State<_QrOrManualSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: const [
                Icon(Icons.qr_code_scanner),
                SizedBox(width: 8),
                Text(
                  'Palet Kodu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'P260221009 gibi…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onScan, // gerçek cihazda tarama
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Tara'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final v = _ctrl.text.trim();
                      if (v.isEmpty) return;
                      widget.onManual(v);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Kodu Kullan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class _UrunChip extends StatelessWidget {
  const _UrunChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.03),
          border: Border.all(color: selected ? Colors.black26 : Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}