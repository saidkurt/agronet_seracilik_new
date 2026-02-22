import 'package:flutter/material.dart';
import 'package:agronet/comp/appbar.dart';

class PuanDetayiDun extends StatefulWidget {
  const PuanDetayiDun({Key? key}) : super(key: key);

  @override
  State<PuanDetayiDun> createState() => _PuanDetayiDunState();
}

class _PuanDetayiDunState extends State<PuanDetayiDun> {
  // API’den gelen listeyi böyle tanımla
  final List<Map<String, dynamic>> sonuc = [];

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBarCustomAppBar(context),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Bölüm Kodu")),
              DataColumn(label: Text("İş Adı")),
              DataColumn(label: Text("Tünel")),
              DataColumn(label: Text("Koridor")),
              DataColumn(label: Text("Aktif Süre")),
              DataColumn(label: Text("Son Durum")),
              DataColumn(label: Text("Performans Puanı")),
              DataColumn(label: Text("Net Kilo")),
            ],
            rows: sonuc.map((e) {
              return DataRow(
                cells: [
                  DataCell(Text((e["bolumkodu"] ?? "").toString())),
                  DataCell(Text((e["isadi"] ?? "").toString())),
                  DataCell(Text((e["tunel"] ?? "").toString())),
                  DataCell(Text((e["koridor"] ?? "").toString())),
                  DataCell(Text((e["aktifsure"] ?? "").toString())),
                  DataCell(Text((e["sondurum"] ?? "").toString())),
                  DataCell(Text(_toDouble(e["performanspuan"]).toInt().toString())),
                  DataCell(Text(_toDouble(e["netkg"]).toInt().toString())),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
