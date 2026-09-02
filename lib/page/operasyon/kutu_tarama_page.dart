import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:agronet/api/operasyon_api.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class KutuTaramaPage extends StatefulWidget {
  final OperasyonApi api;
  final int isEmriId;
  final bool cikar;

  const KutuTaramaPage({
    super.key,
    required this.api,
    required this.isEmriId,
    this.cikar = false,
  });

  @override
  State<KutuTaramaPage> createState() => _KutuTaramaPageState();
}

class _KutuTaramaPageState extends State<KutuTaramaPage>
    with WidgetsBindingObserver {
  static const Color accent = Color(0xFF1E6F5C);

  late MobileScannerController _controller;
  final Queue<String> _kuyruk = Queue<String>();
  final Set<String> _kilitliKodlar = <String>{};
  final List<_TaramaKaydi> _kayitlar = <_TaramaKaydi>[];

  _TaramaModu _taramaModu = _TaramaModu.kasa;
  bool _modDegisiyor = false;
  bool _kuyrukCalisiyor = false;
  bool _fenerAcik = false;
  int _basarili = 0;
  int _hatali = 0;
  String _sonMesaj = 'Siyah kasa barkodunu yatay tutun';
  Color _sonRenk = Colors.blueGrey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = _controllerOlustur(_taramaModu);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_kamerayiBaslat());
    });
  }

  MobileScannerController _controllerOlustur(_TaramaModu mod) {
    final kasaModu = mod == _TaramaModu.kasa;

    return MobileScannerController(
      autoStart: false,
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 180,
      // Kasa modunda sadece 1D, kutu modunda sadece QR aranir. Bu ayrim
      // algilamayi hizlandirir ve kadrajdaki ilgisiz kodlari filtreler.
      formats: kasaModu
          ? const [
              BarcodeFormat.codabar,
              BarcodeFormat.code39,
              BarcodeFormat.code93,
              BarcodeFormat.code128,
              BarcodeFormat.ean8,
              BarcodeFormat.ean13,
              BarcodeFormat.itf,
              BarcodeFormat.upcA,
              BarcodeFormat.upcE,
            ]
          : const [BarcodeFormat.qrCode],
      returnImage: false,
      // Kasa: siyah zemin/beyaz cizgi. Kutu QR: normal acik zemin/koyu kod.
      invertImage: kasaModu,
      autoZoom: true,
    );
  }

  Future<void> _taramaModunuDegistir(_TaramaModu yeniMod) async {
    if (_modDegisiyor || yeniMod == _taramaModu) return;

    setState(() => _modDegisiyor = true);

    final eskiController = _controller;
    try {
      await eskiController.stop();
    } catch (_) {}
    try {
      await eskiController.dispose();
    } catch (_) {}

    if (!mounted) return;

    final yeniController = _controllerOlustur(yeniMod);
    setState(() {
      _controller = yeniController;
      _taramaModu = yeniMod;
      _fenerAcik = false;
      _sonMesaj = yeniMod == _TaramaModu.kasa
          ? 'Siyah kasa barkodunu yatay tutun'
          : 'Kutu QR kodunu çerçevenin ortasında tutun';
      _sonRenk = Colors.blueGrey;
    });

    await _kamerayiBaslat();
    if (mounted) setState(() => _modDegisiyor = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_kamerayiBaslat());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_kamerayiDurdur());
    }
  }

  Future<void> _kamerayiBaslat() async {
    try {
      await _controller.start();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sonMesaj = 'Kamera başlatılamadı';
        _sonRenk = Colors.red;
      });
    }
  }

  Future<void> _kamerayiDurdur() async {
    try {
      await _controller.stop();
    } catch (_) {}
  }

  void _barkodAlgilandi(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final kod = barcode.rawValue?.trim() ?? '';
      if (kod.isEmpty || _kilitliKodlar.contains(kod)) continue;

      _kilitliKodlar.add(kod);
      _kuyruk.add(kod);

      setState(() {
        _kayitlar.insert(
          0,
          _TaramaKaydi(
            kod: kod,
            mesaj: 'Kontrol ediliyor',
            durum: _TaramaDurumu.bekliyor,
          ),
        );
        if (_kayitlar.length > 30) _kayitlar.removeLast();
        _sonMesaj = 'Barkod algılandı';
        _sonRenk = Colors.orange;
      });
    }

    if (!_kuyrukCalisiyor && _kuyruk.isNotEmpty) {
      unawaited(_kuyruguCalistir());
    }
  }

  Future<void> _kuyruguCalistir() async {
    if (_kuyrukCalisiyor) return;
    _kuyrukCalisiyor = true;

    while (_kuyruk.isNotEmpty) {
      final kod = _kuyruk.removeFirst();

      try {
        final sonuc = widget.cikar
            ? await widget.api.kutuCikar(
                isEmriId: widget.isEmriId,
                barkod: kod,
              )
            : await widget.api.kutuEkle(
                isEmriId: widget.isEmriId,
                barkod: kod,
              );

        if (!mounted) break;

        setState(() {
          _basarili++;
          _kaydiGuncelle(
            kod,
            sonuc.zatenKayitli ? 'Zaten ekli' : sonuc.mesaj,
            _TaramaDurumu.basarili,
          );
          _sonMesaj = sonuc.zatenKayitli
              ? 'Bu barkod zaten eklenmiş'
              : sonuc.mesaj;
          _sonRenk = sonuc.zatenKayitli ? Colors.amber.shade800 : accent;
        });

        await HapticFeedback.mediumImpact();
        await SystemSound.play(SystemSoundType.click);
      } catch (e) {
        if (!mounted) break;

        setState(() {
          _hatali++;
          _kaydiGuncelle(kod, e.toString(), _TaramaDurumu.hatali);
          _sonMesaj = e.toString();
          _sonRenk = Colors.red;
        });

        await HapticFeedback.heavyImpact();
        await SystemSound.play(SystemSoundType.alert);

        // Hatalı okuma düzeltildikten sonra aynı barkod yeniden denenebilir.
        Future<void>.delayed(const Duration(milliseconds: 1400), () {
          _kilitliKodlar.remove(kod);
        });
      }
    }

    _kuyrukCalisiyor = false;
    if (mounted) setState(() {});
  }

  void _kaydiGuncelle(
    String kod,
    String mesaj,
    _TaramaDurumu durum,
  ) {
    final index = _kayitlar.indexWhere((e) => e.kod == kod);
    if (index < 0) return;
    _kayitlar[index] = _TaramaKaydi(
      kod: kod,
      mesaj: mesaj,
      durum: durum,
    );
  }

  int get _bekleyen => _kuyruk.length + (_kuyrukCalisiyor ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: Text(
            widget.cikar ? 'Kasa / Kutu Çıkarma' : 'Kasa / Kutu Okutma',
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            IconButton(
              tooltip: 'Fener',
              onPressed: _modDegisiyor
                  ? null
                  : () async {
                      await _controller.toggleTorch();
                      if (mounted) setState(() => _fenerAcik = !_fenerAcik);
                    },
              icon: Icon(
                _fenerAcik ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  _TaramaModButonu(
                    secili: _taramaModu == _TaramaModu.kasa,
                    etkin: !_modDegisiyor,
                    icon: Icons.view_week_rounded,
                    baslik: 'KASA',
                    aciklama: 'Siyah 1D barkod',
                    onTap: () => unawaited(
                      _taramaModunuDegistir(_TaramaModu.kasa),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TaramaModButonu(
                    secili: _taramaModu == _TaramaModu.kutu,
                    etkin: !_modDegisiyor,
                    icon: Icons.qr_code_2_rounded,
                    baslik: 'KUTU',
                    aciklama: 'QR kod',
                    onTap: () => unawaited(
                      _taramaModunuDegistir(_TaramaModu.kutu),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 330,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Kasa barkodu icin yatay, QR icin kare hedef alani.
                  final kasaModu = _taramaModu == _TaramaModu.kasa;
                  final qrKare = (constraints.maxWidth * .66)
                      .clamp(210.0, 260.0)
                      .toDouble();
                  final pencereGenisligi = kasaModu
                      ? (constraints.maxWidth * .88)
                          .clamp(260.0, 410.0)
                          .toDouble()
                      : qrKare;
                  final pencereYuksekligi = kasaModu
                      ? (constraints.maxHeight * .50)
                          .clamp(150.0, 205.0)
                          .toDouble()
                      : qrKare;
                  final pencere = Rect.fromCenter(
                    center: Offset(
                      constraints.maxWidth / 2,
                      constraints.maxHeight / 2,
                    ),
                    width: pencereGenisligi,
                    height: pencereYuksekligi,
                  );

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        key: ValueKey(_taramaModu),
                        controller: _controller,
                        scanWindow: pencere,
                        onDetect: _barkodAlgilandi,
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _TaramaCercevesiPainter(pencere),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 12,
                        child: Text(
                          kasaModu
                              ? 'Siyah kasa barkodunu yatay ve tam çerçeveye alın'
                              : 'Kutu QR kodunu çerçevenin ortasında tutun',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 5),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              color: _sonRenk,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              child: Text(
                _sonMesaj,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Row(
                children: [
                  _Sayac(title: 'Başarılı', value: _basarili, color: accent),
                  const SizedBox(width: 8),
                  _Sayac(title: 'Hatalı', value: _hatali, color: Colors.red),
                  const SizedBox(width: 8),
                  _Sayac(
                    title: 'Bekleyen',
                    value: _bekleyen,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _kayitlar.isEmpty
                  ? const Center(
                      child: Text('Henüz barkod okutulmadı.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                      itemCount: _kayitlar.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        return _TaramaSatiri(kayit: _kayitlar[index]);
                      },
                    ),
            ),
          ],
        ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }
}

enum _TaramaModu { kasa, kutu }

enum _TaramaDurumu { bekliyor, basarili, hatali }

class _TaramaModButonu extends StatelessWidget {
  final bool secili;
  final bool etkin;
  final IconData icon;
  final String baslik;
  final String aciklama;
  final VoidCallback onTap;

  const _TaramaModButonu({
    required this.secili,
    required this.etkin,
    required this.icon,
    required this.baslik,
    required this.aciklama,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const seciliRenk = Color(0xFF1E6F5C);

    return Expanded(
      child: Material(
        color: secili ? seciliRenk : const Color(0xFFF1F4F3),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: etkin ? onTap : null,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: secili ? seciliRenk : const Color(0xFFDCE5E2),
                width: 1.4,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: secili ? Colors.white : seciliRenk,
                  size: 25,
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        baslik,
                        style: TextStyle(
                          color: secili ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        aciklama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secili
                              ? Colors.white.withOpacity(.82)
                              : Colors.black54,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaramaKaydi {
  final String kod;
  final String mesaj;
  final _TaramaDurumu durum;

  const _TaramaKaydi({
    required this.kod,
    required this.mesaj,
    required this.durum,
  });
}

class _TaramaSatiri extends StatelessWidget {
  final _TaramaKaydi kayit;

  const _TaramaSatiri({required this.kayit});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (kayit.durum) {
      _TaramaDurumu.bekliyor => (Icons.hourglass_top_rounded, Colors.orange),
      _TaramaDurumu.basarili => (Icons.check_circle_rounded, const Color(0xFF1E6F5C)),
      _TaramaDurumu.hatali => (Icons.error_rounded, Colors.red),
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: color),
        title: Text(
          kayit.kod,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          kayit.mesaj,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _Sayac extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const _Sayac({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(.35)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaramaCercevesiPainter extends CustomPainter {
  final Rect pencere;

  const _TaramaCercevesiPainter(this.pencere);

  @override
  void paint(Canvas canvas, Size size) {
    final karartma = Paint()..color = Colors.black.withOpacity(.48);
    final dis = Path()..addRect(Offset.zero & size);
    final ic = Path()
      ..addRRect(RRect.fromRectAndRadius(pencere, const Radius.circular(18)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, dis, ic),
      karartma,
    );

    final cerceve = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(pencere, const Radius.circular(18)),
      cerceve,
    );
  }

  @override
  bool shouldRepaint(covariant _TaramaCercevesiPainter oldDelegate) {
    return oldDelegate.pencere != pencere;
  }
}
