class OtpGonderResponse {
  final bool ok;
  final String msg;
  final String? otpRef; // guid string
  final String? debugOtp; // eğer backend testte döndürürse

  OtpGonderResponse({
    required this.ok,
    required this.msg,
    this.otpRef,
    this.debugOtp,
  });

  factory OtpGonderResponse.fromJson(Map<String, dynamic> j) {
    return OtpGonderResponse(
      ok: (j['ok'] ?? false) == true,
      msg: (j['msg'] ?? '').toString(),
      otpRef: j['otpRef']?.toString(),
      debugOtp: j['debugOtp']?.toString(),
    );
  }
}

class OtpDogrulaResponse {
  final bool ok;
  final String msg;
  final String? resetToken; // guid string

  OtpDogrulaResponse({
    required this.ok,
    required this.msg,
    this.resetToken,
  });

  factory OtpDogrulaResponse.fromJson(Map<String, dynamic> j) {
    return OtpDogrulaResponse(
      ok: (j['ok'] ?? false) == true,
      msg: (j['msg'] ?? '').toString(),
      resetToken: j['resetToken']?.toString(),
    );
  }
}

class YeniSifreResponse {
  final bool ok;
  final String msg;

  YeniSifreResponse({
    required this.ok,
    required this.msg,
  });

  factory YeniSifreResponse.fromJson(Map<String, dynamic> j) {
    return YeniSifreResponse(
      ok: (j['ok'] ?? false) == true,
      msg: (j['msg'] ?? '').toString(),
    );
  }
}