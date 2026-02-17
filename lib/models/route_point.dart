/// Model punktu na trasie
class RoutePoint {
  final String stationId;
  final String name;
  final Map<int, String> scheduleByCircuit; // Obieg -> godzina "HH:mm" (pierwszy kurs)
  final Map<int, String>? secondScheduleByCircuit; // Obieg -> godzina "HH:mm" (drugi kurs)
  final String? firstDepartureMonThu;
  final String? firstDepartureFriSat;
  final String? lastDepartureMonThu;
  final String? lastDepartureFriSat;

  const RoutePoint({
    required this.stationId,
    required this.name,
    required this.scheduleByCircuit,
    this.secondScheduleByCircuit,
    this.firstDepartureMonThu,
    this.firstDepartureFriSat,
    this.lastDepartureMonThu,
    this.lastDepartureFriSat,
  });

  /// Pobiera godzinę dla danego obiegu (pierwszy kurs)
  String? getScheduledTime(int circuit) {
    return scheduleByCircuit[circuit];
  }
  
  /// Pobiera godzinę drugiego kursu dla danego obiegu
  String? getSecondScheduledTime(int circuit) {
    return secondScheduleByCircuit?[circuit];
  }
  
  /// Pobiera wszystkie czasy dla danego obiegu (pierwszy i drugi kurs)
  List<String> getAllScheduledTimes(int circuit) {
    final times = <String>[];
    final first = scheduleByCircuit[circuit];
    final second = secondScheduleByCircuit?[circuit];
    if (first != null) times.add(first);
    if (second != null) times.add(second);
    return times;
  }
  
  /// Pobiera najbliższy czas odjazdu względem aktualnego czasu
  String? getNearestScheduledTime(DateTime now, int circuit) {
    final times = getAllScheduledTimes(circuit);
    if (times.isEmpty) return null;
    if (times.length == 1) return times[0];
    
    // Znajdź najbliższy czas (który jeszcze nie minął lub jest najbliższy)
    String? nearest;
    int minDiff = 999999;
    
    for (final time in times) {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      final diff = scheduled.difference(now).inSeconds;
      
      // Preferuj czasy w przyszłości lub w oknie aktywności (-59s do +2:59)
      if (diff >= -179 && diff.abs() < minDiff.abs()) {
        minDiff = diff;
        nearest = time;
      }
    }
    
    // Jeśli nie znaleziono, zwróć pierwszy czas
    return nearest ?? times[0];
  }

  /// Sprawdza czy aktualny czas jest w oknie czasowym (sprawdza oba kursy)
  /// Okno: od -59 sekund do +2:59 względem scheduledTime
  bool isInTimeWindow(DateTime now, int circuit) {
    final times = getAllScheduledTimes(circuit);
    if (times.isEmpty) return false;

    for (final time in times) {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      final windowStart = scheduled.subtract(const Duration(seconds: 59));
      final windowEnd = scheduled.add(const Duration(seconds: 179));

      if (now.isAfter(windowStart) && now.isBefore(windowEnd)) {
        return true;
      }
    }
    return false;
  }

  /// Zwraca status okna czasowego (sprawdza oba kursy, bierze najbliższy)
  TimeWindowStatus getTimeWindowStatus(DateTime now, int circuit) {
    final scheduledTime = getNearestScheduledTime(now, circuit);
    if (scheduledTime == null) return TimeWindowStatus.upcoming;

    final parts = scheduledTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    final windowStart = scheduled.subtract(const Duration(seconds: 59));
    final windowEnd = scheduled.add(const Duration(seconds: 179));
    // Dokładna minuta: od scheduled do scheduled + 59 sekund
    final exactMinuteEnd = scheduled.add(const Duration(seconds: 59));

    if (now.isBefore(windowStart)) {
      return TimeWindowStatus.upcoming;
    } else if (now.isAfter(windowEnd)) {
      return TimeWindowStatus.passed;
    } else if (now.isBefore(scheduled)) {
      // W oknie, ale przed godziną odjazdu - pomarańczowa
      return TimeWindowStatus.activeApproaching;
    } else if (now.isBefore(exactMinuteEnd) || now.isAtSameMomentAs(scheduled)) {
      // W dokładnej minucie (0-59 sekund po scheduled) - zielona
      return TimeWindowStatus.active;
    } else {
      // Po dokładnej minucie, ale jeszcze w oknie - pomarańczowa
      return TimeWindowStatus.activeSecondary;
    }
  }

  /// Czas do godziny rozkładowej (w sekundach, ujemny jeśli minęła) - bierze najbliższy kurs
  int secondsToScheduled(DateTime now, int circuit) {
    final scheduledTime = getNearestScheduledTime(now, circuit);
    if (scheduledTime == null) return 999999;

    final parts = scheduledTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final scheduled = DateTime(now.year, now.month, now.day, hour, minute);

    return scheduled.difference(now).inSeconds;
  }
}

enum TimeWindowStatus {
  upcoming, // Przed oknem
  active,   // W oknie, po lub w godzinie odjazdu - główna stacja (zielona)
  activeApproaching, // W oknie, ale przed godziną odjazdu (pomarańczowa)
  activeSecondary, // W oknie, po godzinie, ale nie główna stacja (pomarańczowa)
  passed,   // Po oknie
}

enum Direction {
  mlociny,
  kabaty,
}

/// Wrapper dla stacji w pełnym obiegu
/// Zawiera RoutePoint, kierunek i numer w sekwencji obiegu
class CircuitStop {
  final RoutePoint point;
  final Direction direction;
  final int sequenceNumber; // 0-40 dla 41 stacji w obiegu
  
  const CircuitStop({
    required this.point,
    required this.direction,
    required this.sequenceNumber,
  });
  
  /// Unikalny identyfikator w obiegu (np. "A1_mlociny" lub "A1_kabaty")
  String get uniqueId => '${point.stationId}_${direction.name}_$sequenceNumber';
}
