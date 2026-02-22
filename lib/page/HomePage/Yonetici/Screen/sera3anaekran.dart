
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

class Sera3AnaEkran extends StatefulWidget {
  const Sera3AnaEkran({super.key});

  @override
  State<Sera3AnaEkran> createState() => _Sera3AnaEkranState();
}

class _Sera3AnaEkranState extends State<Sera3AnaEkran> {
  // ---------------- STATE ----------------
  String _iskkodu = '0030';

  int hafta = Jiffy.now().weekOfYear;
  String sondeger = '1';

  final int _tabbarViewLenght = 3;

  List<dynamic> _seraIsTarihleriList = [];

  late Future<List<PersonelAnlikDurum>> _personelAnlikFuture;
  late Future<List<BostaOlanlar>> _bostaOlanlarFuture;
  late Future<List<dynamic>> _seraIsTarihleriFuture;
  late Future<List<dynamic>> _isListesiFuture;

  @override
  void initState() {
    super.initState();

    _personelAnlikFuture =
        PersonelAnlikApi().personelAnlikDurum("3.SERA");

    _bostaOlanlarFuture = BostaOlanlarApi().personelBos();

    _isListesiFuture = SeraIsTanimlariApi().getSeraIsTanimlari(); // iş tanımları

    _seraIsTarihleriFuture = _fetchSeraIsTarihleri();
  }

  // ---------------- HELPERS ----------------
  Future<List<dynamic>> _fetchSeraIsTarihleri() async {
    final result = await SeraIsTarihleriApi().isTarihleri(bolum:"3.SERA", isKodu: _iskkodu, hafta: hafta, deger: sondeger);
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
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Personel Anlık'),
                    Tab(text: 'Boşta Olanlar'),
                    Tab(text: 'Sera İş Tarihi'),
                  ],
                ),
                title: const Text("Agronet Seracılık A.Ş"),
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
              PersonelAnlikApi().personelAnlikDurum("3.SERA");
        });
      },
      child: FutureBuilder<List<PersonelAnlikDurum>>(
        future: _personelAnlikFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SpinKitDualRing(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final p = data[index];
              return Card(
                child: ListTile(
                  title: Text(p.personeladi),
                  subtitle: Text(p.personeltipi),
                  trailing: Text('${p.tunel} ${p.koridor}\n${p.yapilanis}'),
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
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data!;
          return GridView.builder(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
            itemCount: data.length,
            itemBuilder: (context, index) {
              return Card(
                color: Colors.brown.shade500.withOpacity(0.5),
                child: Center(
                  child: Text(
                    data[index].personeladi,
                    style: const TextStyle(color: Colors.white),
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
        _dropdown(),
        Expanded(child: _seraIsTarihleri()),
      ],
    );
  }

  Widget _dropdown() {
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.shade500, Colors.black],
        ),
      ),
      child: FutureBuilder<List<dynamic>>(
        future: _isListesiFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SpinKitCircle(color: Colors.white, size: 20);
          }

          final list = snapshot.data!;
          final exists = list.any((e) => e['kod'] == _iskkodu);
          if (!exists) {
            _iskkodu = list.first['kod'];
          }

          return DropdownButton<String>(
            value: _iskkodu,
            dropdownColor: Colors.brown.shade500,
            icon: const Icon(Icons.search, color: Colors.white),
            style: const TextStyle(color: Colors.white),
            items: list.map((e) {
              return DropdownMenuItem<String>(
                value: e['kod'],
                child: Text(e['isim']),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _iskkodu = val!;
                _seraIsTarihleriFuture = _fetchSeraIsTarihleri();
              });
            },
          );
        },
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
          if (!snapshot.hasData) {
            return const Center(
              child: SpinKitDualRing(color: Colors.white),
            );
          }

          _seraIsTarihleriList = snapshot.data!;

          return GroupedListView<dynamic, String>(
            elements: _seraIsTarihleriList,
            groupBy: (e) => e['Tünel'],
            groupSeparatorBuilder: (val) => Container(
              padding: const EdgeInsets.all(8),
              color: Colors.brown.shade500,
              child: Text(val,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            itemBuilder: (context, e) => Card(
              color: cardcolor(e['Durum']),
              child: ListTile(
                title: Text(e['Personel Adı']),
                subtitle: Text(e['Tarih']),
                trailing: Text(e['Koridor']),
              ),
            ),
          );
        },
      ),
    );
  }
}
