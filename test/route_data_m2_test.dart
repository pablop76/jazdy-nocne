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

  group('RouteDataM2: pierwsze odjazdy i ostatnie przejazdy', () {
    test('kierunek Bródno, C18: inaczej w dni robocze, sobotę i niedzielę', () {
      final c18 = station(Direction.kabaty, 'C18');
      expect(c18.firstDepartureMonThu, '05:17');
      expect(c18.firstDepartureSat, '05:10');
      expect(c18.firstDepartureSun, '05:00');
      expect(c18.lastDepartureMonThu, '00:45');
      expect(c18.lastDepartureFriSat, '02:40');
    });

    test('kierunek Bemowo, C18: w weekend pierwszy jest pociąg z C21', () {
      final c18 = station(Direction.mlociny, 'C18');
      expect(c18.firstDepartureMonThu, '05:00');
      expect(c18.firstDepartureSat, '05:06');
      expect(c18.firstDepartureSun, '05:06');
    });

    test('kierunek Bemowo, C4: ostatnia stacja kursu', () {
      final c4 = station(Direction.mlociny, 'C4');
      expect(c4.firstDepartureMonThu, '05:10');
      expect(c4.firstDepartureSat, '05:21');
      expect(c4.lastDepartureMonThu, '00:46');
      expect(c4.lastDepartureFriSat, '02:41');
    });

    test('każda stacja w obu kierunkach ma komplet godzin', () {
      for (final direction in Direction.values) {
        for (final point in RouteDataM2.getRoute(direction, DayType.friday)) {
          expect(point.firstDepartureMonThu, isNotNull, reason: point.name);
          expect(point.lastDepartureFriSat, isNotNull, reason: point.name);
        }
      }
    });
  });
}
