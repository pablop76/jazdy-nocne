import 'package:flutter_application_1/data/route_data.dart';
import 'package:flutter_application_1/data/route_data_m2.dart';
import 'package:flutter_application_1/models/route_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Direction.mlociny oznacza na M2 kierunek Bemowo, kabaty — Bródno
  RoutePoint station(Direction direction, String id) => RouteDataM2.getRoute(
    direction,
    DayType.friday,
  ).firstWhere((point) => point.stationId == id);

  group('RouteDataM2: pierwsze i ostatnie odjazdy', () {
    test('kierunek Bródno, C18', () {
      final c18 = station(Direction.kabaty, 'C18');
      expect(c18.firstDepartureMonThu, '05:17');
      expect(c18.lastDepartureMonThu, '00:45');
      expect(c18.lastDepartureFriSat, '02:40');
    });

    test('kierunek Bemowo, C9: pierwszy pociąg rusza ze stacji pośredniej', () {
      final c9 = station(Direction.mlociny, 'C9');
      expect(c9.firstDepartureMonThu, '05:00');
      expect(c9.lastDepartureMonThu, '00:36');
      expect(c9.lastDepartureFriSat, '02:31');
    });

    test('ostatni odjazd w piątek i sobotę to ostatni kurs nocny', () {
      for (final direction in Direction.values) {
        final times = direction == Direction.mlociny
            ? RouteDataM2.bemowoTimes
            : RouteDataM2.brodnoTimes;
        for (final point in RouteDataM2.getRoute(direction, DayType.friday)) {
          expect(
            point.lastDepartureFriSat,
            times[point.stationId]!.last,
            reason: point.name,
          );
        }
      }
    });

    test('każda stacja w obu kierunkach ma komplet godzin', () {
      for (final direction in Direction.values) {
        for (final point in RouteDataM2.getRoute(direction, DayType.friday)) {
          expect(point.firstDepartureMonThu, isNotNull, reason: point.name);
          expect(point.lastDepartureMonThu, isNotNull, reason: point.name);
        }
      }
    });
  });
}
