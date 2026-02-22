import 'dart:async';

import 'package:agronet/api/otp_api.dart';
import 'package:agronet/page/LoginPage/yeni_sifre_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpDogrulamaPage extends StatefulWidget {
  final String telefon; // login'den gelecek (ham hali olabilir)
  const OtpDogrulamaPage({super.key, required this.telefon});

  @override
  State<OtpDogrulamaPage> createState() => _OtpDogrulamaPageState();
}

class _OtpDogrulamaPageState extends State<OtpDogrulamaPage> {
  final _api = const SistemOtpApi();

  // OTP UI
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  String? _otpRef; // backend'den gelecek
  bool _loadingSend = false;
  bool _loadingVerify = false;
  String? _error;

  Timer? _timer;
  int _secondsLeft = 0; // resend için

  @override
  void initState() {
    super.initState();
    _sendOtp(); // sayfa açılır açılmaz gönder
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _loadingSend = true;
      _error = null;
    });

    try {
      final r = await _api.otpGonder(widget.telefon);

      if (!mounted) return;

      if (!r.ok) {
        setState(() {
          _otpRef = null;
          _error = r.msg.isEmpty ? 'Kod gönderilemedi' : r.msg;
        });
      } else {
        setState(() {
          _otpRef = r.otpRef;
          _error = null;
        });

        _startResendCountdown(60);

        // OTP kutularını temizle
        for (final c in _ctrls) c.clear();
        _nodes.first.requestFocus();

        // İstersen testte debugOtp varsa burada gösterebilirsin (normalde gösterme)
        // debugPrint('debugOtp: ${r.debugOtp}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _otpRef = null;
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingSend = false;
      });
    }
  }

  void _startResendCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  String _otpValue() {
    return _ctrls.map((e) => e.text.trim()).join();
  }

  bool get _otpComplete => _otpValue().length == 6;

  Future<void> _verifyOtp() async {
    if (_otpRef == null || _otpRef!.isEmpty) {
      setState(() => _error = 'Önce kod gönderilmeli');
      return;
    }

    final kod = _otpValue();
    if (kod.length != 6) {
      setState(() => _error = 'Lütfen 6 haneli kodu girin');
      return;
    }

    setState(() {
      _loadingVerify = true;
      _error = null;
    });

    try {
      final r = await _api.otpDogrula(otpRef: _otpRef!, kod: kod);

      if (!mounted) return;

      if (!r.ok) {
        setState(() => _error = r.msg.isEmpty ? 'Kod doğrulanamadı' : r.msg);
        return;
      }

     final resetToken = r.resetToken;
if (resetToken == null || resetToken.isEmpty) {
  setState(() => _error = 'Reset token alınamadı');
  return;
}

// ✅ Başarılı -> Yeni Şifre sayfasına geç
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => YeniSifrePage(
      resetToken: resetToken,
      telefon: widget.telefon,
    ),
  ),
);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loadingVerify = false);
    }
  }

  void _onChangedBox(int index, String v) {
    // sadece 1 karakter
    if (v.length > 1) {
      _ctrls[index].text = v.substring(v.length - 1);
      _ctrls[index].selection = TextSelection.fromPosition(
        const TextPosition(offset: 1),
      );
    }

    // ileri
    if (_ctrls[index].text.isNotEmpty && index < _nodes.length - 1) {
      _nodes[index + 1].requestFocus();
    }

    // son kutuya gelince otomatik doğrula (istersen kapat)
    if (_otpComplete) {
      FocusScope.of(context).unfocus();
      // _verifyOtp(); // istersen otomatik doğrulama aç
    }
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event, int index) {
    // backspace ile geri
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_ctrls[index].text.isEmpty && index > 0) {
        _nodes[index - 1].requestFocus();
        _ctrls[index - 1].clear();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = _loadingSend || _loadingVerify;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Doğrulama'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Telefon: ${widget.telefon}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SMS ile gelen 6 haneli kodu girin',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // OTP kutucuklar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 46,
                        child: Focus(
                          onKey: (node, event) => _onKey(node, event, i),
                          child: TextField(
                            controller: _ctrls[i],
                            focusNode: _nodes[i],
                            enabled: !busy,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (v) => _onChangedBox(i, v),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 12),

                  if (_error != null && _error!.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.25)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: busy ? null : _verifyOtp,
                      child: _loadingVerify
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Doğrula'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _secondsLeft > 0
                            ? 'Tekrar gönder: $_secondsLeft sn'
                            : 'Kod gelmedi mi?',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed: (busy || _secondsLeft > 0) ? null : _sendOtp,
                        child: _loadingSend
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Tekrar Gönder'),
                      ),
                    ],
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
