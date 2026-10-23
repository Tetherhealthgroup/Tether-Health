// Tether Health UI kit — design tokens.
// Mirrors design/tokens.json. Every text/background pair used by the kit
// meets WCAG 2.2 AA (see tokens.json → contrast).
import 'package:flutter/material.dart';

abstract final class TColors {
  static const teal = Color(0xFF123C37);
  static const teal2 = Color(0xFF536F69);
  static const muted = Color(0xFF5A726C);
  static const mint = Color(0xFFDFF2E7);
  static const mintStrong = Color(0xFFBFE1D2);
  static const mintTint = Color(0xFFF1F8F3);
  static const cream = Color(0xFFF8F5EC);
  static const paper = Color(0xFFFFFDF7);
  static const coral = Color(0xFFFF7D61);
  static const coralFill = Color(0xFFFFE9E2);
  static const coralBorder = Color(0xFFFFC6B7);
  static const coralText = Color(0xFFB5432A);
  static const lime = Color(0xFFD5EF75);
  static const line = Color(0xFFB6C8C2);
  static const line2 = Color(0xFFDCE6E0);
  static const segBg = Color(0xFFE8EFEA);
  static const tealRaised = Color(0xFF1D514A);
  static const tealBorder = Color(0xFF3F6660);
  static const onDarkMuted = Color(0xFFB9D1C8);
  static const onDark = Color(0xFFD3E2DC);
  static const error = Color(0xFFB3261E);
  static const errorFill = Color(0xFFFDECEA);
  static const errorBorder = Color(0xFFE8A39D);
  static const errorText = Color(0xFF7A1A14);
  static const warn = Color(0xFF8A5A00);
  static const warnFill = Color(0xFFFFF5DB);
  static const warnBorder = Color(0xFFEBCB7E);
  static const warnText = Color(0xFF5C3D00);
  static const ok = Color(0xFF2E6B3A);
  static const okFill = Color(0xFFE5F3E8);
  static const okText = Color(0xFF1D4A26);
  static const disabledBg = Color(0xFFDCE3E0);
  static const disabledFg = Color(0xFF5E6E69);
  static const toggleOff = Color(0xFF9AABA6);

  static const programs = <String, Color>{
    'bf': Color(0xFFB5432A),
    'sf': Color(0xFF3B4CC0),
    'ca': Color(0xFF1D6A93),
    'hw': Color(0xFFB3263E),
    'st': Color(0xFF8A5A00),
    're': Color(0xFF1E6B68),
    'nu': Color(0xFF3F7426),
    'sd': Color(0xFF94501F),
    'ea': Color(0xFF5B4FB8),
    'ck': Color(0xFF5A661A),
    'be': Color(0xFF74428F),
  };
  static Color program(String id) => programs[id] ?? teal;
}

abstract final class TSpace {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 20.0, xxl = 24.0;
  static const screen = 20.0; // horizontal screen margin
  static const gap = 12.0; // vertical gap between blocks
}

abstract final class TRadius {
  static const control = 14.0, field = 12.0, card = 18.0, tile = 16.0, chip = 19.0, sheet = 26.0;
}

abstract final class TText {
  static const _f = <String>['Inter', 'SF Pro Text', 'Roboto'];
  static const titleM = TextStyle(fontSize: 24, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: TColors.teal, fontFamilyFallback: _f);
  static const titleL = TextStyle(fontSize: 28, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: TColors.teal, fontFamilyFallback: _f);
  static const titleXl = TextStyle(fontSize: 32, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: TColors.teal, fontFamilyFallback: _f);
  static const largeTitle = TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: TColors.teal, fontFamilyFallback: _f);
  static const headerTitle = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: TColors.teal, fontFamilyFallback: _f);
  static const body = TextStyle(fontSize: 15.5, height: 1.45, color: TColors.teal2, fontFamilyFallback: _f);
  static const muted = TextStyle(fontSize: 15, height: 1.45, color: TColors.teal2, fontFamilyFallback: _f);
  static const small = TextStyle(fontSize: 13, height: 1.4, color: TColors.muted, fontFamilyFallback: _f);
  static const eyebrow = TextStyle(fontSize: 11.5, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: TColors.muted, fontFamilyFallback: _f);
  static const label = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TColors.teal, fontFamilyFallback: _f);
  static const fieldLabel = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: TColors.teal, fontFamilyFallback: _f);
  static const input = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: TColors.teal, fontFamilyFallback: _f);
  static const optionLabel = TextStyle(fontSize: 15.5, height: 1.3, fontWeight: FontWeight.w700, color: TColors.teal, fontFamilyFallback: _f);
  static const sub = TextStyle(fontSize: 13, height: 1.35, color: TColors.muted, fontFamilyFallback: _f);
  static const cardTitle = TextStyle(fontSize: 16, height: 1.3, fontWeight: FontWeight.w700, color: TColors.teal, fontFamilyFallback: _f);
  static const cardText = TextStyle(fontSize: 13.5, height: 1.4, color: TColors.teal2, fontFamilyFallback: _f);
  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamilyFallback: _f);
  static const buttonSmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamilyFallback: _f);
  static const chip = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TColors.teal, fontFamilyFallback: _f);
  static const pill = TextStyle(fontSize: 11, letterSpacing: 0.9, fontWeight: FontWeight.w800, color: TColors.teal, fontFamilyFallback: _f);
  static const tag = TextStyle(fontSize: 11.5, letterSpacing: 0.8, fontWeight: FontWeight.w800, fontFamilyFallback: _f);
  static const stat = TextStyle(fontSize: 26, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: TColors.teal, fontFamilyFallback: _f);
  static const big = TextStyle(fontSize: 44, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.4, color: TColors.teal, fontFamilyFallback: _f);
  static const quote = TextStyle(fontFamily: 'Georgia', fontFamilyFallback: ['Georgia', 'Noto Serif', 'serif'], fontStyle: FontStyle.italic, fontSize: 20, height: 1.35, color: TColors.teal);
  static const tab = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamilyFallback: _f);
}

abstract final class TMotion {
  static const enter = Duration(milliseconds: 200);
  static const exit = Duration(milliseconds: 150);
  static const curve = Curves.easeOutCubic;
}

ThemeData tetherTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: TColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TColors.teal,
      primary: TColors.teal,
      secondary: TColors.coral,
      surface: TColors.paper,
      error: TColors.error,
    ),
    splashFactory: InkSparkle.splashFactory,
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
