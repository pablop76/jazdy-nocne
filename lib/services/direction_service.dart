import '../models/route_point.dart';

/// Kurs obiegu w jednym kierunku, od pierwszej do ostatniej stacji
class CircuitRun {
  const CircuitRun({
    required this.direction,
    required this.start,
    required this.end,
  });

  final Direction direction;
  final int start; // minuty od północy
  final int end;
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
      _addRun(runs, direction, points.map((p) => p.getScheduledTime(circuit)));
      _addRun(
        runs,
        direction,
        points.map((p) => p.getSecondScheduledTime(circuit)),
      );
    });
    runs.sort((a, b) => a.start.compareTo(b.start));
    return runs;
  }

  static void _addRun(
    List<CircuitRun> runs,
    Direction direction,
    Iterable<String?> times,
  ) {
    final minutes = [
      for (final time in times)
        if (time != null) _toMinutes(time),
    ]..sort();
    if (minutes.isEmpty) return;
    runs.add(
      CircuitRun(direction: direction, start: minutes.first, end: minutes.last),
    );
  }

  /// Kierunek kursu, który trwa albo ruszy jako następny.
  /// Zwraca null, gdy wszystkie kursy już minęły albo obieg nie ma kursów.
  static Direction? directionAt(List<CircuitRun> runs, DateTime now) {
    final seconds = now.hour * 3600 + now.minute * 60 + now.second;
    for (final run in runs) {
      // Kurs trwa do końca okna czasowego ostatniej stacji
      if (seconds <= run.end * 60 + _windowAfterSeconds) return run.direction;
    }
    return null;
  }

  static int _toMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
