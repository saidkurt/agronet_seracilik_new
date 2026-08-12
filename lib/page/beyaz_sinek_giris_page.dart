import 'package:agronet/api/beyaz_sinek_giris_api.dart';
import 'package:agronet/models/beyaz_sinek_giris_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BeyazSinekGirisPage extends StatefulWidget {
  const BeyazSinekGirisPage({
    super.key,
    required this.personelKodu,
  });

  final String personelKodu;

  @override
  State<BeyazSinekGirisPage> createState() =>
      _BeyazSinekGirisPageState();
}

class _BeyazSinekGirisPageState
    extends State<BeyazSinekGirisPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  final BeyazSinekGirisApi _api =
      const BeyazSinekGirisApi();

  DateTime _selectedDate = DateTime.now();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChange = false;

  List<BeyazSinekRowModel> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // MESAJ
  // ============================================================

  void _snack(
    String mesaj, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mesaj,
            style: const TextStyle(
              fontSize: 11,
            ),
          ),
          backgroundColor:
              error ? Colors.red.shade700 : accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // VERİ
  // ============================================================

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await _api.beyazSinekGirisGetir(
        tarih: _selectedDate,
        personelKodu: widget.personelKodu,
      );

      if (!mounted) return;

      setState(() {
        _rows = result.rows;
        _hasChange = false;
      });
    } catch (e) {
      _snack(
        'Veriler alınamadı: $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // TARİH
  // ============================================================

  Future<void> _pickDate() async {
    if (_isLoading || _isSaving) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );

    if (picked == null) return;

    if (_hasChange) {
      final devamEt =
          await _tarihDegistirmeOnayi();

      if (!devamEt) return;
    }

    setState(() {
      _selectedDate = picked;
    });

    await _loadData();
  }

  Future<bool> _tarihDegistirmeOnayi() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Kaydedilmemiş değişiklik',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'Tarihi değiştirirsen yaptığın değişiklikler kaybolacak. Devam etmek istiyor musun?',
          style: TextStyle(
            fontSize: 11.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                false,
              );
            },
            child: const Text(
              'Vazgeç',
              style: TextStyle(
                fontSize: 11,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
            ),
            onPressed: () {
              Navigator.pop(
                context,
                true,
              );
            },
            child: const Text(
              'Devam Et',
              style: TextStyle(
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ============================================================
  // KAYDET
  // ============================================================

  Future<void> _save() async {
    if (_isSaving || _isLoading) return;

    if (_rows.isEmpty) {
      _snack(
        'Kaydedilecek sera bulunamadı.',
        error: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final sonuc =
          await _api.beyazSinekGirisKaydet(
        tarih: _selectedDate,
        personelKodu: widget.personelKodu,
        rows: _rows,
      );

      if (!mounted) return;

      if (sonuc.durum) {
        setState(() {
          _hasChange = false;
        });

        _snack(
          sonuc.mesaj.isEmpty
              ? 'Kayıt başarılı.'
              : sonuc.mesaj,
        );
      } else {
        _snack(
          sonuc.mesaj.isEmpty
              ? 'Kayıt sırasında hata oluştu.'
              : sonuc.mesaj,
          error: true,
        );
      }
    } catch (e) {
      _snack(
        'Kaydetme hatası: $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // DÜZENLE
  // ============================================================

  Future<void> _openEditSheet(
    int index,
  ) async {
    if (_isLoading || _isSaving) return;

    final current = _rows[index];

    final updated =
        await showModalBottomSheet<
            BeyazSinekRowModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: .78,
        child: _BeyazSinekEditSheet(
          key: ValueKey(current.sera),
          row: current,
          accent: accent,
        ),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      _rows[index] = updated;
      _hasChange = true;
    });
  }

  // ============================================================
  // TOPLAMLAR
  // ============================================================

  int get _genelToplam {
    return _rows.fold<int>(
      0,
      (sum, item) => sum + item.toplam,
    );
  }

  int get _duzenlenenSeraSayisi {
    return _rows
        .where(
          (item) =>
              item.doluAlanSayisi > 0,
        )
        .length;
  }

  // ============================================================
  // GERİ
  // ============================================================

  Future<bool> _onWillPop() async {
    if (!_hasChange) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Kaydedilmemiş değişiklik',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'Bu sayfadan çıkarsan yaptığın değişiklikler kaybolabilir. Çıkmak istiyor musun?',
          style: TextStyle(
            fontSize: 11.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                false,
              );
            },
            child: const Text(
              'Vazgeç',
              style: TextStyle(
                fontSize: 11,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  Colors.red.shade700,
            ),
            onPressed: () {
              Navigator.pop(
                context,
                true,
              );
            },
            child: const Text(
              'Çık',
              style: TextStyle(
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final tarihText =
        DateFormat('dd.MM.yyyy').format(
      _selectedDate,
    );

    final scaler =
        MediaQuery.textScalerOf(context).clamp(
      maxScaleFactor: 1.06,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: scaler,
      ),
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: bg,

          // ======================================================
          // APP BAR
          // ======================================================

          appBar: AppBar(
            toolbarHeight: 48,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            centerTitle: true,
            title: const Text(
              'Beyaz Sinek Sayımı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(
                  right: 7,
                ),
                child: Center(
                  child: SizedBox(
                    height: 34,
                    child: FilledButton.icon(
                      style:
                          FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  8),
                        ),
                      ),
                      onPressed:
                          (_isLoading ||
                                  _isSaving)
                              ? null
                              : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 13,
                              height: 13,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.save_rounded,
                              size: 16,
                            ),
                      label: Text(
                        _isSaving
                            ? 'Kaydediliyor'
                            : 'Kaydet',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ======================================================
          // BODY
          // ======================================================

          body: RefreshIndicator(
            color: accent,
            onRefresh: _loadData,
            child: Column(
              children: [
                _buildTopSection(
                  tarihText,
                ),

                Expanded(
                  child: _isLoading
                      ? _buildLoadingList()
                      : _rows.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(
                                10,
                                7,
                                10,
                                14,
                              ),
                              itemCount:
                                  _rows.length,
                              separatorBuilder:
                                  (_, __) =>
                                      const SizedBox(
                                height: 6,
                              ),
                              itemBuilder:
                                  (context, index) {
                                return _buildSeraCard(
                                  _rows[index],
                                  index,
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ÜST ALAN
  // ============================================================

  Widget _buildTopSection(
    String tarihText,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        8,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _pickDate,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFF7F7F9),
                borderRadius:
                    BorderRadius.circular(10),
                border: Border.all(
                  color:
                      Colors.black.withOpacity(.06),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color:
                          accent.withOpacity(.10),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: accent,
                      size: 18,
                    ),
                  ),

                  const SizedBox(width: 9),

                  const Text(
                    'Tarih',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    tarihText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(width: 4),

                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: Colors.black38,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  title: 'Toplam Sera',
                  value:
                      '${_rows.length}',
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: _buildInfoBox(
                  title: 'Dolu Sera',
                  value:
                      '$_duzenlenenSeraSayisi',
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: _buildInfoBox(
                  title: 'Genel Toplam',
                  value:
                      '$_genelToplam',
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
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.black.withOpacity(.05),
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        mainAxisSize:
            MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1,
                fontWeight:
                    FontWeight.w900,
                color: accent,
              ),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9.5,
              height: 1,
              color: Colors.black45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SERA SATIRI
  // ============================================================

  Widget _buildSeraCard(
    BeyazSinekRowModel item,
    int index,
  ) {
    final dolu =
        item.doluAlanSayisi > 0;

    final durumRenk = dolu
        ? Colors.green.shade700
        : Colors.orange.shade700;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          _openEditSheet(index);
        },
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(10),
            border: Border.all(
              color:
                  Colors.black.withOpacity(.055),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: durumRenk,
                  borderRadius:
                      const BorderRadius.only(
                    topLeft:
                        Radius.circular(9),
                    bottomLeft:
                        Radius.circular(9),
                  ),
                ),
              ),

              const SizedBox(width: 9),

              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      accent.withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.pest_control_rounded,
                  color: accent,
                  size: 20,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.sera,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Text(
                          '${item.doluAlanSayisi}/${item.aktifAlanSayisi} alan',
                          style:
                              const TextStyle(
                            fontSize: 10,
                            color:
                                Colors.black45,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(
                            width: 8),

                        Container(
                          width: 3,
                          height: 3,
                          decoration:
                              const BoxDecoration(
                            color:
                                Colors.black26,
                            shape:
                                BoxShape.circle,
                          ),
                        ),

                        const SizedBox(
                            width: 8),

                        Text(
                          dolu
                              ? 'Dolu'
                              : 'Boş',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight:
                                FontWeight.w800,
                            color: durumRenk,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Toplam',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.black38,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    '${item.toplam}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 7),

              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: Colors.black26,
              ),

              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        10,
        7,
        10,
        14,
      ),
      itemCount: 7,
      separatorBuilder:
          (_, __) =>
              const SizedBox(height: 6),
      itemBuilder: (_, __) {
        return Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(10),
          ),
        );
      },
    );
  }

  // ============================================================
  // BOŞ
  // ============================================================

  Widget _buildEmptyState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 110),
        Icon(
          Icons.inbox_outlined,
          size: 45,
          color: Colors.black26,
        ),
        SizedBox(height: 8),
        Text(
          'Bu personele tanımlı sera bulunamadı',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black45,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BEYAZ SİNEK DÜZENLEME
// ============================================================================

class _BeyazSinekEditSheet
    extends StatefulWidget {
  const _BeyazSinekEditSheet({
    super.key,
    required this.row,
    required this.accent,
  });

  final BeyazSinekRowModel row;
  final Color accent;

  @override
  State<_BeyazSinekEditSheet>
      createState() =>
          _BeyazSinekEditSheetState();
}

class _BeyazSinekEditSheetState
    extends State<_BeyazSinekEditSheet> {
  late List<TextEditingController>
      _controllers;

  @override
  void initState() {
    super.initState();
    _fillControllers();
  }

  void _fillControllers() {
    _controllers = [
      TextEditingController(
        text: widget.row.deger1.toString(),
      ),
      TextEditingController(
        text: widget.row.deger2.toString(),
      ),
      TextEditingController(
        text: widget.row.deger3.toString(),
      ),
      TextEditingController(
        text: widget.row.deger4.toString(),
      ),
      TextEditingController(
        text: widget.row.deger5.toString(),
      ),
      TextEditingController(
        text: widget.row.deger6.toString(),
      ),
      TextEditingController(
        text: widget.row.deger7.toString(),
      ),
      TextEditingController(
        text: widget.row.deger8.toString(),
      ),
      TextEditingController(
        text: widget.row.deger9.toString(),
      ),
      TextEditingController(
        text: widget.row.deger10.toString(),
      ),
      TextEditingController(
        text: widget.row.deger11.toString(),
      ),
      TextEditingController(
        text: widget.row.deger12.toString(),
      ),
      TextEditingController(
        text: widget.row.deger13.toString(),
      ),
      TextEditingController(
        text: widget.row.deger14.toString(),
      ),
      TextEditingController(
        text: widget.row.deger15.toString(),
      ),
      TextEditingController(
        text: widget.row.deger16.toString(),
      ),
    ];
  }

  @override
  void didUpdateWidget(
    covariant _BeyazSinekEditSheet oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.row.sera !=
        widget.row.sera) {
      for (final controller
          in _controllers) {
        controller.dispose();
      }

      _fillControllers();

      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final controller
        in _controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  int _parse(String text) {
    return int.tryParse(
          text.trim(),
        ) ??
        0;
  }

  void _clearAll() {
    for (final alan
        in widget.row.aktifAlanlar) {
      _controllers[alan.index].text =
          '0';
    }

    setState(() {});
  }

  void _apply() {
    final updated = widget.row.copyWith(
      deger1:
          _parse(_controllers[0].text),
      deger2:
          _parse(_controllers[1].text),
      deger3:
          _parse(_controllers[2].text),
      deger4:
          _parse(_controllers[3].text),
      deger5:
          _parse(_controllers[4].text),
      deger6:
          _parse(_controllers[5].text),
      deger7:
          _parse(_controllers[6].text),
      deger8:
          _parse(_controllers[7].text),
      deger9:
          _parse(_controllers[8].text),
      deger10:
          _parse(_controllers[9].text),
      deger11:
          _parse(_controllers[10].text),
      deger12:
          _parse(_controllers[11].text),
      deger13:
          _parse(_controllers[12].text),
      deger14:
          _parse(_controllers[13].text),
      deger15:
          _parse(_controllers[14].text),
      deger16:
          _parse(_controllers[15].text),
    );

    Navigator.pop(
      context,
      updated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final aktifAlanlar =
        widget.row.aktifAlanlar;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6F8),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 10,
            right: 10,
            top: 8,
            bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius:
                      BorderRadius.circular(99),
                ),
              ),

              const SizedBox(height: 7),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.row.sera,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 30,
                    child: TextButton.icon(
                      onPressed: _clearAll,
                      style:
                          TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        visualDensity:
                            VisualDensity.compact,
                      ),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 15,
                      ),
                      label: const Text(
                        'Sıfırla',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 2),

              const Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  'Alanları düzenleyin.',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 9.5,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Flexible(
                child:
                    SingleChildScrollView(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount:
                        aktifAlanlar.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 78,
                      crossAxisSpacing: 9,
                      mainAxisSpacing: 9,
                    ),
                    itemBuilder:
                        (context, index) {
                      final alan =
                          aktifAlanlar[index];

                      final controllerIndex =
                          alan.index;

                      final baslik =
                          alan.isim;

                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(
                              left: 2,
                              bottom: 3,
                            ),
                            child: Text(
                              baslik.isEmpty
                                  ? 'Değer ${index + 1}'
                                  : baslik,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    Colors.black54,
                              ),
                            ),
                          ),

                          Expanded(
                            child: TextField(
                              controller:
                                  _controllers[
                                      controllerIndex],
                              keyboardType:
                                  TextInputType.number,
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly,
                              ],
                              onTap: () {
                                final controller =
                                    _controllers[
                                        controllerIndex];

                                if (controller
                                        .text ==
                                    '0') {
                                  controller
                                          .selection =
                                      TextSelection(
                                    baseOffset: 0,
                                    extentOffset:
                                        controller
                                            .text
                                            .length,
                                  );
                                }
                              },
                              decoration:
                                  InputDecoration(
                                hintText: '0',
                                isDense: true,
                                filled: true,
                                fillColor:
                                    Colors.white,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          8),
                                  borderSide:
                                      const BorderSide(
                                    color: Color(
                                      0xFFE2E8F0,
                                    ),
                                  ),
                                ),
                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          8),
                                  borderSide:
                                      const BorderSide(
                                    color: Color(
                                      0xFFE2E8F0,
                                    ),
                                  ),
                                ),
                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          8),
                                  borderSide:
                                      BorderSide(
                                    color:
                                        widget.accent,
                                    width: 1.2,
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

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        widget.accent,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(9),
                    ),
                  ),
                  onPressed: _apply,
                  icon: const Icon(
                    Icons.check_rounded,
                    size: 17,
                  ),
                  label: const Text(
                    'UYGULA',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                          FontWeight.w900,
                    ),
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