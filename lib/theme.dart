import 'package:flutter/material.dart';

/// Colours taken from the Figma file "Snake-watch-add-on".
class C {
  static const bg = Color(0xFF0F0F0F);
  static const card = Color(0xFF1B1B1B);
  static const card2 = Color(0xFF1C1C1C);
  static const line = Color(0xFF262626);
  static const line2 = Color(0xFF303030);
  static const green = Color(0xFF2FD46B);
  static const greenInk = Color(0xFF06210F);
  static const greenSoft = Color(0xFF17301F);
  static const greenText = Color(0xFF7FE0A5);
  static const red = Color(0xFFFF453A);
  static const redSoft = Color(0xFF26100F);
  static const redText = Color(0xFFFF8A8E);
  static const amber = Color(0xFFF5A524);
  static const blue = Color(0xFF3B82F6);
  static const text = Color(0xFFEDEDED);
  static const sub = Color(0xFFC8C8C8);
  static const muted = Color(0xFF8A8A8A);
  static const faint = Color(0xFF6E6E6E);

  // Onestop sign-in (from the Onestop Flutter source, welcome_header.dart)
  static const onestopGreen = Color(0xFF148440);
  static const onestopMint = Color(0xFFDCEFE4);
  static const onestopInk = Color(0xFF232329);
}

/// Figtree text style helper. The bundled fonts are variable fonts, so the
/// weight is passed as a font variation as well as a FontWeight.
TextStyle ft(double size, {int w = 400, Color color = C.text, double? height, double? ls}) => TextStyle(
      fontFamily: 'Figtree',
      fontSize: size,
      fontWeight: FontWeight.values[(w ~/ 100) - 1],
      fontVariations: [FontVariation('wght', w.toDouble())],
      color: color,
      height: height,
      letterSpacing: ls,
    );

TextStyle geist(double size, {int w = 500, Color color = C.onestopInk, double? height, double? ls}) => TextStyle(
      fontFamily: 'Geist',
      fontSize: size,
      fontWeight: FontWeight.values[(w ~/ 100) - 1],
      fontVariations: [FontVariation('wght', w.toDouble())],
      color: color,
      height: height,
      letterSpacing: ls,
    );

TextStyle mont(double size, {int w = 600, Color color = Colors.white}) => TextStyle(
      fontFamily: 'Montserrat',
      fontSize: size,
      fontWeight: FontWeight.values[(w ~/ 100) - 1],
      fontVariations: [FontVariation('wght', w.toDouble())],
      color: color,
    );

ThemeData buildTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: C.bg,
      fontFamily: 'Figtree',
      colorScheme: const ColorScheme.dark(primary: C.green, surface: C.bg),
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      }),
    );
