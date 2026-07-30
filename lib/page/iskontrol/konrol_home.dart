import 'package:agronet/api/kontrol_api.dart';
import 'package:agronet/models/kontrol_is_model.dart';
import 'package:agronet/models/kontrol_personel_model.dart';
import 'package:agronet/page/iskontrol/kontrol_detay_page.dart';
import 'package:flutter/material.dart';

class KontrolPage extends StatefulWidget {
  final String personelKodu;
  final String personelAdi;

  const KontrolPage({
    super.key,
    required this.personelKodu,
    required this.personelAdi,
  });

  @override
  State<KontrolPage> createState() => _KontrolPageState();
}

class _KontrolPageState extends State<KontrolPage> {
  bool _yukleniyor = true;
  String? _hataMesaji;

  List<KontrolPersonelModel> _personeller = [];
  List<KontrolIsModel> _kontrolIsleri = [];

  KontrolPersonelModel? _seciliPersonel;

  // Geçici olarak sabit.
  // Daha sonra widget.personelKodu kullanılabilir.
  static const String _kontrolEdenKodu = '0713';

  @override
  void initState() {
    super.initState();
    _personelleriGetir();
  }

  Future<void> _personelleriGetir() async {
    setState(() {
      _yukleniyor = true;
      _hataMesaji = null;
      _seciliPersonel = null;
      _kontrolIsleri = [];
    });

    try {
      final sonuc = await KontrolApi.personelleriGetir(
        _kontrolEdenKodu,
      );

      if (!mounted) return;

      setState(() {
        _personeller = sonuc;
      });
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

  Future<void> _kontrolIsleriniGetir(
    KontrolPersonelModel personel,
  ) async {
    setState(() {
      _seciliPersonel = personel;
      _kontrolIsleri = [];
      _yukleniyor = true;
      _hataMesaji = null;
    });

    try {
      final sonuc = await KontrolApi.kontrolIsleriniGetir(
        kontrolEdenPersonelKodu: _kontrolEdenKodu,
        kontrolEdilenPersonelKodu: personel.personelKodu,
      );

      if (!mounted) return;

      setState(() {
        _kontrolIsleri = sonuc;
      });
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

  Future<void> _tumKontrolEkraniniYenile() async {
  final seciliPersonel = _seciliPersonel;

  if (seciliPersonel == null) {
    await _personelleriGetir();
    return;
  }

  if (!mounted) return;

  setState(() {
    _yukleniyor = true;
    _hataMesaji = null;
  });

  try {
    final sonuclar = await Future.wait([
      KontrolApi.personelleriGetir(
        _kontrolEdenKodu,
      ),
      KontrolApi.kontrolIsleriniGetir(
        kontrolEdenPersonelKodu:
            _kontrolEdenKodu,
        kontrolEdilenPersonelKodu:
            seciliPersonel.personelKodu,
      ),
    ]);

    if (!mounted) return;

    final yeniPersoneller =
        sonuclar[0] as List<KontrolPersonelModel>;

    final yeniKontrolIsleri =
        sonuclar[1] as List<KontrolIsModel>;

    KontrolPersonelModel? guncelSeciliPersonel;

    for (final personel in yeniPersoneller) {
      if (personel.personelKodu ==
          seciliPersonel.personelKodu) {
        guncelSeciliPersonel = personel;
        break;
      }
    }

    setState(() {
      _personeller = yeniPersoneller;
      _kontrolIsleri = yeniKontrolIsleri;

      // Personel listede hâlâ varsa güncel adetli halini kullan.
      // Listeden çıkmışsa mevcut seçimi koru.
      _seciliPersonel =
          guncelSeciliPersonel ?? seciliPersonel;
    });
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

  void _personelListesineDon() {
    setState(() {
      _seciliPersonel = null;
      _kontrolIsleri = [];
      _hataMesaji = null;
    });
  }

  Future<bool> _geriTusunaBasildi() async {
    if (_seciliPersonel != null) {
      _personelListesineDon();
      return false;
    }

    return true;
  }

  Map<String, List<KontrolPersonelModel>> _personelleriGrupla() {
    final gruplar = <String, List<KontrolPersonelModel>>{};

    for (final personel in _personeller) {
      String grup = personel.grup.trim().toUpperCase();

      if (grup.isEmpty) {
        final ad = personel.personelAdi.trim();

        grup = ad.isEmpty
            ? '#'
            : ad.substring(0, 1).toUpperCase();
      }

      gruplar.putIfAbsent(grup, () => []);
      gruplar[grup]!.add(personel);
    }

    final anahtarlar = gruplar.keys.toList()..sort();

    return {
      for (final anahtar in anahtarlar)
        anahtar: gruplar[anahtar]!,
    };
  }

  Map<String, List<KontrolIsModel>> _isleriTuneleGoreGrupla() {
    final gruplar = <String, List<KontrolIsModel>>{};

    for (final kontrolIsi in _kontrolIsleri) {
      final tunel = kontrolIsi.tunel.trim().isEmpty
          ? 'Tünel belirtilmemiş'
          : kontrolIsi.tunel.trim();

      gruplar.putIfAbsent(tunel, () => []);
      gruplar[tunel]!.add(kontrolIsi);
    }

    final anahtarlar = gruplar.keys.toList()..sort();

    return {
      for (final anahtar in anahtarlar)
        anahtar: gruplar[anahtar]!,
    };
  }

  _KontrolKartDurumu _kartDurumu(
    KontrolIsModel kontrolIsi,
  ) {
    // Kontrol işi bitmiş ancak asıl işe puan verilmemiş.
    if (kontrolIsi.kontrolDurum == 3 &&
        kontrolIsi.puan <= 0) {
      return _KontrolKartDurumu(
        renk: Colors.red.shade700,
        arkaPlan: Colors.red.withOpacity(.07),
        ikon: Icons.priority_high_rounded,
        metin: 'Puan bekliyor',
      );
    }

    // Kontrol işi bitmiş ve asıl iş puanlanmış.
    if (kontrolIsi.kontrolDurum == 3 &&
        kontrolIsi.puan > 0) {
      return _KontrolKartDurumu(
        renk: Colors.green.shade700,
        arkaPlan: Colors.green.withOpacity(.07),
        ikon: Icons.check_circle_rounded,
        metin: 'Puanlandı: ${kontrolIsi.puan.toInt()}',
      );
    }

    // Kontrol işi devam ediyor.
    if (kontrolIsi.kontrolDurum == 1) {
      return _KontrolKartDurumu(
        renk: Colors.blue.shade700,
        arkaPlan: Colors.blue.withOpacity(.07),
        ikon: Icons.play_circle_fill_rounded,
        metin: 'Kontrol devam ediyor',
      );
    }

    // Kontrol işine ara verilmiş.
    if (kontrolIsi.kontrolDurum == 2) {
      return _KontrolKartDurumu(
        renk: Colors.orange.shade800,
        arkaPlan: Colors.orange.withOpacity(.08),
        ikon: Icons.pause_circle_filled_rounded,
        metin: 'Ara verildi',
      );
    }

    // Kontrol henüz başlamamış.
    return _KontrolKartDurumu(
      renk: Colors.grey.shade700,
      arkaPlan: const Color(0xFFF7F7F9),
      ikon: Icons.schedule_rounded,
      metin: 'Kontrol bekliyor',
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _geriTusunaBasildi,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        appBar: AppBar(
          leading: _seciliPersonel != null
              ? IconButton(
                  onPressed: _personelListesineDon,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                  ),
                )
              : null,
          title: Text(
            _seciliPersonel == null
                ? 'Kontrol'
                : _seciliPersonel!.personelAdi,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Yenile',
              onPressed: _yukleniyor
                  ? null
                  : () {
                      if (_seciliPersonel == null) {
                        _personelleriGetir();
                      } else {
                        _kontrolIsleriniGetir(
                          _seciliPersonel!,
                        );
                      }
                    },
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () {
            if (_seciliPersonel == null) {
              return _personelleriGetir();
            }

            return _kontrolIsleriniGetir(
              _seciliPersonel!,
            );
          },
          child: _icerik(),
        ),
      ),
    );
  }

  Widget _icerik() {
    if (_yukleniyor) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hataMesaji != null) {
      return _hataGorunumu();
    }

    if (_seciliPersonel == null) {
      return _personelListesiGorunumu();
    }

    return _kontrolIsleriGorunumu();
  }

  Widget _hataGorunumu() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 100),
        const Icon(
          Icons.cloud_off_rounded,
          size: 64,
          color: Colors.redAccent,
        ),
        const SizedBox(height: 16),
        const Text(
          'Veriler alınamadı',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _hataMesaji!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black.withOpacity(.60),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: () {
              if (_seciliPersonel == null) {
                _personelleriGetir();
              } else {
                _kontrolIsleriniGetir(
                  _seciliPersonel!,
                );
              }
            },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Tekrar dene'),
          ),
        ),
      ],
    );
  }

  Widget _personelListesiGorunumu() {
    if (_personeller.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.fact_check_outlined,
            size: 70,
            color: Colors.black.withOpacity(.25),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bekleyen kontrol bulunamadı',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kontrol personeli: ${widget.personelAdi}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(.55),
            ),
          ),
        ],
      );
    }

    final gruplar = _personelleriGrupla();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        24,
      ),
      children: [
        _personelOzetKarti(),
        const SizedBox(height: 12),
        for (final grup in gruplar.entries)
          _personelGrupKarti(
            grup: grup.key,
            personeller: grup.value,
          ),
      ],
    );
  }

  Widget _personelOzetKarti() {
    final toplamKontrol = _personeller.fold<int>(
      0,
      (toplam, personel) {
        return toplam + personel.adet;
      },
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withOpacity(.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.personelAdi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_personeller.length} personel • '
                  '$toplamKontrol kontrol',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personelGrupKarti({
    required String grup,
    required List<KontrolPersonelModel> personeller,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withOpacity(.06),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 2,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          10,
          0,
          10,
          10,
        ),
        title: Text(
          '$grup (${personeller.length})',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        children: personeller
            .map(_personelKarti)
            .toList(),
      ),
    );
  }

  Widget _personelKarti(
    KontrolPersonelModel personel,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _kontrolIsleriniGetir(
            personel,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      Colors.green.withOpacity(.12),
                  child: Text(
                    _basHarfler(
                      personel.personelAdi,
                    ),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        personel.personelAdi,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Personel kodu: '
                        '${personel.personelKodu}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.black.withOpacity(.50),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Colors.green.withOpacity(.10),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${personel.adet} adet',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color:
                      Colors.black.withOpacity(.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kontrolIsleriGorunumu() {
    if (_kontrolIsleri.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 70,
            color: Colors.black.withOpacity(.25),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kontrol işi bulunamadı',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _seciliPersonel?.personelAdi ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(.55),
            ),
          ),
        ],
      );
    }

    final gruplar = _isleriTuneleGoreGrupla();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        24,
      ),
      children: [
        _kontrolDurumOzeti(),
        const SizedBox(height: 12),
        for (final grup in gruplar.entries)
          _tunelGrubu(
            tunel: grup.key,
            isler: grup.value,
          ),
      ],
    );
  }

  Widget _kontrolDurumOzeti() {
    final bekleyen = _kontrolIsleri.where(
      (x) => x.kontrolDurum == 0,
    ).length;

    final devamEden = _kontrolIsleri.where(
      (x) =>
          x.kontrolDurum == 1 ||
          x.kontrolDurum == 2,
    ).length;

    final puanBekleyen = _kontrolIsleri.where(
      (x) =>
          x.kontrolDurum == 3 &&
          x.puan <= 0,
    ).length;

    final tamamlanan = _kontrolIsleri.where(
      (x) =>
          x.kontrolDurum == 3 &&
          x.puan > 0,
    ).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withOpacity(.06),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            _seciliPersonel?.personelAdi ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ozetEtiketi(
                metin: '$bekleyen bekliyor',
                renk: Colors.grey.shade700,
                ikon: Icons.schedule_rounded,
              ),
              _ozetEtiketi(
                metin: '$devamEden devam ediyor',
                renk: Colors.blue.shade700,
                ikon:
                    Icons.play_circle_fill_rounded,
              ),
              _ozetEtiketi(
                metin: '$puanBekleyen puan bekliyor',
                renk: Colors.red.shade700,
                ikon: Icons.priority_high_rounded,
              ),
              _ozetEtiketi(
                metin: '$tamamlanan tamamlandı',
                renk: Colors.green.shade700,
                ikon: Icons.check_circle_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ozetEtiketi({
    required String metin,
    required Color renk,
    required IconData ikon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: renk.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: renk.withOpacity(.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ikon,
            size: 15,
            color: renk,
          ),
          const SizedBox(width: 5),
          Text(
            metin,
            style: TextStyle(
              fontSize: 11.5,
              color: renk,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tunelGrubu({
    required String tunel,
    required List<KontrolIsModel> isler,
  }) {
    final int toplamSira = isler.length;

    final int devamEdenSayisi = isler.where(
      (x) =>
          x.kontrolDurum == 1 ||
          x.kontrolDurum == 2,
    ).length;

    final int puanBekleyenSayisi = isler.where(
      (x) =>
          x.kontrolDurum == 3 &&
          x.puan <= 0,
    ).length;

    final int tamamlananSayisi = isler.where(
      (x) =>
          x.kontrolDurum == 3 &&
          x.puan > 0,
    ).length;

    final Color tunelRengi =
        puanBekleyenSayisi > 0
            ? Colors.red.shade700
            : devamEdenSayisi > 0
                ? Colors.blue.shade700
                : tamamlananSayisi == toplamSira
                    ? Colors.green.shade700
                    : Colors.grey.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tunelRengi.withOpacity(.18),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tunelRengi.withOpacity(.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.grid_view_rounded,
            size: 20,
            color: tunelRengi,
          ),
        ),
        title: Text(
          tunel,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              '$toplamSira sıra',
              style: TextStyle(
                fontSize: 13,
                color:
                    Colors.black.withOpacity(.55),
              ),
            ),
            if (devamEdenSayisi > 0 ||
                puanBekleyenSayisi > 0)
              Padding(
                padding:
                    const EdgeInsets.only(top: 3),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 3,
                  children: [
                    if (devamEdenSayisi > 0)
                      Text(
                        '$devamEdenSayisi devam eden',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.blue.shade700,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    if (puanBekleyenSayisi > 0)
                      Text(
                        '$puanBekleyenSayisi puan bekliyor',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.red.shade700,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        children: [
          for (final kontrolIsi in isler)
            _kontrolIsKarti(kontrolIsi),
        ],
      ),
    );
  }

  Widget _kontrolIsKarti(
    KontrolIsModel kontrolIsi,
  ) {
    final durum = _kartDurumu(kontrolIsi);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: durum.arkaPlan,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
       onTap: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => KontrolDetayPage(
        kontrolIsId: kontrolIsi.id,
        secilenSira:
            kontrolIsi.koridor,
        siraSayisi:
            kontrolIsi.siraSayisi,
      ),
    ),
  );

  if (!mounted) return;

  // Detay sayfasında işlem yapılıp yapılmadığına
  // bakmadan iki ekranın verilerini de yenile.
  await _tumKontrolEkraniniYenile();
},
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(15),
              border: Border.all(
                color:
                    durum.renk.withOpacity(.28),
                width: 1.3,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          durum.renk.withOpacity(.12),
                      borderRadius:
                          BorderRadius.circular(13),
                      border: Border.all(
                        color: durum.renk
                            .withOpacity(.20),
                      ),
                    ),
                    child: Text(
                      kontrolIsi.koridor
                              .trim()
                              .isEmpty
                          ? '-'
                          : kontrolIsi.koridor
                              .trim()
                              .toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 20,
                        color: durum.renk,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          kontrolIsi.isAdi,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: durum.renk
                                .withOpacity(.12),
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(
                                durum.ikon,
                                size: 15,
                                color: durum.renk,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  durum.metin,
                                  maxLines: 1,
                                  overflow: TextOverflow
                                      .ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color:
                                        durum.renk,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Tünel: '
                          '${kontrolIsi.tunel}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.black
                                .withOpacity(.60),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          kontrolIsi.koridor
                                  .trim()
                                  .isEmpty
                              ? 'Sıra belirtilmemiş'
                              : 'Sıra: '
                                  '${kontrolIsi.koridor.trim().toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                FontWeight.w600,
                            color: Colors.black
                                .withOpacity(.65),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _tarihYaz(
                            kontrolIsi.tarih,
                          ),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.black
                                .withOpacity(.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: durum.renk,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _tarihYaz(DateTime? tarih) {
    if (tarih == null) {
      return 'Tarih bulunamadı';
    }

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

  String _basHarfler(String ad) {
    final parcalar = ad
        .trim()
        .split(RegExp(r'\s+'))
        .where((x) => x.isNotEmpty)
        .toList();

    if (parcalar.isEmpty) {
      return '?';
    }

    if (parcalar.length == 1) {
      return parcalar.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parcalar.first.substring(0, 1)}'
            '${parcalar.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _KontrolKartDurumu {
  final Color renk;
  final Color arkaPlan;
  final IconData ikon;
  final String metin;

  const _KontrolKartDurumu({
    required this.renk,
    required this.arkaPlan,
    required this.ikon,
    required this.metin,
  });
}