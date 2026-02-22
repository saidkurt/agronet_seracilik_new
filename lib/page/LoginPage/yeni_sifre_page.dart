import 'package:agronet/api/otp_api.dart'; // sende otp api dosyası adı bu görünüyor (otp_api.dart). Gerekirse düzelt.
import 'package:flutter/material.dart';

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
  final _api = const SistemOtpApi(); // sende sınıf adı SistemOtpApi ise
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

 String? _validatePass1(String? v) {
  final s = (v ?? '').trim();

  if (s.isEmpty) {
    return 'Yeni şifre boş olamaz';
  }

  if (s.length < 6) {
    return 'Şifre en az 6 haneli olmalı';
  }

  return null;
}

  String? _validatePass2(String? v) {
    final s2 = (v ?? '').trim();
    if (s2.isEmpty) return 'Şifre doğrulama boş olamaz';
    if (s2 != _pass1.text.trim()) return 'Şifreler aynı değil';
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

      _snack('Şifre güncellendi ✅');

      // Login'e geri dön: OTP + YeniŞifre sayfalarını kapat
      Navigator.pop(context); // YeniŞifre kapanır
      Navigator.pop(context); // OTP kapanır (Login'e döner)
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Şifre'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Telefon: ${widget.telefon}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _pass1,
                    obscureText: _obscure1,
                    enabled: !_loading,
                    decoration: InputDecoration(
                      labelText: 'Yeni Şifre',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() => _obscure1 = !_obscure1),
                        icon: Icon(
                          _obscure1 ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: _validatePass1,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pass2,
                    obscureText: _obscure2,
                    enabled: !_loading,
                    decoration: InputDecoration(
                      labelText: 'Yeni Şifre (Tekrar)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() => _obscure2 = !_obscure2),
                        icon: Icon(
                          _obscure2 ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: _validatePass2,
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _kaydet,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}