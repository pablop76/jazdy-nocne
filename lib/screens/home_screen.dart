import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../data/route_data.dart';
import '../models/route_point.dart';
import '../widgets/route_point_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const double _cardHeight = 120.0; // Stała wysokość karty
  late Timer _timer;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer(); // Player do dźwięku powitalnego
  // Aktualny czas (rzeczywisty)
  DateTime _currentTime = DateTime.now();
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Włącz utrzymywanie ekranu (domyślnie)
    WakelockPlus.enable();
    _hourController.text = _currentTime.hour.toString().padLeft(2, '0');
    _minuteController.text = _currentTime.minute.toString().padLeft(2, '0');
    // Aktualizuj czas co sekundę
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = _currentTime.add(const Duration(seconds: 1));
        });
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  // Obsługa zmiany stanu aplikacji (np. pauza/wznowienie)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Po wznowieniu aplikacji aktualizuj czas tylko jeśli NIE jesteśmy w trybie ręcznym
      if (!_manualTimeMode) {
        setState(() {
          _currentTime = DateTime.now();
          _hourController.text = _currentTime.hour.toString().padLeft(2, '0');
          _minuteController.text = _currentTime.minute.toString().padLeft(2, '0');
        });
      }
    }
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

  // Sprawdź czy aktualny czas jest w godzinach nocnych kursów (00:00 - 03:00)
  bool _isNightServiceTime() {
    final hour = _currentTime.hour;
    // Nocne kursy: od 00:00 do około 03:00
    return hour >= 0 && hour < 4;
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

    // Stacje dla wybranego kierunku i dnia (21 stacji)
    final routePoints = RouteData.getRoute(_direction, _dayType);
    
    // Sprawdź czy jesteśmy w godzinach nocnych
    final isNightTime = _isNightServiceTime();
    
    // Znajdź wszystkie aktywne punkty (w oknie czasowym)
    final activePoints = isNightTime ? routePoints.where((point) {
      final status = point.getTimeWindowStatus(_currentTime, _selectedCircuit);
      return status == TimeWindowStatus.active || 
             status == TimeWindowStatus.activeApproaching || 
             status == TimeWindowStatus.activeSecondary;
    }).toList() : <RoutePoint>[];
    
    // Znajdź główny aktywny punkt (najbliższy rozkładowemu czasowi - czyli ten z najmniejszą bezwzględną różnicą)
    RoutePoint? primaryActivePoint;
    if (activePoints.isNotEmpty) {
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
            primaryActivePoint = point;
          }
        }
      }
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Metro M1 - Jazdy Nocne'),
              centerTitle: true,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            body: Column(
        children: [
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
                      // Pola do wpisania godziny i minuty
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
                                  _manualTimeMode = true; // Pozostajemy w trybie ręcznym
                                  // Aktualizuj kontrolery
                                  _hourController.text = hour.toString().padLeft(2, '0');
                                  _minuteController.text = minute.toString().padLeft(2, '0');
                                });
                                // NIE wznawiamy timera w trybie ręcznym
                              } else {
                                // Jeśli nieprawidłowe dane, zamknij edycję i wznów timer
                                setState(() {
                                  _manualTimeMode = false;
                                });
                                _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                                  if (mounted) {
                                    setState(() {
                                      _currentTime = _currentTime.add(const Duration(seconds: 1));
                                    });
                                  }
                                });
                              }
                              FocusScope.of(context).unfocus();
                            },
                            child: const Text('USTAW', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Szybkie skoki (+/- 15 min)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _currentTime = _currentTime.subtract(const Duration(minutes: 15));
                              });
                            },
                            child: const Text('-15m', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _currentTime = _currentTime.add(const Duration(minutes: 15));
                              });
                            },
                            child: const Text('+15m', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      // Precyzyjne skoki (+/- 1 min, +/- 10 sek)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle, size: 28),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _currentTime = _currentTime.subtract(const Duration(minutes: 1));
                              });
                            },
                            tooltip: '-1 min',
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.remove, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _currentTime = _currentTime.subtract(const Duration(seconds: 10));
                              });
                            },
                            tooltip: '-10 sek',
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _currentTime = _currentTime.add(const Duration(seconds: 10));
                              });
                            },
                            tooltip: '+10 sek',
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.add_circle, size: 28),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _currentTime = _currentTime.add(const Duration(minutes: 1));
                              });
                            },
                            tooltip: '+1 min',
                          ),
                        ],
                      ),
                    ],
                  ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _manualTimeMode = !_manualTimeMode;
                      if (_manualTimeMode) {
                        _timer.cancel();
                      } else {
                        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                          setState(() {
                            _currentTime = _currentTime.add(const Duration(seconds: 1));
                          });
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
                      if (_manualTimeMode)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.edit, color: Colors.orange, size: 24),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (primaryActivePoint != null)
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
                            Text(
                              primaryActivePoint.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                          icon: Icon(Icons.weekend),
                        ),
                      ],
                      selected: {_dayType},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _dayType = newSelection.first;
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
                      segments: const [
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
                      ],
                      selected: {_direction},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _direction = newSelection.first;
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
                      children: RouteData.availableCircuits.map((circuit) {
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
          // Lista punktów lub komunikat o braku kursów
          Expanded(
            child: isNightTime 
              ? Builder(
                  builder: (context) {
                    // Znajdź indeks aktywnej stacji
                    int activeIndex = -1;
                    if (primaryActivePoint != null) {
                      activeIndex = routePoints.indexWhere((p) => p.stationId == primaryActivePoint!.stationId);
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
                  child: Padding(
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
