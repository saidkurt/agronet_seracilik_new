import 'package:agronet/api/otp_api.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class YeniSifrePage extends StatefulWidget {
  final String resetToken;
  final String telefon;

  const YeniSifrePage({
    super.key,
    required this.resetToken,
    required this.telefon,
  });

  @override
  State<YeniSifrePage> createState() =>
      _YeniSifrePageState();
}

class _YeniSifrePageState extends State<YeniSifrePage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  final _api = const SistemOtpApi();
  final _formKey = GlobalKey<FormState>();

  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _pass1.dispose();
    _pass2.dispose();
    super.dispose();
  }

  // ============================================================
  // MESAJ
  // ============================================================

  void _snack(
    String msg, {
    bool success = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          backgroundColor:
              success ? accent : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // TELEFON MASKELE
  // ============================================================

  String _maskedPhone(String phone) {
    final digits =
        phone.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.length < 4) {
      return phone;
    }

    final visible =
        digits.substring(
      digits.length - 4,
    );

    return '••• ••• $visible';
  }

  // ============================================================
  // VALIDASYON
  // ============================================================

  String? _validatePass1(String? v) {
    final s =
        (v ?? '').trim();

    if (s.isEmpty) {
      return 'Yeni şifre boş olamaz';
    }

    if (!RegExp(r'^\d+$').hasMatch(s)) {
      return 'Şifre sadece rakamlardan oluşmalı';
    }

    if (s.length < 6) {
      return 'Şifre en az 6 haneli olmalı';
    }

    return null;
  }

  String? _validatePass2(String? v) {
    final s2 =
        (v ?? '').trim();

    if (s2.isEmpty) {
      return 'Şifre doğrulama boş olamaz';
    }

    if (!RegExp(r'^\d+$').hasMatch(s2)) {
      return 'Şifre sadece rakamlardan oluşmalı';
    }

    if (s2 != _pass1.text.trim()) {
      return 'Şifreler aynı değil';
    }

    return null;
  }

  // ============================================================
  // KAYDET
  // ============================================================

  Future<void> _kaydet() async {
    FocusScope.of(context).unfocus();

    final valid =
        _formKey.currentState?.validate() ?? false;

    if (!valid) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final r =
          await _api.yeniSifreKaydet(
        resetToken: widget.resetToken,
        yeniSifre: _pass1.text.trim(),
      );

      if (!mounted) return;

      if (!r.ok) {
        _snack(
          r.msg.isEmpty
              ? 'Şifre güncellenemedi'
              : r.msg,
        );

        return;
      }

      _snack(
        'Şifre güncellendi',
        success: true,
      );

      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _snack(
        'Bir hata oluştu: $e',
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
  // INPUT
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: const Color(0xFFF7F7F9),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(.07),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(.07),
        ),
      ),
      focusedBorder:
          const OutlineInputBorder(
        borderRadius:
            BorderRadius.all(
          Radius.circular(10),
        ),
        borderSide: BorderSide(
          color: accent,
          width: 1.3,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.red.shade400,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 1.3,
        ),
      ),
      suffixIcon: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed:
            _loading ? null : onToggle,
        icon: Icon(
          obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 19,
          color: Colors.black45,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final scaler =
        MediaQuery.textScalerOf(context).clamp(
      maxScaleFactor: 1.06,
    );

    return MediaQuery(
      data:
          MediaQuery.of(context).copyWith(
        textScaler: scaler,
      ),
      child: Scaffold(
        backgroundColor: bg,

        // ========================================================
        // APP BAR
        // ========================================================

        appBar: AppBar(
          toolbarHeight: 48,
          elevation: 0,
          backgroundColor:
              Colors.white,
          foregroundColor:
              Colors.black87,
          centerTitle: true,
          title: const Text(
            'Yeni Şifre',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ),

        // ========================================================
        // BODY
        // ========================================================

        body: SafeArea(
          child: Center(
            child:
                SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                18,
              ),
              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 390,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: [
                    // ============================================
                    // İKON
                    // ============================================

                    Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration:
                            BoxDecoration(
                          color: accent
                              .withOpacity(.09),
                          shape:
                              BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons
                              .lock_reset_rounded,
                          size: 26,
                          color: accent,
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 10),

                    // ============================================
                    // BAŞLIK
                    // ============================================

                    const Text(
                      'Şifre Yenileme',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            Colors.black87,
                      ),
                    ),

                    const SizedBox(
                        height: 3),

                    Text(
                      '${_maskedPhone(widget.telefon)} için yeni şifrenizi belirleyin.',
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color:
                            Colors.black45,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                        height: 16),

                    // ============================================
                    // FORM KARTI
                    // ============================================

                    Container(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        13,
                        13,
                        13,
                        12,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(14),
                        border: Border.all(
                          color: Colors.black
                              .withOpacity(.05),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              'Yeni Şifre Bilgileri',
                              style:
                                  TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                    FontWeight
                                        .w900,
                              ),
                            ),

                            const SizedBox(
                                height: 3),

                            const Text(
                              'En az 6 hane ve sadece rakamlardan oluşmalıdır.',
                              style:
                                  TextStyle(
                                fontSize: 9.8,
                                color: Colors
                                    .black45,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),

                            const SizedBox(
                                height: 11),

                            // ====================================
                            // ŞİFRE 1
                            // ====================================

                            TextFormField(
                              controller:
                                  _pass1,
                              obscureText:
                                  _obscure1,
                              enabled:
                                  !_loading,
                              keyboardType:
                                  TextInputType
                                      .number,
                              textInputAction:
                                  TextInputAction
                                      .next,
                              style:
                                  const TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly,
                              ],
                              decoration:
                                  _inputDecoration(
                                label:
                                    'Yeni Şifre',
                                obscure:
                                    _obscure1,
                                onToggle: () {
                                  setState(() {
                                    _obscure1 =
                                        !_obscure1;
                                  });
                                },
                              ),
                              validator:
                                  _validatePass1,
                            ),

                            const SizedBox(
                                height: 9),

                            // ====================================
                            // ŞİFRE 2
                            // ====================================

                            TextFormField(
                              controller:
                                  _pass2,
                              obscureText:
                                  _obscure2,
                              enabled:
                                  !_loading,
                              keyboardType:
                                  TextInputType
                                      .number,
                              textInputAction:
                                  TextInputAction
                                      .done,
                              style:
                                  const TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly,
                              ],
                              decoration:
                                  _inputDecoration(
                                label:
                                    'Yeni Şifre (Tekrar)',
                                obscure:
                                    _obscure2,
                                onToggle: () {
                                  setState(() {
                                    _obscure2 =
                                        !_obscure2;
                                  });
                                },
                              ),
                              validator:
                                  _validatePass2,
                              onFieldSubmitted:
                                  (_) {
                                if (!_loading) {
                                  _kaydet();
                                }
                              },
                            ),

                            const SizedBox(
                                height: 10),

                            // ====================================
                            // KISA BİLGİ
                            // ====================================

                            Container(
                              width:
                                  double.infinity,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 8,
                                vertical: 7,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFF7F7F9,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(8),
                                border: Border.all(
                                  color: Colors
                                      .black
                                      .withOpacity(
                                          .045),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .info_outline_rounded,
                                    size: 15,
                                    color:
                                        Colors.black45,
                                  ),
                                  const SizedBox(
                                      width: 5),
                                  const Expanded(
                                    child:
                                        Text(
                                      'Şifre en az 6 rakam olmalıdır.',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            9.8,
                                        color:
                                            Colors.black45,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                                height: 10),

                            // ====================================
                            // KAYDET
                            // ====================================

                            SizedBox(
                              width:
                                  double.infinity,
                              height: 42,
                              child:
                                  ElevatedButton
                                      .icon(
                                onPressed:
                                    _loading
                                        ? null
                                        : _kaydet,
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  elevation: 0,
                                  backgroundColor:
                                      accent,
                                  foregroundColor:
                                      Colors.white,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                9),
                                  ),
                                ),
                                icon:
                                    _loading
                                        ? const SizedBox(
                                            width:
                                                14,
                                            height:
                                                14,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth:
                                                  2,
                                              color:
                                                  Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons
                                                .save_outlined,
                                            size:
                                                18,
                                          ),
                                label: Text(
                                  _loading
                                      ? 'Kaydediliyor...'
                                      : 'Kaydet',
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        12,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 12),

                    Center(
                      child: Text(
                        'Agronet Seracılık A.Ş',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.black
                              .withOpacity(.28),
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}