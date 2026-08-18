import 'package:flutter/material.dart';

import 'package:agronet/api/depo_talep_api.dart';
import 'package:agronet/models/depo_talep_model.dart';

class TalepDetayPage extends StatefulWidget {
  final String seri;
  final int sira;

  const TalepDetayPage({
    super.key,
    required this.seri,
    required this.sira,
  });

  @override
  State<TalepDetayPage> createState() =>
      _TalepDetayPageState();
}

class _TalepDetayPageState
    extends State<TalepDetayPage> {
  static const Color accent =
      Color(0xFF1E6F5C);

  static const Color bg =
      Color(0xFFF5F6F8);

  final DepoTalepApi _api =
      DepoTalepApi();

  DepoTalepBildirimDetayModel? _detay;

  bool _yukleniyor = true;

  String? _hata;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _detayGetir();
  }

  // ============================================================
  // DETAY GETİR
  // ============================================================

  Future<void> _detayGetir() async {
    if (mounted) {
      setState(() {
        _yukleniyor = true;
        _hata = null;
      });
    }

    try {
      final sonuc =
          await _api
              .talepBildirimDetayGetir(
        seri: widget.seri,
        sira: widget.sira,
      );

      if (!mounted) return;

      if (sonuc == null) {
        setState(() {
          _detay = null;
          _yukleniyor = false;
          _hata =
              'Talep bilgisi bulunamadı.';
        });

        return;
      }

      setState(() {
        _detay = sonuc;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _detay = null;
        _yukleniyor = false;
        _hata = _hataTemizle(e);
      });
    }
  }

  String _hataTemizle(
    Object hata,
  ) {
    var text =
        hata.toString();

    if (text.startsWith(
      'Exception: ',
    )) {
      text = text.substring(
        'Exception: '.length,
      );
    }

    return text;
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

        // ========================================================
        // APP BAR
        // ========================================================

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

          title: Text(
            _detay?.gorunenEvrakNo ??
                'Talep Detayı',
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
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
                  _yukleniyor
                      ? null
                      : _detayGetir,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 21,
              ),
            ),
          ],
        ),

        // ========================================================
        // BODY
        // ========================================================

        body: _icerik(),
      ),
    );
  }

  // ============================================================
  // İÇERİK
  // ============================================================

  Widget _icerik() {
    if (_yukleniyor) {
      return const Center(
        child:
            CircularProgressIndicator(
          strokeWidth: 2.6,
        ),
      );
    }

    if (_hata != null ||
        _detay == null) {
      return _hataGorunumu();
    }

    final detay =
        _detay!;

    return RefreshIndicator(
      color: accent,
      onRefresh: _detayGetir,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          9,
          7,
          9,
          14,
        ),
        children: [
          _ustBilgi(detay),

          const SizedBox(
            height: 6,
          ),

          _kisiler(detay),

          const SizedBox(
            height: 7,
          ),

          Row(
            children: [
              const Icon(
                Icons
                    .inventory_2_outlined,
                size: 16,
                color: accent,
              ),

              const SizedBox(
                width: 5,
              ),

              const Expanded(
                child: Text(
                  'Talep Kalemleri',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        FontWeight.w900,
                  ),
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
                    6,
                  ),
                ),
                child: Text(
                  '${detay.kalemler.length} kalem',
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
          ),

          const SizedBox(
            height: 6,
          ),

          if (detay.kalemler.isEmpty)
            _bosKalem()
          else
            ...List.generate(
              detay.kalemler.length,
              (index) {
                return Padding(
                  padding:
                      const EdgeInsets
                          .only(
                    bottom: 5,
                  ),
                  child: _urunKarti(
                    detay.kalemler[
                        index],
                    index,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ÜST BİLGİ
  // ============================================================

  Widget _ustBilgi(
    DepoTalepBildirimDetayModel detay,
  ) {
    final durum =
        _durumGorunum(
      detay.durum,
    );

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        9,
        7,
        9,
        8,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black
              .withOpacity(.05),
        ),
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
                  color: durum.arkaPlan,
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                ),
                child: Icon(
                  durum.icon,
                  size: 17,
                  color: durum.renk,
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
                      detay
                          .gorunenEvrakNo,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    _durumEtiketi(
                      durum,
                    ),
                  ],
                ),
              ),

              if (detay.tarih !=
                  null)
                Text(
                  _tarihYaz(
                    detay.tarih!,
                  ),
                  style:
                      const TextStyle(
                    fontSize: 9.3,
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
                      detay.kaynakDepo,
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
                  size: 16,
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
                      detay.hedefDepo,
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

  // ============================================================
  // KİŞİLER
  // ============================================================

  Widget _kisiler(
    DepoTalepBildirimDetayModel detay,
  ) {
    final talepEden =
        detay.olusturanAdi
                .trim()
                .isNotEmpty
            ? detay.olusturanAdi
            : detay
                .olusturanProsisKodu;

    final onaylayan =
        detay.sonOnaylayanAdi
                .trim()
                .isNotEmpty
            ? detay
                .sonOnaylayanAdi
            : detay
                .sonOnaylayanProsisKodu;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black
              .withOpacity(.05),
        ),
      ),
      child: Column(
        children: [
          _kisiSatiri(
            ikon:
                Icons.person_outline,
            baslik:
                'Talep Eden',
            deger:
                _bosDeger(
              talepEden,
            ),
            altDeger:
                detay
                        .olusturanProsisKodu
                        .trim()
                        .isEmpty
                    ? null
                    : detay
                        .olusturanProsisKodu,
          ),

          if (onaylayan
              .trim()
              .isNotEmpty) ...[
            const Divider(
              height: 9,
              thickness: .5,
            ),

            _kisiSatiri(
              ikon: Icons
                  .verified_user_outlined,
              baslik:
                  'Son Onaylayan',
              deger:
                  onaylayan,
              altDeger:
                  detay.sonOnayTarihi ==
                          null
                      ? null
                      : _tarihSaat(
                          detay
                              .sonOnayTarihi!,
                        ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kisiSatiri({
    required IconData ikon,
    required String baslik,
    required String deger,
    String? altDeger,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment:
              Alignment.center,
          decoration:
              BoxDecoration(
            color: accent
                .withOpacity(.08),
            borderRadius:
                BorderRadius.circular(7),
          ),
          child: Icon(
            ikon,
            size: 16,
            color: accent,
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
                baslik,
                style:
                    const TextStyle(
                  fontSize: 8.4,
                  color:
                      Colors.black38,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 1,
              ),

              Text(
                deger,
                maxLines: 1,
                overflow:
                    TextOverflow
                        .ellipsis,
                style:
                    const TextStyle(
                  fontSize: 10.2,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              if (altDeger != null &&
                  altDeger
                      .trim()
                      .isNotEmpty)
                Text(
                  altDeger,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 8.2,
                    color:
                        Colors.black38,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DEPO KUTUSU
  // ============================================================

  Widget _depoBilgiKutusu({
    required String baslik,
    required String deger,
    required IconData ikon,
  }) {
    return Container(
      height: 44,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF7F7F9),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black
              .withOpacity(.04),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ikon,
            size: 15,
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
                    fontSize: 8,
                    color:
                        Colors.black38,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                Text(
                  _bosDeger(
                    deger,
                  ),
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 9.5,
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
    DepoTalepBildirimKalemModel kalem,
    int index,
  ) {
    final durum =
        _durumGorunum(
      kalem.durum,
    );

    return Container(
      decoration:
          BoxDecoration(
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
              7,
              6,
              7,
              5,
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
                        durum.arkaPlan,
                    borderRadius:
                        BorderRadius
                            .circular(7),
                  ),
                  child: Icon(
                    durum.icon,
                    size: 15,
                    color:
                        durum.renk,
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
                        _bosDeger(
                          kalem
                              .stokAdi,
                        ),
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
                        kalem
                            .stokKodu,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 8.7,
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

                const SizedBox(
                  width: 5,
                ),

                _durumEtiketi(
                  durum,
                  kucuk: true,
                ),

                const SizedBox(
                  width: 5,
                ),

                Container(
                  width: 23,
                  height: 23,
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
                      fontSize: 8.3,
                      color:
                          Colors.black45,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 42,
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
                  BorderRadius.circular(
                8,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      _miktarBilgisi(
                    baslik:
                        'Talep',
                    miktar:
                        kalem
                            .talepMiktari,
                    birim:
                        kalem.birim,
                  ),
                ),

                _inceCizgi(),

                Expanded(
                  child:
                      _miktarBilgisi(
                    baslik:
                        'Teslim',
                    miktar:
                        kalem
                            .teslimMiktari,
                    birim:
                        kalem.birim,
                  ),
                ),

                _inceCizgi(),

                Expanded(
                  child:
                      _miktarBilgisi(
                    baslik:
                        'Kalan',
                    miktar:
                        kalem
                            .kalanMiktar,
                    birim:
                        kalem.birim,
                    kalin: true,
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
  // MİKTAR
  // ============================================================

  Widget _miktarBilgisi({
    required String baslik,
    required double miktar,
    required String birim,
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
            fontSize: 8,
            color:
                Colors.black38,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 1,
        ),

        Text(
          '${_miktarYaz(miktar)} '
          '${birim.trim()}',
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight:
                kalin
                    ? FontWeight.w900
                    : FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _inceCizgi() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.black
          .withOpacity(.05),
    );
  }

  // ============================================================
  // DURUM
  // ============================================================

  _DurumGorunum _durumGorunum(
    String durum,
  ) {
    switch (
        durum.trim().toUpperCase()) {
      case 'ONAYLANDI':
        return const _DurumGorunum(
          text: 'Onaylandı',
          icon:
              Icons.check_circle_rounded,
          renk:
              Color(0xFF1E6F5C),
          arkaPlan:
              Color(0xFFE8F2EF),
        );

      case 'KISMI_ONAY':
        return const _DurumGorunum(
          text: 'Kısmi',
          icon:
              Icons.timelapse_rounded,
          renk:
              Color(0xFFB7791F),
          arkaPlan:
              Color(0xFFFFF3DD),
        );

      case 'IPTAL':
        return const _DurumGorunum(
          text: 'İptal',
          icon:
              Icons.cancel_rounded,
          renk:
              Color(0xFFC94B4B),
          arkaPlan:
              Color(0xFFFBECEC),
        );

      default:
        return const _DurumGorunum(
          text: 'Bekliyor',
          icon:
              Icons.schedule_rounded,
          renk:
              Color(0xFF607D8B),
          arkaPlan:
              Color(0xFFEDF1F3),
        );
    }
  }

  Widget _durumEtiketi(
    _DurumGorunum durum, {
    bool kucuk = false,
  }) {
    return Container(
      padding:
          EdgeInsets.symmetric(
        horizontal:
            kucuk ? 5 : 6,
        vertical:
            kucuk ? 2 : 3,
      ),
      decoration:
          BoxDecoration(
        color: durum.arkaPlan,
        borderRadius:
            BorderRadius.circular(6),
      ),
      child: Text(
        durum.text,
        style: TextStyle(
          fontSize:
              kucuk ? 7.8 : 8.5,
          color: durum.renk,
          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  // ============================================================
  // HATA
  // ============================================================

  Widget _hataGorunumu() {
    return RefreshIndicator(
      color: accent,
      onRefresh: _detayGetir,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(
            height: 110,
          ),

          Icon(
            Icons
                .error_outline_rounded,
            size: 42,
            color:
                Colors.red.shade300,
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Talep bilgisi yüklenemedi',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize: 12.5,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 28,
            ),
            child: Text(
              _hata ??
                  'Talep bulunamadı.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 10,
                color:
                    Colors.black45,
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Center(
            child:
                OutlinedButton.icon(
              onPressed:
                  _detayGetir,
              icon:
                  const Icon(
                Icons
                    .refresh_rounded,
                size: 16,
              ),
              label:
                  const Text(
                'Tekrar Dene',
                style:
                    TextStyle(
                  fontSize: 9.5,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bosKalem() {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'Talep kalemi bulunamadı.',
          style:
              TextStyle(
            fontSize: 10.5,
            color:
                Colors.black45,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT
  // ============================================================

  String _bosDeger(
    String? value,
  ) {
    final text =
        value?.trim() ?? '';

    return text.isEmpty
        ? '-'
        : text;
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

  String _tarihSaat(
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

    final saat =
        tarih.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final dakika =
        tarih.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$gun.$ay.${tarih.year} '
        '$saat:$dakika';
  }
}


// ============================================================
// DURUM GÖRSELİ
// ============================================================

class _DurumGorunum {
  final String text;

  final IconData icon;

  final Color renk;

  final Color arkaPlan;

  const _DurumGorunum({
    required this.text,
    required this.icon,
    required this.renk,
    required this.arkaPlan,
  });
}