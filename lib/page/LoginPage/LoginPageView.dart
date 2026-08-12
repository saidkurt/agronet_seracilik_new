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
  State<LoginPageView> createState() => _LoginPageViewState();
}

class _LoginPageViewState extends State<LoginPageView> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF6F7F9);
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

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? accent : Colors.red.shade600,
        ),
      );
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  String _formatTr10(String digits) {
    final d = _digitsOnly(digits);
    if (d.isEmpty) return '';
    final x = d.length > 10 ? d.substring(0, 10) : d;

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
    return RegExp(r'^\d{10}$').hasMatch(digits);
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final telDigits = _digitsOnly(_telCtrl.text.trim());
    final sifre = _sifreCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      final users = await _api.girisTel(
        telefon: telDigits,
        sifre: sifre,
      );

      if (users.isEmpty) {
        _snack("Kullanıcı bulunamadı");
        return;
      }

      final u = users.first;

      if (_rememberMe) {
        await _savePref(telDigits, sifre);
      } else {
        await _clearPref();
      }

      if (!mounted) return;

      await UpdateService.cihazKaydet(
  personelKodu: u.bsrKullaniciKodu,
);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeMenuPage(user: u),
        ),
        
      );
    } catch (e) {
      if (!mounted) return;
      _snack("Bağlantı hatası: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePref(String telDigits, String sifre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('TEL', telDigits);
    await prefs.setString('Sifre', sifre);
  }

  Future<void> _clearPref() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('TEL', '');
    await prefs.setString('Sifre', '');
  }

  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    final telDigits = prefs.getString('TEL') ?? '';
    final sifre = prefs.getString('Sifre') ?? '';

    if (telDigits.isNotEmpty) {
      _telCtrl.text = _formatTr10(telDigits);
      _sifreCtrl.text = sifre;
      if (mounted) {
        setState(() => _rememberMe = true);
      }
    } else {
      if (mounted) {
        setState(() => _rememberMe = false);
      }
    }
  }

  Future<void> _onRememberChanged(bool value) async {
    setState(() => _rememberMe = value);

    if (!value) {
      await _clearPref();
      if (!mounted) return;
      setState(() {
        _telCtrl.clear();
        _sifreCtrl.clear();
      });
    }
  }

  InputDecoration _dec({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: accent),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 18),

                    Center(
                      child: Image.asset(
                        "assets/agronet.png",
                        height: 130,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Agronet’e Hoş Geldiniz',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Telefon numaranız ve şifreniz ile giriş yaparak sisteme güvenli şekilde erişebilirsiniz.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giriş Bilgileri',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Telefon numaranızı 10 hane olarak girin.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 18),

                          TextFormField(
                            controller: _telCtrl,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            inputFormatters: const [
                              TrPhoneFormatter10(prefixMustBe505: true),
                            ],
                            decoration: _dec(
                              hint: "Telefon (505 123 45 67)",
                              icon: Icons.phone_android_rounded,
                            ),
                            validator: (v) {
                              final digits = _digitsOnly(v ?? '');
                              if (digits.isEmpty) {
                                return "Telefon boş olamaz";
                              }
                              if (!_isValidTel(digits)) {
                                return "Telefon 10 hane olmalı";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _sifreCtrl,
                            enabled: !_isLoading,
                            obscureText: _obscure,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_isLoading) {
                                _login();
                              }
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _dec(
                              hint: "Şifre",
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() => _obscure = !_obscure);
                                      },
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) {
                                return "Şifre boş olamaz";
                              }
                              if (!RegExp(r'^\d+$').hasMatch(s)) {
                                return "Şifre sadece rakamlardan oluşmalı";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: _isLoading
                                      ? null
                                      : (v) => _onRememberChanged(v ?? false),
                                ),
                                const SizedBox(width: 4),
                                const Expanded(
                                  child: Text(
                                    "Beni Hatırla",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: Text(
                                _isLoading ? "Giriş Yapılıyor..." : "Giriş Yap",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Center(
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      final tel = _telCtrl.text.trim();

                                      if (tel.isEmpty) {
                                        _snack("Telefon giriniz");
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
                              child: Text(
                                "Şifremi Unuttum",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.grey.shade700,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
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

class TrPhoneFormatter10 extends TextInputFormatter {
  const TrPhoneFormatter10({this.prefixMustBe505 = false});

  final bool prefixMustBe505;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final d = digits.length > 10 ? digits.substring(0, 10) : digits;

    final sb = StringBuffer();
    for (int i = 0; i < d.length; i++) {
      if (i == 3) sb.write(' ');
      if (i == 6) sb.write(' ');
      if (i == 8) sb.write(' ');
      sb.write(d[i]);
    }

    final text = sb.toString();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}