/// Stacja zjazdu bez pasażerów z godziną co do sekundy
class DeadheadStop {
  const DeadheadStop(this.stationId, this.time);

  final String stationId;
  final String time; // "HH:mm:ss"

  /// Godzina tej stacji w dniu wskazanym przez [day]
  DateTime timeOn(DateTime day) {
    final parts = time.split(':').map(int.parse).toList();
    return DateTime(day.year, day.month, day.day, parts[0], parts[1], parts[2]);
  }
}
