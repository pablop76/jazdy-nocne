import 'package:flutter_application_1/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateService.apkUrlFor', () {
    const base = 'https://github.com/pablop76/jazdy-nocne/releases/download';
    // Kolejność jak w odpowiedzi GitHuba: alfabetycznie po nazwie
    final assets = [
      {
        'name': 'jazdy-nocne-32bit.apk',
        'browser_download_url': '$base/v2.6.1/jazdy-nocne-32bit.apk',
      },
      {
        'name': 'jazdy-nocne-x86_64.apk',
        'browser_download_url': '$base/v2.6.1/jazdy-nocne-x86_64.apk',
      },
      {
        'name': 'jazdy-nocne.apk',
        'browser_download_url': '$base/v2.6.1/jazdy-nocne.apk',
      },
    ];

    test('telefon 64-bitowy dostaje plik główny', () {
      expect(
        UpdateService.apkUrlFor(assets, 'arm64-v8a'),
        '$base/v2.6.1/jazdy-nocne.apk',
      );
    });

    test('telefon 32-bitowy dostaje plik 32-bitowy', () {
      expect(
        UpdateService.apkUrlFor(assets, 'armeabi-v7a'),
        '$base/v2.6.1/jazdy-nocne-32bit.apk',
      );
    });

    test('emulator dostaje plik x86_64', () {
      expect(
        UpdateService.apkUrlFor(assets, 'x86_64'),
        '$base/v2.6.1/jazdy-nocne-x86_64.apk',
      );
    });

    test('nieznana architektura dostaje plik główny', () {
      expect(
        UpdateService.apkUrlFor(assets, null),
        '$base/v2.6.1/jazdy-nocne.apk',
      );
    });

    test('brak pasującego pliku nie podsuwa innego', () {
      final onlyMain = [assets.last];
      expect(UpdateService.apkUrlFor(onlyMain, 'armeabi-v7a'), isNull);
      expect(UpdateService.apkUrlFor([], 'arm64-v8a'), isNull);
    });
  });

  group('UpdateService.isNewer', () {
    test('wyższy numer to nowsza wersja', () {
      expect(UpdateService.isNewer('2.6.1', '2.6.0'), isTrue);
      expect(UpdateService.isNewer('2.7.0', '2.6.9'), isTrue);
      expect(UpdateService.isNewer('3.0.0', '2.99.99'), isTrue);
    });

    test('porównuje liczby, a nie napisy', () {
      expect(UpdateService.isNewer('2.10.0', '2.9.0'), isTrue);
      expect(UpdateService.isNewer('2.9.0', '2.10.0'), isFalse);
    });

    test('ta sama lub starsza wersja nie jest nowsza', () {
      expect(UpdateService.isNewer('2.6.0', '2.6.0'), isFalse);
      expect(UpdateService.isNewer('2.5.9', '2.6.0'), isFalse);
      expect(UpdateService.isNewer('2.6', '2.6.0'), isFalse);
    });

    test('krótszy zapis uzupełnia zerami', () {
      expect(UpdateService.isNewer('2.7', '2.6.5'), isTrue);
    });

    test('nieczytelny numer nie wywołuje aktualizacji', () {
      expect(UpdateService.isNewer('', '2.6.0'), isFalse);
      expect(UpdateService.isNewer('beta', '2.6.0'), isFalse);
      expect(UpdateService.isNewer('2.6.0-rc1', '2.5.0'), isFalse);
    });
  });
}
