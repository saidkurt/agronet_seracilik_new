import 'package:agronet/api/depo_durum_api.dart';
import 'package:agronet/models/depo_durum_model.dart';
import 'package:flutter/material.dart';

class DepodurumRaporu extends StatefulWidget {
  final String personelkodu;

  const DepodurumRaporu({
    Key? key,
    required this.personelkodu,
  }) : super(key: key);

  @override
  State<DepodurumRaporu> createState() => _DepodurumRaporuState();
}

class _DepodurumRaporuState extends State<DepodurumRaporu> {
  final _api = DepoDurumApi();
  final _searchCtrl = TextEditingController();

  bool _loading = false;
  String _query = "";

  int _value = 2; // depo no
  List<DepoDurumModel> sonuc = [];

 @override
void initState() {
  super.initState();

  _searchCtrl.addListener(() {
    setState(() => _query = _searchCtrl.text.trim().toLowerCase());
  });

  // ✅ sayfa açılır açılmaz depo=2 çek
  WidgetsBinding.instance.addPostFrameCallback((_) {
    depodurumraporu(); // _value zaten 2
  });
}
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DepoDurumModel> get _filtered {
    if (_query.isEmpty) return sonuc;

    return sonuc.where((x) {
      final kod = (x.stokKodu ?? "").toLowerCase();
      final ad = (x.stokAdi ?? "").toLowerCase();
      return kod.contains(_query) || ad.contains(_query);
    }).toList();
  }

  Future<void> depodurumraporu() async {
    setState(() => _loading = true);

    try {
      final data = await _api.depoDurumGetir(_value);
      if (!mounted) return;
      setState(() => sonuc = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => sonuc = []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildSkeletonList() {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
        );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      itemCount: 10,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                bar(110, 14),
                const Spacer(),
                bar(70, 14),
              ],
            ),
            const SizedBox(height: 10),
            bar(240, 14),
            const SizedBox(height: 10),
            Row(
              children: [
                bar(110, 22),
                const SizedBox(width: 8),
                bar(70, 22),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
  title: const Text("Depo Durum Raporu"),
  centerTitle: true,
),

      body: Column(
        children: [
          // ✅ ÜST PANEL (depo seç + getir + arama)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: _value,
                            items: const [
                              DropdownMenuItem(value: 2, child: Text("Kırşehir Merkez Depo")),
                              DropdownMenuItem(value: 3, child: Text("1.Sera Üretim Depo")),
                              DropdownMenuItem(value: 4, child: Text("2.Sera Üretim Depo")),
                              DropdownMenuItem(value: 5, child: Text("3.Sera Üretim Depo")),
                              DropdownMenuItem(value: 6, child: Text("4.Sera Üretim Depo")),
                              DropdownMenuItem(value: 10, child: Text("Tesisat Sarf Deposu")),
                              DropdownMenuItem(value: 11, child: Text("Paketleme ve Sevkiyat Sarf Deposu")),
                              DropdownMenuItem(value: 7, child: Text("Fidelik Üretim Depo")),
                              DropdownMenuItem(value: 8, child: Text("1-3 Gübre ve İlaç Deposu")),
                              DropdownMenuItem(value: 9, child: Text("2-4 Gübre ve İlaç Deposu")),
                            ],
                            onChanged: _loading
                                ? null
                                : (v) => setState(() => _value = v ?? 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : depodurumraporu,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                        label: const Text("Getir"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _searchCtrl,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    hintText: "Stok kodu / stok adı ara…",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _searchCtrl.clear(),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),

          // ✅ LİSTE
          Expanded(
            child: Container(
              color: Colors.white,
              width: double.infinity,
              child: _loading
                  ? _buildSkeletonList()
                  : list.isEmpty
                      ? const Center(child: Text("Kayıt yok"))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final x = list[i];

                            final kod = (x.stokKodu ?? "").trim();
                            final ad = (x.stokAdi ?? "").trim();
                            final miktar = x.miktar;
                            final birim = (x.birim ?? "").trim();

                            final miktarStr = miktar == null
                                ? "-"
                                : (miktar % 1 == 0 ? miktar.toInt().toString() : miktar.toStringAsFixed(2));

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black12),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 98,
                                    child: Text(
                                      kod.isEmpty ? "-" : kod,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ad.isEmpty ? "-" : ad,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _pill("Miktar", miktarStr),
                                            _pill("Birim", birim.isEmpty ? "-" : birim),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withOpacity(0.04),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}