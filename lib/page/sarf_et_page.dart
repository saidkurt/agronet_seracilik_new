import 'package:flutter/material.dart';

import 'package:agronet/api/sarf_et_api.dart';
import 'package:agronet/models/sarf_et_model.dart';

class SarfEtPage extends StatefulWidget {
  const SarfEtPage({
    super.key,
    required this.kullaniciKodu,
    required this.oturumId,
    required this.token,
  });

  final String kullaniciKodu;
  final int oturumId;
  final String token;

  @override
  State<SarfEtPage> createState() => _SarfEtPageState();
}

class _SarfEtPageState extends State<SarfEtPage> {
  static const Color _accent = Color(0xFF1E6F5C);
  static const Color _background = Color(0xFFF4F7F6);
  static const Color _cardBorder = Color(0xFFE3ECE8);
  static const Color _muted = Color(0xFF6F8079);
  static const Color _soft = Color(0xFFF7FAF8);

  final SarfEtApi _api = SarfEtApi();

  List<SarfDepoModel> _depolar = <SarfDepoModel>[];
  final List<_SarfSatir> _satirlar = <_SarfSatir>[];

  SarfDepoModel? _secilenDepo;
  DateTime _tarih = DateTime.now();

  int? _secilenSatirIndex;

  bool _ilkYukleniyor = true;
  bool _depodakilerYukleniyor = false;
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    _depolariYukle();
  }

  @override
  void dispose() {
    for (final satir in _satirlar) {
      satir.dispose();
    }
    super.dispose();
  }

  // ============================================================
  // DEPOLAR
  // Kırşehir Merkez Depo (2) ASLA GELMEZ.
  // ============================================================

  Future<void> _depolariYukle() async {
    setState(() => _ilkYukleniyor = true);

    try {
      final gelen = await _api.depolar();

      // 2 = Kırşehir Merkez Depo
      final liste = gelen
          .where((x) => x.depoNo != 2)
          .toList();

      if (!mounted) return;

      setState(() {
        _depolar = liste;
        _secilenDepo =
            liste.isNotEmpty ? liste.first : null;
      });
    } catch (e) {
      if (!mounted) return;
      _hataGoster(_exceptionText(e));
    } finally {
      if (mounted) {
        setState(() => _ilkYukleniyor = false);
      }
    }
  }

  // ============================================================
  // TARİH
  // ============================================================

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Sarf Tarihi',
      cancelText: 'VAZGEÇ',
      confirmText: 'SEÇ',
    );

    if (secilen == null || !mounted) return;

    setState(() {
      _tarih = secilen;
      _listeyiTemizle();
    });
  }

  // ============================================================
  // DEPOMDAKİ ÜRÜNLERİ GETİR
  // ============================================================

  Future<void> _depodakileriGetir() async {
    final depo = _secilenDepo;

    if (depo == null) {
      _hataGoster('Önce depo seçmelisiniz.');
      return;
    }

    setState(() {
      _depodakilerYukleniyor = true;
    });

    try {
      final liste = await _api.depodakiler(
        depoNo: depo.depoNo,
        tarih: _tarih,
      );

      if (!mounted) return;

      _listeyiTemizle();

      setState(() {
        for (final stok in liste) {
          _satirlar.add(
            _SarfSatir(
              stokKodu: stok.stokKodu,
              stokAdi: stok.stokAdi,
              maksimumMiktar: stok.depodakiMiktar,
              birim: stok.birim,
              miktar: stok.depodakiMiktar,
            ),
          );
        }

        _secilenSatirIndex =
            _satirlar.isEmpty ? null : 0;
      });

      if (_satirlar.isEmpty) {
        _mesajGoster(
          'Seçilen depoda sarf edilebilir stok bulunamadı.',
        );
      } else {
        _mesajGoster(
          '${_satirlar.length} ürün getirildi.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _hataGoster(_exceptionText(e));
    } finally {
      if (mounted) {
        setState(() {
          _depodakilerYukleniyor = false;
        });
      }
    }
  }

  // ============================================================
  // SATIR SİL
  // ============================================================

  void _satirSil() {
    final index = _secilenSatirIndex;

    if (index == null ||
        index < 0 ||
        index >= _satirlar.length) {
      _hataGoster(
        'Silmek için listeden bir satır seçin.',
      );
      return;
    }

    setState(() {
      final silinen = _satirlar.removeAt(index);
      silinen.dispose();

      if (_satirlar.isEmpty) {
        _secilenSatirIndex = null;
      } else if (index >= _satirlar.length) {
        _secilenSatirIndex =
            _satirlar.length - 1;
      } else {
        _secilenSatirIndex = index;
      }
    });
  }

  // ============================================================
  // KAYDET
  // ============================================================

  Future<void> _kaydet() async {
    if (_kaydediliyor) return;

    final depo = _secilenDepo;

    if (depo == null) {
      _hataGoster('Depo seçilmedi.');
      return;
    }

    if (_satirlar.isEmpty) {
      _hataGoster(
        'Kaydedilecek sarf satırı bulunamadı.',
      );
      return;
    }

    if (widget.kullaniciKodu.trim().isEmpty) {
      _hataGoster(
        'Kullanıcı kodu bulunamadı.',
      );
      return;
    }

    if (widget.oturumId <= 0 ||
        widget.token.trim().isEmpty) {
      _hataGoster(
        'Mobil oturum bilgisi geçersiz. '
        'Tekrar giriş yapın.',
      );
      return;
    }

    final gecerliKalemler =
        <SarfKaydetKalemModel>[];

    for (final satir in _satirlar) {
      final miktar =
          _doubleParse(satir.controller.text);

      if (miktar <= 0) {
        continue;
      }

      if (miktar > satir.maksimumMiktar) {
        _hataGoster(
          '${satir.stokAdi} için miktar '
          'depo miktarından fazla olamaz.\n'
          'Maksimum: '
          '${_miktarYaz(satir.maksimumMiktar)} '
          '${satir.birim}',
        );
        return;
      }

      gecerliKalemler.add(
        SarfKaydetKalemModel(
          stokKodu: satir.stokKodu,
          miktar: miktar,
        ),
      );
    }

    if (gecerliKalemler.isEmpty) {
      _hataGoster(
        'Sarf miktarı girilmiş ürün bulunamadı.',
      );
      return;
    }

    final devam = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(
            Icons.inventory_2_outlined,
            color: _accent,
            size: 38,
          ),
          title: const Text(
            'Sarf Kaydı',
            textAlign: TextAlign.center,
          ),
          content: Text(
            '${gecerliKalemler.length} kalem '
            'sarf edilecek.\n\n'
            '${depo.depoAdi}\n'
            '${_tarihYaz(_tarih)}',
            textAlign: TextAlign.center,
          ),
          actionsAlignment:
              MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('VAZGEÇ'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
              ),
              child: const Text('SARF ET'),
            ),
          ],
        );
      },
    );

    if (devam != true || !mounted) return;

    setState(() {
      _kaydediliyor = true;
    });

    try {
      final sonuc = await _api.kaydet(
        request: SarfKaydetRequestModel(
          depoNo: depo.depoNo,
          tarih: _tarih,

          // Açıklama alanı ekranda yok.
          aciklama: '',

          kullaniciKodu:
              widget.kullaniciKodu.trim(),
          oturumId: widget.oturumId,
          token: widget.token.trim(),
          kalemler: gecerliKalemler,
        ),
      );

      if (!mounted) return;

      _listeyiTemizle();

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle_rounded,
              color: _accent,
              size: 42,
            ),
            title: const Text(
              'İşlem Tamam',
              textAlign: TextAlign.center,
            ),
            content: Text(
              sonuc.evrakSeri.trim().isEmpty
                  ? sonuc.mesaj
                  : '${sonuc.mesaj}\n\n'
                    'Evrak: '
                    '${sonuc.evrakSeri}-'
                    '${sonuc.evrakSira}',
              textAlign: TextAlign.center,
            ),
            actionsAlignment:
                MainAxisAlignment.center,
            actions: [
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                ),
                child: const Text('TAMAM'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      _hataGoster(_exceptionText(e));
    } finally {
      if (mounted) {
        setState(() {
          _kaydediliyor = false;
        });
      }
    }
  }

  // ============================================================
  // TEMİZLE
  // ============================================================

  void _listeyiTemizle() {
    for (final satir in _satirlar) {
      satir.dispose();
    }

    _satirlar.clear();
    _secilenSatirIndex = null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        toolbarHeight: 52,
        elevation: 0,
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: const Text(
          'Sarf Et',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Listeyi temizle',
            onPressed: _kaydediliyor
                ? null
                : () {
                    setState(() {
                      _listeyiTemizle();
                    });
                  },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: _ilkYukleniyor
          ? const Center(
              child: CircularProgressIndicator(
                color: _accent,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    physics:
                        const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      10,
                      10,
                      10,
                      12,
                    ),
                    children: [
                      _ustKart(),
                      const SizedBox(height: 8),
                      _sarfListesiKarti(),
                    ],
                  ),
                ),
                _altKaydetBar(),
              ],
            ),
    );
  }

  // ============================================================
  // ÜST KART
  // ============================================================

  Widget _ustKart() {
    return _card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          const _MiniTitle(
            icon: Icons.warehouse_outlined,
            title: 'SARF BİLGİLERİ',
          ),
          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: _depoDropdown(),
              ),
              const SizedBox(width: 7),
              Expanded(
                flex: 2,
                child: _tarihButton(),
              ),
            ],
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 42,
            child: FilledButton.icon(
              onPressed:
                  _depodakilerYukleniyor
                      ? null
                      : _depodakileriGetir,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              icon: _depodakilerYukleniyor
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                    ),
              label: const Text(
                'DEPOMDAKİ ÜRÜNLERİ GETİR',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SARF LİSTESİ
  // ============================================================

  Widget _sarfListesiKarti() {
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              10,
              8,
              8,
              7,
            ),
            child: Row(
              children: [
                const _MiniTitle(
                  icon: Icons.list_alt_rounded,
                  title: 'SARF LİSTESİ',
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _accent.withOpacity(.08),
                    borderRadius:
                        BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_satirlar.length} kalem',
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_satirlar.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 38,
                horizontal: 14,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.black26,
                    size: 34,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Depodaki ürünleri getirerek başlayın',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Container(
              color: _soft,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Text(
                      'STOK',
                      style: _tableHeadStyle,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'SARF MİKTARI',
                      textAlign: TextAlign.center,
                      style: _tableHeadStyle,
                    ),
                  ),
                ],
              ),
            ),

            ...List.generate(
              _satirlar.length,
              (index) {
                final item =
                    _satirlar[index];

                final selected =
                    _secilenSatirIndex ==
                        index;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _secilenSatirIndex =
                          index;
                    });
                  },
                  child: AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 120,
                    ),
                    padding:
                        const EdgeInsets.fromLTRB(
                      8,
                      6,
                      8,
                      6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? _accent.withOpacity(.06)
                          : Colors.white,
                      border: const Border(
                        top: BorderSide(
                          color:
                              Color(0xFFEDF2F0),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 42,
                          decoration: BoxDecoration(
                            color: selected
                                ? _accent
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                        ),

                        const SizedBox(width: 7),

                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                item.stokAdi,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              Text(
                                '${item.stokKodu}  •  '
                                'Depo: '
                                '${_miktarYaz(item.maksimumMiktar)} '
                                '${item.birim}',
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color: _muted,
                                  fontSize: 8.8,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller:
                                  item.controller,
                              keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                decimal: true,
                              ),
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                fontSize: 10.5,
                                fontWeight:
                                    FontWeight.w900,
                                color: _accent,
                              ),
                              onTap: () {
                                setState(() {
                                  _secilenSatirIndex =
                                      index;
                                });
                              },
                              decoration:
                                  InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                suffixText:
                                    item.birim,
                                suffixStyle:
                                    const TextStyle(
                                  color: _muted,
                                  fontSize: 8,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 7,
                                  vertical: 9,
                                ),
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(8),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        _cardBorder,
                                  ),
                                ),
                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(8),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        _cardBorder,
                                  ),
                                ),
                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(8),
                                  borderSide:
                                      const BorderSide(
                                    color: _accent,
                                    width: 1.2,
                                  ),
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
            ),

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                9,
                8,
                9,
                9,
              ),
              child: SizedBox(
                height: 38,
                child:
                    OutlinedButton.icon(
                  onPressed: _satirSil,
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.red.shade700,
                    side: BorderSide(
                      color:
                          Colors.red.shade200,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(9),
                    ),
                  ),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 17,
                  ),
                  label: const Text(
                    'SEÇİLİ SATIRI SİL',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ALT KAYDET
  // ============================================================

  Widget _altKaydetBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          10,
          7,
          10,
          7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: _cardBorder,
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 45,
          child: FilledButton.icon(
            onPressed:
                _kaydediliyor
                    ? null
                    : _kaydet,
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(11),
              ),
            ),
            icon: _kaydediliyor
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.save_rounded,
                    size: 18,
                  ),
            label: Text(
              _kaydediliyor
                  ? 'KAYDEDİLİYOR'
                  : 'SARF ET (${_satirlar.length})',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DEPO
  // ============================================================

  Widget _depoDropdown() {
    return DropdownButtonFormField<
        SarfDepoModel>(
      value: _secilenDepo,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Depo',
        icon: Icons.warehouse_outlined,
      ),
      items: _depolar
          .map(
            (depo) => DropdownMenuItem(
              value: depo,
              child: Text(
                depo.depoAdi,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _secilenDepo = value;
          _listeyiTemizle();
        });
      },
    );
  }

  // ============================================================
  // TARİH BUTTON
  // ============================================================

  Widget _tarihButton() {
    return InkWell(
      onTap: _tarihSec,
      borderRadius:
          BorderRadius.circular(10),
      child: Container(
        height: 47,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 9,
        ),
        decoration: BoxDecoration(
          color: _soft,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: _cardBorder,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: _accent,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TARİH',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 8,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _tarihYaz(_tarih),
                    style:
                        const TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(10),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color: _cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 10,
        color: _muted,
        fontWeight: FontWeight.w700,
      ),
      prefixIcon: Icon(
        icon,
        size: 18,
        color: _accent,
      ),
      isDense: true,
      filled: true,
      fillColor: _soft,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 11,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide:
            const BorderSide(
          color: _cardBorder,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide:
            const BorderSide(
          color: _cardBorder,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide:
            const BorderSide(
          color: _accent,
          width: 1.3,
        ),
      ),
    );
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor:
            Colors.red.shade700,
      ),
    );
  }

  void _mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mesaj),
      ),
    );
  }

  String _exceptionText(Object e) {
    final text = e.toString();

    if (text.startsWith(
      'Exception: ',
    )) {
      return text.substring(
        'Exception: '.length,
      );
    }

    return text;
  }

  double _doubleParse(String value) {
    return double.tryParse(
          value
              .trim()
              .replaceAll(',', '.'),
        ) ??
        0;
  }

  String _tarihYaz(DateTime tarih) {
    final gun =
        tarih.day.toString().padLeft(
              2,
              '0',
            );

    final ay =
        tarih.month.toString().padLeft(
              2,
              '0',
            );

    return '$gun.$ay.${tarih.year}';
  }

  String _miktarYaz(double value) {
    if (value ==
        value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }
}

class _SarfSatir {
  final String stokKodu;
  final String stokAdi;
  final double maksimumMiktar;
  final String birim;

  final TextEditingController controller;

  _SarfSatir({
    required this.stokKodu,
    required this.stokAdi,
    required this.maksimumMiktar,
    required this.birim,
    required double miktar,
  }) : controller =
            TextEditingController(
          text: _ilkMiktarYaz(miktar),
        );

  static String _ilkMiktarYaz(
    double value,
  ) {
    if (value ==
        value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  void dispose() {
    controller.dispose();
  }
}

class _MiniTitle extends StatelessWidget {
  const _MiniTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  static const Color _accent =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            color:
                _accent.withOpacity(.08),
            borderRadius:
                BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            color: _accent,
            size: 14,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF5F716A),
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

const TextStyle _tableHeadStyle =
    TextStyle(
  color: Color(0xFF7B8984),
  fontSize: 8.5,
  fontWeight: FontWeight.w900,
);
