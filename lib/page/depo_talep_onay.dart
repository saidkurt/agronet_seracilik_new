import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:agronet/api/depo_talep_api.dart';
import 'package:agronet/models/depo_talep_model.dart';

class DepoTalepOnayPage extends StatefulWidget {
  final String kullaniciKodu;
  final int oturumId;
  final String token;

  const DepoTalepOnayPage({
    super.key,
    required this.kullaniciKodu,
    required this.oturumId,
    required this.token,
  });

  @override
  State<DepoTalepOnayPage> createState() =>
      _DepoTalepOnayPageState();
}

class _DepoTalepOnayPageState
    extends State<DepoTalepOnayPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  final DepoTalepApi _api = DepoTalepApi();

  List<DepoTalepEvrakModel> _evraklar = [];

  DepoTalepEvrakModel? _secilenEvrak;
  DepoTalepDetayModel? _detay;

  final Map<String, bool> _secimler = {};
  final Map<String, TextEditingController>
      _miktarControllerlari = {};

  bool _evraklarYukleniyor = false;
  bool _detayYukleniyor = false;
  bool _islemYapiliyor = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _evraklariGetir();
  }

  @override
  void dispose() {
    _controllerlariTemizle();
    super.dispose();
  }

  // ============================================================
  // CONTROLLER
  // ============================================================

  void _controllerlariTemizle() {
    for (final controller
        in _miktarControllerlari.values) {
      controller.dispose();
    }

    _miktarControllerlari.clear();
    _secimler.clear();
  }

  // ============================================================
  // EVRAKLAR
  // ============================================================

  Future<void> _evraklariGetir() async {
    setState(() {
      _evraklarYukleniyor = true;
    });

    try {
      final sonuc =
          await _api.talepEvraklariGetir();

      if (!mounted) return;

      setState(() {
        _evraklar = sonuc;
      });
    } catch (e) {
      if (!mounted) return;

      _hataGoster(
        'Evraklar getirilemedi.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _evraklarYukleniyor = false;
        });
      }
    }
  }

  // ============================================================
  // EVRAK SEÇ
  // ============================================================

  Future<void> _evrakSec(
    DepoTalepEvrakModel evrak,
  ) async {
    final seri = evrak.seri ?? '';
    final sira = evrak.sira ?? 0;

    if (sira <= 0) {
      _hataGoster(
        'Evrak sıra numarası geçersiz.',
      );
      return;
    }

    setState(() {
      _secilenEvrak = evrak;
      _detay = null;
      _detayYukleniyor = true;
    });

    _controllerlariTemizle();

    try {
      final sonuc =
          await _api.talepDetayGetir(
        seri: seri,
        sira: sira,
      );

      if (!mounted) return;

      if (sonuc == null) {
        _hataGoster(
          'Evrak detayı bulunamadı.',
        );

        setState(() {
          _secilenEvrak = null;
        });

        return;
      }

      _detay = sonuc;

      for (final kalem
          in sonuc.kalemler ??
              <DepoTalepKalemModel>[]) {
        final guid = kalem.guid ?? '';

        if (guid.isEmpty) {
          continue;
        }

        _secimler[guid] = false;

        _miktarControllerlari[guid] =
            TextEditingController(
          text: '0',
        );
      }

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      _hataGoster(
        'Evrak detayı getirilemedi.\n$e',
      );

      setState(() {
        _secilenEvrak = null;
        _detay = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _detayYukleniyor = false;
        });
      }
    }
  }

  // ============================================================
  // EVRAKTAN ÇIK
  // ============================================================

  void _evraktanCik() {
    FocusManager.instance.primaryFocus?.unfocus();

    _controllerlariTemizle();

    setState(() {
      _secilenEvrak = null;
      _detay = null;
    });
  }

  // ============================================================
  // KALEM SEÇ
  // ============================================================

  void _kalemSec(
    DepoTalepKalemModel kalem,
    bool secildi,
  ) {
    final guid = kalem.guid ?? '';

    if (guid.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _secimler[guid] = secildi;

      final controller =
          _miktarControllerlari[guid];

      if (secildi) {
        controller?.text =
            _miktarYaz(
          kalem.kalanMiktar ?? 0,
        );
      } else {
        controller?.text = '0';
      }
    });
  }

  void _tumunuSec() {
    final kalemler =
        _detay?.kalemler ??
            <DepoTalepKalemModel>[];

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      for (final kalem in kalemler) {
        final guid = kalem.guid ?? '';

        if (guid.isEmpty) continue;

        _secimler[guid] = true;

        _miktarControllerlari[guid]
                ?.text =
            _miktarYaz(
          kalem.kalanMiktar ?? 0,
        );
      }
    });
  }

  void _tumunuKaldir() {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      for (final guid in _secimler.keys) {
        _secimler[guid] = false;
        _miktarControllerlari[guid]
            ?.text = '0';
      }
    });
  }

  bool get _tumKalemlerSecili {
    final kalemler =
        _detay?.kalemler ??
            <DepoTalepKalemModel>[];

    if (kalemler.isEmpty) {
      return false;
    }

    return kalemler.every(
      (kalem) {
        final guid = kalem.guid ?? '';

        return guid.isNotEmpty &&
            (_secimler[guid] ?? false);
      },
    );
  }

  int get _secilenKalemSayisi {
    return _secimler.values
        .where((x) => x)
        .length;
  }

  bool get _oturumGecerli {
    return widget.kullaniciKodu
            .trim()
            .isNotEmpty &&
        widget.oturumId > 0 &&
        widget.token.trim().isNotEmpty;
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

    if (_detay == null ||
        _secilenEvrak == null) {
      _hataGoster(
        'Önce evrak seçmelisiniz.',
      );
      return;
    }

    final List<DepoTalepOnayKalemModel>
        onayKalemleri = [];

    for (final kalem
        in _detay!.kalemler ??
            <DepoTalepKalemModel>[]) {
      final guid = kalem.guid ?? '';

      if (guid.isEmpty ||
          !(_secimler[guid] ?? false)) {
        continue;
      }

      final miktar = _doubleOku(
        _miktarControllerlari[guid]
            ?.text,
      );

      final kalanMiktar =
          kalem.kalanMiktar ?? 0;

      if (miktar <= 0) {
        _hataGoster(
          '${kalem.stokAdi ?? kalem.stokKodu ?? 'Ürün'} için '
          'kabul miktarı sıfırdan büyük olmalıdır.',
        );
        return;
      }

      if (miktar > kalanMiktar) {
        _hataGoster(
          '${kalem.stokAdi ?? kalem.stokKodu ?? 'Ürün'} için '
          'kabul miktarı kalan miktarı geçemez.',
        );
        return;
      }

      onayKalemleri.add(
        DepoTalepOnayKalemModel(
          guid: guid,
          kabulMiktar: miktar,
        ),
      );
    }

    if (onayKalemleri.isEmpty) {
      _hataGoster(
        'En az bir ürün seçmelisiniz.',
      );
      return;
    }

    final onay = await _onaySor(
      baslik: 'Talebi Onayla',
      mesaj:
          '${onayKalemleri.length} ürün için kabul işlemi kaydedilecek.',
      onayMetni: 'KAYDET',
    );

    if (!onay) return;

    setState(() {
      _islemYapiliyor = true;
    });

    try {
      final sonuc =
          await _api.talepOnayla(
        DepoTalepOnayRequestModel(
          seri: _detay!.seri ??
              _secilenEvrak!.seri ??
              '',
          sira: _detay!.sira ??
              _secilenEvrak!.sira,
          kullaniciKodu:
              widget.kullaniciKodu,
          oturumId:
              widget.oturumId,
          token: widget.token,
          kalemler: onayKalemleri,
        ),
      );

      if (!mounted) return;

      if (sonuc.basarili == false) {
        _hataGoster(
          sonuc.mesaj ??
              'İşlem başarısız.',
        );
        return;
      }

      _mesajGoster(
        sonuc.mesaj ??
            'Talep başarıyla onaylandı.',
      );

      final secili =
          _secilenEvrak;

      await _evraklariGetir();

      if (!mounted) return;

      if (secili != null) {
        final halaAcik =
            _evraklar.any(
          (e) =>
              e.seri == secili.seri &&
              e.sira == secili.sira,
        );

        if (halaAcik) {
          final guncelEvrak =
              _evraklar.firstWhere(
            (e) =>
                e.seri ==
                    secili.seri &&
                e.sira ==
                    secili.sira,
          );

          await _evrakSec(
            guncelEvrak,
          );
        } else {
          _evraktanCik();
        }
      }
    } catch (e) {
      if (!mounted) return;

      _hataGoster(
        'Kayıt işlemi başarısız.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _islemYapiliyor = false;
        });
      }
    }
  }

  // ============================================================
  // KALANI KAPAT
  // ============================================================

  Future<void> _kalaniKapat() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_oturumGecerli) {
      _hataGoster(
        'Oturum bilgisi geçersiz. Tekrar giriş yapın.',
      );
      return;
    }

    if (_detay == null ||
        _secilenEvrak == null) {
      _hataGoster(
        'Önce evrak seçmelisiniz.',
      );
      return;
    }

    final onay = await _onaySor(
      baslik: 'Kalanı Kapat',
      mesaj:
          'Bu evrakta teslim edilmemiş tüm kalan miktarlar iptal edilecek. Bu işlem geri alınamaz.',
      onayMetni: 'KALANI KAPAT',
      tehlikeli: true,
    );

    if (!onay) return;

    setState(() {
      _islemYapiliyor = true;
    });

    try {
      final sonuc =
          await _api.talepKalaniKapat(
        DepoTalepKapatRequestModel(
          seri: _detay!.seri ??
              _secilenEvrak!.seri ??
              '',
          sira: _detay!.sira ??
              _secilenEvrak!.sira,
          kullaniciKodu:
              widget.kullaniciKodu,
          oturumId:
              widget.oturumId,
          token:
              widget.token,
        ),
      );

      if (!mounted) return;

      if (sonuc.basarili == false) {
        _hataGoster(
          sonuc.mesaj ??
              'İşlem başarısız.',
        );
        return;
      }

      _mesajGoster(
        sonuc.mesaj ??
            'Evrakın kalan kısmı kapatıldı.',
      );

      _evraktanCik();
      await _evraklariGetir();
    } catch (e) {
      if (!mounted) return;

      _hataGoster(
        'Kalanı kapatma işlemi başarısız.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _islemYapiliyor = false;
        });
      }
    }
  }

  // ============================================================
  // ONAY
  // ============================================================

  Future<bool> _onaySor({
    required String baslik,
    required String mesaj,
    required String onayMetni,
    bool tehlikeli = false,
  }) async {
    final sonuc =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
          title: Text(
            baslik,
            style: const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          content: Text(
            mesaj,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.35,
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
              child: const Text(
                'VAZGEÇ',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    tehlikeli
                        ? Colors.red.shade700
                        : accent,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: Text(
                onayMetni,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    return sonuc ?? false;
  }

  // ============================================================
  // MESAJ
  // ============================================================

  void _hataGoster(
    String mesaj,
  ) {
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
            style: const TextStyle(
              fontSize: 11,
            ),
          ),
        ),
      );
  }

  void _mesajGoster(
    String mesaj,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: accent,
          content: Text(
            mesaj,
            style: const TextStyle(
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
              .replaceAll(',', '.'),
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

  String _tarihYaz(
    DateTime? tarih,
  ) {
    if (tarih == null) {
      return '-';
    }

    final gun =
        tarih.day
            .toString()
            .padLeft(2, '0');

    final ay =
        tarih.month
            .toString()
            .padLeft(2, '0');

    return '$gun.$ay.${tarih.year}';
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

          leading:
              _secilenEvrak != null
                  ? IconButton(
                      visualDensity:
                          VisualDensity
                              .compact,
                      onPressed:
                          _islemYapiliyor
                              ? null
                              : _evraktanCik,
                      icon:
                          const Icon(
                        Icons
                            .arrow_back_rounded,
                        size: 21,
                      ),
                    )
                  : null,

          title: Text(
            _secilenEvrak == null
                ? 'Depo Talep Onay'
                : _secilenEvrak!
                        .evrakNo ??
                    'Evrak Detayı',
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          actions: [
            IconButton(
              visualDensity:
                  VisualDensity.compact,
              tooltip: 'Yenile',
              onPressed:
                  _islemYapiliyor
                      ? null
                      : () async {
                          if (_secilenEvrak ==
                              null) {
                            await _evraklariGetir();
                          } else {
                            await _evrakSec(
                              _secilenEvrak!,
                            );
                          }
                        },
              icon: const Icon(
                Icons.refresh_rounded,
                size: 21,
              ),
            ),
          ],
        ),

        body: Stack(
          children: [
            if (_secilenEvrak ==
                null)
              _evrakListesi()
            else
              _evrakDetayi(),

            if (_islemYapiliyor)
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
                          'İşlem yapılıyor...',
                          style:
                              TextStyle(
                            fontSize: 10.5,
                            fontWeight:
                                FontWeight.w700,
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
            _secilenEvrak != null &&
                    _detay != null
                ? _altIslemAlani()
                : null,
      ),
    );
  }

  // ============================================================
  // EVRAK LİSTESİ
  // ============================================================

  Widget _evrakListesi() {
    return RefreshIndicator(
      color: accent,
      onRefresh: _evraklariGetir,
      child: _evraklarYukleniyor
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _evraklar.isEmpty
              ? _bosEvrak()
              : ListView.separated(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    10,
                    8,
                    10,
                    14,
                  ),
                  itemCount:
                      _evraklar.length,
                  separatorBuilder:
                      (_, __) =>
                          const SizedBox(
                    height: 6,
                  ),
                  itemBuilder:
                      (context, index) {
                    return _evrakKarti(
                      _evraklar[
                          index],
                    );
                  },
                ),
    );
  }

  Widget _bosEvrak() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(
          Icons.inventory_2_outlined,
          size: 46,
          color: Colors.black26,
        ),
        SizedBox(height: 9),
        Text(
          'Açık depo talep evrakı bulunamadı',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black45,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EVRAK KARTI
  // ============================================================

  Widget _evrakKarti(
    DepoTalepEvrakModel evrak,
  ) {
    final evrakNo =
        evrak.evrakNo ??
            '${evrak.seri ?? ''}-${evrak.sira ?? 0}';

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(10),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(10),
        onTap: () =>
            _evrakSec(evrak),
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            9,
            8,
            7,
            8,
          ),
          decoration:
              BoxDecoration(
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
                  Container(
                    width: 38,
                    height: 38,
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
                    child: Text(
                      '${evrak.kalemSayisi ?? 0}',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color: accent,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),

                  const SizedBox(
                      width: 8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          evrakNo,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize:
                                12.5,
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          _tarihYaz(
                            evrak.tarih,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 9.5,
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

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 6,
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
                      '${evrak.kalemSayisi ?? 0} kalem',
                      style:
                          const TextStyle(
                        fontSize: 8.8,
                        color: accent,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),

                  const SizedBox(
                      width: 2),

                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    size: 19,
                    color:
                        Colors.black26,
                  ),
                ],
              ),

              const SizedBox(
                height: 7,
              ),

              Container(
                height: 39,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 7,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF7F7F9,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                          8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          _depoMini(
                        'Kaynak',
                        evrak.kaynakDepo ??
                            '-',
                        Icons
                            .warehouse_outlined,
                      ),
                    ),

                    const Icon(
                      Icons
                          .arrow_forward_rounded,
                      size: 15,
                      color:
                          Colors.black26,
                    ),

                    Expanded(
                      child:
                          _depoMini(
                        'Hedef',
                        evrak.hedefDepo ??
                            '-',
                        Icons
                            .location_on_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _depoMini(
    String baslik,
    String deger,
    IconData ikon,
  ) {
    return Row(
      children: [
        Icon(
          ikon,
          size: 14,
          color: accent,
        ),

        const SizedBox(width: 4),

        Expanded(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
              Text(
                deger,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontSize: 9.5,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EVRAK DETAY
  // ============================================================

  Widget _evrakDetayi() {
    if (_detayYukleniyor) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_detay == null) {
      return const Center(
        child: Text(
          'Evrak detayı bulunamadı.',
        ),
      );
    }

    final kalemler =
        _detay!.kalemler ??
            <DepoTalepKalemModel>[];

    return Column(
      children: [
        _evrakUstBilgi(),

        Container(
          height: 40,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
          ),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${kalemler.length} ürün  •  '
                  '$_secilenKalemSayisi seçili',
                  style:
                      const TextStyle(
                    fontSize: 10.5,
                    color:
                        Colors.black54,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              TextButton.icon(
                style:
                    TextButton.styleFrom(
                  visualDensity:
                      VisualDensity
                          .compact,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 5,
                  ),
                  foregroundColor:
                      accent,
                ),
                onPressed:
                    _tumKalemlerSecili
                        ? _tumunuKaldir
                        : _tumunuSec,
                icon: Icon(
                  _tumKalemlerSecili
                      ? Icons
                          .deselect_rounded
                      : Icons
                          .select_all_rounded,
                  size: 16,
                ),
                label: Text(
                  _tumKalemlerSecili
                      ? 'Kaldır'
                      : 'Tümünü Seç',
                  style:
                      const TextStyle(
                    fontSize: 9.5,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: kalemler.isEmpty
              ? const Center(
                  child: Text(
                    'Açık ürün bulunamadı.',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.black45,
                    ),
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    9,
                    6,
                    9,
                    12,
                  ),
                  itemCount:
                      kalemler.length,
                  separatorBuilder:
                      (_, __) =>
                          const SizedBox(
                    height: 5,
                  ),
                  itemBuilder:
                      (context, index) {
                    return _urunKarti(
                      kalemler[
                          index],
                      index,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================
  // ÜST EVRAK BİLGİ
  // ============================================================

  Widget _evrakUstBilgi() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        9,
        7,
        9,
        8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration:
                    BoxDecoration(
                  color:
                      accent.withOpacity(.09),
                  borderRadius:
                      BorderRadius.circular(
                          8),
                ),
                child: const Icon(
                  Icons
                      .receipt_long_outlined,
                  size: 17,
                  color: accent,
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child: Text(
                  _detay!.evrakNo ??
                      _secilenEvrak!
                          .evrakNo ??
                      '-',
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

              Text(
                _tarihYaz(
                  _detay!.tarih,
                ),
                style:
                    const TextStyle(
                  fontSize: 9.5,
                  color:
                      Colors.black45,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 6,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _depoBilgiKutusu(
                  baslik:
                      'Kaynak Depo',
                  deger:
                      _detay!.kaynakDepo ??
                          '-',
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
                    _depoBilgiKutusu(
                  baslik:
                      'Hedef Depo',
                  deger:
                      _detay!.hedefDepo ??
                          '-',
                  ikon: Icons
                      .location_on_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _depoBilgiKutusu({
    required String baslik,
    required String deger,
    required IconData ikon,
  }) {
    return Container(
      height: 46,
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
          color:
              Colors.black.withOpacity(.045),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ikon,
            size: 16,
            color: accent,
          ),

          const SizedBox(width: 5),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style:
                      const TextStyle(
                    fontSize: 8.5,
                    color:
                        Colors.black38,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                Text(
                  deger,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ÜRÜN KARTI
  // ============================================================

  Widget _urunKarti(
    DepoTalepKalemModel kalem,
    int index,
  ) {
    final guid =
        kalem.guid ?? '';

    final secili =
        _secimler[guid] ?? false;

    final kalanMiktar =
        kalem.kalanMiktar ?? 0;

    final controller =
        _miktarControllerlari[guid];

    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 120,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: secili
              ? accent.withOpacity(.55)
              : Colors.black
                  .withOpacity(.055),
          width: secili ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius:
                BorderRadius.circular(10),
            onTap: guid.isEmpty
                ? null
                : () {
                    _kalemSec(
                      kalem,
                      !secili,
                    );
                  },
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                4,
                6,
                7,
                6,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child:
                        Checkbox(
                      value: secili,
                      visualDensity:
                          VisualDensity
                              .compact,
                      activeColor:
                          accent,
                      onChanged:
                          guid.isEmpty
                              ? null
                              : (value) {
                                  _kalemSec(
                                    kalem,
                                    value ??
                                        false,
                                  );
                                },
                    ),
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          kalem.stokAdi ??
                              'Stok adı yok',
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
                          kalem.stokKodu ??
                              '-',
                          style:
                              const TextStyle(
                            fontSize: 8.8,
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

                  Container(
                    width: 24,
                    height: 24,
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
                              .circular(6),
                    ),
                    child: Text(
                      '${index + 1}',
                      style:
                          const TextStyle(
                        fontSize: 8.5,
                        color:
                            Colors.black45,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            height: 44,
            margin:
                const EdgeInsets.fromLTRB(
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
                  BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      _miktarBilgisi(
                    baslik: 'Talep',
                    miktar:
                        kalem.talepMiktari ??
                            0,
                    birim:
                        kalem.birim,
                  ),
                ),

                _inceCizgi(),

                Expanded(
                  child:
                      _miktarBilgisi(
                    baslik: 'Teslim',
                    miktar:
                        kalem.teslimMiktari ??
                            0,
                    birim:
                        kalem.birim,
                  ),
                ),

                _inceCizgi(),

                Expanded(
                  child:
                      _miktarBilgisi(
                    baslik: 'Kalan',
                    miktar:
                        kalanMiktar,
                    birim:
                        kalem.birim,
                    kalin: true,
                  ),
                ),
              ],
            ),
          ),

          if (secili)
            Container(
              padding:
                  const EdgeInsets.fromLTRB(
                7,
                0,
                7,
                7,
              ),
              child: Row(
                children: [
                  Expanded(
                    child:
                        SizedBox(
                      height: 43,
                      child:
                          TextField(
                        controller:
                            controller,
                        enabled:
                            !_islemYapiliyor,
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
                          fontSize: 12,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                        decoration:
                            InputDecoration(
                          labelText:
                              'Kabul miktarı',
                          labelStyle:
                              const TextStyle(
                            fontSize: 9.5,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                          suffixText:
                              kalem.birim ??
                                  '',
                          suffixStyle:
                              const TextStyle(
                            fontSize: 9,
                          ),
                          isDense: true,
                          filled: true,
                          fillColor:
                              const Color(
                            0xFFF7F7F9,
                          ),
                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 9,
                            vertical: 10,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    8),
                            borderSide:
                                BorderSide.none,
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    8),
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
                              color:
                                  accent,
                              width:
                                  1.3,
                            ),
                          ),
                        ),
                        onChanged:
                            (_) {
                          setState(
                              () {});
                        },
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  SizedBox(
                    height: 43,
                    child:
                        OutlinedButton(
                      style:
                          OutlinedButton
                              .styleFrom(
                        foregroundColor:
                            accent,
                        side: BorderSide(
                          color: accent
                              .withOpacity(
                                  .30),
                        ),
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              10,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  8),
                        ),
                      ),
                      onPressed:
                          _islemYapiliyor
                              ? null
                              : () {
                                  controller
                                          ?.text =
                                      _miktarYaz(
                                    kalanMiktar,
                                  );

                                  setState(
                                      () {});
                                },
                      child:
                          const Text(
                        'TAMAMI',
                        style:
                            TextStyle(
                          fontSize:
                              9.5,
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
        ],
      ),
    );
  }

  Widget _inceCizgi() {
    return Container(
      width: 1,
      height: 25,
      color:
          Colors.black.withOpacity(.05),
    );
  }

  // ============================================================
  // ALT İŞLEM
  // ============================================================

  Widget _altIslemAlani() {
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
        child: Row(
          children: [
            SizedBox(
              height: 42,
              child:
                  OutlinedButton.icon(
                onPressed:
                    _islemYapiliyor
                        ? null
                        : _kalaniKapat,
                style:
                    OutlinedButton
                        .styleFrom(
                  foregroundColor:
                      Colors.red.shade700,
                  side: BorderSide(
                    color: Colors.red
                        .withOpacity(.25),
                  ),
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 8,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            9),
                  ),
                ),
                icon: const Icon(
                  Icons.block_rounded,
                  size: 16,
                ),
                label: const Text(
                  'KAPAT',
                  style:
                      TextStyle(
                    fontSize: 9.5,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 6,
            ),

            Expanded(
              child: SizedBox(
                height: 42,
                child:
                    FilledButton.icon(
                  onPressed:
                      _islemYapiliyor ||
                              _secilenKalemSayisi ==
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
                          BorderRadius.circular(
                              9),
                    ),
                  ),
                  icon: const Icon(
                    Icons
                        .save_outlined,
                    size: 17,
                  ),
                  label: Text(
                    _secilenKalemSayisi ==
                            0
                        ? 'ÜRÜN SEÇİN'
                        : '$_secilenKalemSayisi ÜRÜNÜ KAYDET',
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
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MİKTAR
  // ============================================================

  Widget _miktarBilgisi({
    required String baslik,
    required double miktar,
    String? birim,
    bool kalin = false,
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
            '${_miktarYaz(miktar)} ${birim ?? ''}',
            maxLines: 1,
            style:
                TextStyle(
              fontSize: 10,
              color: kalin
                  ? accent
                  : Colors.black87,
              fontWeight: kalin
                  ? FontWeight.w900
                  : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}