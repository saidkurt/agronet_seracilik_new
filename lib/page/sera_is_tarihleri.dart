import 'package:agronet/api/seraistarihleri_api.dart';
import 'package:agronet/models/sera_is_tarih_model.dart';
import 'package:flutter/material.dart';


class DonguKontrolPage extends StatefulWidget {
  const DonguKontrolPage({
    super.key,
    required this.personelKodu,
    required this.kullaniciId,
  });

  final String personelKodu;
  final int kullaniciId;

  @override
  State<DonguKontrolPage> createState() => _DonguKontrolPageState();
}

class _DonguKontrolPageState extends State<DonguKontrolPage> {
  final SeraIsTarihleriApi _api = SeraIsTarihleriApi();

  static const Color _bg = Color(0xFFF3F7F5);
  static const Color _green = Color(0xFF1E6F5C);
  static const Color _greenDark = Color(0xFF145447);
  static const Color _greenSoft = Color(0xFFE8F3EF);
  static const Color _card = Colors.white;
  static const Color _text = Color(0xFF17342D);
  static const Color _muted = Color(0xFF6F817B);

  List<DonguBolumModel> _bolumler = [];
  List<DonguIsModel> _isler = [];
  List<DonguListeModel> _liste = [];

  DonguBolumModel? _seciliBolum;
  DonguIsModel? _seciliIs;

  int _yil = DateTime.now().year;
  int _hafta = 1;

  bool _tamamlananlariGoster = false;

  bool _ilkYukleniyor = true;
  bool _isYukleniyor = false;
  bool _listeYukleniyor = false;
  bool _personelDegisiyor = false;

  String? _hata;

  @override
  void initState() {
    super.initState();
    _hazirla();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  // ============================================================
  // BAŞLANGIÇ
  // ============================================================

  Future<void> _hazirla() async {
    setState(() {
      _ilkYukleniyor = true;
      _hata = null;
    });

    try {
      final hafta = await _api.mevcutHafta();

      final bolumler = await _api.bolumler(
        personelKodu: widget.personelKodu,
      );

      if (!mounted) return;

      setState(() {
        _yil = hafta.yil;
        _hafta = hafta.hafta;
        _bolumler = bolumler;
      });

      if (bolumler.length == 1) {
        _seciliBolum = bolumler.first;
        await _isleriGetir();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hata = _temizHata(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _ilkYukleniyor = false;
        });
      }
    }
  }

  // ============================================================
  // İŞLER
  // ============================================================

  Future<void> _isleriGetir() async {
    final bolum = _seciliBolum;
    if (bolum == null) return;

    setState(() {
      _isYukleniyor = true;
      _seciliIs = null;
      _isler = [];
      _liste = [];
      _hata = null;
    });

    try {
      final sonuc = await _api.isler(
        personelKodu: widget.personelKodu,
        bolumKodu: bolum.kod,
      );

      if (!mounted) return;

      setState(() {
        _isler = sonuc;
      });

      if (sonuc.length == 1) {
        _seciliIs = sonuc.first;
        await _listeyiGetir();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hata = _temizHata(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isYukleniyor = false;
        });
      }
    }
  }

  // ============================================================
  // LİSTE
  // ============================================================

  Future<void> _listeyiGetir() async {
    final bolum = _seciliBolum;
    final isSecim = _seciliIs;

    if (bolum == null || isSecim == null) {
      return;
    }

    setState(() {
      _listeYukleniyor = true;
      _hata = null;
    });

    try {
      final sonuc = await _api.donguListe(
        bolum: bolum.kod,
        isKodu: isSecim.kod,
        yil: _yil,
        hafta: _hafta,
        tamamlananlar: _tamamlananlariGoster,
      );

      if (!mounted) return;

      setState(() {
        _liste = sonuc;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hata = _temizHata(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _listeYukleniyor = false;
        });
      }
    }
  }

  // ============================================================
  // HAFTA
  // ============================================================

  Future<void> _haftaDegistir(int fark) async {
    int hafta = _hafta + fark;
    int yil = _yil;

    if (hafta <= 0) {
      hafta = 53;
      yil--;
    } else if (hafta > 53) {
      hafta = 1;
      yil++;
    }

    setState(() {
      _hafta = hafta;
      _yil = yil;
    });

    if (_seciliIs != null) {
      await _listeyiGetir();
    }
  }

  // ============================================================
  // SEÇİM
  // ============================================================

  int get _seciliSayisi =>
      _liste.where((x) => x.sec && x.isEmriId > 0).length;

  List<int> get _seciliIdler {
    return _liste
        .where((x) => x.sec && x.isEmriId > 0)
        .map((x) => x.isEmriId)
        .toSet()
        .toList();
  }

  List<DonguListeModel> get _secilebilirListe =>
      _liste.where((x) => x.isEmriId > 0).toList();

  bool get _hepsiSecili {
    final liste = _secilebilirListe;

    if (liste.isEmpty) return false;

    return liste.every((x) => x.sec);
  }

  void _tumunuSec(bool value) {
    setState(() {
      for (final item in _liste) {
        if (item.isEmriId > 0) {
          item.sec = value;
        }
      }
    });
  }

  // ============================================================
  // PERSONEL
  // ============================================================

  Future<void> _personelSec() async {
    final idler = _seciliIdler;

    if (idler.isEmpty) {
      _snack('Önce en az bir iş seçin.');
      return;
    }

    try {
      final personeller = await _api.personeller();

      if (!mounted) return;

      final secilen = await showModalBottomSheet<DonguPersonelModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PersonelSecSheet(
          personeller: personeller,
        ),
      );

      if (secilen == null) return;

      await _personelDegistir(secilen);
    } catch (e) {
      _snack(
        _temizHata(e),
        hata: true,
      );
    }
  }

  Future<void> _personelDegistir(
    DonguPersonelModel personel,
  ) async {
    final idler = _seciliIdler;

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Personel Değiştir',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '${idler.length} iş emri '
            '${personel.isim} personeline aktarılacak.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('VAZGEÇ'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _green,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('DEĞİŞTİR'),
            ),
          ],
        );
      },
    );

    if (onay != true) return;

    setState(() {
      _personelDegisiyor = true;
    });

    try {
      final sonuc = await _api.personelDegistir(
        isEmriIdleri: idler,
        yeniPersonelKodu: personel.kod,
        kullaniciId: widget.kullaniciId,
      );

      if (!mounted) return;

      _snack(sonuc.mesaj);

      await _listeyiGetir();
    } catch (e) {
      if (!mounted) return;

      _snack(
        _temizHata(e),
        hata: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _personelDegisiyor = false;
        });
      }
    }
  }

  // ============================================================
  // TABLO
  // ============================================================

  Future<void> _tabloGoster() async {
    final bolum = _seciliBolum;
    final isSecim = _seciliIs;

    if (bolum == null || isSecim == null) {
      _snack('Önce bölüm ve iş seçin.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final tablo = await _api.donguTablo(
        bolum: bolum.kod,
        isKodu: isSecim.kod,
        yil: _yil,
        hafta: _hafta,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _DonguTabloPage(
            liste: tablo,
            bolum: '${bolum.kod} - ${bolum.isim}',
            isAdi: '${isSecim.kod} - ${isSecim.isim}',
            yil: _yil,
            hafta: _hafta,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      _snack(
        _temizHata(e),
        hata: true,
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final scaler =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.08);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          toolbarHeight: 54,
          titleSpacing: 16,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AGRONET',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2.1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFCDE5DC),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Döngü Kontrol',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          foregroundColor: Colors.white,
          backgroundColor: _green,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                tooltip: 'Yenile',
                onPressed: _listeYukleniyor ? null : _listeyiGetir,
                icon: const Icon(Icons.refresh_rounded, size: 21),
              ),
            ),
          ],
        ),
        body: _ilkYukleniyor
            ? const Center(
                child: CircularProgressIndicator(color: _green),
              )
            : Column(
                children: [
                  _filtrePaneli(),
                  if (_hata != null) _hataSatiri(),
                  Expanded(child: _icerik()),
                ],
              ),
        bottomNavigationBar: _ilkYukleniyor ? null : _altBar(),
      ),
    );
  }

  // ============================================================
  // FİLTRE
  // ============================================================

  Widget _filtrePaneli() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 5),
      decoration: const BoxDecoration(
        color: _bg,
      ),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFE4ECE8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.035),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _bolumDropdown()),
                const SizedBox(width: 5),
                Expanded(flex: 2, child: _isDropdown()),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _greenSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _haftaButonu(
                    Icons.chevron_left_rounded,
                    () => _haftaDegistir(-1),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'DÖNEM',
                          style: TextStyle(
                            fontSize: 8,
                            letterSpacing: .9,
                            fontWeight: FontWeight.w800,
                            color: _muted,
                          ),
                        ),
                        Text(
                          '$_yil  •  $_hafta. Hafta',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: _greenDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _haftaButonu(
                    Icons.chevron_right_rounded,
                    () => _haftaDegistir(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                setState(() {
                  _tamamlananlariGoster = !_tamamlananlariGoster;
                });
                if (_seciliIs != null) await _listeyiGetir();
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: Checkbox(
                      value: _tamamlananlariGoster,
                      activeColor: _green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      visualDensity: VisualDensity.compact,
                      onChanged: (value) async {
                        setState(() {
                          _tamamlananlariGoster = value ?? false;
                        });
                        if (_seciliIs != null) await _listeyiGetir();
                      },
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Tamamlananları göster',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bolumDropdown() {
    return SizedBox(
      height: 35,
      child: DropdownButtonFormField<DonguBolumModel>(
        value: _seciliBolum,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
        ),
        decoration: _denseInput('Bölüm'),
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black87,
          fontWeight: FontWeight.w700,
        ),
        hint: const Text(
          'Bölüm',
          style: TextStyle(fontSize: 11),
        ),
        items: _bolumler.map((x) {
          return DropdownMenuItem(
            value: x,
            child: Text(
              x.kod,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            _seciliBolum = value;
            _seciliIs = null;
            _isler = [];
            _liste = [];
          });

          if (value != null) {
            await _isleriGetir();
          }
        },
      ),
    );
  }

  Widget _isDropdown() {
    return SizedBox(
      height: 35,
      child: DropdownButtonFormField<DonguIsModel>(
        value: _seciliIs,
        isExpanded: true,
        icon: _isYukleniyor
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
              ),
        decoration: _denseInput('İş'),
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black87,
          fontWeight: FontWeight.w700,
        ),
        hint: Text(
          _isYukleniyor ? 'Yükleniyor...' : 'İş seç',
          style: const TextStyle(fontSize: 11),
        ),
        items: _isler.map((x) {
          return DropdownMenuItem(
            value: x,
            child: Text(
              '${x.isim} (${x.aktifAdet})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: _isYukleniyor
            ? null
            : (value) async {
                setState(() {
                  _seciliIs = value;
                  _liste = [];
                });

                if (value != null) {
                  await _listeyiGetir();
                }
              },
      ),
    );
  }

  InputDecoration _denseInput(String label) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      labelStyle: const TextStyle(
        fontSize: 9,
        letterSpacing: .6,
        fontWeight: FontWeight.w800,
        color: _muted,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.fromLTRB(9, 8, 7, 7),
      filled: true,
      fillColor: const Color(0xFFF8FBFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE1EAE6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE1EAE6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _green, width: 1.3),
      ),
    );
  }

  Widget _haftaButonu(
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 32,
      height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 22,
        ),
      ),
    );
  }

  // ============================================================
  // ANA İÇERİK
  // ============================================================

  Widget _icerik() {
    if (_listeYukleniyor) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_seciliBolum == null) {
      return _bosGorunum(
        Icons.grid_view_outlined,
        'Bölüm seçin',
      );
    }

    if (_seciliIs == null) {
      return _bosGorunum(
        Icons.assignment_outlined,
        'İş seçin',
      );
    }

    if (_liste.isEmpty) {
      return _bosGorunum(
        Icons.inbox_outlined,
        'Kayıt bulunamadı',
      );
    }

    return Column(
      children: [
        

        Expanded(
          child: RefreshIndicator(
            onRefresh: _listeyiGetir,
            child: ListView.separated(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(9, 1, 9, 8),
              itemCount: _liste.length,
              separatorBuilder: (_, __) {
                return const SizedBox(height: 4);
              },
              itemBuilder: (_, index) {
                return _listeSatiri(
                  _liste[index],
                );
              },
            ),
          ),
        ),
      ],
    );
  }



  Widget _listeSatiri(
    DonguListeModel item,
  ) {
    final renk = _durumRengi(item.durum, item.dongusuKacti);
    final secilebilir = item.isEmriId > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: secilebilir
            ? () {
                setState(() {
                  item.sec = !item.sec;
                });
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minHeight: 54),
          decoration: BoxDecoration(
            color: item.sec ? _greenSoft.withOpacity(.68) : Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: item.sec
                  ? _green.withOpacity(.38)
                  : const Color(0xFFE4ECE8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                constraints: const BoxConstraints(minHeight: 52),
                decoration: BoxDecoration(
                  color: renk,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: item.sec,
                  visualDensity: VisualDensity.compact,
                  activeColor: _green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: secilebilir
                      ? (value) {
                          setState(() {
                            item.sec = value ?? false;
                          });
                        }
                      : null,
                ),
              ),
              Container(
                width: 54,
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.tunel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.koridor.isEmpty ? '-' : 'Kor. ${item.koridor}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.personelAdi.trim().isEmpty ? '-' : item.personelAdi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.8,
                          fontWeight: FontWeight.w900,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: _muted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.tarih.trim().isEmpty ? '-' : item.tarih,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.3,
                                color: _muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: _muted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${item.sure.toStringAsFixed(0)} dk',
                            style: const TextStyle(
                              fontSize: 9.3,
                              color: _muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                constraints: const BoxConstraints(maxWidth: 78),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: renk.withOpacity(.11),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: renk.withOpacity(.18)),
                ),
                child: Text(
                  item.dongusuKacti ? 'Döngü Kaçtı' : _durumKisa(item.durum),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.2,
                    height: 1.05,
                    color: renk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _durumKisa(String durum) {
    switch (durum) {
      case 'Tamamlandı':
        return 'Tamam';
      case 'Ara Verildi':
        return 'Ara';
      case 'Aktif':
        return 'Aktif';
      case 'Bekliyor':
        return 'Bekliyor';
      default:
        return durum.isEmpty ? '-' : durum;
    }
  }

  Color _durumRengi(
    String durum,
    bool dongusuKacti,
  ) {
    if (dongusuKacti) {
      return Colors.red.shade800;
    }

    switch (durum) {
      case 'Tamamlandı':
        return Colors.green.shade700;

      case 'Ara Verildi':
        return Colors.orange.shade800;

      case 'Aktif':
        return Colors.blue.shade700;

      case 'Bekliyor':
        return Colors.grey.shade700;

      default:
        return Colors.black38;
    }
  }

  // ============================================================
  // ALT BAR
  // ============================================================

  Widget _altBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE1EAE6)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _greenDark,
                    side: const BorderSide(color: Color(0xFFD7E5DF)),
                    backgroundColor: const Color(0xFFF8FBFA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _seciliIs == null ? null : _tabloGoster,
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: const Text(
                    'TABLO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 40,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: const Color(0xFFB9C8C3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _seciliSayisi == 0 || _personelDegisiyor
                      ? null
                      : _personelSec,
                  icon: _personelDegisiyor
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.manage_accounts_outlined, size: 18),
                  label: Text(
                    _seciliSayisi == 0
                        ? 'PERSONEL DEĞİŞTİR'
                        : 'PERSONEL DEĞİŞTİR ($_seciliSayisi)',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
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
  // HATA / BOŞ
  // ============================================================

  Widget _hataSatiri() {
    return Container(
      width: double.infinity,
      color: Colors.red.shade50,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              _hata ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                color: Colors.red.shade800,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _hata = null;
              });
            },
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(
                Icons.close_rounded,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bosGorunum(
    IconData icon,
    String text,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(
          icon,
          size: 46,
          color: Colors.black26,
        ),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black45,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _temizHata(dynamic hata) {
    return hata
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }

  void _snack(
    String mesaj, {
    bool hata = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mesaj,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        backgroundColor:
            hata ? Colors.red.shade700 : _green,
      ),
    );
  }
}

// ============================================================================
// PERSONEL SEÇ
// ============================================================================

class _PersonelSecSheet extends StatefulWidget {
  const _PersonelSecSheet({
    required this.personeller,
  });

  final List<DonguPersonelModel> personeller;

  @override
  State<_PersonelSecSheet> createState() =>
      _PersonelSecSheetState();
}

class _PersonelSecSheetState
    extends State<_PersonelSecSheet> {
  final TextEditingController _arama =
      TextEditingController();

  String _aranan = '';

  @override
  void dispose() {
    _arama.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _aranan.trim().toLowerCase();

    final liste = widget.personeller.where((x) {
      return q.isEmpty ||
          x.isim.toLowerCase().contains(q) ||
          x.kod.toLowerCase().contains(q);
    }).toList();

    return Container(
      height:
          MediaQuery.of(context).size.height * .72,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F7F5),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 3),

          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(5),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              12,
              9,
              6,
              5,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Personel Seç',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _arama,
                style: const TextStyle(
                  fontSize: 12,
                ),
                onChanged: (value) {
                  setState(() {
                    _aranan = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Personel ara...',
                  hintStyle: const TextStyle(
                    fontSize: 11,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 19,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                8,
                0,
                8,
                12,
              ),
              itemCount: liste.length,
              separatorBuilder: (_, __) {
                return const SizedBox(height: 3);
              },
              itemBuilder: (_, index) {
                final item = liste[index];

                return Material(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(9),
                  child: ListTile(
                    dense: true,
                    minTileHeight: 48,
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                    ),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          const Color(0xFFE8F3EF),
                      child: Text(
                        item.grup.trim().isEmpty
                            ? '?'
                            : item.grup,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1E6F5C),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    title: Text(
                      item.isim,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      item.kod,
                      style: const TextStyle(
                        fontSize: 9.5,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      size: 19,
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        item,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TABLO GÖSTER
// ============================================================================

class _DonguTabloPage extends StatefulWidget {
  const _DonguTabloPage({
    required this.liste,
    required this.bolum,
    required this.isAdi,
    required this.yil,
    required this.hafta,
  });

  final List<DonguTabloModel> liste;
  final String bolum;
  final String isAdi;
  final int yil;
  final int hafta;

  @override
  State<_DonguTabloPage> createState() =>
      _DonguTabloPageState();
}

class _DonguTabloPageState
    extends State<_DonguTabloPage> {
  bool _kuzey = true;

  static const Color _green =
      Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    final scaler =
        MediaQuery.textScalerOf(context).clamp(
      maxScaleFactor: 1.05,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: scaler,
      ),
      child: Scaffold(
        backgroundColor:
            const Color(0xFFF3F7F5),
        appBar: AppBar(
          title: const Text(
            'Döngü Tablosu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          foregroundColor: Colors.white,
          backgroundColor: _green,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Column(
          children: [
            _ustBilgi(),
            _yonSecim(),
            _baslik(),

            Expanded(
              child: widget.liste.isEmpty
                  ? const Center(
                      child: Text(
                        'Kayıt bulunamadı',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black45,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(
                        5,
                        0,
                        5,
                        8,
                      ),
                      itemCount:
                          widget.liste.length,
                      itemBuilder: (_, index) {
                        return _satir(
                          widget.liste[index],
                        );
                      },
                    ),
            ),

            _lejant(),
          ],
        ),
      ),
    );
  }

  Widget _ustBilgi() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        8,
        3,
        8,
        3,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            widget.isAdi,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${widget.bolum}  •  '
            '${widget.yil} / ${widget.hafta}. Hafta',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.8,
              color: Colors.black45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _yonSecim() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        5,
        1,
        5,
        3,
      ),
      child: Row(
        children: [
          Expanded(
            child: _yonButon(
              'KUZEY',
              Icons.north_rounded,
              true,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _yonButon(
              'GÜNEY',
              Icons.south_rounded,
              false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _yonButon(
    String text,
    IconData icon,
    bool kuzey,
  ) {
    final secili = _kuzey == kuzey;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _kuzey = kuzey;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 120),
        height: 28,
        decoration: BoxDecoration(
          color: secili
              ? _green.withOpacity(.12)
              : const Color(0xFFF8FBFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: secili
                ? _green.withOpacity(.35)
                : Colors.black.withOpacity(.06),
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color:
                  secili ? _green : Colors.black45,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 9,
                color:
                    secili ? _green : Colors.black54,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 350 civarı kullanılabilir ekranda:
  // 42 tünel + 6 x Expanded
  // tamamı dikey ekrana sığar.
  Widget _baslik() {
    return Container(
      height: 25,
      margin: const EdgeInsets.fromLTRB(
        4,
        3,
        4,
        0,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFE3EFEA),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(7),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 38,
            child: Center(
              child: Text(
                'TÜN',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _TabloBaslik('A'),
          _TabloBaslik('B'),
          _TabloBaslik('C'),
          _TabloBaslik('D'),
          _TabloBaslik('E'),
          _TabloBaslik('F'),
        ],
      ),
    );
  }

  Widget _satir(
    DonguTabloModel item,
  ) {
    final List<DonguTabloHucreModel?> hucreler =
        _kuzey
            ? [
                item.ka,
                item.kb,
                item.kc,
                item.kd,
                item.ke,
                item.kf,
              ]
            : [
                item.ga,
                item.gb,
                item.gc,
                item.gd,
                item.ge,
                item.gf,
              ];

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(.06),
          ),
          left: BorderSide(
            color: Colors.black.withOpacity(.04),
          ),
          right: BorderSide(
            color: Colors.black.withOpacity(.04),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Center(
              child: Text(
                item.sira,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          for (final hucre in hucreler)
            Expanded(
              child: _hucre(hucre),
            ),
        ],
      ),
    );
  }

  Widget _hucre(
    DonguTabloHucreModel? item,
  ) {
    if (item == null ||
        item.text.trim().isEmpty ||
        item.text == '-') {
      return const Center(
        child: Text(
          '-',
          style: TextStyle(
            fontSize: 11,
            color: Colors.black26,
          ),
        ),
      );
    }

    final renk = _hucreRengi(item.renk);

    return InkWell(
      onTap: () => _detayGoster(item),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: renk.withOpacity(
            item.renk == 'donguKacti'
                ? 1
                : .15,
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: renk.withOpacity(.25),
          ),
        ),
        child: Center(
          child: Icon(
            _hucreIkon(item),
            size: 13,
            color: item.renk == 'donguKacti'
                ? Colors.white
                : renk,
          ),
        ),
      ),
    );
  }

  IconData _hucreIkon(
    DonguTabloHucreModel item,
  ) {
    switch (item.renk) {
      case 'tamamlandi':
        return Icons.check_rounded;

      case 'aktif':
        return Icons.play_arrow_rounded;

      case 'ara':
        return Icons.pause_rounded;

      case 'bekliyor':
        return Icons.schedule_rounded;

      case 'personelYok':
        return Icons.person_off_outlined;

      case 'donguKacti':
        return Icons.priority_high_rounded;

      default:
        return Icons.remove_rounded;
    }
  }

  Color _hucreRengi(String durum) {
    switch (durum) {
      case 'tamamlandi':
        return Colors.green.shade700;

      case 'aktif':
        return Colors.blue.shade700;

      case 'ara':
        return Colors.orange.shade800;

      case 'bekliyor':
        return Colors.grey.shade700;

      case 'personelYok':
        return Colors.orange.shade800;

      case 'donguKacti':
        return Colors.red.shade800;

      default:
        return Colors.grey;
    }
  }

  void _detayGoster(
    DonguTabloHucreModel item,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            15,
            12,
            15,
            22,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(18),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.durum.isEmpty
                            ? 'Döngü Detayı'
                            : item.durum,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color:
                            _hucreRengi(item.renk),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  item.text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (item.dongusuKacti) ...[
                  const SizedBox(height: 9),
                  Text(
                    'Döngüsü kaçtı',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _lejant() {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3,
        ),
        child: const Wrap(
          alignment: WrapAlignment.center,
          spacing: 7,
          runSpacing: 2,
          children: [
            _Lejant(
              renk: Colors.green,
              yazi: 'Tamam',
            ),
            _Lejant(
              renk: Colors.blue,
              yazi: 'Aktif',
            ),
            _Lejant(
              renk: Colors.orange,
              yazi: 'Ara / PYOK',
            ),
            _Lejant(
              renk: Colors.grey,
              yazi: 'Bekliyor',
            ),
            _Lejant(
              renk: Colors.red,
              yazi: 'Döngü kaçtı',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TABLO YARDIMCILARI
// ============================================================================

class _TabloBaslik extends StatelessWidget {
  const _TabloBaslik(this.yazi);

  final String yazi;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          yazi,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _Lejant extends StatelessWidget {
  const _Lejant({
    required this.renk,
    required this.yazi,
  });

  final Color renk;
  final String yazi;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: renk,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          yazi,
          style: const TextStyle(
            fontSize: 7.8,
            color: Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}