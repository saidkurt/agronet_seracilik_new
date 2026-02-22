import 'package:flutter/material.dart';
import 'package:agronet/api/personelbilgileri_api.dart';
import 'package:agronet/comp/appbar.dart';

class PersonelBilgileri extends StatefulWidget {
  final String personelId;

  const PersonelBilgileri({
    Key? key,
    required this.personelId,
  }) : super(key: key);

  @override
  State<PersonelBilgileri> createState() => _PersonelBilgileriState();
}

class _PersonelBilgileriState extends State<PersonelBilgileri> {
  late Future<List<Map<String, dynamic>>> _futurePersonel;

  @override
  void initState() {
    super.initState();
    _futurePersonel =
        PersonelBilgileriApi().personelBilgileri(personelId: widget.personelId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBarCustomAppBar(context),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futurePersonel,
        builder: (context, snapshot) {
          /// ⏳ YÜKLENİYOR
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          /// ❌ HATA
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hata oluştu:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          /// 📭 BOŞ
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Personel bilgisi bulunamadı'),
            );
          }

          /// ✅ VERİ VAR
          final personeller = snapshot.data!;

          return ListView.builder(
            itemCount: personeller.length,
            itemBuilder: (context, index) {
              final p = personeller[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (p['kullanicikodu'] ?? '').toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  title: Text(
                    (p['isimsoyisim'] ?? '').toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Şifre: ${p['sifre'] ?? ''}',
                  ),
                  trailing: Text(
                    (p['tip'] ?? '').toString(),
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
