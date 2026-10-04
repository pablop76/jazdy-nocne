import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/route_data.dart';
import '../data/route_data_m2.dart';
import '../models/deadhead.dart';
import '../models/route_point.dart';
import '../services/direction_service.dart';
import '../services/schedule_day.dart';
import '../services/update_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/route_point_card.dart';
import '../widgets/update_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum MetroLine { m1, m2 }

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const double _cardHeight = 120.0; // Stała wysokość karty
  // Klucze zapamiętanego wyboru (linia, obieg) i ustawień
  static const String _prefLine = 'metro_line';
  static const String _prefCircuit = 'circuit';
  static const String _prefTimeWindow = 'time_window';
  static const String _prefDimming = 'screen_dimming';
  static const String _prefKeepScreenOn = 'keep_screen_on';
  static const String _prefAlertEnabled = 'alert_enabled';
  static const String _prefAlertThreshold = 'alert_threshold';
  late Timer _timer;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  final AudioPlayer _audioPlayer =
      AudioPlayer(); // Player do dźwięku powitalnego
  final FlutterTts _tts = FlutterTts();
  // Czas pokazywany przez aplikację: zegar telefonu plus przesunięcie testowe
  DateTime _currentTime = DateTime.now();
  // Przesunięcie czasu testowego; zero oznacza czas rzeczywisty
  Duration _timeOffset = Duration.zero;
  MetroLine _metroLine = MetroLine.m1;
  // Kierunek nie jest wybierany: wynika z rozkładu obiegu i godziny
  Direction _direction = Direction.mlociny;
  // Rozkład piątkowy albo sobotni; domyślnie według daty
  DayType _dayType = ScheduleDay.forTime(DateTime.now());
  // Dzień ostatnio ustawiony automatycznie na podstawie daty
  DayType _autoDayType = ScheduleDay.forTime(DateTime.now());
  int _selectedCircuit = 1;
  bool _showTimeWindow = true; // Przełącznik okna czasowego
  bool _settingsExpanded =
      false; // Czy ustawienia są rozwinięte (domyślnie zwinięte)
  String? _lastActiveStationId; // Do śledzenia zmiany aktywnej stacji
  bool _initialScrollDone = false; // Czy wykonano początkowe przewinięcie
  bool _manualTimeMode = false; // Tryb ręcznego ustawiania czasu
  bool _disclaimerAccepted = false; // Czy użytkownik zaakceptował ostrzeżenie
  double _screenDimming = 0.0; // Przyciemnienie ekranu (0.0 - 0.8)
  bool _keepScreenOn = true; // Czy ekran ma być zawsze włączony
  int _alertThresholdSeconds = 30;
  bool _alertEnabled = true;
  bool _showAlertBanner = false;
  String _alertMessage = '';
  String? _lastAlertKey;
  Timer? _alertDismissTimer;
  String _appVersion = ''; // Numer wersji pokazywany w tytule

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Włącz utrzymywanie ekranu (domyślnie)
    WakelockPlus.enable();
    _tts.setLanguage('pl-PL');
    _tts.setSpeechRate(0.45);
    _tts.setVolume(1.0);
    _restoreSettings();
    _loadAppVersion();
    _checkForUpdate();
    _scheduleTick();
  }

  // Budzi zegar tuż po zmianie sekundy, żeby sekundy na ekranie zmieniały się
  // równo z zegarem telefonu
  void _scheduleTick() {
    final shown = DateTime.now().add(_timeOffset);
    _timer = Timer(Duration(milliseconds: 1010 - shown.millisecond), () {
      _tick();
      if (mounted) _scheduleTick();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    WakelockPlus.disable(); // Wyłącz utrzymywanie ekranu
    _alertDismissTimer?.cancel();
    _tts.stop();
    _audioPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  // Obsługa zmiany stanu aplikacji (np. pauza/wznowienie)

  // Odświeżenie zegara. Czas zawsze pochodzi z zegara telefonu, więc pauza
  // aplikacji ani zgubione takty timera nie powodują spóźnienia.
  void _tick() {
    if (!mounted) return;
    final now = DateTime.now().add(_timeOffset);
    // Przerysowanie tylko wtedy, gdy zmieniła się sekunda
    if (now.millisecondsSinceEpoch ~/ 1000 ==
        _currentTime.millisecondsSinceEpoch ~/ 1000) {
      return;
    }
    setState(() {
      _currentTime = now;
      _syncDayWithCalendar();
      _syncDirectionWithTime();
    });
    _checkAndTriggerAlert();
  }

  // Przywróć wybór i ustawienia z poprzedniego uruchomienia aplikacji
  Future<void> _restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _metroLine =
          MetroLine.values.asNameMap()[prefs.getString(_prefLine)] ??
          _metroLine;
      _selectedCircuit = prefs.getInt(_prefCircuit) ?? _selectedCircuit;
      _showTimeWindow = prefs.getBool(_prefTimeWindow) ?? _showTimeWindow;
      _screenDimming = (prefs.getDouble(_prefDimming) ?? _screenDimming)
          .clamp(0.0, 0.8)
          .toDouble();
      _keepScreenOn = prefs.getBool(_prefKeepScreenOn) ?? _keepScreenOn;
      _alertEnabled = prefs.getBool(_prefAlertEnabled) ?? _alertEnabled;
      _alertThresholdSeconds =
          (prefs.getInt(_prefAlertThreshold) ?? _alertThresholdSeconds)
              .clamp(10, 120)
              .toInt();
      _normalizeSelectedCircuit();
      _initialScrollDone = false;
      _lastActiveStationId = null;
      _syncDirectionWithTime();
    });
    if (!_keepScreenOn) WakelockPlus.disable();
  }

  // Zapamiętaj wybór i ustawienia, żeby nie ustawiać ich od nowa po ponownym
  // uruchomieniu. Dnia i kierunku tu nie ma: wynikają z daty i rozkładu.
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLine, _metroLine.name);
    await prefs.setInt(_prefCircuit, _selectedCircuit);
    await prefs.setBool(_prefTimeWindow, _showTimeWindow);
    await prefs.setDouble(_prefDimming, _screenDimming);
    await prefs.setBool(_prefKeepScreenOn, _keepScreenOn);
    await prefs.setBool(_prefAlertEnabled, _alertEnabled);
    await prefs.setInt(_prefAlertThreshold, _alertThresholdSeconds);
  }

  Future<void> _loadAppVersion() async {
    final version = await UpdateService.currentVersion();
    if (mounted) setState(() => _appVersion = version);
  }

  // Sprawdź, czy jest nowsza wersja aplikacji, i zaproponuj aktualizację
  Future<void> _checkForUpdate() async {
    final update = await UpdateService.checkForUpdate();
    if (update == null || !mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => UpdateDialog(update: update),
    );
  }

  void _scrollToActiveStation(int index) {
    // Przewiń do poprzedniej stacji (index - 1), żeby aktywna była druga widoczna
    final scrollIndex = index > 0 ? index - 1 : 0;
    final targetOffset = scrollIndex * _cardHeight;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  RoutePoint? _computePrimaryActivePoint(List<RoutePoint> routePoints) {
    if (!_isNightServiceTime()) return null;
    final activePoints = routePoints.where((point) {
      final status = point.getTimeWindowStatus(_currentTime, _selectedCircuit);
      return status == TimeWindowStatus.active ||
          status == TimeWindowStatus.activeApproaching ||
          status == TimeWindowStatus.activeSecondary;
    }).toList();
    if (activePoints.isEmpty) return null;
    RoutePoint? primary;
    int minDiff = 999999;
    for (final point in activePoints) {
      final scheduledTime = point.getNearestScheduledTime(
        _currentTime,
        _selectedCircuit,
      );
      if (scheduledTime != null) {
        final parts = scheduledTime.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final scheduled = DateTime(
          _currentTime.year,
          _currentTime.month,
          _currentTime.day,
          hour,
          minute,
        );
        final diff = (_currentTime.difference(scheduled).inSeconds).abs();
        if (diff < minDiff) {
          minDiff = diff;
          primary = point;
        }
      }
    }
    return primary;
  }

  void _checkAndTriggerAlert() {
    if (!_alertEnabled || !_disclaimerAccepted) return;
    final routePoints = _routeFor(_direction);
    final primaryPoint = _computePrimaryActivePoint(routePoints);
    if (primaryPoint == null) return;
    final secondsTo = primaryPoint.secondsToScheduled(
      _currentTime,
      _selectedCircuit,
    );
    final scheduledTime =
        primaryPoint.getNearestScheduledTime(_currentTime, _selectedCircuit) ??
        '';
    final key = '${primaryPoint.stationId}_$scheduledTime';
    if (secondsTo > 0 &&
        secondsTo <= _alertThresholdSeconds &&
        _lastAlertKey != key) {
      _lastAlertKey = key;
      final stationName = primaryPoint.name.contains(' - ')
          ? primaryPoint.name.split(' - ').last
          : primaryPoint.name;
      final ttsText = 'Za $secondsTo sekund odjazd ze stacji $stationName';
      setState(() {
        _showAlertBanner = true;
        _alertMessage = 'Za ${secondsTo}s odjazd ze stacji $stationName';
      });
      _tts.stop();
      _tts.speak(ttsText);
      _alertDismissTimer?.cancel();
      _alertDismissTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _showAlertBanner = false);
      });
    }
  }

  // Sprawdź czy aktualny czas jest w godzinach nocnych kursów (00:00 - 03:00)
  bool _isNightServiceTime() {
    final hour = _currentTime.hour;
    // Nocne kursy: od 00:00 do około 03:00
    return hour >= 0 && hour < 4;
  }

  // Stacje wybranej linii i dnia w podanym kierunku
  List<RoutePoint> _routeFor(Direction direction) {
    return _metroLine == MetroLine.m1
        ? RouteData.getRoute(direction, _dayType)
        : RouteDataM2.getRoute(direction, _dayType);
  }

  // Zjazd bez pasażerów po ostatnim kursie wybranego obiegu, jeśli go ma
  List<DeadheadStop>? _deadhead() {
    return _metroLine == MetroLine.m1
        ? RouteData.deadheads[_selectedCircuit]
        : RouteDataM2.getDeadhead(_selectedCircuit, _dayType);
  }

  // Pełna nazwa stacji wybranej linii, np. „A18 - Plac Wilsona”
  String _stationName(String stationId) {
    for (final point in _routeFor(Direction.mlociny)) {
      if (point.stationId == stationId) return point.name;
    }
    return stationId;
  }

  // Kursy wybranego obiegu w obu kierunkach, w kolejności odjazdów
  List<CircuitRun> _circuitRuns() {
    return DirectionService.runsFor({
      for (final direction in Direction.values) direction: _routeFor(direction),
    }, _selectedCircuit);
  }

  // Kierunek, w którym wybrany obieg jedzie o aktualnej godzinie
  Direction? _scheduledDirection() {
    final runs = _circuitRuns();
    if (runs.isEmpty) return null;
    final direction = DirectionService.directionAt(runs, _currentTime);
    if (direction != null) return direction;
    // Po ostatnim kursie kierunek zostaje bez zmian, a w dzień aplikacja
    // ustawia się na pierwszy kurs najbliższej nocy
    return _isNightServiceTime() ? null : runs.first.direction;
  }

  // Ustawia kierunek zgodnie z rozkładem. Wywoływać wewnątrz setState.
  void _syncDirectionWithTime() {
    final scheduled = _scheduledDirection();
    if (scheduled == null || scheduled == _direction) return;
    _direction = scheduled;
    _normalizeSelectedCircuit();
    _initialScrollDone = false;
    _lastActiveStationId = null;
  }

  // Ustawia rozkład piątkowy albo sobotni według daty z zegara telefonu.
  // Robi to tylko wtedy, gdy zaczyna się kolejna doba rozkładowa, więc dzień
  // wybrany ręcznie (np. na noc z osobnym rozkładem) zostaje do tego momentu.
  // Wywoływać wewnątrz setState.
  void _syncDayWithCalendar() {
    final scheduled = ScheduleDay.forTime(DateTime.now());
    if (scheduled == _autoDayType) return;
    _autoDayType = scheduled;
    if (scheduled == _dayType) return;
    _dayType = scheduled;
    _normalizeSelectedCircuit();
    _initialScrollDone = false;
    _lastActiveStationId = null;
  }

  // Czy zegar pokazuje czas testowy zamiast czasu telefonu
  bool get _isTestTime => _timeOffset != Duration.zero;

  List<int> _getCurrentCircuits() {
    if (_metroLine == MetroLine.m1) {
      return RouteData.availableCircuits;
    }

    return RouteDataM2.getAvailableCircuits(_direction, _dayType);
  }

  void _normalizeSelectedCircuit() {
    final circuits = _getCurrentCircuits();
    if (circuits.isEmpty) return;
    if (!circuits.contains(_selectedCircuit)) {
      _selectedCircuit = circuits.first;
    }
  }

  // Krótki opis zapamiętanego wyboru, np. „Sobota · kierunek Młociny · obieg 4”
  String _selectionSummary() {
    final day = _dayType == DayType.friday ? 'Piątek' : 'Sobota';
    return '$day · kierunek ${_directionName(_direction)} · obieg $_selectedCircuit';
  }

  // Nazwa stacji końcowej kierunku na wybranej linii
  String _directionName(Direction direction) {
    if (_metroLine == MetroLine.m1) {
      return direction == Direction.mlociny ? 'Młociny' : 'Kabaty';
    }
    return direction == Direction.mlociny ? 'Bemowo' : 'Bródno';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Jasne ikony paska stanu na ciemnym tle
      value: SystemUiOverlayStyle.light,
      child: _disclaimerAccepted ? _buildMainScreen() : _buildDisclaimer(),
    );
  }

  // Ostrzeżenie pokazywane po uruchomieniu, przed właściwym ekranem
  Widget _buildDisclaimer() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(version: _appVersion, showPhoto: false),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 72,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Uwaga',
                        style: TextStyle(
                          fontSize: 28,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderStrong),
                        ),
                        child: const Text(
                          'Korzystanie podczas prowadzenia pociągu metra '
                          'jest zabronione.',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Aplikacja przeznaczona wyłącznie\ndo użytku prywatnego.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: () {
                          // Odtwórz dźwięk powitalny
                          _audioPlayer.play(AssetSource('audio/welcome.mp3'));
                          // Zmień ekran
                          setState(() {
                            _disclaimerAccepted = true;
                          });
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(250, 52),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Rozumiem i akceptuję',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainScreen() {
    final routePoints = _routeFor(_direction);

    _normalizeSelectedCircuit();

    final isNightTime = _isNightServiceTime();
    final primaryActivePoint = _computePrimaryActivePoint(routePoints);
    // Kurs, który trwa albo zaraz ruszy, i ten po nim
    final runs = _circuitRuns();
    final currentRun = DirectionService.runAt(runs, _currentTime);
    final nextIndex = currentRun == null ? -1 : runs.indexOf(currentRun) + 1;
    final nextRun = nextIndex > 0 && nextIndex < runs.length
        ? runs[nextIndex]
        : null;

    return Stack(
      children: [
        Positioned.fill(
          child: Scaffold(
            backgroundColor: AppColors.background,
            // Klawiatura przy edycji czasu zasłania listę zamiast ściskać układ
            resizeToAvoidBottomInset: false,
            body: Column(
              children: [
                AppHeader(
                  version: _appVersion,
                  settingsTooltip: _settingsExpanded
                      ? 'Zwiń ustawienia'
                      : 'Rozwiń ustawienia',
                  onSettingsPressed: _toggleSettings,
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        if (_showAlertBanner) _buildAlertBanner(),
                        _buildLineSelector(),
                        _buildClock(),
                        _buildActiveStation(primaryActivePoint),
                        // Kierunek i obieg zmienia się tu tylko przy liście
                        // stacji; poza nią wybór pokazuje karta ustawień
                        if (isNightTime && !_settingsExpanded)
                          _buildSelectionChips(),
                        if (!_settingsExpanded) _buildSettingsToggle(),
                        // Rozwinięte ustawienia zajmują miejsce listy i same
                        // się przewijają, więc mieszczą się na każdym ekranie
                        Expanded(
                          child: _settingsExpanded
                              ? _buildSettingsPanel()
                              : !isNightTime
                              ? _buildOffHoursMessage()
                              : currentRun == null && runs.isNotEmpty
                              ? _buildCircuitFinishedMessage(runs.last)
                              : _buildStationList(
                                  routePoints,
                                  primaryActivePoint,
                                  nextRun,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Overlay przyciemniający ekran (na całej aplikacji)
        if (_screenDimming > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withValues(alpha: _screenDimming),
              ),
            ),
          ),
      ],
    );
  }

  static const TextStyle _settingLabelStyle = TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
  );
  // Podpisy przełączników i suwaków w ustawieniach
  static const TextStyle _toggleLabelStyle = TextStyle(
    fontSize: 15,
    color: AppColors.primaryLight,
  );
  static const Widget _settingsDivider = Divider(
    height: 1,
    color: AppColors.border,
  );

  // Banner alertu zbliżającego się odjazdu
  Widget _buildAlertBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _alertMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              _alertDismissTimer?.cancel();
              setState(() => _showAlertBanner = false);
            },
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  // Wybór linii metra
  Widget _buildLineSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Linia:',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          const SizedBox(width: 12),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLineSegment(MetroLine.m1, 'M1'),
                _buildLineSegment(MetroLine.m2, 'M2'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineSegment(MetroLine line, String label) {
    final selected = _metroLine == line;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selected ? null : () => _setLine(line),
      child: Container(
        width: 84,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryLight, AppColors.primary],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _setLine(MetroLine line) {
    setState(() {
      _metroLine = line;
      _normalizeSelectedCircuit();
      _initialScrollDone = false;
      _lastActiveStationId = null;
      _syncDirectionWithTime();
    });
    _saveSettings();
  }

  // Zegar; stuknięcie otwiera i zamyka pola ręcznego ustawiania czasu
  Widget _buildClock() {
    final hour = _currentTime.hour.toString().padLeft(2, '0');
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    final second = _currentTime.second.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isTestTime) _buildTestTimeBar(),
          if (_manualTimeMode) _buildManualTimeRow(),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              // Pusty wiersz rozciąga stos na całą szerokość, żeby przycisk
              // „Edycja” trafił na prawą krawędź, a nie na krawędź zegara
              const SizedBox(width: double.infinity),
              // Odstęp u góry robi miejsce na przycisk „Edycja” nad zegarem
              Padding(
                padding: EdgeInsets.only(top: _manualTimeMode ? 0 : 16),
                child: GestureDetector(
                  onTap: _toggleManualTimeMode,
                  child: Text(
                    '$hour:$minute:$second',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      // Pomarańczowy zegar to czas testowy albo jego ustawianie
                      color: _manualTimeMode || _isTestTime
                          ? AppColors.warning
                          : AppColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              if (!_manualTimeMode)
                Positioned(
                  top: 0,
                  right: 0,
                  child: TextButton.icon(
                    onPressed: _toggleManualTimeMode,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    icon: const Icon(Icons.edit, size: 15),
                    label: const Text('Edycja'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Pasek czasu testowego; stuknięcie wraca do zegara telefonu
  Widget _buildTestTimeBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.warningSurface,
        shape: const StadiumBorder(side: BorderSide(color: AppColors.warning)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _resetToRealTime,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CZAS TESTOWY',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 10),
                Icon(Icons.restore, size: 16, color: AppColors.textPrimary),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'wróć do rzeczywistego',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Pola ręcznego ustawiania czasu
  Widget _buildManualTimeRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimeField(_hourController, 'Godz'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _buildTimeField(_minuteController, 'Min'),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: _applyManualTime,
            child: const Text(
              'USTAW',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField(TextEditingController controller, String label) {
    return SizedBox(
      width: 70,
      height: 50,
      child: TextField(
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
        ),
        controller: controller,
      ),
    );
  }

  // Ustawia czas testowy: zegar idzie dalej od podanej godziny, a aplikacja
  // pamięta tylko przesunięcie względem zegara telefonu
  void _applyManualTime() {
    final hour = int.tryParse(_hourController.text);
    final minute = int.tryParse(_minuteController.text);
    if (hour == null ||
        hour < 0 ||
        hour > 23 ||
        minute == null ||
        minute < 0 ||
        minute > 59) {
      return;
    }
    final phoneNow = DateTime.now();
    final target = DateTime(
      phoneNow.year,
      phoneNow.month,
      phoneNow.day,
      hour,
      minute,
    );
    setState(() {
      _timeOffset = target.difference(phoneNow);
      _currentTime = target;
      _manualTimeMode = false; // zamknij panel edycji
      _syncDirectionWithTime();
    });
    _realignClock();
    FocusScope.of(context).unfocus();
  }

  // Koniec czasu testowego: zegar znów pokazuje czas telefonu
  void _resetToRealTime() {
    setState(() {
      _timeOffset = Duration.zero;
      _currentTime = DateTime.now();
      _manualTimeMode = false;
      _syncDirectionWithTime();
    });
    _realignClock();
    FocusScope.of(context).unfocus();
  }

  // Po zmianie przesunięcia sekundy wypadają w innym momencie, więc budzik
  // zegara trzeba nastawić od nowa
  void _realignClock() {
    _timer.cancel();
    _scheduleTick();
  }

  // Pokazuje albo chowa pola ustawiania czasu; zegar chodzi przez cały czas
  void _toggleManualTimeMode() {
    setState(() {
      _manualTimeMode = !_manualTimeMode;
      if (_manualTimeMode) {
        _hourController.text = _currentTime.hour.toString().padLeft(2, '0');
        _minuteController.text = _currentTime.minute.toString().padLeft(2, '0');
      }
    });
    if (!_manualTimeMode) FocusScope.of(context).unfocus();
  }

  // Aktywna stacja z godziną odjazdu albo informacja o braku okna
  Widget _buildActiveStation(RoutePoint? point) {
    if (point == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Brak aktywnego okna',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      );
    }
    final time =
        point.getNearestScheduledTime(_currentTime, _selectedCircuit) ??
        '--:--';
    return Container(
      height: 52,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.successDark, AppColors.success],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.successBright, width: 1.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Text('🚇', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              point.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(width: 1, color: AppColors.successBright),
          const SizedBox(width: 12),
          const Icon(Icons.access_time, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  // Pigułki z kierunkiem i obiegiem
  Widget _buildSelectionChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: _buildChip('Kierunek:', _directionName(_direction))),
          const SizedBox(width: 12),
          _buildChip('Obieg:', '$_selectedCircuit'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Karta rozwijania ustawień (po rozwinięciu zastępuje ją panel ustawień)
  Widget _buildSettingsToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _toggleSettings,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.format_list_bulleted,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Rozwiń ustawienia',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      // Zapamiętany wybór widoczny bez rozwijania ustawień
                      Text(
                        _selectionSummary(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSettings() {
    setState(() {
      _settingsExpanded = !_settingsExpanded;
      // Lista stacji wraca po zwinięciu, więc przewiń ją znów do aktywnej
      _initialScrollDone = false;
      _lastActiveStationId = null;
    });
  }

  Widget _buildSettingRow(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 84, child: Text(label, style: _settingLabelStyle)),
          Expanded(child: child),
        ],
      ),
    );
  }

  // Dwupolowy wybór w kształcie pigułki
  Widget _buildSegmented<T>({
    required Map<T, String> options,
    required T selected,
    required IconData icon,
    required Color selectedIconColor,
    required ValueChanged<T> onChanged,
  }) {
    const radius = Radius.circular(21);
    final values = options.keys.toList();
    return SizedBox(
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(radius),
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final value in values)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: value == selected ? null : () => onChanged(value),
                  child: DecoratedBox(
                    // Zaznaczone pole zakrywa obrys pigułki własnym, niebieskim
                    decoration: value == selected
                        ? BoxDecoration(
                            color: AppColors.primarySurface,
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.horizontal(
                              left: value == values.first
                                  ? radius
                                  : Radius.zero,
                              right: value == values.last
                                  ? radius
                                  : Radius.zero,
                            ),
                          )
                        : const BoxDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: value == selected
                              ? selectedIconColor
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            options[value]!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              color: value == selected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Pole wyboru obiegu
  Widget _buildCircuitChip(int circuit) {
    final selected = circuit == _selectedCircuit;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primarySurface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.borderStrong,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selected
              ? null
              : () {
                  setState(() {
                    _selectedCircuit = circuit;
                    _syncDirectionWithTime();
                  });
                  _saveSettings();
                },
          child: Container(
            height: 40,
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Text(
                  '$circuit',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Rozwinięte ustawienia: stały wiersz zwijania i przewijana lista opcji
  Widget _buildSettingsPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: double.infinity,
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _toggleSettings,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Zwiń ustawienia',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_arrow_up,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
                _settingsDivider,
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(children: _buildSettingsRows()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSettingsRows() {
    return [
      // Wybór dnia (piątek / sobota-niedziela)
      _buildSettingRow(
        'Dzień:',
        _buildSegmented<DayType>(
          options: const {DayType.friday: 'Piątek', DayType.saturday: 'Sobota'},
          selected: _dayType,
          icon: Icons.nights_stay,
          selectedIconColor: AppColors.primaryLight,
          onChanged: (dayType) {
            setState(() {
              _dayType = dayType;
              _normalizeSelectedCircuit();
              _initialScrollDone = false;
              _lastActiveStationId = null;
              _syncDirectionWithTime();
            });
            _saveSettings();
          },
        ),
      ),
      _settingsDivider,
      // Kierunek wynika z rozkładu, więc jest tu tylko informacją
      _buildSettingRow(
        'Kierunek:',
        Row(
          children: [
            const Icon(Icons.train, size: 18, color: AppColors.successBright),
            const SizedBox(width: 6),
            Text(
              _directionName(_direction),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'według rozkładu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
      _settingsDivider,
      // Wybór obiegu
      _buildSettingRow(
        'Obieg:',
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final circuit in _getCurrentCircuits())
                _buildCircuitChip(circuit),
            ],
          ),
        ),
      ),
      _settingsDivider,
      const SizedBox(height: 6),
      // Przełącznik okna czasowego
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Okno czasowe', style: _toggleLabelStyle),
            const SizedBox(width: 8),
            Switch(
              value: _showTimeWindow,
              onChanged: (value) {
                setState(() {
                  _showTimeWindow = value;
                });
                _saveSettings();
              },
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _showTimeWindow ? '(-59s do +2:59)' : '(tylko godziny)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
      // Przyciemnienie ekranu
      Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Row(
          children: [
            const Icon(
              Icons.brightness_6,
              size: 20,
              color: AppColors.primaryLight,
            ),
            const SizedBox(width: 10),
            const Text('Przyciemnienie', style: _toggleLabelStyle),
            Expanded(
              child: Slider(
                value: _screenDimming,
                min: 0.0,
                max: 0.8,
                onChanged: (value) {
                  setState(() {
                    _screenDimming = value;
                  });
                },
                onChangeEnd: (_) => _saveSettings(),
              ),
            ),
          ],
        ),
      ),
      // Ekran zawsze włączony
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.screen_lock_portrait,
              size: 20,
              color: AppColors.primaryLight,
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Ekran zawsze włączony',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _toggleLabelStyle,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _keepScreenOn,
              onChanged: (value) {
                setState(() {
                  _keepScreenOn = value;
                  if (value) {
                    WakelockPlus.enable();
                  } else {
                    WakelockPlus.disable();
                  }
                });
                _saveSettings();
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      // Alert zbliżającego się odjazdu na wyróżnionym tle
      Container(
        width: double.infinity,
        color: AppColors.dangerSurface,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_active,
                  size: 20,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Alert odjazdu',
                  style: TextStyle(fontSize: 15, color: AppColors.danger),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _alertEnabled,
                  activeThumbColor: AppColors.danger,
                  onChanged: (value) {
                    setState(() => _alertEnabled = value);
                    _saveSettings();
                  },
                ),
                if (_alertEnabled) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${_alertThresholdSeconds}s',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            if (_alertEnabled)
              Slider(
                value: _alertThresholdSeconds.toDouble(),
                min: 10,
                max: 120,
                divisions: 22,
                activeColor: AppColors.danger,
                label: '${_alertThresholdSeconds}s',
                onChanged: (value) =>
                    setState(() => _alertThresholdSeconds = value.round()),
                onChangeEnd: (_) => _saveSettings(),
              ),
          ],
        ),
      ),
    ];
  }

  // Lista stacji z przewijaniem do aktywnej
  Widget _buildStationList(
    List<RoutePoint> routePoints,
    RoutePoint? primaryActivePoint,
    CircuitRun? nextRun,
  ) {
    // Znajdź indeks aktywnej stacji
    int activeIndex = -1;
    if (primaryActivePoint != null) {
      activeIndex = routePoints.indexWhere(
        (p) => p.stationId == primaryActivePoint.stationId,
      );
    }

    // Przewiń do aktywnej stacji przy pierwszym uruchomieniu lub zmianie stacji
    if (activeIndex >= 0) {
      final currentActiveId = primaryActivePoint?.stationId;
      if (!_initialScrollDone || _lastActiveStationId != currentActiveId) {
        _lastActiveStationId = currentActiveId;
        _initialScrollDone = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActiveStation(activeIndex);
        });
      }
    } else if (!_initialScrollDone) {
      // Bez aktywnej stacji (np. tuż po zmianie kierunku) pokaż najbliższy
      // odjazd zamiast miejsca, w którym lista stała wcześniej
      _initialScrollDone = true;
      final nextIndex = routePoints.indexWhere(
        (point) =>
            point.getTimeWindowStatus(_currentTime, _selectedCircuit) ==
            TimeWindowStatus.upcoming,
      );
      if (nextIndex >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActiveStation(nextIndex);
        });
      }
    }

    return ListView.builder(
      controller: _scrollController,
      itemExtent: _cardHeight,
      padding: const EdgeInsets.only(bottom: 8),
      // Ostatnia pozycja to zapowiedź następnego kursu
      itemCount: routePoints.length + 1,
      itemBuilder: (context, index) {
        if (index == routePoints.length) return _buildNextRunCard(nextRun);
        return RoutePointCard(
          point: routePoints[index],
          currentTime: _currentTime,
          circuit: _selectedCircuit,
          showTimeWindow: _showTimeWindow,
          primaryActiveStationId: primaryActivePoint?.stationId,
          direction: _direction,
        );
      },
    );
  }

  // Karta na końcu listy: następny kurs obiegu, zjazd bez pasażerów albo
  // informacja, że to ostatni kurs
  Widget _buildNextRunCard(CircuitRun? nextRun) {
    final deadhead = nextRun == null ? _deadhead() : null;
    final String title;
    final String text;
    if (nextRun != null) {
      title = 'Następny kurs';
      text =
          'Odjazd ${DirectionService.formatMinutes(nextRun.start)} · '
          '${nextRun.startStation} → ${_directionName(nextRun.direction)}';
    } else if (deadhead != null) {
      title = 'Po tym kursie';
      text =
          'Zjazd bez pasażerów ${deadhead.first.time}\n'
          '${_stationName(deadhead.first.stationId)} → '
          '${_stationName(deadhead.last.stationId)}';
    } else {
      title = 'Koniec kursów';
      text = 'To ostatni kurs obiegu $_selectedCircuit';
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            nextRun == null && deadhead == null
                ? Icons.flag_outlined
                : Icons.swap_vert,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Komunikat poza godzinami nocnych kursów
  Widget _buildOffHoursMessage() {
    return _buildMessageCard(
      icon: Icons.nightlight_round,
      title: 'Poza godzinami nocnych kursów',
      text:
          'Nocne kursy metra odbywają się\nw godzinach 00:00 - 03:00\n(piątek/sobota i sobota/niedziela)',
      hint: 'Użyj edycji czasu powyżej,\naby przetestować rozkład',
    );
  }

  // Komunikat po ostatnim kursie obiegu; jeśli obieg ma jeszcze zjazd bez
  // pasażerów, pod spodem są jego godziny
  Widget _buildCircuitFinishedMessage(CircuitRun lastRun) {
    final deadhead = _deadhead();
    final arrival = DirectionService.formatMinutes(lastRun.end);
    return _buildMessageCard(
      icon: Icons.flag_outlined,
      title: 'Obieg $_selectedCircuit zakończył kursy',
      // Ze zjazdem całość ma się zmieścić bez przewijania, stąd jedna linia
      text: deadhead == null
          ? 'Ostatni przyjazd: $arrival\n${lastRun.endStation}'
          : 'Ostatni przyjazd: $arrival · ${lastRun.endStation}',
      extra: deadhead == null ? null : _buildDeadheadInfo(deadhead),
    );
  }

  // Zjazd bez pasażerów: kiedy rusza i o której jest na kolejnych stacjach
  Widget _buildDeadheadInfo(List<DeadheadStop> stops) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'Zjazd bez pasażerów',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _deadheadStatus(stops),
            style: const TextStyle(fontSize: 14, color: AppColors.primaryLight),
          ),
          const SizedBox(height: 10),
          for (final stop in stops)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _stationName(stop.stationId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    stop.time,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Stan zjazdu względem zegara: przed odjazdem, w trakcie albo po
  String _deadheadStatus(List<DeadheadStop> stops) {
    final toStart = stops.first
        .timeOn(_currentTime)
        .difference(_currentTime)
        .inSeconds;
    if (toStart > 0) {
      return toStart < 60
          ? 'odjazd za ${toStart}s'
          : 'odjazd za ${toStart ~/ 60}min ${toStart % 60}s';
    }
    final toEnd = stops.last
        .timeOn(_currentTime)
        .difference(_currentTime)
        .inSeconds;
    return toEnd > 0 ? 'w trakcie' : 'zakończony';
  }

  // Karta z komunikatem zamiast listy stacji
  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String text,
    String? hint,
    Widget? extra,
  }) {
    // Z dodatkową treścią karta jest ciaśniejsza, żeby nie trzeba było przewijać
    final compact = extra != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ikona z delikatnym cieniowaniem
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC9D6EA), AppColors.textMuted],
                  ).createShader(bounds),
                  child: Icon(icon, size: compact ? 36 : 76),
                ),
                SizedBox(height: compact ? 10 : 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: compact ? 6 : 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (extra != null) ...[const SizedBox(height: 14), extra],
                if (hint != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
