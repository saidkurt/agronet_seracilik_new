import 'package:agronet/api/depo_durum_api.dart';
import 'package:agronet/models/depo_durum_model.dart';
import 'package:agronet/widget/shimmer.dart';
import 'package:flutter/material.dart';

class DepodurumRaporu extends StatefulWidget {
  final String personeladi;

  const DepodurumRaporu({
    Key? key,
    required this.personeladi,
  }) : super(key: key);

  @override
  State<DepodurumRaporu> createState() => _DepodurumRaporuState();
}

class _DepodurumRaporuState extends State<DepodurumRaporu> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  final _api = DepoDurumApi();
  final _searchCtrl = TextEditingController();

  bool _loading = false;
  String _query = '';

  int _value = 2;

  List<DepoDurumModel> sonuc = [];

  // ============================================================
  // DEPOLAR
  // ============================================================

  static const List<Map<String, dynamic>> _depolar = [
    {
      'id': 2,
      'ad': 'Kırşehir Merkez Depo',
    },
    {
      'id': 3,
      'ad': '1.Sera Üretim Depo',
    },
    {
      'id': 4,
      'ad': '2.Sera Üretim Depo',
    },
    {
      'id': 5,
      'ad': '3.Sera Üretim Depo',
    },
    {
      'id': 6,
      'ad': '4.Sera Üretim Depo',
    },
    {
      'id': 10,
      'ad': 'Tesisat Sarf Deposu',
    },
    {
      'id': 11,
      'ad': 'Paketleme ve Sevkiyat Sarf Deposu',
    },
    {
      'id': 7,
      'ad': 'Fidelik Üretim Depo',
    },
    {
      'id': 8,
      'ad': '1-3 Gübre ve İlaç Deposu',
    },
    {
      'id': 9,
      'ad': '2-4 Gübre ve İlaç Deposu',
    },
  ];

  @override
  void initState() {
    super.initState();

    _searchCtrl.addListener(() {
      if (!mounted) return;

      setState(() {
        _query = _searchCtrl.text.trim().toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      depodurumraporu();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // FİLTRE
  // ============================================================

  List<DepoDurumModel> get _filtered {
    if (_query.isEmpty) {
      return sonuc;
    }

    return sonuc.where((x) {
      final kod = (x.stokKodu ?? '').toLowerCase();
      final ad = (x.stokAdi ?? '').toLowerCase();

      return kod.contains(_query) || ad.contains(_query);
    }).toList();
  }

  // ============================================================
  // API
  // ============================================================

  Future<void> depodurumraporu() async {
    if (_loading) return;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _loading = true;
    });

    try {
      final data = await _api.depoDurumGetir(_value);

      if (!mounted) return;

      setState(() {
        sonuc = data;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        sonuc = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _miktarStr(num? miktar) {
    if (miktar == null) return '-';

    final d = miktar.toDouble();

    return d % 1 == 0
        ? d.toInt().toString()
        : d.toStringAsFixed(2);
  }

  String _depoBaslik(int value) {
    for (final depo in _depolar) {
      if (depo['id'] == value) {
        return depo['ad'] as String;
      }
    }

    return 'Depo';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    final scaler = MediaQuery.textScalerOf(context).clamp(
      maxScaleFactor: 1.06,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: scaler,
      ),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          toolbarHeight: 48,
          title: const Text(
            'Depo Durum Raporu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: Colors.black87,
          actions: [
            IconButton(
              tooltip: 'Yenile',
              visualDensity: VisualDensity.compact,
              onPressed: _loading ? null : depodurumraporu,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 20,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildTopPanel(list.length),

            Expanded(
              child: _loading
                  ? _buildSkeletonList()
                  : list.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: accent,
                          onRefresh: depodurumraporu,
                          child: _buildList(list),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ÜST PANEL
  // ============================================================

  Widget _buildTopPanel(int count) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
      child: Column(
        children: [
          // PERSONEL + KAYIT
          Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: accent,
                  size: 16,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personel',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.black38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.personeladi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count kayıt',
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // DEPO SEÇ
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F9),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: Colors.black.withOpacity(.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warehouse_outlined,
                        size: 17,
                        color: accent,
                      ),

                      const SizedBox(width: 7),

                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _value,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 19,
                            ),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Colors.black87,
                              fontWeight: FontWeight.w800,
                            ),
                            items: _depolar.map((depo) {
                              return DropdownMenuItem<int>(
                                value: depo['id'] as int,
                                child: Text(
                                  depo['ad'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: _loading
                                ? null
                                : (v) {
                                    if (v == null) return;

                                    setState(() {
                                      _value = v;
                                    });
                                  },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: _loading ? null : depodurumraporu,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'GETİR',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ARAMA
          SizedBox(
            height: 42,
            child: TextField(
              controller: _searchCtrl,
              enabled: !_loading,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Stok kodu veya stok adı ara...',
                hintStyle: const TextStyle(
                  fontSize: 10,
                  color: Colors.black38,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 38,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: _searchCtrl.clear,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 17,
                        ),
                      ),
                filled: true,
                fillColor: const Color(0xFFF7F7F9),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(
                    color: Colors.black.withOpacity(.05),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(
                    color: Colors.black.withOpacity(.05),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(
                    color: accent,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // SEÇİLİ DEPO
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: accent,
              ),

              const SizedBox(width: 4),

              Expanded(
                child: Text(
                  _depoBaslik(_value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (_query.isNotEmpty)
                Text(
                  '${sonuc.length} stoktan $count sonuç',
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STOK LİSTESİ
  // ============================================================

  Widget _buildList(List<DepoDurumModel> list) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 14),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 5),
      itemBuilder: (context, i) {
        final x = list[i];

        final kod = (x.stokKodu ?? '').trim();
        final ad = (x.stokAdi ?? '').trim();
        final birim = (x.birim ?? '').trim();
        final miktar = _miktarStr(x.miktar);

        return _StokCard(
          kod: kod,
          ad: ad,
          birim: birim,
          miktar: miktar,
        );
      },
    );
  }

  // ============================================================
  // BOŞ
  // ============================================================

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 100),
        Icon(
          Icons.inventory_2_outlined,
          size: 46,
          color: Colors.black26,
        ),
        SizedBox(height: 8),
        Text(
          'Kayıt bulunamadı',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Seçili depoda gösterilecek stok bulunmuyor.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            color: Colors.black38,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SKELETON
  // ============================================================

  Widget _buildSkeletonList() {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 14),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 5),
        itemBuilder: (_, __) => const _SkeletonStokCard(),
      ),
    );
  }
}

// ============================================================================
// STOK KARTI
// ============================================================================

class _StokCard extends StatelessWidget {
  const _StokCard({
    required this.kod,
    required this.ad,
    required this.birim,
    required this.miktar,
  });

  final String kod;
  final String ad;
  final String birim;
  final String miktar;

  static const Color accent = Color(0xFF1E6F5C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.black.withOpacity(.05),
        ),
      ),
      child: Row(
        children: [
          // SOL ÇİZGİ
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(width: 7),

          // İKON
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withOpacity(.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: accent,
              size: 18,
            ),
          ),

          const SizedBox(width: 8),

          // STOK BİLGİSİ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.isEmpty ? '-' : ad,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        kod.isEmpty ? '-' : kod,
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    if (birim.isNotEmpty)
                      Text(
                        birim,
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: Colors.black38,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),

          // MİKTAR
          Container(
            constraints: const BoxConstraints(
              minWidth: 58,
              maxWidth: 90,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: accent.withOpacity(.08),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: accent.withOpacity(.12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MİKTAR',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.black38,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 1),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    miktar,
                    style: const TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                if (birim.isNotEmpty)
                  Text(
                    birim,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 7.5,
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SKELETON
// ============================================================================

class _SkeletonStokCard extends StatelessWidget {
  const _SkeletonStokCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.black.withOpacity(.04),
        ),
      ),
      child: Row(
        children: [
          _bar(34, 34),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(170, 10),
                const SizedBox(height: 7),
                _bar(90, 8),
              ],
            ),
          ),

          const SizedBox(width: 8),

          _bar(62, 38),
        ],
      ),
    );
  }

  static Widget _bar(
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.06),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}