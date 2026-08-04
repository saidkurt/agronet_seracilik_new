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
        widget.personelKodu,
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
        kontrolEdenPersonelKodu: widget.personelKodu,
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

    setState(() {
      _yukleniyor = true;
      _hataMesaji = null;
    });

    try {
      final sonuclar = await Future.wait([
        KontrolApi.personelleriGetir(
          widget.personelKodu,
        ),
        KontrolApi.kontrolIsleriniGetir(
          kontrolEdenPersonelKodu:
              widget.personelKodu,
          kontrolEdilenPersonelKodu:
              seciliPersonel.personelKodu,
        ),
      ]);

      if (!mounted) return;

      final yeniPersoneller =
          sonuclar[0] as List<KontrolPersonelModel>;
      final yeniKontrolIsleri =
          sonuclar[1] as List<KontrolIsModel>;

      KontrolPersonelModel? guncelSecili;

      for (final personel in yeniPersoneller) {
        if (personel.personelKodu ==
            seciliPersonel.personelKodu) {
          guncelSecili = personel;
          break;
        }
      }

      setState(() {
        _personeller = yeniPersoneller;
        _kontrolIsleri = yeniKontrolIsleri;
        _seciliPersonel =
            guncelSecili ?? seciliPersonel;
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

  Map<String, List<KontrolPersonelModel>>
      _personelleriGrupla() {
    final gruplar =
        <String, List<KontrolPersonelModel>>{};

    for (final personel in _personeller) {
      String grup =
          personel.grup.trim().toUpperCase();

      if (grup.isEmpty) {
        final ad = personel.personelAdi.trim();
        grup = ad.isEmpty
            ? '#'
            : ad.substring(0, 1).toUpperCase();
      }

      gruplar.putIfAbsent(grup, () => []);
      gruplar[grup]!.add(personel);
    }

    final anahtarlar = gruplar.keys.toList()
      ..sort();

    return {
      for (final anahtar in anahtarlar)
        anahtar: gruplar[anahtar]!,
    };
  }

  Map<int, List<KontrolIsModel>>
      _isleriAsilIseGoreGrupla() {
    final gruplar =
        <int, List<KontrolIsModel>>{};

    for (final kontrolIsi in _kontrolIsleri) {
      // Eski API cevabında AsilIsId yoksa kayıtların
      // yanlış birleşmemesi için kontrol işi ID'si kullanılır.
      final anahtar = kontrolIsi.asilIsId > 0
          ? kontrolIsi.asilIsId
          : kontrolIsi.id;

      gruplar.putIfAbsent(anahtar, () => []);
      gruplar[anahtar]!.add(kontrolIsi);
    }

    final sirali = gruplar.entries.toList()
      ..sort((a, b) {
        final aTarih = a.value.first.tarih;
        final bTarih = b.value.first.tarih;

        if (aTarih == null && bTarih == null) {
          return 0;
        }
        if (aTarih == null) return 1;
        if (bTarih == null) return -1;

        return bTarih.compareTo(aTarih);
      });

    return {
      for (final entry in sirali)
        entry.key: entry.value,
    };
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _geriTusunaBasildi,
      child: Scaffold(
        backgroundColor:
            const Color(0xFFF5F6F8),
        appBar: AppBar(
          leading: _seciliPersonel != null
              ? IconButton(
                  onPressed:
                      _personelListesineDon,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                  ),
                )
              : null,
          title: Text(
            _seciliPersonel == null
                ? 'Kontrol'
                : _seciliPersonel!
                    .personelAdi,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
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
                      if (_seciliPersonel ==
                          null) {
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
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 110),
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
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _personelListesiGorunumu() {
    if (_personeller.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 130),
          Icon(
            Icons.fact_check_outlined,
            size: 70,
            color: Colors.black26,
          ),
          SizedBox(height: 16),
          Text(
            'Bekleyen kontrol bulunamadı',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    final gruplar = _personelleriGrupla();

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        24,
      ),
      children: [
        _personelOzetKarti(),
        const SizedBox(height: 10),
        for (final grup in gruplar.entries)
          _personelGrupKarti(
            grup: grup.key,
            personeller: grup.value,
          ),
      ],
    );
  }

  Widget _personelOzetKarti() {
  final tamamlananIs = _personeller.fold<int>(
    0,
    (toplam, personel) => toplam + personel.adet,
  );

  return _beyazKart(
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.analytics_outlined,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_personeller.length} Personel',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bu Hafta',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$tamamlananIs İş Tamamlandı',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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
    required List<KontrolPersonelModel>
        personeller,
  }) {
    return _beyazKart(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding:
            const EdgeInsets.symmetric(
          horizontal: 15,
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          10,
          0,
          10,
          10,
        ),
        title: Text(
          '$grup (${personeller.length})',
          style: const TextStyle(
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
      padding:
          const EdgeInsets.only(top: 7),
      child: Material(
        color: const Color(0xFFF6F7F9),
        borderRadius:
            BorderRadius.circular(13),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(13),
          onTap: () =>
              _kontrolIsleriniGetir(
            personel,
          ),
          child: Padding(
            padding:
                const EdgeInsets.all(13),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      Colors.green
                          .withOpacity(.12),
                  child: Text(
                    _basHarfler(
                      personel.personelAdi,
                    ),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    personel.personelAdi,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                if (personel.aktifKontrolDurumu == 1)
                  _personelDurumEtiketi(
                    'Devam Ediyor',
                    Colors.blue,
                    Icons.play_arrow_rounded,
                  )
                else if (personel.aktifKontrolDurumu == 2)
                  _personelDurumEtiketi(
                    'Ara Verildi',
                    Colors.orange,
                    Icons.pause_rounded,
                  )
                else
                  Text(
                    '${personel.adet} iş',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black38,
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
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 130),
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 70,
            color: Colors.black26,
          ),
          SizedBox(height: 16),
          Text(
            'Kontrol işi bulunamadı',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    final gruplar =
        _isleriAsilIseGoreGrupla();

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        24,
      ),
      children: [
        _kontrolOzetKarti(gruplar.length),
        const SizedBox(height: 10),
        for (final grup in gruplar.values)
          _asilIsKarti(grup),
      ],
    );
  }

  Widget _kontrolOzetKarti(
    int asilIsSayisi,
  ) {
    return _beyazKart(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  Colors.green.withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _seciliPersonel
                          ?.personelAdi ??
                      '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$asilIsSayisi asıl iş • '
                  '${_kontrolIsleri.length} kontrol sırası',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _asilIsKarti(
    List<KontrolIsModel> isler,
  ) {
    final ilk = isler.first;

    final bekleyen = isler
        .where((x) => x.kontrolDurum == 0)
        .length;
    final devam = isler
        .where((x) =>
            x.kontrolDurum == 1 ||
            x.kontrolDurum == 2)
        .length;
    final puanBekleyen = isler
        .where((x) =>
            x.kontrolDurum == 3 &&
            x.puan <= 0)
        .length;

    final Color durumRengi =
        puanBekleyen > 0
            ? Colors.red.shade700
            : devam > 0
                ? Colors.blue.shade700
                : Colors.grey.shade700;

    final siralar = [...isler]
      ..sort((a, b) =>
          a.koridor.compareTo(b.koridor));

    return _beyazKart(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: false,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding:
            const EdgeInsets.fromLTRB(
          14,
          5,
          12,
          5,
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12,
        ),
        leading: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                durumRengi.withOpacity(.10),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Text(
            ilk.asilKoridor.trim().isEmpty
                ? '${isler.length}'
                : ilk.asilKoridor
                    .trim()
                    .toUpperCase(),
            style: TextStyle(
              color: durumRengi,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Text(
          ilk.isAdi,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
     subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      '${ilk.tunel} • '
      '${isler.length} sıra'
      '${devam > 0 ? ' • $devam devam' : ''}'
      '${puanBekleyen > 0 ? ' • $puanBekleyen puan' : ''}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        color: durumRengi,
        fontWeight: FontWeight.w700,
      ),
    ),
    if (ilk.tarih != null) ...[
      const SizedBox(height: 3),
      Text(
        'İş tarihi: ${_tarihSaatYaz(ilk.tarih!)}',
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ],
),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kontrolIsi
                  in siralar)
                _siraButonu(kontrolIsi),
            ],
          ),
          if (bekleyen == isler.length)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 9,
              ),
              child: Text(
                'Kontrole başlamak için bir sıra seçin.',
                style: TextStyle(
                  fontSize: 11.5,
                  color:
                      Colors.black.withOpacity(.45),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _siraButonu(
    KontrolIsModel kontrolIsi,
  ) {
    final durum = _kartDurumu(kontrolIsi);

    return Material(
      color: durum.arkaPlan,
      borderRadius:
          BorderRadius.circular(12),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  KontrolDetayPage(
                kontrolIsId:
                    kontrolIsi.id,
                kontrolEdenPersonelKodu:
                    widget.personelKodu,
              ),
            ),
          );

          if (!mounted) return;
          await _tumKontrolEkraniniYenile();
        },
        child: Container(
          width: 96,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color:
                  durum.renk.withOpacity(.25),
            ),
          ),
          child: Column(
            children: [
              Text(
                kontrolIsi.koridor
                        .trim()
                        .isEmpty
                    ? '-'
                    : kontrolIsi.koridor
                        .trim()
                        .toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  color: durum.renk,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                durum.ikon,
                size: 16,
                color: durum.renk,
              ),
              const SizedBox(height: 2),
              Text(
                _kisaDurumMetni(
                  kontrolIsi,
                ),
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: durum.renk,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _KontrolKartDurumu _kartDurumu(
    KontrolIsModel kontrolIsi,
  ) {
    if (kontrolIsi.kontrolDurum == 3 &&
        kontrolIsi.puan <= 0) {
      return _KontrolKartDurumu(
        renk: Colors.red.shade700,
        arkaPlan:
            Colors.red.withOpacity(.06),
        ikon:
            Icons.priority_high_rounded,
      );
    }

    if (kontrolIsi.kontrolDurum == 1) {
      return _KontrolKartDurumu(
        renk: Colors.blue.shade700,
        arkaPlan:
            Colors.blue.withOpacity(.06),
        ikon:
            Icons.play_arrow_rounded,
      );
    }

    if (kontrolIsi.kontrolDurum == 2) {
      return _KontrolKartDurumu(
        renk: Colors.orange.shade800,
        arkaPlan:
            Colors.orange.withOpacity(.07),
        ikon: Icons.pause_rounded,
      );
    }

    if (kontrolIsi.kontrolDurum == 3 &&
        kontrolIsi.puan > 0) {
      return _KontrolKartDurumu(
        renk: Colors.green.shade700,
        arkaPlan:
            Colors.green.withOpacity(.06),
        ikon: Icons.check_rounded,
      );
    }

    return _KontrolKartDurumu(
      renk: Colors.grey.shade700,
      arkaPlan:
          const Color(0xFFF7F7F9),
      ikon: Icons.schedule_rounded,
    );
  }

  String _kisaDurumMetni(
    KontrolIsModel kontrolIsi,
  ) {
    switch (kontrolIsi.kontrolDurum) {
      case 1:
        return 'Devam';
      case 2:
        return 'Ara';
      case 3:
        return kontrolIsi.puan > 0
            ? 'Puanlı'
            : 'Puan';
      default:
        return 'Bekliyor';
    }
  }

  Widget _personelDurumEtiketi(
    String yazi,
    Color renk,
    IconData ikon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: renk.withOpacity(.10),
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(width: 4),
          Text(
            yazi,
            style: TextStyle(
              color: renk,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _beyazKart({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(14),
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.black.withOpacity(.055),
        ),
      ),
      child: child,
    );
  }

  String _basHarfler(String ad) {
    final parcalar = ad
        .trim()
        .split(RegExp(r'\s+'))
        .where((x) => x.isNotEmpty)
        .toList();

    if (parcalar.isEmpty) return '?';

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

String _tarihSaatYaz(DateTime tarih) {
  String iki(int deger) => deger.toString().padLeft(2, '0');

  return '${iki(tarih.day)}.${iki(tarih.month)}.${tarih.year} '
      '${iki(tarih.hour)}:${iki(tarih.minute)}';
}

class _KontrolKartDurumu {
  final Color renk;
  final Color arkaPlan;
  final IconData ikon;

  const _KontrolKartDurumu({
    required this.renk,
    required this.arkaPlan,
    required this.ikon,
  });
}
