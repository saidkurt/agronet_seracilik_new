import 'package:agronet/api/barkod_kontrol_api.dart';
import 'package:agronet/models/barkod_kontrol_model.dart';
import 'package:agronet/widget/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✅ Sende zaten var:
// import 'package:agronet/api/koli_barkod_api.dart';
// import 'package:agronet/models/koli_barkod_model.dart';

class KoliBarkodPage extends StatefulWidget {
  const KoliBarkodPage({super.key});

  @override
  State<KoliBarkodPage> createState() => _KoliBarkodPageState();
}

class _KoliBarkodPageState extends State<KoliBarkodPage> {
  static const accent = Color(0xFF1E6F5C);

  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<KoliBarkodModel> _items = const [];

  final _fmt = DateFormat("dd.MM.yyyy  HH:mm");

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _ara() async {
    final barkod = _ctrl.text.trim();
    if (barkod.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _items = const [];
    });

    try {
      final list = await KoliBarkodApi.getir(barkod);
      setState(() => _items = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Koli Barkod Sorgu"),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          children: [
            _SearchCard(
              controller: _ctrl,
              onSearch: _ara,
            ),
            const SizedBox(height: 12),
            _SectionHeader(
              title: "Son Kayıtlar",
              subtitle: _loading
                  ? "Yükleniyor…"
                  : (_items.isEmpty ? "0 kayıt" : "${_items.length} kayıt"),
            ),
            const SizedBox(height: 10),

            if (_loading) ...List.generate(5, (_) => const _ShimmerSkeletonCard()),

            if (!_loading && _error != null)
              _ErrorCard(message: _error!),

            if (!_loading && _error == null && _items.isEmpty)
              const _EmptyCard(),

            if (!_loading && _error == null && _items.isNotEmpty)
              ..._items.map((e) => _ResultCard(
                    dt: e.tartimZamani == null ? "-" : _fmt.format(e.tartimZamani!),
                    personel: (e.personel ?? "-").trim().isEmpty ? "-" : e.personel!,
                    bolum: (e.bolum ?? "-").trim().isEmpty ? "-" : e.bolum!,
                    tunel: (e.tunel ?? "-").trim().isEmpty ? "-" : e.tunel!,
                  )),
          ],
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  static const accent = Color(0xFF1E6F5C);

  const _SearchCard({
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Barkod",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: "Örn: AG04852",
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.qr_code_2, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text("Ara"),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.black.withOpacity(.55),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String dt;
  final String personel;
  final String bolum;
  final String tunel;

  static const accent = Color(0xFF1E6F5C);

  const _ResultCard({
    required this.dt,
    required this.personel,
    required this.bolum,
    required this.tunel,
  });

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withOpacity(.06)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.inventory_2_outlined, color: accent.withOpacity(.95)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dt,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  personel,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(.75),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip("Bölüm: $bolum"),
                    _chip("Tünel: $tunel"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.info_outline, color: Colors.black.withOpacity(.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Kayıt bulunamadı.\nBarkodu kontrol edip tekrar deneyin.",
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: Colors.black.withOpacity(.7),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.error_outline, color: Colors.red.withOpacity(.85)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Hata oluştu:\n$message",
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: Colors.black.withOpacity(.75),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ Shimmer Skeleton Card
/// Buradaki ShimmerLoading sınıfı = senin projedeki shimmer class.
/// Eğer adı farklıysa sadece bu widget içindeki 1 satırı kendi classınla değiştir.
class _ShimmerSkeletonCard extends StatelessWidget {
  const _ShimmerSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.06),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(w: 160, h: 12),
                const SizedBox(height: 10),
                _bar(w: 220, h: 12),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _bar(w: 90, h: 26, r: 999),
                    const SizedBox(width: 8),
                    _bar(w: 90, h: 26, r: 999),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // ✅ SENİN SHIMMER CLASS'IN BURAYA
    // Örn: ShimmerLoading(child: card)
    return Shimmer(child: card);
  }

  static Widget _bar({double w = 140, double h = 12, double r = 8}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          color: Colors.black.withOpacity(0.06),
        ),
      );
}
