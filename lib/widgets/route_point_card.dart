import 'package:flutter/material.dart';

import '../models/route_point.dart';

class RoutePointCard extends StatelessWidget {
  final RoutePoint point;
  final DateTime currentTime;
  final int circuit;
  final bool showTimeWindow;
  final String? primaryActiveStationId;
  final Direction direction;

  const RoutePointCard({
    super.key,
    required this.point,
    required this.currentTime,
    required this.circuit,
    this.showTimeWindow = true,
    this.primaryActiveStationId,
    required this.direction,
  });

  /// Sprawdza czy to stacja końcowa dla danego kierunku
  bool get isTerminalStation {
    // M2: kody stacji C4..C21
    if (point.stationId.startsWith('C')) {
      if (direction == Direction.mlociny) {
        return point.stationId == 'C4'; // kierunek Bemowo
      }
      return point.stationId == 'C21'; // kierunek Bródno
    }

    // M1: kody stacji A1..A23
    if (direction == Direction.mlociny) {
      return point.stationId == 'A23'; // Młociny
    } else {
      return point.stationId == 'A1'; // Kabaty
    }
  }

  /// Zwraca odpowiedni komunikat (Odjazd/Przyjazd)
  String get departureLabel => isTerminalStation ? 'Przyjazd' : 'Odjazd';
  
  /// Zwraca komunikat dla przycisku statusu (ODJAZD!/PRZYJAZD!)
  String get activeStatusLabel => isTerminalStation ? 'PRZYJAZD!' : 'ODJAZD!';

  /// Zwraca etykietę kierunku analogicznie dla M1 i M2
  String get directionLabel {
    if (point.stationId.startsWith('C')) {
      return direction == Direction.mlociny ? '→ Bemowo' : '→ Bródno';
    }
    return direction == Direction.mlociny ? '→ Młociny' : '→ Kabaty';
  }

  // Pobierz najwcześniejszy czas z formatu "05:29/05:21/05:11/05:00" -> "05:00"
  String _getEarliestTime(String? timeString) {
    if (timeString == null) return '--:--';
    final parts = timeString.split('/');
    return parts.last; // Ostatni czas jest najwcześniejszy (stacja startowa)
  }

  @override
  Widget build(BuildContext context) {
    var status = point.getTimeWindowStatus(currentTime, circuit);
    
    // Jeśli jest aktywny, sprawdź czy to główna stacja
    if (status == TimeWindowStatus.active && primaryActiveStationId != null) {
      if (point.stationId != primaryActiveStationId) {
        status = TimeWindowStatus.activeSecondary;
      }
    }
    
    final secondsTo = point.secondsToScheduled(currentTime, circuit);
    final scheduledTime = point.getNearestScheduledTime(currentTime, circuit) ?? '--:--';

    // Jeśli okno czasowe wyłączone, pokazuj godzinę i czas do odjazdu
    if (!showTimeWindow) {
      // Oblicz czas do planowanego odjazdu
      final scheduledParts = scheduledTime.split(':');
      int secondsToScheduled = 0;
      bool isPassed = false;

      if (scheduledParts.length == 2) {
        final hour = int.parse(scheduledParts[0]);
        final minute = int.parse(scheduledParts[1]);
        final scheduled = DateTime(
          currentTime.year,
          currentTime.month,
          currentTime.day,
          hour,
          minute,
        );
        secondsToScheduled = scheduled.difference(currentTime).inSeconds;
        isPassed =
            secondsToScheduled < -179; // Uznajemy za miniony po 2:59
      }

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        color: isPassed ? Colors.grey.shade100 : Colors.white,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Górny wiersz: numer stacji + nazwa + countdown
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isPassed ? Colors.grey : Colors.blue,
                    child: Text(
                      point.stationId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: isPassed ? Colors.grey : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$directionLabel • $departureLabel: $scheduledTime',
                          style: TextStyle(
                            fontSize: 13,
                            color: isPassed ? Colors.grey : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildSimpleCountdown(secondsToScheduled, isPassed),
                ],
              ),
              // Dolny wiersz: pierwszy i ostatni odjazd
              if (point.firstDepartureMonThu != null || point.lastDepartureMonThu != null)
                Row(
                  children: [
                    const SizedBox(width: 52),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (point.firstDepartureMonThu != null)
                            Text(
                              'Pierwszy: ${_getEarliestTime(point.firstDepartureMonThu)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isPassed ? Colors.grey.shade400 : Colors.green.shade700,
                              ),
                              softWrap: true,
                            ),
                          if (point.firstDepartureFriSat != null &&
                              _getEarliestTime(point.firstDepartureFriSat) != _getEarliestTime(point.firstDepartureMonThu))
                            Text(
                              'Pierwszy (pt-sb): ${_getEarliestTime(point.firstDepartureFriSat)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isPassed ? Colors.grey.shade400 : Colors.green.shade600,
                              ),
                              softWrap: true,
                            ),
                          if (point.lastDepartureMonThu != null || point.lastDepartureFriSat != null)
                            Text(
                              'Ostatni: ${point.lastDepartureMonThu ?? "--:--"} / ${point.lastDepartureFriSat ?? "--:--"} (pt-sb)',
                              style: TextStyle(
                                fontSize: 10,
                                color: isPassed ? Colors.grey.shade400 : Colors.red.shade700,
                              ),
                              softWrap: true,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    final isActiveStatus = status == TimeWindowStatus.active || 
        status == TimeWindowStatus.activeApproaching || 
        status == TimeWindowStatus.activeSecondary;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: _getBackgroundColor(status),
      elevation: isActiveStatus ? 8 : 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Górny wiersz: numer stacji + nazwa + status
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getStatusColor(status),
                  child: Text(
                    point.stationId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.name,
                        style: TextStyle(
                          fontWeight: isActiveStatus ? FontWeight.bold : FontWeight.w500,
                          fontSize: status == TimeWindowStatus.active ? 17 : 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$directionLabel • $departureLabel: $scheduledTime',
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusWidget(status, secondsTo),
              ],
            ),
            // Dolny wiersz: pierwszy i ostatni odjazd
            if (point.firstDepartureMonThu != null || point.lastDepartureMonThu != null)
              Row(
                children: [
                  const SizedBox(width: 52),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (point.firstDepartureMonThu != null)
                          Text(
                            'Pierwszy: ${_getEarliestTime(point.firstDepartureMonThu)}',
                            style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                            softWrap: true,
                          ),
                        if (point.firstDepartureFriSat != null &&
                            _getEarliestTime(point.firstDepartureFriSat) != _getEarliestTime(point.firstDepartureMonThu))
                          Text(
                            'Pierwszy (pt-sb): ${_getEarliestTime(point.firstDepartureFriSat)}',
                            style: TextStyle(fontSize: 10, color: Colors.green.shade600),
                            softWrap: true,
                          ),
                        if (point.lastDepartureMonThu != null || point.lastDepartureFriSat != null)
                          Text(
                            'Ostatni: ${point.lastDepartureMonThu ?? "--:--"} / ${point.lastDepartureFriSat ?? "--:--"} (pt-sb)',
                            style: TextStyle(fontSize: 10, color: Colors.red.shade700),
                            softWrap: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(TimeWindowStatus status) {
    switch (status) {
      case TimeWindowStatus.active:
        return Colors.green.shade50;
      case TimeWindowStatus.activeApproaching:
        return Colors.orange.shade50;
      case TimeWindowStatus.activeSecondary:
        return Colors.orange.shade50;
      case TimeWindowStatus.passed:
        return Colors.red.shade50;
      case TimeWindowStatus.upcoming:
        return Colors.white;
    }
  }

  Color _getStatusColor(TimeWindowStatus status) {
    switch (status) {
      case TimeWindowStatus.active:
        return Colors.green;
      case TimeWindowStatus.activeApproaching:
        return Colors.orange;
      case TimeWindowStatus.activeSecondary:
        return Colors.orange;
      case TimeWindowStatus.passed:
        return Colors.red.shade400;
      case TimeWindowStatus.upcoming:
        return Colors.blue;
    }
  }

  Widget _buildStatusWidget(TimeWindowStatus status, int secondsTo) {
    switch (status) {
      case TimeWindowStatus.active:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            activeStatusLabel,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      case TimeWindowStatus.activeApproaching:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'ZBLIŻA SIĘ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      case TimeWindowStatus.activeSecondary:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'W OKNIE',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      case TimeWindowStatus.passed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'CZAS MINĄŁ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      case TimeWindowStatus.upcoming:
        return Text(
          _formatTimeRemaining(secondsTo),
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }

  String _formatTimeRemaining(int seconds) {
    if (seconds < 60) {
      return 'za ${seconds}s';
    } else if (seconds < 300) {
      // Poniżej 5 minut - pokaż minuty i sekundy
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return 'za ${minutes}min ${secs}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return 'za ${minutes}min';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return 'za ${hours}h ${minutes}min';
    }
  }

  Widget _buildSimpleCountdown(int secondsToScheduled, bool isPassed) {
    if (isPassed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'MINĘŁO',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (secondsToScheduled <= 0 && secondsToScheduled > -179) {
      // Odjazd/Przyjazd teraz (w ciągu ostatnich 2:59)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          activeStatusLabel,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    // Przed odjazdem - pokaż odliczanie
    return Text(
      _formatTimeRemaining(secondsToScheduled),
      style: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    );
  }
}
