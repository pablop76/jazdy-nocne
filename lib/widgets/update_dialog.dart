import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

import '../services/update_service.dart';

/// Okno z propozycją pobrania i instalacji nowszej wersji aplikacji
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.update});

  final AppUpdate update;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  StreamSubscription<OtaEvent>? _subscription;
  bool _downloading = false;
  int _progress = 0;
  String? _error;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startUpdate() {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });
    _subscription?.cancel();
    _subscription = OtaUpdate()
        .execute(widget.update.apkUrl, destinationFilename: 'jazdy-nocne.apk')
        .listen(
          _onEvent,
          onError: (_) => _fail('Nie udało się pobrać aktualizacji.'),
        );
  }

  void _onEvent(OtaEvent event) {
    if (!mounted) return;
    switch (event.status) {
      case OtaStatus.DOWNLOADING:
        setState(() {
          _progress = int.tryParse(event.value ?? '') ?? _progress;
        });
      case OtaStatus.INSTALLING:
        // Dalej prowadzi systemowy instalator Androida
        Navigator.of(context).pop();
      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        _fail(
          'Zezwól na instalowanie aplikacji z tego źródła i spróbuj ponownie.',
        );
      default:
        _fail(
          'Nie udało się pobrać aktualizacji. Sprawdź internet i spróbuj ponownie.',
        );
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _downloading = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // W trakcie pobierania okna nie da się zamknąć
      canPop: !_downloading,
      child: AlertDialog(
        title: const Text('Dostępna aktualizacja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nowa wersja: ${widget.update.version}\n'
              'Zainstalowana: ${widget.update.currentVersion}',
            ),
            if (_downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress / 100),
              const SizedBox(height: 8),
              Text('Pobieranie… $_progress%'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
        actions: _downloading
            ? null
            : [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Później'),
                ),
                FilledButton(
                  onPressed: _startUpdate,
                  child: Text(
                    _error == null ? 'Aktualizuj' : 'Spróbuj ponownie',
                  ),
                ),
              ],
      ),
    );
  }
}
