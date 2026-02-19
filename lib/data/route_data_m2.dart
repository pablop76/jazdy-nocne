import '../models/route_point.dart';
import 'route_data.dart';

/// Rozkład jazdy metra M2 - nocny
/// Uwaga: godziny są takie same dla piątku i soboty,
/// zmienia się tylko przypisanie obiegów.
class RouteDataM2 {
  static const Map<String, String> stationNames = {
    'C4': 'C4 - Bemowo',
    'C5': 'C5 - Ulrychów',
    'C6': 'C6 - Księcia Janusza',
    'C7': 'C7 - Młynów',
    'C8': 'C8 - Płocka',
    'C9': 'C9 - Rondo Daszyńskiego',
    'C10': 'C10 - Rondo ONZ',
    'C11': 'C11 - Świętokrzyska',
    'C12': 'C12 - Nowy Świat-Uniwersytet',
    'C13': 'C13 - Centrum Nauki Kopernik',
    'C14': 'C14 - Stadion Narodowy',
    'C15': 'C15 - Dworzec Wileński',
    'C16': 'C16 - Szwedzka',
    'C17': 'C17 - Targówek Mieszkaniowy',
    'C18': 'C18 - Trocka',
    'C19': 'C19 - Zacisze',
    'C20': 'C20 - Kondratowicza',
    'C21': 'C21 - Bródno',
  };

  // Kierunek Bródno: C4 -> C21
  static const List<String> stationsToBrodno = [
    'C4', 'C5', 'C6', 'C7', 'C8', 'C9', 'C10', 'C11', 'C12',
    'C13', 'C14', 'C15', 'C16', 'C17', 'C18', 'C19', 'C20', 'C21'
  ];

  // Kierunek Bemowo: C21 -> C4
  static const List<String> stationsToBemowo = [
    'C21', 'C20', 'C19', 'C18', 'C17', 'C16', 'C15', 'C14', 'C13',
    'C12', 'C11', 'C10', 'C9', 'C8', 'C7', 'C6', 'C5', 'C4'
  ];

  // Godziny dla kierunku Bródno (identyczne w piątek i sobotę)
  static const Map<String, List<String>> brodnoTimes = {
    'C4': ['00:13', '00:28', '00:43', '00:58', '01:13', '01:28', '01:43', '01:58', '02:13'],
    'C5': ['00:15', '00:30', '00:45', '01:00', '01:15', '01:30', '01:45', '02:00', '02:15'],
    'C6': ['00:17', '00:32', '00:47', '01:02', '01:17', '01:32', '01:47', '02:02', '02:17'],
    'C7': ['00:19', '00:34', '00:49', '01:04', '01:19', '01:34', '01:49', '02:04', '02:19'],
    'C8': ['00:21', '00:36', '00:51', '01:06', '01:21', '01:36', '01:51', '02:06', '02:21'],
    'C9': ['00:23', '00:38', '00:53', '01:08', '01:23', '01:38', '01:53', '02:08', '02:23'],
    'C10': ['00:25', '00:40', '00:55', '01:10', '01:25', '01:40', '01:55', '02:10', '02:25'],
    'C11': ['00:27', '00:42', '00:57', '01:12', '01:27', '01:42', '01:57', '02:12', '02:27'],
    'C12': ['00:28', '00:43', '00:58', '01:13', '01:28', '01:43', '01:58', '02:13', '02:28'],
    'C13': ['00:30', '00:45', '01:00', '01:15', '01:30', '01:45', '02:00', '02:15', '02:30'],
    'C14': ['00:32', '00:47', '01:02', '01:17', '01:32', '01:47', '02:02', '02:17', '02:32'],
    'C15': ['00:34', '00:49', '01:04', '01:19', '01:34', '01:49', '02:04', '02:19', '02:34'],
    'C16': ['00:36', '00:51', '01:06', '01:21', '01:36', '01:51', '02:06', '02:21', '02:36'],
    'C17': ['00:38', '00:53', '01:08', '01:23', '01:38', '01:53', '02:08', '02:23', '02:38'],
    'C18': ['00:40', '00:55', '01:10', '01:25', '01:40', '01:55', '02:10', '02:25', '02:40'],
    'C19': ['00:42', '00:57', '01:12', '01:27', '01:42', '01:57', '02:12', '02:27', '02:42'],
    'C20': ['00:44', '00:59', '01:14', '01:29', '01:44', '01:59', '02:14', '02:29', '02:44'],
    'C21': ['00:46', '01:01', '01:16', '01:31', '01:46', '02:01', '02:16', '02:31', '02:46'],
  };

  // Godziny dla kierunku Bemowo (identyczne w piątek i sobotę)
  static const Map<String, List<String>> bemowoTimes = {
    'C21': ['00:08', '00:23', '00:38', '00:53', '01:08', '01:23', '01:38', '01:53', '02:08'],
    'C20': ['00:10', '00:25', '00:40', '00:55', '01:10', '01:25', '01:40', '01:55', '02:10'],
    'C19': ['00:12', '00:27', '00:42', '00:57', '01:12', '01:27', '01:42', '01:57', '02:12'],
    'C18': ['00:14', '00:29', '00:44', '00:59', '01:14', '01:29', '01:44', '01:59', '02:14'],
    'C17': ['00:16', '00:31', '00:46', '01:01', '01:16', '01:31', '01:46', '02:01', '02:16'],
    'C16': ['00:18', '00:33', '00:48', '01:03', '01:18', '01:33', '01:48', '02:03', '02:18'],
    'C15': ['00:20', '00:35', '00:50', '01:05', '01:20', '01:35', '01:50', '02:05', '02:20'],
    'C14': ['00:22', '00:37', '00:52', '01:07', '01:22', '01:37', '01:52', '02:07', '02:22'],
    'C13': ['00:24', '00:39', '00:54', '01:09', '01:24', '01:39', '01:54', '02:09', '02:24'],
    'C12': ['00:26', '00:41', '00:56', '01:11', '01:26', '01:41', '01:56', '02:11', '02:26'],
    'C11': ['00:27', '00:42', '00:57', '01:12', '01:27', '01:42', '01:57', '02:12', '02:27'],
    'C10': ['00:29', '00:44', '00:59', '01:14', '01:29', '01:44', '01:59', '02:14', '02:29'],
    'C9': ['00:31', '00:46', '01:01', '01:16', '01:31', '01:46', '02:01', '02:16', '02:31'],
    'C8': ['00:33', '00:48', '01:03', '01:18', '01:33', '01:48', '02:03', '02:18', '02:33'],
    'C7': ['00:35', '00:50', '01:05', '01:20', '01:35', '01:50', '02:05', '02:20', '02:35'],
    'C6': ['00:37', '00:52', '01:07', '01:22', '01:37', '01:52', '02:07', '02:22', '02:37'],
    'C5': ['00:39', '00:54', '01:09', '01:24', '01:39', '01:54', '02:09', '02:24', '02:39'],
    'C4': ['00:41', '00:56', '01:11', '01:26', '01:41', '01:56', '02:11', '02:26', '02:41'],
  };

  // Przypisanie obiegów do slotów godzinowych (piątek / sobota)
  static const List<int> brodnoCircuitsFriday = [10, 11, 1, 3, 5, 7, 10, 11, 1];
  static const List<int> brodnoCircuitsSaturday = [7, 9, 10, 2, 3, 5, 7, 9, 10];

  static const List<int> bemowoCircuitsFriday = [3, 5, 7, 10, 11, 1, 3, 5, 7];
  static const List<int> bemowoCircuitsSaturday = [2, 3, 5, 7, 9, 10, 2, 3, 5];

  static List<int> getAvailableCircuits(Direction direction, DayType dayType) {
    final sequence = _getCircuitSequence(direction, dayType);
    final seen = <int>{};
    final result = <int>[];
    for (final item in sequence) {
      if (!seen.contains(item)) {
        seen.add(item);
        result.add(item);
      }
    }
    return result;
  }

  static List<RoutePoint> getRoute(Direction direction, DayType dayType) {
    final isToBemowo = direction == Direction.mlociny;
    final stations = isToBemowo ? stationsToBemowo : stationsToBrodno;
    final timesMap = isToBemowo ? bemowoTimes : brodnoTimes;
    final circuits = _getCircuitSequence(direction, dayType);

    return stations.map((stationId) {
      final stationTimes = timesMap[stationId] ?? const <String>[];

      final firstByCircuit = <int, String>{};
      final secondByCircuit = <int, String>{};

      for (var i = 0; i < stationTimes.length && i < circuits.length; i++) {
        final circuit = circuits[i];
        final time = stationTimes[i];
        if (!firstByCircuit.containsKey(circuit)) {
          firstByCircuit[circuit] = time;
        } else if (!secondByCircuit.containsKey(circuit)) {
          secondByCircuit[circuit] = time;
        }
      }

      return RoutePoint(
        stationId: stationId,
        name: stationNames[stationId] ?? stationId,
        scheduleByCircuit: firstByCircuit,
        secondScheduleByCircuit: secondByCircuit.isEmpty ? null : secondByCircuit,
      );
    }).toList();
  }

  static List<int> _getCircuitSequence(Direction direction, DayType dayType) {
    final isToBemowo = direction == Direction.mlociny;

    if (isToBemowo) {
      return dayType == DayType.friday ? bemowoCircuitsFriday : bemowoCircuitsSaturday;
    }

    return dayType == DayType.friday ? brodnoCircuitsFriday : brodnoCircuitsSaturday;
  }
}
