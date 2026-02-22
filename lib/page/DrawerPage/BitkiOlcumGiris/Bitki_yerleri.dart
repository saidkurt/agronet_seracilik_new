import 'dart:convert';
import 'package:agronet/api/bitki_olcum_tipleri_api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:agronet/const/string.dart';
import 'package:agronet/api/bitki_yerleri_api.dart';
import 'package:agronet/models/bitki_sera_yerler.dart';
import 'package:agronet/models/olcum_tipleri.dart';

class BitkiOlcumSahaSayfa extends StatefulWidget {
  /// Sayfa açılırken gelecek: personel kodu (createuser olarak gönderilecek)
  final String personelKodu;

  const BitkiOlcumSahaSayfa({
    super.key,
    required this.personelKodu,
  });

  @override
  State<BitkiOlcumSahaSayfa> createState() => _BitkiOlcumSahaSayfaState();
}

class _BitkiOlcumSahaSayfaState extends State<BitkiOlcumSahaSayfa> {
  // Üst bilgiler
  DateTime secilenTarih = DateTime.now();
  String? seciliSera; // sadece bilgi amaçlı
  String? seciliYer;  // vana/yer

  // Zorunlular
  final TextEditingController uzamaCtrl = TextEditingController();
  final TextEditingController kalinlikCtrl = TextEditingController();

  // Diğer ölçüm (tek tek)
  OlcumTipleriModel? seciliTip;
  final TextEditingController degerCtrl = TextEditingController();

  // Data
  late Future<_InitData> _initFuture;

  // UI state
  bool zorunluTamamlandi = false; // true olunca zorunlu kart animasyonla gizlenir
  bool loadingZorunlu = false;
  bool loadingEk = false;

  static const int idUzama = 35;
  static const int idKalinlik = 36;

  @override
  void initState() {
    super.initState();
    _initFuture = _loadAll();
  }

  @override
  void dispose() {
    uzamaCtrl.dispose();
    kalinlikCtrl.dispose();
    degerCtrl.dispose();
    super.dispose();
  }

  Future<_InitData> _loadAll() async {
    final yerler = await BitkiSeraYerleriApi().getir();
    final tipler = await const OlcumTipleriApi().getir();
    return _InitData(yerler: yerler, tipler: tipler);
  }

  bool get yerSeciliMi => (seciliSera != null && seciliYer != null);

  bool get zorunluHazir =>
      yerSeciliMi &&
      uzamaCtrl.text.trim().isNotEmpty &&
      kalinlikCtrl.text.trim().isNotEmpty;

  bool get ekOlcumHazir =>
      zorunluTamamlandi &&
      yerSeciliMi &&
      seciliTip != null &&
      degerCtrl.text.trim().isNotEmpty;

  // Yer değişince her şey reset + zorunlu geri gelsin
  void _resetOnYerChanged() {
    zorunluTamamlandi = false;

    uzamaCtrl.clear();
    kalinlikCtrl.clear();

    seciliTip = null;
    degerCtrl.clear();
  }

  // ----------------------------
  // SERA + YER SEÇ (BOTTOMSHEET)
  // ----------------------------
  void _seraYerSec(List<SeraYerModel> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: data.expand((sera) {
              final seraAdi = sera.sera ?? "";
              return [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    seraAdi,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ...?sera.yerler?.map(
                  (y) => ListTile(
                    title: Text(y),
                    onTap: () {
                      setState(() {
                        final bool degisti =
                            (seciliSera != seraAdi) || (seciliYer != y);

                        seciliSera = seraAdi;
                        seciliYer = y;

                        if (degisti) {
                          _resetOnYerChanged();
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ];
            }).toList(),
          ),
        );
      },
    );
  }

  // ----------------------------
  // POST /Sera/OlcumKaydet (tek ölçüm)
  // ----------------------------
  Future<void> _postTekOlcum({
    required DateTime tarih,
    required String sera,
    required String vana,
    required String tip,
    required String deger,
    required int bildirildi,
  }) async {
    final uri = Uri.parse("${App.localurl}/Sera/OlcumKaydet");

    final body = {
      "tarih": _yyyyMmDd(tarih),
      "sera": sera,
      "vana": vana,
      "createuser": widget.personelKodu, // ✅ personel kodu gönderiliyor
      "tip": tip,
      "deger": deger,
      "bildirildi": bildirildi,
    };

    final res = await http.post(
      uri,
      headers: const {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception("Kayıt başarısız. Status: ${res.statusCode} Body: ${res.body}");
    }

    // Backend {success:false} döndürebilir diye kontrol
    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      decoded = null;
    }
    if (decoded is Map && decoded["success"] == false) {
      throw Exception(decoded["message"] ?? "Kayıt başarısız");
    }
  }

  // ----------------------------
  // ZORUNLULARI KAYDET (35-36)
  // ----------------------------
  Future<void> _kaydetZorunlular(_InitData init) async {
    if (!zorunluHazir || loadingZorunlu) return;

    setState(() => loadingZorunlu = true);
    try {
      final uzamaTip = init.tipById(idUzama);
      final kalinlikTip = init.tipById(idKalinlik);

      await _postTekOlcum(
        tarih: secilenTarih,
        sera: seciliSera!,
        vana: seciliYer!,
        tip: uzamaTip?.isim ?? "Bitki Uzaması (cm)",
        deger: uzamaCtrl.text.trim(),
        bildirildi: uzamaTip?.bildir ?? 0,
      );

      await _postTekOlcum(
        tarih: secilenTarih,
        sera: seciliSera!,
        vana: seciliYer!,
        tip: kalinlikTip?.isim ?? "Tepe Kalınlığı (mm)",
        deger: kalinlikCtrl.text.trim(),
        bildirildi: kalinlikTip?.bildir ?? 0,
      );

      setState(() {
        zorunluTamamlandi = true; // ✅ animasyonla zorunlular gizlenecek
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bitki Bilgileri Kaydedildi ✅")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      if (mounted) setState(() => loadingZorunlu = false);
    }
  }

  // ----------------------------
  // EK ÖLÇÜM KAYDET (dropdown ile tek ölçüm)
  // ----------------------------
  Future<void> _kaydetEkOlcum() async {
    if (!ekOlcumHazir || loadingEk) return;

    setState(() => loadingEk = true);
    try {
      await _postTekOlcum(
        tarih: secilenTarih,
        sera: seciliSera!,
        vana: seciliYer!,
        tip: seciliTip!.isim ?? "",
        deger: degerCtrl.text.trim(),
        bildirildi: seciliTip!.bildir ?? 0,
      );

      setState(() {
        degerCtrl.clear(); // sadece değer temizlensin (hız için)
        // seciliTip'i istersen aynı bırak, hızlı tekrar kayıt için iyi
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ölçüm Kaydedildi ✅")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      if (mounted) setState(() => loadingEk = false);
    }
  }

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bitki Ölçüm Girişi")),
      body: FutureBuilder<_InitData>(
        future: _initFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final init = snap.data!;

          // Zorunlu label’ları API’den al
          final uzamaLabel = init.tipById(idUzama)?.isim ?? "Bitki Uzaması (cm)";
          final kalinlikLabel = init.tipById(idKalinlik)?.isim ?? "Tepe Kalınlığı (mm)";

          // Dropdown tipleri: manuelGiris==1 ve 35-36 hariç
          final tiplerDropdown = init.tipler
              .where((x) => (x.manuelGiris ?? 0) == 1)
              .where((x) => (x.id ?? 0) != idUzama && (x.id ?? 0) != idKalinlik)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Üst bilgi satırları (sadece Tarih/Sera/Yer)
              _infoRow(
                title: "Tarih",
                value: _yyyyMmDd(secilenTarih),
                onTap: () async {
                  final t = await showDatePicker(
                    context: context,
                    initialDate: secilenTarih,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (t != null) setState(() => secilenTarih = t);
                },
              ),
              const SizedBox(height: 10),

              _infoRow(
                title: "Sera",
                value: seciliSera ?? "Seç",
                onTap: () => _seraYerSec(init.yerler),
              ),
              const SizedBox(height: 10),

              _infoRow(
                title: "Yer",
                value: seciliYer ?? "Seç",
                onTap: () => _seraYerSec(init.yerler),
              ),

              const SizedBox(height: 16),

            
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: (!yerSeciliMi || zorunluTamamlandi)
                    ? const SizedBox.shrink(key: ValueKey("zorunlu_hidden"))
                    : _card(
                        key: const ValueKey("zorunlu_shown"),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Zorunlu Ölçümler",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: uzamaCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: uzamaLabel),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: kalinlikCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: kalinlikLabel),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 14),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (!zorunluHazir || loadingZorunlu)
                                    ? null
                                    : () => _kaydetZorunlular(init),
                                child: loadingZorunlu
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text("Zorunluları Kaydet"),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              // Diğer ölçümler (zorunlu tamamlanınca aktif)
              const SizedBox(height: 12),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Diğer Ölçümler",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: zorunluTamamlandi ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<OlcumTipleriModel>(
                      value: seciliTip,
                      items: tiplerDropdown
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.isim ?? ""),
                              ))
                          .toList(),
                      onChanged: (!zorunluTamamlandi || !yerSeciliMi)
                          ? null
                          : (v) {
                              setState(() {
                                seciliTip = v;
                                degerCtrl.clear(); // tip değişince değer sıfırla
                              });
                            },
                      decoration: const InputDecoration(
                        labelText: "Ölçüm Tipi",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: degerCtrl,
                      enabled: zorunluTamamlandi && yerSeciliMi && seciliTip != null,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Değer",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (!ekOlcumHazir || loadingEk) ? null : _kaydetEkOlcum,
                        child: loadingEk
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Ölçüm Kaydet"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------
  // UI Helpers
  // ----------------------------
  Widget _card({Key? key, required Widget child}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _infoRow({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  String _yyyyMmDd(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${d.year}-${two(d.month)}-${two(d.day)}";
  }
}

class _InitData {
  final List<SeraYerModel> yerler;
  final List<OlcumTipleriModel> tipler;

  _InitData({required this.yerler, required this.tipler});

  OlcumTipleriModel? tipById(int id) {
    for (final t in tipler) {
      if ((t.id ?? 0) == id) return t;
    }
    return null;
  }
}
