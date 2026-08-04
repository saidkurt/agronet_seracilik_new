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
  State<DepoTalepOnayPage> createState() => _DepoTalepOnayPageState();
}

class _DepoTalepOnayPageState extends State<DepoTalepOnayPage> {
  final DepoTalepApi _api = DepoTalepApi();

  List<DepoTalepEvrakModel> _evraklar = [];

  DepoTalepEvrakModel? _secilenEvrak;
  DepoTalepDetayModel? _detay;

  final Map<String, bool> _secimler = {};
  final Map<String, TextEditingController> _miktarControllerlari = {};

  bool _evraklarYukleniyor = false;
  bool _detayYukleniyor = false;
  bool _islemYapiliyor = false;

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

  void _controllerlariTemizle() {
    for (final controller in _miktarControllerlari.values) {
      controller.dispose();
    }

    _miktarControllerlari.clear();
    _secimler.clear();
  }

  Future<void> _evraklariGetir() async {
    setState(() {
      _evraklarYukleniyor = true;
    });

    try {
      final sonuc = await _api.talepEvraklariGetir();

      if (!mounted) return;

      setState(() {
        _evraklar = sonuc;
      });
    } catch (e) {
      if (!mounted) return;
      _hataGoster('Evraklar getirilemedi.\n$e');
    } finally {
      if (mounted) {
        setState(() {
          _evraklarYukleniyor = false;
        });
      }
    }
  }

  Future<void> _evrakSec(DepoTalepEvrakModel evrak) async {
    final seri = evrak.seri ?? '';
    final sira = evrak.sira ?? 0;

    if (sira <= 0) {
      _hataGoster('Evrak sıra numarası geçersiz.');
      return;
    }

    setState(() {
      _secilenEvrak = evrak;
      _detay = null;
      _detayYukleniyor = true;
    });

    _controllerlariTemizle();

    try {
      final sonuc = await _api.talepDetayGetir(
        seri: seri,
        sira: sira,
      );

      if (!mounted) return;

      if (sonuc == null) {
        _hataGoster('Evrak detayı bulunamadı.');

        setState(() {
          _secilenEvrak = null;
        });

        return;
      }

      _detay = sonuc;

      for (final kalem in sonuc.kalemler ?? <DepoTalepKalemModel>[]) {
        final guid = kalem.guid ?? '';

        if (guid.isEmpty) continue;

        _secimler[guid] = false;
        _miktarControllerlari[guid] = TextEditingController(text: '0');
      }

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      _hataGoster('Evrak detayı getirilemedi.\n$e');

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

  void _evraktanCik() {
    _controllerlariTemizle();

    setState(() {
      _secilenEvrak = null;
      _detay = null;
    });
  }

  void _kalemSec(
    DepoTalepKalemModel kalem,
    bool secildi,
  ) {
    final guid = kalem.guid ?? '';
    if (guid.isEmpty) return;

    setState(() {
      _secimler[guid] = secildi;

      final controller = _miktarControllerlari[guid];

      if (secildi) {
        controller?.text = _miktarYaz(kalem.kalanMiktar ?? 0);
      } else {
        controller?.text = '0';
      }
    });
  }

  void _tumunuSec() {
    final kalemler = _detay?.kalemler ?? <DepoTalepKalemModel>[];

    setState(() {
      for (final kalem in kalemler) {
        final guid = kalem.guid ?? '';
        if (guid.isEmpty) continue;

        _secimler[guid] = true;
        _miktarControllerlari[guid]?.text = _miktarYaz(
          kalem.kalanMiktar ?? 0,
        );
      }
    });
  }

  void _tumunuKaldir() {
    setState(() {
      for (final guid in _secimler.keys) {
        _secimler[guid] = false;
        _miktarControllerlari[guid]?.text = '0';
      }
    });
  }

  bool get _tumKalemlerSecili {
    final kalemler = _detay?.kalemler ?? <DepoTalepKalemModel>[];

    if (kalemler.isEmpty) return false;

    return kalemler.every((kalem) {
      final guid = kalem.guid ?? '';
      return guid.isNotEmpty && (_secimler[guid] ?? false);
    });
  }

  int get _secilenKalemSayisi {
    return _secimler.values.where((secili) => secili).length;
  }

  bool get _oturumGecerli {
    return widget.kullaniciKodu.trim().isNotEmpty &&
        widget.oturumId > 0 &&
        widget.token.trim().isNotEmpty;
  }

  Future<void> _kaydet() async {
    if (!_oturumGecerli) {
      _hataGoster('Oturum bilgisi geçersiz. Tekrar giriş yapın.');
      return;
    }
    if (_detay == null || _secilenEvrak == null) {
      _hataGoster('Önce evrak seçmelisiniz.');
      return;
    }

    final List<DepoTalepOnayKalemModel> onayKalemleri = [];

    for (final kalem
        in _detay!.kalemler ?? <DepoTalepKalemModel>[]) {
      final guid = kalem.guid ?? '';

      if (guid.isEmpty || !(_secimler[guid] ?? false)) {
        continue;
      }

      final miktar = _doubleOku(
        _miktarControllerlari[guid]?.text,
      );

      final kalanMiktar = kalem.kalanMiktar ?? 0;

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
      _hataGoster('En az bir ürün seçmelisiniz.');
      return;
    }

    final onay = await _onaySor(
      baslik: 'Talebi onayla',
      mesaj:
          '${onayKalemleri.length} ürün için kabul işlemi kaydedilecek. '
          'Devam edilsin mi?',
      onayMetni: 'Kaydet',
    );

    if (!onay) return;

    setState(() {
      _islemYapiliyor = true;
    });

    try {
      final sonuc = await _api.talepOnayla(
        DepoTalepOnayRequestModel(
          seri: _detay!.seri ?? _secilenEvrak!.seri ?? '',
          sira: _detay!.sira ?? _secilenEvrak!.sira,
          kullaniciKodu: widget.kullaniciKodu,
          oturumId: widget.oturumId,
          token: widget.token,
          kalemler: onayKalemleri,
        ),
      );

      if (!mounted) return;

      if (sonuc.basarili == false) {
        _hataGoster(sonuc.mesaj ?? 'İşlem başarısız.');
        return;
      }

      _mesajGoster(
        sonuc.mesaj ?? 'Talep başarıyla onaylandı.',
      );

      final secili = _secilenEvrak;

      await _evraklariGetir();

      if (!mounted) return;

      if (secili != null) {
        final halaAcik = _evraklar.any(
          (e) =>
              e.seri == secili.seri &&
              e.sira == secili.sira,
        );

        if (halaAcik) {
          final guncelEvrak = _evraklar.firstWhere(
            (e) =>
                e.seri == secili.seri &&
                e.sira == secili.sira,
          );

          await _evrakSec(guncelEvrak);
        } else {
          _evraktanCik();
        }
      }
    } catch (e) {
      if (!mounted) return;
      _hataGoster('Kayıt işlemi başarısız.\n$e');
    } finally {
      if (mounted) {
        setState(() {
          _islemYapiliyor = false;
        });
      }
    }
  }

  Future<void> _kalaniKapat() async {
    if (!_oturumGecerli) {
      _hataGoster('Oturum bilgisi geçersiz. Tekrar giriş yapın.');
      return;
    }

    if (_detay == null || _secilenEvrak == null) {
      _hataGoster('Önce evrak seçmelisiniz.');
      return;
    }

    final onay = await _onaySor(
      baslik: 'Kalanı kapat',
      mesaj:
          'Bu evrakta teslim edilmemiş tüm kalan miktarlar iptal edilecek. '
          'Bu işlem geri alınamaz.',
      onayMetni: 'Kalanı kapat',
      tehlikeli: true,
    );

    if (!onay) return;

    setState(() {
      _islemYapiliyor = true;
    });

    try {
      final sonuc = await _api.talepKalaniKapat(
        DepoTalepKapatRequestModel(
          seri: _detay!.seri ?? _secilenEvrak!.seri ?? '',
          sira: _detay!.sira ?? _secilenEvrak!.sira,
          kullaniciKodu: widget.kullaniciKodu,
          oturumId: widget.oturumId,
          token: widget.token,
        ),
      );

      if (!mounted) return;

      if (sonuc.basarili == false) {
        _hataGoster(sonuc.mesaj ?? 'İşlem başarısız.');
        return;
      }

      _mesajGoster(
        sonuc.mesaj ?? 'Evrakın kalan kısmı kapatıldı.',
      );

      _evraktanCik();
      await _evraklariGetir();
    } catch (e) {
      if (!mounted) return;
      _hataGoster('Kalanı kapatma işlemi başarısız.\n$e');
    } finally {
      if (mounted) {
        setState(() {
          _islemYapiliyor = false;
        });
      }
    }
  }

  Future<bool> _onaySor({
    required String baslik,
    required String mesaj,
    required String onayMetni,
    bool tehlikeli = false,
  }) async {
    final sonuc = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(baslik),
          content: Text(mesaj),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              style: tehlikeli
                  ? FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.error,
                    )
                  : null,
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(onayMetni),
            ),
          ],
        );
      },
    );

    return sonuc ?? false;
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mesaj),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
  }

  void _mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mesaj),
        ),
      );
  }

  double _doubleOku(String? deger) {
    if (deger == null || deger.trim().isEmpty) {
      return 0;
    }

    return double.tryParse(
          deger.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  String _miktarYaz(double miktar) {
    if (miktar == miktar.roundToDouble()) {
      return miktar.toInt().toString();
    }

    return miktar
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
String _tarihYaz(DateTime? tarih) {
  if (tarih == null) {
    return '-';
  }

  final gun = tarih.day.toString().padLeft(2, '0');
  final ay = tarih.month.toString().padLeft(2, '0');

  return '$gun.$ay.${tarih.year}';
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _secilenEvrak == null
              ? 'Depo Talep Onay'
              : _secilenEvrak!.evrakNo ?? 'Evrak Detayı',
        ),
        leading: _secilenEvrak != null
            ? IconButton(
                onPressed: _islemYapiliyor ? null : _evraktanCik,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _islemYapiliyor
                ? null
                : () async {
                    if (_secilenEvrak == null) {
                      await _evraklariGetir();
                    } else {
                      await _evrakSec(_secilenEvrak!);
                    }
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_secilenEvrak == null)
            _evrakListesi()
          else
            _evrakDetayi(),

          if (_islemYapiliyor)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              alignment: Alignment.center,
              child: const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('İşlem yapılıyor...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar:
          _secilenEvrak != null && _detay != null
          ? _altIslemAlani()
          : null,
    );
  }

  Widget _evrakListesi() {
    return RefreshIndicator(
      onRefresh: _evraklariGetir,
      child: _evraklarYukleniyor
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _evraklar.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 160),
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 72,
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Açık depo talep evrakı bulunamadı.',
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    20,
                  ),
                  itemCount: _evraklar.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _evrakKarti(
                      _evraklar[index],
                    );
                  },
                ),
    );
  }

  Widget _evrakKarti(DepoTalepEvrakModel evrak) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _evrakSec(evrak),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      '${evrak.kalemSayisi ?? 0}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          evrak.evrakNo ??
                              '${evrak.seri ?? ''}-${evrak.sira ?? 0}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _tarihYaz(evrak.tarih),
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const Divider(height: 24),
              _depoSatiri(
                ikon: Icons.warehouse_outlined,
                baslik: 'Kaynak',
                deger: evrak.kaynakDepo ?? '-',
              ),
              const SizedBox(height: 8),
              _depoSatiri(
                ikon: Icons.location_on_outlined,
                baslik: 'Hedef',
                deger: evrak.hedefDepo ?? '-',
              ),
              const SizedBox(height: 10),
              Text(
                '${evrak.kalemSayisi ?? 0} kalem ürün',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _evrakDetayi() {
    if (_detayYukleniyor) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_detay == null) {
      return const Center(
        child: Text('Evrak detayı bulunamadı.'),
      );
    }

    final kalemler =
        _detay!.kalemler ?? <DepoTalepKalemModel>[];

    return Column(
      children: [
        _evrakUstBilgi(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${kalemler.length} ürün • '
                  '$_secilenKalemSayisi seçili',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall,
                ),
              ),
              TextButton.icon(
                onPressed:
                    _tumKalemlerSecili ? _tumunuKaldir : _tumunuSec,
                icon: Icon(
                  _tumKalemlerSecili
                      ? Icons.deselect
                      : Icons.select_all,
                ),
                label: Text(
                  _tumKalemlerSecili
                      ? 'Seçimi kaldır'
                      : 'Tümünü seç',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: kalemler.isEmpty
              ? const Center(
                  child: Text('Açık ürün bulunamadı.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    4,
                    12,
                    120,
                  ),
                  itemCount: kalemler.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _urunKarti(
                      kalemler[index],
                      index,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _evrakUstBilgi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _detay!.evrakNo ??
                      _secilenEvrak!.evrakNo ??
                      '-',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Text(_tarihYaz(_detay!.tarih)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _depoBilgiKutusu(
                  baslik: 'Kaynak depo',
                  deger: _detay!.kaynakDepo ?? '-',
                  ikon: Icons.warehouse_outlined,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward),
              ),
              Expanded(
                child: _depoBilgiKutusu(
                  baslik: 'Hedef depo',
                  deger: _detay!.hedefDepo ?? '-',
                  ikon: Icons.location_on_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _urunKarti(
    DepoTalepKalemModel kalem,
    int index,
  ) {
    final guid = kalem.guid ?? '';
    final secili = _secimler[guid] ?? false;
    final kalanMiktar = kalem.kalanMiktar ?? 0;
    final controller = _miktarControllerlari[guid];

    return Card(
      elevation: secili ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: secili
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: secili ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: secili,
                  onChanged: guid.isEmpty
                      ? null
                      : (value) {
                          _kalemSec(kalem, value ?? false);
                        },
                ),
                Expanded(
                  child: InkWell(
                    onTap: guid.isEmpty
                        ? null
                        : () {
                            _kalemSec(kalem, !secili);
                          },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            kalem.stokAdi ?? 'Stok adı yok',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            kalem.stokKodu ?? '-',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Text(
                  '${index + 1}',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _miktarBilgisi(
                    baslik: 'Talep',
                    miktar: kalem.talepMiktari ?? 0,
                    birim: kalem.birim,
                  ),
                ),
                Expanded(
                  child: _miktarBilgisi(
                    baslik: 'Teslim',
                    miktar: kalem.teslimMiktari ?? 0,
                    birim: kalem.birim,
                  ),
                ),
                Expanded(
                  child: _miktarBilgisi(
                    baslik: 'Kalan',
                    miktar: kalanMiktar,
                    birim: kalem.birim,
                    kalin: true,
                  ),
                ),
              ],
            ),
            if (secili) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: !_islemYapiliyor,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,]'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Kabul miktarı',
                        suffixText: kalem.birim ?? '',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _islemYapiliyor
                        ? null
                        : () {
                            controller?.text =
                                _miktarYaz(kalanMiktar);

                            setState(() {});
                          },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      child: Text('Tamamı'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _altIslemAlani() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, -2),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Evrakın kalanını kapat',
              onPressed:
                  _islemYapiliyor ? null : _kalaniKapat,
              icon: const Icon(Icons.block),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    _islemYapiliyor || _secilenKalemSayisi == 0
                    ? null
                    : _kaydet,
                icon: const Icon(Icons.save_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  child: Text(
                    _secilenKalemSayisi == 0
                        ? 'Ürün seçin'
                        : '$_secilenKalemSayisi ürünü kaydet',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _depoSatiri({
    required IconData ikon,
    required String baslik,
    required String deger,
  }) {
    return Row(
      children: [
        Icon(ikon, size: 20),
        const SizedBox(width: 8),
        SizedBox(
          width: 55,
          child: Text(
            baslik,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            deger,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _depoBilgiKutusu({
    required String baslik,
    required String deger,
    required IconData ikon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 17),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  baslik,
                  style:
                      Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            deger,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miktarBilgisi({
    required String baslik,
    required double miktar,
    String? birim,
    bool kalin = false,
  }) {
    return Column(
      children: [
        Text(
          baslik,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text(
          _miktarYaz(miktar),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight:
                kalin ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          birim ?? '',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}