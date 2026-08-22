import 'dart:math' as math;

import 'package:agronet/api/sera_kontrol_rapor_api.dart';
import 'package:flutter/material.dart';

import 'package:agronet/models/sera_kontrol_rapor_model.dart';

class SeraKontrolRaporuPage extends StatefulWidget {
  const SeraKontrolRaporuPage({
    super.key,
  });

  @override
  State<SeraKontrolRaporuPage> createState() =>
      _SeraKontrolRaporuPageState();
}

class _SeraKontrolRaporuPageState
    extends State<SeraKontrolRaporuPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  final SeraKontrolRaporuApi _api =
      SeraKontrolRaporuApi();

  // ============================================================
  // VERİ
  // ============================================================

  List<SeraKontrolBolumModel> _bolumler = [];
  SeraKontrolBolumModel? _seciliBolum;

  DateTime _ilkTarih = DateTime.now();
  DateTime _sonTarih = DateTime.now();

  SeraKontrolRaporModel? _rapor;

  bool _bolumlerYukleniyor = false;
  bool _raporYukleniyor = false;

  // ============================================================
  // RAPOR AYARLARI
  // ============================================================

  List<String> _kolonSirasi = [];

  final Set<String> _gizliKolonlar = {};

  String? _grupKolonu;

  String? _siralaKolonu;
  bool _artanSirala = true;

  String? _hesapKolonu;
  _HesapTipi _hesapTipi =
      _HesapTipi.toplam;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _bolumleriGetir();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  // ============================================================
  // BÖLÜMLER
  // ============================================================

  Future<void> _bolumleriGetir() async {
    setState(() {
      _bolumlerYukleniyor = true;
    });

    try {
      final sonuc =
          await _api.bolumler();

      if (!mounted) return;

      setState(() {
        _bolumler = sonuc;

        if (_seciliBolum == null &&
            _bolumler.isNotEmpty) {
          _seciliBolum =
              _bolumler.first;
        }
      });
    } catch (e) {
      if (!mounted) return;

      _hataGoster(
        'Bölümler getirilemedi.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _bolumlerYukleniyor = false;
        });
      }
    }
  }

  // ============================================================
  // RAPOR
  // ============================================================

  Future<void> _raporuGetir() async {
    final bolum =
        _seciliBolum;

    if (bolum == null) {
      _hataGoster(
        'Bölüm seçmelisiniz.',
      );
      return;
    }

    if (_sonTarih.isBefore(
      _ilkTarih,
    )) {
      _hataGoster(
        'Son tarih ilk tarihten küçük olamaz.',
      );
      return;
    }

    setState(() {
      _raporYukleniyor = true;
    });

    try {
      final sonuc =
          await _api.rapor(
        bolum: bolum.kod,
        ilkTarih: _ilkTarih,
        sonTarih: _sonTarih,
      );

      if (!mounted) return;

      _raporAyarlariniHazirla(
        sonuc,
      );

      setState(() {
        _rapor = sonuc;
      });
    } catch (e) {
      if (!mounted) return;

      _hataGoster(
        'Rapor getirilemedi.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _raporYukleniyor = false;
        });
      }
    }
  }

  void _raporAyarlariniHazirla(
    SeraKontrolRaporModel rapor,
  ) {
    final gelen =
        rapor.columns
            .map(
              (e) => e.name,
            )
            .toList();

    if (_kolonSirasi.isEmpty) {
      _kolonSirasi =
          gelen;
    } else {
      _kolonSirasi.removeWhere(
        (e) =>
            !gelen.contains(e),
      );

      for (final kolon
          in gelen) {
        if (!_kolonSirasi
            .contains(kolon)) {
          _kolonSirasi.add(
            kolon,
          );
        }
      }
    }

    _gizliKolonlar.removeWhere(
      (e) =>
          !gelen.contains(e),
    );

    // ========================================================
    // İŞ ADI VARSA OTOMATİK GRUPLA
    // ========================================================

    if (_grupKolonu == null) {
      for (final kolon
          in rapor.columns) {
        final n =
            _normalize(
          kolon.name,
        );

        if (n == 'IS ADI' ||
            n == 'ISADI') {
          _grupKolonu =
              kolon.name;
          break;
        }
      }
    }

    // ========================================================
    // AKTİF SÜREYİ VARSAYILAN HESAP KOLONU YAP
    // ========================================================

    if (_hesapKolonu == null) {
      SeraKontrolKolonModel?
          ilkSayisal;

      for (final kolon
          in rapor.columns) {
        if (!kolon.numeric) {
          continue;
        }

        ilkSayisal ??= kolon;

        final n =
            _normalize(
          kolon.name,
        );

        if (n.contains(
          'AKTIF SURE',
        )) {
          _hesapKolonu =
              kolon.name;
          break;
        }
      }

      _hesapKolonu ??=
          ilkSayisal?.name;
    }
  }

  // ============================================================
  // TARİH
  // ============================================================

  Future<void> _ilkTarihSec() async {
    final sonuc =
        await showDatePicker(
      context: context,
      initialDate: _ilkTarih,
      firstDate:
          DateTime(2020),
      lastDate:
          DateTime(2100),
      locale:
          const Locale(
        'tr',
        'TR',
      ),
    );

    if (sonuc == null) return;

    setState(() {
      _ilkTarih = sonuc;

      if (_sonTarih
          .isBefore(sonuc)) {
        _sonTarih = sonuc;
      }
    });
  }

  Future<void> _sonTarihSec() async {
    final sonuc =
        await showDatePicker(
      context: context,
      initialDate: _sonTarih,
      firstDate: _ilkTarih,
      lastDate:
          DateTime(2100),
      locale:
          const Locale(
        'tr',
        'TR',
      ),
    );

    if (sonuc == null) return;

    setState(() {
      _sonTarih = sonuc;
    });
  }

  // ============================================================
  // SATIRLAR
  // ============================================================

  List<Map<String, dynamic>>
      get _siraliSatirlar {
    final rapor =
        _rapor;

    if (rapor == null) {
      return [];
    }

    final liste =
        rapor.rows
            .map(
              (e) =>
                  Map<String, dynamic>.from(
                e,
              ),
            )
            .toList();

    final kolon =
        _siralaKolonu;

    if (kolon == null) {
      return liste;
    }

    liste.sort(
      (a, b) {
        final sonuc =
            _degerKarsilastir(
          a[kolon],
          b[kolon],
        );

        return _artanSirala
            ? sonuc
            : -sonuc;
      },
    );

    return liste;
  }

  List<String>
      get _gorunenKolonlar {
    return _kolonSirasi
        .where(
          (e) =>
              !_gizliKolonlar
                  .contains(e),
        )
        .toList();
  }

  SeraKontrolKolonModel?
      _kolonBul(
    String name,
  ) {
    final rapor =
        _rapor;

    if (rapor == null) {
      return null;
    }

    for (final kolon
        in rapor.columns) {
      if (kolon.name ==
          name) {
        return kolon;
      }
    }

    return null;
  }

  // ============================================================
  // GRUPLAMA
  // ============================================================

  Map<String,
          List<Map<String, dynamic>>>
      _gruplariOlustur() {
    final satirlar =
        _siraliSatirlar;

    final kolon =
        _grupKolonu;

    if (kolon == null ||
        kolon.isEmpty) {
      return {
        'Tüm Kayıtlar':
            satirlar,
      };
    }

    final sonuc =
        <String,
            List<
                Map<String,
                    dynamic>>>{};

    for (final satir
        in satirlar) {
      final deger =
          satir[kolon];

      final grupAdi =
          deger == null ||
                  deger
                      .toString()
                      .trim()
                      .isEmpty
              ? '(Boş)'
              : deger
                  .toString()
                  .trim();

      sonuc.putIfAbsent(
        grupAdi,
        () => [],
      );

      sonuc[grupAdi]!.add(
        satir,
      );
    }

    return sonuc;
  }

  // ============================================================
  // HESAP
  // ============================================================

  double? _hesapla(
    List<Map<String, dynamic>>
        satirlar,
  ) {
    final kolon =
        _hesapKolonu;

    if (kolon == null) {
      return null;
    }

    final degerler =
        <double>[];

    for (final satir
        in satirlar) {
      final sayi =
          _doubleDeger(
        satir[kolon],
      );

      if (sayi != null) {
        degerler.add(
          sayi,
        );
      }
    }

    if (degerler.isEmpty) {
      return null;
    }

    switch (_hesapTipi) {
      case _HesapTipi.toplam:
        return degerler.fold<double>(
          0.0,
          (a, b) => a + b,
        );

      case _HesapTipi.ortalama:
        return degerler.fold<double>(
              0.0,
              (a, b) => a + b,
            ) /
            degerler.length;

      case _HesapTipi.minimum:
        return degerler.reduce(
          math.min,
        );

      case _HesapTipi.maksimum:
        return degerler.reduce(
          math.max,
        );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final media =
        MediaQuery.of(
      context,
    );

    final yatay =
        media.orientation ==
            Orientation.landscape;

    final scaler =
        MediaQuery.textScalerOf(
          context,
        ).clamp(
      maxScaleFactor:
          1.04,
    );

    return MediaQuery(
      data:
          media.copyWith(
        textScaler:
            scaler,
      ),
      child:
          Scaffold(
        backgroundColor:
            bg,

        appBar:
            AppBar(
          toolbarHeight:
              yatay
                  ? 42
                  : 48,
          elevation:
              0,
          backgroundColor:
              Colors.white,
          surfaceTintColor:
              Colors.white,
          foregroundColor:
              Colors.black87,
          centerTitle:
              true,
          title:
              Text(
            'Sera Kontrol Raporu',
            style:
                TextStyle(
              fontSize:
                  yatay
                      ? 14
                      : 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          actions: [
            if (_rapor != null)
              IconButton(
                visualDensity:
                    VisualDensity.compact,
                tooltip:
                    'Ayarlar',
                onPressed:
                    _raporYukleniyor
                        ? null
                        : _raporAyarlariAc,
                icon:
                    Icon(
                  Icons
                      .tune_rounded,
                  size:
                      yatay
                          ? 18
                          : 20,
                ),
              ),

            IconButton(
              visualDensity:
                  VisualDensity.compact,
              tooltip:
                  'Yenile',
              onPressed:
                  _raporYukleniyor
                      ? null
                      : () {
                          if (_rapor ==
                              null) {
                            _bolumleriGetir();
                          } else {
                            _raporuGetir();
                          }
                        },
              icon:
                  Icon(
                Icons
                    .refresh_rounded,
                size:
                    yatay
                        ? 19
                        : 21,
              ),
            ),
          ],
        ),

        body:
            Stack(
          children: [
            Column(
              children: [
                _filtreAlani(
                  yatay,
                ),

                Expanded(
                  child:
                      _icerik(
                    yatay,
                  ),
                ),
              ],
            ),

            if (_raporYukleniyor)
              _loadingOverlay(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FİLTRE ALANI
  // ============================================================

  Widget _filtreAlani(
    bool yatay,
  ) {
    if (yatay) {
      return _yatayFiltre();
    }

    return _dikeyFiltre();
  }

  // ============================================================
  // DİKEY FİLTRE
  // ============================================================

  Widget _dikeyFiltre() {
    return Container(
      color:
          Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        8,
        6,
        8,
        7,
      ),
      child:
          Column(
        children: [
          Row(
            children: [
              Expanded(
                flex:
                    5,
                child:
                    _bolumKutusu(
                  yukseklik:
                      39,
                ),
              ),

              const SizedBox(
                width:
                    5,
              ),

              Expanded(
                flex:
                    3,
                child:
                    _tarihMini(
                  _ilkTarih,
                  _ilkTarihSec,
                ),
              ),

              const SizedBox(
                width:
                    4,
              ),

              Expanded(
                flex:
                    3,
                child:
                    _tarihMini(
                  _sonTarih,
                  _sonTarihSec,
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                5,
          ),

          SizedBox(
            height:
                36,
            width:
                double.infinity,
            child:
                FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    accent,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      8,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    7,
                  ),
                ),
              ),
              onPressed:
                  _raporYukleniyor ||
                          _bolumlerYukleniyor
                      ? null
                      : _raporuGetir,
              icon:
                  const Icon(
                Icons
                    .analytics_outlined,
                size:
                    15,
              ),
              label:
                  const Text(
                'RAPORU GETİR',
                style:
                    TextStyle(
                  fontSize:
                      9.5,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // YATAY FİLTRE
  // ============================================================

  Widget _yatayFiltre() {
    return Container(
      height:
          50,
      color:
          Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        7,
        5,
        7,
        5,
      ),
      child:
          Row(
        children: [
          Expanded(
            flex:
                4,
            child:
                _bolumKutusu(
              yukseklik:
                  38,
            ),
          ),

          const SizedBox(
            width:
                5,
          ),

          Expanded(
            flex:
                2,
            child:
                _tarihMini(
              _ilkTarih,
              _ilkTarihSec,
            ),
          ),

          const SizedBox(
            width:
                4,
          ),

          Expanded(
            flex:
                2,
            child:
                _tarihMini(
              _sonTarih,
              _sonTarihSec,
            ),
          ),

          const SizedBox(
            width:
                5,
          ),

          SizedBox(
            height:
                38,
            child:
                FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    accent,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      10,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    7,
                  ),
                ),
              ),
              onPressed:
                  _raporYukleniyor ||
                          _bolumlerYukleniyor
                      ? null
                      : _raporuGetir,
              icon:
                  const Icon(
                Icons
                    .search_rounded,
                size:
                    15,
              ),
              label:
                  const Text(
                'GETİR',
                style:
                    TextStyle(
                  fontSize:
                      9,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BÖLÜM KUTUSU
  // ============================================================

  Widget _bolumKutusu({
    required double yukseklik,
  }) {
    return Container(
      height:
          yukseklik,
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF7F7F9,
        ),
        borderRadius:
            BorderRadius.circular(
          7,
        ),
        border:
            Border.all(
          color:
              Colors.black.withOpacity(
            .045,
          ),
        ),
      ),
      child:
          DropdownButtonHideUnderline(
        child:
            DropdownButton<
                SeraKontrolBolumModel>(
          value:
              _seciliBolum,
          isExpanded:
              true,
          icon:
              const Icon(
            Icons
                .keyboard_arrow_down_rounded,
            size:
                16,
            color:
                Colors.black38,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                7,
          ),
          items:
              _bolumler.map(
            (bolum) {
              return DropdownMenuItem<
                  SeraKontrolBolumModel>(
                value:
                    bolum,
                child:
                    Row(
                  children: [
                    const Icon(
                      Icons
                          .domain_outlined,
                      size:
                          13,
                      color:
                          accent,
                    ),

                    const SizedBox(
                      width:
                          5,
                    ),

                    Expanded(
                      child:
                          Text(
                        bolum.baslik,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize:
                              9.5,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ).toList(),
          onChanged:
              _bolumlerYukleniyor
                  ? null
                  : (value) {
                      setState(
                        () {
                          _seciliBolum =
                              value;
                        },
                      );
                    },
        ),
      ),
    );
  }

  // ============================================================
  // TARİH MİNİ
  // ============================================================

  Widget _tarihMini(
    DateTime tarih,
    VoidCallback onTap,
  ) {
    return Material(
      color:
          const Color(
        0xFFF7F7F9,
      ),
      borderRadius:
          BorderRadius.circular(
        7,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          7,
        ),
        child:
            Container(
          height:
              38,
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                6,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              7,
            ),
            border:
                Border.all(
              color:
                  Colors.black.withOpacity(
                .045,
              ),
            ),
          ),
          child:
              Row(
            children: [
              const Icon(
                Icons
                    .calendar_month_outlined,
                size:
                    13,
                color:
                    accent,
              ),

              const SizedBox(
                width:
                    4,
              ),

              Expanded(
                child:
                    Text(
                  _tarihYaz(
                    tarih,
                  ),
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize:
                        9,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // İÇERİK
  // ============================================================

  Widget _icerik(
    bool yatay,
  ) {
    if (_bolumlerYukleniyor) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              accent,
        ),
      );
    }

    if (_rapor == null) {
      return _bosRapor(
        yatay,
      );
    }

    if (_rapor!.rows.isEmpty) {
      return _kayitYok(
        yatay,
      );
    }

    return _raporIcerigi(
      yatay,
    );
  }

  Widget _bosRapor(
    bool yatay,
  ) {
    return Center(
      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons
                .analytics_outlined,
            size:
                yatay
                    ? 34
                    : 44,
            color:
                Colors.black26,
          ),

          SizedBox(
            height:
                yatay
                    ? 5
                    : 8,
          ),

          Text(
            'Bölüm ve tarih seçerek raporu getirin',
            style:
                TextStyle(
              fontSize:
                  yatay
                      ? 10.5
                      : 12,
              color:
                  Colors.black45,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kayitYok(
    bool yatay,
  ) {
    return Center(
      child:
          Text(
        'Seçilen kriterlerde kayıt bulunamadı.',
        style:
            TextStyle(
          fontSize:
              yatay
                  ? 10
                  : 12,
          color:
              Colors.black45,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // RAPOR İÇERİĞİ
  // ============================================================

  Widget _raporIcerigi(
    bool yatay,
  ) {
    final gruplar =
        _gruplariOlustur();

    return Column(
      children: [
        _raporUstBilgi(
          yatay,
        ),

        Expanded(
          child:
              ListView.separated(
            padding:
                EdgeInsets.fromLTRB(
              yatay
                  ? 6
                  : 8,
              5,
              yatay
                  ? 6
                  : 8,
              10,
            ),
            itemCount:
                gruplar.length,
            separatorBuilder:
                (_, __) =>
                    const SizedBox(
              height:
                  5,
            ),
            itemBuilder:
                (
              context,
              index,
            ) {
              final entry =
                  gruplar.entries
                      .elementAt(
                index,
              );

              return _grupKarti(
                entry.key,
                entry.value,
                yatay,
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ÜST ÖZET
  // ============================================================

  Widget _raporUstBilgi(
    bool yatay,
  ) {
    final hesap =
        _hesapla(
      _siraliSatirlar,
    );

    return Container(
      height:
          yatay
              ? 36
              : 42,
      color:
          Colors.white,
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            8,
      ),
      child:
          Row(
        children: [
          const Icon(
            Icons
                .table_chart_outlined,
            size:
                15,
            color:
                accent,
          ),

          const SizedBox(
            width:
                5,
          ),

          Text(
            '${_rapor!.kayitSayisi} kayıt',
            style:
                TextStyle(
              fontSize:
                  yatay
                      ? 9
                      : 10,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          if (_grupKolonu !=
              null) ...[
            const SizedBox(
              width:
                  8,
            ),

            Expanded(
              child:
                  Text(
                'Grup: $_grupKolonu',
                maxLines:
                    1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    TextStyle(
                  fontSize:
                      yatay
                          ? 8
                          : 8.5,
                  color:
                      Colors.black45,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ] else
            const Spacer(),

          if (hesap != null &&
              _hesapKolonu !=
                  null)
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal:
                    6,
                vertical:
                    3,
              ),
              decoration:
                  BoxDecoration(
                color:
                    accent.withOpacity(
                  .07,
                ),
                borderRadius:
                    BorderRadius.circular(
                  6,
                ),
              ),
              child:
                  Text(
                '${_hesapTipiYazi(_hesapTipi)}: ${_sayiYaz(hesap)}',
                style:
                    TextStyle(
                  fontSize:
                      yatay
                          ? 8
                          : 8.5,
                  color:
                      accent,
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
  // GRUP KARTI
  // ============================================================

  Widget _grupKarti(
    String grupAdi,
    List<Map<String, dynamic>>
        satirlar,
    bool yatay,
  ) {
    final hesap =
        _hesapla(
      satirlar,
    );

    return Material(
      color:
          Colors.white,
      borderRadius:
          BorderRadius.circular(
        8,
      ),
      child:
          Container(
        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(
            8,
          ),
          border:
              Border.all(
            color:
                Colors.black.withOpacity(
              .05,
            ),
          ),
        ),
        child:
            Theme(
          data:
              Theme.of(
            context,
          ).copyWith(
            dividerColor:
                Colors.transparent,
          ),
          child:
              ExpansionTile(
            initiallyExpanded:
                true,
            dense:
                true,
            visualDensity:
                const VisualDensity(
              vertical:
                  -3,
            ),
            tilePadding:
                const EdgeInsets.fromLTRB(
              6,
              0,
              3,
              0,
            ),
            childrenPadding:
                EdgeInsets.zero,

            leading:
                Container(
              width:
                  yatay
                      ? 27
                      : 30,
              height:
                  yatay
                      ? 27
                      : 30,
              alignment:
                  Alignment.center,
              decoration:
                  BoxDecoration(
                color:
                    accent.withOpacity(
                  .08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  6,
                ),
              ),
              child:
                  Text(
                '${satirlar.length}',
                style:
                    TextStyle(
                  fontSize:
                      yatay
                          ? 8.5
                          : 9,
                  color:
                      accent,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),

            title:
                Text(
              grupAdi,
              maxLines:
                  1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  TextStyle(
                fontSize:
                    yatay
                        ? 9.5
                        : 10.5,
                fontWeight:
                    FontWeight.w900,
              ),
            ),

            subtitle:
                hesap == null
                    ? null
                    : Text(
                        '${_hesapTipiYazi(_hesapTipi)}: ${_sayiYaz(hesap)}',
                        style:
                            TextStyle(
                          fontSize:
                              yatay
                                  ? 7.5
                                  : 8,
                          color:
                              accent,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

            children: [
              _tablo(
                satirlar,
                yatay,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TABLO
  // ============================================================

  Widget _tablo(
    List<Map<String, dynamic>>
        satirlar,
    bool yatay,
  ) {
    final kolonlar =
        _gorunenKolonlar;

    if (kolonlar.isEmpty) {
      return const Padding(
        padding:
            EdgeInsets.all(
          10,
        ),
        child:
            Text(
          'Görünür kolon yok.',
          style:
              TextStyle(
            fontSize:
                9,
            color:
                Colors.black45,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,
      child:
          DataTable(
        headingRowHeight:
            yatay
                ? 30
                : 34,
        dataRowMinHeight:
            yatay
                ? 27
                : 31,
        dataRowMaxHeight:
            yatay
                ? 34
                : 38,
        horizontalMargin:
            yatay
                ? 6
                : 7,
        columnSpacing:
            yatay
                ? 11
                : 14,
        dividerThickness:
            .4,

        columns:
            kolonlar.map(
          (kolonAdi) {
            final numeric =
                _kolonBul(
                      kolonAdi,
                    )?.numeric ??
                    false;

            final sirali =
                _siralaKolonu ==
                    kolonAdi;

            return DataColumn(
              numeric:
                  numeric,
              label:
                  InkWell(
                onTap:
                    () {
                  _kolonMenuAc(
                    kolonAdi,
                  );
                },
                child:
                    Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(
                        maxWidth:
                            yatay
                                ? 110
                                : 130,
                      ),
                      child:
                          Text(
                        kolonAdi,
                        maxLines:
                            2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            TextStyle(
                          fontSize:
                              yatay
                                  ? 7.8
                                  : 8.5,
                          fontWeight:
                              FontWeight.w900,
                          height:
                              1.05,
                        ),
                      ),
                    ),

                    if (sirali)
                      Icon(
                        _artanSirala
                            ? Icons
                                .arrow_upward_rounded
                            : Icons
                                .arrow_downward_rounded,
                        size:
                            9,
                        color:
                            accent,
                      ),
                  ],
                ),
              ),
            );
          },
        ).toList(),

        rows:
            satirlar.map(
          (satir) {
            return DataRow(
              cells:
                  kolonlar.map(
                (kolonAdi) {
                  final numeric =
                      _kolonBul(
                            kolonAdi,
                          )?.numeric ??
                          false;

                  return DataCell(
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(
                        minWidth:
                            numeric
                                ? 40
                                : 55,
                        maxWidth:
                            yatay
                                ? 125
                                : 145,
                      ),
                      child:
                          Text(
                        _degerYaz(
                          satir[
                              kolonAdi],
                        ),
                        maxLines:
                            2,
                        overflow:
                            TextOverflow.ellipsis,
                        textAlign:
                            numeric
                                ? TextAlign.right
                                : TextAlign.left,
                        style:
                            TextStyle(
                          fontSize:
                              yatay
                                  ? 8
                                  : 8.8,
                          fontWeight:
                              FontWeight.w600,
                          height:
                              1.05,
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            );
          },
        ).toList(),
      ),
    );
  }

  // ============================================================
  // RAPOR AYARLARI
  // ============================================================

  Future<void> _raporAyarlariAc() async {
    final rapor =
        _rapor;

    if (rapor == null) {
      return;
    }

    List<String> tempSira =
        List.from(
      _kolonSirasi,
    );

    final tempGizli =
        Set<String>.from(
      _gizliKolonlar,
    );

    String? tempGrup =
        _grupKolonu;

    String? tempHesap =
        _hesapKolonu;

    _HesapTipi tempTip =
        _hesapTipi;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            12,
          ),
        ),
      ),
      builder:
          (
        bottomContext,
      ) {
        return StatefulBuilder(
          builder:
              (
            context,
            setSheetState,
          ) {
            final numeric =
                rapor.columns
                    .where(
                      (e) =>
                          e.numeric,
                    )
                    .toList();

            final yatay =
                MediaQuery.of(
                      context,
                    ).orientation ==
                    Orientation.landscape;

            return SafeArea(
              child:
                  SizedBox(
                height:
                    MediaQuery.of(
                          context,
                        ).size.height *
                        (yatay
                            ? .92
                            : .78),
                child:
                    Column(
                  children: [
                    // =================================================
                    // BAŞLIK
                    // =================================================

                    Container(
                      height:
                          40,
                      padding:
                          const EdgeInsets.fromLTRB(
                        9,
                        0,
                        3,
                        0,
                      ),
                      child:
                          Row(
                        children: [
                          const Icon(
                            Icons
                                .tune_rounded,
                            size:
                                16,
                            color:
                                accent,
                          ),

                          const SizedBox(
                            width:
                                5,
                          ),

                          const Expanded(
                            child:
                                Text(
                              'Rapor Ayarları',
                              style:
                                  TextStyle(
                                fontSize:
                                    11,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),

                          IconButton(
                            visualDensity:
                                VisualDensity.compact,
                            onPressed:
                                () {
                              Navigator.pop(
                                bottomContext,
                              );
                            },
                            icon:
                                const Icon(
                              Icons
                                  .close_rounded,
                              size:
                                  18,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(
                      height:
                          1,
                      color:
                          Colors.black.withOpacity(
                        .05,
                      ),
                    ),

                    Expanded(
                      child:
                          ListView(
                        padding:
                            const EdgeInsets.fromLTRB(
                          8,
                          7,
                          8,
                          8,
                        ),
                        children: [
                          // =============================================
                          // GRUP
                          // =============================================

                          _ayarMiniSecim(
                            baslik:
                                'Grup',
                            deger:
                                tempGrup ??
                                    'Yok',
                            ikon:
                                Icons
                                    .account_tree_outlined,
                            onTap:
                                () async {
                              final secenekler =
                                  <String>[
                                'Gruplama Yok',
                                ...rapor.columns.map(
                                  (e) =>
                                      e.name,
                                ),
                              ];

                              final secilen =
                                  await _miniSecimAc(
                                baslik:
                                    'Gruplama',
                                secili:
                                    tempGrup,
                                secenekler:
                                    secenekler,
                              );

                              if (secilen ==
                                  null) {
                                return;
                              }

                              setSheetState(
                                () {
                                  tempGrup =
                                      secilen ==
                                              'Gruplama Yok'
                                          ? null
                                          : secilen;
                                },
                              );
                            },
                          ),

                          const SizedBox(
                            height:
                                5,
                          ),

                          // =============================================
                          // HESAP KOLONU
                          // =============================================

                          _ayarMiniSecim(
                            baslik:
                                'Hesap',
                            deger:
                                tempHesap ??
                                    'Yok',
                            ikon:
                                Icons
                                    .functions_rounded,
                            onTap:
                                numeric.isEmpty
                                    ? null
                                    : () async {
                                        final secilen =
                                            await _miniSecimAc(
                                          baslik:
                                              'Hesap Kolonu',
                                          secili:
                                              tempHesap,
                                          secenekler:
                                              numeric
                                                  .map(
                                                    (e) => e.name,
                                                  )
                                                  .toList(),
                                        );

                                        if (secilen ==
                                            null) {
                                          return;
                                        }

                                        setSheetState(
                                          () {
                                            tempHesap =
                                                secilen;
                                          },
                                        );
                                      },
                          ),

                          const SizedBox(
                            height:
                                5,
                          ),

                          // =============================================
                          // HESAP TİPİ
                          // =============================================

                          Row(
                            children:
                                _HesapTipi.values.map(
                              (tip) {
                                final secili =
                                    tempTip ==
                                        tip;

                                return Expanded(
                                  child:
                                      Padding(
                                    padding:
                                        EdgeInsets.only(
                                      right:
                                          tip !=
                                                  _HesapTipi
                                                      .maksimum
                                              ? 3
                                              : 0,
                                    ),
                                    child:
                                        Material(
                                      color:
                                          secili
                                              ? accent.withOpacity(
                                                  .09,
                                                )
                                              : const Color(
                                                  0xFFF7F7F9,
                                                ),
                                      borderRadius:
                                          BorderRadius.circular(
                                        6,
                                      ),
                                      child:
                                          InkWell(
                                        borderRadius:
                                            BorderRadius.circular(
                                          6,
                                        ),
                                        onTap:
                                            () {
                                          setSheetState(
                                            () {
                                              tempTip =
                                                  tip;
                                            },
                                          );
                                        },
                                        child:
                                            Container(
                                          height:
                                              31,
                                          alignment:
                                              Alignment.center,
                                          decoration:
                                              BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(
                                              6,
                                            ),
                                            border:
                                                Border.all(
                                              color:
                                                  secili
                                                      ? accent.withOpacity(.25)
                                                      : Colors.black.withOpacity(.04),
                                            ),
                                          ),
                                          child:
                                              Text(
                                            _hesapTipiKisa(
                                              tip,
                                            ),
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  8,
                                              fontWeight:
                                                  FontWeight.w900,
                                              color:
                                                  secili
                                                      ? accent
                                                      : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ).toList(),
                          ),

                          const SizedBox(
                            height:
                                8,
                          ),

                          Row(
                            children: [
                              const Icon(
                                Icons
                                    .view_column_outlined,
                                size:
                                    14,
                                color:
                                    accent,
                              ),

                              const SizedBox(
                                width:
                                    4,
                              ),

                              const Text(
                                'Kolonlar',
                                style:
                                    TextStyle(
                                  fontSize:
                                      9.5,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),

                              const Spacer(),

                              Text(
                                '${tempSira.length}',
                                style:
                                    const TextStyle(
                                  fontSize:
                                      8,
                                  color:
                                      Colors.black38,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height:
                                4,
                          ),

                          ReorderableListView.builder(
                            shrinkWrap:
                                true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles:
                                false,
                            itemCount:
                                tempSira.length,
                            onReorder:
                                (
                              oldIndex,
                              newIndex,
                            ) {
                              if (newIndex >
                                  oldIndex) {
                                newIndex--;
                              }

                              setSheetState(
                                () {
                                  final item =
                                      tempSira.removeAt(
                                    oldIndex,
                                  );

                                  tempSira.insert(
                                    newIndex,
                                    item,
                                  );
                                },
                              );
                            },
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              final name =
                                  tempSira[
                                      index];

                              final gorunur =
                                  !tempGizli
                                      .contains(
                                name,
                              );

                              return Container(
                                key:
                                    ValueKey(
                                  name,
                                ),
                                height:
                                    36,
                                margin:
                                    const EdgeInsets.only(
                                  bottom:
                                      3,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFF7F7F9,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    7,
                                  ),
                                  border:
                                      Border.all(
                                    color:
                                        Colors.black.withOpacity(
                                      .04,
                                    ),
                                  ),
                                ),
                                child:
                                    Row(
                                  children: [
                                    ReorderableDragStartListener(
                                      index:
                                          index,
                                      child:
                                          const SizedBox(
                                        width:
                                            30,
                                        child:
                                            Icon(
                                          Icons
                                              .drag_indicator_rounded,
                                          size:
                                              16,
                                          color:
                                              Colors.black38,
                                        ),
                                      ),
                                    ),

                                    Expanded(
                                      child:
                                          Text(
                                        name,
                                        maxLines:
                                            1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style:
                                            const TextStyle(
                                          fontSize:
                                              8.8,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                    ),

                                    SizedBox(
                                      width:
                                          38,
                                      child:
                                          Switch(
                                        value:
                                            gorunur,
                                        activeColor:
                                            accent,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        onChanged:
                                            (value) {
                                          setSheetState(
                                            () {
                                              if (value) {
                                                tempGizli.remove(
                                                  name,
                                                );
                                              } else {
                                                tempGizli.add(
                                                  name,
                                                );
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets.fromLTRB(
                        7,
                        5,
                        7,
                        6,
                      ),
                      child:
                          SizedBox(
                        height:
                            36,
                        width:
                            double.infinity,
                        child:
                            FilledButton(
                          style:
                              FilledButton.styleFrom(
                            backgroundColor:
                                accent,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                7,
                              ),
                            ),
                          ),
                          onPressed:
                              () {
                            setState(
                              () {
                                _kolonSirasi =
                                    tempSira;

                                _gizliKolonlar
                                  ..clear()
                                  ..addAll(
                                    tempGizli,
                                  );

                                _grupKolonu =
                                    tempGrup;

                                _hesapKolonu =
                                    tempHesap;

                                _hesapTipi =
                                    tempTip;
                              },
                            );

                            Navigator.pop(
                              bottomContext,
                            );
                          },
                          child:
                              const Text(
                            'UYGULA',
                            style:
                                TextStyle(
                              fontSize:
                                  9,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),
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

  // ============================================================
  // AYAR MİNİ SEÇİM
  // ============================================================

  Widget _ayarMiniSecim({
    required String baslik,
    required String deger,
    required IconData ikon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color:
          const Color(
        0xFFF7F7F9,
      ),
      borderRadius:
          BorderRadius.circular(
        7,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          7,
        ),
        child:
            Container(
          height:
              34,
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                6,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              7,
            ),
            border:
                Border.all(
              color:
                  Colors.black.withOpacity(
                .04,
              ),
            ),
          ),
          child:
              Row(
            children: [
              Container(
                width:
                    20,
                height:
                    20,
                decoration:
                    BoxDecoration(
                  color:
                      accent.withOpacity(
                    .08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    5,
                  ),
                ),
                child:
                    Icon(
                  ikon,
                  size:
                      12,
                  color:
                      accent,
                ),
              ),

              const SizedBox(
                width:
                    5,
              ),

              Text(
                '$baslik:',
                style:
                    const TextStyle(
                  fontSize:
                      8,
                  color:
                      Colors.black45,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                width:
                    3,
              ),

              Expanded(
                child:
                    Text(
                  deger,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize:
                        8.8,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),

              const Icon(
                Icons
                    .keyboard_arrow_down_rounded,
                size:
                    14,
                color:
                    Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MİNİ SEÇİM LİSTESİ
  // ============================================================

  Future<String?> _miniSecimAc({
    required String baslik,
    required String? secili,
    required List<String> secenekler,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor:
          Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            11,
          ),
        ),
      ),
      builder:
          (
        context,
      ) {
        final yatay =
            MediaQuery.of(
                  context,
                ).orientation ==
                Orientation.landscape;

        return SafeArea(
          child:
              ConstrainedBox(
            constraints:
                BoxConstraints(
              maxHeight:
                  MediaQuery.of(
                        context,
                      ).size.height *
                      (yatay
                          ? .78
                          : .52),
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                SizedBox(
                  height:
                      36,
                  child:
                      Row(
                    children: [
                      const SizedBox(
                        width:
                            9,
                      ),

                      Expanded(
                        child:
                            Text(
                          baslik,
                          style:
                              const TextStyle(
                            fontSize:
                                10,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),

                      IconButton(
                        visualDensity:
                            VisualDensity.compact,
                        onPressed:
                            () {
                          Navigator.pop(
                            context,
                          );
                        },
                        icon:
                            const Icon(
                          Icons
                              .close_rounded,
                          size:
                              17,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  height:
                      1,
                  color:
                      Colors.black.withOpacity(
                    .05,
                  ),
                ),

                Flexible(
                  child:
                      ListView.separated(
                    shrinkWrap:
                        true,
                    padding:
                        const EdgeInsets.fromLTRB(
                      6,
                      5,
                      6,
                      7,
                    ),
                    itemCount:
                        secenekler.length,
                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      height:
                          3,
                    ),
                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      final item =
                          secenekler[
                              index];

                      final aktif =
                          item ==
                                  secili ||
                              (item ==
                                      'Gruplama Yok' &&
                                  secili ==
                                      null);

                      return Material(
                        color:
                            aktif
                                ? accent.withOpacity(
                                    .07,
                                  )
                                : const Color(
                                    0xFFF7F7F9,
                                  ),
                        borderRadius:
                            BorderRadius.circular(
                          6,
                        ),
                        child:
                            InkWell(
                          borderRadius:
                              BorderRadius.circular(
                            6,
                          ),
                          onTap:
                              () {
                            Navigator.pop(
                              context,
                              item,
                            );
                          },
                          child:
                              Container(
                            height:
                                31,
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal:
                                  7,
                            ),
                            child:
                                Row(
                              children: [
                                Expanded(
                                  child:
                                      Text(
                                    item,
                                    maxLines:
                                        1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style:
                                        TextStyle(
                                      fontSize:
                                          8.5,
                                      fontWeight:
                                          FontWeight.w800,
                                      color:
                                          aktif
                                              ? accent
                                              : Colors.black87,
                                    ),
                                  ),
                                ),

                                if (aktif)
                                  const Icon(
                                    Icons
                                        .check_rounded,
                                    size:
                                        13,
                                    color:
                                        accent,
                                  ),
                              ],
                            ),
                          ),
                        ),
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
  }

  // ============================================================
  // KOLON MENÜ
  // ============================================================

  Future<void> _kolonMenuAc(
    String kolonAdi,
  ) async {
    final kolon =
        _kolonBul(
      kolonAdi,
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            11,
          ),
        ),
      ),
      builder:
          (
        bottomContext,
      ) {
        return SafeArea(
          child:
              Padding(
            padding:
                const EdgeInsets.fromLTRB(
              6,
              4,
              6,
              7,
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                SizedBox(
                  height:
                      34,
                  child:
                      Row(
                    children: [
                      Expanded(
                        child:
                            Text(
                          kolonAdi,
                          maxLines:
                              1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontSize:
                                10,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),

                      IconButton(
                        visualDensity:
                            VisualDensity.compact,
                        onPressed:
                            () {
                          Navigator.pop(
                            bottomContext,
                          );
                        },
                        icon:
                            const Icon(
                          Icons
                              .close_rounded,
                          size:
                              17,
                        ),
                      ),
                    ],
                  ),
                ),

                _kolonMenuSatiri(
                  Icons
                      .arrow_upward_rounded,
                  'Artan Sırala',
                  () {
                    setState(
                      () {
                        _siralaKolonu =
                            kolonAdi;
                        _artanSirala =
                            true;
                      },
                    );

                    Navigator.pop(
                      bottomContext,
                    );
                  },
                ),

                _kolonMenuSatiri(
                  Icons
                      .arrow_downward_rounded,
                  'Azalan Sırala',
                  () {
                    setState(
                      () {
                        _siralaKolonu =
                            kolonAdi;
                        _artanSirala =
                            false;
                      },
                    );

                    Navigator.pop(
                      bottomContext,
                    );
                  },
                ),

                _kolonMenuSatiri(
                  Icons
                      .account_tree_outlined,
                  'Bu Kolona Göre Grupla',
                  () {
                    setState(
                      () {
                        _grupKolonu =
                            kolonAdi;
                      },
                    );

                    Navigator.pop(
                      bottomContext,
                    );
                  },
                ),

                _kolonMenuSatiri(
                  Icons
                      .visibility_off_outlined,
                  'Kolonu Gizle',
                  () {
                    setState(
                      () {
                        _gizliKolonlar.add(
                          kolonAdi,
                        );
                      },
                    );

                    Navigator.pop(
                      bottomContext,
                    );
                  },
                ),

                if (kolon?.numeric ==
                    true) ...[
                  const Divider(
                    height:
                        6,
                  ),

                  _kolonMenuSatiri(
                    Icons
                        .functions_rounded,
                    'Toplam',
                    () {
                      _hesapSec(
                        kolonAdi,
                        _HesapTipi
                            .toplam,
                      );

                      Navigator.pop(
                        bottomContext,
                      );
                    },
                  ),

                  _kolonMenuSatiri(
                    Icons
                        .calculate_outlined,
                    'Ortalama',
                    () {
                      _hesapSec(
                        kolonAdi,
                        _HesapTipi
                            .ortalama,
                      );

                      Navigator.pop(
                        bottomContext,
                      );
                    },
                  ),

                  _kolonMenuSatiri(
                    Icons
                        .south_rounded,
                    'Minimum',
                    () {
                      _hesapSec(
                        kolonAdi,
                        _HesapTipi
                            .minimum,
                      );

                      Navigator.pop(
                        bottomContext,
                      );
                    },
                  ),

                  _kolonMenuSatiri(
                    Icons
                        .north_rounded,
                    'Maksimum',
                    () {
                      _hesapSec(
                        kolonAdi,
                        _HesapTipi
                            .maksimum,
                      );

                      Navigator.pop(
                        bottomContext,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kolonMenuSatiri(
    IconData icon,
    String text,
    VoidCallback onTap,
  ) {
    return ListTile(
      minTileHeight:
          32,
      dense:
          true,
      visualDensity:
          const VisualDensity(
        vertical:
            -4,
      ),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal:
            5,
      ),
      minLeadingWidth:
          20,
      leading:
          Icon(
        icon,
        size:
            14,
        color:
            accent,
      ),
      title:
          Text(
        text,
        style:
            const TextStyle(
          fontSize:
              8.8,
          fontWeight:
              FontWeight.w700,
        ),
      ),
      onTap:
          onTap,
    );
  }

  void _hesapSec(
    String kolon,
    _HesapTipi tip,
  ) {
    setState(() {
      _hesapKolonu =
          kolon;
      _hesapTipi =
          tip;
    });
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _loadingOverlay() {
    return Positioned.fill(
      child:
          Container(
        color:
            Colors.black.withOpacity(
          .10,
        ),
        alignment:
            Alignment.center,
        child:
            Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                14,
            vertical:
                10,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.white,
            borderRadius:
                BorderRadius.circular(
              9,
            ),
          ),
          child:
              const Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              SizedBox(
                width:
                    23,
                height:
                    23,
                child:
                    CircularProgressIndicator(
                  strokeWidth:
                      2.2,
                  color:
                      accent,
                ),
              ),

              SizedBox(
                height:
                    6,
              ),

              Text(
                'Rapor hazırlanıyor...',
                style:
                    TextStyle(
                  fontSize:
                      9,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int _degerKarsilastir(
    dynamic a,
    dynamic b,
  ) {
    if (a == null &&
        b == null) {
      return 0;
    }

    if (a == null) {
      return 1;
    }

    if (b == null) {
      return -1;
    }

    final da =
        _doubleDeger(
      a,
    );

    final db =
        _doubleDeger(
      b,
    );

    if (da != null &&
        db != null) {
      return da.compareTo(
        db,
      );
    }

    return a
        .toString()
        .toLowerCase()
        .compareTo(
          b
              .toString()
              .toLowerCase(),
        );
  }

  double? _doubleDeger(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    var text =
        value
            .toString()
            .trim();

    if (text.isEmpty) {
      return null;
    }

    final direkt =
        double.tryParse(
      text,
    );

    if (direkt != null) {
      return direkt;
    }

    text =
        text
            .replaceAll(
              '.',
              '',
            )
            .replaceAll(
              ',',
              '.',
            );

    return double.tryParse(
      text,
    );
  }

  String _degerYaz(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    if (value is DateTime) {
      return _tarihYaz(
        value,
      );
    }

    if (value is double) {
      return _sayiYaz(
        value,
      );
    }

    return value.toString();
  }

  String _sayiYaz(
    double value,
  ) {
    if (value ==
        value.roundToDouble()) {
      return value
          .toInt()
          .toString();
    }

    return value
        .toStringAsFixed(
          2,
        )
        .replaceAll(
          '.',
          ',',
        );
  }

  String _tarihYaz(
    DateTime tarih,
  ) {
    final gun =
        tarih.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final ay =
        tarih.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$gun.$ay.${tarih.year}';
  }

  String _normalize(
    String value,
  ) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll(
          'İ',
          'I',
        )
        .replaceAll(
          'Ş',
          'S',
        )
        .replaceAll(
          'Ğ',
          'G',
        )
        .replaceAll(
          'Ü',
          'U',
        )
        .replaceAll(
          'Ö',
          'O',
        )
        .replaceAll(
          'Ç',
          'C',
        );
  }

  static String _hesapTipiYazi(
    _HesapTipi tip,
  ) {
    switch (tip) {
      case _HesapTipi.toplam:
        return 'Toplam';

      case _HesapTipi.ortalama:
        return 'Ortalama';

      case _HesapTipi.minimum:
        return 'Minimum';

      case _HesapTipi.maksimum:
        return 'Maksimum';
    }
  }

  static String _hesapTipiKisa(
    _HesapTipi tip,
  ) {
    switch (tip) {
      case _HesapTipi.toplam:
        return 'TOPLAM';

      case _HesapTipi.ortalama:
        return 'ORT.';

      case _HesapTipi.minimum:
        return 'MIN';

      case _HesapTipi.maksimum:
        return 'MAX';
    }
  }

  // ============================================================
  // HATA
  // ============================================================

  void _hataGoster(
    String mesaj,
  ) {
    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              Colors.red.shade700,
          content:
              Text(
            mesaj,
            style:
                const TextStyle(
              fontSize:
                  10,
            ),
          ),
        ),
      );
  }
}

enum _HesapTipi {
  toplam,
  ortalama,
  minimum,
  maksimum,
}