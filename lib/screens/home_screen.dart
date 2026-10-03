import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/route_data.dart';
import '../data/route_data_m2.dart';
import '../models/route_point.dart';
import '../services/update_service.dart';
import '../theme/app_colors.dart';
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
  // Klucze zapamiętanego wyboru (linia, dzień, kierunek, obieg)
  static const String _prefLine = 'metro_line';
  static const String _prefDayType = 'day_type';
  static const String _prefDirection = 'direction';
  static const String _prefCircuit = 'circuit';
  late Timer _timer;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  final AudioPlayer _audioPlayer =
      AudioPlayer(); // Player do dźwięku powitalnego
  final FlutterTts _tts = FlutterTts();
  // Aktualny czas (rzeczywisty)
  DateTime _currentTime = DateTime.now();
  MetroLine _metroLine = MetroLine.m1;
  Direction _direction = Direction.mlociny;
  DayType _dayType = DayType.saturday; // Piątek lub Sobota/Niedziela
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
    _hourController.text = _currentTime.hour.toString().padLeft(2, '0');
    _minuteController.text = _currentTime.minute.toString().padLeft(2, '0');
    _restoreSelection();
    _loadAppVersion();
    _checkForUpdate();
    // Aktualizuj czas co sekundę
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = _currentTime.add(const Duration(seconds: 1));
        });
        _checkAndTriggerAlert();
      }
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

  // Przywróć wybór z poprzedniego uruchomienia aplikacji
  Future<void> _restoreSelection() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _metroLine =
          MetroLine.values.asNameMap()[prefs.getString(_prefLine)] ??
          _metroLine;
      _dayType =
          DayType.values.asNameMap()[prefs.getString(_prefDayType)] ?? _dayType;
      _direction =
          Direction.values.asNameMap()[prefs.getString(_prefDirection)] ??
          _direction;
      _selectedCircuit = prefs.getInt(_prefCircuit) ?? _selectedCircuit;
      _normalizeSelectedCircuit();
      _initialScrollDone = false;
      _lastActiveStationId = null;
    });
  }

  // Zapamiętaj wybór, żeby nie ustawiać go od nowa po ponownym uruchomieniu
  Future<void> _saveSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLine, _metroLine.name);
    await prefs.setString(_prefDayType, _dayType.name);
    await prefs.setString(_prefDirection, _direction.name);
    await prefs.setInt(_prefCircuit, _selectedCircuit);
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
    final routePoints = _metroLine == MetroLine.m1
        ? RouteData.getRoute(_direction, _dayType)
        : RouteDataM2.getRoute(_direction, _dayType);
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
    // Pokaż overlay z ostrzeżeniem jeśli nie zaakceptowano
    if (!_disclaimerAccepted) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  '⚠️ UWAGA ⚠️',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: const Text(
                    'KORZYSTANIE PODCZAS PROWADZENIA\nPOCIĄGU METRA JEST ZABRONIONE',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Aplikacja przeznaczona wyłącznie\ndo użytku prywatnego.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Odtwórz dźwięk powitalny
                    _audioPlayer.play(AssetSource('audio/welcome.mp3'));
                    // Zmień ekran
                    setState(() {
                      _disclaimerAccepted = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'ROZUMIEM I AKCEPTUJĘ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Stacje dla wybranej linii, kierunku i dnia
    final routePoints = _metroLine == MetroLine.m1
        ? RouteData.getRoute(_direction, _dayType)
        : RouteDataM2.getRoute(_direction, _dayType);

    _normalizeSelectedCircuit();

    final isNightTime = _isNightServiceTime();
    final primaryActivePoint = _computePrimaryActivePoint(routePoints);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Jasne ikony paska stanu na ciemnym tle
      value: SystemUiOverlayStyle.light,
      child: Stack(
        children: [
          Positioned.fill(
            child: Scaffold(
              backgroundColor: AppColors.background,
              // Klawiatura przy edycji czasu zasłania listę zamiast ściskać układ
              resizeToAvoidBottomInset: false,
              body: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    if (_showAlertBanner) _buildAlertBanner(),
                    _buildLineSelector(),
                    _buildClock(),
                    _buildActiveStation(primaryActivePoint),
                    _buildSelectionChips(),
                    _buildSettingsToggle(),
                    // Rozwinięte ustawienia zajmują miejsce listy i same się
                    // przewijają, więc mieszczą się na każdym ekranie
                    Expanded(
                      child: _settingsExpanded
                          ? _buildSettingsPanel()
                          : isNightTime
                          ? _buildStationList(routePoints, primaryActivePoint)
                          : _buildOffHoursMessage(),
                    ),
                  ],
                ),
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
      ),
    );
  }

  static const TextStyle _settingLabelStyle = TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w500,
  );
  static const Widget _settingsDivider = Divider(
    height: 1,
    color: AppColors.border,
  );

  // Nagłówek: logo, nazwa z numerem wersji i skrót do ustawień
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.background, AppColors.headerGlow],
        ),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          // Zarys pociągu w tle nagłówka
          const Positioned(
            right: 48,
            child: Icon(
              Icons.directions_subway_filled,
              size: 60,
              color: AppColors.headerArt,
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'M',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Metro',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        text: 'Jazdy Nocne',
                        children: [
                          if (_appVersion.isNotEmpty)
                            TextSpan(
                              text: '   v$_appVersion',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _settingsExpanded
                    ? 'Zwiń ustawienia'
                    : 'Rozwiń ustawienia',
                icon: const Icon(Icons.settings_outlined),
                color: AppColors.textPrimary,
                onPressed: _toggleSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

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
          color: selected ? AppColors.primary : Colors.transparent,
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
      _direction = Direction.mlociny;
      _normalizeSelectedCircuit();
      _initialScrollDone = false;
      _lastActiveStationId = null;
    });
    _saveSelection();
  }

  void _setDirection(Direction direction) {
    setState(() {
      _direction = direction;
      _normalizeSelectedCircuit();
      _initialScrollDone = false;
      _lastActiveStationId = null;
    });
    _saveSelection();
  }

  // Zegar; stuknięcie przełącza tryb ręcznego ustawiania czasu
  Widget _buildClock() {
    final hour = _currentTime.hour.toString().padLeft(2, '0');
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    final second = _currentTime.second.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_manualTimeMode) _buildManualTimeRow(),
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: _toggleManualTimeMode,
                child: Text(
                  '$hour:$minute:$second',
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: _manualTimeMode
                        ? AppColors.warning
                        : AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (!_manualTimeMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Edycja czasu',
                    icon: const Icon(Icons.edit, size: 18),
                    color: AppColors.textMuted,
                    onPressed: () {
                      setState(() {
                        _manualTimeMode = true;
                      });
                    },
                  ),
                ),
            ],
          ),
        ],
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
    setState(() {
      _currentTime = DateTime(
        _currentTime.year,
        _currentTime.month,
        _currentTime.day,
        hour,
        minute,
        0,
      );
      _manualTimeMode = false; // zamknij panel edycji
      _hourController.text = hour.toString().padLeft(2, '0');
      _minuteController.text = minute.toString().padLeft(2, '0');
    });
    _restartClock();
    FocusScope.of(context).unfocus();
  }

  void _toggleManualTimeMode() {
    setState(() {
      _manualTimeMode = !_manualTimeMode;
    });
    if (_manualTimeMode) {
      _timer.cancel();
    } else {
      _restartClock();
    }
  }

  // Uruchom od nowa odliczanie sekund
  void _restartClock() {
    _timer.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = _currentTime.add(const Duration(seconds: 1));
        });
        _checkAndTriggerAlert();
      }
    });
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

  // Pigułki z kierunkiem (z szybką zmianą) i obiegiem
  Widget _buildSelectionChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: PopupMenuButton<Direction>(
              tooltip: 'Zmień kierunek',
              initialValue: _direction,
              color: AppColors.surfaceHigh,
              onSelected: _setDirection,
              itemBuilder: (context) => [
                for (final direction in Direction.values)
                  PopupMenuItem(
                    value: direction,
                    child: Text(_directionName(direction)),
                  ),
              ],
              child: _buildChip(
                'Kierunek:',
                _directionName(_direction),
                trailing: Icons.keyboard_arrow_down,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildChip('Obieg:', '$_selectedCircuit'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, {IconData? trailing}) {
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
          if (trailing != null) ...[
            const SizedBox(width: 6),
            Icon(trailing, size: 18, color: AppColors.textSecondary),
          ],
        ],
      ),
    );
  }

  // Karta zwijania ustawień
  Widget _buildSettingsToggle() {
    final expanded = _settingsExpanded;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Material(
        // Po rozwinięciu karta ma wyraźny kolor, żeby „Zwiń ustawienia”
        // nie ginęło wśród wierszy ustawień
        color: expanded ? AppColors.primary : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: expanded ? AppColors.primary : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _toggleSettings,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.format_list_bulleted,
                  size: 22,
                  color: expanded ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        expanded ? 'Zwiń ustawienia' : 'Rozwiń ustawienia',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: expanded
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                      // Zapamiętany wybór widoczny bez rozwijania ustawień
                      if (!expanded)
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
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: expanded ? Colors.white : AppColors.textSecondary,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 78, child: Text(label, style: _settingLabelStyle)),
          Expanded(child: child),
        ],
      ),
    );
  }

  // Rozwinięte ustawienia
  Widget _buildSettingsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            // Wybór dnia (piątek / sobota-niedziela)
            _buildSettingRow(
              'Dzień',
              SegmentedButton<DayType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: DayType.friday,
                    label: Text('Piątek'),
                    icon: Icon(Icons.nights_stay),
                  ),
                  ButtonSegment(
                    value: DayType.saturday,
                    label: Text('Sobota'),
                    icon: Icon(Icons.nights_stay),
                  ),
                ],
                selected: {_dayType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _dayType = newSelection.first;
                    _normalizeSelectedCircuit();
                    _initialScrollDone = false;
                    _lastActiveStationId = null;
                  });
                  _saveSelection();
                },
              ),
            ),
            _settingsDivider,
            // Wybór kierunku
            _buildSettingRow(
              'Kierunek',
              SegmentedButton<Direction>(
                showSelectedIcon: false,
                segments: [
                  for (final direction in Direction.values)
                    ButtonSegment(
                      value: direction,
                      label: Text(_directionName(direction)),
                      icon: const Icon(Icons.train),
                    ),
                ],
                selected: {_direction},
                onSelectionChanged: (newSelection) =>
                    _setDirection(newSelection.first),
              ),
            ),
            _settingsDivider,
            // Wybór obiegu
            _buildSettingRow(
              'Obieg',
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _getCurrentCircuits().map((circuit) {
                    final isSelected = circuit == _selectedCircuit;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$circuit'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCircuit = circuit;
                            });
                            _saveSelection();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            _settingsDivider,
            // Przełącznik okna czasowego
            Row(
              children: [
                const Icon(Icons.timelapse, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Okno czasowe', style: _settingLabelStyle),
                      Text(
                        _showTimeWindow ? '-59s do +2:59' : 'Tylko godziny',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _showTimeWindow,
                  onChanged: (value) {
                    setState(() {
                      _showTimeWindow = value;
                    });
                  },
                ),
              ],
            ),
            _settingsDivider,
            // Przyciemnienie ekranu
            Row(
              children: [
                const Icon(
                  Icons.brightness_6,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                const Text('Przyciemnienie', style: _settingLabelStyle),
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
                  ),
                ),
              ],
            ),
            _settingsDivider,
            // Ekran zawsze włączony
            Row(
              children: [
                const Icon(
                  Icons.screen_lock_portrait,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Ekran zawsze włączony',
                    style: _settingLabelStyle,
                  ),
                ),
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
                  },
                ),
              ],
            ),
            _settingsDivider,
            // Alert zbliżającego się odjazdu
            Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  size: 20,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Alert odjazdu', style: _settingLabelStyle),
                ),
                if (_alertEnabled)
                  Text(
                    '${_alertThresholdSeconds}s',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Switch(
                  value: _alertEnabled,
                  activeThumbColor: AppColors.danger,
                  onChanged: (value) => setState(() => _alertEnabled = value),
                ),
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
              ),
          ],
        ),
      ),
    );
  }

  // Lista stacji z przewijaniem do aktywnej
  Widget _buildStationList(
    List<RoutePoint> routePoints,
    RoutePoint? primaryActivePoint,
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
    }

    return ListView.builder(
      controller: _scrollController,
      itemExtent: _cardHeight,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: routePoints.length,
      itemBuilder: (context, index) {
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

  // Komunikat poza godzinami nocnych kursów
  Widget _buildOffHoursMessage() {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nightlight_round, size: 80, color: AppColors.textMuted),
            SizedBox(height: 24),
            Text(
              'Poza godzinami nocnych kursów',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Nocne kursy metra odbywają się\nw godzinach 00:00 - 03:00\n(piątek/sobota i sobota/niedziela)',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Text(
              'Stuknij zegar albo ołówek obok niego,\naby przetestować rozkład',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
