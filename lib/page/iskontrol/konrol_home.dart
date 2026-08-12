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
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _green = Color(0xFF1E6F5C);

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

  // ============================================================
  // PERSONELLER
  // ============================================================

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
  // KONTROL İŞLERİ
  // ============================================================

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
  // TAM YENİLE
  // ============================================================

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
          kontrolEdenPersonelKodu: widget.personelKodu,
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
  // GERİ
  // ============================================================

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

  // ============================================================
  // GRUPLAMA
  // ============================================================

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
      child: WillPopScope(
        onWillPop: _geriTusunaBasildi,
        child: Scaffold(
          backgroundColor: _bg,

          // ======================================================
          // APPBAR
          // ======================================================

          appBar: AppBar(
            toolbarHeight: 48,
            leading: _seciliPersonel != null
                ? IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _personelListesineDon,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 21,
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
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            centerTitle: true,
            foregroundColor: Colors.black87,
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                visualDensity: VisualDensity.compact,
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
                  size: 21,
                ),
              ),
            ],
          ),

          body: RefreshIndicator(
            color: _green,
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
      ),
    );
  }

  // ============================================================
  // İÇERİK
  // ============================================================

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

  // ============================================================
  // HATA
  // ============================================================

  Widget _hataGorunumu() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 90),

        Icon(
          Icons.cloud_off_rounded,
          size: 42,
          color: Colors.red.shade300,
        ),

        const SizedBox(height: 10),

        const Text(
          'Veriler alınamadı',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          _hataMesaji!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PERSONEL LİSTESİ
  // ============================================================

  Widget _personelListesiGorunumu() {
    if (_personeller.isEmpty) {
      return _bosGorunum(
        icon: Icons.fact_check_outlined,
        text: 'Bekleyen kontrol bulunamadı',
      );
    }

    final gruplar = _personelleriGrupla();

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        7,
        6,
        7,
        12,
      ),
      children: [
        _personelOzetKarti(),

        const SizedBox(height: 5),

        for (final grup in gruplar.entries)
          _personelGrupKarti(
            grup: grup.key,
            personeller: grup.value,
          ),
      ],
    );
  }

  // ============================================================
  // PERSONEL ÖZET
  // ============================================================

  Widget _personelOzetKarti() {
    final tamamlananIs =
        _personeller.fold<int>(
      0,
      (toplam, personel) =>
          toplam + personel.adet,
    );

    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.black.withOpacity(.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: _green.withOpacity(.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 17,
              color: _green,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              '${_personeller.length} personel',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          Text(
            '$tamamlananIs iş',
            style: const TextStyle(
              fontSize: 10.5,
              color: _green,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HARF GRUBU
  // ============================================================

  Widget _personelGrupKarti({
    required String grup,
    required List<KontrolPersonelModel> personeller,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.black.withOpacity(.05),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          visualDensity: VisualDensity.compact,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          dense: true,
          shape: const Border(),
          collapsedShape: const Border(),

          tilePadding: const EdgeInsets.symmetric(
            horizontal: 9,
          ),

          childrenPadding:
              const EdgeInsets.fromLTRB(
            6,
            0,
            6,
            6,
          ),

          title: Text(
            '$grup  (${personeller.length})',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),

          children: personeller
              .map(_personelKarti)
              .toList(),
        ),
      ),
    );
  }

  // ============================================================
  // PERSONEL SATIRI
  // ============================================================

  Widget _personelKarti(
    KontrolPersonelModel personel,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Material(
        color: const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: () {
            _kontrolIsleriniGetir(personel);
          },
          child: SizedBox(
            height: 43,
            child: Row(
              children: [
                const SizedBox(width: 7),

                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      _green.withOpacity(.10),
                  child: Text(
                    _basHarfler(
                      personel.personelAdi,
                    ),
                    style: const TextStyle(
                      fontSize: 9,
                      color: _green,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    personel.personelAdi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                if (personel.aktifKontrolDurumu == 1)
                  _personelDurumEtiketi(
                    'Devam',
                    Colors.blue.shade700,
                    Icons.play_arrow_rounded,
                  )
                else if (personel.aktifKontrolDurumu == 2)
                  _personelDurumEtiketi(
                    'Ara',
                    Colors.orange.shade800,
                    Icons.pause_rounded,
                  )
                else
                  Text(
                    '${personel.adet} iş',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: _green,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                const SizedBox(width: 3),

                const Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: Colors.black26,
                ),

                const SizedBox(width: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // KONTROL İŞLERİ
  // ============================================================

  Widget _kontrolIsleriGorunumu() {
    if (_kontrolIsleri.isEmpty) {
      return _bosGorunum(
        icon: Icons.assignment_turned_in_outlined,
        text: 'Kontrol işi bulunamadı',
      );
    }

    final gruplar =
        _isleriAsilIseGoreGrupla();

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        7,
        6,
        7,
        12,
      ),
      children: [
        _kontrolOzetKarti(
          gruplar.length,
        ),

        const SizedBox(height: 5),

        for (final grup in gruplar.values)
          _asilIsKarti(grup),
      ],
    );
  }

  // ============================================================
  // KONTROL ÖZET
  // ============================================================

  Widget _kontrolOzetKarti(
    int asilIsSayisi,
  ) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.black.withOpacity(.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: _green.withOpacity(.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              size: 17,
              color: _green,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              _seciliPersonel?.personelAdi ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          Text(
            '$asilIsSayisi iş • '
            '${_kontrolIsleri.length} sıra',
            style: const TextStyle(
              fontSize: 9.5,
              color: Colors.black45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ASIL İŞ
  // ============================================================

  Widget _asilIsKarti(
    List<KontrolIsModel> isler,
  ) {
    final ilk = isler.first;

    final bekleyen = isler
        .where(
          (x) => x.kontrolDurum == 0,
        )
        .length;

    final devam = isler
        .where(
          (x) =>
              x.kontrolDurum == 1 ||
              x.kontrolDurum == 2,
        )
        .length;

    final puanBekleyen = isler
        .where(
          (x) =>
              x.kontrolDurum == 3 &&
              x.puan <= 0,
        )
        .length;

    final Color durumRengi =
        puanBekleyen > 0
            ? Colors.red.shade700
            : devam > 0
                ? Colors.blue.shade700
                : Colors.grey.shade700;

    final siralar = [...isler]
      ..sort(
        (a, b) =>
            a.koridor.compareTo(b.koridor),
      );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.black.withOpacity(.05),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          visualDensity: VisualDensity.compact,
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          dense: true,
          shape: const Border(),
          collapsedShape: const Border(),

          tilePadding:
              const EdgeInsets.fromLTRB(
            8,
            2,
            7,
            2,
          ),

          childrenPadding:
              const EdgeInsets.fromLTRB(
            7,
            0,
            7,
            7,
          ),

          leading: Container(
            width: 31,
            height: 31,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  durumRengi.withOpacity(.09),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Text(
              ilk.asilKoridor.trim().isEmpty
                  ? '${isler.length}'
                  : ilk.asilKoridor
                      .trim()
                      .toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: durumRengi,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          title: Text(
            ilk.isAdi,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),

          subtitle: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '${ilk.tunel} • '
                '${isler.length} sıra'
                '${devam > 0 ? ' • $devam devam' : ''}'
                '${puanBekleyen > 0 ? ' • $puanBekleyen puan' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  color: durumRengi,
                  fontWeight: FontWeight.w700,
                ),
              ),

              if (ilk.tarih != null)
                Text(
                  _tarihSaatYaz(
                    ilk.tarih!,
                  ),
                  style: const TextStyle(
                    fontSize: 8.8,
                    color: Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final kontrolIsi
                      in siralar)
                    _siraButonu(
                      kontrolIsi,
                    ),
                ],
              ),
            ),

            if (bekleyen == isler.length)
              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 5,
                ),
                child: Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'Kontrole başlamak için sıra seçin.',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.black
                          .withOpacity(.38),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SIRA BUTONU
  // ============================================================

  Widget _siraButonu(
    KontrolIsModel kontrolIsi,
  ) {
    final durum =
        _kartDurumu(kontrolIsi);

    return Material(
      color: durum.arkaPlan,
      borderRadius:
          BorderRadius.circular(7),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(7),
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
          width: 71,
          height: 47,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(7),
            border: Border.all(
              color:
                  durum.renk.withOpacity(.20),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  kontrolIsi.koridor
                          .trim()
                          .isEmpty
                      ? '-'
                      : kontrolIsi.koridor
                          .trim()
                          .toUpperCase(),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: durum.renk,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(width: 2),

              Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    durum.ikon,
                    size: 13,
                    color: durum.renk,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _kisaDurumMetni(
                      kontrolIsi,
                    ),
                    style: TextStyle(
                      fontSize: 7.5,
                      color: durum.renk,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DURUMLAR
  // ============================================================

  _KontrolKartDurumu _kartDurumu(
    KontrolIsModel kontrolIsi,
  ) {
    if (kontrolIsi.kontrolDurum == 3 &&
        kontrolIsi.puan <= 0) {
      return _KontrolKartDurumu(
        renk: Colors.red.shade700,
        arkaPlan:
            Colors.red.withOpacity(.05),
        ikon: Icons.priority_high_rounded,
      );
    }

    if (kontrolIsi.kontrolDurum == 1) {
      return _KontrolKartDurumu(
        renk: Colors.blue.shade700,
        arkaPlan:
            Colors.blue.withOpacity(.05),
        ikon: Icons.play_arrow_rounded,
      );
    }

    if (kontrolIsi.kontrolDurum == 2) {
      return _KontrolKartDurumu(
        renk: Colors.orange.shade800,
        arkaPlan:
            Colors.orange.withOpacity(.06),
        ikon: Icons.pause_rounded,
      );
    }

    if (kontrolIsi.kontrolDurum == 3 &&
        kontrolIsi.puan > 0) {
      return _KontrolKartDurumu(
        renk: Colors.green.shade700,
        arkaPlan:
            Colors.green.withOpacity(.05),
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

  // ============================================================
  // PERSONEL DURUM
  // ============================================================

  Widget _personelDurumEtiketi(
    String yazi,
    Color renk,
    IconData ikon,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: renk.withOpacity(.08),
        borderRadius:
            BorderRadius.circular(6),
        border: Border.all(
          color: renk.withOpacity(.12),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            ikon,
            size: 11,
            color: renk,
          ),

          const SizedBox(width: 2),

          Text(
            yazi,
            style: TextStyle(
              color: renk,
              fontSize: 8.5,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOŞ GÖRÜNÜM
  // ============================================================

  Widget _bosGorunum({
    required IconData icon,
    required String text,
  }) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),

        Icon(
          icon,
          size: 45,
          color: Colors.black26,
        ),

        const SizedBox(height: 9),

        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black45,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // YARDIMCI
  // ============================================================

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

// ================================================================
// TARİH
// ================================================================

String _tarihSaatYaz(
  DateTime tarih,
) {
  String iki(int deger) =>
      deger.toString().padLeft(
            2,
            '0',
          );

  return '${iki(tarih.day)}.'
      '${iki(tarih.month)}.'
      '${tarih.year} '
      '${iki(tarih.hour)}:'
      '${iki(tarih.minute)}';
}

// ================================================================
// DURUM MODEL
// ================================================================

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