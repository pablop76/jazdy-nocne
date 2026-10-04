import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Nagłówek aplikacji: logo, nazwa z numerem wersji, a na ekranie głównym
/// także zdjęcie pociągów w tle i skrót do ustawień
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.version,
    this.showPhoto = true,
    this.settingsTooltip,
    this.onSettingsPressed,
  });

  final String version;
  final bool showPhoto;
  final String? settingsTooltip;
  final VoidCallback? onSettingsPressed;

  // Zdjęcie w jednej tonacji: cienie w kolorze tła, światła błękitne
  static final ColorFilter _photoTint = _duotone(
    AppColors.background,
    AppColors.headerPhotoLight,
  );

  static ColorFilter _duotone(Color shadows, Color highlights) {
    List<double> channel(double low, double high) => [
      0.2126 * (high - low),
      0.7152 * (high - low),
      0.0722 * (high - low),
      0,
      low * 255,
    ];
    return ColorFilter.matrix([
      ...channel(shadows.r, highlights.r),
      ...channel(shadows.g, highlights.g),
      ...channel(shadows.b, highlights.b),
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Nagłówek sięga pod pasek stanu, więc sam odsuwa treść od góry ekranu
    final topInset = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: showPhoto ? AppColors.background : AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Stack(
        children: [
          if (showPhoto) Positioned.fill(child: _buildPhoto()),
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 8, 4, 10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'M',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
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
                            if (version.isNotEmpty)
                              TextSpan(
                                text: '   v$version',
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
                if (onSettingsPressed != null)
                  IconButton(
                    tooltip: settingsTooltip,
                    icon: const Icon(Icons.settings_outlined),
                    color: AppColors.textPrimary,
                    onPressed: onSettingsPressed,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Zdjęcie po prawej stronie, wtopione w tło od lewej i od góry
  Widget _buildPhoto() {
    return Align(
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: 0.62,
        heightFactor: 1,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.transparent, Colors.white],
            stops: [0, 0.5],
          ).createShader(bounds),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            // Przyciemnienie u góry, żeby ikony paska stanu były czytelne
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.8),
                  AppColors.background.withValues(alpha: 0),
                ],
                stops: const [0, 0.55],
              ),
            ),
            child: ColorFiltered(
              colorFilter: _photoTint,
              child: Image.asset(
                'assets/images/header.jpg',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
