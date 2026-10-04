# Jazdy nocne

Aplikacja ułatwiająca trzymanie czasu odjazdu zgodnie z rozkładem jazd nocnych metra warszawskiego, na liniach M1 i M2.

> Aplikacja przeznaczona wyłącznie do użytku prywatnego. Nie używaj jej podczas prowadzenia pociągu!

## Funkcje

- Nocne rozkłady linii M1 i M2 na piątek i sobotę
- Wybór linii, dnia i obiegu; aplikacja zapamiętuje wybór do następnego uruchomienia
- Kierunek wynika z rozkładu: aplikacja pokazuje kurs, który wybrany obieg właśnie jedzie albo zaraz zacznie, i sama przełącza listę stacji na kurs powrotny
- Odliczanie czasu do odjazdu i podświetlenie aktywnej stacji
- Alert zbliżającego się odjazdu: baner i komunikat głosowy, od 10 do 120 sekund przed odjazdem
- Ręczne ustawianie czasu, żeby sprawdzić rozkład poza godzinami kursów
- Przyciemnianie ekranu i blokada wygaszania
- Sprawdzanie przy starcie, czy jest nowsza wersja

## Instalacja

Aplikacja działa na Androidzie 7 lub nowszym.

1. Pobierz plik [jazdy-nocne.apk](https://github.com/pablop76/jazdy-nocne/releases/latest/download/jazdy-nocne.apk) (ok. 18 MB) z [najnowszego wydania](https://github.com/pablop76/jazdy-nocne/releases/latest). Pasuje do prawie wszystkich telefonów.
2. Otwórz pobrany plik i zezwól na instalację z tego źródła.
3. Jeśli Google Play Protect zaproponuje sprawdzenie aplikacji, wybierz skanowanie, a po nim instalację.

Jeśli telefon zgłosi, że aplikacja nie jest zgodna z urządzeniem, masz starszy model z 32-bitowym systemem. Pobierz wtedy [jazdy-nocne-32bit.apk](https://github.com/pablop76/jazdy-nocne/releases/latest/download/jazdy-nocne-32bit.apk).

**Masz wersję 2.5 lub starszą?** Najpierw ją odinstaluj. Od wersji 2.6.0 aplikacja ma nowy podpis i Android nie zainstaluje jej na starej.

## Aktualizacje

Od wersji 2.6.0 aplikacja przy uruchomieniu sama sprawdza, czy jest nowsze wydanie. Jeśli jest, pokazuje okno z przyciskiem „Aktualizuj”, pobiera plik pasujący do telefonu i otwiera instalator. Za pierwszym razem Android poprosi o zgodę na instalowanie aplikacji z tego źródła, a Google Play Protect może zaproponować skanowanie. Po włączeniu zgody instalator sam wraca na ekran, wystarczy potwierdzić aktualizację.

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

1. Podnieś `version` w `pubspec.yaml`, na przykład z `2.6.1+27` na `2.7.0+28`. Obie części muszą rosnąć.
2. Zbuduj pliki: `flutter build apk --release --split-per-abi`.
3. Skopiuj je z `build/app/outputs/flutter-apk/` pod nazwami, których szuka aplikacja:

   | Plik z budowania | Nazwa w wydaniu | Dla kogo |
   | --- | --- | --- |
   | `app-arm64-v8a-release.apk` | `jazdy-nocne.apk` | prawie wszystkie telefony |
   | `app-armeabi-v7a-release.apk` | `jazdy-nocne-32bit.apk` | starsze telefony z 32-bitowym systemem |
   | `app-x86_64-release.apk` | `jazdy-nocne-x86_64.apk` | emulatory |

4. Opublikuj wydanie z tagiem zgodnym z wersją: `gh release create v2.7.0 jazdy-nocne.apk jazdy-nocne-32bit.apk jazdy-nocne-x86_64.apk`.

Aplikacja porównuje swoją wersję z tagiem najnowszego wydania i pobiera plik o nazwie odpowiadającej procesorowi telefonu. Jeśli w wydaniu zabraknie pliku o tej nazwie, telefon nie dostanie aktualizacji.

Wydania są podpisywane kluczem opisanym w pliku `android/key.properties`, którego nie ma w repozytorium. Bez tego pliku Gradle podpisuje aplikację kluczem debugowym. Takiej wersji nie publikuj, bo telefony przyjmują aktualizację tylko z tym samym podpisem.
