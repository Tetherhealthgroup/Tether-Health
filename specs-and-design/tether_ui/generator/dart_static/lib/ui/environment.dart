// Tether Health UI kit — environment badge.
//
// A build that is not production can label itself: the app shell sets
// [TEnvironment.badge] to the text to show (for example the name of a test
// environment), and every screen and sheet then shows a small pill at its top
// trailing edge. With no badge (the default) nothing is drawn and nothing
// changes in any layout. The kit never chooses the text.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.g.dart';
import 'strings.dart';
import 'components.dart';
import 'tokens.dart';

/// The environment the app runs in.
abstract final class TEnvironment {
  static final ValueNotifier<String?> _badge = ValueNotifier<String?>(null);

  /// The text of the badge shown on every screen, or null for none (the
  /// default). Blank text counts as none. May be set at any time; screens
  /// already shown update.
  static String? get badge => _badge.value;
  static set badge(String? text) {
    final trimmed = text?.trim();
    _badge.value = trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// Notifies when [badge] changes.
  static ValueListenable<String?> get changes => _badge;
}

/// The badge: a small pill at the top trailing edge of a screen or sheet,
/// above its header. It takes no room when [TEnvironment.badge] is null.
/// Screen readers hear "Environment: <text>".
class TEnvironmentBadge extends StatelessWidget {
  const TEnvironmentBadge({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
        valueListenable: TEnvironment.changes,
        builder: (context, text, _) {
          if (text == null) return const SizedBox.shrink();
          final dark = TDark.of(context);
          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(TSpace.screen, 4, 12, 0),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Semantics(
                container: true,
                label: TStrings.of(context).kitEnvironment(name: text),
                child: ExcludeSemantics(
                  child: Container(
                    key: const ValueKey('environment-badge'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: dark ? TColors.tealRaised : TColors.mintStrong,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: dark ? TColors.tealBorder : TColors.line),
                    ),
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
                      style: TText.tab.copyWith(fontSize: 10.5, color: dark ? TColors.onDark : TColors.teal),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
