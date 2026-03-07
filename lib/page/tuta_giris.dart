import 'package:agronet/api/tuta_giris_kay%C4%B1t.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/tuta_giris_model.dart';

class TutaGirisPage extends StatefulWidget {
  const TutaGirisPage({super.key});

  @override
  State<TutaGirisPage> createState() => _TutaGirisPageState();
}

class _TutaGirisPageState extends State<TutaGirisPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F7FA);
  static const Color cardBg = Colors.white;

  final TutaGirisApi _api = const TutaGirisApi();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChange = false;
  List<TutaRowModel> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final result = await _api.tutaGirisGetir(_selectedDate);

   setState(() {
  _rows = result.rows;
  _hasChange = false;
});
    } catch (e) {
      _snack('Veriler alınamadı: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });

    await _loadData();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final sonuc = await _api.tutaGirisKaydet(
        tarih: _selectedDate,
        rows: _rows,
      );

      if (sonuc.durum) {
        setState(() => _hasChange = false);
        _snack(sonuc.mesaj.isEmpty ? 'Kayıt başarılı.' : sonuc.mesaj);
      } else {
        _snack(
          sonuc.mesaj.isEmpty ? 'Kayıt sırasında hata oluştu.' : sonuc.mesaj,
          error: true,
        );
      }
    } catch (e) {
      _snack('Kaydetme hatası: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
Future<void> _openEditSheet(int index) async {
  final current = _rows[index];

  final updated = await showModalBottomSheet<TutaRowModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.80,
      child: _TutaEditSheet(
        key: ValueKey(current.sera),
        row: current,
        accent: accent,
      ),
    ),
  );

  if (updated != null) {
    setState(() {
      _rows[index] = updated;
      _hasChange = true;
    });
  }
}

  int get _genelToplam =>
      _rows.fold<int>(0, (sum, item) => sum + item.toplam);

  int get _duzenlenenSeraSayisi =>
      _rows.where((e) => e.doluAlanSayisi > 0).length;

  Future<bool> _onWillPop() async {
    if (!_hasChange) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kaydedilmemiş değişiklik var'),
        content: const Text(
          'Bu sayfadan çıkarsan yaptığın değişiklikler kaybolabilir. Çıkmak istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çık'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final tarihText = DateFormat('dd.MM.yyyy').format(_selectedDate);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          centerTitle: false,
          title: const Text(
            'Tuta Giriş',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (_isLoading || _isSaving) ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Kaydediliyor' : 'Kaydet'),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: accent,
          onRefresh: _loadData,
          child: Column(
            children: [
              _buildTopSection(tarihText),
              Expanded(
                child: _isLoading
                    ? _buildLoadingList()
                    : _rows.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _rows.length,
                            itemBuilder: (context, index) {
                              final item = _rows[index];
                              return _buildSeraCard(item, index);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(String tarihText) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9EDF2)),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pickDate,
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4EAF1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tarih',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    tarihText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  title: 'Toplam Sera',
                  value: '${_rows.length}',
                  icon: Icons.grid_view_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoBox(
                  title: 'Dolu Sera',
                  value: '$_duzenlenenSeraSayisi',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoBox(
                  title: 'Genel Toplam',
                  value: '$_genelToplam',
                  icon: Icons.summarize_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeraCard(TutaRowModel item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openEditSheet(index),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.energy_savings_leaf_rounded,
                      color: accent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.sera,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: item.doluAlanSayisi > 0
                          ? Colors.green.withOpacity(.10)
                          : Colors.orange.withOpacity(.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.doluAlanSayisi > 0 ? 'Dolu' : 'Boş',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: item.doluAlanSayisi > 0
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat(
                      'Toplam',
                      '${item.toplam}',
                      Icons.calculate_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMiniStat(
                      'Dolu Alan',
                      '${item.doluAlanSayisi}/16',
                      Icons.view_module_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMiniStat(
                      'İşlem',
                      'Düzenle',
                      Icons.edit_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Container(
          height: 128,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 70,
                color: Colors.black26,
              ),
              SizedBox(height: 12),
              Text(
                'Gösterilecek kayıt bulunamadı',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class _TutaEditSheet extends StatefulWidget {
  final TutaRowModel row;
  final Color accent;

  const _TutaEditSheet({
    Key? key,
    required this.row,
    required this.accent,
  }) : super(key: key);

  @override
  State<_TutaEditSheet> createState() => _TutaEditSheetState();
}

class _TutaEditSheetState extends State<_TutaEditSheet> {
 late List<TextEditingController> _controllers;

@override
void initState() {
  super.initState();
  _fillControllers();
}

void _fillControllers() {
  _controllers = [
    TextEditingController(text: widget.row.deger1.toString()),
    TextEditingController(text: widget.row.deger2.toString()),
    TextEditingController(text: widget.row.deger3.toString()),
    TextEditingController(text: widget.row.deger4.toString()),
    TextEditingController(text: widget.row.deger5.toString()),
    TextEditingController(text: widget.row.deger6.toString()),
    TextEditingController(text: widget.row.deger7.toString()),
    TextEditingController(text: widget.row.deger8.toString()),
    TextEditingController(text: widget.row.deger9.toString()),
    TextEditingController(text: widget.row.deger10.toString()),
    TextEditingController(text: widget.row.deger11.toString()),
    TextEditingController(text: widget.row.deger12.toString()),
    TextEditingController(text: widget.row.deger13.toString()),
    TextEditingController(text: widget.row.deger14.toString()),
    TextEditingController(text: widget.row.deger15.toString()),
    TextEditingController(text: widget.row.deger16.toString()),
  ];
}
@override
void didUpdateWidget(covariant _TutaEditSheet oldWidget) {
  super.didUpdateWidget(oldWidget);

  if (oldWidget.row.sera != widget.row.sera) {
    for (final c in _controllers) {
      c.dispose();
    }
    _fillControllers();
    setState(() {});
  }
}

  @override
  void dispose() {
    for (final item in _controllers) {
      item.dispose();
    }
    super.dispose();
  }

  int _parse(String text) => int.tryParse(text.trim()) ?? 0;

  void _clearAll() {
    for (final c in _controllers) {
      c.text = '0';
    }
    setState(() {});
  }

  void _apply() {
    final updated = widget.row.copyWith(
      deger1: _parse(_controllers[0].text),
      deger2: _parse(_controllers[1].text),
      deger3: _parse(_controllers[2].text),
      deger4: _parse(_controllers[3].text),
      deger5: _parse(_controllers[4].text),
      deger6: _parse(_controllers[5].text),
      deger7: _parse(_controllers[6].text),
      deger8: _parse(_controllers[7].text),
      deger9: _parse(_controllers[8].text),
      deger10: _parse(_controllers[9].text),
      deger11: _parse(_controllers[10].text),
      deger12: _parse(_controllers[11].text),
      deger13: _parse(_controllers[12].text),
      deger14: _parse(_controllers[13].text),
      deger15: _parse(_controllers[14].text),
      deger16: _parse(_controllers[15].text),
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
   final names = widget.row.isimler;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
          Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Expanded(
      child: Text(
        widget.row.sera,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    ),
    const SizedBox(width: 8),
    SizedBox(
      height: 40,
      child: TextButton.icon(
        onPressed: _clearAll,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          minimumSize: const Size(0, 40),
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Sıfırla'),
      ),
    ),
  ],
),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Alanları düzenleyip uygula butonuna bas.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 16,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 100,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      return  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        names[index].trim().isEmpty ? 'Değer ${index + 1}' : names[index],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    ),
    Expanded(
      child: TextField(
        controller: _controllers[index],
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          hintText: '0',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: widget.accent,
              width: 1.4,
            ),
          ),
        ),
      ),
    ),
  ],
);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _apply,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'Uygula',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}