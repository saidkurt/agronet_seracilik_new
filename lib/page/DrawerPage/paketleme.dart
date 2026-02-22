import 'package:agronet/api/kututipi_api.dart';
import 'package:agronet/api/palet_tipi.dart';
import 'package:agronet/api/paletleme_post_api.dart';
import 'package:agronet/api/stok_adlari_api.dart';
import 'package:agronet/page/DrawerPage/PaletlemeRaporu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Paketleme extends StatefulWidget {
  final String personelkodu;
  const Paketleme({Key? key, required this.personelkodu}) : super(key: key);

  @override
  State<Paketleme> createState() => _PaketlemeState();
}

class _PaketlemeState extends State<Paketleme> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;

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

  // ✅ Stack yok → loading için dialog
  Future<void> _showLoadingDialog() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoadingDialog() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
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

        // Güvenli varsayılanlar (listelerde yoksa ilk elemanı al)
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
      setState(() => _dropdownsReady = true); // hata olsa da ekran açılsın
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Listeler alınamadı. İnterneti kontrol edin.")),
      );
    }
  }

  InputDecoration _dec(String hint, IconData icon) {
    // ✅ arka normal olacak, o yüzden beyaz yazı yerine standart tema
    return InputDecoration(
      prefixIcon: Icon(icon),
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
          Future.delayed(const Duration(milliseconds: 700), () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
          });
          return AlertDialog(
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
      MaterialPageRoute(
        builder: (_) => PaletlemeRaporPage(),
      ),
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
      // ✅ normal arka plan
      backgroundColor: Colors.grey.shade100,

      // ✅ normal appbar + başlık Paketleme
      appBar: AppBar(
        title: const Text("Paketleme"),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: w > 520 ? 520 : w),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  
                    DropdownButtonFormField<String>(
                      value: kiosksecimi,
                      isExpanded: true,
                      decoration: _dec("Kiosk", Icons.devices),
                      items: const [
                        DropdownMenuItem(value: "Kiosk 1", child: Text("Kiosk 1")),
                        DropdownMenuItem(value: "Kiosk 2", child: Text("Kiosk 2")),
                      ],
                      onChanged: (v) => setState(() => kiosksecimi = v ?? "Kiosk 1"),
                    ),

                    const SizedBox(height: 10),

                    // Palet boş ağırlık
                    TextFormField(
                      controller: paletbosagirlik,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[0-9\.,]")),
                      ],
                      decoration: _dec("Palet Boş Ağırlığı", Icons.line_weight),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Boş olamaz";
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    // Kutu sayısı
                    TextFormField(
                      controller: kutusayisi,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _dec("Kutu Sayısı", Icons.inventory_2),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Boş olamaz";
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) return "Geçerli sayı gir";
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    // Toplam KG
                    TextFormField(
                      controller: toplamkg,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[0-9\.,]")),
                      ],
                      decoration: _dec("Toplam Kg", Icons.scale),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Boş olamaz";
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Dropdownlar (stok/kutu/palet)
                    if (!_dropdownsReady)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 22),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      // STOK (uzun isim taşmasın)
                      DropdownButtonFormField<String>(
                        value: stokkodu,
                        isExpanded: true,
                        decoration: _dec("Ürün (Stok)", Icons.local_florist),
                        selectedItemBuilder: (context) {
                          return stokadlari.map<Widget>((item) {
                            final text = "${item['sto_kisa_ismi']}";
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList();
                        },
                        items: stokadlari.map<DropdownMenuItem<String>>((item) {
                          final text = "${item['sto_kisa_ismi']}";
                          return DropdownMenuItem<String>(
                            value: item['sto_kod'],
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => stokkodu = v ?? stokkodu),
                      ),

                      const SizedBox(height: 10),

                      // KUTU
                      DropdownButtonFormField<String>(
                        value: kutukodu,
                        isExpanded: true,
                        decoration: _dec("Kutu Tipi", Icons.all_inbox),
                        selectedItemBuilder: (context) {
                          return kututipi.map<Widget>((item) {
                            final text = "${item['isim']}";
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList();
                        },
                        items: kututipi.map<DropdownMenuItem<String>>((item) {
                          final text = "${item['isim']}";
                          return DropdownMenuItem<String>(
                            value: item['kod'],
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => kutukodu = v ?? kutukodu),
                      ),

                      const SizedBox(height: 10),

                      // PALET
                      DropdownButtonFormField<String>(
                        value: paletkodu,
                        isExpanded: true,
                        decoration: _dec("Palet Tipi", Icons.view_module),
                        selectedItemBuilder: (context) {
                          return palet_tipi.map<Widget>((item) {
                            final text = "${item['pak_ismi']}";
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList();
                        },
                        items: palet_tipi.map<DropdownMenuItem<String>>((item) {
                          final text = "${item['pak_ismi']}";
                          return DropdownMenuItem<String>(
                            value: item['pak_kod'],
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => paletkodu = v ?? paletkodu),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ✅ KAYDET
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown.shade500,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        label: const Text(
                          "Kaydet",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        onPressed: _loading ? null : _kaydet,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ✅ Paletleri Gör
                    SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.list_alt),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        label: const Text("Paletleri Gör"),
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