import 'package:agronet/api/bitenisler_api.dart';
import 'package:agronet/api/bosta_olanlar_api.dart';
import 'package:agronet/api/personelanlik_api.dart';
import 'package:agronet/api/seraistanimlari.dart';
import 'package:agronet/api/seraistarihleri_api.dart';

import 'package:agronet/models/bostaolanlar_model.dart';
import 'package:agronet/models/personelanlik_model.dart';
import 'package:agronet/models/seraistanimlari.dart';

import 'package:agronet/page/LoginPage/Resim.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:jiffy/jiffy.dart';

class Sera2AnaEkran extends StatefulWidget {
  const Sera2AnaEkran({super.key});

  @override
  State<Sera2AnaEkran> createState() => _Sera2AnaEkranState();
}

class _Sera2AnaEkranState extends State<Sera2AnaEkran> {
  // ---------------- STATE ----------------
  String _iskkodu = '0030';
  bool _value = true;

  int hafta = Jiffy.now().weekOfYear; // eski Jiffy().week yerine
  String sondeger = '1';

  final int _tabbarViewLenght = 3;

  // ✅ ayrı liste (global karışıklık yok)
  List<dynamic> _seraIsTarihleriList = [];

  // Future cache
  late Future<List<PersonelAnlikDurum>> _personelAnlikFuture;
  late Future<List<BostaOlanlar>> _bostaOlanlarFuture;
  late Future<List<dynamic>> _isListesiFuture;
  late Future<List<dynamic>> _seraIsTarihleriFuture;

  @override
  void initState() {
    super.initState();

    _personelAnlikFuture =
        PersonelAnlikApi().personelAnlikDurum("2.SERA");

    _bostaOlanlarFuture = BostaOlanlarApi().personelBos();

    _isListesiFuture = SeraIsTanimlariApi().getSeraIsTanimlari(); // dropdown listesi
    _seraIsTarihleriFuture = _fetchSeraIsTarihleri();
  }

  // ---------------- HELPERS ----------------
  Future<List<dynamic>> _fetchSeraIsTarihleri() async {
    final result = await SeraIsTarihleriApi().isTarihleri(bolum:"2.SERA", isKodu: _iskkodu, hafta: hafta, deger: sondeger);
    return result as List<SeraIsTanimlari>;
  }

  void checkboxdeger(bool value) {
    setState(() {
      sondeger = value ? '1' : '0';
      _seraIsTarihleriFuture = _fetchSeraIsTarihleri();
    });
  }

  Color? cardcolor(String durum) {
    if (durum == "Tamamlandı") return Colors.green.withOpacity(0.8);
    if (durum == "Bekliyor") return Colors.yellow.withOpacity(0.5);
    if (durum == "Planlanmadı") return Colors.red.withOpacity(0.8);
    if (durum == "Aktif") return Colors.grey.withOpacity(0.8);
    if (durum == "Ara Verildi") return Colors.lightBlue.withOpacity(0.8);
    return null;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Montserrat",
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        unselectedWidgetColor: Colors.grey,
      ),
      home: DefaultTabController(
        length: _tabbarViewLenght,
        child: Stack(
          children: [
            Resim2(),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.brown.shade500, Colors.black],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                backgroundColor: Colors.brown.shade500,
                toolbarHeight: MediaQuery.of(context).size.height / 11,
                bottom: TabBar(
                  indicatorColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.3),
                  tabs: const [
                    Tab(text: 'Personel Anlık'),
                    Tab(text: 'Boşta Olanlar'),
                    Tab(text: 'Sera İş Tarihi'),
                  ],
                ),
                title: const Center(
                  child: Text(
                    "Agronet Seracılık A.Ş",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              body: TabBarView(
                children: [
                  _personelAnlikTab(),
                  _bostaOlanlarTab(),
                  _seraIsTarihTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TAB 1 ----------------
  Widget _personelAnlikTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _personelAnlikFuture =
              PersonelAnlikApi().personelAnlikDurum("2.SERA");
        });
      },
      child: FutureBuilder<List<PersonelAnlikDurum>>(
        future: _personelAnlikFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SpinKitDualRing(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return const Center(
              child: Text(
                'Kayıt bulunamadı',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final p = data[index];
              return Card(
                margin: const EdgeInsets.all(7),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    p.personeladi,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(p.personeltipi),
                  leading: Text('${p.sonbaslangicsaati}\n${p.aktifsure}'),
                  trailing: Text('${p.tunel} ${p.koridor}\n${p.yapilanis}'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        actions: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.brown.shade400, Colors.black],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                            width: MediaQuery.of(context).size.height / 2,
                            height: MediaQuery.of(context).size.height / 2,
                            child: FutureBuilder(
                              future: BitenislerApi()
                                  .personelBitenisler(p.personeladi),
                              builder: (context, s2) {
                                if (s2.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: SpinKitCircle(color: Colors.white),
                                  );
                                }
                                if (s2.hasError) {
                                  return Center(
                                    child: Text(
                                      s2.error.toString(),
                                      style:
                                          const TextStyle(color: Colors.red),
                                    ),
                                  );
                                }

                                final list = s2.data;
                                if (list == null || list.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'Kayıt yok',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  itemCount: list.length,
                                  itemBuilder: (context, i) {
                                    final x = list[i];
                                    return ListTile(
                                      subtitle: Text(
                                        x.yapilanis,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      title: Text(
                                        x.tunel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      leading: Text(
                                        x.koridor,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------- TAB 2 ----------------
  Widget _bostaOlanlarTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _bostaOlanlarFuture = BostaOlanlarApi().personelBos();
        });
      },
      child: FutureBuilder<List<BostaOlanlar>>(
        future: _bostaOlanlarFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SpinKitDualRing(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return const Center(
              child: Text(
                'Boşta personel yok',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
            ),
            itemCount: data.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final item = data[index];
              return Card(
                elevation: 1,
                color: Colors.brown.shade500.withOpacity(0.5),
                margin: const EdgeInsets.all(3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(60),
                  side: const BorderSide(color: Colors.transparent),
                ),
                child: Center(
                  child: Text(
                    item.personeladi,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------- TAB 3 ----------------
  Widget _seraIsTarihTab() {
    return Column(
      children: [
        _dropdownBar(),
        Expanded(child: _seraIsTarihleri()),
      ],
    );
  }

  Widget _dropdownBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.shade500, Colors.black],
          stops: const [0.5, 1.0],
        ),
      ),
      height: MediaQuery.of(context).size.height / 16,
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.longestSide,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          alignment: WrapAlignment.start,
          children: [
            const SizedBox(width: 20, height: 20),

            // ✅ Dropdown (iş listesi)
            DropdownButtonHideUnderline(
              child: FutureBuilder<List<dynamic>>(
                future: _isListesiFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  if (snapshot.hasError) {
                    return Text(
                      'Hata: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    );
                  }

                  final list = snapshot.data;
                  if (list == null || list.isEmpty) {
                    return const Text(
                      'İş tanımı yok',
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  // seçili kod listede yoksa ilk elemana çek
                  final exists = list.any((e) => e['kod'] == _iskkodu);
                  if (!exists) {
                    _iskkodu = list.first['kod'];
                  }

                  return DropdownButton<String>(
                    icon: const Icon(Icons.search, color: Colors.white),
                    isExpanded: false,
                    value: _iskkodu,
                    dropdownColor: Colors.brown.shade500,
                    style: const TextStyle(color: Colors.white),
                    items: list.map((item) {
                      return DropdownMenuItem<String>(
                        value: item['kod'].toString(),
                        child: Text(item['isim'].toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _iskkodu = value;
                        _seraIsTarihleriFuture = _fetchSeraIsTarihleri();
                      });
                    },
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.all(15),
              color: Colors.transparent,
              child: const Text(
                'Tamamlananları Göster',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),

            Checkbox(
              checkColor: Colors.white,
              value: _value,
              onChanged: (value) {
                final v = value ?? false;
                setState(() => _value = v);
                checkboxdeger(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _seraIsTarihleri() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _seraIsTarihleriFuture = _fetchSeraIsTarihleri();
        });
      },
      child: FutureBuilder<List<dynamic>>(
        future: _seraIsTarihleriFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SpinKitDualRing(color: Colors.white));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hata: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return const Center(
              child: Text(
                'Kayıt bulunamadı',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          _seraIsTarihleriList = data;

          return GroupedListView<dynamic, String>(
            elements: _seraIsTarihleriList,
            groupBy: (element) => (element['Tünel'] ?? '').toString(),
            groupSeparatorBuilder: (String groupByValue) => Container(
              alignment: Alignment.center,
              height: MediaQuery.of(context).size.height / 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [Colors.brown.shade500, Colors.black],
                  stops: const [0.5, 1.0],
                ),
              ),
              child: Text(
                groupByValue,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            itemBuilder: (context, dynamic element) => Card(
              shadowColor: Colors.white,
              color: cardcolor((element["Durum"] ?? '').toString()),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 25,
                  children: [
                    Text(
                      (element['Koridor'] ?? '').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      (element['Personel Adı'] ?? '').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      (element['Tarih'] ?? '').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            itemComparator: (item1, item2) => (item1['Koridor'] ?? '')
                .toString()
                .compareTo((item2['Koridor'] ?? '').toString()),
            useStickyGroupSeparators: true,
            floatingHeader: true,
            order: GroupedListOrder.ASC,
          );
        },
      ),
    );
  }
}
