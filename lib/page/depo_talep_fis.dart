import 'package:agronet/models/depo_talep.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:agronet/api/depo_talep_api.dart';
import 'package:agronet/models/depo_talep_model.dart';

class DepoTalepFisiPage extends StatefulWidget {
  final String kullaniciKodu;
  final int oturumId;
  final String token;

  const DepoTalepFisiPage({
    super.key,
    required this.kullaniciKodu,
    required this.oturumId,
    required this.token,
  });

  @override
  State<DepoTalepFisiPage> createState() =>
      _DepoTalepFisiPageState();
}

class _DepoTalepFisiPageState
    extends State<DepoTalepFisiPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  final DepoTalepApi _api = DepoTalepApi();

  final TextEditingController _aramaController =
      TextEditingController();

  List<DepoTalepDepoModel> _depolar = [];
  List<DepoTalepStokModel> _stoklar = [];

  final List<DepoTalepGirisKalemModel> _kalemler = [];

  DepoTalepDepoModel? _kaynakDepo;
  DepoTalepDepoModel? _hedefDepo;

  bool _sadeceDepodaOlanlar = true;

  bool _depolarYukleniyor = false;
  bool _stoklarYukleniyor = false;
  bool _kaydediliyor = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _depolariGetir();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  // ============================================================
  // OTURUM
  // ============================================================

  bool get _oturumGecerli {
    return widget.kullaniciKodu.trim().isNotEmpty &&
        widget.oturumId > 0 &&
        widget.token.trim().isNotEmpty;
  }

  // ============================================================
  // DEPOLAR
  // ============================================================

  Future<void> _depolariGetir() async {
    if (_depolarYukleniyor) return;

    setState(() {
      _depolarYukleniyor = true;
    });

    try {
      final sonuc =
          await _api.talepDepolariGetir(
        personelKodu: widget.kullaniciKodu,
      );

      if (!mounted) return;

      if (sonuc.kaynakDepo == null) {
        throw Exception(
          'Kırşehir Merkez Depo bulunamadı.',
        );
      }

      setState(() {
        _kaynakDepo = sonuc.kaynakDepo;
        _depolar = sonuc.hedefDepolar;

        if (_depolar.length == 1) {
          _hedefDepo = _depolar.first;
        } else {
          final eskiDepoNo =
              _hedefDepo?.depoNo;

          if (eskiDepoNo != null &&
              _depolar.any(
                (x) =>
                    x.depoNo == eskiDepoNo,
              )) {
            _hedefDepo =
                _depolar.firstWhere(
              (x) =>
                  x.depoNo == eskiDepoNo,
            );
          } else {
            _hedefDepo = null;
          }
        }

        _stoklar.clear();
        _aramaController.clear();
      });
    } catch (e) {
      if (!mounted) return;

      _hataGoster(
        'Depolar getirilemedi.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _depolarYukleniyor = false;
        });
      }
    }
  }

  // ============================================================
  // ÜRÜN SEÇİM EKRANI
  // ============================================================

  Future<void> _stokSecimAc() async {
    if (_kaynakDepo == null) {
      _hataGoster(
        'Kaynak depo bulunamadı.',
      );
      return;
    }

    if (_hedefDepo == null) {
      _hataGoster(
        'Önce hedef depo seçmelisiniz.',
      );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    _aramaController.clear();

    setState(() {
      _stoklar.clear();
    });

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            Future<void> ara() async {
              FocusManager
                  .instance.primaryFocus
                  ?.unfocus();

              if (_stoklarYukleniyor) {
                return;
              }

              setState(() {
                _stoklarYukleniyor = true;
              });

              setSheetState(() {});

              try {
                final sonuc =
                    await _api.talepStokAra(
                  depoNo:
                      _kaynakDepo!.depoNo,
                  arama:
                      _aramaController.text.trim(),
                  sadeceDepodaOlanlar:
                      _sadeceDepodaOlanlar,
                );

                if (!mounted) return;

                setState(() {
                  _stoklar = sonuc;
                });

                setSheetState(() {});
              } catch (e) {
                if (!mounted) return;

                _hataGoster(
                  'Stoklar getirilemedi.\n$e',
                );
              } finally {
                if (mounted) {
                  setState(() {
                    _stoklarYukleniyor = false;
                  });

                  setSheetState(() {});
                }
              }
            }

            return SizedBox(
              height:
                  MediaQuery.of(context)
                          .size
                          .height *
                      .90,
              child: Column(
                children: [
                  // =================================================
                  // TUTMA ÇUBUĞU
                  // =================================================

                  const SizedBox(height: 8),

                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),

                  // =================================================
                  // BAŞLIK
                  // =================================================

                  Container(
                    height: 55,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment:
                              Alignment.center,
                          decoration:
                              BoxDecoration(
                            color: accent
                                .withOpacity(.09),
                            borderRadius:
                                BorderRadius.circular(
                                    9),
                          ),
                          child: const Icon(
                            Icons
                                .inventory_2_outlined,
                            size: 18,
                            color: accent,
                          ),
                        ),

                        const SizedBox(width: 9),

                        const Expanded(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Ürün Ekle',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Talep edilecek ürünü arayın',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: Colors
                                      .black45,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          tooltip: 'Kapat',
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                            );
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // =================================================
                  // ARAMA ALANI
                  // =================================================

                  Container(
                    color: Colors.white,
                    padding:
                        const EdgeInsets.fromLTRB(
                      10,
                      9,
                      10,
                      7,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 45,
                          child: TextField(
                            controller:
                                _aramaController,
                            autofocus: true,
                            textInputAction:
                                TextInputAction
                                    .search,
                            onSubmitted:
                                (_) => ara(),
                            style:
                                const TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                            decoration:
                                InputDecoration(
                              hintText:
                                  'Stok kodu veya adı ara...',
                              hintStyle:
                                  const TextStyle(
                                fontSize: 10,
                              ),
                              prefixIcon:
                                  const Icon(
                                Icons.search_rounded,
                                size: 19,
                              ),
                              suffixIcon:
                                  IconButton(
                                tooltip: 'Ara',
                                onPressed:
                                    _stoklarYukleniyor
                                        ? null
                                        : ara,
                                icon: const Icon(
                                  Icons
                                      .arrow_forward_rounded,
                                  color: accent,
                                  size: 19,
                                ),
                              ),
                              filled: true,
                              fillColor:
                                  const Color(
                                0xFFF5F6F8,
                              ),
                              isDense: true,
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(9),
                                borderSide:
                                    BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 3),

                        Row(
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: Checkbox(
                                value:
                                    _sadeceDepodaOlanlar,
                                activeColor:
                                    accent,
                                visualDensity:
                                    VisualDensity
                                        .compact,
                                onChanged:
                                    (value) {
                                  setState(() {
                                    _sadeceDepodaOlanlar =
                                        value ??
                                            true;
                                  });

                                  setSheetState(
                                    () {},
                                  );
                                },
                              ),
                            ),
                            const Text(
                              'Sadece stokta olan ürünler',
                              style: TextStyle(
                                fontSize: 9.5,
                                color:
                                    Colors.black54,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                            const Spacer(),

                            if (_stoklar.isNotEmpty)
                              Text(
                                '${_stoklar.length} sonuç',
                                style:
                                    const TextStyle(
                                  fontSize: 8.5,
                                  color: accent,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // =================================================
                  // SONUÇLAR
                  // =================================================

                  Expanded(
                    child: _stoklarYukleniyor
                        ? const Center(
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2.4,
                                  ),
                                ),
                                SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  'Ürünler aranıyor...',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        9.5,
                                    color: Colors
                                        .black45,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _stoklar.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisSize:
                                      MainAxisSize
                                          .min,
                                  children: [
                                    Icon(
                                      Icons
                                          .manage_search_rounded,
                                      size: 45,
                                      color: Colors
                                          .black26,
                                    ),
                                    SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                      'Ürün arayın',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            11,
                                        color: Colors
                                            .black45,
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      'Stok kodu veya ürün adıyla arama yapabilirsiniz.',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            8.5,
                                        color: Colors
                                            .black38,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior
                                        .onDrag,
                                padding:
                                    const EdgeInsets
                                        .fromLTRB(
                                  9,
                                  8,
                                  9,
                                  12,
                                ),
                                itemCount:
                                    _stoklar
                                        .length,
                                separatorBuilder:
                                    (_, __) =>
                                        const SizedBox(
                                  height: 5,
                                ),
                                itemBuilder:
                                    (context,
                                        index) {
                                  return _stokSecimKarti(
                                    _stoklar[
                                        index],
                                    setSheetState,
                                  );
                                },
                              ),
                  ),

                  // =================================================
                  // ALT TAMAM
                  // =================================================

                  SafeArea(
                    top: false,
                    child: Container(
                      color: Colors.white,
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        9,
                        7,
                        9,
                        7,
                      ),
                      child: SizedBox(
                        width:
                            double.infinity,
                        height: 43,
                        child:
                            FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                            );
                          },
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
                                          9),
                            ),
                          ),
                          icon: const Icon(
                            Icons
                                .check_rounded,
                            size: 17,
                          ),
                          label: Text(
                            _kalemler
                                    .isEmpty
                                ? 'TAMAM'
                                : '${_kalemler.length} ÜRÜN EKLENDİ • TAMAM',
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
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _stoklar.clear();
      _aramaController.clear();
    });
  }

  // ============================================================
  // STOK SEÇİM KARTI
  // ============================================================

  Widget _stokSecimKarti(
    DepoTalepStokModel stok,
    StateSetter setSheetState,
  ) {
    final index = _kalemler.indexWhere(
      (x) =>
          x.stokKodu
              .trim()
              .toUpperCase() ==
          stok.stokKodu
              .trim()
              .toUpperCase(),
    );

    final bool ekli = index >= 0;

    final double eklenenMiktar =
        ekli ? _kalemler[index].miktar : 0;

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(10),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(10),
        onTap: () async {
          await _stokEkle(stok);

          if (mounted) {
            setSheetState(() {});
          }
        },
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            8,
            7,
            7,
            7,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(10),
            border: Border.all(
              color: ekli
                  ? accent.withOpacity(.35)
                  : Colors.black
                      .withOpacity(.05),
              width: ekli ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color: accent
                      .withOpacity(.08),
                  borderRadius:
                      BorderRadius.circular(
                          8),
                ),
                child: Icon(
                  ekli
                      ? Icons
                          .check_rounded
                      : Icons
                          .inventory_2_outlined,
                  size: 18,
                  color: accent,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      stok.stokAdi,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 10.5,
                        height: 1.15,
                        fontWeight:
                            FontWeight
                                .w900,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      stok.stokKodu,
                      style:
                          const TextStyle(
                        fontSize: 8.5,
                        color: Colors
                            .black45,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),

                    if (ekli) ...[
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        'Eklenen: ${_miktarYaz(eklenenMiktar)} ${stok.birim}',
                        style:
                            const TextStyle(
                          fontSize: 8.5,
                          color: accent,
                          fontWeight:
                              FontWeight
                                  .w900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 5),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Depodaki',
                    style: TextStyle(
                      fontSize: 7.5,
                      color:
                          Colors.black38,
                    ),
                  ),
                  const SizedBox(
                    height: 1,
                  ),
                  Text(
                    '${_miktarYaz(stok.depodakiMiktar)} ${stok.birim}',
                    style:
                        const TextStyle(
                      fontSize: 9.5,
                      color: accent,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 7),

              Icon(
                ekli
                    ? Icons
                        .check_circle_rounded
                    : Icons
                        .add_circle_outline_rounded,
                color: accent,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STOK EKLE
  // ============================================================

  Future<void> _stokEkle(
    DepoTalepStokModel stok,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();

    String girilenMiktar = '';

    final miktar =
        await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
          titlePadding:
              const EdgeInsets.fromLTRB(
            16,
            14,
            16,
            0,
          ),
          contentPadding:
              const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            6,
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(
            8,
            0,
            8,
            8,
          ),
          title: Text(
            stok.stokAdi,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                stok.stokKodu,
                style:
                    const TextStyle(
                  fontSize: 9.5,
                  color:
                      Colors.black45,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 7,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF7F7F9,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(8),
                ),
                child: Text(
                  'Depodaki: '
                  '${_miktarYaz(stok.depodakiMiktar)} '
                  '${stok.birim}',
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color: accent,
                    fontWeight:
                        FontWeight
                            .w900,
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              TextFormField(
                autofocus: true,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter
                      .allow(
                    RegExp(
                      r'[0-9.,]',
                    ),
                  ),
                ],
                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w800,
                ),
                decoration:
                    InputDecoration(
                  labelText:
                      'Talep miktarı',
                  suffixText:
                      stok.birim,
                  isDense: true,
                  filled: true,
                  fillColor:
                      const Color(
                    0xFFF7F7F9,
                  ),
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(8),
                    borderSide:
                        BorderSide.none,
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(8),
                    borderSide:
                        BorderSide(
                      color: Colors
                          .black
                          .withOpacity(
                              .06),
                    ),
                  ),
                  focusedBorder:
                      const OutlineInputBorder(
                    borderRadius:
                        BorderRadius.all(
                      Radius.circular(
                          8),
                    ),
                    borderSide:
                        BorderSide(
                      color: accent,
                      width: 1.3,
                    ),
                  ),
                ),
                onChanged: (value) {
                  girilenMiktar =
                      value;
                },
                onFieldSubmitted:
                    (value) {
                  final deger =
                      _doubleOku(
                          value);

                  if (deger <= 0) {
                    return;
                  }

                  Navigator.of(
                          dialogContext)
                      .pop(deger);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                        dialogContext)
                    .pop();
              },
              child:
                  const Text(
                'VAZGEÇ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight
                          .w800,
                ),
              ),
            ),
            FilledButton(
              style:
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    accent,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(8),
                ),
              ),
              onPressed: () {
                final deger =
                    _doubleOku(
                  girilenMiktar,
                );

                if (deger <= 0) {
                  return;
                }

                Navigator.of(
                        dialogContext)
                    .pop(deger);
              },
              child:
                  const Text(
                'EKLE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight
                          .w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted ||
        miktar == null ||
        miktar <= 0) {
      return;
    }

    final stokKodu =
        stok.stokKodu
            .trim()
            .toUpperCase();

    final index =
        _kalemler.indexWhere(
      (e) =>
          e.stokKodu
              .trim()
              .toUpperCase() ==
          stokKodu,
    );

    setState(() {
      if (index >= 0) {
        final mevcut =
            _kalemler[index];

        _kalemler[index] =
            mevcut.copyWith(
          miktar:
              mevcut.miktar +
                  miktar,
        );
      } else {
        _kalemler.add(
          DepoTalepGirisKalemModel(
            stokKodu:
                stok.stokKodu,
            stokAdi:
                stok.stokAdi,
            miktar: miktar,
            birim: stok.birim,
            depodakiMiktar:
                stok.depodakiMiktar,
          ),
        );
      }
    });
  }

  // ============================================================
  // KALEM SİL
  // ============================================================

  void _kalemSil(
    int index,
  ) {
    if (index < 0 ||
        index >= _kalemler.length) {
      return;
    }

    setState(() {
      _kalemler.removeAt(index);
    });
  }

  // ============================================================
  // KALEM DÜZENLE
  // ============================================================

  Future<void> _kalemDuzenle(
    int index,
  ) async {
    if (index < 0 ||
        index >= _kalemler.length) {
      return;
    }

    final kalem =
        _kalemler[index];

    String girilen =
        _miktarYaz(
      kalem.miktar,
    );

    final miktar =
        await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
                    12),
          ),
          title: Text(
            kalem.stokAdi,
            style:
                const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          content:
              TextFormField(
            initialValue: girilen,
            autofocus: true,
            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter
                  .allow(
                RegExp(
                    r'[0-9.,]'),
              ),
            ],
            onChanged: (value) {
              girilen = value;
            },
            decoration:
                InputDecoration(
              labelText:
                  'Talep miktarı',
              suffixText:
                  kalem.birim,
              filled: true,
              fillColor:
                  const Color(
                0xFFF7F7F9,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius
                        .circular(8),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                    dialogContext);
              },
              child:
                  const Text(
                'VAZGEÇ',
              ),
            ),
            FilledButton(
              style:
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    accent,
              ),
              onPressed: () {
                final deger =
                    _doubleOku(
                        girilen);

                if (deger <= 0) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  deger,
                );
              },
              child:
                  const Text(
                'GÜNCELLE',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted ||
        miktar == null ||
        miktar <= 0) {
      return;
    }

    setState(() {
      _kalemler[index] =
          kalem.copyWith(
        miktar: miktar,
      );
    });
  }

  // ============================================================
  // KAYDET
  // ============================================================

  Future<void> _kaydet() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_oturumGecerli) {
      _hataGoster(
        'Oturum bilgisi geçersiz. Tekrar giriş yapın.',
      );
      return;
    }

    if (_kaynakDepo == null) {
      _hataGoster(
        'Kaynak depo bulunamadı.',
      );
      return;
    }

    if (_hedefDepo == null) {
      _hataGoster(
        'Hedef depo seçmelisiniz.',
      );
      return;
    }

    if (_kaynakDepo!.depoNo ==
        _hedefDepo!.depoNo) {
      _hataGoster(
        'Kaynak ve hedef depo aynı olamaz.',
      );
      return;
    }

    if (_kalemler.isEmpty) {
      _hataGoster(
        'En az bir ürün eklemelisiniz.',
      );
      return;
    }

    final onay =
        await _onaySor();

    if (!onay) return;

    setState(() {
      _kaydediliyor = true;
    });

    try {
      final sonuc =
          await _api.talepKaydet(
        DepoTalepKaydetModel(
          kaynakDepoNo:
              _kaynakDepo!.depoNo,
          hedefDepoNo:
              _hedefDepo!.depoNo,
          kullaniciKodu:
              widget.kullaniciKodu,
          oturumId:
              widget.oturumId,
          token:
              widget.token,
          kalemler:
              _kalemler
                  .map(
                    (e) =>
                        DepoTalepKaydetKalemModel(
                      stokKodu:
                          e.stokKodu,
                      miktar:
                          e.miktar,
                    ),
                  )
                  .toList(),
        ),
      );

      if (!mounted) return;

      _mesajGoster(
        sonuc.mesaj.isNotEmpty
            ? sonuc.mesaj
            : 'Depo talebi kaydedildi.',
      );

      setState(() {
        _kalemler.clear();
        _stoklar.clear();
        _aramaController.clear();
      });
    } catch (e) {
      if (!mounted) return;

      _hataGoster(
        'Talep kaydedilemedi.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _kaydediliyor = false;
        });
      }
    }
  }

  Future<bool> _onaySor() async {
    final sonuc =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
                    12),
          ),
          title:
              const Text(
            'Depo Talebi',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          content: Text(
            '${_kalemler.length} ürün için '
            'depo talebi oluşturulacak.\n\n'
            '${_kaynakDepo?.depoAdi ?? '-'}'
            ' → '
            '${_hedefDepo?.depoAdi ?? '-'}',
            style:
                const TextStyle(
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text(
                'VAZGEÇ',
              ),
            ),
            FilledButton(
              style:
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    accent,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text(
                'KAYDET',
              ),
            ),
          ],
        );
      },
    );

    return sonuc ?? false;
  }

  // ============================================================
  // MESAJLAR
  // ============================================================

  void _hataGoster(
    String mesaj,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              Colors.red.shade700,
          content: Text(
            mesaj,
            style:
                const TextStyle(
              fontSize: 11,
            ),
          ),
        ),
      );
  }

  void _mesajGoster(
    String mesaj,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              accent,
          content: Text(
            mesaj,
            style:
                const TextStyle(
              fontSize: 11,
            ),
          ),
        ),
      );
  }

  // ============================================================
  // FORMAT
  // ============================================================

  double _doubleOku(
    String? deger,
  ) {
    if (deger == null ||
        deger.trim().isEmpty) {
      return 0;
    }

    return double.tryParse(
          deger
              .trim()
              .replaceAll(
                ',',
                '.',
              ),
        ) ??
        0;
  }

  String _miktarYaz(
    double miktar,
  ) {
    if (miktar ==
        miktar.roundToDouble()) {
      return miktar
          .toInt()
          .toString();
    }

    return miktar
        .toStringAsFixed(3)
        .replaceFirst(
          RegExp(r'0+$'),
          '',
        )
        .replaceFirst(
          RegExp(r'\.$'),
          '',
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
        MediaQuery.textScalerOf(
                context)
            .clamp(
      maxScaleFactor: 1.06,
    );

    return MediaQuery(
      data:
          MediaQuery.of(context)
              .copyWith(
        textScaler: scaler,
      ),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          toolbarHeight: 48,
          elevation: 0,
          backgroundColor:
              Colors.white,
          surfaceTintColor:
              Colors.white,
          foregroundColor:
              Colors.black87,
          centerTitle: true,
          title:
              const Text(
            'Depo Talep Fişi',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Yenile',
              visualDensity:
                  VisualDensity.compact,
              onPressed:
                  _kaydediliyor
                      ? null
                      : _depolariGetir,
              icon:
                  const Icon(
                Icons
                    .refresh_rounded,
                size: 21,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            _icerik(),

            if (_kaydediliyor)
              Positioned.fill(
                child: Container(
                  color: Colors.black
                      .withOpacity(.12),
                  alignment:
                      Alignment.center,
                  child: Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(12),
                    ),
                    child:
                        const Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2.6,
                          ),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          'Talep kaydediliyor...',
                          style:
                              TextStyle(
                            fontSize:
                                10.5,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar:
            _altKaydetAlani(),
      ),
    );
  }

  // ============================================================
  // ANA İÇERİK
  // ============================================================

  Widget _icerik() {
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(
        9,
        8,
        9,
        14,
      ),
      children: [
        _depoSecimKarti(),

        const SizedBox(
          height: 8,
        ),

        // ÜRÜN EKLE BUTONU
        SizedBox(
          height: 46,
          width: double.infinity,
          child:
              FilledButton.icon(
            onPressed:
                _kaydediliyor ||
                        _hedefDepo ==
                            null
                    ? null
                    : _stokSecimAc,
            style:
                FilledButton
                    .styleFrom(
              backgroundColor:
                  accent,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(10),
              ),
            ),
            icon:
                const Icon(
              Icons
                  .add_shopping_cart_rounded,
              size: 18,
            ),
            label:
                const Text(
              'ÜRÜN EKLE',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        _eklenenlerBaslik(),

        const SizedBox(
          height: 5,
        ),

        if (_kalemler.isEmpty)
          _bosKalem()
        else
          ...List.generate(
            _kalemler.length,
            (index) =>
                Padding(
              padding:
                  const EdgeInsets
                      .only(
                bottom: 5,
              ),
              child:
                  _kalemKarti(
                _kalemler[
                    index],
                index,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // DEPO SEÇİMİ
  // ============================================================

  Widget _depoSecimKarti() {
    return Container(
      padding:
          const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black
              .withOpacity(.055),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons
                    .swap_horiz_rounded,
                color: accent,
                size: 18,
              ),
              const SizedBox(
                width: 6,
              ),
              const Text(
                'Depo Seçimi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (_depolarYukleniyor)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _sabitDepoKutusu(
                  baslik:
                      'Kaynak Depo',
                  depoAdi:
                      _kaynakDepo
                              ?.depoAdi ??
                          'Kırşehir Merkez Depo',
                  ikon: Icons
                      .warehouse_outlined,
                ),
              ),

              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                child: Icon(
                  Icons
                      .arrow_forward_rounded,
                  size: 17,
                  color:
                      Colors.black26,
                ),
              ),

              Expanded(
                child:
                    _hedefDepoDropdown(),
              ),
            ],
          ),

          if (!_depolarYukleniyor &&
              _depolar.isEmpty) ...[
            const SizedBox(
              height: 7,
            ),
            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.orange
                    .withOpacity(.08),
                borderRadius:
                    BorderRadius
                        .circular(8),
                border: Border.all(
                  color: Colors.orange
                      .withOpacity(.15),
                ),
              ),
              child:
                  const Row(
                children: [
                  Icon(
                    Icons
                        .info_outline_rounded,
                    size: 15,
                    color:
                        Colors.orange,
                  ),
                  SizedBox(
                    width: 6,
                  ),
                  Expanded(
                    child: Text(
                      'Bu kullanıcı için hedef sera deposu tanımlı değil.',
                      style:
                          TextStyle(
                        fontSize: 9,
                        color: Colors
                            .black54,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sabitDepoKutusu({
    required String baslik,
    required String depoAdi,
    required IconData ikon,
  }) {
    return Container(
      height: 55,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F7F9),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black
              .withOpacity(.045),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ikon,
            size: 16,
            color: accent,
          ),
          const SizedBox(
            width: 5,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  baslik,
                  style:
                      const TextStyle(
                    fontSize: 8.5,
                    color: Colors
                        .black38,
                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),
                const SizedBox(
                  height: 1,
                ),
                Text(
                  depoAdi,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight
                            .w900,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons
                .lock_outline_rounded,
            size: 13,
            color:
                Colors.black26,
          ),
        ],
      ),
    );
  }

  Widget _hedefDepoDropdown() {
    return Container(
      height: 55,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F7F9),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black
              .withOpacity(.045),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons
                .location_on_outlined,
            size: 16,
            color: accent,
          ),
          const SizedBox(
            width: 5,
          ),
          Expanded(
            child:
                DropdownButtonHideUnderline(
              child: DropdownButton<
                  DepoTalepDepoModel>(
                value:
                    _hedefDepo,
                isExpanded: true,
                hint:
                    const Text(
                  'Hedef Depo',
                  style:
                      TextStyle(
                    fontSize: 9.5,
                    color: Colors
                        .black45,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
                items:
                    _depolar
                        .map(
                          (depo) =>
                              DropdownMenuItem<
                                  DepoTalepDepoModel>(
                            value:
                                depo,
                            child:
                                Text(
                              depo.depoAdi,
                              maxLines:
                                  1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize:
                                    10,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                onChanged:
                    _kaydediliyor ||
                            _depolarYukleniyor
                        ? null
                        : (value) {
                            setState(
                              () {
                                _hedefDepo =
                                    value;
                              },
                            );
                          },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TALEP KALEMLERİ BAŞLIK
  // ============================================================

  Widget _eklenenlerBaslik() {
    return Row(
      children: [
        const Icon(
          Icons
              .format_list_bulleted_rounded,
          size: 17,
          color: accent,
        ),
        const SizedBox(
          width: 5,
        ),
        const Text(
          'Talep Kalemleri',
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 7,
            vertical: 3,
          ),
          decoration:
              BoxDecoration(
            color: accent
                .withOpacity(.08),
            borderRadius:
                BorderRadius.circular(
                    6),
          ),
          child: Text(
            '${_kalemler.length} kalem',
            style:
                const TextStyle(
              fontSize: 8.8,
              color: accent,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOŞ
  // ============================================================

  Widget _bosKalem() {
    return Container(
      height: 110,
      alignment:
          Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black
              .withOpacity(.055),
        ),
      ),
      child:
          const Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons
                .playlist_add_outlined,
            size: 32,
            color:
                Colors.black26,
          ),
          SizedBox(
            height: 6,
          ),
          Text(
            'Henüz ürün eklenmedi',
            style:
                TextStyle(
              fontSize: 10.5,
              color:
                  Colors.black45,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          SizedBox(
            height: 2,
          ),
          Text(
            'Yukarıdaki Ürün Ekle butonunu kullanın.',
            style:
                TextStyle(
              fontSize: 8.5,
              color:
                  Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KALEM KARTI
  // ============================================================

  Widget _kalemKarti(
    DepoTalepGirisKalemModel kalem,
    int index,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black
              .withOpacity(.055),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets
                    .fromLTRB(
              8,
              7,
              5,
              6,
            ),
            child: Row(
              children: [
                Container(
                  width: 27,
                  height: 27,
                  alignment:
                      Alignment.center,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFF7F7F9,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(7),
                  ),
                  child: Text(
                    '${index + 1}',
                    style:
                        const TextStyle(
                      fontSize: 8.5,
                      color: Colors
                          .black45,
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        kalem.stokAdi,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight
                                  .w900,
                        ),
                      ),
                      const SizedBox(
                        height: 1,
                      ),
                      Text(
                        kalem.stokKodu,
                        style:
                            const TextStyle(
                          fontSize: 8.5,
                          color: Colors
                              .black45,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip:
                      'Düzenle',
                  visualDensity:
                      VisualDensity
                          .compact,
                  onPressed:
                      _kaydediliyor
                          ? null
                          : () =>
                              _kalemDuzenle(
                                index,
                              ),
                  icon:
                      const Icon(
                    Icons
                        .edit_outlined,
                    size: 17,
                    color: accent,
                  ),
                ),

                IconButton(
                  tooltip: 'Sil',
                  visualDensity:
                      VisualDensity
                          .compact,
                  onPressed:
                      _kaydediliyor
                          ? null
                          : () =>
                              _kalemSil(
                                index,
                              ),
                  icon: Icon(
                    Icons
                        .delete_outline_rounded,
                    size: 18,
                    color: Colors
                        .red.shade600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 40,
            margin:
                const EdgeInsets
                    .fromLTRB(
              7,
              0,
              7,
              7,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF7F7F9,
              ),
              borderRadius:
                  BorderRadius
                      .circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      _miniMiktar(
                    baslik:
                        'Depodaki',
                    miktar: kalem
                        .depodakiMiktar,
                    birim:
                        kalem.birim,
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.black
                      .withOpacity(.05),
                ),
                Expanded(
                  child:
                      _miniMiktar(
                    baslik:
                        'Talep',
                    miktar:
                        kalem.miktar,
                    birim:
                        kalem.birim,
                    vurgu: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMiktar({
    required String baslik,
    required double miktar,
    required String birim,
    bool vurgu = false,
  }) {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Text(
          baslik,
          style:
              const TextStyle(
            fontSize: 7.8,
            color:
                Colors.black38,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        const SizedBox(
          height: 1,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${_miktarYaz(miktar)} $birim',
            maxLines: 1,
            style: TextStyle(
              fontSize: 10,
              color: vurgu
                  ? accent
                  : Colors.black87,
              fontWeight: vurgu
                  ? FontWeight.w900
                  : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ALT KAYDET
  // ============================================================

  Widget _altKaydetAlani() {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding:
            const EdgeInsets.fromLTRB(
          7,
          6,
          7,
          6,
        ),
        child: SizedBox(
          height: 44,
          width: double.infinity,
          child:
              FilledButton.icon(
            onPressed:
                _kaydediliyor ||
                        _kalemler
                            .isEmpty
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
                        .circular(9),
              ),
            ),
            icon:
                const Icon(
              Icons.save_outlined,
              size: 17,
            ),
            label: Text(
              _kalemler.isEmpty
                  ? 'ÜRÜN EKLEYİN'
                  : '${_kalemler.length} ÜRÜNÜ KAYDET',
              style:
                  const TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}