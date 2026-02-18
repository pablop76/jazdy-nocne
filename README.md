# Jazdy nocne

Aplikacja ułatwiająca trzymanie czasu odjazdu zgodnie z rozkładem jazd nocnych dla pociągów metra warszawskiego na pierwszej linii metra.

**Funkcje aplikacji:**
- Wyświetlanie stacji i rozkładów nocnych
- Odliczanie czasu do odjazdu/przyjazdu
- Tryb ręcznego ustawiania czasu
- Wybór dnia, kierunku, obiegu
- Przyciemnianie ekranu i blokada wygaszania

Pliki instalacyjne APK nie są przechowywane w repozytorium. Możesz pobrać je z mojego serwera QNAP:
[Folder z plikami APK](https://www.myqnapcloud.com/smartshare/76f015l9n2opo66q107zw34d_4dg1ij6ii0p82834r6v66y8558e5d6fj)

**Folder jest zabezpieczony hasłem. W celu uzyskania hasła napisz do mnie na mój numer telefonu.**

**Opis plików APK:**
- `app-armeabi-v7a-release.apk` – dla starszych urządzeń z procesorem ARM 32-bit (np. starsze telefony z Androidem)
- `app-arm64-v8a-release.apk` – dla większości nowoczesnych urządzeń z Androidem (smartfony, tablety z procesorem ARM 64-bit) – to najpopularniejszy wybór
- `app-x86_64-release.apk` – dla urządzeń z procesorem x86_64 (np. niektóre emulatory)

Najczęściej wybieraj plik `app-arm64-v8a-release.apk` – pasuje do większości współczesnych smartfonów.

**Instrukcja dla użytkowników Maca (kompilacja na iOS):**
1. Sklonuj repozytorium na Macu: `git clone https://github.com/pablop76/jazdy-nocne.git`
2. Otwórz katalog projektu w terminalu: `cd jazdy-nocne/flutter_application_1`
3. Zainstaluj zależności: `flutter pub get`
4. Otwórz projekt w Xcode: `open ios/Runner.xcworkspace`
5. Skonfiguruj podpisywanie aplikacji (Apple Developer Account).
6. Zbuduj i zainstaluj aplikację na iPhone/iPad: `flutter build ios` lub bezpośrednio z Xcode.

Aplikacja przeznaczona wyłącznie do użytku prywatnego. Nie używaj podczas prowadzenia pociągu!
