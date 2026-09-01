import 'dart:async';
import 'dart:collection';

import 'package:agronet/api/operasyon_api.dart';
import 'package:flutter/material.dart';
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

  late final MobileScannerController _controller;
  final Queue<String> _kuyruk = Queue<String>();
  final Set<String> _kilitliKodlar = <String>{};
  final List<_TaramaKaydi> _kayitlar = <_TaramaKaydi>[];

  bool _kuyrukCalisiyor = false;
  bool _fenerAcik = false;
  int _basarili = 0;
  int _hatali = 0;
  String _sonMesaj = 'Kamerayı barkoda yaklaştırın';
  Color _sonRenk = Colors.blueGrey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      autoStart: false,
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 180,
      formats: const [BarcodeFormat.qrCode],
      returnImage: false,
      autoZoom: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_kamerayiBaslat());
    });
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
              ? 'Bu kutu zaten eklenmiş'
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
          title: Text(widget.cikar ? 'Kutu Çıkarma' : 'Seri Kutu Okutma'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            IconButton(
              tooltip: 'Fener',
              onPressed: () async {
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
            SizedBox(
              height: 330,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final kare = constraints.maxWidth
                      .clamp(210.0, 285.0)
                      .toDouble();
                  final pencere = Rect.fromCenter(
                    center: Offset(
                      constraints.maxWidth / 2,
                      constraints.maxHeight / 2,
                    ),
                    width: kare,
                    height: kare,
                  );

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _controller,
                        scanWindow: pencere,
                        onDetect: _barkodAlgilandi,
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _TaramaCercevesiPainter(pencere),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                  _Sayac(title: 'Bekleyen', value: _bekleyen, color: Colors.orange),
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

enum _TaramaDurumu { bekliyor, basarili, hatali }

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
