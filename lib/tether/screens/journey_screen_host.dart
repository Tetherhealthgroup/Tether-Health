import 'package:flutter/material.dart';

import '../journey/journey.dart';
import 'artwork_screen.dart';
import 'content_screen.dart';
import 'unbuilt_screen.dart';
import 'unwritten_screen.dart';

/// Picks the renderer that can tell the truth about a screen.
///
/// Every route in the app goes through here rather than pushing a renderer
/// directly, because whether a screen has copy is a property of the data and
/// not of the caller. A caller that chose its own renderer would have to
/// re-derive readiness at every push site, and the first one to get it wrong
/// would render an unwritten screen as a blank page.
///
/// The switch is exhaustive over [JourneyReadiness] with no default arm, and
/// that has already paid for itself once: adding [JourneyReadiness.artwork]
/// for BreatheFree's approved screens was a compile error here rather than 23
/// screens quietly continuing to render as stubs.
class JourneyScreenHost extends StatelessWidget {
  const JourneyScreenHost({
    required this.screen,
    required this.journey,
    required this.onNavigate,
    super.key,
  });

  final JourneyScreen screen;
  final Journey journey;

  /// Receives a screen id. All three renderers navigate the same way, so the
  /// single thing a caller has to supply is how an id becomes a page.
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return switch (screen.readiness) {
      JourneyReadiness.authored => ContentScreen(
          screen: screen,
          journey: journey,
          onNavigate: onNavigate,
        ),
      JourneyReadiness.artwork => ArtworkScreen(
          screen: screen,
          journey: journey,
          onNavigate: onNavigate,
        ),
      JourneyReadiness.awaitingCopy => UnwrittenScreen(
          screen: screen,
          journey: journey,
          onNavigate: onNavigate,
        ),
      JourneyReadiness.awaitingArchetype => UnbuiltScreen(
          screen: screen,
          journey: journey,
          onNavigate: onNavigate,
        ),
    };
  }
}
