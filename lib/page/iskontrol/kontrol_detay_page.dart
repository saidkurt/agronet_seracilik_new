import 'dart:async';

import 'package:agronet/api/kontrol_api.dart';
import 'package:agronet/models/kontrol_detay_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KontrolDetayPage extends StatefulWidget {
  final int kontrolIsId;
  final String kontrolEdenPersonelKodu;

  const KontrolDetayPage({
    super.key,
    required this.kontrolIsId,
    required this.kontrolEdenPersonelKodu,
  });

  @override
  State<KontrolDetayPage> createState() =>
      _KontrolDetayPageState();
}

class _KontrolDetayPageState extends State<KontrolDetayPage> {
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _green = Color(0xFF1E6F5C);

  KontrolDetayModel? _detay;

  bool _yukleniyor = true;
  bool _islemYapiliyor = false;

  String? _hataMesaji;

  Timer? _timer;
  DateTime _referansZamani = DateTime.now();

  int _temelCalisilanSaniye = 0;
  int _temelAraSaniye = 0;

  @override
  void initState() {
    super.initState();
    _detayGetir();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // DETAY
  // ============================================================

  Future<void> _detayGetir() async {
    if (!mounted) return;

    setState(() {
      _yukleniyor = true;
      _hataMesaji = null;
    });

    try {
      final sonuc = await KontrolApi.detayGetir(
        kontrolIsId: widget.kontrolIsId,
      );

      if (!mounted) return;

      setState(() {
        _detay = sonuc;

        _temelCalisilanSaniye =
            sonuc.kontrolCalisilanSaniye;

        _temelAraSaniye =
            sonuc.kontrolAraSaniye;

        _referansZamani = DateTime.now();
      });

      _timeriAyarla();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hataMesaji = _temizHata(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
        });
      }
    }
  }

  // ============================================================
  // TIMER
  // ============================================================

  void _timeriAyarla() {
    _timer?.cancel();

    if (_detay == null) return;

    final durum = _detay!.kontrolDurum;

    if (durum != 1 && durum != 2) {
      return;
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  int get _gecenSaniye {
    if (_detay == null) return 0;

    final durum = _detay!.kontrolDurum;

    if (durum != 1 && durum != 2) {
      return 0;
    }

    return DateTime.now()
        .difference(_referansZamani)
        .inSeconds;
  }

  int get _calisilanSaniye {
    if (_detay?.kontrolDurum == 1) {
      return _temelCalisilanSaniye + _gecenSaniye;
    }

    return _temelCalisilanSaniye;
  }

  int get _araSaniye {
    if (_detay?.kontrolDurum == 2) {
      return _temelAraSaniye + _gecenSaniye;
    }

    return _temelAraSaniye;
  }

  // ============================================================
  // DURUM
  // ============================================================

  Future<void> _durumDegistir() async {
    await _islemYap(
      () => KontrolApi.durumDegistir(
        kontrolIsId: widget.kontrolIsId,
        kontrolEdenPersonelKodu:
            widget.kontrolEdenPersonelKodu,
      ),
    );
  }

  // ============================================================
  // BİTİR
  // ============================================================

  Future<void> _bitir() async {
    if (_detay == null || _islemYapiliyor) {
      return;
    }

    if (_detay!.kontrolDurum != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kontrolü bitirmek için kontrolün devam ediyor olması gerekir.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final puan = await _puanSor();

    if (puan == null || !mounted) {
      return;
    }

    final onay = await _onaySor(
      'Kontrol görevi $puan puan verilerek tamamlanacak.',
      baslik: 'Kontrolü bitir',
      onayYazisi: 'Bitir',
      tehlikeli: true,
    );

    if (!onay || !mounted) {
      return;
    }

    await _islemYap(
      () => KontrolApi.bitir(
        kontrolIsId: widget.kontrolIsId,
        kontrolEdenPersonelKodu:
            widget.kontrolEdenPersonelKodu,
        puan: puan,
      ),
      sayfayiKapat: true,
    );
  }

  // ============================================================
  // TEKRAR
  // ============================================================

  Future<void> _tekrarEt() async {
    final onay = await _onaySor(
      'Kontrol edilen asıl iş tekrar yapılmak üzere gönderilecek.',
      baslik: 'Asıl işi tekrar et',
      onayYazisi: 'Tekrar ettir',
      tehlikeli: true,
    );

    if (!onay) return;

    await _islemYap(
      () => KontrolApi.tekrarEt(
        kontrolIsId: widget.kontrolIsId,
        kontrolEdenPersonelKodu:
            widget.kontrolEdenPersonelKodu,
      ),
      sayfayiKapat: true,
    );
  }

  // ============================================================
  // PUAN
  // ============================================================

  Future<int?> _puanSor() async {
    if (_detay == null || _islemYapiliyor) {
      return null;
    }

    String girilenPuan = '';

    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              14,
              9,
              14,
              14,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Kontrol Puanı',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Asıl işe 1 ile 10 arasında puan verin.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 54,
                    child: TextFormField(
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      maxLength: 2,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '1 - 10',
                        hintStyle: const TextStyle(
                          fontSize: 15,
                          color: Colors.black26,
                        ),
                        filled: true,
                        fillColor: _bg,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(9),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(9),
                          borderSide: BorderSide(
                            color: Colors.black.withOpacity(.06),
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(9),
                          ),
                          borderSide: BorderSide(
                            color: _green,
                            width: 1.3,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        girilenPuan = value.trim();
                      },
                      onFieldSubmitted: (value) {
                        final sayi =
                            int.tryParse(value.trim());

                        if (sayi == null ||
                            sayi < 1 ||
                            sayi > 10) {
                          ScaffoldMessenger.of(sheetContext)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Puan 1 ile 10 arasında olmalıdır.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );

                          return;
                        }

                        Navigator.of(sheetContext).pop(sayi);
                      },
                    ),
                  ),

                  const SizedBox(height: 9),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(9),
                              ),
                            ),
                            child: const Text(
                              'Vazgeç',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 40,
                          child: FilledButton.icon(
                            onPressed: () {
                              final sayi =
                                  int.tryParse(girilenPuan);

                              if (sayi == null ||
                                  sayi < 1 ||
                                  sayi > 10) {
                                ScaffoldMessenger.of(
                                  sheetContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Puan 1 ile 10 arasında olmalıdır.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );

                                return;
                              }

                              Navigator.of(sheetContext)
                                  .pop(sayi);
                            },
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 17,
                            ),
                            label: const Text(
                              'DEVAM ET',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _green,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // İŞLEM
  // ============================================================

  Future<void> _islemYap(
    Future<String> Function() islem, {
    bool sayfayiKapat = false,
  }) async {
    if (_islemYapiliyor) return;

    setState(() {
      _islemYapiliyor = true;
    });

    try {
      final mesaj = await islem();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mesaj,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );

      if (sayfayiKapat) {
        Navigator.pop(context, true);
        return;
      }

      await _detayGetir();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_temizHata(e)),
          backgroundColor: Colors.red,
        ),
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

  Future<bool> _onaySor(
    String mesaj, {
    String baslik = 'Onay',
    String onayYazisi = 'Evet',
    bool tehlikeli = false,
  }) async {
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            baslik,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
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
                'Vazgeç',
                style: TextStyle(fontSize: 11),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    tehlikeli ? Colors.red : _green,
              ),
              child: Text(
                onayYazisi,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final scaler =
        MediaQuery.textScalerOf(context).clamp(
      maxScaleFactor: 1.06,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: scaler,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          toolbarHeight: 48,
          title: const Text(
            'Kontrol Detayı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          actions: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Yenile',
              onPressed:
                  _yukleniyor || _islemYapiliyor
                      ? null
                      : _detayGetir,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 21,
              ),
            ),
          ],
        ),
        body: _govde(),
        bottomNavigationBar: _altIslemAlani(),
      ),
    );
  }

  // ============================================================
  // GÖVDE
  // ============================================================

  Widget _govde() {
    if (_yukleniyor) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hataMesaji != null) {
      return _hataEkrani();
    }

    if (_detay == null) {
      return const Center(
        child: Text(
          'Kontrol detayı bulunamadı.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black45,
          ),
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: _green,
          onRefresh: _detayGetir,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              7,
              6,
              7,
              12,
            ),
            children: [
              _ustOzetKarti(),

              if (_detay!.tekrarSayisi > 0) ...[
                const SizedBox(height: 5),
                _tekrarBilgisi(),
              ],

              const SizedBox(height: 5),
              _asilIsSureleriKarti(),

              const SizedBox(height: 5),
              _kontrolSureleriKarti(),

              const SizedBox(height: 5),
              _durumBilgisi(),
            ],
          ),
        ),

        if (_islemYapiliyor)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(.10),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // HATA
  // ============================================================

  Widget _hataEkrani() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),

        Icon(
          Icons.error_outline_rounded,
          size: 44,
          color: Colors.red.shade300,
        ),

        const SizedBox(height: 8),

        Text(
          _hataMesaji!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 10),

        Center(
          child: SizedBox(
            height: 36,
            child: FilledButton.icon(
              onPressed: _detayGetir,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
              ),
              label: const Text(
                'Tekrar dene',
                style: TextStyle(
                  fontSize: 10.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ÜST ÖZET
  // ============================================================

  Widget _ustOzetKarti() {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: _kartDekorasyonu(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _green.withOpacity(.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: _green,
                  size: 18,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _detay!.personel.isEmpty
                          ? '-'
                          : _detay!.personel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _detay!.gorev.isEmpty
                          ? '-'
                          : _detay!.gorev,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              _durumRozeti(
                _detay!.asilDurumAdi,
              ),
            ],
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Expanded(
                child: _kisaBilgi(
                  'Tünel',
                  _detay!.tunel,
                ),
              ),

              Container(
                width: 1,
                height: 26,
                color: Colors.black.withOpacity(.06),
              ),

              Expanded(
                child: _kisaBilgi(
                  'Koridor',
                  _detay!.koridor,
                ),
              ),

              Container(
                width: 1,
                height: 26,
                color: Colors.black.withOpacity(.06),
              ),

              Expanded(
                flex: 2,
                child: _kisaBilgi(
                  'Başlangıç',
                  _tarihYaz(_detay!.baslangic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ASIL İŞ SÜRELERİ
  // ============================================================

  Widget _asilIsSureleriKarti() {
    final aktifFazla =
        _detay!.azamiSaniye > 0 &&
            _detay!.aktifSaniye >
                _detay!.azamiSaniye;

    return _kart(
      baslik: 'Asıl İş Süreleri',
      ikon: Icons.work_history_rounded,
      child: Row(
        children: [
          Expanded(
            child: _sureKutusu(
              baslik: 'Aktif',
              deger: _kisaSure(
                _detay!.aktifSaniye,
              ),
              uyari: aktifFazla,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _sureKutusu(
              baslik: 'Mola',
              deger: _kisaSure(
                _detay!.molaSaniye,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _sureKutusu(
              baslik: 'Hedef',
              deger: _kisaSure(
                _detay!.hedefSaniye,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _sureKutusu(
              baslik: 'Azami',
              deger: _kisaSure(
                _detay!.azamiSaniye,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KONTROL SÜRELERİ
  // ============================================================

  Widget _kontrolSureleriKarti() {
    return _kart(
      baslik: 'Kontrol Süreleri',
      ikon: Icons.fact_check_rounded,
      child: Row(
        children: [
          Expanded(
            child: _kontrolSureKutusu(
              'Çalışılan',
              _saatFormat(
                _calisilanSaniye,
              ),
              Colors.green,
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: _kontrolSureKutusu(
              'Ara',
              _saatFormat(
                _araSaniye,
              ),
              Colors.orange,
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: _kontrolSureKutusu(
              'Toplam',
              _saatFormat(
                _calisilanSaniye +
                    _araSaniye,
              ),
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DURUM
  // ============================================================

  Widget _durumBilgisi() {
    final durum = _detay!.kontrolDurum;

    late final Color renk;
    late final IconData ikon;
    late final String baslik;
    late final String aciklama;

    switch (durum) {
      case 1:
        renk = Colors.green.shade700;
        ikon = Icons.play_circle_rounded;
        baslik = 'Kontrol devam ediyor';
        aciklama = 'Kontrol süresi çalışıyor.';
        break;

      case 2:
        renk = Colors.orange.shade800;
        ikon = Icons.pause_circle_rounded;
        baslik = 'Kontrole ara verildi';
        aciklama = 'Devam Et ile sürdürebilirsiniz.';
        break;

      case 3:
        renk = Colors.green.shade700;
        ikon = Icons.check_circle_rounded;
        baslik = 'Kontrol tamamlandı';
        aciklama = _detay!.puan > 0
            ? 'Puan: ${_detay!.puan.toInt()}'
            : 'Kontrol tamamlandı.';
        break;

      default:
        renk = Colors.blue.shade700;
        ikon = Icons.info_rounded;
        baslik = 'Kontrol bekliyor';
        aciklama = 'Başla ile kontrolü başlatın.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: renk.withOpacity(.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: renk.withOpacity(.16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ikon,
            color: renk,
            size: 19,
          ),

          const SizedBox(width: 6),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: TextStyle(
                    color: renk,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  aciklama,
                  style: TextStyle(
                    color: renk.withOpacity(.8),
                    fontSize: 9,
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
  // ALT BAR
  // ============================================================

  Widget? _altIslemAlani() {
    if (_yukleniyor ||
        _hataMesaji != null ||
        _detay == null) {
      return null;
    }

    if (_detay!.kontrolDurum == 3) {
      return null;
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          7,
          5,
          7,
          5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.black.withOpacity(.06),
            ),
          ),
        ),
        child: _altButonlar(),
      ),
    );
  }

  Widget _altButonlar() {
    switch (_detay!.kontrolDurum) {
      case 0:
      case 4:
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: _anaButon(
                yazi: 'BAŞLA',
                ikon: Icons.play_arrow_rounded,
                renk: _green,
                onPressed: _durumDegistir,
              ),
            ),

            const SizedBox(width: 5),

            Expanded(
              child: _ikincilButon(
                yazi: 'Tekrar',
                ikon: Icons.replay_rounded,
                renk: Colors.orange.shade800,
                onPressed: _tekrarEt,
              ),
            ),
          ],
        );

      case 1:
        return Row(
          children: [
            Expanded(
              child: _anaButon(
                yazi: 'ARA VER',
                ikon: Icons.pause_rounded,
                renk: Colors.orange.shade800,
                onPressed: _durumDegistir,
              ),
            ),

            const SizedBox(width: 5),

            Expanded(
              child: _anaButon(
                yazi: 'BİTİR',
                ikon: Icons.stop_rounded,
                renk: Colors.red.shade700,
                onPressed: _bitir,
              ),
            ),
          ],
        );

      case 2:
        return _anaButon(
          yazi: 'DEVAM ET',
          ikon: Icons.play_arrow_rounded,
          renk: _green,
          onPressed: _durumDegistir,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _anaButon({
    required String yazi,
    required IconData ikon,
    required Color renk,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 40,
      child: FilledButton.icon(
        onPressed:
            _islemYapiliyor ? null : onPressed,
        icon: Icon(
          ikon,
          size: 17,
        ),
        label: Text(
          yazi,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: renk,
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }

  Widget _ikincilButon({
    required String yazi,
    required IconData ikon,
    required Color renk,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed:
            _islemYapiliyor ? null : onPressed,
        icon: Icon(
          ikon,
          size: 16,
        ),
        label: Text(
          yazi,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: renk,
          side: BorderSide(
            color: renk.withOpacity(.4),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TEKRAR
  // ============================================================

  Widget _tekrarBilgisi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.replay_rounded,
            color: Colors.orange.shade800,
            size: 15,
          ),

          const SizedBox(width: 5),

          Expanded(
            child: Text(
              '${_detay!.tekrarSayisi} defa tekrar edildi.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w800,
                fontSize: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KART
  // ============================================================

  Widget _kart({
    required String baslik,
    required IconData ikon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _kartDekorasyonu(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ikon,
                size: 15,
                color: Colors.black45,
              ),

              const SizedBox(width: 4),

              Text(
                baslik,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          child,
        ],
      ),
    );
  }

  BoxDecoration _kartDekorasyonu() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(
        color: Colors.black.withOpacity(.05),
      ),
    );
  }

  // ============================================================
  // KISA BİLGİ
  // ============================================================

  Widget _kisaBilgi(
    String baslik,
    String deger,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: const TextStyle(
              fontSize: 8.5,
              color: Colors.black38,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 1),

          Text(
            deger.isEmpty ? '-' : deger,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _durumRozeti(
    String durum,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _green.withOpacity(.09),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        durum.isEmpty ? '-' : durum,
        style: const TextStyle(
          color: _green,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ============================================================
  // ASIL SÜRE
  // ============================================================

  Widget _sureKutusu({
    required String baslik,
    required String deger,
    bool uyari = false,
  }) {
    final renk =
        uyari ? Colors.red.shade700 : Colors.black87;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: uyari
            ? Colors.red.withOpacity(.06)
            : const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: uyari
              ? Colors.red.withOpacity(.18)
              : Colors.black.withOpacity(.035),
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            baslik,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.black45,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 1),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              deger,
              style: TextStyle(
                color: renk,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KONTROL SÜRESİ
  // ============================================================

  Widget _kontrolSureKutusu(
    String baslik,
    String deger,
    Color renk,
  ) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: renk.withOpacity(.07),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            baslik,
            style: TextStyle(
              fontSize: 8,
              color: renk,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              deger,
              style: TextStyle(
                color: renk,
                fontSize: 11,
                fontWeight: FontWeight.w900,
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

  String _tarihYaz(
    DateTime? tarih,
  ) {
    if (tarih == null) return '-';

    final gun =
        tarih.day.toString().padLeft(2, '0');

    final ay =
        tarih.month.toString().padLeft(2, '0');

    final saat =
        tarih.hour.toString().padLeft(2, '0');

    final dakika =
        tarih.minute.toString().padLeft(2, '0');

    return '$gun.$ay $saat:$dakika';
  }

  // ============================================================
  // SÜRE
  // ============================================================

  String _saatFormat(
    int toplamSaniye,
  ) {
    if (toplamSaniye < 0) {
      toplamSaniye = 0;
    }

    final saat =
        toplamSaniye ~/ 3600;

    final dakika =
        (toplamSaniye % 3600) ~/ 60;

    final saniye =
        toplamSaniye % 60;

    return '${saat.toString().padLeft(2, '0')}:'
        '${dakika.toString().padLeft(2, '0')}:'
        '${saniye.toString().padLeft(2, '0')}';
  }

  String _kisaSure(
    int toplamSaniye,
  ) {
    if (toplamSaniye <= 0) {
      return '0 dk';
    }

    final saat =
        toplamSaniye ~/ 3600;

    final dakika =
        (toplamSaniye % 3600) ~/ 60;

    if (saat > 0) {
      return '$saat sa ${dakika > 0 ? '$dakika dk' : ''}';
    }

    if (dakika > 0) {
      return '$dakika dk';
    }

    return '${toplamSaniye % 60} sn';
  }

  String _temizHata(dynamic e) {
    return e
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }
}