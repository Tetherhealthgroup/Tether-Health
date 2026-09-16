import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;

/// The design tokens and copy shared by all three intercept implementations.
///
/// Addendum §2.1 requires the intercept to be built three times — Dart, SwiftUI
/// and an Android overlay — and warns that the three drift apart within two
/// sprints unless the colours and copy live in one file all of them read. That
/// file is `assets/unplug/intercept_tokens.json`; this class is the Dart reader
/// for it.
///
/// Parsing is strict on purpose. A missing key is a token file the native
/// implementations will also fail on, and silently substituting a default here
/// would hide exactly the drift this file exists to prevent.
class InterceptTokens {
  const InterceptTokens({
    required this.version,
    required this.colors,
    required this.copy,
    required this.breathSeconds,
    required this.androidLatencyMsMin,
    required this.androidLatencyMsMax,
  });

  /// Where the token file lives in the asset bundle.
  static const assetPath = 'assets/unplug/intercept_tokens.json';

  final String version;
  final Map<String, Color> colors;
  final Map<String, String> copy;
  final int breathSeconds;
  final int androidLatencyMsMin;
  final int androidLatencyMsMax;

  Color color(String name) {
    final value = colors[name];
    if (value == null) {
      throw StateError('Intercept token file has no colour named "$name".');
    }
    return value;
  }

  /// Returns a copy string, substituting `{name}` placeholders.
  String text(String name, [Map<String, String> values = const {}]) {
    final template = copy[name];
    if (template == null) {
      throw StateError(
          'Intercept token file has no copy string named "$name".');
    }
    return values.entries.fold(
      template,
      (result, entry) => result.replaceAll('{${entry.key}}', entry.value),
    );
  }

  static Future<InterceptTokens> load() async {
    return parse(await rootBundle.loadString(assetPath));
  }

  static InterceptTokens parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Intercept token file is not a JSON object.');
    }

    final colors = _section(decoded, 'colors');
    final copy = _section(decoded, 'copy');
    final timing = _section(decoded, 'timing');

    return InterceptTokens(
      version: _string(decoded, 'version'),
      colors: {
        for (final entry in colors.entries)
          entry.key: _color(entry.key, entry.value),
      },
      copy: {
        for (final entry in copy.entries) entry.key: _copyString(entry),
      },
      breathSeconds: _int(timing, 'breathSeconds'),
      androidLatencyMsMin: _int(timing, 'androidOverlayLatencyMsMin'),
      androidLatencyMsMax: _int(timing, 'androidOverlayLatencyMsMax'),
    );
  }

  static Map<String, dynamic> _section(Map<String, dynamic> root, String key) {
    final value = root[key];
    if (value is! Map<String, dynamic>) {
      throw FormatException('Intercept token file has no "$key" object.');
    }
    return value;
  }

  static String _string(Map<String, dynamic> root, String key) {
    final value = root[key];
    if (value is! String) {
      throw FormatException('Intercept token "$key" is not a string.');
    }
    return value;
  }

  static String _copyString(MapEntry<String, dynamic> entry) {
    final value = entry.value;
    if (value is! String) {
      throw FormatException('Intercept copy "${entry.key}" is not a string.');
    }
    return value;
  }

  static int _int(Map<String, dynamic> root, String key) {
    final value = root[key];
    if (value is! int) {
      throw FormatException('Intercept token "$key" is not an integer.');
    }
    return value;
  }

  /// Parses `#RRGGBB`, the form the native implementations also read.
  static Color _color(String name, Object? value) {
    if (value is! String || value.length != 7 || !value.startsWith('#')) {
      throw FormatException('Intercept colour "$name" is not #RRGGBB.');
    }
    final channels = int.tryParse(value.substring(1), radix: 16);
    if (channels == null) {
      throw FormatException('Intercept colour "$name" is not hexadecimal.');
    }
    return Color(0xFF000000 | channels);
  }
}
