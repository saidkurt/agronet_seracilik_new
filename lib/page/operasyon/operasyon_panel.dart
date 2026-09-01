import 'dart:async';
import 'dart:typed_data';

import 'package:agronet/api/operasyon_api.dart';
import 'package:agronet/models/login_user_model.dart';
import 'package:agronet/models/operasyon_models.dart';
import 'package:agronet/page/operasyon/kutu_tarama_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class OperasyonPanel extends StatefulWidget {
  final LoginUserModel user;

  const OperasyonPanel({
    super.key,
    required this.user,
  });

  static bool seraPersoneliMi(LoginUserModel user) {
    final tip = user.tip?.trim() ?? '';
    return RegExp(
      r'^[1-5]\s*\.\s*Sera Kültürel İşlem Elemanı$',
      caseSensitive: false,
    ).hasMatch(tip);
  }

  @override
  State<OperasyonPanel> createState() => _OperasyonPanelState();
}

enum _PanelEkrani {
  ana,
  bekleyenGruplar,
  seralar,
  isler,
  tuneller,
  koridorlar,
  durumIsleri,
  detay,
}

class _OperasyonPanelState extends State<OperasyonPanel> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color background = Color(0xFFF5F6F8);
  static const Color cardBorder = Color(0xFFE3ECE8);
  static const Color muted = Color(0xFF6F8079);
  static const Color bekleyenRenk = Color(0xFF3F6FE5);
  static const Color araRenk = Color(0xFFE79A1A);
  static const Color tekrarRenk = Color(0xFFC94F55);

  late final OperasyonApi _api;
  Timer? _timer;

  _PanelEkrani _ekran = _PanelEkrani.ana;
  _PanelEkrani _detayGeri = _PanelEkrani.ana;
  OperasyonOzet? _ozet;
  BekleyenGruplar? _gruplar;
  OperasyonDetay? _detay;
  DateTime _detayZamani = DateTime.now();

  List<OperasyonSecim> _secimler = const [];
  List<OperasyonTunel> _tuneller = const [];
  List<OperasyonKoridor> _koridorlar = const [];
  List<OperasyonIs> _durumIsleri = const [];

  bool _oncelikli = false;
  int _secilenDurum = 0;
  String _bolumKodu = '';
  String _isKodu = '';
  String _isAdi = '';
  int _isSeviyesi = 0;
  String _tunel = '';

  bool _yukleniyor = true;
  bool _islemYapiliyor = false;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _api = OperasyonApi(user: widget.user);
    unawaited(_ilkYukleme());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _ekran == _PanelEkrani.detay &&
          (_detay?.durum == 1 || _detay?.durum == 2)) {
        setState(() {});
      }
    });
  }

  Future<void> _ilkYukleme() async {
    if (mounted) {
      setState(() {
        _yukleniyor = true;
        _hata = null;
      });
    }
    try {
      final ozet = await _api.ozet();
      var ekran = _PanelEkrani.ana;
      var durumIsleri = const <OperasyonIs>[];
      OperasyonDetay? detay;

      if (ozet.aktif > 0) {
        durumIsleri = await _api.durumIsleri(1);
        if (durumIsleri.length == 1) {
          detay = await _api.detay(durumIsleri.first.isEmriId);
          ekran = _PanelEkrani.detay;
        } else if (durumIsleri.isNotEmpty) {
          ekran = _PanelEkrani.durumIsleri;
        }
      }

      if (!mounted) return;
      setState(() {
        _ozet = ozet;
        _durumIsleri = durumIsleri;
        _detay = detay;
        _detayZamani = DateTime.now();
        _secilenDurum = 1;
        _detayGeri = _PanelEkrani.ana;
        _ekran = ekran;
        _hata = null;
      });
    } catch (e) {
      if (mounted) setState(() => _hata = _hataMetni(e));
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _calistir(Future<void> Function() islem) async {
    if (_yukleniyor || _islemYapiliyor) return;
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      await islem();
    } catch (e) {
      if (mounted) setState(() => _hata = _hataMetni(e));
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _anaSayfayaDon() async {
    await _calistir(() async {
      final veri = await _api.ozet();
      if (!mounted) return;
      setState(() {
        _ozet = veri;
        _ekran = _PanelEkrani.ana;
        _detay = null;
        _secimleriTemizle();
      });
    });
  }

  Future<void> _bekleyenGruplariAc() async {
    await _calistir(() async {
      final veri = await _api.bekleyenGruplar();
      if (!mounted) return;
      setState(() {
        _gruplar = veri;
        _secilenDurum = 0;
        _ekran = _PanelEkrani.bekleyenGruplar;
        _secimleriTemizle();
      });
    });
  }

  Future<void> _bekleyenTipiSec(bool oncelikli, int adet) async {
    if (adet <= 0) {
      _mesaj('Bu grupta iş bulunmuyor.');
      return;
    }
    await _calistir(() async {
      final veri = await _api.seralar(oncelikli);
      if (!mounted) return;
      setState(() {
        _oncelikli = oncelikli;
        _secimler = veri;
        _ekran = _PanelEkrani.seralar;
      });
    });
  }

  Future<void> _seraSec(OperasyonSecim secim) async {
    await _calistir(() async {
      final veri = await _api.isler(
        bolumKodu: secim.kod,
        oncelikli: _oncelikli,
      );
      if (!mounted) return;
      setState(() {
        _bolumKodu = secim.kod;
        _secimler = veri;
        _ekran = _PanelEkrani.isler;
      });
    });
  }

  Future<void> _isSec(OperasyonSecim secim) async {
    await _calistir(() async {
      final veri = await _api.tuneller(
        bolumKodu: _bolumKodu,
        isKodu: secim.kod,
        isSeviyesi: secim.isSeviyesi,
        oncelikli: _oncelikli,
      );
      if (!mounted) return;
      setState(() {
        _isKodu = secim.kod;
        _isAdi = secim.isim;
        _isSeviyesi = secim.isSeviyesi;
        _tuneller = veri;
        _ekran = _PanelEkrani.tuneller;
      });
    });
  }

  Future<void> _tunelSec(OperasyonTunel secim) async {
    await _calistir(() async {
      final veri = await _api.koridorlar(
        bolumKodu: _bolumKodu,
        isKodu: _isKodu,
        isSeviyesi: _isSeviyesi,
        tunel: secim.tunel,
        oncelikli: _oncelikli,
      );
      if (!mounted) return;
      setState(() {
        _tunel = secim.tunel;
        _koridorlar = veri;
        _ekran = _PanelEkrani.koridorlar;
      });
    });
  }

  Future<void> _durumIsleriniAc(int durum) async {
    final adet = _durumAdedi(durum);
    if (adet <= 0) {
      _mesaj('Bu bölümde iş bulunmuyor.');
      return;
    }
    await _calistir(() async {
      final veri = await _api.durumIsleri(durum);
      if (!mounted) return;
      if (durum == 1 && veri.length == 1) {
        final detay = await _api.detay(veri.first.isEmriId);
        if (!mounted) return;
        setState(() {
          _secilenDurum = durum;
          _durumIsleri = veri;
          _detay = detay;
          _detayZamani = DateTime.now();
          _detayGeri = _PanelEkrani.ana;
          _ekran = _PanelEkrani.detay;
        });
      } else {
        setState(() {
          _secilenDurum = durum;
          _durumIsleri = veri;
          _ekran = _PanelEkrani.durumIsleri;
        });
      }
    });
  }

  Future<void> _detayiAc(int isEmriId) async {
    final geri = _ekran;
    await _calistir(() async {
      final detay = await _api.detay(isEmriId);
      if (!mounted) return;
      setState(() {
        _detay = detay;
        _detayZamani = DateTime.now();
        _detayGeri = geri;
        _ekran = _PanelEkrani.detay;
      });
    });
  }

  Future<void> _yenile() async {
    await _calistir(() async {
      final ozet = await _api.ozet();
      if (!mounted) return;

      switch (_ekran) {
        case _PanelEkrani.ana:
          setState(() => _ozet = ozet);
          break;
        case _PanelEkrani.bekleyenGruplar:
          final grupVerisi = await _api.bekleyenGruplar();
          if (mounted) setState(() {
            _ozet = ozet;
            _gruplar = grupVerisi;
          });
          break;
        case _PanelEkrani.seralar:
          final seraVerisi = await _api.seralar(_oncelikli);
          if (mounted) setState(() {
            _ozet = ozet;
            _secimler = seraVerisi;
          });
          break;
        case _PanelEkrani.isler:
          final isVerisi = await _api.isler(
            bolumKodu: _bolumKodu,
            oncelikli: _oncelikli,
          );
          if (mounted) setState(() {
            _ozet = ozet;
            _secimler = isVerisi;
          });
          break;
        case _PanelEkrani.tuneller:
          final tunelVerisi = await _api.tuneller(
            bolumKodu: _bolumKodu,
            isKodu: _isKodu,
            isSeviyesi: _isSeviyesi,
            oncelikli: _oncelikli,
          );
          if (mounted) setState(() {
            _ozet = ozet;
            _tuneller = tunelVerisi;
          });
          break;
        case _PanelEkrani.koridorlar:
          final koridorVerisi = await _api.koridorlar(
            bolumKodu: _bolumKodu,
            isKodu: _isKodu,
            isSeviyesi: _isSeviyesi,
            tunel: _tunel,
            oncelikli: _oncelikli,
          );
          if (mounted) setState(() {
            _ozet = ozet;
            _koridorlar = koridorVerisi;
          });
          break;
        case _PanelEkrani.durumIsleri:
          final durumVerisi = await _api.durumIsleri(_secilenDurum);
          if (mounted) setState(() {
            _ozet = ozet;
            _durumIsleri = durumVerisi;
          });
          break;
        case _PanelEkrani.detay:
          final detay = await _api.detay(_detay!.isEmriId);
          if (mounted) setState(() {
            _ozet = ozet;
            _detay = detay;
            _detayZamani = DateTime.now();
          });
          break;
      }
    });
  }

  void _geri() {
    setState(() {
      switch (_ekran) {
        case _PanelEkrani.bekleyenGruplar:
          _ekran = _PanelEkrani.ana;
          break;
        case _PanelEkrani.seralar:
          _ekran = _PanelEkrani.bekleyenGruplar;
          break;
        case _PanelEkrani.isler:
          _ekran = _PanelEkrani.seralar;
          break;
        case _PanelEkrani.tuneller:
          _ekran = _PanelEkrani.isler;
          break;
        case _PanelEkrani.koridorlar:
          _ekran = _PanelEkrani.tuneller;
          break;
        case _PanelEkrani.durumIsleri:
          _ekran = _PanelEkrani.ana;
          break;
        case _PanelEkrani.detay:
          _ekran = _detayGeri;
          break;
        case _PanelEkrani.ana:
          break;
      }
      _hata = null;
    });
  }

  Future<void> _durumDegistir() async {
    final detay = _detay;
    if (detay == null) return;

    var araSebebi = '';
    if (detay.durum == 2) {
      try {
        final liste = await _api.araSebepleri();
        if (!mounted) return;
        final secilen = await _kodIsimSec('Ara verme sebebi', liste);
        if (secilen == null) return;
        araSebebi = secilen.kod;
      } catch (e) {
        _mesaj(_hataMetni(e));
        return;
      }
    }

    await _islemYap(() async {
      final sonuc = await _api.durumDegistir(
        isEmriId: detay.isEmriId,
        araSebebi: araSebebi,
      );
      if (!sonuc.basarili) throw Exception(sonuc.mesaj);
      _mesaj(sonuc.mesaj);
      final yeniDetay = await _api.detay(detay.isEmriId);
      final yeniOzet = await _api.ozet();
      if (!mounted) return;
      setState(() {
        _detay = yeniDetay;
        _ozet = yeniOzet;
        _secilenDurum = yeniDetay.durum;
        _detayZamani = DateTime.now();
      });
    });
  }

  Future<void> _bitir() async {
    final detay = _detay;
    if (detay == null) return;

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşi tamamla'),
        content: const Text('Bu işi tamamlamak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) return;

    var sokulenAdet = 0;
    var sokumNedeni = '';
    if (detay.bitkiSokumu) {
      final adet = await _sayiGir('Sökülen bitki sayısı');
      if (adet == null || !mounted) return;
      sokulenAdet = adet;

      if (sokulenAdet > 0) {
        try {
          final nedenler = await _api.sokumNedenleri();
          if (!mounted) return;
          final secilen = await _kodIsimSec('Söküm nedeni', nedenler);
          if (secilen == null) return;
          sokumNedeni = secilen.kod;
        } catch (e) {
          _mesaj(_hataMetni(e));
          return;
        }
      }
    }

    await _islemYap(() async {
      final sonuc = await _api.bitir(
        isEmriId: detay.isEmriId,
        sokulenBitkiSayisi: sokulenAdet,
        sokumNedeni: sokumNedeni,
      );
      if (!sonuc.basarili) throw Exception(sonuc.mesaj);
      _mesaj(sonuc.mesaj);
      final yeniOzet = await _api.ozet();
      if (!mounted) return;
      setState(() {
        _ozet = yeniOzet;
        _detay = null;
        _ekran = _PanelEkrani.ana;
        _secimleriTemizle();
      });
    });
  }

  Future<void> _kutuEkrani(bool cikar) async {
    final detay = _detay;
    if (detay == null) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => KutuTaramaPage(
          api: _api,
          isEmriId: detay.isEmriId,
          cikar: cikar,
        ),
      ),
    );
    if (!mounted) return;
    await _calistir(() async {
      final yeniDetay = await _api.detay(detay.isEmriId);
      if (mounted) setState(() {
        _detay = yeniDetay;
        _detayZamani = DateTime.now();
      });
    });
  }

  Future<void> _islemYap(Future<void> Function() islem) async {
    if (_islemYapiliyor || _yukleniyor) return;
    setState(() {
      _islemYapiliyor = true;
      _hata = null;
    });
    try {
      await islem();
    } catch (e) {
      _mesaj(_hataMetni(e));
    } finally {
      if (mounted) setState(() => _islemYapiliyor = false);
    }
  }

  Future<OperasyonKodIsim?> _kodIsimSec(
    String baslik,
    List<OperasyonKodIsim> liste,
  ) {
    return showModalBottomSheet<OperasyonKodIsim>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Text(
                baslik,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: liste.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = liste[index];
                  return ListTile(
                    title: Text(item.isim),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _sayiGir(String baslik) async {
    final controller = TextEditingController();
    final sonuc = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(baslik),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: '0'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              int.tryParse(controller.text.trim()) ?? 0,
            ),
            child: const Text('Devam'),
          ),
        ],
      ),
    );
    controller.dispose();
    return sonuc;
  }

  void _secimleriTemizle() {
    _bolumKodu = '';
    _isKodu = '';
    _isAdi = '';
    _isSeviyesi = 0;
    _tunel = '';
    _secimler = const [];
    _tuneller = const [];
    _koridorlar = const [];
  }

  int _durumAdedi(int durum) {
    final o = _ozet;
    if (o == null) return 0;
    switch (durum) {
      case 0:
        return o.bekleyen;
      case 1:
        return o.aktif;
      case 2:
        return o.araVerilen;
      case 5:
        return o.tekrar;
      default:
        return 0;
    }
  }

  String get _ekranBasligi {
    switch (_ekran) {
      case _PanelEkrani.ana:
        return 'İş Operasyonları';
      case _PanelEkrani.bekleyenGruplar:
        return 'Bekleyen İşler';
      case _PanelEkrani.seralar:
        return 'Sera Seçin';
      case _PanelEkrani.isler:
        return 'İş Seçin';
      case _PanelEkrani.tuneller:
        return 'Tünel Seçin';
      case _PanelEkrani.koridorlar:
        return 'Koridor Seçin';
      case _PanelEkrani.durumIsleri:
        return _durumBasligi(_secilenDurum);
      case _PanelEkrani.detay:
        return 'Operasyon';
    }
  }

  String get _secimYolu {
    final parcalar = <String>[
      if (_oncelikli && _ekran.index >= _PanelEkrani.seralar.index) 'Öncelikli',
      if (!_oncelikli && _ekran.index >= _PanelEkrani.seralar.index) 'Haftalık',
      if (_bolumKodu.isNotEmpty) _bolumKodu,
      if (_isAdi.isNotEmpty) _isAdi,
      if (_tunel.isNotEmpty) _tunel,
    ];
    return parcalar.join('  ›  ');
  }

  int get _gecenSaniye => DateTime.now().difference(_detayZamani).inSeconds;

  int get _aktifSaniye {
    final d = _detay!;
    return d.aktifSaniye + (d.durum == 1 ? _gecenSaniye : 0);
  }

  int get _araSaniye {
    final d = _detay!;
    return d.araSaniye + (d.durum == 2 ? _gecenSaniye : 0);
  }

  void _mesaj(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj)),
    );
  }

  String _hataMetni(Object hata) {
    return hata.toString().replaceFirst('Exception: ', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_ozet == null && _yukleniyor) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: accent)),
      );
    }

    if (_ozet == null && _hata != null) {
      return _HataKutusu(mesaj: _hata!, tekrar: _ilkYukleme);
    }

    final tema = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.08);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: Theme(
        data: tema.copyWith(
          colorScheme: tema.colorScheme.copyWith(
            primary: accent,
            secondary: accent,
          ),
          textTheme: tema.textTheme.apply(
            fontFamily: 'Montserrat',
            bodyColor: Colors.black87,
            displayColor: Colors.black87,
          ),
          primaryTextTheme: tema.primaryTextTheme.apply(
            fontFamily: 'Montserrat',
          ),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: 'Montserrat'),
          child: Container(
            color: background,
            child: AbsorbPointer(
              absorbing: _islemYapiliyor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_ekran == _PanelEkrani.ana)
                    _anaBaslik()
                  else ...[
                    _miniOzet(),
                    const SizedBox(height: 7),
                    _gezinmeBasligi(),
                    if (_secimYolu.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _YolGostergesi(metin: _secimYolu),
                    ],
                  ],
                  if (_yukleniyor) ...[
                    const SizedBox(height: 6),
                    const LinearProgressIndicator(
                      minHeight: 2,
                      color: accent,
                      backgroundColor: Color(0xFFDDE8E5),
                    ),
                  ],
                  if (_hata != null) ...[
                    const SizedBox(height: 7),
                    _HataKutusu(mesaj: _hata!, tekrar: _yenile),
                  ],
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: KeyedSubtree(
                      key: ValueKey(_ekran),
                      child: _icerik(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _anaBaslik() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 4, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 7),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withOpacity(.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İŞ OPERASYONLARI',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 2),
                Text(
                  'Yapacağınız işlemi seçin',
                  style: TextStyle(
                    fontSize: 8.8,
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Yenile',
            visualDensity: VisualDensity.compact,
            onPressed: _yukleniyor ? null : _yenile,
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _miniOzet() {
    final o = _ozet!;
    return Row(
      children: [
        Expanded(
          child: _MiniDurum(
            etiket: 'Bekleyen',
            adet: o.bekleyen,
            renk: bekleyenRenk,
            secili: _ekran != _PanelEkrani.detay && _secilenDurum == 0,
            onTap: _bekleyenGruplariAc,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _MiniDurum(
            etiket: 'Ara',
            adet: o.araVerilen,
            renk: araRenk,
            secili: _secilenDurum == 2,
            onTap: () => _durumIsleriniAc(2),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _MiniDurum(
            etiket: 'Aktif',
            adet: o.aktif,
            renk: accent,
            secili: _secilenDurum == 1,
            onTap: () => _durumIsleriniAc(1),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _MiniDurum(
            etiket: 'Tekrar',
            adet: o.tekrar,
            renk: tekrarRenk,
            secili: _secilenDurum == 5,
            onTap: () => _durumIsleriniAc(5),
          ),
        ),
      ],
    );
  }

  Widget _gezinmeBasligi() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Geri',
            onPressed: _geri,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          Expanded(
            child: Text(
              _ekranBasligi,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            tooltip: 'Ana operasyon ekranı',
            onPressed: _anaSayfayaDon,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.home_rounded, size: 19),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _yukleniyor ? null : _yenile,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh_rounded, size: 19),
          ),
        ],
      ),
    );
  }

  Widget _icerik() {
    switch (_ekran) {
      case _PanelEkrani.ana:
        return _anaIcerik();
      case _PanelEkrani.bekleyenGruplar:
        return _grupIcerik();
      case _PanelEkrani.seralar:
        return _secimIcerik(Icons.home_work_rounded, _seraSec);
      case _PanelEkrani.isler:
        return _secimIcerik(Icons.agriculture_rounded, _isSec);
      case _PanelEkrani.tuneller:
        return _tunelIcerik();
      case _PanelEkrani.koridorlar:
        return _koridorIcerik();
      case _PanelEkrani.durumIsleri:
        return _durumIsleriIcerik();
      case _PanelEkrani.detay:
        return _detayIcerik();
    }
  }

  Widget _anaIcerik() {
    final o = _ozet!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
      children: [
        _OperasyonKart(
          baslik: 'Bekleyen İşler',
          adet: o.bekleyen,
          icon: Icons.pending_actions_rounded,
          renk: bekleyenRenk,
          onTap: _bekleyenGruplariAc,
        ),
        _OperasyonKart(
          baslik: 'Ara Verilen İşler',
          adet: o.araVerilen,
          icon: Icons.pause_circle_filled_rounded,
          renk: araRenk,
          onTap: () => _durumIsleriniAc(2),
        ),
        _OperasyonKart(
          baslik: 'Devam Eden İşler',
          adet: o.aktif,
          icon: Icons.play_circle_fill_rounded,
          renk: accent,
          onTap: () => _durumIsleriniAc(1),
        ),
        _OperasyonKart(
          baslik: 'Tekrar Edilecek',
          adet: o.tekrar,
          icon: Icons.replay_circle_filled_rounded,
          renk: tekrarRenk,
          onTap: () => _durumIsleriniAc(5),
        ),
      ],
    );
  }

  Widget _grupIcerik() {
    final veri = _gruplar;
    if (veri == null) return _bos('Bekleyen iş bilgisi yüklenemedi.');
    return Column(
      children: [
        _GrupKart(
          baslik: 'Öncelikli İşler',
          aciklama: 'Yapılma süresi geçmiş işler',
          adet: veri.oncelikli,
          renk: tekrarRenk,
          icon: Icons.priority_high_rounded,
          onTap: () => _bekleyenTipiSec(true, veri.oncelikli),
        ),
        const SizedBox(height: 9),
        _GrupKart(
          baslik: 'Haftalık İşler',
          aciklama: 'Planlanan dönem içindeki işler',
          adet: veri.haftalik,
          renk: bekleyenRenk,
          icon: Icons.calendar_month_rounded,
          onTap: () => _bekleyenTipiSec(false, veri.haftalik),
        ),
      ],
    );
  }

  Widget _secimIcerik(
    IconData icon,
    Future<void> Function(OperasyonSecim) onTap,
  ) {
    if (_secimler.isEmpty) return _bos('Gösterilecek kayıt bulunamadı.');
    return Column(
      children: [
        for (var i = 0; i < _secimler.length; i++) ...[
          _ListeKart(
            baslik: _secimler[i].isim,
            altBaslik: '${_secimler[i].adet} adet',
            resim: _secimler[i].resim,
            icon: icon,
            onTap: () => onTap(_secimler[i]),
          ),
          if (i != _secimler.length - 1) const SizedBox(height: 7),
        ],
      ],
    );
  }

  Widget _tunelIcerik() {
    if (_tuneller.isEmpty) return _bos('Gösterilecek tünel bulunamadı.');
    return Column(
      children: [
        for (var i = 0; i < _tuneller.length; i++) ...[
          _ListeKart(
            baslik: _tuneller[i].tunel,
            altBaslik: '${_tuneller[i].yon} • ${_tuneller[i].adet} adet • '
                'Son: ${_tarih(_tuneller[i].sonYapilmaTarihi)}',
            icon: Icons.view_week_rounded,
            onTap: () => _tunelSec(_tuneller[i]),
          ),
          if (i != _tuneller.length - 1) const SizedBox(height: 7),
        ],
      ],
    );
  }

  Widget _koridorIcerik() {
    if (_koridorlar.isEmpty) return _bos('Gösterilecek koridor bulunamadı.');
    return Column(
      children: [
        for (var i = 0; i < _koridorlar.length; i++) ...[
          _ListeKart(
            baslik: 'Koridor ${_koridorlar[i].koridor}',
            altBaslik: 'Son yapılma: ${_tarih(_koridorlar[i].sonYapilmaTarihi)}',
            icon: Icons.table_rows_rounded,
            onTap: () => _detayiAc(_koridorlar[i].isEmriId),
          ),
          if (i != _koridorlar.length - 1) const SizedBox(height: 7),
        ],
      ],
    );
  }

  Widget _durumIsleriIcerik() {
    if (_durumIsleri.isEmpty) return _bos('Gösterilecek iş bulunamadı.');
    return Column(
      children: [
        for (var i = 0; i < _durumIsleri.length; i++) ...[
          _ListeKart(
            baslik: _durumIsleri[i].isAdi,
            altBaslik: '${_durumIsleri[i].bolumKodu} • '
                '${_durumIsleri[i].tunel} • Koridor ${_durumIsleri[i].koridor}',
            resim: _durumIsleri[i].resim,
            icon: Icons.agriculture_rounded,
            onTap: () => _detayiAc(_durumIsleri[i].isEmriId),
          ),
          if (i != _durumIsleri.length - 1) const SizedBox(height: 7),
        ],
      ],
    );
  }

  Widget _detayIcerik() {
    final d = _detay;
    if (d == null) return _bos('Operasyon bilgisi bulunamadı.');

    final aktif = _aktifSaniye;
    final ara = _araSaniye;
    final azamiGecildi = d.azamiSaniye > 0 && aktif > d.azamiSaniye;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetayBaslik(detay: d),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _SureKart(
                baslik: 'Çalışılan',
                saniye: aktif,
                renk: azamiGecildi ? Colors.red : accent,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _SureKart(
                baslik: 'Ara',
                saniye: ara,
                renk: araRenk,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _SureKart(
                baslik: 'Toplam',
                saniye: aktif + ara,
                renk: bekleyenRenk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _HedefSatiri(detay: d),
        if (d.maxEtiketAdedi > 0) ...[
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: d.durum == 1 ? () => _kutuEkrani(false) : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: const BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text('Kutu Ekle (${d.eklenenKutuSayisi})'),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: d.durum == 1 ? () => _kutuEkrani(true) : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tekrarRenk,
                    side: const BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  label: const Text('Kutu Çıkar'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 13),
        if (d.durum == 0 || d.durum == 1 || d.durum == 2 || d.durum == 5)
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _islemYapiliyor ? null : _durumDegistir,
              icon: Icon(d.durum == 1
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded),
              label: Text(
                d.durum == 1
                    ? 'ARA VER'
                    : d.durum == 2
                        ? 'DEVAM ET'
                        : 'İŞİ BAŞLAT',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        if (d.durum == 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: tekrarRenk,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _islemYapiliyor ? null : _bitir,
              icon: const Icon(Icons.stop_circle_rounded),
              label: const Text(
                'İŞİ TAMAMLA',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
        if (_islemYapiliyor) ...[
          const SizedBox(height: 10),
          const Center(child: CircularProgressIndicator(color: accent)),
        ],
      ],
    );
  }

  Widget _bos(String metin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 38, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            metin,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _api.dispose();
    super.dispose();
  }
}

class _OperasyonKart extends StatelessWidget {
  final String baslik;
  final int adet;
  final IconData icon;
  final Color renk;
  final VoidCallback onTap;

  const _OperasyonKart({
    required this.baslik,
    required this.adet,
    required this.icon,
    required this.renk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDCE6E2), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: adet > 0
                    ? [renk.withOpacity(.78), renk]
                    : [const Color(0xFFB7C1BD), const Color(0xFF8F9B96)],
              ),
              border: Border.all(color: Colors.white.withOpacity(.75), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 19),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$adet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    baslik.toUpperCase(),
                    maxLines: 3,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniDurum extends StatelessWidget {
  final String etiket;
  final int adet;
  final Color renk;
  final bool secili;
  final VoidCallback onTap;

  const _MiniDurum({
    required this.etiket,
    required this.adet,
    required this.renk,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: secili ? renk : Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: secili ? renk : const Color(0xFFE3ECE8),
            ),
          ),
          child: Column(
            children: [
              Text(
                '$adet',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.05,
                  color: secili ? Colors.white : renk,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                etiket,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8.2,
                  color: secili ? Colors.white : const Color(0xFF6F8079),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrupKart extends StatelessWidget {
  final String baslik;
  final String aciklama;
  final int adet;
  final Color renk;
  final IconData icon;
  final VoidCallback onTap;

  const _GrupKart({
    required this.baslik,
    required this.aciklama,
    required this.adet,
    required this.renk,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 9, 7, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFE3ECE8)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: renk,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 7),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: renk.withOpacity(.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: renk, size: 20),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      aciklama,
                      style: const TextStyle(
                        fontSize: 8.7,
                        color: Color(0xFF6F8079),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$adet',
                style: TextStyle(fontSize: 20, color: renk, fontWeight: FontWeight.w900),
              ),
              const Icon(Icons.chevron_right_rounded, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListeKart extends StatelessWidget {
  final String baslik;
  final String altBaslik;
  final Uint8List? resim;
  final IconData icon;
  final VoidCallback onTap;

  const _ListeKart({
    required this.baslik,
    required this.altBaslik,
    this.resim,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 7, 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFE3ECE8)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E6F5C),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 42,
                  height: 42,
                  color: const Color(0xFFEDF4F1),
                  child: resim != null
                      ? Image.memory(resim!, fit: BoxFit.cover)
                      : Icon(icon, color: const Color(0xFF1E6F5C), size: 20),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      altBaslik,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: Color(0xFF6F8079),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class _YolGostergesi extends StatelessWidget {
  final String metin;

  const _YolGostergesi({required this.metin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F0ED),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        metin,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF155E4E),
          fontSize: 8.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetayBaslik extends StatelessWidget {
  final OperasyonDetay detay;

  const _DetayBaslik({required this.detay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 9, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE3ECE8)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF1E6F5C),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 50,
              color: const Color(0xFFEDF4F1),
              child: detay.resim == null
                  ? const Icon(
                      Icons.agriculture_rounded,
                      size: 24,
                      color: Color(0xFF1E6F5C),
                    )
                  : Image.memory(detay.resim!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detay.isAdi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.2, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '${detay.bolumKodu} • ${detay.tunel} • Koridor ${detay.koridor}',
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFF6F8079),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F0ED),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    detay.durumAdi,
                    style: const TextStyle(
                      color: Color(0xFF155E4E),
                      fontSize: 8.2,
                      fontWeight: FontWeight.w900,
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
}

class _SureKart extends StatelessWidget {
  final String baslik;
  final int saniye;
  final Color renk;

  const _SureKart({
    required this.baslik,
    required this.saniye,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: renk.withOpacity(.20)),
      ),
      child: Column(
        children: [
          Text(
            _sure(saniye),
            style: TextStyle(fontSize: 12.5, color: renk, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            baslik,
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xFF6F8079),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HedefSatiri extends StatelessWidget {
  final OperasyonDetay detay;

  const _HedefSatiri({required this.detay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE3ECE8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _hedef('Ortalama', detay.ortalamaSaniye),
          ),
          Container(width: 1, height: 26, color: const Color(0xFFE3ECE8)),
          Expanded(
            child: _hedef('Azami', detay.azamiSaniye),
          ),
          Container(width: 1, height: 26, color: const Color(0xFFE3ECE8)),
          Expanded(
            child: _hedef('Minimum', detay.minimumSaniye),
          ),
        ],
      ),
    );
  }

  Widget _hedef(String baslik, int saniye) {
    return Column(
      children: [
        Text(
          saniye > 0 ? _sure(saniye) : '-',
          style: const TextStyle(fontSize: 10.2, fontWeight: FontWeight.w900),
        ),
        Text(
          baslik,
          style: const TextStyle(
            fontSize: 7.8,
            color: Color(0xFF6F8079),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HataKutusu extends StatelessWidget {
  final String mesaj;
  final Future<void> Function() tekrar;

  const _HataKutusu({required this.mesaj, required this.tekrar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7E7),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              mesaj,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Tekrar dene',
            onPressed: tekrar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

String _sure(int toplamSaniye) {
  final saniye = toplamSaniye < 0 ? 0 : toplamSaniye;
  final saat = saniye ~/ 3600;
  final dakika = (saniye % 3600) ~/ 60;
  final kalan = saniye % 60;
  return '${saat.toString().padLeft(2, '0')}:'
      '${dakika.toString().padLeft(2, '0')}:'
      '${kalan.toString().padLeft(2, '0')}';
}

String _tarih(DateTime? tarih) {
  if (tarih == null || tarih.year <= 1900) return '-';
  return DateFormat('dd.MM.yyyy').format(tarih);
}

String _durumBasligi(int durum) {
  switch (durum) {
    case 1:
      return 'Devam Eden İşler';
    case 2:
      return 'Ara Verilen İşler';
    case 5:
      return 'Tekrar Edilecek İşler';
    default:
      return 'İşler';
  }
}
