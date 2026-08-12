import 'package:agronet/api/login_api.dart';
import 'package:agronet/page/Homepage/home_page.dart';
import 'package:agronet/page/LoginPage/otp_dogrulama_page.dart';
import 'package:agronet/services/update_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPageView extends StatefulWidget {
  const LoginPageView({super.key});

  @override
  State<LoginPageView> createState() =>
      _LoginPageViewState();
}

class _LoginPageViewState extends State<LoginPageView> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);
  static const Color cardBg = Colors.white;

  final _formKey = GlobalKey<FormState>();

  final _telCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();

  final LoginApi _api = const LoginApi();

  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  @override
  void dispose() {
    _telCtrl.dispose();
    _sifreCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // SNACK
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
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              success ? accent : Colors.red.shade600,
        ),
      );
  }

  // ============================================================
  // TELEFON
  // ============================================================

  String _digitsOnly(String s) {
    return s.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
  }

  String _formatTr10(String digits) {
    final d = _digitsOnly(digits);

    if (d.isEmpty) {
      return '';
    }

    final x = d.length > 10
        ? d.substring(0, 10)
        : d;

    final sb = StringBuffer();

    for (int i = 0; i < x.length; i++) {
      if (i == 3) sb.write(' ');
      if (i == 6) sb.write(' ');
      if (i == 8) sb.write(' ');

      sb.write(x[i]);
    }

    return sb.toString();
  }

  bool _isValidTel(String digits) {
    return RegExp(r'^\d{10}$').hasMatch(
      digits,
    );
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final ok =
        _formKey.currentState?.validate() ?? false;

    if (!ok) return;

    final telDigits =
        _digitsOnly(_telCtrl.text.trim());

    final sifre =
        _sifreCtrl.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _api.girisTel(
        telefon: telDigits,
        sifre: sifre,
      );

      if (users.isEmpty) {
        _snack(
          "Kullanıcı bulunamadı",
        );
        return;
      }

      final u = users.first;

      if (_rememberMe) {
        await _savePref(
          telDigits,
          sifre,
        );
      } else {
        await _clearPref();
      }

      if (!mounted) return;

      await UpdateService.cihazKaydet(
        personelKodu:
            u.bsrKullaniciKodu,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HomeMenuPage(
            user: u,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _snack(
        "Bağlantı hatası: $e",
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
  // SHARED PREFERENCES
  // ============================================================

  Future<void> _savePref(
    String telDigits,
    String sifre,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'TEL',
      telDigits,
    );

    await prefs.setString(
      'Sifre',
      sifre,
    );
  }

  Future<void> _clearPref() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'TEL',
      '',
    );

    await prefs.setString(
      'Sifre',
      '',
    );
  }

  Future<void> _loadPref() async {
    final prefs =
        await SharedPreferences.getInstance();

    final telDigits =
        prefs.getString('TEL') ?? '';

    final sifre =
        prefs.getString('Sifre') ?? '';

    if (telDigits.isNotEmpty) {
      _telCtrl.text =
          _formatTr10(telDigits);

      _sifreCtrl.text =
          sifre;

      if (mounted) {
        setState(() {
          _rememberMe = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _rememberMe = false;
        });
      }
    }
  }

  Future<void> _onRememberChanged(
    bool value,
  ) async {
    setState(() {
      _rememberMe = value;
    });

    if (!value) {
      await _clearPref();

      if (!mounted) return;

      setState(() {
        _telCtrl.clear();
        _sifreCtrl.clear();
      });
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _dec({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: Colors.black38,
      ),
      prefixIcon: Icon(
        icon,
        color: accent,
        size: 19,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor:
          const Color(0xFFF7F7F9),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide: BorderSide(
          color:
              Colors.black.withOpacity(.07),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide: BorderSide(
          color:
              Colors.black.withOpacity(.07),
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
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final scaler =
        MediaQuery.textScalerOf(context)
            .clamp(
      maxScaleFactor: 1.06,
    );

    return MediaQuery(
      data:
          MediaQuery.of(context).copyWith(
        textScaler: scaler,
      ),
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                14,
                18,
                18,
              ),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 390,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      // ==================================================
                      // LOGO
                      // ==================================================

                      Center(
                        child: Image.asset(
                          "assets/agronet.png",
                          height: 82,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(
                          height: 11),

                      // ==================================================
                      // BAŞLIK
                      // ==================================================

                      const Text(
                        "Agronet'e Hoş Geldiniz",
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w900,
                          color:
                              Colors.black87,
                        ),
                      ),

                      const SizedBox(
                          height: 3),

                      const Text(
                        "Hesabınıza giriş yapın",
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color:
                              Colors.black45,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                          height: 18),

                      // ==================================================
                      // LOGIN CARD
                      // ==================================================

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          14,
                          14,
                          14,
                          11,
                        ),
                        decoration:
                            BoxDecoration(
                          color: cardBg,
                          borderRadius:
                              BorderRadius
                                  .circular(14),
                          border:
                              Border.all(
                            color: Colors
                                .black
                                .withOpacity(
                                    .05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              "Giriş Bilgileri",
                              style:
                                  TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight
                                        .w900,
                                color: Colors
                                    .black87,
                              ),
                            ),

                            const SizedBox(
                                height: 3),

                            const Text(
                              "Telefon ve şifrenizi girin.",
                              style:
                                  TextStyle(
                                fontSize: 10.5,
                                color: Colors
                                    .black45,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),

                            const SizedBox(
                                height: 11),

                            // ==============================================
                            // TELEFON
                            // ==============================================

                            TextFormField(
                              controller:
                                  _telCtrl,
                              enabled:
                                  !_isLoading,
                              keyboardType:
                                  TextInputType
                                      .phone,
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
                              inputFormatters:
                                  const [
                                TrPhoneFormatter10(
                                  prefixMustBe505:
                                      true,
                                ),
                              ],
                              decoration:
                                  _dec(
                                hint:
                                    "Telefon (505 123 45 67)",
                                icon: Icons
                                    .phone_android_rounded,
                              ),
                              validator: (v) {
                                final digits =
                                    _digitsOnly(
                                  v ?? '',
                                );

                                if (digits
                                    .isEmpty) {
                                  return "Telefon boş olamaz";
                                }

                                if (!_isValidTel(
                                    digits)) {
                                  return "Telefon 10 hane olmalı";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                                height: 9),

                            // ==============================================
                            // ŞİFRE
                            // ==============================================

                            TextFormField(
                              controller:
                                  _sifreCtrl,
                              enabled:
                                  !_isLoading,
                              obscureText:
                                  _obscure,
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
                              onFieldSubmitted:
                                  (_) {
                                if (!_isLoading) {
                                  _login();
                                }
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly,
                              ],
                              decoration:
                                  _dec(
                                hint: "Şifre",
                                icon: Icons
                                    .lock_outline_rounded,
                                suffix:
                                    IconButton(
                                  visualDensity:
                                      VisualDensity
                                          .compact,
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () {
                                              setState(
                                                  () {
                                                _obscure =
                                                    !_obscure;
                                              });
                                            },
                                  icon: Icon(
                                    _obscure
                                        ? Icons
                                            .visibility_outlined
                                        : Icons
                                            .visibility_off_outlined,
                                    size: 19,
                                    color: Colors
                                        .black45,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                final s =
                                    (v ?? '')
                                        .trim();

                                if (s.isEmpty) {
                                  return "Şifre boş olamaz";
                                }

                                if (!RegExp(
                                        r'^\d+$')
                                    .hasMatch(
                                        s)) {
                                  return "Şifre sadece rakamlardan oluşmalı";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                                height: 7),

                            // ==============================================
                            // HATIRLA + ŞİFREMİ UNUTTUM
                            // ==============================================

                            Row(
                              children: [
                                InkWell(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              7),
                                  onTap:
                                      _isLoading
                                          ? null
                                          : () {
                                              _onRememberChanged(
                                                !_rememberMe,
                                              );
                                            },
                                  child:
                                      Padding(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      vertical:
                                          3,
                                    ),
                                    child:
                                        Row(
                                      mainAxisSize:
                                          MainAxisSize
                                              .min,
                                      children: [
                                        SizedBox(
                                          width: 28,
                                          height:
                                              28,
                                          child:
                                              Checkbox(
                                            value:
                                                _rememberMe,
                                            activeColor:
                                                accent,
                                            visualDensity:
                                                VisualDensity.compact,
                                            shape:
                                                RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            onChanged: _isLoading
                                                ? null
                                                : (v) {
                                                    _onRememberChanged(
                                                      v ?? false,
                                                    );
                                                  },
                                          ),
                                        ),
                                        const SizedBox(
                                            width:
                                                1),
                                        const Text(
                                          "Beni Hatırla",
                                          style:
                                              TextStyle(
                                            fontSize:
                                                10.8,
                                            fontWeight:
                                                FontWeight.w700,
                                            color:
                                                Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const Spacer(),

                                TextButton(
                                  style:
                                      TextButton
                                          .styleFrom(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal:
                                          4,
                                      vertical:
                                          2,
                                    ),
                                    minimumSize:
                                        const Size(
                                      0,
                                      30,
                                    ),
                                  ),
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () {
                                              final tel =
                                                  _telCtrl.text.trim();

                                              if (tel
                                                  .isEmpty) {
                                                _snack(
                                                  "Telefon giriniz",
                                                );
                                                return;
                                              }

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => OtpDogrulamaPage(
                                                    telefon: tel,
                                                  ),
                                                ),
                                              );
                                            },
                                  child:
                                      const Text(
                                    "Şifremi Unuttum",
                                    style:
                                        TextStyle(
                                      fontSize:
                                          10.8,
                                      color: Colors
                                          .black45,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 6),

                            // ==============================================
                            // GİRİŞ BUTONU
                            // ==============================================

                            SizedBox(
                              width:
                                  double.infinity,
                              height: 43,
                              child:
                                  ElevatedButton
                                      .icon(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : _login,
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
                                        BorderRadius.circular(
                                            10),
                                  ),
                                ),
                                icon:
                                    _isLoading
                                        ? const SizedBox(
                                            width: 15,
                                            height: 15,
                                            child:
                                                CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.login_rounded,
                                            size: 18,
                                          ),
                                label: Text(
                                  _isLoading
                                      ? "Giriş Yapılıyor..."
                                      : "Giriş Yap",
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        12.5,
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

                      const SizedBox(
                          height: 13),

                      // ==================================================
                      // FOOTER
                      // ==================================================

                      Center(
                        child: Text(
                          "Agronet Seracılık A.Ş",
                          style:
                              TextStyle(
                            fontSize: 9.5,
                            color: Colors
                                .black
                                .withOpacity(
                                    .28),
                            fontWeight:
                                FontWeight
                                    .w600,
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
      ),
    );
  }
}

// ============================================================================
// TELEFON FORMATTER
// ============================================================================

class TrPhoneFormatter10
    extends TextInputFormatter {
  const TrPhoneFormatter10({
    this.prefixMustBe505 = false,
  });

  final bool prefixMustBe505;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text
        .replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final d = digits.length > 10
        ? digits.substring(0, 10)
        : digits;

    final sb = StringBuffer();

    for (int i = 0; i < d.length; i++) {
      if (i == 3) sb.write(' ');
      if (i == 6) sb.write(' ');
      if (i == 8) sb.write(' ');

      sb.write(d[i]);
    }

    final text =
        sb.toString();

    return TextEditingValue(
      text: text,
      selection:
          TextSelection.collapsed(
        offset: text.length,
      ),
    );
  }
}