# Jazdy nocne

Aplikacja ułatwiająca trzymanie czasu odjazdu zgodnie z rozkładem jazd nocnych metra warszawskiego, na liniach M1 i M2.

> Aplikacja przeznaczona wyłącznie do użytku prywatnego. Nie używaj jej podczas prowadzenia pociągu!

## Funkcje

- Nocne rozkłady linii M1 i M2 na piątek i sobotę
- Wybór linii, dnia, kierunku i obiegu; aplikacja zapamiętuje wybór do następnego uruchomienia
- Odliczanie czasu do odjazdu i podświetlenie aktywnej stacji
- Alert zbliżającego się odjazdu: baner i komunikat głosowy, od 10 do 120 sekund przed odjazdem
- Ręczne ustawianie czasu, żeby sprawdzić rozkład poza godzinami kursów
- Przyciemnianie ekranu i blokada wygaszania
- Sprawdzanie przy starcie, czy jest nowsza wersja

## Instalacja

Aplikacja działa na Androidzie 7 lub nowszym.

1. Pobierz plik [jazdy-nocne.apk](https://github.com/pablop76/jazdy-nocne/releases/latest/download/jazdy-nocne.apk) z [najnowszego wydania](https://github.com/pablop76/jazdy-nocne/releases/latest).
2. Otwórz pobrany plik i zezwól na instalację z tego źródła.

Jeden plik pasuje do wszystkich telefonów, nie trzeba wybierać wersji pod procesor.

**Masz wersję 2.5 lub starszą?** Najpierw ją odinstaluj. Od wersji 2.6.0 aplikacja ma nowy podpis i Android nie zainstaluje jej na starej.

## Aktualizacje

Od wersji 2.6.0 aplikacja przy uruchomieniu sama sprawdza, czy jest nowsze wydanie. Jeśli jest, pokazuje okno z przyciskiem „Aktualizuj”, pobiera plik i otwiera instalator. Za pierwszym razem Android poprosi o zgodę na instalowanie aplikacji z tego źródła.

Lista zmian w kolejnych wersjach jest na stronie [wydań](https://github.com/pablop76/jazdy-nocne/releases).

## Dla programistów

Projekt jest napisany we Flutterze. Plik `pubspec.yaml` i katalog `lib/` leżą bezpośrednio w katalogu repozytorium.

```bash
git clone https://github.com/pablop76/jazdy-nocne.git
cd jazdy-nocne
flutter pub get
flutter run
```

### iOS

1. Otwórz projekt w Xcode: `open ios/Runner.xcworkspace`.
2. Skonfiguruj podpisywanie aplikacji (Apple Developer Account).
3. Zbuduj i zainstaluj aplikację: `flutter build ios` albo bezpośrednio z Xcode.

Sprawdzanie aktualizacji działa tylko na Androidzie.

### Wydanie nowej wersji na Androida

1. Podnieś `version` w `pubspec.yaml`, na przykład z `2.6.0+26` na `2.7.0+27`. Obie części muszą rosnąć.
2. Zbuduj plik: `flutter build apk --release`.
3. Skopiuj `build/app/outputs/flutter-apk/app-release.apk` pod nazwą `jazdy-nocne.apk`.
4. Opublikuj wydanie z tagiem zgodnym z wersją: `gh release create v2.7.0 jazdy-nocne.apk`.

Aplikacja porównuje swoją wersję z tagiem najnowszego wydania i pobiera z niego plik `.apk`.

Wydania są podpisywane kluczem opisanym w pliku `android/key.properties`, którego nie ma w repozytorium. Bez tego pliku Gradle podpisuje aplikację kluczem debugowym. Takiej wersji nie publikuj, bo telefony przyjmują aktualizację tylko z tym samym podpisem.
