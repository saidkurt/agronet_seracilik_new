import 'package:agronet/api/bitenisler_api.dart';
import 'package:agronet/api/bosta_olanlar_api.dart';
import 'package:agronet/api/personelanlik_api.dart';
import 'package:agronet/api/seraistanimlari.dart';
import 'package:agronet/api/seraistarihleri_api.dart';

import 'package:agronet/models/bostaolanlar_model.dart';
import 'package:agronet/models/personelanlik_model.dart';
import 'package:agronet/models/sera_is_tarih_model.dart';
import 'package:agronet/models/seraistanimlari.dart';

import 'package:agronet/page/LoginPage/Resim.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:jiffy/jiffy.dart';

class Sera1AnaEkran extends StatefulWidget {
  final String? personelkodu;
  const Sera1AnaEkran({super.key, this.personelkodu});

  @override
  State<Sera1AnaEkran> createState() => _Sera1AnaEkranState();
}

class _Sera1AnaEkranState extends State<Sera1AnaEkran> {
  // ---------------- STATE ----------------
  String _iskkodu = "0030";

  bool _value = true;

  int hafta = Jiffy.now().weekOfYear;
  String sondeger = '1';

  final int _tabbarViewLenght = 3;

  // local listeler
   List<SeraIsTarihModel> _seraIsTarihleriList = [];

  // future cache
  late Future<List<PersonelAnlikDurum>> _personelAnlikFuture;
  late Future<List<BostaOlanlar>> _bostaOlanlarFuture;
  late Future<List<SeraIsTanimlari>> _isListesiFuture;
   late Future<List<SeraIsTarihModel>> _seraIsTarihleriFuture;

  @override
  void initState() {
    super.initState();

    _personelAnlikFuture =
        PersonelAnlikApi().personelAnlikDurum("1.SERA");

    _bostaOlanlarFuture = BostaOlanlarApi().personelBos();

    _isListesiFuture = SeraIsTanimlariApi().getSeraIsTanimlari();

    _seraIsTarihleriFuture = SeraIsTarihleriApi().isTarihleri(bolum: "1.SERA", isKodu: _iskkodu, hafta: hafta, deger: sondeger);
  }

  // ---------------- HELPERS ----------------
  Future<List<SeraIsTarihModel>> _fetchSeraIsTarihleri() async {
    final result = await SeraIsTarihleriApi().isTarihleri(bolum:"1.SERA", isKodu: _iskkodu, hafta: hafta, deger: sondeger);
    return result;
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
                bottom: TabBar(labelColor: Colors.white,
                  indicatorColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.6),
                  tabs: const [
                    Tab(text: 'Personel Anlık',),
                    Tab(text: 'Boşta Olanlar'),
                    Tab(text: 'Sera İş Tarihi'),
                  ],
                ),
                title: const Center(
                  child: Text(
                    "Agronet Seracılık A.Ş",
                    
                    style: TextStyle(fontSize: 14,color: Colors.white),
                    
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
              PersonelAnlikApi().personelAnlikDurum("1.SERA");
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
  clipBehavior: Clip.antiAlias,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: Colors.white.withOpacity(0.4), width: 1),
  ),
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      // LEADING: sabit genişlik + Column
      leading: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${p.sonbaslangicsaati}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${p.aktifsure}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),

      // TITLE/SUBTITLE: taşmayı engelle
      title: Text(
        p.personeladi,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
      subtitle: Text(
        p.personeltipi,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      // TRAILING: sabit genişlik + sağa hizalı + taşma kontrol
      trailing: SizedBox(
        width: 140,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${p.tunel} ${p.koridor}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${p.yapilanis}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),

    ),
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

            // ✅ Dropdown iş listesi (future’dan)
            DropdownButtonHideUnderline(
              child: FutureBuilder<List<SeraIsTanimlari>>(
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
                  final exists = list.any((e) => e.kod.toString() == _iskkodu);
                  if (!exists) {
                    _iskkodu = list.first.kod.toString();
                  } else {
                  }

                  return DropdownButton<String>(
                    icon: const Icon(Icons.search, color: Colors.white),
                    value: _iskkodu,
                    dropdownColor: Colors.brown.shade500,
                    style: const TextStyle(color: Colors.white),
                    items: list.map((item) {
                      return DropdownMenuItem<String>(
                        value: item.kod.toString(),
                        child: Text(item.isim.toString()),
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

          

          return GroupedListView<SeraIsTarihModel, String>(
            elements: _seraIsTarihleriList,
            groupBy: (element) => (element.tunel ?? 0).toString(),
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
                    InkWell(
                      onTap: () {
                        // eski kodun hatalıydı: listeyi id ile indexlemeye çalışıyordu
                        // burada sadece id'yi yazdırıyoruz:
                        debugPrint((element["İş Emri Id"] ?? '').toString());
                      },
                      child: Text(
                        (element['Personel Adı'] ?? '').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      (element['Tarih'] ?? '').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            itemComparator: (item1, item2) => (item1.koridor ?? '')
                .toString()
                .compareTo((item2.koridor ?? '').toString()),
            useStickyGroupSeparators: true,
            floatingHeader: true,
            order: GroupedListOrder.ASC,
          );
        },
      ),
    );
  }
}
