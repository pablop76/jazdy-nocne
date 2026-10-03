import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Nowsze wydanie aplikacji znalezione na GitHubie
class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.currentVersion,
    required this.apkUrl,
  });

  final String version;
  final String currentVersion;
  final String apkUrl;
}

/// Sprawdzanie, czy na GitHubie jest nowsze wydanie aplikacji
class UpdateService {
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/pablop76/jazdy-nocne/releases/latest';

  /// Wersja zainstalowanej aplikacji, np. 2.6.0
  static Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Zwraca nowsze wydanie albo null, gdy aplikacja jest aktualna
  /// lub sprawdzenie się nie udało (np. brak internetu)
  static Future<AppUpdate?> checkForUpdate() async {
    // Instalacja pobranego pliku APK działa tylko na Androidzie
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final current = await currentVersion();
      final response = await http
          .get(
            Uri.parse(_latestReleaseUrl),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final release = jsonDecode(response.body) as Map<String, dynamic>;
      final latest = (release['tag_name'] as String? ?? '').replaceFirst(
        RegExp(r'^v'),
        '',
      );
      if (!isNewer(latest, current)) return null;
      final assets = release['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final url =
            (asset as Map<String, dynamic>)['browser_download_url']
                as String? ??
            '';
        if (url.endsWith('.apk')) {
          return AppUpdate(
            version: latest,
            currentVersion: current,
            apkUrl: url,
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Porównuje numery wersji w postaci 2.6.0
  static bool isNewer(String candidate, String current) {
    final a = _parse(candidate);
    final b = _parse(current);
    if (a == null || b == null) return false;
    for (var i = 0; i < a.length || i < b.length; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  static List<int>? _parse(String version) {
    final parts = version.trim().split('.').map(int.tryParse).toList();
    if (parts.contains(null)) return null;
    return parts.cast<int>();
  }
}
