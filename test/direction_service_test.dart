import 'package:flutter_application_1/data/route_data.dart';
import 'package:flutter_application_1/data/route_data_m2.dart';
import 'package:flutter_application_1/models/route_point.dart';
import 'package:flutter_application_1/services/direction_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime at(int hour, int minute, [int second = 0]) =>
      DateTime(2026, 10, 3, hour, minute, second);

  List<CircuitRun> m1(int circuit) => DirectionService.runsFor({
    for (final direction in Direction.values)
      direction: RouteData.getRoute(direction, DayType.saturday),
  }, circuit);

  List<CircuitRun> m2(int circuit) => DirectionService.runsFor({
    for (final direction in Direction.values)
      direction: RouteDataM2.getRoute(direction, DayType.saturday),
  }, circuit);

  group('DirectionService.runsFor', () {
    test('obieg 1 na M1 jedzie na Młociny, na Kabaty i znów na Młociny', () {
      expect(m1(1).map((run) => run.direction), [
        Direction.mlociny,
        Direction.kabaty,
        Direction.mlociny,
      ]);
    });

    test('obieg 7 na M1 zaczyna w stronę Kabat', () {
      expect(m1(7).map((run) => run.direction), [
        Direction.kabaty,
        Direction.mlociny,
        Direction.kabaty,
      ]);
    });

    test('obieg bez kursów daje pustą listę', () {
      expect(m1(2), isEmpty);
    });

    test('kurs zna stację początkową, końcową i godziny', () {
      final second = m1(1)[1];
      expect(second.startStation, 'A23 - Młociny');
      expect(second.endStation, 'A1 - Kabaty');
      expect(DirectionService.formatMinutes(second.start), '01:03');
      expect(DirectionService.formatMinutes(second.end), '01:41');
    });
  });

  group('DirectionService.runAt', () {
    test('między kursami wskazuje ten, który ruszy jako następny', () {
      final runs = m1(1);
      expect(DirectionService.runAt(runs, at(0, 55)), same(runs[1]));
    });

    test('po ostatnim kursie nie ma żadnego', () {
      expect(DirectionService.runAt(m1(1), at(2, 38)), isNull);
    });
  });

  group('RoutePoint.secondsToWindowEnd', () {
    test('okno kończy się 2:59 po godzinie rozkładowej', () {
      // Obieg 1 odjeżdża z A1 Kabaty o 00:12
      final kabaty = RouteData.getRoute(
        Direction.mlociny,
        DayType.saturday,
      ).first;
      expect(kabaty.secondsToWindowEnd(at(0, 12), 1), 179);
      expect(kabaty.secondsToWindowEnd(at(0, 14, 59), 1), 0);
    });
  });

  group('DirectionService.directionAt', () {
    test('przed pierwszym kursem wskazuje jego kierunek', () {
      expect(DirectionService.directionAt(m1(1), at(0, 5)), Direction.mlociny);
      expect(DirectionService.directionAt(m1(7), at(0, 5)), Direction.kabaty);
    });

    test('w trakcie kursu wskazuje jego kierunek', () {
      expect(DirectionService.directionAt(m1(1), at(0, 30)), Direction.mlociny);
      expect(DirectionService.directionAt(m1(1), at(1, 20)), Direction.kabaty);
      expect(DirectionService.directionAt(m1(1), at(2, 10)), Direction.mlociny);
    });

    test('kierunek zmienia się po oknie czasowym stacji końcowej', () {
      // Obieg 1 kończy kurs na Młocinach o 00:50, okno trwa do 00:52:59
      expect(
        DirectionService.directionAt(m1(1), at(0, 52, 59)),
        Direction.mlociny,
      );
      expect(DirectionService.directionAt(m1(1), at(0, 53)), Direction.kabaty);
    });

    test('po ostatnim kursie i w dzień nie ma kierunku', () {
      expect(DirectionService.directionAt(m1(1), at(2, 38)), isNull);
      expect(DirectionService.directionAt(m1(1), at(12, 0)), isNull);
    });

    test('na M2 obieg 3 jedzie na Bemowo, na Bródno i znów na Bemowo', () {
      // Direction.mlociny oznacza na M2 kierunek Bemowo, kabaty — Bródno
      expect(DirectionService.directionAt(m2(3), at(0, 30)), Direction.mlociny);
      expect(DirectionService.directionAt(m2(3), at(1, 20)), Direction.kabaty);
      expect(DirectionService.directionAt(m2(3), at(2, 0)), Direction.mlociny);
    });
  });
}
