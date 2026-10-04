import 'package:flutter_application_1/data/route_data.dart';
import 'package:flutter_application_1/services/schedule_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2 października 2026 to piątek
  DateTime at(int day, int hour, [int minute = 0]) =>
      DateTime(2026, 10, day, hour, minute);

  group('ScheduleDay.forTime', () {
    test('piątek w dzień i wieczorem to rozkład piątkowy', () {
      expect(ScheduleDay.forTime(at(2, 12)), DayType.friday);
      expect(ScheduleDay.forTime(at(2, 23, 59)), DayType.friday);
    });

    test('noc z piątku na sobotę to nadal rozkład piątkowy', () {
      expect(ScheduleDay.forTime(at(3, 0, 30)), DayType.friday);
      expect(ScheduleDay.forTime(at(3, 3, 59)), DayType.friday);
    });

    test('sobota od 04:00 i noc na niedzielę to rozkład sobotni', () {
      expect(ScheduleDay.forTime(at(3, 4)), DayType.saturday);
      expect(ScheduleDay.forTime(at(3, 18)), DayType.saturday);
      expect(ScheduleDay.forTime(at(4, 2, 30)), DayType.saturday);
    });

    test('od niedzieli rana do piątku pokazuje najbliższy, piątkowy', () {
      expect(ScheduleDay.forTime(at(4, 4)), DayType.friday);
      expect(ScheduleDay.forTime(at(7, 1)), DayType.friday);
    });
  });
}
