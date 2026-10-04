import '../data/route_data.dart';

/// Wybór rozkładu (piątkowego albo sobotniego) na podstawie daty
class ScheduleDay {
  /// Noc należy do dnia, w którym się zaczęła: sobota 01:00 to jeszcze noc
  /// piątkowa. Poza piątkiem i sobotą zwraca rozkład najbliższej nocy z kursami.
  static DayType forTime(DateTime now) {
    final serviceDay = now.subtract(const Duration(hours: 4)).weekday;
    return serviceDay == DateTime.saturday ? DayType.saturday : DayType.friday;
  }
}
