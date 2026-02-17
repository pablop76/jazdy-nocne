import '../models/route_point.dart';

/// Typ dnia: piątek lub sobota
enum DayType {
  friday,   // Piątek
  saturday, // Sobota/Niedziela
}

/// Rozkład jazdy metra M1 - nocny
/// Obiegi: 1, 3, 4, 6, 7, 9, 11
class RouteData {
  static const List<int> availableCircuits = [1, 3, 4, 6, 7, 9, 11];

  // ============================================
  // PIĄTEK - Kierunek Młociny
  // Stacje startowe: A1, A7, A11, A18
  // ============================================
  static const List<RoutePoint> fridayToMlociny = [
    RoutePoint(stationId: 'A1', name: 'A1 - Kabaty', scheduleByCircuit: {
      1: '00:12', 3: '00:27', 4: '00:42', 6: '00:57', 7: '01:12', 9: '01:27', 11: '01:42',
    }, secondScheduleByCircuit: {1: '01:57'},
    firstDepartureMonThu: '05:00', lastDepartureMonThu: '00:06', lastDepartureFriSat: '01:57'),
    RoutePoint(stationId: 'A2', name: 'A2 - Natolin', scheduleByCircuit: {
      1: '00:14', 3: '00:29', 4: '00:44', 6: '00:59', 7: '01:14', 9: '01:29', 11: '01:44',
    }, secondScheduleByCircuit: {1: '01:59'},
    firstDepartureMonThu: '05:02', lastDepartureMonThu: '00:08', lastDepartureFriSat: '01:59'),
    RoutePoint(stationId: 'A3', name: 'A3 - Imielin', scheduleByCircuit: {
      1: '00:16', 3: '00:31', 4: '00:46', 6: '01:01', 7: '01:16', 9: '01:31', 11: '01:46',
    }, secondScheduleByCircuit: {1: '02:01'},
    firstDepartureMonThu: '05:04', lastDepartureMonThu: '00:10', lastDepartureFriSat: '02:01'),
    RoutePoint(stationId: 'A4', name: 'A4 - Stokłosy', scheduleByCircuit: {
      1: '00:18', 3: '00:33', 4: '00:48', 6: '01:03', 7: '01:18', 9: '01:33', 11: '01:48',
    }, secondScheduleByCircuit: {1: '02:03'},
    firstDepartureMonThu: '05:06', lastDepartureMonThu: '00:12', lastDepartureFriSat: '02:03'),
    RoutePoint(stationId: 'A5', name: 'A5 - Ursynów', scheduleByCircuit: {
      1: '00:19', 3: '00:34', 4: '00:49', 6: '01:04', 7: '01:19', 9: '01:34', 11: '01:49',
    }, secondScheduleByCircuit: {1: '02:04'},
    firstDepartureMonThu: '05:07', lastDepartureMonThu: '00:13', lastDepartureFriSat: '02:04'),
    RoutePoint(stationId: 'A6', name: 'A6 - Służew', scheduleByCircuit: {
      1: '00:21', 3: '00:36', 4: '00:51', 6: '01:06', 7: '01:21', 9: '01:36', 11: '01:51',
    }, secondScheduleByCircuit: {1: '02:06'},
    firstDepartureMonThu: '05:09', lastDepartureMonThu: '00:15', lastDepartureFriSat: '02:06'),
    RoutePoint(stationId: 'A7', name: 'A7 - Wilanowska', scheduleByCircuit: {
      1: '00:23', 3: '00:38', 4: '00:53', 6: '01:08', 7: '01:23', 9: '01:38', 11: '01:53',
    }, secondScheduleByCircuit: {1: '02:08'},
    firstDepartureMonThu: '05:11/05:03', firstDepartureFriSat: '05:04', lastDepartureMonThu: '00:17', lastDepartureFriSat: '02:08'),
    RoutePoint(stationId: 'A8', name: 'A8 - Wierzbno', scheduleByCircuit: {
      1: '00:25', 3: '00:40', 4: '00:55', 6: '01:10', 7: '01:25', 9: '01:40', 11: '01:55',
    }, secondScheduleByCircuit: {1: '02:10'},
    firstDepartureMonThu: '05:13/05:05', firstDepartureFriSat: '05:06', lastDepartureMonThu: '00:19', lastDepartureFriSat: '02:10'),
    RoutePoint(stationId: 'A9', name: 'A9 - Racławicka', scheduleByCircuit: {
      1: '00:27', 3: '00:42', 4: '00:57', 6: '01:12', 7: '01:27', 9: '01:42', 11: '01:57',
    }, secondScheduleByCircuit: {1: '02:12'},
    firstDepartureMonThu: '05:15/05:07', firstDepartureFriSat: '05:08', lastDepartureMonThu: '00:21', lastDepartureFriSat: '02:12'),
    RoutePoint(stationId: 'A10', name: 'A10 - Pole Mokotowskie', scheduleByCircuit: {
      1: '00:29', 3: '00:44', 4: '00:59', 6: '01:14', 7: '01:29', 9: '01:44', 11: '01:59',
    }, secondScheduleByCircuit: {1: '02:14'},
    firstDepartureMonThu: '05:17/05:09', firstDepartureFriSat: '05:10', lastDepartureMonThu: '00:23', lastDepartureFriSat: '02:14'),
    RoutePoint(stationId: 'A11', name: 'A11 - Politechnika', scheduleByCircuit: {
      1: '00:30', 3: '00:45', 4: '01:00', 6: '01:15', 7: '01:30', 9: '01:45', 11: '02:00',
    }, secondScheduleByCircuit: {1: '02:15'},
    firstDepartureMonThu: '05:18/05:10/05:00', firstDepartureFriSat: '05:11/05:04', lastDepartureMonThu: '00:24', lastDepartureFriSat: '02:15'),
    RoutePoint(stationId: 'A13', name: 'A13 - Centrum', scheduleByCircuit: {
      1: '00:32', 3: '00:47', 4: '01:02', 6: '01:17', 7: '01:32', 9: '01:47', 11: '02:02',
    }, secondScheduleByCircuit: {1: '02:17'},
    firstDepartureMonThu: '05:20/05:12/05:02', firstDepartureFriSat: '05:13/05:06', lastDepartureMonThu: '00:26', lastDepartureFriSat: '02:17'),
    RoutePoint(stationId: 'A14', name: 'A14 - Świętokrzyska', scheduleByCircuit: {
      1: '00:34', 3: '00:49', 4: '01:04', 6: '01:19', 7: '01:34', 9: '01:49', 11: '02:04',
    }, secondScheduleByCircuit: {1: '02:19'},
    firstDepartureMonThu: '05:22/05:14/05:04', firstDepartureFriSat: '05:15/05:08', lastDepartureMonThu: '00:28', lastDepartureFriSat: '02:19'),
    RoutePoint(stationId: 'A15', name: 'A15 - Ratusz Arsenał', scheduleByCircuit: {
      1: '00:36', 3: '00:51', 4: '01:06', 6: '01:21', 7: '01:36', 9: '01:51', 11: '02:06',
    }, secondScheduleByCircuit: {1: '02:21'},
    firstDepartureMonThu: '05:24/05:16/05:06', firstDepartureFriSat: '05:17/05:10', lastDepartureMonThu: '00:30', lastDepartureFriSat: '02:21'),
    RoutePoint(stationId: 'A17', name: 'A17 - Dworzec Gdański', scheduleByCircuit: {
      1: '00:39', 3: '00:54', 4: '01:09', 6: '01:24', 7: '01:39', 9: '01:54', 11: '02:09',
    }, secondScheduleByCircuit: {1: '02:24'},
    firstDepartureMonThu: '05:27/05:19/05:09', firstDepartureFriSat: '05:20/05:13', lastDepartureMonThu: '00:33', lastDepartureFriSat: '02:24'),
    RoutePoint(stationId: 'A18', name: 'A18 - Plac Wilsona', scheduleByCircuit: {
      1: '00:41', 3: '00:56', 4: '01:11', 6: '01:26', 7: '01:41', 9: '01:56', 11: '02:11',
    }, secondScheduleByCircuit: {1: '02:26'},
    firstDepartureMonThu: '05:29/05:21/05:11/05:00', firstDepartureFriSat: '05:22/05:15/05:08', lastDepartureMonThu: '00:35', lastDepartureFriSat: '02:26'),
    RoutePoint(stationId: 'A19', name: 'A19 - Marymont', scheduleByCircuit: {
      1: '00:43', 3: '00:58', 4: '01:13', 6: '01:28', 7: '01:43', 9: '01:58', 11: '02:13',
    }, secondScheduleByCircuit: {1: '02:28'},
    firstDepartureMonThu: '05:31/05:23/05:13/05:02', firstDepartureFriSat: '05:24/05:17/05:10', lastDepartureMonThu: '00:37', lastDepartureFriSat: '02:28'),
    RoutePoint(stationId: 'A20', name: 'A20 - Słodowiec', scheduleByCircuit: {
      1: '00:45', 3: '01:00', 4: '01:15', 6: '01:30', 7: '01:45', 9: '02:00', 11: '02:15',
    }, secondScheduleByCircuit: {1: '02:30'},
    firstDepartureMonThu: '05:33/05:25/05:15/05:04', firstDepartureFriSat: '05:26/05:19/05:12', lastDepartureMonThu: '00:39', lastDepartureFriSat: '02:30'),
    RoutePoint(stationId: 'A21', name: 'A21 - Stare Bielany', scheduleByCircuit: {
      1: '00:47', 3: '01:02', 4: '01:17', 6: '01:32', 7: '01:47', 9: '02:02', 11: '02:17',
    }, secondScheduleByCircuit: {1: '02:32'},
    firstDepartureMonThu: '05:34/05:26/05:16/05:05', firstDepartureFriSat: '05:27/05:20/05:13', lastDepartureMonThu: '00:40', lastDepartureFriSat: '02:31'),
    RoutePoint(stationId: 'A22', name: 'A22 - Wawrzyszew', scheduleByCircuit: {
      1: '00:48', 3: '01:03', 4: '01:18', 6: '01:33', 7: '01:48', 9: '02:03', 11: '02:18',
    }, secondScheduleByCircuit: {1: '02:33'},
    firstDepartureMonThu: '05:36/05:28/05:18/05:07', firstDepartureFriSat: '05:29/05:22/05:15', lastDepartureMonThu: '00:42', lastDepartureFriSat: '02:33'),
    RoutePoint(stationId: 'A23', name: 'A23 - Młociny', scheduleByCircuit: {
      1: '00:50', 3: '01:05', 4: '01:20', 6: '01:35', 7: '01:50', 9: '02:05', 11: '02:20',
    }, secondScheduleByCircuit: {1: '02:35'},
    firstDepartureMonThu: '05:38/05:30/05:20/05:09', firstDepartureFriSat: '05:31/05:24/05:17', lastDepartureMonThu: '00:44', lastDepartureFriSat: '02:35'),
  ];

  // ============================================
  // PIĄTEK - Kierunek Kabaty
  // ============================================
  static const List<RoutePoint> fridayToKabaty = [
    RoutePoint(stationId: 'A23', name: 'A23 - Młociny', scheduleByCircuit: {
      7: '00:18', 9: '00:33', 11: '00:48', 1: '01:03', 3: '01:18', 4: '01:33', 6: '01:48',
    }, secondScheduleByCircuit: {7: '02:03', 9: '02:18'},
    firstDepartureMonThu: '05:00', lastDepartureMonThu: '00:12', lastDepartureFriSat: '02:18'),
    RoutePoint(stationId: 'A22', name: 'A22 - Wawrzyszew', scheduleByCircuit: {
      7: '00:19', 9: '00:34', 11: '00:49', 1: '01:04', 3: '01:19', 4: '01:34', 6: '01:49',
    }, secondScheduleByCircuit: {7: '02:04', 9: '02:19'},
    firstDepartureMonThu: '05:01', lastDepartureMonThu: '00:13', lastDepartureFriSat: '02:19'),
    RoutePoint(stationId: 'A21', name: 'A21 - Stare Bielany', scheduleByCircuit: {
      7: '00:21', 9: '00:36', 11: '00:51', 1: '01:06', 3: '01:21', 4: '01:36', 6: '01:51',
    }, secondScheduleByCircuit: {7: '02:06', 9: '02:21'},
    firstDepartureMonThu: '05:03', lastDepartureMonThu: '00:15', lastDepartureFriSat: '02:21'),
    RoutePoint(stationId: 'A20', name: 'A20 - Słodowiec', scheduleByCircuit: {
      7: '00:23', 9: '00:38', 11: '00:53', 1: '01:08', 3: '01:23', 4: '01:38', 6: '01:53',
    }, secondScheduleByCircuit: {7: '02:08', 9: '02:23'},
    firstDepartureMonThu: '05:05', lastDepartureMonThu: '00:17', lastDepartureFriSat: '02:23'),
    RoutePoint(stationId: 'A19', name: 'A19 - Marymont', scheduleByCircuit: {
      7: '00:25', 9: '00:40', 11: '00:55', 1: '01:10', 3: '01:25', 4: '01:40', 6: '01:55',
    }, secondScheduleByCircuit: {7: '02:10', 9: '02:25'},
    firstDepartureMonThu: '05:07', lastDepartureMonThu: '00:19', lastDepartureFriSat: '02:25'),
    RoutePoint(stationId: 'A18', name: 'A18 - Plac Wilsona', scheduleByCircuit: {
      7: '00:26', 9: '00:41', 11: '00:56', 1: '01:11', 3: '01:26', 4: '01:41', 6: '01:56',
    }, secondScheduleByCircuit: {7: '02:11', 9: '02:26'},
    firstDepartureMonThu: '05:08/05:00', lastDepartureMonThu: '00:20', lastDepartureFriSat: '02:26'),
    RoutePoint(stationId: 'A17', name: 'A17 - Dworzec Gdański', scheduleByCircuit: {
      7: '00:29', 9: '00:44', 11: '00:59', 1: '01:14', 3: '01:29', 4: '01:44', 6: '01:59',
    }, secondScheduleByCircuit: {7: '02:14', 9: '02:29'},
    firstDepartureMonThu: '05:10/05:02', lastDepartureMonThu: '00:22', lastDepartureFriSat: '02:28'),
    RoutePoint(stationId: 'A15', name: 'A15 - Ratusz Arsenał', scheduleByCircuit: {
      7: '00:31', 9: '00:46', 11: '01:01', 1: '01:16', 3: '01:31', 4: '01:46', 6: '02:01',
    }, secondScheduleByCircuit: {7: '02:16', 9: '02:31'},
    firstDepartureMonThu: '05:12/05:04', lastDepartureMonThu: '00:24', lastDepartureFriSat: '02:30'),
    RoutePoint(stationId: 'A14', name: 'A14 - Świętokrzyska', scheduleByCircuit: {
      7: '00:34', 9: '00:49', 11: '01:04', 1: '01:19', 3: '01:34', 4: '01:49', 6: '02:04',
    }, secondScheduleByCircuit: {7: '02:19', 9: '02:34'},
    firstDepartureMonThu: '05:15/05:07', lastDepartureMonThu: '00:27', lastDepartureFriSat: '02:33'),
    RoutePoint(stationId: 'A13', name: 'A13 - Centrum', scheduleByCircuit: {
      7: '00:35', 9: '00:50', 11: '01:05', 1: '01:20', 3: '01:35', 4: '01:50', 6: '02:05',
    }, secondScheduleByCircuit: {7: '02:20', 9: '02:35'},
    firstDepartureMonThu: '05:17/05:09', lastDepartureMonThu: '00:29', lastDepartureFriSat: '02:35'),
    RoutePoint(stationId: 'A11', name: 'A11 - Politechnika', scheduleByCircuit: {
      7: '00:37', 9: '00:52', 11: '01:07', 1: '01:22', 3: '01:37', 4: '01:52', 6: '02:07',
    }, secondScheduleByCircuit: {7: '02:22', 9: '02:37'},
    firstDepartureMonThu: '05:19/05:11', lastDepartureMonThu: '00:31', lastDepartureFriSat: '02:37'),
    RoutePoint(stationId: 'A10', name: 'A10 - Pole Mokotowskie', scheduleByCircuit: {
      7: '00:39', 9: '00:54', 11: '01:09', 1: '01:24', 3: '01:39', 4: '01:54', 6: '02:09',
    }, secondScheduleByCircuit: {7: '02:24', 9: '02:39'},
    firstDepartureMonThu: '05:21/05:13', lastDepartureMonThu: '00:33', lastDepartureFriSat: '02:39'),
    RoutePoint(stationId: 'A9', name: 'A9 - Racławicka', scheduleByCircuit: {
      7: '00:41', 9: '00:56', 11: '01:11', 1: '01:26', 3: '01:41', 4: '01:56', 6: '02:11',
    }, secondScheduleByCircuit: {7: '02:26', 9: '02:41'},
    firstDepartureMonThu: '05:23/05:15', lastDepartureMonThu: '00:35', lastDepartureFriSat: '02:41'),
    RoutePoint(stationId: 'A8', name: 'A8 - Wierzbno', scheduleByCircuit: {
      7: '00:43', 9: '00:58', 11: '01:13', 1: '01:28', 3: '01:43', 4: '01:58', 6: '02:13',
    }, secondScheduleByCircuit: {7: '02:28', 9: '02:43'},
    firstDepartureMonThu: '05:25/05:17', lastDepartureMonThu: '00:37', lastDepartureFriSat: '02:43'),
    RoutePoint(stationId: 'A7', name: 'A7 - Wilanowska', scheduleByCircuit: {
      7: '00:44', 9: '00:59', 11: '01:14', 1: '01:29', 3: '01:44', 4: '01:59', 6: '02:14',
    }, secondScheduleByCircuit: {7: '02:29', 9: '02:44'},
    firstDepartureMonThu: '05:26/05:18', lastDepartureMonThu: '00:38', lastDepartureFriSat: '02:44'),
    RoutePoint(stationId: 'A6', name: 'A6 - Służew', scheduleByCircuit: {
      7: '00:46', 9: '01:01', 11: '01:16', 1: '01:31', 3: '01:46', 4: '02:01', 6: '02:16',
    }, secondScheduleByCircuit: {7: '02:31', 9: '02:46'},
    firstDepartureMonThu: '05:28/05:20', lastDepartureMonThu: '00:40', lastDepartureFriSat: '02:46'),
    RoutePoint(stationId: 'A5', name: 'A5 - Ursynów', scheduleByCircuit: {
      7: '00:48', 9: '01:03', 11: '01:18', 1: '01:33', 3: '01:48', 4: '02:03', 6: '02:18',
    }, secondScheduleByCircuit: {7: '02:33', 9: '02:48'},
    firstDepartureMonThu: '05:30/05:22', lastDepartureMonThu: '00:42', lastDepartureFriSat: '02:48'),
    RoutePoint(stationId: 'A4', name: 'A4 - Stokłosy', scheduleByCircuit: {
      7: '00:50', 9: '01:05', 11: '01:20', 1: '01:35', 3: '01:50', 4: '02:05', 6: '02:20',
    }, secondScheduleByCircuit: {7: '02:35', 9: '02:50'},
    firstDepartureMonThu: '05:32/05:24', lastDepartureMonThu: '00:44', lastDepartureFriSat: '02:50'),
    RoutePoint(stationId: 'A3', name: 'A3 - Imielin', scheduleByCircuit: {
      7: '00:52', 9: '01:07', 11: '01:22', 1: '01:37', 3: '01:52', 4: '02:07', 6: '02:22',
    }, secondScheduleByCircuit: {7: '02:37', 9: '02:52'},
    firstDepartureMonThu: '05:34/05:26', lastDepartureMonThu: '00:46', lastDepartureFriSat: '02:52'),
    RoutePoint(stationId: 'A2', name: 'A2 - Natolin', scheduleByCircuit: {
      7: '00:54', 9: '01:09', 11: '01:24', 1: '01:39', 3: '01:54', 4: '02:09', 6: '02:24',
    }, secondScheduleByCircuit: {7: '02:39', 9: '02:54'},
    firstDepartureMonThu: '05:36/05:28', lastDepartureMonThu: '00:48', lastDepartureFriSat: '02:54'),
    RoutePoint(stationId: 'A1', name: 'A1 - Kabaty', scheduleByCircuit: {
      7: '00:56', 9: '01:11', 11: '01:26', 1: '01:41', 3: '01:56', 4: '02:11', 6: '02:26',
    }, secondScheduleByCircuit: {7: '02:41', 9: '02:56'},
    firstDepartureMonThu: '05:38/05:30', lastDepartureMonThu: '00:50', lastDepartureFriSat: '02:56'),
  ];

  // ============================================
  // SOBOTA/NIEDZIELA - Kierunek Młociny
  // Stacje startowe: A1, A7, A11, A18
  // ============================================
  static const List<RoutePoint> saturdayToMlociny = [
    RoutePoint(stationId: 'A1', name: 'A1 - Kabaty', scheduleByCircuit: {
      1: '00:12', 3: '00:27', 4: '00:42', 6: '00:57', 7: '01:12', 9: '01:27', 11: '01:42',
    }, secondScheduleByCircuit: {1: '01:57'},
    firstDepartureMonThu: '05:00', lastDepartureMonThu: '00:06', lastDepartureFriSat: '01:57'),
    RoutePoint(stationId: 'A2', name: 'A2 - Natolin', scheduleByCircuit: {
      1: '00:14', 3: '00:29', 4: '00:44', 6: '00:59', 7: '01:14', 9: '01:29', 11: '01:44',
    }, secondScheduleByCircuit: {1: '01:59'},
    firstDepartureMonThu: '05:02', lastDepartureMonThu: '00:08', lastDepartureFriSat: '01:59'),
    RoutePoint(stationId: 'A3', name: 'A3 - Imielin', scheduleByCircuit: {
      1: '00:16', 3: '00:31', 4: '00:46', 6: '01:01', 7: '01:16', 9: '01:31', 11: '01:46',
    }, secondScheduleByCircuit: {1: '02:01'},
    firstDepartureMonThu: '05:04', lastDepartureMonThu: '00:10', lastDepartureFriSat: '02:01'),
    RoutePoint(stationId: 'A4', name: 'A4 - Stokłosy', scheduleByCircuit: {
      1: '00:18', 3: '00:33', 4: '00:48', 6: '01:03', 7: '01:18', 9: '01:33', 11: '01:48',
    }, secondScheduleByCircuit: {1: '02:03'},
    firstDepartureMonThu: '05:06', lastDepartureMonThu: '00:12', lastDepartureFriSat: '02:03'),
    RoutePoint(stationId: 'A5', name: 'A5 - Ursynów', scheduleByCircuit: {
      1: '00:19', 3: '00:34', 4: '00:49', 6: '01:04', 7: '01:19', 9: '01:34', 11: '01:49',
    }, secondScheduleByCircuit: {1: '02:04'},
    firstDepartureMonThu: '05:07', lastDepartureMonThu: '00:13', lastDepartureFriSat: '02:04'),
    RoutePoint(stationId: 'A6', name: 'A6 - Służew', scheduleByCircuit: {
      1: '00:21', 3: '00:36', 4: '00:51', 6: '01:06', 7: '01:21', 9: '01:36', 11: '01:51',
    }, secondScheduleByCircuit: {1: '02:06'},
    firstDepartureMonThu: '05:09', lastDepartureMonThu: '00:15', lastDepartureFriSat: '02:06'),
    RoutePoint(stationId: 'A7', name: 'A7 - Wilanowska', scheduleByCircuit: {
      1: '00:23', 3: '00:38', 4: '00:53', 6: '01:08', 7: '01:23', 9: '01:38', 11: '01:53',
    }, secondScheduleByCircuit: {1: '02:08'},
    firstDepartureMonThu: '05:11/05:03', firstDepartureFriSat: '05:04', lastDepartureMonThu: '00:17', lastDepartureFriSat: '02:08'),
    RoutePoint(stationId: 'A8', name: 'A8 - Wierzbno', scheduleByCircuit: {
      1: '00:25', 3: '00:40', 4: '00:55', 6: '01:10', 7: '01:25', 9: '01:40', 11: '01:55',
    }, secondScheduleByCircuit: {1: '02:10'},
    firstDepartureMonThu: '05:13/05:05', firstDepartureFriSat: '05:06', lastDepartureMonThu: '00:19', lastDepartureFriSat: '02:10'),
    RoutePoint(stationId: 'A9', name: 'A9 - Racławicka', scheduleByCircuit: {
      1: '00:27', 3: '00:42', 4: '00:57', 6: '01:12', 7: '01:27', 9: '01:42', 11: '01:57',
    }, secondScheduleByCircuit: {1: '02:12'},
    firstDepartureMonThu: '05:15/05:07', firstDepartureFriSat: '05:08', lastDepartureMonThu: '00:21', lastDepartureFriSat: '02:12'),
    RoutePoint(stationId: 'A10', name: 'A10 - Pole Mokotowskie', scheduleByCircuit: {
      1: '00:29', 3: '00:44', 4: '00:59', 6: '01:14', 7: '01:29', 9: '01:44', 11: '01:59',
    }, secondScheduleByCircuit: {1: '02:14'},
    firstDepartureMonThu: '05:17/05:09', firstDepartureFriSat: '05:10', lastDepartureMonThu: '00:23', lastDepartureFriSat: '02:14'),
    RoutePoint(stationId: 'A11', name: 'A11 - Politechnika', scheduleByCircuit: {
      1: '00:30', 3: '00:45', 4: '01:00', 6: '01:15', 7: '01:30', 9: '01:45', 11: '02:00',
    }, secondScheduleByCircuit: {1: '02:15'},
    firstDepartureMonThu: '05:18/05:10/05:00', firstDepartureFriSat: '05:11/05:04', lastDepartureMonThu: '00:24', lastDepartureFriSat: '02:15'),
    RoutePoint(stationId: 'A13', name: 'A13 - Centrum', scheduleByCircuit: {
      1: '00:32', 3: '00:47', 4: '01:02', 6: '01:17', 7: '01:32', 9: '01:47', 11: '02:02',
    }, secondScheduleByCircuit: {1: '02:17'},
    firstDepartureMonThu: '05:20/05:12/05:02', firstDepartureFriSat: '05:13/05:06', lastDepartureMonThu: '00:26', lastDepartureFriSat: '02:17'),
    RoutePoint(stationId: 'A14', name: 'A14 - Świętokrzyska', scheduleByCircuit: {
      1: '00:34', 3: '00:49', 4: '01:04', 6: '01:19', 7: '01:34', 9: '01:49', 11: '02:04',
    }, secondScheduleByCircuit: {1: '02:19'},
    firstDepartureMonThu: '05:22/05:14/05:04', firstDepartureFriSat: '05:15/05:08', lastDepartureMonThu: '00:28', lastDepartureFriSat: '02:19'),
    RoutePoint(stationId: 'A15', name: 'A15 - Ratusz Arsenał', scheduleByCircuit: {
      1: '00:36', 3: '00:51', 4: '01:06', 6: '01:21', 7: '01:36', 9: '01:51', 11: '02:06',
    }, secondScheduleByCircuit: {1: '02:21'},
    firstDepartureMonThu: '05:24/05:16/05:06', firstDepartureFriSat: '05:17/05:10', lastDepartureMonThu: '00:30', lastDepartureFriSat: '02:21'),
    RoutePoint(stationId: 'A17', name: 'A17 - Dworzec Gdański', scheduleByCircuit: {
      1: '00:39', 3: '00:54', 4: '01:09', 6: '01:24', 7: '01:39', 9: '01:54', 11: '02:09',
    }, secondScheduleByCircuit: {1: '02:24'},
    firstDepartureMonThu: '05:27/05:19/05:09', firstDepartureFriSat: '05:20/05:13', lastDepartureMonThu: '00:33', lastDepartureFriSat: '02:24'),
    RoutePoint(stationId: 'A18', name: 'A18 - Plac Wilsona', scheduleByCircuit: {
      1: '00:41', 3: '00:56', 4: '01:11', 6: '01:26', 7: '01:41', 9: '01:56', 11: '02:11',
    }, secondScheduleByCircuit: {1: '02:26'},
    firstDepartureMonThu: '05:29/05:21/05:11/05:00', firstDepartureFriSat: '05:22/05:15/05:08', lastDepartureMonThu: '00:35', lastDepartureFriSat: '02:26'),
    RoutePoint(stationId: 'A19', name: 'A19 - Marymont', scheduleByCircuit: {
      1: '00:43', 3: '00:58', 4: '01:13', 6: '01:28', 7: '01:43', 9: '01:58', 11: '02:13',
    }, secondScheduleByCircuit: {1: '02:28'},
    firstDepartureMonThu: '05:31/05:23/05:13/05:02', firstDepartureFriSat: '05:24/05:17/05:10', lastDepartureMonThu: '00:37', lastDepartureFriSat: '02:28'),
    RoutePoint(stationId: 'A20', name: 'A20 - Słodowiec', scheduleByCircuit: {
      1: '00:45', 3: '01:00', 4: '01:15', 6: '01:30', 7: '01:45', 9: '02:00', 11: '02:15',
    }, secondScheduleByCircuit: {1: '02:30'},
    firstDepartureMonThu: '05:33/05:25/05:15/05:04', firstDepartureFriSat: '05:26/05:19/05:12', lastDepartureMonThu: '00:39', lastDepartureFriSat: '02:30'),
    RoutePoint(stationId: 'A21', name: 'A21 - Stare Bielany', scheduleByCircuit: {
      1: '00:47', 3: '01:02', 4: '01:17', 6: '01:32', 7: '01:47', 9: '02:02', 11: '02:17',
    }, secondScheduleByCircuit: {1: '02:32'},
    firstDepartureMonThu: '05:34/05:26/05:16/05:05', firstDepartureFriSat: '05:27/05:20/05:13', lastDepartureMonThu: '00:40', lastDepartureFriSat: '02:31'),
    RoutePoint(stationId: 'A22', name: 'A22 - Wawrzyszew', scheduleByCircuit: {
      1: '00:48', 3: '01:03', 4: '01:18', 6: '01:33', 7: '01:48', 9: '02:03', 11: '02:18',
    }, secondScheduleByCircuit: {1: '02:33'},
    firstDepartureMonThu: '05:36/05:28/05:18/05:07', firstDepartureFriSat: '05:29/05:22/05:15', lastDepartureMonThu: '00:42', lastDepartureFriSat: '02:33'),
    RoutePoint(stationId: 'A23', name: 'A23 - Młociny', scheduleByCircuit: {
      1: '00:50', 3: '01:05', 4: '01:20', 6: '01:35', 7: '01:50', 9: '02:05', 11: '02:20',
    }, secondScheduleByCircuit: {1: '02:35'},
    firstDepartureMonThu: '05:38/05:30/05:20/05:09', firstDepartureFriSat: '05:31/05:24/05:17', lastDepartureMonThu: '00:44', lastDepartureFriSat: '02:35'),
  ];

  // ============================================
  // SOBOTA/NIEDZIELA - Kierunek Kabaty
  // ============================================
  static const List<RoutePoint> saturdayToKabaty = [
    RoutePoint(stationId: 'A23', name: 'A23 - Młociny', scheduleByCircuit: {
      7: '00:18', 9: '00:33', 11: '00:48', 1: '01:03', 3: '01:18', 4: '01:33', 6: '01:48',
    }, secondScheduleByCircuit: {7: '02:03', 9: '02:18'},
    firstDepartureMonThu: '05:00', lastDepartureMonThu: '00:12', lastDepartureFriSat: '02:18'),
    RoutePoint(stationId: 'A22', name: 'A22 - Wawrzyszew', scheduleByCircuit: {
      7: '00:19', 9: '00:34', 11: '00:49', 1: '01:04', 3: '01:19', 4: '01:34', 6: '01:49',
    }, secondScheduleByCircuit: {7: '02:04', 9: '02:19'},
    firstDepartureMonThu: '05:01', lastDepartureMonThu: '00:13', lastDepartureFriSat: '02:19'),
    RoutePoint(stationId: 'A21', name: 'A21 - Stare Bielany', scheduleByCircuit: {
      7: '00:21', 9: '00:36', 11: '00:51', 1: '01:06', 3: '01:21', 4: '01:36', 6: '01:51',
    }, secondScheduleByCircuit: {7: '02:06', 9: '02:21'},
    firstDepartureMonThu: '05:03', lastDepartureMonThu: '00:15', lastDepartureFriSat: '02:21'),
    RoutePoint(stationId: 'A20', name: 'A20 - Słodowiec', scheduleByCircuit: {
      7: '00:23', 9: '00:38', 11: '00:53', 1: '01:08', 3: '01:23', 4: '01:38', 6: '01:53',
    }, secondScheduleByCircuit: {7: '02:08', 9: '02:23'},
    firstDepartureMonThu: '05:05', lastDepartureMonThu: '00:17', lastDepartureFriSat: '02:23'),
    RoutePoint(stationId: 'A19', name: 'A19 - Marymont', scheduleByCircuit: {
      7: '00:25', 9: '00:40', 11: '00:55', 1: '01:10', 3: '01:25', 4: '01:40', 6: '01:55',
    }, secondScheduleByCircuit: {7: '02:10', 9: '02:25'},
    firstDepartureMonThu: '05:07', lastDepartureMonThu: '00:19', lastDepartureFriSat: '02:25'),
    RoutePoint(stationId: 'A18', name: 'A18 - Plac Wilsona', scheduleByCircuit: {
      7: '00:26', 9: '00:41', 11: '00:56', 1: '01:11', 3: '01:26', 4: '01:41', 6: '01:56',
    }, secondScheduleByCircuit: {7: '02:11', 9: '02:26'},
    firstDepartureMonThu: '05:08/05:00', lastDepartureMonThu: '00:20', lastDepartureFriSat: '02:26'),
    RoutePoint(stationId: 'A17', name: 'A17 - Dworzec Gdański', scheduleByCircuit: {
      7: '00:29', 9: '00:44', 11: '00:59', 1: '01:14', 3: '01:29', 4: '01:44', 6: '01:59',
    }, secondScheduleByCircuit: {7: '02:14', 9: '02:29'},
    firstDepartureMonThu: '05:10/05:02', lastDepartureMonThu: '00:22', lastDepartureFriSat: '02:28'),
    RoutePoint(stationId: 'A15', name: 'A15 - Ratusz Arsenał', scheduleByCircuit: {
      7: '00:31', 9: '00:46', 11: '01:01', 1: '01:16', 3: '01:31', 4: '01:46', 6: '02:01',
    }, secondScheduleByCircuit: {7: '02:16', 9: '02:31'},
    firstDepartureMonThu: '05:12/05:04', lastDepartureMonThu: '00:24', lastDepartureFriSat: '02:30'),
    RoutePoint(stationId: 'A14', name: 'A14 - Świętokrzyska', scheduleByCircuit: {
      7: '00:34', 9: '00:49', 11: '01:04', 1: '01:19', 3: '01:34', 4: '01:49', 6: '02:04',
    }, secondScheduleByCircuit: {7: '02:19', 9: '02:34'},
    firstDepartureMonThu: '05:15/05:07', lastDepartureMonThu: '00:27', lastDepartureFriSat: '02:33'),
    RoutePoint(stationId: 'A13', name: 'A13 - Centrum', scheduleByCircuit: {
      7: '00:35', 9: '00:50', 11: '01:05', 1: '01:20', 3: '01:35', 4: '01:50', 6: '02:05',
    }, secondScheduleByCircuit: {7: '02:20', 9: '02:35'},
    firstDepartureMonThu: '05:17/05:09', lastDepartureMonThu: '00:29', lastDepartureFriSat: '02:35'),
    RoutePoint(stationId: 'A11', name: 'A11 - Politechnika', scheduleByCircuit: {
      7: '00:37', 9: '00:52', 11: '01:07', 1: '01:22', 3: '01:37', 4: '01:52', 6: '02:07',
    }, secondScheduleByCircuit: {7: '02:22', 9: '02:37'},
    firstDepartureMonThu: '05:19/05:11', lastDepartureMonThu: '00:31', lastDepartureFriSat: '02:37'),
    RoutePoint(stationId: 'A10', name: 'A10 - Pole Mokotowskie', scheduleByCircuit: {
      7: '00:39', 9: '00:54', 11: '01:09', 1: '01:24', 3: '01:39', 4: '01:54', 6: '02:09',
    }, secondScheduleByCircuit: {7: '02:24', 9: '02:39'},
    firstDepartureMonThu: '05:21/05:13', lastDepartureMonThu: '00:33', lastDepartureFriSat: '02:39'),
    RoutePoint(stationId: 'A9', name: 'A9 - Racławicka', scheduleByCircuit: {
      7: '00:41', 9: '00:56', 11: '01:11', 1: '01:26', 3: '01:41', 4: '01:56', 6: '02:11',
    }, secondScheduleByCircuit: {7: '02:26', 9: '02:41'},
    firstDepartureMonThu: '05:23/05:15', lastDepartureMonThu: '00:35', lastDepartureFriSat: '02:41'),
    RoutePoint(stationId: 'A8', name: 'A8 - Wierzbno', scheduleByCircuit: {
      7: '00:43', 9: '00:58', 11: '01:13', 1: '01:28', 3: '01:43', 4: '01:58', 6: '02:13',
    }, secondScheduleByCircuit: {7: '02:28', 9: '02:43'},
    firstDepartureMonThu: '05:25/05:17', lastDepartureMonThu: '00:37', lastDepartureFriSat: '02:43'),
    RoutePoint(stationId: 'A7', name: 'A7 - Wilanowska', scheduleByCircuit: {
      7: '00:44', 9: '00:59', 11: '01:14', 1: '01:29', 3: '01:44', 4: '01:59', 6: '02:14',
    }, secondScheduleByCircuit: {7: '02:29', 9: '02:44'},
    firstDepartureMonThu: '05:26/05:18', lastDepartureMonThu: '00:38', lastDepartureFriSat: '02:44'),
    RoutePoint(stationId: 'A6', name: 'A6 - Służew', scheduleByCircuit: {
      7: '00:46', 9: '01:01', 11: '01:16', 1: '01:31', 3: '01:46', 4: '02:01', 6: '02:16',
    }, secondScheduleByCircuit: {7: '02:31', 9: '02:46'},
    firstDepartureMonThu: '05:28/05:20', lastDepartureMonThu: '00:40', lastDepartureFriSat: '02:46'),
    RoutePoint(stationId: 'A5', name: 'A5 - Ursynów', scheduleByCircuit: {
      7: '00:48', 9: '01:03', 11: '01:18', 1: '01:33', 3: '01:48', 4: '02:03', 6: '02:18',
    }, secondScheduleByCircuit: {7: '02:33', 9: '02:48'},
    firstDepartureMonThu: '05:30/05:22', lastDepartureMonThu: '00:42', lastDepartureFriSat: '02:48'),
    RoutePoint(stationId: 'A4', name: 'A4 - Stokłosy', scheduleByCircuit: {
      7: '00:50', 9: '01:05', 11: '01:20', 1: '01:35', 3: '01:50', 4: '02:05', 6: '02:20',
    }, secondScheduleByCircuit: {7: '02:35', 9: '02:50'},
    firstDepartureMonThu: '05:32/05:24', lastDepartureMonThu: '00:44', lastDepartureFriSat: '02:50'),
    RoutePoint(stationId: 'A3', name: 'A3 - Imielin', scheduleByCircuit: {
      7: '00:52', 9: '01:07', 11: '01:22', 1: '01:37', 3: '01:52', 4: '02:07', 6: '02:22',
    }, secondScheduleByCircuit: {7: '02:37', 9: '02:52'},
    firstDepartureMonThu: '05:34/05:26', lastDepartureMonThu: '00:46', lastDepartureFriSat: '02:52'),
    RoutePoint(stationId: 'A2', name: 'A2 - Natolin', scheduleByCircuit: {
      7: '00:54', 9: '01:09', 11: '01:24', 1: '01:39', 3: '01:54', 4: '02:09', 6: '02:24',
    }, secondScheduleByCircuit: {7: '02:39', 9: '02:54'},
    firstDepartureMonThu: '05:36/05:28', lastDepartureMonThu: '00:48', lastDepartureFriSat: '02:54'),
    RoutePoint(stationId: 'A1', name: 'A1 - Kabaty', scheduleByCircuit: {
      7: '00:56', 9: '01:11', 11: '01:26', 1: '01:41', 3: '01:56', 4: '02:11', 6: '02:26',
    }, secondScheduleByCircuit: {7: '02:41', 9: '02:56'},
    firstDepartureMonThu: '05:38/05:30', lastDepartureMonThu: '00:50', lastDepartureFriSat: '02:56'),
  ];

  /// Zwraca listę stacji dla danego kierunku i dnia
  static List<RoutePoint> getRoute(Direction direction, DayType dayType) {
    if (dayType == DayType.friday) {
      return direction == Direction.mlociny ? fridayToMlociny : fridayToKabaty;
    } else {
      return direction == Direction.mlociny ? saturdayToMlociny : saturdayToKabaty;
    }
  }
  
  /// Obiegi startujące z Kabat (kierunek Młociny pierwszy)
  static const List<int> circuitsFromKabaty = [1, 3, 4, 6];
  
  /// Obiegi startujące z Młocin (kierunek Kabaty pierwszy)
  static const List<int> circuitsFromMlociny = [7, 9, 11];
  
  /// Sprawdza czy dany obieg startuje z Kabat
  static bool startsFromKabaty(int circuit) {
    return circuitsFromKabaty.contains(circuit);
  }
}
