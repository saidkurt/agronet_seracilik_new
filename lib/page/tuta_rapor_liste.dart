import 'package:agronet/api/tuta_rapor_api.dart';
import 'package:agronet/models/tuta_liste_rapor_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class TutaListeRaporPage extends StatefulWidget {
  final String sera;

  const TutaListeRaporPage({
    super.key,
    required this.sera,
  });

  @override
  State<TutaListeRaporPage> createState() => _TutaListeRaporPageState();
}

class _TutaListeRaporPageState extends State<TutaListeRaporPage> {
  final TutaApi _api = TutaApi();

  late DateTime _ilkTarih;
  late DateTime _sonTarih;

  bool _isLoading = false;
  String? _error;

  TutaListeRaporResponse? _data;
  TutaListeRowModel? _selectedRow;

  final DateFormat _dateFmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _sonTarih = DateTime.now();
    _ilkTarih = _sonTarih.subtract(const Duration(days: 14));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _api.getListeRapor(
        sera: widget.sera,
        ilkTarih: _ilkTarih,
        sonTarih: _sonTarih,
      );

      setState(() {
        _data = result;
        _selectedRow = result.rapor.isNotEmpty ? result.rapor.first : null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickIlkTarih() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _ilkTarih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('tr'),
    );

    if (picked != null) {
      setState(() {
        _ilkTarih = picked;
        if (_ilkTarih.isAfter(_sonTarih)) {
          _sonTarih = _ilkTarih;
        }
      });
    }
  }

  Future<void> _pickSonTarih() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sonTarih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('tr'),
    );

    if (picked != null) {
      setState(() {
        _sonTarih = picked;
        if (_sonTarih.isBefore(_ilkTarih)) {
          _ilkTarih = _sonTarih;
        }
      });
    }
  }

  TutaIsimlerModel? get _isimler {
    if (_data == null || _data!.isimler.isEmpty) return null;
    return _data!.isimler.first;
  }

  List<_DegerItem> _buildVisibleDegerler(TutaListeRowModel row) {
    final isimler = _isimler;
    if (isimler == null) return [];

    final result = <_DegerItem>[];

    for (int i = 1; i <= 16; i++) {
      final isim = isimler.getIsimByIndex(i).trim();
      if (isim.isEmpty) continue;

      result.add(
        _DegerItem(
          index: i,
          isim: isim,
          deger: row.getDegerByIndex(i),
        ),
      );
    }

    return result;
  }

  int _extractDegerIndexFromCaption(String caption) {
    final match = RegExp(r'(\d+)$').firstMatch(caption);
    if (match == null) return 0;
    return int.tryParse(match.group(1) ?? '') ?? 0;
    }

  int _getTunelValue(TutaTunelModel tunel, TutaListeRowModel row) {
    final isimler = _isimler;
    if (isimler == null) return 0;

    final targetCaption = tunel.tunel.trim().toUpperCase();

    for (int i = 1; i <= 16; i++) {
      final isim = isimler.getIsimByIndex(i).trim().toUpperCase();
      if (isim == targetCaption) {
        return row.getDegerByIndex(i);
      }
    }

    final fallbackIndex = _extractDegerIndexFromCaption(tunel.tunel);
    if (fallbackIndex >= 1 && fallbackIndex <= 16) {
      return row.getDegerByIndex(fallbackIndex);
    }

    return 0;
  }


  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF4F7F6);
    const cardColor = Colors.white;
    const primaryColor = Color(0xFF1F7A63);
    const softGreen = Color(0xFFE8F3EF);
    const textColor = Color(0xFF24323D);
    const subTextColor = Color(0xFF7B8794);
    const borderColor = Color(0xFFE5E9EF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        foregroundColor: textColor,
         centerTitle: true,
        title: Text(
          widget.sera,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ),
    body: RefreshIndicator(
  onRefresh: _load,
  child: CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtreler',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'İlk Tarih',
                            value: _dateFmt.format(_ilkTarih),
                            onTap: _pickIlkTarih,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'Son Tarih',
                            value: _dateFmt.format(_sonTarih),
                            onTap: _pickSonTarih,
                          ),
                        ),
                      ],
                    ),
                 
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _load,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.assessment_outlined),
                        label: Text(_isLoading ? 'Yükleniyor...' : 'Rapor Al'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),

      if (_error == null && !(_isLoading && _data == null))
       SliverPersistentHeader(
  pinned: true,
  delegate: _PinnedHeaderDelegate(
    minHeight: 250,
    maxHeight: 300,
    child: _buildSummaryCard(
      cardColor: cardColor,
      primaryColor: primaryColor,
      softGreen: softGreen,
      textColor: textColor,
      subTextColor: subTextColor,
    ),
  ),
),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            children: [
              if (_error != null)
                _SectionCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isLoading && _data == null) ...[
                const _SkeletonCard(height: 88),
                const SizedBox(height: 12),
                const _SkeletonCard(height: 110),
                const SizedBox(height: 12),
                const _SkeletonCard(height: 260),
              ] else if ((_data?.rapor.isEmpty ?? true) && _error == null) ...[
                _SectionCard(
                  child: Column(
                    children: const [
                      Icon(
                        Icons.inbox_outlined,
                        size: 42,
                        color: subTextColor,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Bu tarih aralığında kayıt bulunamadı.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_error == null) ...[
                _buildListSection(
                  primaryColor: primaryColor,
                  softGreen: softGreen,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                ),
               
              ],
            ],
          ),
        ),
      ),
    ],
  ),
),
    );
  }

  Widget _buildSummaryCard({
    required Color cardColor,
    required Color primaryColor,
    required Color softGreen,
    required Color textColor,
    required Color subTextColor,
  }) {
    final selectedDate = _selectedRow?.tarih != null
        ? _dateFmt.format(_selectedRow!.tarih!)
        : '-';
    final selectedToplam = _selectedRow?.toplam ?? 0;

   final toplam = _data?.rapor.fold<int>(
  0,
  (sum, item) => sum + item.toplam,
) ?? 0;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Özet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryBox(
                  title: 'Toplam Tuta',
                  value: '$toplam',
                  icon: Icons.list_alt_outlined,
                  bg: softGreen,
                  iconColor: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryBox(
                  title: 'Seçili Gün',
                  value: selectedDate,
                  icon: Icons.calendar_today_outlined,
                  bg: const Color(0xFFF7F3E9),
                  iconColor: const Color(0xFFB78103),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E9EF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: softGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.insights_outlined,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seçili Gün Tuta',
                        style: TextStyle(
                          fontSize: 13,
                          color: subTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$selectedToplam',
                        style: TextStyle(
                          fontSize: 22,
                          color: textColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection({
    required Color primaryColor,
    required Color softGreen,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    final rapor = _data?.rapor ?? [];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Günlük Liste',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          ...rapor.map((row) {
            final isSelected = _selectedRow == row;
            final degerler = _buildVisibleDegerler(row);

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() {
                  _selectedRow = row;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? softGreen : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? primaryColor : borderColor,
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.tarih != null
                                ? _dateFmt.format(row.tarih!)
                                : '-',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected ? primaryColor : borderColor,
                            ),
                          ),
                          child: Text(
                            row.sera,
                            style: TextStyle(
                              color: isSelected ? primaryColor : subTextColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (row.ilac.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF1E2AA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.medication_outlined,
                                size: 18,
                                color: Color(0xFFB78103),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                row.ilac,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (degerler.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: degerler.map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Text(
                              '${item.isim}: ${item.deger}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTunelSection({
    required String title,
    required List<TutaTunelModel> tuneller,
    required Color primaryColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required Color softGreen,
  }) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedRow == null)
            Text(
              'Görüntülenecek kayıt yok.',
              style: TextStyle(
                color: subTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
          else if (tuneller.isEmpty)
            Text(
              'Tünel bilgisi bulunamadı.',
              style: TextStyle(
                color: subTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: tuneller.map((tunel) {
                final value = _getTunelValue(tunel, _selectedRow!);
                return Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        tunel.kod,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: value > 0 ? softGreen : const Color(0xFFF6F7F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$value',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: value > 0 ? primaryColor : subTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF24323D);
    const subTextColor = Color(0xFF7B8794);
    const borderColor = Color(0xFFE5E9EF);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: subTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: subTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color bg;
  final Color iconColor;

  const _SummaryBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.bg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF24323D);
    const subTextColor = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: subTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    color: textColor,
                    fontWeight: FontWeight.w800,
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

class _MiniInfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniInfoBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF24323D);
    const subTextColor = Color(0xFF7B8794);
    const borderColor = Color(0xFFE5E9EF);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: subTextColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: subTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: textColor,
                    fontWeight: FontWeight.w800,
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

class _SkeletonCard extends StatelessWidget {
  final double height;

  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F5),
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

class _DegerItem {
  final int index;
  final String isim;
  final int deger;

  _DegerItem({
    required this.index,
    required this.isim,
    required this.deger,
  });
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _PinnedHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF4F7F6),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}

