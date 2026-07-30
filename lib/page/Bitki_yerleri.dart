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
  final String personelAdi;

  const BitkiOlcumSahaSayfa({
    super.key,
    required this.personelKodu,
    required this.personelAdi,
  });

  @override
  State<BitkiOlcumSahaSayfa> createState() => _BitkiOlcumSahaSayfaState();
}

class _BitkiOlcumSahaSayfaState extends State<BitkiOlcumSahaSayfa> {
  // Tema
  static const Color accent = Color(0xFF1E6F5C);

  // Üst bilgiler
  DateTime secilenTarih = DateTime.now();
  String? seciliSera;
  String? seciliYer;

  // Zorunlular
  final TextEditingController uzamaCtrl = TextEditingController();
  final TextEditingController kalinlikCtrl = TextEditingController();

  // Diğer ölçüm
  OlcumTipleriModel? seciliTip;
  final TextEditingController degerCtrl = TextEditingController();

  // Data
  late Future<_InitData> _initFuture;

  // UI state
  bool zorunluTamamlandi = false;
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

  void _resetOnYerChanged() {
    zorunluTamamlandi = false;
    uzamaCtrl.clear();
    kalinlikCtrl.clear();
    seciliTip = null;
    degerCtrl.clear();
  }

  // ----------------------------
  // SERA + YER SEÇ (BOTTOMSHEET) - aramalı / daha güzel
  // ----------------------------
  void _seraYerSec(List<SeraYerModel> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        String q = "";
        final ctrl = TextEditingController();

        List<_YerItem> flatten(String query) {
          final list = <_YerItem>[];
          for (final s in data) {
            final seraAdi = (s.sera ?? "").trim();
            for (final y in (s.yerler ?? const <String>[])) {
              final yer = y.trim();
              final haystack = "$seraAdi $yer".toLowerCase();
              if (query.isEmpty || haystack.contains(query.toLowerCase())) {
                list.add(_YerItem(sera: seraAdi, yer: yer));
              }
            }
          }
          return list;
        }

        return StatefulBuilder(
          builder: (context, setBS) {
            final items = flatten(q);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: 10,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: const [
                        Icon(Icons.place, color: accent),
                        SizedBox(width: 8),
                        Text(
                          "Sera / Yer Seç",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: ctrl,
                      onChanged: (v) => setBS(() => q = v.trim()),
                      decoration: InputDecoration(
                        hintText: "Ara... (Örn: 1.SERA, Vana 3)",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFF6F7F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Flexible(
                      child: items.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              child: Column(
                                children: const [
                                  Icon(Icons.search_off, size: 42, color: Colors.grey),
                                  SizedBox(height: 10),
                                  Text("Sonuç bulunamadı"),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final it = items[i];
                                final selected =
                                    (seciliSera == it.sera) && (seciliYer == it.yer);

                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  title: Text(
                                    it.yer,
                                    style: TextStyle(
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(it.sera),
                                  trailing: selected
                                      ? const Icon(Icons.check_circle, color: accent)
                                      : const Icon(Icons.chevron_right),
                                  onTap: () {
                                    setState(() {
                                      final degisti =
                                          (seciliSera != it.sera) || (seciliYer != it.yer);
                                      seciliSera = it.sera;
                                      seciliYer = it.yer;
                                      if (degisti) _resetOnYerChanged();
                                    });
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
      },
    );
  }

  // ----------------------------
  // POST /Sera/OlcumKaydet
  // ----------------------------
  Future<void> _postTekOlcum({
    required DateTime tarih,
    required String sera,
    required String vana,
    required String tip,
    required String deger,
    required int bildirildi,
  }) async {
    final uri = Uri.parse("${App.outsideurl}/Sera/OlcumKaydet");
    final body = {
      "tarih": _yyyyMmDd(tarih),
      "sera": sera,
      "vana": vana,
      "createuser": widget.personelKodu,
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

      setState(() => zorunluTamamlandi = true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Bitki Bilgileri Kaydedildi ✅"),
          backgroundColor: accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      if (mounted) setState(() => loadingZorunlu = false);
    }
  }

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

      setState(() => degerCtrl.clear());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Ölçüm Kaydedildi ✅"),
          backgroundColor: accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
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
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text("Bitki Ölçüm Girişi"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder<_InitData>(
        future: _initFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final init = snap.data!;

          final uzamaLabel =
              init.tipById(idUzama)?.isim ?? "Bitki Uzaması (cm)";
          final kalinlikLabel =
              init.tipById(idKalinlik)?.isim ?? "Tepe Kalınlığı (mm)";

          final tiplerDropdown = init.tipler
              .where((x) => (x.manuelGiris ?? 0) == 1)
              .where((x) => (x.id ?? 0) != idUzama && (x.id ?? 0) != idKalinlik)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            children: [
              _personelChip(),

              const SizedBox(height: 12),

              _sectionCard(
                title: "Seçimler",
                icon: Icons.event_note,
                child: Column(
                  children: [
                    _infoTile(
                      title: "Tarih",
                      value: _yyyyMmDd(secilenTarih),
                      icon: Icons.calendar_month,
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
                    _infoTile(
                      title: "Sera",
                      value: seciliSera ?? "Seç",
                      icon: Icons.warehouse,
                      onTap: () => _seraYerSec(init.yerler),
                    ),
                    const SizedBox(height: 10),
                    _infoTile(
                      title: "Yer",
                      value: seciliYer ?? "Seç",
                      icon: Icons.place,
                      onTap: () => _seraYerSec(init.yerler),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: (!yerSeciliMi || zorunluTamamlandi)
                    ? const SizedBox.shrink(key: ValueKey("zorunlu_hidden"))
                    : _sectionCard(
                        key: const ValueKey("zorunlu_shown"),
                        title: "Zorunlu Ölçümler",
                        icon: Icons.playlist_add_check,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _filledNumberField(
                              controller: uzamaCtrl,
                              label: uzamaLabel,
                              hint: "Değer girin",
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 10),
                            _filledNumberField(
                              controller: kalinlikCtrl,
                              label: kalinlikLabel,
                              hint: "Değer girin",
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: (!zorunluHazir || loadingZorunlu)
                                    ? null
                                    : () => _kaydetZorunlular(init),
                                icon: loadingZorunlu
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: const Text(
                                  "Zorunluları Kaydet",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 12),

              _sectionCard(
                title: "Diğer Ölçümler",
                icon: Icons.tune,
                muted: !zorunluTamamlandi,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<OlcumTipleriModel>(
                      value: seciliTip,
                      items: tiplerDropdown
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t.isim ?? "",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (!zorunluTamamlandi || !yerSeciliMi)
                          ? null
                          : (v) {
                              setState(() {
                                seciliTip = v;
                                degerCtrl.clear();
                              });
                            },
                      decoration: _dec(
                        label: "Ölçüm Tipi",
                        hint: "Seçiniz",
                        icon: Icons.list_alt,
                      ),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 10),

                    _filledNumberField(
                      controller: degerCtrl,
                      label: "Değer",
                      hint: "Değer girin",
                      enabled: zorunluTamamlandi && yerSeciliMi && seciliTip != null,
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (!ekOlcumHazir || loadingEk)
                            ? null
                            : _kaydetEkOlcum,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: loadingEk
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Ölçüm Kaydet",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
  // UI Components
  // ----------------------------
  Widget _personelChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
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
              "Personel: ${widget.personelAdi}",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (seciliSera != null && seciliYer != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withOpacity(.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "${seciliSera!} • ${seciliYer!}",
                style: const TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    Key? key,
    required String title,
    required IconData icon,
    required Widget child,
    bool muted = false,
  }) {
    return Card(
      key: key,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: DefaultTextStyle(
          style: TextStyle(color: muted ? Colors.grey : Colors.black87),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: muted ? Colors.grey : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(16),
     
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),

              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
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
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  Widget _filledNumberField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _dec(label: label, hint: hint, icon: Icons.numbers),
      onChanged: onChanged,
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

class _YerItem {
  final String sera;
  final String yer;
  _YerItem({required this.sera, required this.yer});
}