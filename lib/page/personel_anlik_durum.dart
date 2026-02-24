import 'package:agronet/widget/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:agronet/api/personelanlik_api.dart';
import 'package:agronet/models/personelanlik_model.dart';

class PersonelAnlikDurumPage extends StatefulWidget {
  const PersonelAnlikDurumPage({super.key});

  @override
  State<PersonelAnlikDurumPage> createState() => _PersonelAnlikDurumPageState();
}

class _PersonelAnlikDurumPageState extends State<PersonelAnlikDurumPage> {
  bool _loading = false;
  String? _error;

  final _api = PersonelAnlikApi();
  List<PersonelAnlikDurum> _data = [];

  // ✅ Açılışta otomatik 1.SERA
  final List<String> _seraList = const ["1.SERA", "2.SERA", "3.SERA", "4.SERA", "5.SERA"];
  String _selectedSera = "1.SERA";

  @override
  void initState() {
    super.initState();
    // ilk frame sonrası fetch (daha akıcı)
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.personelAnlikDurum(_selectedSera);
      if (!mounted) return;
      setState(() => _data = res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSeraChanged(String? v) {
    if (v == null) return;
    if (v == _selectedSera) return;
    setState(() {
      _selectedSera = v;
      _data = [];
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text("Personel Anlık Durum"),
        centerTitle: true,
      ),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
          children: [
            _SeraDropdownCard(
              seraList: _seraList,
              selected: _selectedSera,
              onChanged: _onSeraChanged,
              onRefresh: _fetch,
            ),
            const SizedBox(height: 12),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _loading
                  ? _buildSkeleton()
                  : _error != null
                      ? _buildError()
                      : _buildList(),
            ),
          ],
        ),
      
    );
  }

  Widget _buildSkeleton() {
    return Column(
      key: const ValueKey("skeleton"),
      children: List.generate(7, (i) => const _SkeletonCard()),
    );
  }

  Widget _buildError() {
    return Container(
      key: const ValueKey("error"),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, size: 34, color: Colors.red.shade400),
          const SizedBox(height: 10),
          Text(
            "Hata oluştu",
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black.withOpacity(.85)),
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? "-",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black.withOpacity(.55)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh),
              label: const Text("Tekrar dene"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_data.isEmpty) {
      return Container(
        key: const ValueKey("empty"),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(.06)),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 36, color: Colors.black.withOpacity(.35)),
            const SizedBox(height: 10),
            Text(
              "Kayıt yok",
              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black.withOpacity(.75)),
            ),
            const SizedBox(height: 4),
            Text(
              "Seçili serada personel bulunamadı.",
              style: TextStyle(color: Colors.black.withOpacity(.50)),
            ),
          ],
        ),
      );
    }

    // stabil sıralama: tünel/koridor/isim
    final list = [..._data]..sort((a, b) {
        final k1 = "${a.tunel}|${a.koridor}|${a.personeladi}".toLowerCase();
        final k2 = "${b.tunel}|${b.koridor}|${b.personeladi}".toLowerCase();
        return k1.compareTo(k2);
      });

    return Column(
      key: const ValueKey("list"),
      children: [
        const SizedBox(height: 10),
        ...list.map((e) => _PersonelCard(item: e)).toList(),
      ],
    );
  }
}

class _SeraDropdownCard extends StatelessWidget {
  final List<String> seraList;
  final String selected;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRefresh;

  const _SeraDropdownCard({
    required this.seraList,
    required this.selected,
    required this.onChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E6F5C).withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.spa_outlined, color: const Color(0xFF1E6F5C).withOpacity(.9)),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: DropdownButtonFormField<String>(
              value: selected,
              items: seraList
                  .map((s) => DropdownMenuItem<String>(
                        value: s,
                        child: Text(s),
                      ))
                  .toList(),
              onChanged: onChanged,
              decoration: InputDecoration(
                labelText: "Sera Seç",
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF7F7F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.black.withOpacity(.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.black.withOpacity(.08)),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),
          IconButton(
            onPressed: onRefresh,
            tooltip: "Yenile",
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
    );
  }
}

class _PersonelCard extends StatelessWidget {
  final PersonelAnlikDurum item;
  const _PersonelCard({required this.item});

  static const accent = Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    final title = _nz(item.personeladi);
    final type = item.personeltipi.trim();
    final place = "${_nz(item.tunel)} • ${_nz(item.koridor)}";
    final job = item.yapilanis.trim();
    final start = item.sonbaslangicsaati.trim();
    final active = item.aktifsure.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.person_outline_rounded, color: accent.withOpacity(.9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.black.withOpacity(.86),
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    if (type.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: accent.withOpacity(.18)),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            color: accent.withOpacity(.95),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                Text(
                  place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black.withOpacity(.55),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),

                if (job.isNotEmpty)
                  Text(
                    job,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black.withOpacity(.75),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        start.isEmpty ? "" : "Başlangıç: $start",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black.withOpacity(.50),
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    if (active.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.06),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          active,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                            color: Colors.black.withOpacity(.70),
                          ),
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

  String _nz(String s) {
    final t = s.trim();
    return t.isEmpty ? "-" : t;
  }
}

// ------------------ Skeleton ------------------

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    Widget bar({double w = 160, double h = 12}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withOpacity(0.06),
          ),
        );

    return Shimmer(
      child: Container(
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
                  Row(
                    children: [
                      bar(w: 170, h: 12),
                      const Spacer(),
                      Container(
                        width: 64,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.06),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  bar(w: 220, h: 12),
                  const SizedBox(height: 8),
                  bar(w: 180, h: 12),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      bar(w: 140, h: 12),
                      const Spacer(),
                      Container(
                        width: 64,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.06),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}