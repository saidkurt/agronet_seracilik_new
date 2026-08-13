import 'package:flutter/material.dart';

import 'package:agronet/api/personel_listesi_api.dart';
import 'package:agronet/models/personel_listesi_model.dart';

class PersonelListesiPage extends StatefulWidget {
  const PersonelListesiPage({super.key});

  @override
  State<PersonelListesiPage> createState() =>
      _PersonelListesiPageState();
}

class _PersonelListesiPageState
    extends State<PersonelListesiPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color background = Color(0xFFF5F6F8);

  final PersonelListesiApi _api = PersonelListesiApi();
  final TextEditingController _aramaController =
      TextEditingController();

  bool _yukleniyor = true;

  List<PersonelListesiModel> _tumListe = [];
  List<PersonelListesiModel> _filtreliListe = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    try {
      setState(() {
        _yukleniyor = true;
      });

      final liste = await _api.personelListesiGetir();

      liste.sort(
        (a, b) => a.adSoyad
            .toLowerCase()
            .compareTo(
              b.adSoyad.toLowerCase(),
            ),
      );

      if (!mounted) return;

      setState(() {
        _tumListe = liste;
        _filtreliListe = List.from(liste);
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _yukleniyor = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Personel listesi yüklenemedi: $e',
          ),
        ),
      );
    }
  }

  void _ara(String value) {
    final text = value.trim().toLowerCase();

    if (text.isEmpty) {
      setState(() {
        _filtreliListe = List.from(_tumListe);
      });

      return;
    }

    final liste = _tumListe.where((item) {
      return item.adSoyad
              .toLowerCase()
              .contains(text) ||
          item.sicilNo
              .toLowerCase()
              .contains(text) ||
          item.tip
              .toLowerCase()
              .contains(text) ||
          item.postaAdi
              .toLowerCase()
              .contains(text) ||
          item.telefon
              .toLowerCase()
              .contains(text);
    }).toList();

    setState(() {
      _filtreliListe = liste;
    });
  }

  String _tarih(DateTime? tarih) {
    if (tarih == null) return '-';

    if (tarih.year <= 1900) {
      return '-';
    }

    final gun =
        tarih.day.toString().padLeft(2, '0');

    final ay =
        tarih.month.toString().padLeft(2, '0');

    return '$gun.$ay.${tarih.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text(
          'Personel Listesi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed:
                _yukleniyor ? null : _yukle,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 20,
            ),
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                _ustAlan(),

                const SizedBox(height: 6),

                Expanded(
                  child: _filtreliListe.isEmpty
                      ? _bosAlan()
                      : _liste(),
                ),
              ],
            ),
    );
  }

  Widget _ustAlan() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        9,
        7,
        9,
        7,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.08),
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  size: 17,
                  color: accent,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personeller',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${_filtreliListe.length} personel',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight:
                            FontWeight.w600,
                        color: Colors.black
                            .withOpacity(.42),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          TextField(
            controller: _aramaController,
            onChanged: _ara,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText:
                  'Ad, sicil, tip, posta veya telefon ara',
              hintStyle: TextStyle(
                fontSize: 10,
                color:
                    Colors.black.withOpacity(.35),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 17,
                color: accent,
              ),
              prefixIconConstraints:
                  const BoxConstraints(
                minWidth: 34,
                minHeight: 34,
              ),
              suffixIcon:
                  _aramaController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _aramaController.clear();
                            _ara('');
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 16,
                          ),
                        ),
              filled: true,
              fillColor:
                  const Color(0xFFF7F7F9),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 9,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liste() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        9,
        0,
        9,
        14,
      ),
      itemCount: _filtreliListe.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = _filtreliListe[index];

        return _personelKart(
          item,
          index + 1,
        );
      },
    );
  }

  Widget _personelKart(
    PersonelListesiModel item,
    int sira,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        9,
        10,
        9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.black.withOpacity(.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.09),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  sira.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.adSoyad.isEmpty
                          ? '-'
                          : item.adSoyad,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Row(
                      children: [
                        Text(
                          'Sicil: ${item.sicilNo.isEmpty ? '-' : item.sicilNo}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight:
                                FontWeight.w600,
                            color: Colors.black
                                .withOpacity(.45),
                          ),
                        ),

                        if (item.tip.isNotEmpty) ...[
                          const SizedBox(width: 7),

                          Container(
                            width: 3,
                            height: 3,
                            decoration:
                                BoxDecoration(
                              color: Colors.black
                                  .withOpacity(.20),
                              shape:
                                  BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 7),

                          Expanded(
                            child: Text(
                              item.tip,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight:
                                    FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.fromLTRB(
              8,
              7,
              8,
              7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F9),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _bilgiSatiri(
                  icon:
                      Icons.work_outline_rounded,
                  label: 'Posta',
                  value: item.postaAdi,
                ),

                _divider(),

                _bilgiSatiri(
                  icon:
                      Icons.phone_outlined,
                  label: 'Telefon',
                  value: item.telefon,
                ),

                _divider(),

                Row(
                  children: [
                    Expanded(
                      child: _miniBilgi(
                        label: 'İşe Giriş',
                        value: _tarih(
                          item.iseGirisTarihi,
                        ),
                      ),
                    ),

                    Container(
                      width: 1,
                      height: 25,
                      color: Colors.black
                          .withOpacity(.07),
                    ),

                    Expanded(
                      child: _miniBilgi(
                        label: 'İşten Çıkış',
                        value: _tarih(
                          item.istenCikisTarihi,
                        ),
                      ),
                    ),
                  ],
                ),

                _divider(),

                Row(
                  children: [
                    Expanded(
                      child: _durumChip(
                        label: 'Puantaj',
                        value:
                            item.puantajaTabi,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: _durumChip(
                        label: 'Mesai',
                        value:
                            item.mesaiAlir,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bilgiSatiri({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: accent,
        ),

        const SizedBox(width: 6),

        SizedBox(
          width: 48,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight:
                  FontWeight.w700,
              color: Colors.black
                  .withOpacity(.42),
            ),
          ),
        ),

        Expanded(
          child: Text(
            value.trim().isEmpty
                ? '-'
                : value.trim(),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniBilgi({
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight:
                FontWeight.w600,
            color:
                Colors.black.withOpacity(.40),
          ),
        ),

        const SizedBox(height: 2),

        Text(
          value,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _durumChip({
    required String label,
    required bool value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: value
            ? accent.withOpacity(.07)
            : Colors.black.withOpacity(.035),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            value
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline,
            size: 13,
            color: value
                ? accent
                : Colors.black.withOpacity(.35),
          ),

          const SizedBox(width: 4),

          Text(
            '$label: ${value ? "Evet" : "Hayır"}',
            style: TextStyle(
              fontSize: 9,
              fontWeight:
                  FontWeight.w800,
              color: value
                  ? accent
                  : Colors.black.withOpacity(.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Divider(
        height: 1,
        thickness: 1,
        color:
            Colors.black.withOpacity(.045),
      ),
    );
  }

  Widget _bosAlan() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 42,
            color:
                Colors.black.withOpacity(.18),
          ),

          const SizedBox(height: 8),

          Text(
            'Personel bulunamadı',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
              color: Colors.black
                  .withOpacity(.45),
            ),
          ),
        ],
      ),
    );
  }
}