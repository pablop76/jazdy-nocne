import 'package:flutter_application_1/data/route_data.dart';
import 'package:flutter_application_1/models/route_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RoutePoint station(Direction direction, String id) => RouteData.getRoute(
    direction,
    DayType.saturday,
  ).firstWhere((point) => point.stationId == id);

  // Najpóźniejsza godzina kursów nocnych na stacji
  String lastNightTime(RoutePoint point) {
    final times = [
      ...point.scheduleByCircuit.values,
      ...?point.secondScheduleByCircuit?.values,
    ]..sort();
    return times.last;
  }

  group('RouteData (M1): pierwsze i ostatnie odjazdy', () {
    test('Stokłosy na Młociny: w weekend pierwszy pociąg rusza później', () {
      final a4 = station(Direction.mlociny, 'A4');
      expect(a4.firstDepartureMonThu, '05:00');
      expect(a4.firstDepartureWeekend, '05:06');
      expect(a4.lastDepartureMonThu, '00:12');
      expect(a4.lastDepartureFriSat, '02:03');
    });

    test('Wilanowska na Młociny: ta sama godzina we wszystkie dni', () {
      final a7 = station(Direction.mlociny, 'A7');
      expect(a7.firstDepartureMonThu, '05:00');
      expect(a7.firstDepartureWeekend, isNull);
    });

    test('Świętokrzyska na Kabaty', () {
      final a14 = station(Direction.kabaty, 'A14');
      expect(a14.firstDepartureMonThu, '05:07');
      expect(a14.lastDepartureMonThu, '00:28');
      expect(a14.lastDepartureFriSat, '02:34');
    });

    test('ostatni odjazd w piątek i sobotę to ostatni kurs nocny', () {
      for (final dayType in DayType.values) {
        for (final direction in Direction.values) {
          for (final point in RouteData.getRoute(direction, dayType)) {
            expect(
              point.lastDepartureFriSat,
              lastNightTime(point),
              reason: point.name,
            );
          }
        }
      }
    });
  });
}
