import 'package:flutter/material.dart';

import '../../prototype/prototype_app.dart';
import '../data/design_bundle.dart';
import '../journey/journey.dart';
import '../screens/journey_screen_host.dart';
import '../screens/program_overview_screen.dart';
import '../screens/shell/area_directory_screen.dart';
import '../screens/shell/crisis_route_screen.dart';
import '../screens/shell/program_join_screen.dart';
import '../screens/shell/programs_home_screen.dart';
import '../screens/shell/record_screen.dart';
import '../screens/shell/remedies_screen.dart';
import '../screens/shell/remedy_screen.dart';
import '../screens/shell/shell_routes.dart';
import '../screens/shell/sharing_matrix_screen.dart';
import '../state/tether_session.dart';

/// Which program a journey screen belongs to, and which screen it is.
///
/// Screens are addressed by `(areaId, screenId)` rather than by route string
/// because the same archetype appears at a different id in every area — the
/// home archetype is `S12` in LookUp and `tobacco.home` in a generated
/// journey — and because the `to` targets inside the content JSON are screen
/// ids, not paths. Turning an id into a route is this file's whole job.
@immutable
class JourneyRouteArgs {
  const JourneyRouteArgs({required this.areaId, required this.screenId});

  final String areaId;
  final String screenId;
}

/// Routes for the whole shell and every program in it.
abstract final class TetherRouter {
  /// The program index for one area.
  static const programRoute = '/program';

  /// One screen inside a program.
  static const screenRoute = '/screen';

  /// The BreatheFree bitmap prototype, kept reachable for review.
  static const prototypeRoute = '/dev/prototype';

  /// Pushes a journey screen by id, from inside [areaId].
  ///
  /// Shell ids are intercepted: `SH6` in a content file means the one global
  /// crisis route, and `shell.json` is explicit that it is identical from
  /// every screen in every program. Routing it per-program would give eleven
  /// crisis screens, which is the failure that rule exists to prevent.
  static Future<void> goToScreen(
    BuildContext context, {
    required String areaId,
    required String screenId,
  }) {
    final shellRoute = ShellRoutes.forScreenId(screenId);
    if (shellRoute != null) {
      return Navigator.of(context).pushNamed(shellRoute);
    }
    return Navigator.of(context).pushNamed(
      screenRoute,
      arguments: JourneyRouteArgs(areaId: areaId, screenId: screenId),
    );
  }

  /// Builds the route table. [session] is captured so a route can resolve a
  /// journey without the widget tree having to thread it through.
  static Route<Object?>? onGenerateRoute(
    RouteSettings settings,
    TetherSession session,
  ) {
    Route<Object?> page(Widget child) => MaterialPageRoute<Object?>(
          settings: settings,
          builder: (_) => child,
        );

    switch (settings.name) {
      case Navigator.defaultRouteName:
      case ShellRoutes.programs:
        return page(const ProgramsHomeScreen());

      case ShellRoutes.areas:
        return page(const AreaDirectoryScreen());

      case ShellRoutes.join:
        final area = settings.arguments;
        if (area is! Area) {
          return page(
            const _RouteError(
              title: 'Join a program',
              detail:
                  'This screen needs to know which area you are joining, and '
                  'it was opened without one.',
            ),
          );
        }
        return page(ProgramJoinScreen(area: area));

      case ShellRoutes.record:
        return page(const RecordScreen());

      case ShellRoutes.sharing:
        return page(const SharingMatrixScreen());

      case ShellRoutes.crisis:
        return page(const CrisisRouteScreen());

      case ShellRoutes.remedies:
        return page(const RemediesScreen());

      case programRoute:
        final areaId = settings.arguments;
        final journey = areaId is String ? session.journey(areaId) : null;
        if (journey == null) {
          return page(
            _RouteError(
              title: 'Program',
              detail: 'No program exists for "$areaId".',
            ),
          );
        }
        return page(ProgramOverviewScreen(journey: journey));

      case prototypeRoute:
        // Pushed inside the shell's Navigator, so it must not build its own
        // MaterialApp.
        return page(const TetherHealthApp(standalone: false));

      case screenRoute:
        final args = settings.arguments;
        if (args is! JourneyRouteArgs) {
          return page(
            const _RouteError(
              title: 'Screen',
              detail: 'This route was opened without a screen to show.',
            ),
          );
        }
        final journey = session.journey(args.areaId);
        final screen = journey?.screen(args.screenId);
        if (journey == null || screen == null) {
          // A content file pointing at a screen the product does not list is
          // exactly the dead end the bundle's cold-read test looks for. It is
          // reported rather than swallowed.
          return page(
            _RouteError(
              title: 'Dead end',
              detail:
                  'A button points at "${args.screenId}", which no screen in '
                  '${args.areaId} supplies.',
            ),
          );
        }
        return page(
          _JourneyScreenRoute(journey: journey, screen: screen),
        );
    }

    // Every product screen pins its own path — `/today`, `/rescue/active`,
    // `/progress`. Those are authored data, not decoration, so a name that
    // matches one resolves to that screen rather than falling through to the
    // unknown-route handler. It is what makes `flutter run --route=/progress`
    // and a future deep link land somewhere real.
    //
    // `/program/<areaId>` and `/program/<areaId>/<screenId>` address one
    // program explicitly.
    //
    // Needed because a bare product path is ambiguous: BreatheFree and LookUp
    // both pin `/onboarding/triggers`, and the rule below resolves that in
    // favour of whichever can be drawn — which means BreatheFree's screens,
    // being artwork rather than authored slots, are unreachable by path alone.
    // This is how a reviewer opens a named screen in a named program.
    final path = settings.name ?? '';

    // `/remedies/<id>` — one practice, addressed by name.
    //
    // Registered rather than pushed with an object, so the deep link and the
    // tap inside the library are the same code path. They were not: the
    // library pushed a `MaterialPageRoute` carrying the `Remedy` and merely
    // *labelled* it with this path, which meant the label named a route that
    // did not exist. `--route=/remedies/paced_breathing` then landed on the
    // home screen — `MaterialApp` walks a deep link segment by segment and
    // quietly falls back to `/` when one cannot be built, so it did not even
    // reach the unknown-route handler. A silent wrong screen is the worst of
    // the three outcomes, and a remedy is exactly the thing a notification
    // would deep-link to at the moment somebody needs it.
    if (path.startsWith('${ShellRoutes.remedies}/')) {
      final id = path.substring(ShellRoutes.remedies.length + 1);
      final remedy = session.bundle.remedy(id);
      if (remedy == null) {
        return page(
          _RouteError(
            title: 'Things that help',
            detail: 'There is no practice called "$id" any more. Open '
                'Things that help to see what there is.',
          ),
        );
      }
      return page(RemedyScreen(remedy: remedy));
    }

    if (path.startsWith('$programRoute/')) {
      final parts = path.substring(programRoute.length + 1).split('/');
      final journey = session.journey(parts.first);
      if (journey == null) {
        return page(
          _RouteError(
            title: 'Program',
            detail: 'No program exists for "${parts.first}".',
          ),
        );
      }
      if (parts.length == 1) {
        return page(ProgramOverviewScreen(journey: journey));
      }
      final screen = journey.screen(parts[1]);
      if (screen == null) {
        return page(
          _RouteError(
            title: 'Screen',
            detail: '${journey.area.name} has no screen "${parts[1]}".',
          ),
        );
      }
      return page(_JourneyScreenRoute(journey: journey, screen: screen));
    }

    // A path is not unique across programs: BreatheFree and LookUp both pin
    // `/progress`, and `behavioral` and `digital` both point at LookUp, so the
    // same name can match three journeys. A screen that can be drawn wins over
    // one that cannot — otherwise `/progress` lands on whichever program
    // happens to sort first in the catalogue, and for `/progress` that is
    // BreatheFree, whose screens are artwork with no authored slots behind
    // them. Among equals, catalogue order decides, so the choice is stable.
    final name = settings.name;
    if (name != null && name.isNotEmpty) {
      JourneyScreen? fallbackScreen;
      Journey? fallbackJourney;

      for (final journey in session.journeys.values) {
        final screen = journey.byRoute(name);
        if (screen == null) continue;
        if (screen.readiness == JourneyReadiness.authored) {
          return page(_JourneyScreenRoute(journey: journey, screen: screen));
        }
        fallbackScreen ??= screen;
        fallbackJourney ??= journey;
      }

      if (fallbackScreen != null && fallbackJourney != null) {
        return page(
          _JourneyScreenRoute(
            journey: fallbackJourney,
            screen: fallbackScreen,
          ),
        );
      }
    }

    return null;
  }
}

/// Hosts one journey screen and turns its `to` ids back into pushes.
class _JourneyScreenRoute extends StatelessWidget {
  const _JourneyScreenRoute({required this.journey, required this.screen});

  final Journey journey;
  final JourneyScreen screen;

  @override
  Widget build(BuildContext context) {
    return JourneyScreenHost(
      screen: screen,
      journey: journey,
      onNavigate: (screenId) => TetherRouter.goToScreen(
        context,
        areaId: journey.area.id,
        screenId: screenId,
      ),
    );
  }
}

/// Shown when a route is reached without what it needs.
///
/// A visible, specific error beats a blank page or a crash: this app is still
/// being reviewed against its design bundle, and the fastest way to fix a bad
/// link is to be told which link it was.
class _RouteError extends StatelessWidget {
  const _RouteError({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(detail, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
