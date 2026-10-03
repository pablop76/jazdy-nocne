import 'package:flutter/material.dart';

import '../models/route_point.dart';
import '../theme/app_colors.dart';

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
    final scheduledTime =
        point.getNearestScheduledTime(currentTime, circuit) ?? '--:--';

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
        isPassed = secondsToScheduled < -179; // Uznajemy za miniony po 2:59
      }

      return _buildCard(
        accent: isPassed ? AppColors.textMuted : AppColors.primary,
        background: AppColors.surface,
        dimmed: isPassed,
        emphasized: false,
        scheduledTime: scheduledTime,
        trailing: _buildSimpleCountdown(secondsToScheduled, isPassed),
      );
    }

    final isActiveStatus =
        status == TimeWindowStatus.active ||
        status == TimeWindowStatus.activeApproaching ||
        status == TimeWindowStatus.activeSecondary;

    return _buildCard(
      accent: _getStatusColor(status),
      background: _getBackgroundColor(status),
      dimmed: false,
      emphasized: isActiveStatus,
      scheduledTime: scheduledTime,
      trailing: _buildStatusWidget(status, secondsTo),
    );
  }

  /// Karta stacji: kolorowy pasek statusu, numer, nazwa, godziny i status
  Widget _buildCard({
    required Color accent,
    required Color background,
    required bool dimmed,
    required bool emphasized,
    required String scheduledTime,
    required Widget trailing,
  }) {
    final nameColor = dimmed ? AppColors.textMuted : AppColors.textPrimary;
    final detailColor = dimmed ? AppColors.textMuted : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: emphasized ? accent.withValues(alpha: 0.6) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kolorowy pasek statusu przy lewej krawędzi
          Container(width: 4, color: accent),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: accent,
                    child: Text(
                      point.stationId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
                            fontWeight: emphasized
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 15,
                            color: nameColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$directionLabel • $departureLabel: $scheduledTime',
                          style: TextStyle(fontSize: 13, color: detailColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Pierwszy i ostatni odjazd
                        if (point.firstDepartureMonThu != null ||
                            point.lastDepartureMonThu != null) ...[
                          if (point.firstDepartureMonThu != null)
                            _buildDepartureLine(
                              'Pierwszy: ${_getEarliestTime(point.firstDepartureMonThu)}',
                              dimmed
                                  ? AppColors.textMuted
                                  : AppColors.successBright,
                            ),
                          if (point.firstDepartureFriSat != null &&
                              _getEarliestTime(point.firstDepartureFriSat) !=
                                  _getEarliestTime(point.firstDepartureMonThu))
                            _buildDepartureLine(
                              'Pierwszy (pt-sb): ${_getEarliestTime(point.firstDepartureFriSat)}',
                              dimmed
                                  ? AppColors.textMuted
                                  : AppColors.successBright,
                            ),
                          if (point.lastDepartureMonThu != null ||
                              point.lastDepartureFriSat != null)
                            _buildDepartureLine(
                              'Ostatni: ${point.lastDepartureMonThu ?? "--:--"} / ${point.lastDepartureFriSat ?? "--:--"} (pt-sb)',
                              dimmed ? AppColors.textMuted : AppColors.danger,
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartureLine(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 10.5, color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Color _getBackgroundColor(TimeWindowStatus status) {
    switch (status) {
      case TimeWindowStatus.active:
        return AppColors.successSurface;
      case TimeWindowStatus.activeApproaching:
        return AppColors.warningSurface;
      case TimeWindowStatus.activeSecondary:
        return AppColors.warningSurface;
      case TimeWindowStatus.passed:
        return AppColors.dangerSurface;
      case TimeWindowStatus.upcoming:
        return AppColors.surface;
    }
  }

  Color _getStatusColor(TimeWindowStatus status) {
    switch (status) {
      case TimeWindowStatus.active:
        return AppColors.success;
      case TimeWindowStatus.activeApproaching:
        return AppColors.warning;
      case TimeWindowStatus.activeSecondary:
        return AppColors.warning;
      case TimeWindowStatus.passed:
        return AppColors.danger;
      case TimeWindowStatus.upcoming:
        return AppColors.primary;
    }
  }

  Widget _buildStatusWidget(TimeWindowStatus status, int secondsTo) {
    switch (status) {
      case TimeWindowStatus.active:
        return _buildStatusPill(
          activeStatusLabel,
          background: AppColors.success,
          foreground: Colors.white,
        );
      case TimeWindowStatus.activeApproaching:
        return _buildStatusPill(
          'ZBLIŻA SIĘ',
          background: AppColors.warning,
          foreground: Colors.black,
        );
      case TimeWindowStatus.activeSecondary:
        return _buildStatusPill(
          'W OKNIE',
          background: AppColors.warning,
          foreground: Colors.black,
        );
      case TimeWindowStatus.passed:
        return _buildStatusPill(
          'CZAS MINĄŁ',
          background: AppColors.danger,
          foreground: Colors.white,
        );
      case TimeWindowStatus.upcoming:
        return _buildTimeRemaining(secondsTo);
    }
  }

  Widget _buildStatusPill(
    String label, {
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTimeRemaining(int seconds) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          _formatTimeRemaining(seconds),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
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
      return _buildStatusPill(
        'MINĘŁO',
        background: AppColors.surfaceHigh,
        foreground: AppColors.textMuted,
      );
    }

    if (secondsToScheduled <= 0 && secondsToScheduled > -179) {
      // Odjazd/Przyjazd teraz (w ciągu ostatnich 2:59)
      return _buildStatusPill(
        activeStatusLabel,
        background: AppColors.success,
        foreground: Colors.white,
      );
    }

    // Przed odjazdem - pokaż odliczanie
    return _buildTimeRemaining(secondsToScheduled);
  }
}
