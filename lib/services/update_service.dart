import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateService {
  static const String baseUrl = 'http://192.0.0.251:2626';

  static Future<String> _cihazIdGetir() async {
    final prefs = await SharedPreferences.getInstance();

    var cihazId = prefs.getString('agronet_cihaz_id');

    if (cihazId != null && cihazId.isNotEmpty) {
      return cihazId;
    }

    final random = Random.secure();

    cihazId =
        '${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(999999999)}';

    await prefs.setString('agronet_cihaz_id', cihazId);

    return cihazId;
  }

  static Future<void> cihazKaydet({
    String? personelKodu,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      final cihazId = await _cihazIdGetir();

      final versionCode =
          int.tryParse(packageInfo.buildNumber) ?? 0;

      final data = {
        'cihazId': cihazId,
        'cihazAdi':
            '${androidInfo.manufacturer} ${androidInfo.model}',
        'personelKodu': personelKodu ?? '',
        'marka': androidInfo.manufacturer,
        'model': androidInfo.model,
        'versionName': packageInfo.version,
        'versionCode': versionCode,
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
      debugPrint('Cihaz kayıt hatası: $e');
    }
  }

  static Future<void> guncellemeKontrolEt(
    BuildContext context,
  ) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      final mevcutVersionCode =
          int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await Dio().get(
        '$baseUrl/Update/Version',
      );

      final data = response.data;

      final yeniVersionCode =
          int.tryParse(data['versionCode'].toString()) ?? 0;

      final yeniVersionName =
          data['versionName']?.toString() ?? '';

      final zorunlu =
          data['zorunlu'] == true;

      final apkUrl =
          data['apkUrl']?.toString() ?? '';

      debugPrint(
        'Telefon: $mevcutVersionCode - '
        'Sunucu: $yeniVersionCode',
      );

      if (yeniVersionCode <= mevcutVersionCode) {
        return;
      }

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: !zorunlu,
        builder: (dialogContext) {
          return PopScope(
            canPop: !zorunlu,
            child: AlertDialog(
              title: const Text('Yeni Güncelleme'),
              content: Text(
                'Agronet $yeniVersionName sürümü hazır.',
              ),
              actions: [
                if (!zorunlu)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Daha Sonra'),
                  ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    await _indirVeKur(
                      context,
                      apkUrl,
                    );
                  },
                  child: const Text('Güncelle'),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Güncelleme kontrol hatası: $e',
      );
    }
  }

  static Future<void> _indirVeKur(
  BuildContext context,
  String apkUrl,
) async {
  BuildContext? dialogContext;

  try {
    var url = apkUrl;

    if (!url.startsWith('http')) {
      url = '$baseUrl$url';
    }

    final directory = await getTemporaryDirectory();
    final apkPath = '${directory.path}/agronet_update.apk';

    if (!context.mounted) return;

    double progress = 0.0;
    int receivedBytes = 0;
    int totalBytes = 0;

    StateSetter? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;

        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;

            final int yuzde =
                totalBytes > 0 ? (progress * 100).round() : 0;

            final String indirilenMb =
                (receivedBytes / 1024 / 1024).toStringAsFixed(1);

            final String toplamMb = totalBytes > 0
                ? (totalBytes / 1024 / 1024).toStringAsFixed(1)
                : '...';

            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text(
                  'Güncelleme İndiriliyor',
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: totalBytes > 0 ? progress : null,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      '%$yuzde',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '$indirilenMb MB / $toplamMb MB',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
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
      onReceiveProgress: (received, total) {
        receivedBytes = received;
        totalBytes = total;

        if (total > 0) {
          progress = received / total;
        }

        dialogSetState?.call(() {});
      },
    );

    if (dialogContext != null &&
        dialogContext!.mounted) {
      Navigator.of(dialogContext!).pop();
    }

    await OpenFilex.open(
      apkPath,
      type: 'application/vnd.android.package-archive',
    );
  } catch (e) {
    debugPrint('APK indirme hatası: $e');

    if (dialogContext != null &&
        dialogContext!.mounted) {
      Navigator.of(dialogContext!).pop();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Güncelleme indirilemedi: $e',
          ),
        ),
      );
    }
  }
}
}