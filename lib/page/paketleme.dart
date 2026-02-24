import 'package:agronet/api/kututipi_api.dart';
import 'package:agronet/api/palet_tipi.dart';
import 'package:agronet/api/paletleme_post_api.dart';
import 'package:agronet/api/stok_adlari_api.dart';
import 'package:agronet/page/PaletlemeRaporu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Paketleme extends StatefulWidget {
  final String personelkodu;
  final String personelAdi;
  const Paketleme({Key? key, required this.personelkodu, required this.personelAdi}) : super(key: key);

  @override
  State<Paketleme> createState() => _PaketlemeState();
}

class _PaketlemeState extends State<Paketleme> {
  final _formKey = GlobalKey<FormState>();

  static const Color accent = Color(0xFF1E6F5C);

  bool _loading = false;
  bool _dialogOpen = false;

  // Seçimler
  String kiosksecimi = "Kiosk 1";
  String stokkodu = "152.1.001";
  String kutukodu = "K06";
  String paletkodu = "PALET 1";

  // Inputlar
  final paletbosagirlik = TextEditingController();
  final kutusayisi = TextEditingController();
  final toplamkg = TextEditingController();

  // Dropdown dataları
  List stokadlari = [];
  List kututipi = [];
  List palet_tipi = [];

  bool _dropdownsReady = false;

  void _setLoading(bool v) {
    if (!mounted) return;
    setState(() => _loading = v);
  }

  Future<void> _showLoadingDialog() async {
    if (!mounted || _dialogOpen) return;
    _dialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoadingDialog() {
    if (!mounted) return;
    if (_dialogOpen && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    _dialogOpen = false;
  }

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final s = await StokAdlariApi().stokAdlari();
      final k = await KutuTipApi().kutuTipleri();
      final p = await PaletTipApi().paletTipleri();

      if (!mounted) return;
      setState(() {
        stokadlari = s;
        kututipi = k;
        palet_tipi = p;

        // Güvenli varsayılanlar
        if (stokadlari.isNotEmpty &&
            !stokadlari.any((e) => e['sto_kod'] == stokkodu)) {
          stokkodu = stokadlari.first['sto_kod'];
        }
        if (kututipi.isNotEmpty && !kututipi.any((e) => e['kod'] == kutukodu)) {
          kutukodu = kututipi.first['kod'];
        }
        if (palet_tipi.isNotEmpty &&
            !palet_tipi.any((e) => e['pak_kod'] == paletkodu)) {
          paletkodu = palet_tipi.first['pak_kod'];
        }

        _dropdownsReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _dropdownsReady = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Listeler alınamadı. İnterneti kontrol edin.")),
      );
    }
  }

  InputDecoration _dec({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accent, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _kaydet() async {
    if (!_dropdownsReady) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    _setLoading(true);
    await _showLoadingDialog();

    try {
      await PaletlemeApi().paletGonder(
        personelkodu: widget.personelkodu,
        paletbos: paletbosagirlik.text.trim(),
        kututipi: kutukodu,
        kutuadedi: kutusayisi.text.trim(),
        toplamagirlik: toplamkg.text.trim(),
        palettipi: paletkodu,
        cihazadi: kiosksecimi,
        stokkodu: stokkodu,
      );

      _hideLoadingDialog();
      _setLoading(false);

      if (!mounted) return;

      // Kısa başarı bildirimi
      showDialog(
        context: context,
        builder: (context) {
          Future.delayed(const Duration(milliseconds: 750), () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
          });
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Kaydedildi ✅"),
            content: Text("$paletkodu oluşturuldu"),
          );
        },
      );

      paletbosagirlik.clear();
      kutusayisi.clear();
      toplamkg.clear();
    } catch (e) {
      _hideLoadingDialog();
      _setLoading(false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }

  Future<void> _paletleriGor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaletlemeRaporPage()),
    );
  }

  @override
  void dispose() {
    paletbosagirlik.dispose();
    kutusayisi.dispose();
    toplamkg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text("Paketleme"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: w > 560 ? 560 : w),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Üst küçük bilgilendirme chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge, color: accent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Personel: ${widget.personelAdi}",
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    _sectionCard(
                      title: "Cihaz / Kiosk",
                      icon: Icons.devices,
                      children: [
                        DropdownButtonFormField<String>(
                          value: kiosksecimi,
                          isExpanded: true,
                          decoration: _dec(label: "Kiosk", hint: "Cihaz seçin", icon: Icons.devices),
                          items: const [
                            DropdownMenuItem(value: "Kiosk 1", child: Text("Kiosk 1")),
                            DropdownMenuItem(value: "Kiosk 2", child: Text("Kiosk 2")),
                          ],
                          onChanged: (v) => setState(() => kiosksecimi = v ?? "Kiosk 1"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _sectionCard(
                      title: "Ağırlık / Adet",
                      icon: Icons.scale,
                      children: [
                        TextFormField(
                          controller: paletbosagirlik,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"[0-9\.,]")),
                          ],
                          decoration: _dec(
                            label: "Palet Boş Ağırlığı",
                            hint: "Örn: 18,5",
                            icon: Icons.line_weight,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Boş olamaz";
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: kutusayisi,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _dec(
                            label: "Kutu Sayısı",
                            hint: "Örn: 60",
                            icon: Icons.inventory_2,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Boş olamaz";
                            final n = int.tryParse(v.trim());
                            if (n == null || n <= 0) return "Geçerli sayı gir";
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: toplamkg,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"[0-9\.,]")),
                          ],
                          decoration: _dec(
                            label: "Toplam Kg",
                            hint: "Örn: 480,0",
                            icon: Icons.monitor_weight,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Boş olamaz";
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _sectionCard(
                      title: "Seçimler",
                      icon: Icons.tune,
                      children: [
                        if (!_dropdownsReady)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          DropdownButtonFormField<String>(
                            value: stokkodu,
                            isExpanded: true,
                            decoration: _dec(label: "Ürün (Stok)", hint: "Ürün seçin", icon: Icons.local_florist),
                            selectedItemBuilder: (context) {
                              return stokadlari.map<Widget>((item) {
                                final text = "${item['sto_kisa_ismi']}";
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
                                );
                              }).toList();
                            },
                            items: stokadlari.map<DropdownMenuItem<String>>((item) {
                              final text = "${item['sto_kisa_ismi']}";
                              return DropdownMenuItem<String>(
                                value: item['sto_kod'],
                                child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => stokkodu = v ?? stokkodu),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: kutukodu,
                            isExpanded: true,
                            decoration: _dec(label: "Kutu Tipi", hint: "Kutu seçin", icon: Icons.all_inbox),
                            selectedItemBuilder: (context) {
                              return kututipi.map<Widget>((item) {
                                final text = "${item['isim']}";
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
                                );
                              }).toList();
                            },
                            items: kututipi.map<DropdownMenuItem<String>>((item) {
                              final text = "${item['isim']}";
                              return DropdownMenuItem<String>(
                                value: item['kod'],
                                child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => kutukodu = v ?? kutukodu),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: paletkodu,
                            isExpanded: true,
                            decoration: _dec(label: "Palet Tipi", hint: "Palet seçin", icon: Icons.view_module),
                            selectedItemBuilder: (context) {
                              return palet_tipi.map<Widget>((item) {
                                final text = "${item['pak_ismi']}";
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
                                );
                              }).toList();
                            },
                            items: palet_tipi.map<DropdownMenuItem<String>>((item) {
                              final text = "${item['pak_ismi']}";
                              return DropdownMenuItem<String>(
                                value: item['pak_kod'],
                                child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => paletkodu = v ?? paletkodu),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Butonlar
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        label: const Text(
                          "Kaydet",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        onPressed: _loading ? null : _kaydet,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.list_alt),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        label: const Text(
                          "Paletleri Gör",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        onPressed: _loading ? null : _paletleriGor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}