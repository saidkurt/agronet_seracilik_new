import 'dart:convert';

import 'package:agronet/api/bitki_olcum_tipleri_api.dart';
import 'package:agronet/api/bitki_yerleri_api.dart';
import 'package:agronet/const/string.dart';
import 'package:agronet/models/bitki_sera_yerler.dart';
import 'package:agronet/models/olcum_tipleri.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BitkiOlcumSahaSayfa extends StatefulWidget {
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
  static const Color accent = Color(0xFF1E6F5C);

  static const int idUzama = 35;
  static const int idKalinlik = 36;

  DateTime secilenTarih = DateTime.now();

  final TextEditingController bitkiKoduCtrl = TextEditingController();
  final TextEditingController uzamaCtrl = TextEditingController();
  final TextEditingController kalinlikCtrl = TextEditingController();
  final TextEditingController degerCtrl = TextEditingController();

  String? seciliSera;
  String? seciliBitkiKodu;

  OlcumTipleriModel? seciliTip;

  late Future<_InitData> _initFuture;

  bool bitkiBulundu = false;
  bool bitkiAraniyor = false;
  bool zorunluTamamlandi = false;
  bool loadingZorunlu = false;
  bool loadingEk = false;
  bool loadingOlcumDeger = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _loadAll();
  }

  @override
  void dispose() {
    bitkiKoduCtrl.dispose();
    uzamaCtrl.dispose();
    kalinlikCtrl.dispose();
    degerCtrl.dispose();
    super.dispose();
  }

  Future<_InitData> _loadAll() async {
    final yerler = await const BitkiSeraYerleriApi().getir();
    final tipler = await const OlcumTipleriApi().getir();

    return _InitData(
      yerler: yerler,
      tipler: tipler,
    );
  }

  bool get zorunluHazir =>
      bitkiBulundu &&
      seciliSera != null &&
      seciliBitkiKodu != null &&
      uzamaCtrl.text.trim().isNotEmpty &&
      kalinlikCtrl.text.trim().isNotEmpty;

  bool get ekOlcumHazir =>
      zorunluTamamlandi &&
      bitkiBulundu &&
      seciliSera != null &&
      seciliBitkiKodu != null &&
      seciliTip != null &&
      degerCtrl.text.trim().isNotEmpty;

  void _bitkiDegisti(String value) {
    if (!bitkiBulundu) {
      setState(() {});
      return;
    }

    final girilen = value.trim().toUpperCase();
    final secili = (seciliBitkiKodu ?? '').trim().toUpperCase();

    if (girilen != secili) {
      setState(() {
        _bitkiSeciminiTemizle();
      });
    }
  }

  void _bitkiSeciminiTemizle() {
    bitkiBulundu = false;
    seciliSera = null;
    seciliBitkiKodu = null;
    zorunluTamamlandi = false;
    loadingOlcumDeger = false;

    uzamaCtrl.clear();
    kalinlikCtrl.clear();
    seciliTip = null;
    degerCtrl.clear();
  }
  Future<void> _bitkiyiBul(_InitData init) async {
    if (bitkiAraniyor) return;

    final girilenKod = bitkiKoduCtrl.text.trim();

    if (girilenKod.isEmpty) {
      _mesajGoster(
        'Bitki kodunu girin.',
        hata: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      bitkiAraniyor = true;
      _bitkiSeciminiTemizle();
    });

    String? bulunanSera;
    String? bulunanKod;

    final aranan = girilenKod.toUpperCase();

    for (final seraKaydi in init.yerler) {
      final sera = (seraKaydi.sera ?? '').trim();

      for (final yer in seraKaydi.yerler ?? const <String>[]) {
        final bitkiKodu = yer.trim();

        if (bitkiKodu.toUpperCase() == aranan) {
          bulunanSera = sera;
          bulunanKod = bitkiKodu;
          break;
        }
      }

      if (bulunanKod != null) break;
    }

    if (bulunanKod == null || bulunanSera == null) {
      if (!mounted) return;

      setState(() {
        bitkiAraniyor = false;
      });

      _mesajGoster(
        'Bu bitki kodu bulunamadı.',
        hata: true,
      );
      return;
    }

    final String bitkiKodu = bulunanKod;
    final String sera = bulunanSera;

    try {
  final durum =
      await const BitkiSeraYerleriApi().zorunluOlcumDurumuGetir(
    bitkiKodu: bitkiKodu,
    tarih: secilenTarih,
  );

  if (!mounted) return;

  setState(() {
    bitkiAraniyor = false;
    bitkiBulundu = true;

    seciliBitkiKodu = bitkiKodu;

    seciliSera = (durum.sera ?? '').trim().isNotEmpty
        ? durum.sera!.trim()
        : sera;

    bitkiKoduCtrl.text = bitkiKodu;
    bitkiKoduCtrl.selection = TextSelection.collapsed(
      offset: bitkiKoduCtrl.text.length,
    );

    uzamaCtrl.text = durum.bitkiUzamasi ?? '';
    kalinlikCtrl.text = durum.tepeKalinligi ?? '';

    zorunluTamamlandi = durum.tamamlandi;
  });

  if (durum.tamamlandi) {
    _mesajGoster(
      '$bitkiKodu için zorunlu ölçümler tamamlanmış.',
    );
  } else {
    _mesajGoster(
      '$bitkiKodu bulundu. Zorunlu ölçümleri tamamlayın.',
    );
  }
} catch (e) {
  if (!mounted) return;

  setState(() {
    bitkiAraniyor = false;
  });

  _mesajGoster(
    'Zorunlu ölçüm durumu alınamadı: $e',
    hata: true,
  );
    }
  }

  Future<void> _tarihSec(_InitData init) async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: secilenTarih,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (secilen == null) return;

    final tarihDegisti =
        secilen.year != secilenTarih.year ||
        secilen.month != secilenTarih.month ||
        secilen.day != secilenTarih.day;

    if (!tarihDegisti) return;

    final mevcutBitkiKodu = bitkiKoduCtrl.text.trim();

    setState(() {
      secilenTarih = secilen;
      _bitkiSeciminiTemizle();
    });

    // Bitki kodu yazılıysa yeni seçilen tarihe göre tekrar kontrol et.
    if (mevcutBitkiKodu.isNotEmpty) {
      bitkiKoduCtrl.text = mevcutBitkiKodu;
      await _bitkiyiBul(init);
    }
  }

  Future<void> _postTekOlcum({
    required DateTime tarih,
    required String sera,
    required String bitkiKodu,
    required String tip,
    required String deger,
    required int bildirildi,
  }) async {
    final uri = Uri.parse('${App.insideurl}/Sera/OlcumKaydet');

    final body = <String, dynamic>{
      'tarih': _yyyyMmDd(tarih),
      'sera': sera,

      // Backend ve veritabanında kolon adı "vana".
      // Mobilde bu alana bitki kodu gönderiliyor.
      'vana': bitkiKodu,

      'createuser': widget.personelKodu,
      'tip': tip,
      'deger': deger,
      'bildirildi': bildirildi,
    };

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Kayıt başarısız. Status: ${response.statusCode} '
        'Body: ${response.body}',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (decoded is Map && decoded['success'] == false) {
      throw Exception(
        decoded['message']?.toString() ?? 'Kayıt başarısız.',
      );
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
        bitkiKodu: seciliBitkiKodu!,
        tip: uzamaTip?.isim ?? 'Bitki Uzaması (cm)',
        deger: uzamaCtrl.text.trim(),
        bildirildi: uzamaTip?.bildir ?? 0,
      );

      await _postTekOlcum(
        tarih: secilenTarih,
        sera: seciliSera!,
        bitkiKodu: seciliBitkiKodu!,
        tip: kalinlikTip?.isim ?? 'Tepe Kalınlığı (mm)',
        deger: kalinlikCtrl.text.trim(),
        bildirildi: kalinlikTip?.bildir ?? 0,
      );

      if (!mounted) return;

      setState(() {
        zorunluTamamlandi = true;
      });

      _mesajGoster('Zorunlu ölçümler kaydedildi.');
    } catch (e) {
      if (!mounted) return;
      _mesajGoster(
        'Hata: $e',
        hata: true,
      );
    } finally {
      if (mounted) {
        setState(() => loadingZorunlu = false);
      }
    }
  }

  Future<void> _seciliOlcumDegeriniGetir(
    OlcumTipleriModel tip,
  ) async {
    final String? bitkiKodu = seciliBitkiKodu;
    final String tipAdi = (tip.isim ?? '').trim();

    if (bitkiKodu == null || bitkiKodu.trim().isEmpty) {
      return;
    }

    if (tipAdi.isEmpty) {
      setState(() {
        degerCtrl.clear();
      });
      return;
    }

    setState(() {
      loadingOlcumDeger = true;
      degerCtrl.clear();
    });

    try {
      final sonuc =
          await const BitkiSeraYerleriApi().olcumDegerGetir(
        bitkiKodu: bitkiKodu,
        tip: tipAdi,
        tarih: secilenTarih,
      );

      if (!mounted) return;

      // Kullanıcı sorgu devam ederken başka ölçüm tipine geçtiyse
      // eski sorgunun sonucunu ekrana yazma.
      if (seciliTip != tip) return;

      setState(() {
        degerCtrl.text =
            sonuc.bulundu ? (sonuc.deger ?? '') : '';
      });
    } catch (e) {
      if (!mounted) return;

      if (seciliTip == tip) {
        setState(() {
          degerCtrl.clear();
        });
      }

      _mesajGoster(
        'Ölçüm değeri alınamadı: $e',
        hata: true,
      );
    } finally {
      if (mounted && seciliTip == tip) {
        setState(() {
          loadingOlcumDeger = false;
        });
      }
    }
  }

  Future<void> _kaydetEkOlcum() async {
    if (!ekOlcumHazir || loadingEk) return;

    setState(() => loadingEk = true);

    try {
      await _postTekOlcum(
        tarih: secilenTarih,
        sera: seciliSera!,
        bitkiKodu: seciliBitkiKodu!,
        tip: seciliTip!.isim ?? '',
        deger: degerCtrl.text.trim(),
        bildirildi: seciliTip!.bildir ?? 0,
      );

      if (!mounted) return;

      setState(() {
        degerCtrl.clear();
      });

      _mesajGoster('Ölçüm kaydedildi.');
    } catch (e) {
      if (!mounted) return;
      _mesajGoster(
        'Hata: $e',
        hata: true,
      );
    } finally {
      if (mounted) {
        setState(() => loadingEk = false);
      }
    }
  }

  void _yeniBitki() {
    setState(() {
      bitkiKoduCtrl.clear();
      _bitkiSeciminiTemizle();
    });

    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _mesajGoster(
    String mesaj, {
    bool hata = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: hata ? Colors.red.shade700 : accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Bitki Ölçüm Girişi'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          if (bitkiBulundu)
            IconButton(
              tooltip: 'Yeni bitki',
              onPressed: _yeniBitki,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: FutureBuilder<_InitData>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _hataEkrani(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return _hataEkrani('Veriler alınamadı.');
          }

          final init = snapshot.data!;

          final uzamaLabel =
              init.tipById(idUzama)?.isim ?? 'Bitki Uzaması (cm)';

          final kalinlikLabel =
              init.tipById(idKalinlik)?.isim ?? 'Tepe Kalınlığı (mm)';

          final digerTipler = init.tipler
              .where((tip) => (tip.manuelGiris ?? 0) == 1)
              .where(
                (tip) =>
                    (tip.id ?? 0) != idUzama &&
                    (tip.id ?? 0) != idKalinlik,
              )
              .toList();
              digerTipler.sort((a, b) {
  int sira(String? isim) {
    final m = RegExp(r'^(\d+)').firstMatch(isim ?? '');
    return m == null ? 999 : int.parse(m.group(1)!);
  }

  int tip(String? isim) {
    final text = (isim ?? '').toLowerCase();

    if (text.contains('meyve sayısı')) return 0;
    if (text.contains('meyve çapı')) return 1;

    return 2;
  }

  final s = sira(a.isim).compareTo(sira(b.isim));
  if (s != 0) return s;

  return tip(a.isim).compareTo(tip(b.isim));
});

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              _personelBilgisi(),
              const SizedBox(height: 12),

              _sectionCard(
                title: 'Ölçüm Tarihi',
                icon: Icons.calendar_month,
                child: InkWell(
                  onTap: bitkiAraniyor ? null : () => _tarihSec(init),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event,
                          color: accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _ddMmYyyy(secilenTarih),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _sectionCard(
                title: 'Bitki Kodu',
                icon: Icons.qr_code_scanner,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: bitkiKoduCtrl,
                      enabled: !bitkiAraniyor,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.search,
                      onChanged: _bitkiDegisti,
                      onSubmitted: (_) => _bitkiyiBul(init),
                      decoration: _dec(
                        label: 'Bitki kodunu girin',
                        hint: 'Örn: 110',
                        icon: Icons.eco,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: bitkiAraniyor
                            ? null
                            : () => _bitkiyiBul(init),
                        icon: bitkiAraniyor
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          bitkiAraniyor
                              ? 'Aranıyor...'
                              : 'Bitkiyi Getir',
                          style: const TextStyle(
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
                    if (bitkiBulundu) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: accent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${seciliBitkiKodu!} • ${seciliSera!}',
                                style: const TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: !bitkiBulundu
                    ? const SizedBox.shrink()
                    : Column(
                        key: ValueKey(seciliBitkiKodu),
                        children: [
                          const SizedBox(height: 12),

                          if (!zorunluTamamlandi)
                            _sectionCard(
                              title: 'Zorunlu Ölçümler',
                              icon: Icons.playlist_add_check,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _filledNumberField(
                                    controller: uzamaCtrl,
                                    label: uzamaLabel,
                                    hint: 'Değer girin',
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 10),
                                  _filledNumberField(
                                    controller: kalinlikCtrl,
                                    label: kalinlikLabel,
                                    hint: 'Değer girin',
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          !zorunluHazir || loadingZorunlu
                                              ? null
                                              : () =>
                                                  _kaydetZorunlular(init),
                                      icon: loadingZorunlu
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.save),
                                      label: const Text(
                                        'Zorunluları Kaydet',
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
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          _sectionCard(
                            title: 'Diğer Ölçümler',
                            icon: Icons.tune,
                            muted: !zorunluTamamlandi,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                DropdownButtonFormField<
                                    OlcumTipleriModel>(
                                  value: seciliTip,
                                  isExpanded: true,
                                  items: digerTipler
                                      .map(
                                        (tip) => DropdownMenuItem(
                                          value: tip,
                                          child: Text(
                                            tip.isim ?? '',
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: !zorunluTamamlandi ||
                                          loadingOlcumDeger
                                      ? null
                                      : (tip) async {
                                          setState(() {
                                            seciliTip = tip;
                                            degerCtrl.clear();
                                          });

                                          if (tip != null) {
                                            await _seciliOlcumDegeriniGetir(
                                              tip,
                                            );
                                          }
                                        },
                                  decoration: _dec(
                                    label: 'Ölçüm tipi',
                                    hint: 'Seçiniz',
                                    icon: Icons.list_alt,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (loadingOlcumDeger)
                                  Container(
                                    height: 56,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF6F7F9),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Kayıtlı değer getiriliyor...',
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  _filledNumberField(
                                    controller: degerCtrl,
                                    label: 'Değer',
                                    hint: 'Değer girin',
                                    enabled: zorunluTamamlandi &&
                                        seciliTip != null,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed:
                                        !ekOlcumHazir ||
                                                loadingEk ||
                                                loadingOlcumDeger
                                            ? null
                                            : _kaydetEkOlcum,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: loadingEk
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Ölçüm Kaydet',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
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

  Widget _hataEkrani(String hata) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              hata,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _initFuture = _loadAll();
                });
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _personelBilgisi() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
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
            child: const Icon(
              Icons.badge,
              color: accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Personel: ${widget.personelAdi}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    bool muted = false,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: DefaultTextStyle(
          style: TextStyle(
            color: muted ? Colors.grey : Colors.black87,
          ),
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
                    child: Icon(
                      icon,
                      color: accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color:
                            muted ? Colors.grey : Colors.black87,
                      ),
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
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: accent,
          width: 1.6,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 12,
      ),
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
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: _dec(
        label: label,
        hint: hint,
        icon: Icons.numbers,
      ),
      onChanged: onChanged,
    );
  }

  String _ddMmYyyy(DateTime tarih) {
    String ikiHane(int deger) =>
        deger.toString().padLeft(2, '0');

    return '${ikiHane(tarih.day)}.'
        '${ikiHane(tarih.month)}.'
        '${tarih.year}';
  }

  String _yyyyMmDd(DateTime tarih) {
    String ikiHane(int deger) =>
        deger.toString().padLeft(2, '0');

    return '${tarih.year}-'
        '${ikiHane(tarih.month)}-'
        '${ikiHane(tarih.day)}';
  }
}

class _InitData {
  final List<SeraYerModel> yerler;
  final List<OlcumTipleriModel> tipler;

  _InitData({
    required this.yerler,
    required this.tipler,
  });

  OlcumTipleriModel? tipById(int id) {
    for (final tip in tipler) {
      if ((tip.id ?? 0) == id) {
        return tip;
      }
    }

    return null;
  }
}
