import '../models/route_point.dart';

/// Kurs obiegu w jednym kierunku, od pierwszej do ostatniej stacji
class CircuitRun {
  const CircuitRun({
    required this.direction,
    required this.start,
    required this.end,
    required this.startStation,
    required this.endStation,
  });

  final Direction direction;
  final int start; // minuty od północy
  final int end;
  final String startStation; // nazwa stacji, z której kurs rusza
  final String endStation;
}

/// Ustalanie, w którą stronę obieg jedzie o danej godzinie
class DirectionService {
  // Tyle sekund po godzinie rozkładowej stacja jest jeszcze w oknie czasowym
  static const int _windowAfterSeconds = 179;

  /// Kursy obiegu w obu kierunkach, w kolejności odjazdów.
  /// [routes] to stacje z godzinami dla każdego kierunku.
  static List<CircuitRun> runsFor(
    Map<Direction, List<RoutePoint>> routes,
    int circuit,
  ) {
    final runs = <CircuitRun>[];
    routes.forEach((direction, points) {
      _addRun(runs, direction, points, (p) => p.getScheduledTime(circuit));
      _addRun(
        runs,
        direction,
        points,
        (p) => p.getSecondScheduledTime(circuit),
      );
    });
    runs.sort((a, b) => a.start.compareTo(b.start));
    return runs;
  }

  static void _addRun(
    List<CircuitRun> runs,
    Direction direction,
    List<RoutePoint> points,
    String? Function(RoutePoint) timeOf,
  ) {
    // Stacje kursu z godzinami, od najwcześniejszej
    final stops = [
      for (final point in points)
        if (timeOf(point) case final time?) (_toMinutes(time), point.name),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    if (stops.isEmpty) return;
    runs.add(
      CircuitRun(
        direction: direction,
        start: stops.first.$1,
        end: stops.last.$1,
        startStation: stops.first.$2,
        endStation: stops.last.$2,
      ),
    );
  }

  /// Kurs, który trwa albo ruszy jako następny.
  /// Zwraca null, gdy wszystkie kursy już minęły albo obieg nie ma kursów.
  static CircuitRun? runAt(List<CircuitRun> runs, DateTime now) {
    final seconds = now.hour * 3600 + now.minute * 60 + now.second;
    for (final run in runs) {
      // Kurs trwa do końca okna czasowego ostatniej stacji
      if (seconds <= run.end * 60 + _windowAfterSeconds) return run;
    }
    return null;
  }

  /// Kierunek kursu, który trwa albo ruszy jako następny
  static Direction? directionAt(List<CircuitRun> runs, DateTime now) {
    return runAt(runs, now)?.direction;
  }

  /// Minuty od północy zapisane jako godzina, np. 78 -> 01:18
  static String formatMinutes(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static int _toMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
