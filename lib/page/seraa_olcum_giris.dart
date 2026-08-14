import 'package:agronet/api/sera_olcum_api.dart';
import 'package:agronet/models/sera_olcum_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SeraOlcumGirisSayfa extends StatefulWidget {
  final String personelKodu;
  final String personelAdi;

  const SeraOlcumGirisSayfa({
    super.key,
    required this.personelKodu,
    required this.personelAdi,
  });

  @override
  State<SeraOlcumGirisSayfa> createState() =>
      _SeraOlcumGirisSayfaState();
}

class _SeraOlcumGirisSayfaState
    extends State<SeraOlcumGirisSayfa> {
  // ============================================================
  // AGRONET RENKLER
  // ============================================================

  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  final SeraOlcumApi _api = SeraOlcumApi();

  // ============================================================
  // DURUMLAR
  // ============================================================

  DateTime _tarih = DateTime.now();

  bool _loading = true;
  bool _saving = false;

  String? _hata;

  SeraOlcumEkranModel? _data;

  String? _seciliSera;
  String? _seciliVana;

  final Map<String, _OlcumEditState> _editStates = {};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _ekraniYukle();
  }

  @override
  void dispose() {
    for (final item in _editStates.values) {
      item.controller.dispose();
      item.focusNode.dispose();
    }

    _api.dispose();

    super.dispose();
  }

  // ============================================================
  // UNIQUE KEY
  // ============================================================

  String _key(
    String sera,
    String vana,
    String tip,
  ) {
    return '$sera|||$vana|||$tip';
  }

  // ============================================================
  // EKRANI YÜKLE
  // ============================================================

  Future<void> _ekraniYukle() async {
    if (_saving) return;

    setState(() {
      _loading = true;
      _hata = null;
    });

    try {
      final sonuc = await _api.ekranGetir(
        tarih: _tarih,
      );

      // Eski controller / focusları temizle
      for (final item in _editStates.values) {
        item.controller.dispose();
        item.focusNode.dispose();
      }

      _editStates.clear();

      // Backend'den gelen bütün sera/vana/tipleri state'e al.
      for (final yer in sonuc.yerler) {
        for (final olcum in yer.olcumler) {
          final key = _key(
            yer.sera,
            yer.vana,
            olcum.tip,
          );

          _editStates[key] = _OlcumEditState(
            sera: yer.sera,
            vana: yer.vana,
            tip: olcum.tip,
            deger: olcum.deger,
          );
        }
      }

      final seralar = sonuc.yerler
          .map((e) => e.sera.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      seralar.sort(_naturalCompare);

      String? sera;

      if (_seciliSera != null &&
          seralar.contains(_seciliSera)) {
        sera = _seciliSera;
      } else if (seralar.isNotEmpty) {
        sera = seralar.first;
      }

      String? vana;

      if (sera != null) {
        final vanalar = sonuc.yerler
            .where((e) => e.sera == sera)
            .map((e) => e.vana.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

        vanalar.sort(_naturalCompare);

        if (_seciliVana != null &&
            vanalar.contains(_seciliVana)) {
          vana = _seciliVana;
        } else if (vanalar.isNotEmpty) {
          vana = vanalar.first;
        }
      }

      if (!mounted) return;

      setState(() {
        _data = sonuc;
        _seciliSera = sera;
        _seciliVana = vana;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _hata = e.toString();
      });
    }
  }

  // ============================================================
  // TARİH SEÇ
  // ============================================================

  Future<void> _tarihSec() async {
    if (_loading || _saving) return;

    FocusScope.of(context).unfocus();

    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (secilen == null) return;

    final degisti =
        secilen.year != _tarih.year ||
        secilen.month != _tarih.month ||
        secilen.day != _tarih.day;

    if (!degisti) return;

    setState(() {
      _tarih = secilen;
      _seciliSera = null;
      _seciliVana = null;
    });

    await _ekraniYukle();
  }

  // ============================================================
  // SERALAR
  // ============================================================

  List<String> get _seralar {
    final data = _data;

    if (data == null) return [];

    final liste = data.yerler
        .map((e) => e.sera.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    liste.sort(_naturalCompare);

    return liste;
  }

  // ============================================================
  // VANALAR
  // ============================================================

  List<String> get _vanalar {
    final data = _data;

    if (data == null ||
        _seciliSera == null) {
      return [];
    }

    final liste = data.yerler
        .where(
          (e) => e.sera == _seciliSera,
        )
        .map((e) => e.vana.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    liste.sort(_naturalCompare);

    return liste;
  }

  // ============================================================
  // SEÇİLİ VANANIN ÖLÇÜMLERİ
  // ============================================================

List<_OlcumEditState> get _seciliOlcumler {
  if (_seciliSera == null ||
      _seciliVana == null) {
    return [];
  }

  final liste = _editStates.values
      .where(
        (e) =>
            e.sera == _seciliSera &&
            e.vana == _seciliVana,
      )
      .toList();

  liste.sort((a, b) {
    final sa = _olcumSira(a.tip);
    final sb = _olcumSira(b.tip);

    if (sa != sb) {
      return sa.compareTo(sb);
    }

    return a.tip.compareTo(b.tip);
  });

  return liste;
}
int _olcumSira(String tip) {
  final t = tip
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .trim();

  if (t == 'drip ph') return 1;
  if (t == 'drip ec') return 2;

  if (t == 'drenaj ph') return 3;
  if (t == 'drenaj ec') return 4;

  if (t.contains('otomasyon') &&
      t.contains('drenaj') &&
      t.contains('ph')) {
    return 5;
  }

  if (t.contains('otomasyon') &&
      t.contains('drenaj') &&
      t.contains('ec')) {
    return 6;
  }

  if (t == 'sulama cc') return 7;

  if (t.contains('otomasyon') &&
      t.contains('sulama') &&
      t.contains('cc')) {
    return 8;
  }

  if (t.contains('otomasyon') &&
      t.contains('sulama') &&
      (t.contains('sn') ||
          t.contains('sure'))) {
    return 9;
  }

  if (t.contains('otomasyon') &&
      t.contains('toplam') &&
      t.contains('sulama')) {
    return 10;
  }

  if (t.contains('slap') &&
      t.contains('agirlik') &&
      t.contains('sabah')) {
    return 11;
  }

  if (t.contains('otomasyon') &&
      t.contains('drenaj') &&
      t.contains('cc')) {
    return 12;
  }

  if (t == 'drenaj %' ||
      (t.contains('drenaj') &&
          t.contains('%'))) {
    return 13;
  }

  if (t.contains('hat basinci')) {
    return 14;
  }

  if (t == 'jull' ||
      t.contains('jull')) {
    return 15;
  }

  if (t.contains('slap') &&
      t.contains('agirlik') &&
      t.contains('gece')) {
    return 16;
  }

  return 999;
}

  // ============================================================
  // SERA SEÇ
  // ============================================================

  void _seraSec(String sera) {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    if (_seciliSera == sera) {
      return;
    }

    final data = _data;

    if (data == null) return;

    final vanalar = data.yerler
        .where((e) => e.sera == sera)
        .map((e) => e.vana.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    vanalar.sort(_naturalCompare);

    setState(() {
      _seciliSera = sera;

      _seciliVana =
          vanalar.isEmpty ? null : vanalar.first;
    });
  }

  // ============================================================
  // VANA SEÇ
  // ============================================================

  void _vanaSec(String vana) {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    if (_seciliVana == vana) {
      return;
    }

    setState(() {
      _seciliVana = vana;
    });
  }

  // ============================================================
  // SONRAKİ VANA
  // ============================================================

  void _sonrakiVana() {
    final vanalar = _vanalar;

    if (_seciliVana == null ||
        vanalar.isEmpty) {
      return;
    }

    final index =
        vanalar.indexOf(_seciliVana!);

    if (index < 0) return;

    // Aynı serada sonraki vana
    if (index < vanalar.length - 1) {
      _vanaSec(
        vanalar[index + 1],
      );

      return;
    }

    // Seranın son vanasıysa sonraki sera
    final seralar = _seralar;

    if (_seciliSera == null) return;

    final seraIndex =
        seralar.indexOf(_seciliSera!);

    if (seraIndex >= 0 &&
        seraIndex < seralar.length - 1) {
      _seraSec(
        seralar[seraIndex + 1],
      );
    }
  }

  // ============================================================
  // ÖNCEKİ VANA
  // ============================================================

  void _oncekiVana() {
    final vanalar = _vanalar;

    if (_seciliVana == null ||
        vanalar.isEmpty) {
      return;
    }

    final index =
        vanalar.indexOf(_seciliVana!);

    if (index > 0) {
      _vanaSec(
        vanalar[index - 1],
      );
    }
  }

  // ============================================================
  // KAYDET
  // ============================================================

  Future<void> _kaydet() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    final kayitlar =
        <SeraOlcumKaydetDetayModel>[];

    // ÖNEMLİ:
    // Backend günü silip tekrar oluşturduğu için yalnız seçili
    // vana değil, bütün ekran state'i gönderiliyor.
    for (final state in _editStates.values) {
      final deger =
          _parseDecimal(
        state.controller.text,
      );

      if (deger == null) {
        continue;
      }

      kayitlar.add(
        SeraOlcumKaydetDetayModel(
          sera: state.sera,
          vana: state.vana,
          tip: state.tip,
          deger: deger,

          // Mobilde artık detay/ortalama/toplam kullanmıyoruz.
          veriGirisTipi: null,
          detaylar: const [],
        ),
      );
    }

    if (kayitlar.isEmpty) {
      _mesaj(
        'Kaydedilecek ölçüm bulunamadı.',
        hata: true,
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _api.kaydet(
        model: SeraOlcumKaydetModel(
          tarih: _tarih,
          kullaniciKodu:
              widget.personelKodu,
          olcumler: kayitlar,
        ),
      );

      if (!mounted) return;

      _mesaj(
        'Ölçümler kaydedildi.',
      );

      await _ekraniYukle();
    } catch (e) {
      if (!mounted) return;

      _mesaj(
        'Kayıt hatası: $e',
        hata: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
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
          centerTitle: true,
          elevation: 0,
          backgroundColor:
              Colors.white,
          surfaceTintColor:
              Colors.white,
          foregroundColor:
              Colors.black87,

          title: const Text(
            'Ölçüm Giriş',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          actions: [
            IconButton(
              tooltip: 'Yenile',
              onPressed:
                  _loading || _saving
                      ? null
                      : _ekraniYukle,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 21,
              ),
            ),
          ],
        ),

        body: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : _hata != null
                ? _hataEkrani()
                : _icerik(),

        bottomNavigationBar:
            _loading || _hata != null
                ? null
                : _altKaydet(),
      ),
    );
  }

  // ============================================================
  // ANA İÇERİK
  // ============================================================

  Widget _icerik() {
    return ListView(
      physics:
          const BouncingScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        10,
        9,
        10,
        100,
      ),
      children: [
        _personelBilgisi(),

        const SizedBox(
          height: 7,
        ),

        _tarihKart(),

        const SizedBox(
          height: 7,
        ),

        _seraKart(),

        const SizedBox(
          height: 7,
        ),

        _vanaKart(),

        const SizedBox(
          height: 7,
        ),

        _olcumlerKart(),

        const SizedBox(
          height: 7,
        ),

        _vanaGezinti(),
      ],
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
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color:
              Colors.black.withOpacity(
            .05,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration:
                BoxDecoration(
              color: accent
                  .withOpacity(.09),
              borderRadius:
                  BorderRadius
                      .circular(8),
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
              color: Colors.black45,
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
  // TARİH
  // ============================================================

  Widget _tarihKart() {
    return _sectionCard(
      title: 'Ölçüm Tarihi',
      icon:
          Icons.calendar_month_rounded,
      child: InkWell(
        onTap: _tarihSec,
        borderRadius:
            BorderRadius.circular(9),
        child: Container(
          height: 44,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          decoration:
              _softDecoration(),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration:
                    BoxDecoration(
                  color: accent
                      .withOpacity(
                    .08,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    7,
                  ),
                ),
                child:
                    const Icon(
                  Icons.event_rounded,
                  color: accent,
                  size: 16,
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  _ddMmYyyy(_tarih),
                  style:
                      const TextStyle(
                    fontSize: 12.5,
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
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SERA
  // ============================================================

  Widget _seraKart() {
    return _sectionCard(
      title: 'Sera',
      icon: Icons.eco_rounded,
      child:
          SingleChildScrollView(
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        child: Row(
          children: _seralar.map(
            (sera) {
              final selected =
                  sera ==
                      _seciliSera;

              return Padding(
                padding:
                    const EdgeInsets.only(
                  right: 6,
                ),
                child: InkWell(
                  onTap: () =>
                      _seraSec(
                    sera,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    9,
                  ),
                  child:
                      AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 140,
                    ),
                    height: 39,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 13,
                    ),
                    alignment:
                        Alignment.center,
                    decoration:
                        BoxDecoration(
                      color: selected
                          ? accent
                          : const Color(
                              0xFFF5F6F8,
                            ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        9,
                      ),
                      border:
                          Border.all(
                        color: selected
                            ? accent
                            : Colors
                                .black
                                .withOpacity(
                                  .05,
                                ),
                      ),
                    ),
                    child: Text(
                      sera,
                      style:
                          TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors
                                .black87,
                        fontSize: 10.5,
                        fontWeight:
                            FontWeight
                                .w900,
                      ),
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // VANA
  // ============================================================

  Widget _vanaKart() {
    return _sectionCard(
      title: 'Vana / Sektör',
      icon:
          Icons.water_drop_outlined,
      trailing: _seciliVana == null
          ? null
          : Text(
              _seciliVana!,
              style:
                  const TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
      child:
          SingleChildScrollView(
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        child: Row(
          children: _vanalar.map(
            (vana) {
              final selected =
                  vana ==
                      _seciliVana;

              final dolu =
                  _vanaDoluSayisi(
                _seciliSera!,
                vana,
              );

              final toplam =
                  _vanaToplamOlcum(
                _seciliSera!,
                vana,
              );

              return Padding(
                padding:
                    const EdgeInsets.only(
                  right: 6,
                ),
                child: InkWell(
                  onTap: () =>
                      _vanaSec(
                    vana,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    9,
                  ),
                  child:
                      AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 140,
                    ),
                    constraints:
                        const BoxConstraints(
                      minWidth: 66,
                    ),
                    height: 48,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                    ),
                    decoration:
                        BoxDecoration(
                      color: selected
                          ? accent
                              .withOpacity(
                                .10,
                              )
                          : const Color(
                              0xFFF7F7F9,
                            ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        9,
                      ),
                      border:
                          Border.all(
                        color: selected
                            ? accent
                                .withOpacity(
                                  .40,
                                )
                            : Colors
                                .black
                                .withOpacity(
                                  .05,
                                ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Text(
                          vana,
                          style:
                              TextStyle(
                            color: selected
                                ? accent
                                : Colors
                                    .black87,
                            fontSize: 10.5,
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          '$dolu/$toplam',
                          style:
                              TextStyle(
                            color: dolu > 0
                                ? accent
                                : Colors
                                    .black38,
                            fontSize: 8.5,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // ÖLÇÜMLER
  // ============================================================

  Widget _olcumlerKart() {
    final olcumler =
        _seciliOlcumler;

    final dolu = olcumler
        .where(
          (e) =>
              e.controller.text
                  .trim()
                  .isNotEmpty,
        )
        .length;

    return _sectionCard(
      title: 'Ölçümler',
      icon:
          Icons.straighten_rounded,
      trailing: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 3,
        ),
        decoration:
            BoxDecoration(
          color:
              accent.withOpacity(.08),
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Text(
          '$dolu / ${olcumler.length}',
          style:
              const TextStyle(
            color: accent,
            fontSize: 9,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),
      child: olcumler.isEmpty
          ? const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 18,
              ),
              child: Center(
                child: Text(
                  'Ölçüm bulunamadı.',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Colors.black45,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                for (int i = 0;
                    i <
                        olcumler
                            .length;
                    i++) ...[
                  _olcumSatiri(
                    olcumler,
                    i,
                  ),

                  if (i !=
                      olcumler
                              .length -
                          1)
                    const SizedBox(
                      height: 8,
                    ),
                ],
              ],
            ),
    );
  }

  // ============================================================
  // ÖLÇÜM SATIRI
  // ============================================================

Widget _olcumSatiri(
  List<_OlcumEditState> liste,
  int index,
) {
  final state = liste[index];

  final sonAlan =
      index == liste.length - 1;

  final dolu =
      state.controller.text.trim().isNotEmpty;

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 7,
      vertical: 5,
    ),
    decoration: BoxDecoration(
      color: dolu
          ? accent.withOpacity(.025)
          : const Color(0xFFFAFAFB),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: dolu
            ? accent.withOpacity(.09)
            : Colors.black.withOpacity(.04),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 6,
          child: Text(
            state.tip,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 1.1,
              color: dolu
                  ? accent
                  : Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          flex: 4,
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: state.controller,
              focusNode: state.focusNode,
              enabled: !_saving,

              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),

              textInputAction: sonAlan
                  ? TextInputAction.done
                  : TextInputAction.next,

              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*[.,]?\d*$'),
                ),
              ],

              onChanged: (_) {
                setState(() {});
              },

              onSubmitted: (_) {
                if (!sonAlan) {
                  liste[index + 1]
                      .focusNode
                      .requestFocus();
                } else {
                  FocusScope.of(context).unfocus();
                }
              },

              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),

              decoration: InputDecoration(
                hintText: 'Değer',
                hintStyle: const TextStyle(
                  fontSize: 9.5,
                  color: Colors.black38,
                ),

                filled: true,
                fillColor: Colors.white,
                isDense: true,

                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),

                suffixIconConstraints:
                    const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),

                suffixIcon: dolu
                    ? InkWell(
                        onTap: () {
                          state.controller.clear();
                          setState(() {});
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: Colors.black38,
                        ),
                      )
                    : null,

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(7),
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(7),
                  borderSide: BorderSide(
                    color:
                        Colors.black.withOpacity(.05),
                  ),
                ),

                focusedBorder:
                    const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(7),
                  ),
                  borderSide: BorderSide(
                    color: accent,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  // ============================================================
  // VANA GEZİNTİ
  // ============================================================

  Widget _vanaGezinti() {
    if (_seciliVana == null) {
      return const SizedBox.shrink();
    }

    final vanalar = _vanalar;

    final index =
        vanalar.indexOf(
      _seciliVana!,
    );

    final oncekiVar =
        index > 0;

    final sonrakiVar =
        index >= 0 &&
            index <
                vanalar.length - 1;

    final sonrakiSeraVar =
        _seciliSera != null &&
            _seralar.indexOf(
                  _seciliSera!,
                ) <
                _seralar.length - 1;

    return Container(
      padding:
          const EdgeInsets.all(9),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color:
              Colors.black.withOpacity(
            .05,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child:
                OutlinedButton.icon(
              onPressed:
                  oncekiVar
                      ? _oncekiVana
                      : null,
              style:
                  OutlinedButton
                      .styleFrom(
                foregroundColor:
                    accent,
                minimumSize:
                    const Size(
                  0,
                  41,
                ),
                side: BorderSide(
                  color: accent
                      .withOpacity(
                    .20,
                  ),
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    9,
                  ),
                ),
              ),
              icon: const Icon(
                Icons
                    .chevron_left_rounded,
                size: 18,
              ),
              label:
                  const Text(
                'ÖNCEKİ',
                style:
                    TextStyle(
                  fontSize: 9.5,
                  fontWeight:
                      FontWeight
                          .w900,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          Expanded(
            child:
                FilledButton.icon(
              onPressed:
                  sonrakiVar ||
                          sonrakiSeraVar
                      ? _sonrakiVana
                      : null,
              style:
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    accent,
                minimumSize:
                    const Size(
                  0,
                  41,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    9,
                  ),
                ),
              ),
              label: Text(
                sonrakiVar
                    ? 'SONRAKİ VANA'
                    : sonrakiSeraVar
                        ? 'SONRAKİ SERA'
                        : 'SON',
                style:
                    const TextStyle(
                  fontSize: 9.5,
                  fontWeight:
                      FontWeight
                          .w900,
                ),
              ),
              icon: const Icon(
                Icons
                    .chevron_right_rounded,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALT KAYDET
  // ============================================================

  Widget _altKaydet() {
    final toplamDolu =
        _editStates.values
            .where(
              (e) =>
                  e.controller.text
                      .trim()
                      .isNotEmpty,
            )
            .length;

    return SafeArea(
      top: false,
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          10,
          8,
          10,
          9,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.black
                  .withOpacity(
                .05,
              ),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(
                .04,
              ),
              blurRadius: 12,
              offset:
                  const Offset(
                0,
                -3,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    '$toplamDolu ölçüm girildi',
                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight
                              .w900,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    '${_seciliSera ?? '-'}  •  '
                    '${_seciliVana ?? '-'}',
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 9.5,
                      color:
                          Colors.black45,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            SizedBox(
              width: 145,
              height: 44,
              child:
                  FilledButton.icon(
                onPressed:
                    _saving ||
                            toplamDolu ==
                                0
                        ? null
                        : _kaydet,

                style:
                    FilledButton
                        .styleFrom(
                  backgroundColor:
                      accent,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),
                ),

                icon: _saving
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons
                            .save_rounded,
                        size: 17,
                      ),

                label: Text(
                  _saving
                      ? 'KAYDEDİLİYOR'
                      : 'KAYDET',
                  style:
                      const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight
                            .w900,
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
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
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
              Colors.black.withOpacity(
            .05,
          ),
        ),
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
                  color: accent
                      .withOpacity(
                    .09,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    7,
                  ),
                ),
                child: Icon(
                  icon,
                  color: accent,
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
                      const TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        FontWeight
                            .w900,
                    color:
                        Colors.black87,
                  ),
                ),
              ),

              if (trailing != null)
                trailing,
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // HATA EKRANI
  // ============================================================

  Widget _hataEkrani() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration:
                  BoxDecoration(
                color: Colors.red
                    .withOpacity(
                  .08,
                ),
                borderRadius:
                    BorderRadius
                        .circular(
                  13,
                ),
              ),
              child: const Icon(
                Icons
                    .error_outline_rounded,
                color: Colors.red,
                size: 27,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              _hata ??
                  'Bir hata oluştu.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 11,
                color:
                    Colors.black54,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            SizedBox(
              height: 40,
              child:
                  FilledButton.icon(
                onPressed:
                    _ekraniYukle,
                style:
                    FilledButton
                        .styleFrom(
                  backgroundColor:
                      accent,
                ),
                icon: const Icon(
                  Icons
                      .refresh_rounded,
                  size: 17,
                ),
                label:
                    const Text(
                  'Tekrar Dene',
                  style:
                      TextStyle(
                    fontSize: 10.5,
                    fontWeight:
                        FontWeight
                            .w800,
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
  // SOFT DECORATION
  // ============================================================

  BoxDecoration _softDecoration() {
    return BoxDecoration(
      color:
          const Color(0xFFF7F7F9),
      borderRadius:
          BorderRadius.circular(9),
      border: Border.all(
        color:
            Colors.black.withOpacity(
          .05,
        ),
      ),
    );
  }

  // ============================================================
  // DOLU SAYISI
  // ============================================================

  int _vanaDoluSayisi(
    String sera,
    String vana,
  ) {
    return _editStates.values
        .where(
          (e) =>
              e.sera == sera &&
              e.vana == vana &&
              e.controller.text
                  .trim()
                  .isNotEmpty,
        )
        .length;
  }

  int _vanaToplamOlcum(
    String sera,
    String vana,
  ) {
    return _editStates.values
        .where(
          (e) =>
              e.sera == sera &&
              e.vana == vana,
        )
        .length;
  }

  // ============================================================
  // MESAJ
  // ============================================================

  void _mesaj(
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
          style:
              const TextStyle(
            fontSize: 11,
          ),
        ),
        backgroundColor:
            hata
                ? Colors.red.shade700
                : accent,
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAYI PARSE
  // ============================================================

  double? _parseDecimal(
    String value,
  ) {
    final text =
        value.trim();

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(
      text.replaceAll(',', '.'),
    );
  }

  // ============================================================
  // TARİH FORMAT
  // ============================================================

  String _ddMmYyyy(
    DateTime tarih,
  ) {
    String iki(int value) =>
        value
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '${iki(tarih.day)}.'
        '${iki(tarih.month)}.'
        '${tarih.year}';
  }

  // ============================================================
  // DOĞAL SIRALAMA
  // ============================================================

  static int _naturalCompare(
    String a,
    String b,
  ) {
    final regex =
        RegExp(r'\d+');

    final am =
        regex.firstMatch(a);

    final bm =
        regex.firstMatch(b);

    final an = am == null
        ? null
        : int.tryParse(
            am.group(0)!,
          );

    final bn = bm == null
        ? null
        : int.tryParse(
            bm.group(0)!,
          );

    if (an != null &&
        bn != null &&
        an != bn) {
      return an.compareTo(bn);
    }

    return a.compareTo(b);
  }
}

// ============================================================
// ÖLÇÜM EDIT STATE
// ============================================================

class _OlcumEditState {
  final String sera;
  final String vana;
  final String tip;

  final TextEditingController controller;
  final FocusNode focusNode;

  _OlcumEditState({
    required this.sera,
    required this.vana,
    required this.tip,
    required double? deger,
  })  : controller =
            TextEditingController(
          text: deger == null
              ? ''
              : _formatInitial(
                  deger,
                ),
        ),
        focusNode = FocusNode();

  static String _formatInitial(
    double value,
  ) {
    if (value ==
        value.roundToDouble()) {
      return value
          .toInt()
          .toString();
    }

    return value
        .toStringAsFixed(4)
        .replaceAll(
          RegExp(r'0+$'),
          '',
        )
        .replaceAll(
          RegExp(r'\.$'),
          '',
        );
  }
}