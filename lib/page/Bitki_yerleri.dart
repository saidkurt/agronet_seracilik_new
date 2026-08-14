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
  State<BitkiOlcumSahaSayfa> createState() =>
      _BitkiOlcumSahaSayfaState();
}

class _BitkiOlcumSahaSayfaState
    extends State<BitkiOlcumSahaSayfa> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  static const int idUzama = 35;
  static const int idKalinlik = 36;

  DateTime secilenTarih = DateTime.now();

  final TextEditingController bitkiKoduCtrl =
      TextEditingController();

  final TextEditingController uzamaCtrl =
      TextEditingController();

  final TextEditingController kalinlikCtrl =
      TextEditingController();

  final Map<int, TextEditingController> ekOlcumControllers = {};

  String? seciliSera;
  String? seciliBitkiKodu;

  int? seciliSalkimNo;

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

    for (final controller in ekOlcumControllers.values) {
      controller.dispose();
    }
    ekOlcumControllers.clear();

    super.dispose();
  }

  // ============================================================
  // BAŞLANGIÇ VERİLERİ
  // ============================================================

  Future<_InitData> _loadAll() async {
    final yerler =
        await const BitkiSeraYerleriApi().getir();

    final tipler =
        await const OlcumTipleriApi().getir();

    return _InitData(
      yerler: yerler,
      tipler: tipler,
    );
  }

  // ============================================================
  // DURUMLAR
  // ============================================================

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
      seciliSalkimNo != null;

  // ============================================================
  // BİTKİ KODU DEĞİŞTİ
  // ============================================================

  void _bitkiDegisti(String value) {
    if (!bitkiBulundu) {
      setState(() {});
      return;
    }

    final girilen =
        value.trim().toUpperCase();

    final secili =
        (seciliBitkiKodu ?? '')
            .trim()
            .toUpperCase();

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

    seciliSalkimNo = null;

    for (final controller in ekOlcumControllers.values) {
      controller.clear();
    }
  }

  // ============================================================
  // BİTKİYİ BUL
  // ============================================================

  Future<void> _bitkiyiBul(
    _InitData init,
  ) async {
    if (bitkiAraniyor) return;

    final girilenKod =
        bitkiKoduCtrl.text.trim();

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

    final aranan =
        girilenKod.toUpperCase();

    for (final seraKaydi in init.yerler) {
      final sera =
          (seraKaydi.sera ?? '').trim();

      for (final yer
          in seraKaydi.yerler ??
              const <String>[]) {
        final bitkiKodu =
            yer.trim();

        if (bitkiKodu.toUpperCase() ==
            aranan) {
          bulunanSera = sera;
          bulunanKod = bitkiKodu;

          break;
        }
      }

      if (bulunanKod != null) {
        break;
      }
    }

    if (bulunanKod == null ||
        bulunanSera == null) {
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

    final String bitkiKodu =
        bulunanKod;

    final String sera =
        bulunanSera;

    try {
      final durum =
          await const BitkiSeraYerleriApi()
              .zorunluOlcumDurumuGetir(
        bitkiKodu: bitkiKodu,
        tarih: secilenTarih,
      );

      if (!mounted) return;

      setState(() {
        bitkiAraniyor = false;

        bitkiBulundu = true;

        seciliBitkiKodu =
            bitkiKodu;

        seciliSera =
            (durum.sera ?? '')
                    .trim()
                    .isNotEmpty
                ? durum.sera!.trim()
                : sera;

        bitkiKoduCtrl.text =
            bitkiKodu;

        bitkiKoduCtrl.selection =
            TextSelection.collapsed(
          offset:
              bitkiKoduCtrl.text.length,
        );

        uzamaCtrl.text =
            durum.bitkiUzamasi ?? '';

        kalinlikCtrl.text =
            durum.tepeKalinligi ?? '';

        zorunluTamamlandi =
            durum.tamamlandi;
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

  // ============================================================
  // TARİH
  // ============================================================

  Future<void> _tarihSec(
    _InitData init,
  ) async {
    final secilen =
        await showDatePicker(
      context: context,
      initialDate: secilenTarih,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (secilen == null) return;

    final tarihDegisti =
        secilen.year !=
                secilenTarih.year ||
            secilen.month !=
                secilenTarih.month ||
            secilen.day !=
                secilenTarih.day;

    if (!tarihDegisti) return;

    final mevcutBitkiKodu =
        bitkiKoduCtrl.text.trim();

    setState(() {
      secilenTarih = secilen;

      _bitkiSeciminiTemizle();
    });

    if (mevcutBitkiKodu.isNotEmpty) {
      bitkiKoduCtrl.text =
          mevcutBitkiKodu;

      await _bitkiyiBul(init);
    }
  }

  // ============================================================
  // POST ÖLÇÜM
  // ============================================================

  Future<void> _postTekOlcum({
    required DateTime tarih,
    required String sera,
    required String bitkiKodu,
    required String tip,
    required String deger,
    required int bildirildi,
  }) async {
    final uri = Uri.parse(
      '${App.outsideurl}/Sera/OlcumKaydet',
    );

    final body =
        <String, dynamic>{
      'tarih': _yyyyMmDd(tarih),
      'sera': sera,

      // Backend ve veritabanında kolon adı vana.
      // Mobilde bitki kodunu gönderiyoruz.
      'vana': bitkiKodu,

      'createuser':
          widget.personelKodu,

      'tip': tip,
      'deger': deger,
      'bildirildi': bildirildi,
    };

    final response =
        await http.post(
      uri,
      headers: const {
        'Content-Type':
            'application/json',
        'Accept':
            'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Kayıt başarısız. '
        'Status: ${response.statusCode} '
        'Body: ${response.body}',
      );
    }

    dynamic decoded;

    try {
      decoded =
          jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (decoded is Map &&
        decoded['success'] == false) {
      throw Exception(
        decoded['message']?.toString() ??
            'Kayıt başarısız.',
      );
    }
  }

  // ============================================================
  // ZORUNLU ÖLÇÜMLER
  // ============================================================

  Future<void> _kaydetZorunlular(
    _InitData init,
  ) async {
    if (!zorunluHazir ||
        loadingZorunlu) {
      return;
    }

    setState(() {
      loadingZorunlu = true;
    });

    try {
      final uzamaTip =
          init.tipById(idUzama);

      final kalinlikTip =
          init.tipById(idKalinlik);

      await _postTekOlcum(
        tarih: secilenTarih,
        sera: seciliSera!,
        bitkiKodu:
            seciliBitkiKodu!,
        tip: uzamaTip?.isim ??
            'Bitki Uzaması (cm)',
        deger:
            uzamaCtrl.text.trim(),
        bildirildi:
            uzamaTip?.bildir ?? 0,
      );

      await _postTekOlcum(
        tarih: secilenTarih,
        sera: seciliSera!,
        bitkiKodu:
            seciliBitkiKodu!,
        tip: kalinlikTip?.isim ??
            'Tepe Kalınlığı (mm)',
        deger:
            kalinlikCtrl.text.trim(),
        bildirildi:
            kalinlikTip?.bildir ?? 0,
      );

      if (!mounted) return;

      setState(() {
        zorunluTamamlandi =
            true;
      });

      _mesajGoster(
        'Zorunlu ölçümler kaydedildi.',
      );
    } catch (e) {
      if (!mounted) return;

      _mesajGoster(
        'Hata: $e',
        hata: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingZorunlu = false;
        });
      }
    }
  }

  // ============================================================
  // SALKIM BAZLI DİĞER ÖLÇÜMLER
  // ============================================================

  int _tipKey(OlcumTipleriModel tip) {
    final id = tip.id ?? 0;
    if (id != 0) return id;
    return (tip.isim ?? '').hashCode;
  }

  TextEditingController _controllerForTip(
    OlcumTipleriModel tip,
  ) {
    final key = _tipKey(tip);
    return ekOlcumControllers.putIfAbsent(
      key,
      () => TextEditingController(),
    );
  }

  String _salkimAlanAdi(String? tamAd, int salkimNo) {
    var text = (tamAd ?? '').trim();

    text = text.replaceFirst(
      RegExp(
        r'^\s*\d+\s*[.\-]?\s*(?:salk[ıi]m)?\s*[.\-:]?\s*',
        caseSensitive: false,
      ),
      '',
    );

    if (text.isEmpty) {
      return '$salkimNo. Salkım Ölçümü';
    }

    return text;
  }

  Future<void> _salkimSec(
    int salkimNo,
    List<OlcumTipleriModel> tipler,
  ) async {
    if (!zorunluTamamlandi || loadingOlcumDeger) return;

    final bitkiKodu = seciliBitkiKodu;
    if (bitkiKodu == null || bitkiKodu.trim().isEmpty) return;

    setState(() {
      seciliSalkimNo = salkimNo;
      loadingOlcumDeger = true;

      for (final tip in tipler) {
        _controllerForTip(tip).clear();
      }
    });

    try {
      final sonuclar = await Future.wait(
        tipler.map((tip) async {
          final tipAdi = (tip.isim ?? '').trim();
          if (tipAdi.isEmpty) {
            return MapEntry<int, String>(_tipKey(tip), '');
          }

          final sonuc = await const BitkiSeraYerleriApi()
              .olcumDegerGetir(
            bitkiKodu: bitkiKodu,
            tip: tipAdi,
            tarih: secilenTarih,
          );

          return MapEntry<int, String>(
            _tipKey(tip),
            sonuc.bulundu ? (sonuc.deger ?? '') : '',
          );
        }),
      );

      if (!mounted || seciliSalkimNo != salkimNo) return;

      setState(() {
        for (final sonuc in sonuclar) {
          ekOlcumControllers[sonuc.key]?.text = sonuc.value;
        }
      });
    } catch (e) {
      if (!mounted) return;

      _mesajGoster(
        '$salkimNo. salkım değerleri alınamadı: $e',
        hata: true,
      );
    } finally {
      if (mounted && seciliSalkimNo == salkimNo) {
        setState(() {
          loadingOlcumDeger = false;
        });
      }
    }
  }

  Future<void> _kaydetSalkim({
    required int salkimNo,
    required List<OlcumTipleriModel> tipler,
    required bool sonrakiSalkimaGec,
    required List<int> salkimSirasi,
    required Map<int, List<OlcumTipleriModel>> salkimGruplari,
  }) async {
    if (!ekOlcumHazir || loadingEk || loadingOlcumDeger) return;

    final doluTipler = tipler.where((tip) {
      return _controllerForTip(tip).text.trim().isNotEmpty;
    }).toList();

    if (doluTipler.isEmpty) {
      _mesajGoster(
        'En az bir ölçüm değeri girin.',
        hata: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      loadingEk = true;
    });

    try {
      for (final tip in doluTipler) {
        await _postTekOlcum(
          tarih: secilenTarih,
          sera: seciliSera!,
          bitkiKodu: seciliBitkiKodu!,
          tip: tip.isim ?? '',
          deger: _controllerForTip(tip).text.trim(),
          bildirildi: tip.bildir ?? 0,
        );
      }

      if (!mounted) return;

      _mesajGoster(
        '$salkimNo. salkım ölçümleri kaydedildi.',
      );

      if (sonrakiSalkimaGec) {
        final index = salkimSirasi.indexOf(salkimNo);
        if (index >= 0 && index < salkimSirasi.length - 1) {
          final sonrakiNo = salkimSirasi[index + 1];
          final sonrakiTipler =
              salkimGruplari[sonrakiNo] ?? const <OlcumTipleriModel>[];

          if (sonrakiTipler.isNotEmpty) {
            await _salkimSec(sonrakiNo, sonrakiTipler);
          }
        }
      }
    } catch (e) {
      if (!mounted) return;

      _mesajGoster(
        'Hata: $e',
        hata: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingEk = false;
        });
      }
    }
  }

  // ============================================================
  // YENİ BİTKİ
  // ============================================================

  void _yeniBitki() {
    setState(() {
      bitkiKoduCtrl.clear();

      _bitkiSeciminiTemizle();
    });

    FocusScope.of(context)
        .unfocus();
  }

  // ============================================================
  // MESAJ
  // ============================================================

  void _mesajGoster(
    String mesaj, {
    bool hata = false,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          mesaj,
          style: const TextStyle(
            fontSize: 11,
          ),
        ),
        backgroundColor:
            hata
                ? Colors.red.shade700
                : accent,
        behavior:
            SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final scaler =
        MediaQuery.textScalerOf(context)
            .clamp(
      maxScaleFactor: 1.08,
    );

    return MediaQuery(
      data:
          MediaQuery.of(context).copyWith(
        textScaler: scaler,
      ),
      child: Scaffold(
        backgroundColor: bg,

        appBar: AppBar(
          toolbarHeight: 50,
          title: const Text(
            'Bitki Ölçüm Girişi',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor:
              Colors.white,
          surfaceTintColor:
              Colors.white,
          foregroundColor:
              Colors.black87,
          actions: [
            if (bitkiBulundu)
              IconButton(
                tooltip: 'Yeni bitki',
                onPressed: _yeniBitki,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 21,
                ),
              ),
          ],
        ),

        body:
            FutureBuilder<_InitData>(
          future: _initFuture,
          builder:
              (context, snapshot) {
            if (snapshot
                    .connectionState ==
                ConnectionState
                    .waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return _hataEkrani(
                snapshot.error
                    .toString(),
              );
            }

            if (!snapshot.hasData) {
              return _hataEkrani(
                'Veriler alınamadı.',
              );
            }

            final init =
                snapshot.data!;

            final uzamaLabel =
                init.tipById(idUzama)
                        ?.isim ??
                    'Bitki Uzaması (cm)';

            final kalinlikLabel =
                init.tipById(
                            idKalinlik)
                        ?.isim ??
                    'Tepe Kalınlığı (mm)';

            final digerTipler =
                init.tipler
                    .where(
                      (tip) =>
                          (tip.manuelGiris ??
                              0) ==
                          1,
                    )
                    .where(
                      (tip) =>
                          (tip.id ?? 0) !=
                              idUzama &&
                          (tip.id ?? 0) !=
                              idKalinlik,
                    )
                    .toList();

            digerTipler.sort(
              (a, b) {
                int sira(
                  String? isim,
                ) {
                  final m = RegExp(
                    r'^(\d+)',
                  ).firstMatch(
                    isim ?? '',
                  );

                  return m == null
                      ? 999
                      : int.parse(
                          m.group(1)!,
                        );
                }

                int tip(
                  String? isim,
                ) {
                  final text =
                      (isim ?? '')
                          .toLowerCase();

                  if (text.contains(
                    'meyve sayısı',
                  )) {
                    return 0;
                  }

                  if (text.contains(
                    'meyve çapı',
                  )) {
                    return 1;
                  }

                  return 2;
                }

                final s =
                    sira(a.isim)
                        .compareTo(
                  sira(b.isim),
                );

                if (s != 0) {
                  return s;
                }

                return tip(a.isim)
                    .compareTo(
                  tip(b.isim),
                );
              },
            );

            final Map<int, List<OlcumTipleriModel>>
                salkimGruplari = {};

            for (final tip in digerTipler) {
              final isim = (tip.isim ?? '').trim();
              final eslesme = RegExp(r'^\s*(\d+)').firstMatch(isim);

              if (eslesme == null) continue;

              final salkimNo = int.tryParse(eslesme.group(1) ?? '');
              if (salkimNo == null) continue;

              salkimGruplari
                  .putIfAbsent(
                    salkimNo,
                    () => <OlcumTipleriModel>[],
                  )
                  .add(tip);
            }

            final salkimSirasi = salkimGruplari.keys.toList()..sort();

            // Bitkinin zorunlu ölçümleri daha önce tamamlandıysa,
            // ilk salkımı otomatik seç ve o salkıma ait kayıtlı
            // değerleri ekrana getir.
            if (zorunluTamamlandi &&
                seciliSalkimNo == null &&
                salkimSirasi.isNotEmpty &&
                !loadingOlcumDeger &&
                !loadingEk) {
              final ilkSalkimNo = salkimSirasi.first;
              final ilkSalkimTipleri =
                  salkimGruplari[ilkSalkimNo] ??
                      const <OlcumTipleriModel>[];

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted ||
                    seciliSalkimNo != null ||
                    !zorunluTamamlandi) {
                  return;
                }

                _salkimSec(
                  ilkSalkimNo,
                  ilkSalkimTipleri,
                );
              });
            }

            return ListView(
              physics:
                  const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                10,
                9,
                10,
                18,
              ),
              children: [
                _personelBilgisi(),

                const SizedBox(
                  height: 7,
                ),

                // ================================================
                // TARİH
                // ================================================

                _sectionCard(
                  title: 'Ölçüm Tarihi',
                  icon:
                      Icons.calendar_month_rounded,
                  child: InkWell(
                    onTap: bitkiAraniyor
                        ? null
                        : () =>
                            _tarihSec(init),
                    borderRadius:
                        BorderRadius.circular(
                            9),
                    child: Container(
                      height: 45,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFF7F7F9,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(9),
                        border:
                            Border.all(
                          color: Colors
                              .black
                              .withOpacity(
                                  .055),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 29,
                            height: 29,
                            decoration:
                                BoxDecoration(
                              color: accent
                                  .withOpacity(
                                      .09),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          8),
                            ),
                            child:
                                const Icon(
                              Icons
                                  .event_rounded,
                              color:
                                  accent,
                              size: 17,
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Expanded(
                            child: Text(
                              _ddMmYyyy(
                                secilenTarih,
                              ),
                              style:
                                  const TextStyle(
                                fontSize:
                                    12.5,
                                fontWeight:
                                    FontWeight
                                        .w900,
                              ),
                            ),
                          ),

                          const Icon(
                            Icons
                                .chevron_right_rounded,
                            size: 19,
                            color:
                                Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                // ================================================
                // BİTKİ KODU
                // ================================================

                _sectionCard(
                  title: 'Bitki Kodu',
                  icon:
                      Icons.qr_code_scanner_rounded,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child:
                                TextField(
                              controller:
                                  bitkiKoduCtrl,
                              enabled:
                                  !bitkiAraniyor,
                              textCapitalization:
                                  TextCapitalization
                                      .characters,
                              textInputAction:
                                  TextInputAction
                                      .search,
                              onChanged:
                                  _bitkiDegisti,
                              onSubmitted:
                                  (_) =>
                                      _bitkiyiBul(
                                init,
                              ),
                              style:
                                  const TextStyle(
                                fontSize:
                                    13,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                              decoration:
                                  _dec(
                                label:
                                    'Bitki kodu',
                                hint:
                                    'Örn: 110',
                                icon:
                                    Icons.eco,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 7,
                          ),

                          SizedBox(
                            width: 92,
                            height: 46,
                            child:
                                FilledButton(
                              onPressed:
                                  bitkiAraniyor
                                      ? null
                                      : () =>
                                          _bitkiyiBul(
                                            init,
                                          ),
                              style:
                                  FilledButton
                                      .styleFrom(
                                backgroundColor:
                                    accent,
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      7,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          9),
                                ),
                              ),
                              child: bitkiAraniyor
                                  ? const SizedBox(
                                      width:
                                          16,
                                      height:
                                          16,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_rounded,
                                          size: 17,
                                        ),
                                        SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                          'GETİR',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),

                      if (bitkiBulundu) ...[
                        const SizedBox(
                          height: 7,
                        ),

                        Container(
                          height: 39,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 9,
                          ),
                          decoration:
                              BoxDecoration(
                            color: accent
                                .withOpacity(
                                    .07),
                            borderRadius:
                                BorderRadius
                                    .circular(8),
                            border:
                                Border.all(
                              color: accent
                                  .withOpacity(
                                      .13),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons
                                    .check_circle_rounded,
                                color:
                                    accent,
                                size: 17,
                              ),

                              const SizedBox(
                                width: 6,
                              ),

                              Expanded(
                                child: Text(
                                  '${seciliBitkiKodu!}  •  ${seciliSera!}',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(
                                    color:
                                        accent,
                                    fontSize:
                                        11,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                              ),

                              const Text(
                                'Bulundu',
                                style:
                                    TextStyle(
                                  fontSize:
                                      9,
                                  color:
                                      accent,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ================================================
                // BİTKİ BULUNDUKTAN SONRA
                // ================================================

                AnimatedSwitcher(
                  duration:
                      const Duration(
                    milliseconds: 200,
                  ),
                  child: !bitkiBulundu
                      ? const SizedBox
                          .shrink()
                      : Column(
                          key: ValueKey(
                            seciliBitkiKodu,
                          ),
                          children: [
                            const SizedBox(
                              height: 7,
                            ),

                            // ====================================
                            // ZORUNLU ÖLÇÜMLER
                            // ====================================

                            if (!zorunluTamamlandi)
                              _sectionCard(
                                title:
                                    'Zorunlu Ölçümler',
                                icon: Icons
                                    .playlist_add_check_rounded,
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child:
                                              _filledNumberField(
                                            controller: uzamaCtrl,
                                            label: uzamaLabel,
                                            hint: 'Değer',
                                            onChanged: (_) =>
                                                setState(() {}),
                                          ),
                                        ),

                                        const SizedBox(
                                          width: 7,
                                        ),

                                        Expanded(
                                          child:
                                              _filledNumberField(
                                            controller: kalinlikCtrl,
                                            label: kalinlikLabel,
                                            hint: 'Değer',
                                            onChanged: (_) =>
                                                setState(() {}),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                      height: 9,
                                    ),

                                    SizedBox(
                                      height: 44,
                                      child:
                                          FilledButton.icon(
                                        onPressed: !zorunluHazir ||
                                                loadingZorunlu
                                            ? null
                                            : () => _kaydetZorunlular(
                                                  init,
                                                ),
                                        icon: loadingZorunlu
                                            ? const SizedBox(
                                                width: 15,
                                                height: 15,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.save_rounded,
                                                size: 17,
                                              ),
                                        label:
                                            const Text(
                                          'ZORUNLU ÖLÇÜMLERİ KAYDET',
                                          style:
                                              TextStyle(
                                            fontSize:
                                                10.5,
                                            fontWeight:
                                                FontWeight.w900,
                                          ),
                                        ),
                                        style:
                                            FilledButton.styleFrom(
                                          backgroundColor:
                                              accent,
                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(9),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (!zorunluTamamlandi)
                              const SizedBox(
                                height: 7,
                              ),

                            // ====================================
                            // DİĞER ÖLÇÜMLER - SALKIM BAZLI
                            // ====================================

                            _sectionCard(
                              title: 'Diğer Ölçümler',
                              icon: Icons.tune_rounded,
                              muted: !zorunluTamamlandi,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  if (salkimSirasi.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F7F9),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: const Text(
                                        'Salkım bazlı ölçüm tipi bulunamadı.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black45,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  else ...[
                                    const Text(
                                      'Salkım seçin',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Colors.black45,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    const SizedBox(height: 7),

                                    SizedBox(
                                      height: 39,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: salkimSirasi.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 6),
                                        itemBuilder: (context, index) {
                                          final salkimNo = salkimSirasi[index];
                                          final secili =
                                              seciliSalkimNo == salkimNo;

                                          return ChoiceChip(
                                            selected: secili,
                                            onSelected: !zorunluTamamlandi ||
                                                    loadingOlcumDeger ||
                                                    loadingEk
                                                ? null
                                                : (_) => _salkimSec(
                                                      salkimNo,
                                                      salkimGruplari[salkimNo] ??
                                                          const <OlcumTipleriModel>[],
                                                    ),
                                            label: Text(
                                              '$salkimNo. Salkım',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w900,
                                                color: secili
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            selectedColor: accent,
                                            backgroundColor:
                                                const Color(0xFFF2F3F5),
                                            side: BorderSide(
                                              color: secili
                                                  ? accent
                                                  : Colors.black.withOpacity(.06),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                            ),
                                            showCheckmark: false,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    if (seciliSalkimNo == null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF7F7F9),
                                          borderRadius: BorderRadius.circular(9),
                                          border: Border.all(
                                            color: Colors.black.withOpacity(.05),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.touch_app_rounded,
                                              size: 17,
                                              color: Colors.black38,
                                            ),
                                            SizedBox(width: 7),
                                            Text(
                                              'Değer girmek için salkım seçin.',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: Colors.black45,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (loadingOlcumDeger)
                                      Container(
                                        height: 72,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF7F7F9),
                                          borderRadius: BorderRadius.circular(9),
                                          border: Border.all(
                                            color: Colors.black.withOpacity(.05),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Salkım değerleri getiriliyor...',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withOpacity(.07),
                                          borderRadius: BorderRadius.circular(9),
                                          border: Border.all(
                                            color: accent.withOpacity(.12),
                                          ),
                                        ),
                                        child: Text(
                                          '$seciliSalkimNo. SALKIM',
                                          style: const TextStyle(
                                            color: accent,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      ...(
                                        salkimGruplari[seciliSalkimNo] ??
                                            const <OlcumTipleriModel>[]
                                      ).map((tip) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: _filledNumberField(
                                            controller: _controllerForTip(tip),
                                            label: _salkimAlanAdi(
                                              tip.isim,
                                              seciliSalkimNo!,
                                            ),
                                            hint: 'Değer girin',
                                            enabled: zorunluTamamlandi &&
                                                !loadingEk,
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        );
                                      }),

                                      const SizedBox(height: 1),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 44,
                                              child: OutlinedButton.icon(
                                                onPressed: loadingEk
                                                    ? null
                                                    : () => _kaydetSalkim(
                                                          salkimNo:
                                                              seciliSalkimNo!,
                                                          tipler: salkimGruplari[
                                                                  seciliSalkimNo] ??
                                                              const <OlcumTipleriModel>[],
                                                          sonrakiSalkimaGec:
                                                              false,
                                                          salkimSirasi:
                                                              salkimSirasi,
                                                          salkimGruplari:
                                                              salkimGruplari,
                                                        ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: accent,
                                                  side: const BorderSide(
                                                    color: accent,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(9),
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.save_outlined,
                                                  size: 17,
                                                ),
                                                label: const Text(
                                                  'KAYDET',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 7),

                                          Expanded(
                                            flex: 2,
                                            child: SizedBox(
                                              height: 44,
                                              child: FilledButton.icon(
                                                onPressed: loadingEk
                                                    ? null
                                                    : () => _kaydetSalkim(
                                                          salkimNo:
                                                              seciliSalkimNo!,
                                                          tipler: salkimGruplari[
                                                                  seciliSalkimNo] ??
                                                              const <OlcumTipleriModel>[],
                                                          sonrakiSalkimaGec:
                                                              true,
                                                          salkimSirasi:
                                                              salkimSirasi,
                                                          salkimGruplari:
                                                              salkimGruplari,
                                                        ),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: accent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(9),
                                                  ),
                                                ),
                                                icon: loadingEk
                                                    ? const SizedBox(
                                                        width: 15,
                                                        height: 15,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons
                                                            .arrow_forward_rounded,
                                                        size: 17,
                                                      ),
                                                label: Text(
                                                  loadingEk
                                                      ? 'KAYDEDİLİYOR...'
                                                      : 'KAYDET + SONRAKİ',
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
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
      ),
    );
  }

  // ============================================================
  // HATA
  // ============================================================

  Widget _hataEkrani(
    String hata,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.red,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              hata,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 11,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            SizedBox(
              height: 38,
              child:
                  FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _initFuture =
                        _loadAll();
                  });
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 17,
                ),
                label:
                    const Text(
                  'Tekrar Dene',
                  style:
                      TextStyle(
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PERSONEL
  // ============================================================

  Widget _personelBilgisi() {
    return Container(
      height: 47,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color:
              Colors.black.withOpacity(.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color:
                  accent.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: accent,
              size: 18,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          const Text(
            'Personel',
            style: TextStyle(
              fontSize: 9.5,
              color:
                  Colors.black45,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          Expanded(
            child: Text(
              widget.personelAdi,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    bool muted = false,
  }) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        10,
        9,
        10,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color:
              Colors.black.withOpacity(.05),
        ),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: muted
              ? Colors.grey
              : Colors.black87,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 27,
                  height: 27,
                  decoration:
                      BoxDecoration(
                    color: muted
                        ? Colors.grey
                            .withOpacity(.08)
                        : accent
                            .withOpacity(.09),
                    borderRadius:
                        BorderRadius.circular(
                            7),
                  ),
                  child: Icon(
                    icon,
                    color: muted
                        ? Colors.grey
                        : accent,
                    size: 16,
                  ),
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child: Text(
                    title,
                    style:
                        TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          FontWeight.w900,
                      color: muted
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
                ),

                if (muted)
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color:
                        Colors.black26,
                  ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            child,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _dec({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      labelStyle:
          const TextStyle(
        fontSize: 10.5,
        fontWeight:
            FontWeight.w700,
      ),

      hintStyle:
          const TextStyle(
        fontSize: 11,
        color:
            Colors.black38,
      ),

      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              size: 18,
              color: accent,
            ),

      filled: true,
      fillColor:
          const Color(0xFFF7F7F9),

      isDense: true,

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),
        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),
        borderSide: BorderSide(
          color: Colors.black
              .withOpacity(.055),
        ),
      ),

      focusedBorder:
          const OutlineInputBorder(
        borderRadius:
            BorderRadius.all(
          Radius.circular(9),
        ),
        borderSide:
            BorderSide(
          color: accent,
          width: 1.3,
        ),
      ),

      disabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),
        borderSide: BorderSide(
          color: Colors.black
              .withOpacity(.035),
        ),
      ),

      contentPadding:
          const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 10,
      ),
    );
  }

  // ============================================================
  // SAYISAL GİRİŞ
  // ============================================================

  Widget _filledNumberField({
    required TextEditingController
        controller,
    required String label,
    String? hint,
    bool enabled = true,
    ValueChanged<String>?
        onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,

      keyboardType:
          const TextInputType
              .numberWithOptions(
        decimal: true,
      ),

      style:
          const TextStyle(
        fontSize: 13,
        fontWeight:
            FontWeight.w700,
      ),

      decoration: _dec(
        label: label,
        hint: hint,
        icon:
            Icons.numbers_rounded,
      ),

      onChanged: onChanged,
    );
  }

  // ============================================================
  // TARİH FORMAT
  // ============================================================

  String _ddMmYyyy(
    DateTime tarih,
  ) {
    String ikiHane(int deger) =>
        deger
            .toString()
            .padLeft(2, '0');

    return '${ikiHane(tarih.day)}.'
        '${ikiHane(tarih.month)}.'
        '${tarih.year}';
  }

  String _yyyyMmDd(
    DateTime tarih,
  ) {
    String ikiHane(int deger) =>
        deger
            .toString()
            .padLeft(2, '0');

    return '${tarih.year}-'
        '${ikiHane(tarih.month)}-'
        '${ikiHane(tarih.day)}';
  }
}

// ============================================================================
// INIT DATA
// ============================================================================

class _InitData {
  final List<SeraYerModel> yerler;
  final List<OlcumTipleriModel> tipler;

  _InitData({
    required this.yerler,
    required this.tipler,
  });

  OlcumTipleriModel? tipById(
    int id,
  ) {
    for (final tip in tipler) {
      if ((tip.id ?? 0) == id) {
        return tip;
      }
    }

    return null;
  }
}