import 'dart:io';
import 'dart:math';

import 'package:agronet/const/string.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateService {
  static  String baseUrl = App.outsideurl;

  static const Color accent = Color(0xFF1E6F5C);

  static Future<String> _cihazIdGetir() async {
    final prefs = await SharedPreferences.getInstance();

    var cihazId = prefs.getString('agronet_cihaz_id');

    if (cihazId != null && cihazId.isNotEmpty) {
      return cihazId;
    }

    final random = Random.secure();

    cihazId =
        '${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(999999999)}';

    await prefs.setString(
      'agronet_cihaz_id',
      cihazId,
    );

    return cihazId;
  }

  static Future<void> cihazKaydet({
    String? personelKodu,
  }) async {
    try {
      final packageInfo =
          await PackageInfo.fromPlatform();

      final deviceInfo = DeviceInfoPlugin();

      final androidInfo =
          await deviceInfo.androidInfo;

      final cihazId =
          await _cihazIdGetir();

      final versionCode =
          int.tryParse(
            packageInfo.buildNumber,
          ) ??
          0;

      final data = {
        'cihazId': cihazId,
        'cihazAdi':
            '${androidInfo.manufacturer} ${androidInfo.model}',
        'personelKodu':
            personelKodu ?? '',
        'marka':
            androidInfo.manufacturer,
        'model':
            androidInfo.model,
        'versionName':
            packageInfo.version,
        'versionCode':
            versionCode,
      };

      await Dio().post(
        '$baseUrl/Update/Device',
        data: data,
      );

      debugPrint(
        'Cihaz kaydedildi: '
        '${packageInfo.version}+${packageInfo.buildNumber}',
      );
    } catch (e) {
      debugPrint(
        'Cihaz kayıt hatası: $e',
      );
    }
  }

  static Future<void> guncellemeKontrolEt(
    BuildContext context,
  ) async {
    try {
      final packageInfo =
          await PackageInfo.fromPlatform();

      final mevcutVersionCode =
          int.tryParse(
            packageInfo.buildNumber,
          ) ??
          0;

      final response = await Dio().get(
        '$baseUrl/Update/Version',
      );

      final data = response.data;

      final yeniVersionCode =
          int.tryParse(
            data['versionCode'].toString(),
          ) ??
          0;

      final yeniVersionName =
          data['versionName']
                  ?.toString() ??
              '';

      final zorunlu =
          data['zorunlu'] == true;

      final apkUrl =
          data['apkUrl']
                  ?.toString() ??
              '';

      debugPrint(
        'Telefon: $mevcutVersionCode - '
        'Sunucu: $yeniVersionCode',
      );

      if (yeniVersionCode <=
          mevcutVersionCode) {
        return;
      }

      if (!context.mounted) {
        return;
      }

      await _guncellemeDialogGoster(
        context: context,
        yeniVersionName:
            yeniVersionName,
        zorunlu: zorunlu,
        apkUrl: apkUrl,
      );
    } catch (e) {
      debugPrint(
        'Güncelleme kontrol hatası: $e',
      );
    }
  }

  // ============================================================
  // GÜNCELLEME BULUNDU DIALOG
  // ============================================================

  static Future<void>
      _guncellemeDialogGoster({
    required BuildContext context,
    required String yeniVersionName,
    required bool zorunlu,
    required String apkUrl,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: !zorunlu,
      builder: (dialogContext) {
        return PopScope(
          canPop: !zorunlu,
          child: Dialog(
            backgroundColor:
                Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(
              horizontal: 28,
            ),
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                border: Border.all(
                  color: Colors.black
                      .withOpacity(.04),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(.10),
                    blurRadius: 24,
                    offset:
                        const Offset(
                      0,
                      10,
                    ),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      color: accent
                          .withOpacity(.10),
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .system_update_alt_rounded,
                      color: accent,
                      size: 26,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    'Yeni Güncelleme',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    'Agronet $yeniVersionName sürümü hazır.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          FontWeight.w600,
                      color: Colors.black
                          .withOpacity(.55),
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    zorunlu
                        ? 'Devam etmek için uygulamayı güncellemeniz gerekiyor.'
                        : 'Yeni sürümü şimdi yükleyebilirsiniz.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      fontWeight:
                          FontWeight.w500,
                      color: Colors.black
                          .withOpacity(.38),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  Row(
                    children: [
                      if (!zorunlu)
                        Expanded(
                          child:
                              OutlinedButton(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },
                            style:
                                OutlinedButton
                                    .styleFrom(
                              foregroundColor:
                                  Colors
                                      .black87,
                              side: BorderSide(
                                color: Colors
                                    .black
                                    .withOpacity(
                                  .10,
                                ),
                              ),
                              minimumSize:
                                  const Size
                                      .fromHeight(
                                42,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  11,
                                ),
                              ),
                            ),
                            child:
                                const Text(
                              'Daha Sonra',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                      if (!zorunlu)
                        const SizedBox(
                          width: 8,
                        ),

                      Expanded(
                        child:
                            FilledButton.icon(
                          onPressed: () async {
                            Navigator.pop(
                              dialogContext,
                            );

                            await _indirVeKur(
                              context,
                              apkUrl,
                            );
                          },
                          style:
                              FilledButton
                                  .styleFrom(
                            backgroundColor:
                                accent,
                            foregroundColor:
                                Colors.white,
                            minimumSize:
                                const Size
                                    .fromHeight(
                              42,
                            ),
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                11,
                              ),
                            ),
                          ),
                          icon: const Icon(
                            Icons
                                .download_rounded,
                            size: 18,
                          ),
                          label:
                              const Text(
                            'Güncelle',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // APK İNDİR + KUR
  // ============================================================

  static Future<void> _indirVeKur(
    BuildContext context,
    String apkUrl,
  ) async {
    BuildContext? dialogContext;

    try {
      var url = apkUrl;

      if (!url.startsWith(
        'http',
      )) {
        url = '$baseUrl$url';
      }

      final directory =
          await getTemporaryDirectory();

      final apkPath =
          '${directory.path}/agronet_update.apk';

      final apkFile =
          File(apkPath);

      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      if (!context.mounted) {
        return;
      }

      double progress = 0.0;

      int receivedBytes = 0;
      int totalBytes = 0;

      StateSetter?
          dialogSetState;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;

          return StatefulBuilder(
            builder: (
              context,
              setState,
            ) {
              dialogSetState =
                  setState;

              final int yuzde =
                  totalBytes > 0
                      ? (progress * 100)
                          .round()
                      : 0;

              final String
                  indirilenMb =
                  (receivedBytes /
                          1024 /
                          1024)
                      .toStringAsFixed(
                    1,
                  );

              final String toplamMb =
                  totalBytes > 0
                      ? (totalBytes /
                              1024 /
                              1024)
                          .toStringAsFixed(
                          1,
                        )
                      : '...';

              return PopScope(
                canPop: false,
                child: Dialog(
                  backgroundColor:
                      Colors
                          .transparent,
                  insetPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 28,
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      18,
                      18,
                      18,
                      16,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                      border: Border.all(
                        color: Colors
                            .black
                            .withOpacity(
                          .04,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors
                              .black
                              .withOpacity(
                            .10,
                          ),
                          blurRadius:
                              24,
                          offset:
                              const Offset(
                            0,
                            10,
                          ),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize
                              .min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration:
                                  BoxDecoration(
                                color: accent
                                    .withOpacity(
                                  .10,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .downloading_rounded,
                                color:
                                    accent,
                                size: 22,
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  const Text(
                                    'Güncelleme İndiriliyor',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          14,
                                      fontWeight:
                                          FontWeight
                                              .w900,
                                    ),
                                  ),
                                  const SizedBox(
                                    height:
                                        2,
                                  ),
                                  Text(
                                    'Lütfen bekleyin...',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          10.5,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                      color: Colors
                                          .black
                                          .withOpacity(
                                        .45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    9,
                                vertical:
                                    5,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: accent
                                    .withOpacity(
                                  .08,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                              ),
                              child: Text(
                                '%$yuzde',
                                style:
                                    const TextStyle(
                                  fontSize:
                                      11,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                  color:
                                      accent,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                          child:
                              LinearProgressIndicator(
                            value:
                                totalBytes >
                                        0
                                    ? progress
                                    : null,
                            minHeight: 8,
                            backgroundColor:
                                Colors.black
                                    .withOpacity(
                              .06,
                            ),
                            valueColor:
                                const AlwaysStoppedAnimation<
                                    Color>(
                              accent,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            Text(
                              '$indirilenMb MB indirildi',
                              style:
                                  TextStyle(
                                fontSize:
                                    10.5,
                                fontWeight:
                                    FontWeight
                                        .w700,
                                color: Colors
                                    .black
                                    .withOpacity(
                                  .55,
                                ),
                              ),
                            ),

                            Text(
                              '$toplamMb MB',
                              style:
                                  TextStyle(
                                fontSize:
                                    10.5,
                                fontWeight:
                                    FontWeight
                                        .w700,
                                color: Colors
                                    .black
                                    .withOpacity(
                                  .55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      await Dio().download(
        url,
        apkPath,
        options: Options(
          receiveTimeout:
              const Duration(
            minutes: 10,
          ),
        ),
        onReceiveProgress: (
          received,
          total,
        ) {
          receivedBytes =
              received;

          totalBytes =
              total;

          if (total > 0) {
            progress =
                received /
                    total;
          }

          dialogSetState?.call(
            () {},
          );
        },
      );

      if (dialogContext != null &&
          dialogContext!.mounted) {
        Navigator.of(
          dialogContext!,
        ).pop();
      }

      if (!context.mounted) {
        return;
      }

      await _indirmeTamamlandiDialog(
        context,
      );

      await OpenFilex.open(
        apkPath,
        type:
            'application/vnd.android.package-archive',
      );
    } catch (e) {
      debugPrint(
        'APK indirme hatası: $e',
      );

      if (dialogContext != null &&
          dialogContext!.mounted) {
        Navigator.of(
          dialogContext!,
        ).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            behavior:
                SnackBarBehavior
                    .floating,
            content: Text(
              'Güncelleme indirilemedi: $e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // İNDİRME TAMAMLANDI
  // ============================================================

  static Future<void>
      _indirmeTamamlandiDialog(
    BuildContext context,
  ) async {
    if (!context.mounted) {
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(
          const Duration(
            milliseconds: 850,
          ),
          () {
            if (dialogContext
                .mounted) {
              Navigator.of(
                dialogContext,
              ).pop();
            }
          },
        );

        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor:
                Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(
              horizontal: 42,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(.10),
                    blurRadius: 24,
                    offset:
                        const Offset(
                      0,
                      10,
                    ),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration:
                        BoxDecoration(
                      color: accent
                          .withOpacity(.10),
                      shape:
                          BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons
                          .check_rounded,
                      color: accent,
                      size: 25,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'İndirme Tamamlandı',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    'Kurulum hazırlanıyor...',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                          FontWeight.w600,
                      color: Colors.black
                          .withOpacity(.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}