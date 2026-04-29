import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../data/route_data.dart';
import '../data/route_data_m2.dart';
import '../models/route_point.dart';
import '../widgets/route_point_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum MetroLine { m1, m2 }

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const double _cardHeight = 120.0; // Stała wysokość karty
  late Timer _timer;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer(); // Player do dźwięku powitalnego
  final FlutterTts _tts = FlutterTts();
  // Aktualny czas (rzeczywisty)
  DateTime _currentTime = DateTime.now();
  MetroLine _metroLine = MetroLine.m1;
  Direction _direction = Direction.mlociny;
  DayType _dayType = DayType.saturday; // Piątek lub Sobota/Niedziela
  int _selectedCircuit = 1;
  bool _showTimeWindow = true; // Przełącznik okna czasowego
  bool _settingsExpanded = false; // Czy ustawienia są rozwinięte (domyślnie zwinięte)
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
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Nie resetuj _currentTime po wznowieniu aplikacji!
    // Timer w trybie rzeczywistym sam aktualizuje czas, a w trybie ręcznym czas nie powinien być nadpisywany.
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
      final scheduledTime = point.getNearestScheduledTime(_currentTime, _selectedCircuit);
      if (scheduledTime != null) {
        final parts = scheduledTime.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final scheduled = DateTime(_currentTime.year, _currentTime.month, _currentTime.day, hour, minute);
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
    final secondsTo = primaryPoint.secondsToScheduled(_currentTime, _selectedCircuit);
    final scheduledTime = primaryPoint.getNearestScheduledTime(_currentTime, _selectedCircuit) ?? '';
    final key = '${primaryPoint.stationId}_$scheduledTime';
    if (secondsTo > 0 && secondsTo <= _alertThresholdSeconds && _lastAlertKey != key) {
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

  String _directionLabelForPoint(RoutePoint point) {
    if (point.stationId.startsWith('C')) {
      return _direction == Direction.mlociny ? '→ Bemowo' : '→ Bródno';
    }
    return _direction == Direction.mlociny ? '→ Młociny' : '→ Kabaty';
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
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
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

    return Stack(
      children: [
        Positioned.fill(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Metro - Jazdy Nocne'),
              centerTitle: true,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            body: Column(
        children: [
          // Banner alertu zbliżającego się odjazdu
          if (_showAlertBanner)
            Container(
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
            ),
          // Wybór linii metra
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Linia: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                SegmentedButton<MetroLine>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: MetroLine.m1, label: Text('M1')),
                    ButtonSegment(value: MetroLine.m2, label: Text('M2')),
                  ],
                  selected: {_metroLine},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _metroLine = newSelection.first;
                      _direction = Direction.mlociny;
                      _normalizeSelectedCircuit();
                      _initialScrollDone = false;
                      _lastActiveStationId = null;
                    });
                  },
                ),
              ],
            ),
          ),
          // Nagłówek z aktualnym czasem
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Przyciski sterowania zegarem
                if (_manualTimeMode)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 70,
                            height: 50,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'Godz',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              controller: _hourController,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(
                            width: 70,
                            height: 50,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'Min',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              controller: _minuteController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () {
                              final hour = int.tryParse(_hourController.text);
                              final minute = int.tryParse(_minuteController.text);
                              if (hour != null && hour >= 0 && hour <= 23 &&
                                  minute != null && minute >= 0 && minute <= 59) {
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
                                _timer.cancel();
                                _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                                  if (mounted) {
                                    setState(() {
                                      _currentTime = _currentTime.add(const Duration(seconds: 1));
                                    });
                                    _checkAndTriggerAlert();
                                  }
                                });
                                FocusScope.of(context).unfocus();
                              }
                            },
                            child: const Text('USTAW', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (!_manualTimeMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                      label: const Text('Edycja', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        setState(() {
                          _manualTimeMode = true;
                        });
                      },
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _manualTimeMode = !_manualTimeMode;
                      if (_manualTimeMode) {
                        _timer.cancel();
                      } else {
                        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                          if (mounted) {
                            setState(() {
                              _currentTime = _currentTime.add(const Duration(seconds: 1));
                            });
                            _checkAndTriggerAlert();
                          }
                        });
                      }
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _manualTimeMode ? Colors.orange : null,
                        ),
                      ),
                      // ...ikona edycji usunięta...
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (primaryActivePoint != null)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🚇',
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    primaryActivePoint.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              primaryActivePoint.getNearestScheduledTime(_currentTime, _selectedCircuit) ?? "--:--",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Kierunek: ${_directionLabelForPoint(primaryActivePoint)}   Obieg: $_selectedCircuit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.brown.shade900,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Brak aktywnego okna',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
              ],
            ),
          ),
          // Przycisk zwijania ustawień
          InkWell(
            onTap: () {
              setState(() {
                _settingsExpanded = !_settingsExpanded;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.grey.shade300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _settingsExpanded ? 'Zwiń ustawienia' : 'Rozwiń ustawienia',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _settingsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
          // Wybór dnia (piątek / sobota-niedziela)
          if (_settingsExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.grey.shade300,
              child: Row(
                children: [
                  const Text('Dzień: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<DayType>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        iconColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.blue;
                          }
                          return Colors.grey;
                        }),
                      ),
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
                      },
                    ),
                  ),
                ],
              ),
            ),
          // Wybór kierunku
          if (_settingsExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  const Text('Kierunek: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<Direction>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        iconColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.green;
                          }
                          return Colors.grey;
                        }),
                      ),
                      segments: _metroLine == MetroLine.m1
                          ? const [
                              ButtonSegment(
                                value: Direction.mlociny,
                                label: Text('Młociny'),
                                icon: Icon(Icons.train),
                              ),
                              ButtonSegment(
                                value: Direction.kabaty,
                                label: Text('Kabaty'),
                                icon: Icon(Icons.train),
                              ),
                            ]
                          : const [
                              ButtonSegment(
                                value: Direction.mlociny,
                                label: Text('Bemowo'),
                                icon: Icon(Icons.train),
                              ),
                              ButtonSegment(
                                value: Direction.kabaty,
                                label: Text('Bródno'),
                                icon: Icon(Icons.train),
                              ),
                            ],
                      selected: {_direction},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _direction = newSelection.first;
                          _normalizeSelectedCircuit();
                          _initialScrollDone = false;
                          _lastActiveStationId = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          // Wybór obiegu
          if (_settingsExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  const Text('Obieg: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
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
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Przełącznik okna czasowego
          if (_settingsExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Okno czasowe',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  Switch(
                    value: _showTimeWindow,
                    onChanged: (value) {
                      setState(() {
                        _showTimeWindow = value;
                      });
                    },
                  ),
                  Text(
                    _showTimeWindow ? '(-59s do +2:59)' : 'Tylko godziny',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ),
          // Przyciemnienie ekranu
          if (_settingsExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.brightness_6, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Przyciemnienie',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
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
            ),
          // Ekran zawsze włączony
          if (_settingsExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.screen_lock_portrait, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Ekran zawsze włączony',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
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
            ),
          // Alert zbliżającego się odjazdu
          if (_settingsExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.red.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_active, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        'Alert odjazdu',
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      ),
                      Switch(
                        value: _alertEnabled,
                        activeThumbColor: Colors.red,
                        onChanged: (value) => setState(() => _alertEnabled = value),
                      ),
                      if (_alertEnabled)
                        Text(
                          '${_alertThresholdSeconds}s',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  if (_alertEnabled)
                    Slider(
                      value: _alertThresholdSeconds.toDouble(),
                      min: 10,
                      max: 120,
                      divisions: 22,
                      activeColor: Colors.red,
                      label: '${_alertThresholdSeconds}s',
                      onChanged: (value) =>
                          setState(() => _alertThresholdSeconds = value.round()),
                    ),
                ],
              ),
            ),
          // Lista punktów lub komunikat o braku kursów
          Expanded(
            child: isNightTime 
              ? Builder(
                  builder: (context) {
                    // Znajdź indeks aktywnej stacji
                    int activeIndex = -1;
                    if (primaryActivePoint != null) {
                      activeIndex = routePoints.indexWhere((p) => p.stationId == primaryActivePoint.stationId);
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
                  },
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Poza godzinami nocnych kursów',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nocne kursy metra odbywają się\nw godzinach 00:00 - 03:00\n(piątek/sobota i sobota/niedziela)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Użyj edycji czasu powyżej,\naby przetestować rozkład',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
        ),
      ),
      // Overlay przyciemniający ekran (na całej aplikacji w tym AppBar)
      if (_screenDimming > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withOpacity(_screenDimming),
            ),
          ),
        ),
    ],
    );
  }
}
