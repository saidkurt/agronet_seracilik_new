import 'package:agronet/api/depo_durum_api.dart';
import 'package:agronet/models/depo_durum_model.dart';
import 'package:flutter/material.dart';

class DepodurumRaporu extends StatefulWidget {
  final String personeladi;

  const DepodurumRaporu({
    Key? key,
    required this.personeladi,
  }) : super(key: key);

  @override
  State<DepodurumRaporu> createState() => _DepodurumRaporuState();
}

class _DepodurumRaporuState extends State<DepodurumRaporu> {
  static const Color accent = Color(0xFF1E6F5C);

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
      depodurumraporu();
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
        SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---- UI helpers ----
  InputDecoration _dec({
    required String hint,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF6F7F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accent, width: 1.6),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      itemCount: 10,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
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

  String _miktarStr(num? miktar) {
    if (miktar == null) return "-";
    final d = miktar.toDouble();
    return (d % 1 == 0) ? d.toInt().toString() : d.toStringAsFixed(2);
  }

  String _depoBaslik(int v) {
    switch (v) {
      case 2:
        return "Kırşehir Merkez Depo";
      case 3:
        return "1.Sera Üretim Depo";
      case 4:
        return "2.Sera Üretim Depo";
      case 5:
        return "3.Sera Üretim Depo";
      case 6:
        return "4.Sera Üretim Depo";
      case 10:
        return "Tesisat Sarf Deposu";
      case 11:
        return "Paketleme ve Sevkiyat Sarf Deposu";
      case 7:
        return "Fidelik Üretim Depo";
      case 8:
        return "1-3 Gübre ve İlaç Deposu";
      case 9:
        return "2-4 Gübre ve İlaç Deposu";
      default:
        return "Depo";
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text("Depo Durum Raporu"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Üst panel
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // personel chip
                  Row(
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
                          "Personel: ${widget.personeladi}",
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "Depo: $_value",
                          style: const TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // depo seç + getir
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFF6F7F9),
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
                              onChanged: _loading ? null : (v) => setState(() => _value = v ?? 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : depodurumraporu,
                          icon: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.refresh),
                          label: const Text(
                            "Getir",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // arama
                  TextField(
                    controller: _searchCtrl,
                    enabled: !_loading,
                    decoration: _dec(
                      hint: "Stok kodu / stok adı ara…",
                      icon: Icons.search,
                      suffix: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _searchCtrl.clear(),
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // seçili depo adı satırı
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.black54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _depoBaslik(_value),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "Kayıt: ${list.length}",
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Liste
          Expanded(
            child: _loading
                ? _buildSkeletonList()
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.inventory_2_outlined, size: 44, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("Kayıt yok"),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final x = list[i];

                          final kod = (x.stokKodu ?? "").trim();
                          final ad = (x.stokAdi ?? "").trim();
                          final birim = (x.birim ?? "").trim();
                          final miktarStr = _miktarStr(x.miktar);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade200),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                // sol rozet
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(.10),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.inventory, color: accent, size: 22),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              ad.isEmpty ? "-" : ad,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14.5,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            kod.isEmpty ? "-" : kod,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black54,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
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
        ],
      ),
    );
  }
}