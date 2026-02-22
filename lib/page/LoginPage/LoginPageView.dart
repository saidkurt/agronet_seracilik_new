import 'package:agronet/api/login_api.dart';
import 'package:agronet/models/login_user_model.dart';
import 'package:agronet/page/HomePage/GirisSayfaDrawer.dart';
import 'package:agronet/page/LoginPage/otp_dogrulama_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPageView extends StatefulWidget {
  const LoginPageView({super.key});

  @override
  State<LoginPageView> createState() => _LoginPageViewState();
}

class _LoginPageViewState extends State<LoginPageView> {
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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// "505 123 45 67" -> "5051234567"
  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  /// "5051234567" -> "505 123 45 67"
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
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final telDigits = _digitsOnly(_telCtrl.text.trim()); // 5051234567
    final sifre = _sifreCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      // ✅ UI endpoint bilmez -> sadece API çağırır
    final users = await LoginApi().girisTel(
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

      // ✅ DrawerPage yönlendirmesi model ile
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>  DrawerPageView(
      isimsoyisim: u.kullaniciadi,
      bileklikno: u.bileklikid,
      seraci: u.seraraporlarigorebilir,
      kontrolcu: u.kontrolcuraporlarigorebilir,
      yonetici: u.yonetimraporlarigorebilir,
      depopaketleme: u.depopaketleme,
      personelkodu: u.prosiskodu,
      deporaporlarinigorebilir: u.deporaporlarinigorebilir,
      tip: u.tip,
      danismanraporlari: u.danismanraporlari,
    ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _snack("Bağlantı hatası: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePref(String telDigits, String sifre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('TEL', telDigits); // digits sakla
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
      if (mounted) setState(() => _rememberMe = true);
    } else {
      if (mounted) setState(() => _rememberMe = false);
    }
  }

  void _onRememberChanged(bool value) async {
    setState(() => _rememberMe = value);
    if (!value) {
      // kapatınca temizle
      await _clearPref();
      if (!mounted) return;
      setState(() {
        _telCtrl.text = '';
        _sifreCtrl.text = '';
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
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),

                    // ✅ Logo
                    Center(
                      child: Image.asset(
                        "assets/agronet.png",
                        height: 160,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ Köşeli kart
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            color: Colors.black.withOpacity(0.06),
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          // ✅ Telefon
                          TextFormField(
                            controller: _telCtrl,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            inputFormatters: const [
                              TrPhoneFormatter10(prefixMustBe505: true),
                            ],
                            decoration: _dec(
                              hint: "Telefon (505 123 45 67)",
                              icon: Icons.phone,
                            ),
                            validator: (v) {
                              final digits = _digitsOnly(v ?? '');
                              if (digits.isEmpty) return "Telefon boş olamaz";
                              if (!_isValidTel(digits)) {
                                return "Telefon 10 hane olmalı !";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // ✅ Şifre
                          TextFormField(
                            controller: _sifreCtrl,
                            obscureText: _obscure,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _isLoading ? null : _login(),
                            decoration: _dec(
                              hint: "Şifre",
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure ? Icons.visibility : Icons.visibility_off,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if ((v ?? "").trim().isEmpty) return "Şifre boş olamaz";
                              return null;
                            },
                          ),

                          const SizedBox(height: 8),

                          // ✅ Beni Hatırla
                          Row(
                            children: [
                              Checkbox(
                                activeColor: Colors.red,
                                value: _rememberMe,
                                onChanged: (v) => _onRememberChanged(v ?? false),
                              ),
                              const Text("Beni Hatırla"),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // ✅ Kırmızı giriş
                          SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Giriş",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ✅ Şifremi Unuttum
                          Align(
                            alignment: Alignment.center,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                               
                                _snack("Şifre sıfırlama (OTP) sonraki adım ✅");
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: InkWell(
                                  onTap: () {
                                    
  final tel = _telCtrl.text.trim(); // senin controller adı neyse onu yaz

  if (tel.isEmpty) {
    _snack("Telefon giriniz");
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => OtpDogrulamaPage(telefon: tel),
    ),
  );
                                  },
                                  child: Text(
                                    "Şifremi Unuttum",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
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

/// ✅ 10 hane TR GSM -> "505 123 45 67"
class TrPhoneFormatter10 extends TextInputFormatter {
  const TrPhoneFormatter10({this.prefixMustBe505 = false});

  final bool prefixMustBe505;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // max 10
    var d = digits.length > 10 ? digits.substring(0, 10) : digits;

    // İstersen kullanıcı yanlış başlasa bile yazmaya devam edebilsin diye burada bloklamıyoruz.
    // Validasyon zaten form submit'te yakalayacak.

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