import 'package:flutter_application_1/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
