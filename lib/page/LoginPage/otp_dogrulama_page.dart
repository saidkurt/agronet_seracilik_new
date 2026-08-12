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
  State<OtpDogrulamaPage> createState() =>
      _OtpDogrulamaPageState();
}

class _OtpDogrulamaPageState
    extends State<OtpDogrulamaPage> {
  static const Color accent = Color(0xFF1E6F5C);
  static const Color bg = Color(0xFFF5F6F8);

  final _api = const SistemOtpApi();

  final List<TextEditingController> _ctrls =
      List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _nodes =
      List.generate(
    6,
    (_) => FocusNode(),
  );

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

  // ============================================================
  // OTP GÖNDER
  // ============================================================

  Future<void> _sendOtp() async {
    if (_loadingSend || _loadingVerify) {
      return;
    }

    setState(() {
      _loadingSend = true;
      _error = null;
    });

    try {
      final r =
          await _api.otpGonder(
        widget.telefon,
      );

      if (!mounted) return;

      if (!r.ok) {
        setState(() {
          _otpRef = null;

          _error = r.msg.isEmpty
              ? 'Kod gönderilemedi.'
              : r.msg;
        });

        return;
      }

      setState(() {
        _otpRef = r.otpRef;
        _error = null;
      });

      _startResendCountdown(60);

      for (final c in _ctrls) {
        c.clear();
      }

      _nodes.first.requestFocus();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _otpRef = null;
        _error =
            'Kod gönderilemedi: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSend = false;
        });
      }
    }
  }

  // ============================================================
  // GERİ SAYIM
  // ============================================================

  void _startResendCountdown(
    int seconds,
  ) {
    _timer?.cancel();

    setState(() {
      _secondsLeft = seconds;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) return;

        if (_secondsLeft <= 1) {
          timer.cancel();

          setState(() {
            _secondsLeft = 0;
          });
        } else {
          setState(() {
            _secondsLeft--;
          });
        }
      },
    );
  }

  // ============================================================
  // OTP
  // ============================================================

  String _otpValue() {
    return _ctrls
        .map((e) => e.text.trim())
        .join();
  }

  bool get _otpComplete =>
      _otpValue().length == 6;

  // ============================================================
  // DOĞRULA
  // ============================================================

  Future<void> _verifyOtp() async {
    if (_loadingVerify ||
        _loadingSend) {
      return;
    }

    if (_otpRef == null ||
        _otpRef!.isEmpty) {
      setState(() {
        _error =
            'Önce kod gönderilmeli.';
      });

      return;
    }

    final kod = _otpValue();

    if (kod.length != 6) {
      setState(() {
        _error =
            'Lütfen 6 haneli kodu girin.';
      });

      return;
    }

    setState(() {
      _loadingVerify = true;
      _error = null;
    });

    try {
      final r =
          await _api.otpDogrula(
        otpRef: _otpRef!,
        kod: kod,
      );

      if (!mounted) return;

      if (!r.ok) {
        setState(() {
          _error = r.msg.isEmpty
              ? 'Kod doğrulanamadı.'
              : r.msg;
        });

        return;
      }

      final resetToken =
          r.resetToken;

      if (resetToken == null ||
          resetToken.isEmpty) {
        setState(() {
          _error =
              'Reset token alınamadı.';
        });

        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              YeniSifrePage(
            resetToken: resetToken,
            telefon: widget.telefon,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            'Doğrulama hatası: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingVerify = false;
        });
      }
    }
  }

  // ============================================================
  // OTP BOX DEĞİŞİKLİĞİ
  // ============================================================

  void _onChangedBox(
    int index,
    String value,
  ) {
    if (value.length > 1) {
      final lastChar =
          value.characters.last;

      _ctrls[index].text =
          lastChar;

      _ctrls[index].selection =
          const TextSelection.collapsed(
        offset: 1,
      );
    }

    if (_ctrls[index].text.isNotEmpty &&
        index < _nodes.length - 1) {
      _nodes[index + 1]
          .requestFocus();
    }

    if (_otpComplete) {
      FocusScope.of(context)
          .unfocus();

      _verifyOtp();
    }
  }

  KeyEventResult _onKey(
    FocusNode node,
    RawKeyEvent event,
    int index,
  ) {
    if (event is RawKeyDownEvent &&
        event.logicalKey ==
            LogicalKeyboardKey
                .backspace) {
      if (_ctrls[index]
              .text
              .isEmpty &&
          index > 0) {
        _nodes[index - 1]
            .requestFocus();

        _ctrls[index - 1]
            .clear();

        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  // ============================================================
  // TELEFON MASK
  // ============================================================

  String _maskedPhone(
    String phone,
  ) {
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final busy =
        _loadingSend ||
            _loadingVerify;

    final scaler =
        MediaQuery.textScalerOf(context)
            .clamp(
      maxScaleFactor: 1.06,
    );

    return MediaQuery(
      data:
          MediaQuery.of(context)
              .copyWith(
        textScaler: scaler,
      ),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          toolbarHeight: 48,
          elevation: 0,
          backgroundColor:
              Colors.white,
          foregroundColor:
              Colors.black87,
          centerTitle: true,
          title: const Text(
            'Şifremi Unuttum',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets
                      .fromLTRB(
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
                    // ÜST İKON
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
                              .lock_outline_rounded,
                          size: 26,
                          color: accent,
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 10),

                    const Text(
                      'Kod Doğrulama',
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
                      '${_maskedPhone(widget.telefon)} numarasına SMS gönderildi.',
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
                    // OTP KARTI
                    // ============================================

                    Container(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        12,
                        13,
                        12,
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
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Doğrulama Kodu',
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
                            '6 haneli kodu girin. Tamamlanınca otomatik doğrulanır.',
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
                              height: 12),

                          // ======================================
                          // OTP BOX
                          // ======================================

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children:
                                List.generate(
                              6,
                              (i) {
                                final hasValue =
                                    _ctrls[i]
                                        .text
                                        .isNotEmpty;

                                return SizedBox(
                                  width: 43,
                                  height: 46,
                                  child: Focus(
                                    onKey: (
                                      node,
                                      event,
                                    ) =>
                                        _onKey(
                                      node,
                                      event,
                                      i,
                                    ),
                                    child:
                                        TextField(
                                      controller:
                                          _ctrls[i],
                                      focusNode:
                                          _nodes[i],
                                      enabled:
                                          !busy,
                                      keyboardType:
                                          TextInputType
                                              .number,
                                      textAlign:
                                          TextAlign
                                              .center,
                                      maxLength:
                                          1,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            18,
                                        fontWeight:
                                            FontWeight
                                                .w900,
                                        color: Colors
                                            .black87,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter
                                            .digitsOnly,
                                      ],
                                      decoration:
                                          InputDecoration(
                                        counterText:
                                            '',
                                        isDense:
                                            true,
                                        filled:
                                            true,
                                        fillColor: hasValue
                                            ? accent.withOpacity(.07)
                                            : const Color(0xFFF7F7F9),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical:
                                              10,
                                        ),
                                        border:
                                            OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(9),
                                          borderSide:
                                              BorderSide(
                                            color: Colors.black.withOpacity(.07),
                                          ),
                                        ),
                                        enabledBorder:
                                            OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(9),
                                          borderSide:
                                              BorderSide(
                                            color: hasValue
                                                ? accent.withOpacity(.35)
                                                : Colors.black.withOpacity(.07),
                                          ),
                                        ),
                                        focusedBorder:
                                            const OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.all(
                                            Radius.circular(9),
                                          ),
                                          borderSide:
                                              BorderSide(
                                            color:
                                                accent,
                                            width:
                                                1.3,
                                          ),
                                        ),
                                      ),
                                      onChanged:
                                          (v) {
                                        setState(
                                            () {});

                                        _onChangedBox(
                                          i,
                                          v,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // ======================================
                          // HATA
                          // ======================================

                          if (_error != null &&
                              _error!
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(
                                height: 9),

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
                                color: Colors.red
                                    .withOpacity(.06),
                                borderRadius:
                                    BorderRadius
                                        .circular(8),
                                border:
                                    Border.all(
                                  color: Colors.red
                                      .withOpacity(.18),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  const Icon(
                                    Icons
                                        .error_outline_rounded,
                                    color:
                                        Colors.red,
                                    size: 15,
                                  ),
                                  const SizedBox(
                                      width: 5),
                                  Expanded(
                                    child:
                                        Text(
                                      _error!,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.red,
                                        fontSize:
                                            10,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(
                              height: 10),

                          // ======================================
                          // DOĞRULA BUTONU
                          // ======================================

                          SizedBox(
                            width:
                                double.infinity,
                            height: 42,
                            child:
                                ElevatedButton
                                    .icon(
                              onPressed:
                                  busy
                                      ? null
                                      : _verifyOtp,
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
                                          .circular(9),
                                ),
                              ),
                              icon: _loadingVerify
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
                                          .check_circle_outline_rounded,
                                      size:
                                          18,
                                    ),
                              label: Text(
                                _loadingVerify
                                    ? 'Doğrulanıyor...'
                                    : 'Doğrula',
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

                          const SizedBox(
                              height: 8),

                          // ======================================
                          // TEKRAR SMS
                          // ======================================

                          Row(
                            children: [
                              Icon(
                                Icons
                                    .sms_outlined,
                                size: 16,
                                color: Colors
                                    .grey
                                    .shade600,
                              ),

                              const SizedBox(
                                  width: 5),

                              Expanded(
                                child: Text(
                                  _secondsLeft >
                                          0
                                      ? '$_secondsLeft sn sonra tekrar gönderilebilir.'
                                      : 'Kod gelmedi mi?',
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        9.8,
                                    color:
                                        Colors.black45,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),

                              TextButton(
                                style:
                                    TextButton
                                        .styleFrom(
                                  minimumSize:
                                      const Size(
                                    0,
                                    30,
                                  ),
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        5,
                                    vertical:
                                        2,
                                  ),
                                  foregroundColor:
                                      accent,
                                ),
                                onPressed: busy ||
                                        _secondsLeft >
                                            0
                                    ? null
                                    : _sendOtp,
                                child: _loadingSend
                                    ? const SizedBox(
                                        width:
                                            13,
                                        height:
                                            13,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                        ),
                                      )
                                    : const Text(
                                        'Tekrar Gönder',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              10.5,
                                          fontWeight:
                                              FontWeight.w900,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
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