import 'package:flutter_application_1/data/route_data.dart';
import 'package:flutter_application_1/data/route_data_m2.dart';
import 'package:flutter_application_1/models/deadhead.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Zjazdy bez pasażerów', () {
    test('M1: obieg 3 zjeżdża z Kabat na Plac Wilsona', () {
      final stops = RouteData.deadheads[3]!;
      expect(stops.first.stationId, 'A1');
      expect(stops.first.time, '02:05:45');
      expect(stops.last.stationId, 'A18');
      expect(stops.last.time, '02:34:45');
    });

    test('M1: zjazd mają tylko obiegi 3, 4 i 6', () {
      expect(RouteData.deadheads.keys, [3, 4, 6]);
    });

    test('M2: obieg 10 ma zjazd tylko w piątek', () {
      final friday = RouteDataM2.getDeadhead(10, DayType.friday)!;
      expect(friday.first.time, '02:21:00');
      expect(friday.last.stationId, 'C18');
      expect(RouteDataM2.getDeadhead(10, DayType.saturday), isNull);
      expect(RouteDataM2.getDeadhead(3, DayType.friday), isNull);
    });

    test('godzina stacji uwzględnia sekundy', () {
      const stop = DeadheadStop('A1', '02:05:45');
      expect(
        stop.timeOn(DateTime(2026, 10, 3, 1, 59)),
        DateTime(2026, 10, 3, 2, 5, 45),
      );
    });

    test('stacje zjazdu są w kolejności godzin', () {
      final all = [
        ...RouteData.deadheads.values,
        ...RouteDataM2.deadheadsFriday.values,
      ];
      for (final stops in all) {
        final times = stops.map((s) => s.time).toList();
        expect(times, [...times]..sort());
      }
    });
  });
}
