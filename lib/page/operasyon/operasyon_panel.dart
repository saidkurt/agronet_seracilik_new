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
  Timer? _loadingTimer;
  final ValueNotifier<int> _saatTick = ValueNotifier<int>(0);

  _PanelEkrani _ekran = _PanelEkrani.ana;
  _PanelEkrani _detayGeri = _PanelEkrani.ana;
  OperasyonOzet? _ozet;
  BekleyenGruplar? _gruplar;
  OperasyonDetay? _detay;
  DateTime _detayZamani = DateTime.now();

  List<OperasyonSecim> _secimler = const [];
  List<OperasyonSecim> _seraSecimleri = const [];
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
  bool _loadingGoster = false;
  bool _islemYapiliyor = false;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _api = OperasyonApi(user: widget.user);
    unawaited(_ilkYukleme());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          _ekran == _PanelEkrani.detay &&
          (_detay?.durum == 1 || _detay?.durum == 2)) {
        _saatTick.value++;
      }
    });
  }

  Future<void> _ilkYukleme() async {
    if (mounted) {
      setState(() {
        _yukleniyor = true;
        _loadingGoster = false;
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

    _loadingTimer?.cancel();

    setState(() {
      _yukleniyor = true;
      _loadingGoster = false;
      _hata = null;
    });

    _loadingTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && _yukleniyor) {
        setState(() => _loadingGoster = true);
      }
    });

    try {
      await islem();
    } catch (e) {
      if (mounted) setState(() => _hata = _hataMetni(e));
    } finally {
      _loadingTimer?.cancel();
      if (mounted) {
        setState(() {
          _yukleniyor = false;
          _loadingGoster = false;
        });
      }
    }
  }

  Future<void> _hizliYukle(Future<void> Function() islem) async {
    if (_yukleniyor || _islemYapiliyor) return;

    _loadingTimer?.cancel();

    setState(() {
      _yukleniyor = true;
      _loadingGoster = false;
      _hata = null;
    });

    try {
      await islem();
    } catch (e) {
      if (mounted) {
        setState(() => _hata = _hataMetni(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
          _loadingGoster = false;
        });
      }
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
    if (_yukleniyor || _islemYapiliyor) return;

    setState(() {
      _ekran = _PanelEkrani.bekleyenGruplar;
      _gruplar = null;
      _hata = null;
    });

    await _hizliYukle(() async {
      final veri = await _api.bekleyenGruplar();
      if (!mounted) return;
      setState(() {
        _gruplar = veri;
        _secilenDurum = 0;
        _secimleriTemizle();
      });
    });
  }

  Future<void> _bekleyenTipiSec(bool oncelikli, int adet) async {
    if (adet <= 0) {
      _mesaj('Bu grupta iş bulunmuyor.');
      return;
    }
    if (_yukleniyor || _islemYapiliyor) return;

    setState(() {
      _oncelikli = oncelikli;
      _secimler = const [];
      _ekran = _PanelEkrani.seralar;
      _hata = null;
    });

    await _hizliYukle(() async {
      final veri = await _api.seralar(oncelikli);
      if (!mounted) return;
      setState(() {
        _secimler = veri;
        _seraSecimleri = veri;
      });
    });
  }

  Future<void> _seraSec(OperasyonSecim secim) async {
    if (_yukleniyor || _islemYapiliyor) return;

    setState(() {
      _bolumKodu = secim.kod;
      _seraSecimleri = _secimler;
      _secimler = const [];
      _ekran = _PanelEkrani.isler;
      _hata = null;
    });

    await _hizliYukle(() async {
      final veri = await _api.isler(
        bolumKodu: secim.kod,
        oncelikli: _oncelikli,
      );
      if (!mounted) return;
      setState(() => _secimler = veri);
    });
  }

  Future<void> _isSec(OperasyonSecim secim) async {
    if (_yukleniyor || _islemYapiliyor) return;

    setState(() {
      _isKodu = secim.kod;
      _isAdi = secim.isim;
      _isSeviyesi = secim.isSeviyesi;
      _tuneller = const [];
      _ekran = _PanelEkrani.tuneller;
      _hata = null;
    });

    await _hizliYukle(() async {
      final veri = await _api.tuneller(
        bolumKodu: _bolumKodu,
        isKodu: secim.kod,
        isSeviyesi: secim.isSeviyesi,
        oncelikli: _oncelikli,
      );
      if (!mounted) return;
      setState(() => _tuneller = veri);
    });
  }

  Future<void> _tunelSec(OperasyonTunel secim) async {
    if (_yukleniyor || _islemYapiliyor) return;

    setState(() {
      _tunel = secim.tunel;
      _koridorlar = const [];
      _ekran = _PanelEkrani.koridorlar;
      _hata = null;
    });

    await _hizliYukle(() async {
      final veri = await _api.koridorlar(
        bolumKodu: _bolumKodu,
        isKodu: _isKodu,
        isSeviyesi: _isSeviyesi,
        tunel: secim.tunel,
        oncelikli: _oncelikli,
      );
      if (!mounted) return;
      setState(() => _koridorlar = veri);
    });
  }

  Future<void> _durumIsleriniAc(int durum) async {
    final adet = _durumAdedi(durum);
    if (adet <= 0) {
      _mesaj('Bu bölümde iş bulunmuyor.');
      return;
    }
    if (_yukleniyor || _islemYapiliyor) return;

    final tekAktif = durum == 1 && adet == 1;

    setState(() {
      _secilenDurum = durum;
      _durumIsleri = const [];
      _detay = null;
      _detayGeri = _PanelEkrani.ana;
      _ekran = tekAktif ? _PanelEkrani.detay : _PanelEkrani.durumIsleri;
      _hata = null;
    });

    await _hizliYukle(() async {
      final veri = await _api.durumIsleri(durum);
      if (!mounted) return;

      if (durum == 1 && veri.length == 1) {
        final detay = await _api.detay(veri.first.isEmriId);
        if (!mounted) return;
        setState(() {
          _durumIsleri = veri;
          _detay = detay;
          _detayZamani = DateTime.now();
          _detayGeri = _PanelEkrani.ana;
          _ekran = _PanelEkrani.detay;
        });
      } else {
        setState(() {
          _durumIsleri = veri;
          _ekran = _PanelEkrani.durumIsleri;
        });
      }
    });
  }

  Future<void> _detayiAc(int isEmriId) async {
    if (_yukleniyor || _islemYapiliyor) return;

    final geri = _ekran;

    setState(() {
      _detay = null;
      _detayGeri = geri;
      _ekran = _PanelEkrani.detay;
      _hata = null;
    });

    await _hizliYukle(() async {
      final detay = await _api.detay(isEmriId);
      if (!mounted) return;
      setState(() {
        _detay = detay;
        _detayZamani = DateTime.now();
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
    late final _PanelEkrani hedef;

    switch (_ekran) {
      case _PanelEkrani.bekleyenGruplar:
        hedef = _PanelEkrani.ana;
        break;
      case _PanelEkrani.seralar:
        hedef = _PanelEkrani.bekleyenGruplar;
        break;
      case _PanelEkrani.isler:
        hedef = _PanelEkrani.seralar;
        break;
      case _PanelEkrani.tuneller:
        hedef = _PanelEkrani.isler;
        break;
      case _PanelEkrani.koridorlar:
        hedef = _PanelEkrani.tuneller;
        break;
      case _PanelEkrani.durumIsleri:
        hedef = _PanelEkrani.ana;
        break;
      case _PanelEkrani.detay:
        hedef = _detayGeri;
        break;
      case _PanelEkrani.ana:
        return;
    }

    setState(() {
      _ekran = hedef;
      _hata = null;

      // _secimler hem Sera hem İş ekranında kullanıldığı için,
      // İş -> Sera dönüşünde önce son sera listesini anında geri koy.
      if (hedef == _PanelEkrani.seralar) {
        _secimler = _seraSecimleri;
      }
    });

    // Kullanıcı ekranı beklemeden görür; güncel veri arkadan gelir.
    unawaited(_geriEkraniniYenile(hedef));
  }

  Future<void> _geriEkraniniYenile(_PanelEkrani ekran) async {
    try {
      switch (ekran) {
        case _PanelEkrani.ana:
          final veri = await _api.ozet();
          if (!mounted || _ekran != ekran) return;
          setState(() => _ozet = veri);
          break;

        case _PanelEkrani.bekleyenGruplar:
          final veri = await _api.bekleyenGruplar();
          if (!mounted || _ekran != ekran) return;
          setState(() => _gruplar = veri);
          break;

        case _PanelEkrani.seralar:
          final veri = await _api.seralar(_oncelikli);
          if (!mounted || _ekran != ekran) return;
          setState(() {
            _seraSecimleri = veri;
            _secimler = veri;
          });
          break;

        case _PanelEkrani.isler:
          final veri = await _api.isler(
            bolumKodu: _bolumKodu,
            oncelikli: _oncelikli,
          );
          if (!mounted || _ekran != ekran) return;
          setState(() => _secimler = veri);
          break;

        case _PanelEkrani.tuneller:
          final veri = await _api.tuneller(
            bolumKodu: _bolumKodu,
            isKodu: _isKodu,
            isSeviyesi: _isSeviyesi,
            oncelikli: _oncelikli,
          );
          if (!mounted || _ekran != ekran) return;
          setState(() => _tuneller = veri);
          break;

        case _PanelEkrani.koridorlar:
          final veri = await _api.koridorlar(
            bolumKodu: _bolumKodu,
            isKodu: _isKodu,
            isSeviyesi: _isSeviyesi,
            tunel: _tunel,
            oncelikli: _oncelikli,
          );
          if (!mounted || _ekran != ekran) return;
          setState(() => _koridorlar = veri);
          break;

        case _PanelEkrani.durumIsleri:
          final veri = await _api.durumIsleri(_secilenDurum);
          if (!mounted || _ekran != ekran) return;
          setState(() => _durumIsleri = veri);
          break;

        case _PanelEkrani.detay:
          final mevcut = _detay;
          if (mevcut == null) return;
          final veri = await _api.detay(mevcut.isEmriId);
          if (!mounted || _ekran != ekran) return;
          setState(() {
            _detay = veri;
            _detayZamani = DateTime.now();
          });
          break;
      }
    } catch (_) {
      // Geri dönüşü bloklamıyoruz. Eski veri ekranda kalır.
    }
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
    _seraSecimleri = const [];
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
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    final anaEkran = _ekran == _PanelEkrani.ana;

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
              child: Stack(
                children: [
                  Padding(
                    // Sağ alttaki geri butonu içeriğin üstüne binmesin.
                    padding: EdgeInsets.only(bottom: anaEkran ? 0 : 76),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (anaEkran)
                          const _SayfaMiniBaslik(
                            baslik: 'İşlerim',
                            altBaslik: 'Yapacağınız işlemi seçin',
                          )
                        else ...[
                          _AdimBasligi(
                            baslik: _ekranBasligi,
                            icon: _ekranIkonu,
                          ),
                          if (_secimYolu.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            _YolGostergesi(metin: _secimYolu),
                          ],
                        ],


                        if (_hata != null) ...[
                          const SizedBox(height: 7),
                          _HataKutusu(mesaj: _hata!, tekrar: _yenile),
                        ],

                        const SizedBox(height: 10),

                        _icerik(),
                      ],
                    ),
                  ),

                  if (!anaEkran)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _sabitGeriButonu(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData get _ekranIkonu {
    switch (_ekran) {
      case _PanelEkrani.bekleyenGruplar:
        return Icons.pending_actions_rounded;
      case _PanelEkrani.seralar:
        return Icons.home_work_rounded;
      case _PanelEkrani.isler:
        return Icons.agriculture_rounded;
      case _PanelEkrani.tuneller:
        return Icons.view_week_rounded;
      case _PanelEkrani.koridorlar:
        return Icons.table_rows_rounded;
      case _PanelEkrani.durumIsleri:
        return _secilenDurum == 1
            ? Icons.play_circle_fill_rounded
            : _secilenDurum == 2
                ? Icons.pause_circle_filled_rounded
                : _secilenDurum == 5
                    ? Icons.replay_circle_filled_rounded
                    : Icons.pending_actions_rounded;
      case _PanelEkrani.detay:
        return Icons.assignment_rounded;
      case _PanelEkrani.ana:
        return Icons.grid_view_rounded;
    }
  }

  Widget _sabitGeriButonu() {
    return Material(
      color: accent,
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _geri,
        child: const SizedBox(
          width: 58,
          height: 58,
          child: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
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
    return LayoutBuilder(builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
      final columns = constraints.maxWidth >= 292 * scale ? 2 : 1;
      final side = ((constraints.maxWidth - 10 - (columns - 1) * 12) / columns)
          .clamp(140.0, 230.0).toDouble();
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: side * columns + (columns - 1) * 12 + 10,
          child: GridView.count(
            crossAxisCount: columns,
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
          ),
        ),
      );
    });
  }

  Widget _grupIcerik() {
    final veri = _gruplar;
    if (veri == null) {
      return _yukleniyor
          ? const SizedBox.shrink()
          : _bos('Bekleyen iş bilgisi yüklenemedi.');
    }
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
    if (_secimler.isEmpty) {
      return _yukleniyor
          ? const SizedBox.shrink()
          : _bos('Gösterilecek kayıt bulunamadı.');
    }

    return ListView.separated(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _secimler.length,
      separatorBuilder: (_, __) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        final item = _secimler[index];
        return RepaintBoundary(
          child: _ListeKart(
            baslik: item.isim,
            altBaslik: '${item.adet} adet',
            resim: item.resim,
            icon: icon,
            onTap: () => onTap(item),
          ),
        );
      },
    );
  }

  Widget _tunelIcerik() {
    if (_tuneller.isEmpty) {
      return _yukleniyor
          ? const SizedBox.shrink()
          : _bos('Gösterilecek tünel bulunamadı.');
    }

    return ListView.separated(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tuneller.length,
      separatorBuilder: (_, __) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        final item = _tuneller[index];
        return RepaintBoundary(
          child: _ListeKart(
            baslik: item.tunel,
            altBaslik: '${item.yon} • ${item.adet} adet • '
                'Son: ${_tarih(item.sonYapilmaTarihi)}',
            icon: Icons.view_week_rounded,
            onTap: () => _tunelSec(item),
          ),
        );
      },
    );
  }

  Widget _koridorIcerik() {
    if (_koridorlar.isEmpty) {
      return _yukleniyor
          ? const SizedBox.shrink()
          : _bos('Gösterilecek koridor bulunamadı.');
    }

    return ListView.separated(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _koridorlar.length,
      separatorBuilder: (_, __) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        final item = _koridorlar[index];
        return RepaintBoundary(
          child: _ListeKart(
            baslik: 'Koridor ${item.koridor}',
            altBaslik: 'Son yapılma: ${_tarih(item.sonYapilmaTarihi)}',
            icon: Icons.table_rows_rounded,
            onTap: () => _detayiAc(item.isEmriId),
          ),
        );
      },
    );
  }

  Widget _durumIsleriIcerik() {
    if (_durumIsleri.isEmpty) {
      return _yukleniyor
          ? const SizedBox.shrink()
          : _bos('Gösterilecek iş bulunamadı.');
    }

    return ListView.separated(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _durumIsleri.length,
      separatorBuilder: (_, __) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        final item = _durumIsleri[index];
        return RepaintBoundary(
          child: _ListeKart(
            baslik: item.isAdi,
            altBaslik: '${item.bolumKodu} • ${item.tunel} • '
                'Koridor ${item.koridor}',
            resim: item.resim,
            icon: Icons.agriculture_rounded,
            onTap: () => _detayiAc(item.isEmriId),
          ),
        );
      },
    );
  }

  Widget _detayIcerik() {
    final d = _detay;
    if (d == null) {
      return _yukleniyor
          ? const SizedBox.shrink()
          : _bos('Operasyon bilgisi bulunamadı.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(child: _DetayBaslik(detay: d)),
        const SizedBox(height: 9),
        ValueListenableBuilder<int>(
          valueListenable: _saatTick,
          builder: (context, _, __) {
            final aktif = _aktifSaniye;
            final ara = _araSaniye;
            final azamiGecildi =
                d.azamiSaniye > 0 && aktif > d.azamiSaniye;

            return Row(
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
            );
          },
        ),
        const SizedBox(height: 8),
        if (d.maxEtiketAdedi > 0) ...[
          const SizedBox(height: 9),
          LayoutBuilder(builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
            final stacked = constraints.maxWidth < 350 * scale;
            final width = stacked ? constraints.maxWidth : (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: width,
                  child: OutlinedButton.icon(
                    onPressed: d.durum == 1 ? () => _kutuEkrani(false) : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      foregroundColor: accent,
                      side: const BorderSide(color: cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: Text('Kutu Ekle (${d.eklenenKutuSayisi})'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: OutlinedButton.icon(
                    onPressed: d.durum == 1 ? () => _kutuEkrani(true) : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      foregroundColor: tekrarRenk,
                      side: const BorderSide(color: cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    label: const Text('Kutu Çıkar'),
                  ),
                ),
              ],
            );
          }),
        ],
        const SizedBox(height: 13),
        if (d.durum == 0 || d.durum == 1 || d.durum == 2 || d.durum == 5)
          SizedBox(
            height: 54,
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
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        if (d.durum == 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
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
              fontSize: 15,
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
    _loadingTimer?.cancel();
    _saatTick.dispose();
    _api.dispose();
    super.dispose();
  }
}

class _SayfaMiniBaslik extends StatelessWidget {
  final String baslik;
  final String altBaslik;

  const _SayfaMiniBaslik({
    required this.baslik,
    required this.altBaslik,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: const TextStyle(
              fontSize: 21,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: Color(0xFF24352F),
              letterSpacing: -.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            altBaslik,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7B8984),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdimBasligi extends StatelessWidget {
  final String baslik;
  final IconData icon;

  const _AdimBasligi({
    required this.baslik,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 3, 5, 0),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF1E6F5C),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              baslik,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: Color(0xFF24352F),
                letterSpacing: -.2,
              ),
            ),
          ),
        ],
      ),
    );
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
                    width: 26,
                    height: 26,
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
                      fontSize: 24,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    baslik,
                    maxLines: 3,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.2,
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
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      aciklama,
                      style: const TextStyle(
                        fontSize: 12,
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
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
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
                      ? Image.memory(
                          resim!,
                          fit: BoxFit.cover,
                          cacheWidth: 96,
                          cacheHeight: 96,
                          filterQuality: FilterQuality.low,
                          gaplessPlayback: true,
                        )
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      altBaslik,
                      style: const TextStyle(
                        fontSize: 12,
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
          fontSize: 12,
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
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
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
                  : Image.memory(
                       detay.resim!,
                       fit: BoxFit.cover,
                       cacheWidth: 112,
                       cacheHeight: 112,
                       filterQuality: FilterQuality.low,
                       gaplessPlayback: true,
                     ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detay.isAdi,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '${detay.bolumKodu} • ${detay.tunel} • Koridor ${detay.koridor}',
                  style: const TextStyle(
                    fontSize: 12,
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
                      fontSize: 11.5,
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _sure(saniye),
              style: TextStyle(fontSize: 15, color: renk, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            baslik,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6F8079),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
