import 'dart:async';

import 'package:agronet/api/otp_api.dart';
import 'package:agronet/page/LoginPage/yeni_sifre_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpDogrulamaPage extends StatefulWidget {
  final String telefon;

  const OtpDogrulamaPage({
    super.key,
    required this.telefon,
  });

  @override
  State<OtpDogrulamaPage> createState() => _OtpDogrulamaPageState();
}

class _OtpDogrulamaPageState extends State<OtpDogrulamaPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF6F7F9);
  static const Color cardBg = Colors.white;

  final _api = const SistemOtpApi();

  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  String? _otpRef;
  bool _loadingSend = false;
  bool _loadingVerify = false;
  String? _error;

  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_loadingSend || _loadingVerify) return;

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
          _error = r.msg.isEmpty ? 'Kod gönderilemedi.' : r.msg;
        });
      } else {
        setState(() {
          _otpRef = r.otpRef;
          _error = null;
        });

        _startResendCountdown(60);

        for (final c in _ctrls) {
          c.clear();
        }

        _nodes.first.requestFocus();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _otpRef = null;
        _error = 'Bir hata oluştu: $e';
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

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_secondsLeft <= 1) {
        timer.cancel();
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
    if (_loadingVerify || _loadingSend) return;

    if (_otpRef == null || _otpRef!.isEmpty) {
      setState(() => _error = 'Önce kod gönderilmeli.');
      return;
    }

    final kod = _otpValue();
    if (kod.length != 6) {
      setState(() => _error = 'Lütfen 6 haneli kodu girin.');
      return;
    }

    setState(() {
      _loadingVerify = true;
      _error = null;
    });

    try {
      final r = await _api.otpDogrula(
        otpRef: _otpRef!,
        kod: kod,
      );

      if (!mounted) return;

      if (!r.ok) {
        setState(() {
          _error = r.msg.isEmpty ? 'Kod doğrulanamadı.' : r.msg;
        });
        return;
      }

      final resetToken = r.resetToken;
      if (resetToken == null || resetToken.isEmpty) {
        setState(() => _error = 'Reset token alınamadı.');
        return;
      }

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
      setState(() {
        _error = 'Bir hata oluştu: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingVerify = false;
      });
    }
  }

  void _onChangedBox(int index, String value) {
    if (value.length > 1) {
      final lastChar = value.characters.last;
      _ctrls[index].text = lastChar;
      _ctrls[index].selection = const TextSelection.collapsed(offset: 1);
    }

    if (_ctrls[index].text.isNotEmpty && index < _nodes.length - 1) {
      _nodes[index + 1].requestFocus();
    }

    if (_otpComplete) {
      FocusScope.of(context).unfocus();
      _verifyOtp();
    }
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event, int index) {
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

  String _maskedPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) return phone;
    final visible = digits.substring(digits.length - 4);
    return '••• ••• $visible';
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loadingSend || _loadingVerify;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: const Text(
          'Şifremi Unuttum',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Kod Doğrulama',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Telefonunuza gönderilen 6 haneli doğrulama kodunu girin. Kod tamamlanınca doğrulama otomatik yapılır.',
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
                borderRadius: BorderRadius.circular(20),
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
                    'Doğrulama Kodu',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_maskedPhone(widget.telefon)} numarasına SMS gönderildi.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      final hasValue = _ctrls[i].text.isNotEmpty;

                      return SizedBox(
                        width: 48,
                        child: Focus(
                          onKey: (node, event) => _onKey(node, event, i),
                          child: TextField(
                            controller: _ctrls[i],
                            focusNode: _nodes[i],
                            enabled: !busy,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: hasValue
                                  ? accent.withOpacity(0.08)
                                  : Colors.grey.shade50,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: hasValue
                                      ? accent.withOpacity(0.45)
                                      : Colors.grey.shade300,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: accent,
                                  width: 1.6,
                                ),
                              ),
                            ),
                            onChanged: (v) {
                              setState(() {});
                              _onChangedBox(i, v);
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: (_error != null && _error!.trim().isNotEmpty)
                        ? Container(
                            key: const ValueKey('error_box'),
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 1),
                                  child: Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (_error != null && _error!.trim().isNotEmpty)
                    const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: busy ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _loadingVerify
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        _loadingVerify ? 'Doğrulanıyor...' : 'Doğrula',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sms_outlined,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _secondsLeft > 0
                                ? 'Kod gelmediyse $_secondsLeft saniye sonra tekrar gönderebilirsiniz.'
                                : 'Kod gelmedi mi? Tekrar SMS gönderebilirsiniz.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed:
                              (busy || _secondsLeft > 0) ? null : _sendOtp,
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                          ),
                          child: _loadingSend
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Tekrar Gönder',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ],
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