
import 'package:agronet/api/tuta_rapor_api.dart';
import 'package:agronet/models/tuta_rapor_model.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TutaRaporPage extends StatefulWidget {
  const TutaRaporPage({super.key});

  @override
  State<TutaRaporPage> createState() => _TutaRaporPageState();
}

class _TutaRaporPageState extends State<TutaRaporPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color accentSoft = Color(0xFFE8F3F0);
  static const Color bg = Color(0xFFF5F7F8);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1F2937);

  final TutaApi _api = TutaApi();

  DateTime _ilkTarih = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _sonTarih = DateTime.now();

  final Set<int> _selectedTutalar = {
    1, 2, 3, 4, 5, 6, 7, 8,
    9, 10, 11, 12, 13, 14, 15, 16,
  };

  bool _isLoading = false;
  String? _error;

  TutaIsimlerModel _isimler1 = const TutaIsimlerModel();
  TutaIsimlerModel _isimler2 = const TutaIsimlerModel();
  TutaIsimlerModel _isimler3 = const TutaIsimlerModel();
  TutaIsimlerModel _isimler4 = const TutaIsimlerModel();
   TutaIsimlerModel _isimler5 = const TutaIsimlerModel();

  List<TutaRaporModel> _rapor1 = [];
  List<TutaRaporModel> _rapor2 = [];
  List<TutaRaporModel> _rapor3 = [];
  List<TutaRaporModel> _rapor4 = [];
    List<TutaRaporModel> _rapor5 = [];

  List<TutaToplamModel> _toplamlar = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.isimleriGetir(sera: '1.SERA'),
        _api.isimleriGetir(sera: '2.SERA'),
        _api.isimleriGetir(sera: '3.SERA'),
        _api.isimleriGetir(sera: '4.SERA'),
        _api.isimleriGetir(sera: '5.SERA'),
        _api.raporGetir(
          sera: '1.SERA',
          ilkTarih: _ilkTarih,
          sonTarih: _sonTarih,
        ),
        _api.raporGetir(
          sera: '2.SERA',
          ilkTarih: _ilkTarih,
          sonTarih: _sonTarih,
        ),
        _api.raporGetir(
          sera: '3.SERA',
          ilkTarih: _ilkTarih,
          sonTarih: _sonTarih,
        ),
        _api.raporGetir(
          sera: '4.SERA',
          ilkTarih: _ilkTarih,
          sonTarih: _sonTarih,
        ),
           _api.raporGetir(
          sera: '5.SERA',
          ilkTarih: _ilkTarih,
          sonTarih: _sonTarih,
        ),
        _api.toplamGetir(
          ilkTarih: _ilkTarih,
          sonTarih: _sonTarih,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _isimler1 = results[0] as TutaIsimlerModel;
        _isimler2 = results[1] as TutaIsimlerModel;
        _isimler3 = results[2] as TutaIsimlerModel;
        _isimler4 = results[3] as TutaIsimlerModel;
        _isimler5 = results[4] as TutaIsimlerModel;

        _rapor1 = _siralaByTarih(results[5] as List<TutaRaporModel>);
        _rapor2 = _siralaByTarih(results[6] as List<TutaRaporModel>);
        _rapor3 = _siralaByTarih(results[7] as List<TutaRaporModel>);
        _rapor4 = _siralaByTarih(results[8] as List<TutaRaporModel>);
        _rapor5 = _siralaByTarih(results[9] as List<TutaRaporModel>);

        _toplamlar = _siralaToplam(results[10] as List<TutaToplamModel>);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Tuta raporu alınamadı.\n$e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<TutaRaporModel> _siralaByTarih(List<TutaRaporModel> list) {
    final newList = [...list];
    newList.sort((a, b) {
      final aTarih = a.tarih ?? DateTime(2000);
      final bTarih = b.tarih ?? DateTime(2000);
      return aTarih.compareTo(bTarih);
    });
    return newList;
  }

  List<TutaToplamModel> _siralaToplam(List<TutaToplamModel> list) {
    final newList = [...list];
    newList.sort((a, b) {
      final seraCompare = a.sera.compareTo(b.sera);
      if (seraCompare != 0) return seraCompare;
      final aTarih = a.tarih ?? DateTime(2000);
      final bTarih = b.tarih ?? DateTime(2000);
      return aTarih.compareTo(bTarih);
    });
    return newList;
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _ilkTarih : _sonTarih;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('tr'),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _ilkTarih = picked;
        if (_sonTarih.isBefore(_ilkTarih)) {
          _sonTarih = picked;
        }
      } else {
        _sonTarih = picked;
        if (_sonTarih.isBefore(_ilkTarih)) {
          _ilkTarih = picked;
        }
      }
    });
  }

  String _fmt(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        title: const Text(
          'Tuta Sayım Raporu',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: accent,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          children: [
            _buildFilterCard(),
            const SizedBox(height: 12),
            if (_isLoading) ...[
              const _SkeletonCard(height: 260),
              const SizedBox(height: 12),
              const _SkeletonCard(height: 260),
              const SizedBox(height: 12),
              const _SkeletonCard(height: 260),
              const SizedBox(height: 12),
              const _SkeletonCard(height: 260),
              const SizedBox(height: 12),
              const _SkeletonCard(height: 280),
            ] else if (_error != null) ...[
              _ErrorCard(
                message: _error!,
                onRetry: _load,
              ),
            ] else ...[
              _SeraChartCard(
                title: 'Sera 1',
                subtitle: '1.SERA',
                isimler: _isimler1,
                veriler: _rapor1,
                selectedTutalar: _selectedTutalar.toList()..sort(),
              ),
              const SizedBox(height: 12),
              _SeraChartCard(
                title: 'Sera 2',
                subtitle: '2.SERA',
                isimler: _isimler2,
                veriler: _rapor2,
                selectedTutalar: _selectedTutalar.toList()..sort(),
              ),
              const SizedBox(height: 12),
              _SeraChartCard(
                title: 'Sera 3',
                subtitle: '3.SERA',
                isimler: _isimler3,
                veriler: _rapor3,
                selectedTutalar: _selectedTutalar.toList()..sort(),
              ),
              const SizedBox(height: 12),
              _SeraChartCard(
                title: 'Sera 4',
                subtitle: '4.SERA',
                isimler: _isimler4,
                veriler: _rapor4,
                selectedTutalar: _selectedTutalar.toList()..sort(),
              ),
                  _SeraChartCard(
                title: 'Sera 5',
                subtitle: '5.SERA',
                isimler: _isimler5,
                veriler: _rapor5,
                selectedTutalar: _selectedTutalar.toList()..sort(),
              ),
              const SizedBox(height: 12),
              _ToplamChartCard(
                toplamlar: _toplamlar,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DateSelectBox(
                  label: 'İlk Tarih',
                  value: _fmt(_ilkTarih),
                  onTap: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateSelectBox(
                  label: 'Son Tarih',
                  value: _fmt(_sonTarih),
                  onTap: () => _pickDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Gösterilecek Tutalar',
              style: TextStyle(
                color: textDark.withValues(alpha: .85),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(16, (index) {
              final no = index + 1;
              final selected = _selectedTutalar.contains(no);

              return InkWell(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedTutalar.remove(no);
                    } else {
                      _selectedTutalar.add(no);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? accent : const Color(0xFFF2F4F5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? accent : const Color(0xFFE3E7EA),
                    ),
                  ),
                  child: Text(
                    '$no',
                    style: TextStyle(
                      color: selected ? Colors.white : textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.analytics_outlined, color: Colors.white),
              label: const Text(
                'Rapor Al',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelectBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateSelectBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8EC)),
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
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_month_rounded,
              size: 20,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeraChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final TutaIsimlerModel isimler;
  final List<TutaRaporModel> veriler;
  final List<int> selectedTutalar;

  const _SeraChartCard({
    required this.title,
    required this.subtitle,
    required this.isimler,
    required this.veriler,
    required this.selectedTutalar,
  });

  static const List<Color> _lineColors = [
    Color(0xFF1E6F5C),
    Color(0xFF2C8C99),
    Color(0xFF4F46E5),
    Color(0xFF9333EA),
    Color(0xFFEA580C),
    Color(0xFFDC2626),
    Color(0xFF059669),
    Color(0xFF0891B2),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF65A30D),
    Color(0xFFD97706),
    Color(0xFF0F766E),
    Color(0xFF2563EB),
    Color(0xFFBE123C),
    Color(0xFF475569),
  ];

  @override
  Widget build(BuildContext context) {
    final lines = <LineChartBarData>[];

    for (final tutaNo in selectedTutalar) {
      final spots = <FlSpot>[];

      for (int i = 0; i < veriler.length; i++) {
        spots.add(
          FlSpot(
            i.toDouble(),
            veriler[i].degerGetir(tutaNo).toDouble(),
          ),
        );
      }

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: _lineColors[(tutaNo - 1) % _lineColors.length],
          barWidth: 2.2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.eco_outlined,
                color: Color(0xFF1E6F5C),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3F0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF1E6F5C),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (veriler.isEmpty)
            const SizedBox(
              height: 230,
              child: Center(
                child: Text(
                  'Bu tarih aralığında veri yok',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1F2937),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final int lineIndex = spot.barIndex;
                          final int tutaNo = selectedTutalar[lineIndex];
                          final title = isimler.isimGetir(tutaNo).trim().isEmpty
                              ? 'Tuta $tutaNo'
                              : isimler.isimGetir(tutaNo);
                          return LineTooltipItem(
                            '$title\n${spot.y.toStringAsFixed(0)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFE5E7EB),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (_) => const FlLine(
                      color: Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _bottomInterval(veriler.length),
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= veriler.length) {
                            return const SizedBox();
                          }
                          final dt = veriler[i].tarih;
                          if (dt == null) return const SizedBox();

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd.MM').format(dt),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: lines,
                ),
              ),
            ),
          const SizedBox(height: 12),
          _LegendWrap(
            items: selectedTutalar.map((tutaNo) {
              final isim = isimler.isimGetir(tutaNo).trim();
              final label = isim.isEmpty ? 'Tuta $tutaNo' : isim;
              return _LegendItemData(
                text: '$tutaNo - $label',
                color: _lineColors[(tutaNo - 1) % _lineColors.length],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  double? _bottomInterval(int len) {
    if (len <= 7) return 1;
    if (len <= 15) return 2;
    if (len <= 31) return 4;
    return 7;
  }
}

class _ToplamChartCard extends StatelessWidget {
  final List<TutaToplamModel> toplamlar;

  const _ToplamChartCard({
    required this.toplamlar,
  });

  static const List<Color> _seraColors = [
    Color(0xFF1E6F5C),
    Color(0xFF2563EB),
    Color(0xFFEA580C),
    Color(0xFF9333EA),
    Color(0xFF12ABEA),
  ];

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<TutaToplamModel>>{};
    for (final item in toplamlar) {
      grouped.putIfAbsent(item.sera, () => []).add(item);
    }

    final seraOrder = ['1.SERA', '2.SERA', '3.SERA', '4.SERA', '5.SERA'];

    final bars = <LineChartBarData>[];
    for (int s = 0; s < seraOrder.length; s++) {
      final key = seraOrder[s];
      final list = grouped[key] ?? [];

      bars.add(
        LineChartBarData(
          spots: List.generate(
            list.length,
            (i) => FlSpot(i.toDouble(), list[i].toplam.toDouble()),
          ),
          isCurved: false,
          color: _seraColors[s % _seraColors.length],
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      );
    }

    final firstList = grouped['1.SERA'] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                color: Color(0xFF1E6F5C),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Toplam Tuta',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (toplamlar.isEmpty)
            const SizedBox(
              height: 250,
              child: Center(
                child: Text(
                  'Toplam veri yok',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFE5E7EB),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (_) => const FlLine(
                      color: Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1F2937),
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final seraName = seraOrder[spot.barIndex];
                          return LineTooltipItem(
                            '$seraName\n${spot.y.toStringAsFixed(0)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 34,
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _bottomInterval(firstList.length),
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= firstList.length) {
                            return const SizedBox();
                          }
                          final dt = firstList[i].tarih;
                          if (dt == null) return const SizedBox();

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd.MM').format(dt),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: bars,
                ),
              ),
            ),
          const SizedBox(height: 12),
          _LegendWrap(
            items: [
              _LegendItemData(text: '1.SERA', color: _seraColors[0]),
              _LegendItemData(text: '2.SERA', color: _seraColors[1]),
              _LegendItemData(text: '3.SERA', color: _seraColors[2]),
              _LegendItemData(text: '4.SERA', color: _seraColors[3]),
              _LegendItemData(text: '5.SERA', color: _seraColors[4]),
            ],
          ),
        ],
      ),
    );
  }

  double? _bottomInterval(int len) {
    if (len <= 7) return 1;
    if (len <= 15) return 2;
    if (len <= 31) return 4;
    return 7;
  }
}

class _LegendItemData {
  final String text;
  final Color color;

  _LegendItemData({
    required this.text,
    required this.color,
  });
}

class _LegendWrap extends StatelessWidget {
  final List<_LegendItemData> items;

  const _LegendWrap({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFB),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: e.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                e.text,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6F5C),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Tekrar Dene',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;

  const _SkeletonCard({
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            height: 18,
            width: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}