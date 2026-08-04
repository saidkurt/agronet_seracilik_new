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

class _KontrolDetayPageState
    extends State<KontrolDetayPage> {
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
        _hataMesaji = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
        });
      }
    }
  }

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
      return _temelCalisilanSaniye +
          _gecenSaniye;
    }

    return _temelCalisilanSaniye;
  }

  int get _araSaniye {
    if (_detay?.kontrolDurum == 2) {
      return _temelAraSaniye +
          _gecenSaniye;
    }

    return _temelAraSaniye;
  }

  Future<void> _durumDegistir() async {
    await _islemYap(
      () => KontrolApi.durumDegistir(
  kontrolIsId: widget.kontrolIsId,
  kontrolEdenPersonelKodu:
      widget.kontrolEdenPersonelKodu,
      ));
  }

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
      'Kontrol görevi $puan puan verilerek tamamlanacak. '
      'Devam etmek istediğinizden emin misiniz?',
      baslik: 'Kontrolü bitir',
      onayYazisi: 'Bitir ve kaydet',
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

  Future<void> _tekrarEt() async {
    final onay = await _onaySor(
      'Kontrol edilen asıl iş tekrar yapılmak üzere gönderilecek. '
      'Devam etmek istiyor musunuz?',
      baslik: 'Asıl iş tekrar edilsin',
      onayYazisi: 'Tekrar ettir',
      tehlikeli: true,
    );

    if (!onay) return;

    await _islemYap(
      () => KontrolApi.tekrarEt(
        kontrolIsId: widget.kontrolIsId,
        kontrolEdenPersonelKodu: widget.kontrolEdenPersonelKodu,
      ),
      sayfayiKapat: true,
    );
  }


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
            bottom: MediaQuery.of(
              sheetContext,
            ).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(
                        99,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kontrol Puanı',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Kontrolü bitirmek için asıl işe verilecek puanı girin.',
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
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
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '1 - 10',
                      filled: true,
                      fillColor: const Color(0xFFF5F6F8),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: Colors.black.withOpacity(.06),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Colors.green,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      girilenPuan = value.trim();
                    },
                    onFieldSubmitted: (value) {
                      final sayi = int.tryParse(
                        value.trim(),
                      );

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

                      Navigator.of(sheetContext).pop(sayi);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Vazgeç',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () {
                            final sayi = int.tryParse(
                              girilenPuan,
                            );

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

                            Navigator.of(sheetContext).pop(sayi);
                          },
                          icon: const Icon(
                            Icons.check_rounded,
                          ),
                          label: const Text(
                            'DEVAM ET',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
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
          content: Text(mesaj),
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
          content: Text(e.toString()),
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
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: Text(
            baslik,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(mesaj),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: tehlikeli
                    ? Colors.red
                    : Colors.green,
              ),
              child: Text(onayYazisi),
            ),
          ],
        );
      },
    );

    return sonuc ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text(
          'Kontrol Detayı',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed:
                _yukleniyor ||
                        _islemYapiliyor
                    ? null
                    : _detayGetir,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: _govde(),
      bottomNavigationBar:
          _altIslemAlani(),
    );
  }

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
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _detayGetir,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              24,
            ),
            children: [
              _ustOzetKarti(),

              if (_detay!.tekrarSayisi > 0) ...[
                const SizedBox(height: 10),
                _tekrarBilgisi(),
              ],

              const SizedBox(height: 10),

              _asilIsSureleriKarti(),

              const SizedBox(height: 10),

              _kontrolSureleriKarti(),

              const SizedBox(height: 10),

              _durumBilgisi(),
            ],
          ),
        ),

        if (_islemYapiliyor)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(
                .14,
              ),
              alignment: Alignment.center,
              child: const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child:
                      CircularProgressIndicator(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _hataEkrani() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 62,
              color: Colors.red,
            ),
            const SizedBox(height: 14),
            Text(
              _hataMesaji!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _detayGetir,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Tekrar dene',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ustOzetKarti() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _kartDekorasyonu(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.green
                      .withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.green,
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _detay!.personel.isEmpty
                          ? '-'
                          : _detay!.personel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _detay!.gorev.isEmpty
                          ? '-'
                          : _detay!.gorev,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        fontWeight:
                            FontWeight.w600,
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
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _kisaBilgi(
                  Icons.grid_view_rounded,
                  'Tünel',
                  _detay!.tunel,
                ),
              ),
              _dikeyAyirici(),
              Expanded(
                child: _kisaBilgi(
                  Icons.view_column_rounded,
                  'Koridor',
                  _detay!.koridor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: Colors.black45,
              ),
              const SizedBox(width: 7),
              Text(
                'Başlangıç: ${_tarihYaz(_detay!.baslangic)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _asilIsSureleriKarti() {
    final aktifFazla =
        _detay!.azamiSaniye > 0 &&
        _detay!.aktifSaniye >
            _detay!.azamiSaniye;

    return _kart(
      baslik: 'Asıl İş Süreleri',
      ikon: Icons.work_history_rounded,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.15,
        children: [
          _sureKutusu(
            baslik: 'Aktif',
            deger: _kisaSure(
              _detay!.aktifSaniye,
            ),
            ikon:
                Icons.play_circle_outline_rounded,
            uyari: aktifFazla,
          ),
          _sureKutusu(
            baslik: 'Mola',
            deger: _kisaSure(
              _detay!.molaSaniye,
            ),
            ikon: Icons.coffee_rounded,
          ),
          _sureKutusu(
            baslik: 'Hedef',
            deger: _kisaSure(
              _detay!.hedefSaniye,
            ),
            ikon: Icons.flag_rounded,
          ),
          _sureKutusu(
            baslik: 'Azami',
            deger: _kisaSure(
              _detay!.azamiSaniye,
            ),
            ikon: Icons.timer_rounded,
          ),
        ],
      ),
    );
  }

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
          const SizedBox(width: 8),
          Expanded(
            child: _kontrolSureKutusu(
              'Ara',
              _saatFormat(
                _araSaniye,
              ),
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
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

  Widget _durumBilgisi() {
    final durum = _detay!.kontrolDurum;

    late final Color renk;
    late final IconData ikon;
    late final String baslik;
    late final String aciklama;

    switch (durum) {
      case 1:
        renk = Colors.green;
        ikon = Icons.play_circle_rounded;
        baslik = 'Kontrol devam ediyor';
        aciklama =
            'Kontrol süresi çalışıyor.';
        break;

      case 2:
        renk = Colors.orange;
        ikon = Icons.pause_circle_rounded;
        baslik = 'Kontrole ara verildi';
        aciklama =
            'Devam Et butonuyla sürdürebilirsiniz.';
        break;

      case 3:
        renk = Colors.green;
        ikon = Icons.check_circle_rounded;
        baslik = 'Kontrol tamamlandı';
        aciklama =
            _detay!.puan > 0
                ? 'Verilen puan: ${_detay!.puan.toInt()}'
                : 'Kontrol tamamlandı.';
        break;

      default:
        renk = Colors.blue;
        ikon = Icons.info_rounded;
        baslik = 'Kontrol bekliyor';
        aciklama =
            'Başla butonuna basarak kontrolü başlatın.';
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: renk.withOpacity(.09),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: renk.withOpacity(.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ikon,
            color: renk,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: TextStyle(
                    color: renk,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  aciklama,
                  style: TextStyle(
                    color:
                        renk.withOpacity(.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _altIslemAlani() {
    if (_yukleniyor ||
        _hataMesaji != null ||
        _detay == null) {
      return null;
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          12,
          10,
          12,
          10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
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
                ikon:
                    Icons.play_arrow_rounded,
                renk: Colors.green,
                onPressed: _durumDegistir,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ikincilButon(
                yazi: 'Tekrar',
                ikon:
                    Icons.replay_rounded,
                renk: Colors.orange,
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
                renk: Colors.orange,
                onPressed: _durumDegistir,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _anaButon(
                yazi: 'BİTİR',
                ikon: Icons.stop_rounded,
                renk: Colors.red,
                onPressed: _bitir,
              ),
            ),
          ],
        );

      case 2:
  return _anaButon(
    yazi: 'DEVAM ET',
    ikon: Icons.play_arrow_rounded,
    renk: Colors.green,
    onPressed: _durumDegistir,
  );

     case 3:
  return const SizedBox.shrink();
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
      height: 56,
      child: FilledButton.icon(
        onPressed:
            _islemYapiliyor
                ? null
                : onPressed,
        icon: Icon(
          ikon,
          size: 25,
        ),
        label: Text(
          yazi,
          maxLines: 1,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: renk,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
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
      height: 56,
      child: OutlinedButton(
        onPressed:
            _islemYapiliyor
                ? null
                : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: renk,
          side: BorderSide(
            color: renk.withOpacity(.55),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              ikon,
              size: 21,
            ),
            const SizedBox(height: 1),
            Text(
              yazi,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tekrarBilgisi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color: Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.replay_rounded,
            color: Colors.orange.shade800,
            size: 21,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bu iş ${_detay!.tekrarSayisi} defa tekrar edildi.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kart({
    required String baslik,
    required IconData ikon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _kartDekorasyonu(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ikon,
                size: 20,
                color: Colors.black54,
              ),
              const SizedBox(width: 7),
              Text(
                baslik,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  BoxDecoration _kartDekorasyonu() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(18),
      border: Border.all(
        color: Colors.black.withOpacity(.05),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.025),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _kisaBilgi(
    IconData ikon,
    String baslik,
    String deger,
  ) {
    return Row(
      children: [
        Icon(
          ikon,
          size: 21,
          color: Colors.black45,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              baslik,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
            Text(
              deger.isEmpty ? '-' : deger,
              style: const TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dikeyAyirici() {
    return Container(
      width: 1,
      height: 35,
      margin:
          const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      color: Colors.black.withOpacity(.07),
    );
  }

  Widget _durumRozeti(
    String durum,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(.10),
        borderRadius:
            BorderRadius.circular(99),
      ),
      child: Text(
        durum.isEmpty ? '-' : durum,
        style: const TextStyle(
          color: Colors.green,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _sureKutusu({
    required String baslik,
    required String deger,
    required IconData ikon,
    bool uyari = false,
  }) {
    final renk =
        uyari ? Colors.red : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: uyari
            ? Colors.red.withOpacity(.08)
            : const Color(0xFFF7F8FA),
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color: uyari
              ? Colors.red.withOpacity(.25)
              : Colors.black.withOpacity(.04),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ikon,
            size: 21,
            color: uyari
                ? Colors.red
                : Colors.black45,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),
                Text(
                  deger,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: renk,
                    fontSize: 14,
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

  Widget _kontrolSureKutusu(
    String baslik,
    String deger,
    Color renk,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: renk.withOpacity(.08),
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            baslik,
            style: TextStyle(
              fontSize: 11,
              color: renk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              deger,
              style: TextStyle(
                color: renk,
                fontSize: 16,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tarihYaz(
    DateTime? tarih,
  ) {
    if (tarih == null) return '-';

    final gun =
        tarih.day.toString().padLeft(2, '0');

    final ay =
        tarih.month.toString().padLeft(2, '0');

    final yil = tarih.year.toString();

    final saat =
        tarih.hour.toString().padLeft(2, '0');

    final dakika =
        tarih.minute.toString().padLeft(2, '0');

    return '$gun.$ay.$yil $saat:$dakika';
  }

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
      return '0 sn';
    }

    final saat =
        toplamSaniye ~/ 3600;

    final dakika =
        (toplamSaniye % 3600) ~/ 60;

    final saniye =
        toplamSaniye % 60;

    final parcalar = <String>[];

    if (saat > 0) {
      parcalar.add('$saat sa');
    }

    if (dakika > 0) {
      parcalar.add('$dakika dk');
    }

    if (saat == 0 && dakika == 0) {
      parcalar.add('$saniye sn');
    }

    return parcalar.join(' ');
  }
}