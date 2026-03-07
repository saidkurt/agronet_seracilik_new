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
  State<YeniSifrePage> createState() => _YeniSifrePageState();
}

class _YeniSifrePageState extends State<YeniSifrePage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF6F7F9);
  static const Color cardBg = Colors.white;

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

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? accent : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _maskedPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) return phone;
    final visible = digits.substring(digits.length - 4);
    return '••• ••• $visible';
  }

  String? _validatePass1(String? v) {
    final s = (v ?? '').trim();

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
    final s2 = (v ?? '').trim();

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

  Future<void> _kaydet() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      final r = await _api.yeniSifreKaydet(
        resetToken: widget.resetToken,
        yeniSifre: _pass1.text.trim(),
      );

      if (!mounted) return;

      if (!r.ok) {
        _snack(r.msg.isEmpty ? 'Şifre güncellenemedi' : r.msg);
        return;
      }

      _snack('Şifre güncellendi', success: true);

      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack('Bir hata oluştu: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
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
      suffixIcon: IconButton(
        onPressed: _loading ? null : onToggle,
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: const Text(
          'Yeni Şifre',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Şifre Yenileme',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_maskedPhone(widget.telefon)} numarası için yeni sayısal şifre belirleyin.',
                    style: const TextStyle(
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
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yeni Şifre Bilgileri',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Şifre yalnızca rakamlardan oluşmalıdır.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _pass1,
                      obscureText: _obscure1,
                      enabled: !_loading,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: _inputDecoration(
                        label: 'Yeni Şifre',
                        obscure: _obscure1,
                        onToggle: () {
                          setState(() => _obscure1 = !_obscure1);
                        },
                      ),
                      validator: _validatePass1,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pass2,
                      obscureText: _obscure2,
                      enabled: !_loading,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: _inputDecoration(
                        label: 'Yeni Şifre (Tekrar)',
                        obscure: _obscure2,
                        onToggle: () {
                          setState(() => _obscure2 = !_obscure2);
                        },
                      ),
                      validator: _validatePass2,
                      onFieldSubmitted: (_) => _loading ? null : _kaydet(),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.grey.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Şifreniz en az 6 haneli olmalı ve sadece sayılardan oluşmalıdır.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _kaydet,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _loading ? 'Kaydediliyor...' : 'Kaydet',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}