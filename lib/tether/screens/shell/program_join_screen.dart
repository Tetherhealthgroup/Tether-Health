/// SH3 — Join a program.
///
/// The authored copy for this screen is written for one area (Digital
/// wellbeing) and one situation (already at the ceiling, Healthy weight about
/// to be paused). The shell only gets built once, so the screen has to be true
/// for all eleven areas and all four situations, which means every block on it
/// is assembled from the area catalogue rather than transcribed:
///
/// * **whatChanges** comes from the area's service lines — `areas.json`
///   already describes what each area does, in sentences somebody wrote on
///   purpose.
/// * **whatIsShared** comes from the area's measures, with every honesty flag
///   the bundle carries surfaced rather than smoothed over. A measure that is
///   self-reported says so; one the platform may refuse to supply says that
///   too, because iOS returns aggregate screen time only and a plausible
///   -looking zero is worse than an absence.
/// * the safeguards come from [DesignBundle.safeguardsFor], so the constraints
///   a person is promised are the same strings `tools/validate.py` enforces.
///
/// The ceiling is the part most worth getting right. `shell.json`'s
/// `two_active_max` rule says a third program "requires a conversation with a
/// clinician or coach, not a tap", and [TetherSession.join] will not pause
/// anything unless it is told which program to pause. So this screen never
/// calls join with a silent `pausing:` argument — the person has to tick the
/// trade before the button turns on.
library;

import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../state/tether_scope.dart';
import '../../state/tether_session.dart';
import '../../theme/tether_tokens.dart';
import '../../widgets/tether_page.dart';
import 'shell_routes.dart';

/// The sentence that has to survive every variant of this screen.
///
/// `shell.json` marks `scopeDisclaimer` as required, with no exceptions for
/// areas that look harmless. It is a const rather than a parameter so that no
/// caller can shorten it.
const String _scopeDisclaimer =
    'Education and self-management support. It does not diagnose, treat or '
    'prescribe, and is not a substitute for advice from a qualified health '
    'professional.';

/// What joining [area] changes, what it shares, and what it is not.
class ProgramJoinScreen extends StatefulWidget {
  const ProgramJoinScreen({required this.area, super.key});

  /// The area being considered. Passed as a route argument from SH2.
  final Area area;

  /// Builds the screen from a [RouteSettings] argument, or a visible error
  /// state when the argument is missing or the wrong type.
  ///
  /// The router pushes this route with `arguments: area`, and an `as Area`
  /// cast there would turn a bad deep link or a stale restoration into a red
  /// screen. A person who has arrived here by accident should be told so and
  /// given a way out.
  static Widget fromRouteArguments(Object? arguments, {Key? key}) {
    if (arguments is Area) return ProgramJoinScreen(area: arguments, key: key);
    return _MissingAreaScreen(key: key);
  }

  @override
  State<ProgramJoinScreen> createState() => _ProgramJoinScreenState();
}

class _ProgramJoinScreenState extends State<ProgramJoinScreen> {
  /// Whether the person has explicitly accepted that joining pauses something
  /// else.
  ///
  /// Local to this [State] and therefore to this visit. It is deliberately not
  /// kept in [TetherSession]: a trade accepted last week, against a program
  /// that may since have changed, is not consent to today's trade.
  bool _acceptedPause = false;

  @override
  Widget build(BuildContext context) {
    final session = TetherScope.of(context);
    final bundle = session.bundle;
    final area = widget.area;

    final enrolment = session.enrolment(area.id);
    final outcome = session.canJoin(area.id);
    final product = bundle.productForArea(area.id);
    final safeguards = bundle.safeguardsFor(area);

    final notImplemented = outcome.refusal == JoinRefusal.areaNotImplemented;
    final atCeiling = outcome.refusal == JoinRefusal.atActiveCeiling;
    final pauseId = outcome.wouldPause;
    final pauseName = pauseId == null ? null : _displayName(session, pauseId);

    final platformDependent = [
      for (final measure in area.measures)
        if (measure.platformDependent) measure.label,
    ];

    return TetherPage(
      title: area.name,
      badge: area.status.label,
      leading: LeadingControl.back,
      headline: 'What joining changes.',
      sub:
          'Read this before you decide. You can leave at any point and take your data with you.',
      body: [
        if (enrolment.isJoined)
          const _ShellCard(
            tone: CardTone.mint,
            // TODO(copy): already-joined notice. The authored SH3 copy has no
            // variant for somebody who is already in the program.
            title: 'You are already in this program',
            // TODO(copy): as above.
            body:
                'Nothing on this screen will start it again. Your programs is where you pause, hide or leave it.',
          ),

        // whatChanges — "required". Built from the service lines, because the
        // catalogue already says what each area does and a second description
        // written here would drift from it.
        _ShellCard(
          title: 'What it does',
          body: area.serviceLines.isEmpty
              // TODO(copy): fallback for an area with no service lines. Should
              // not happen with the shipped catalogue, and says so plainly
              // rather than rendering an empty card.
              ? 'This area has no service lines written down yet.'
              : null,
          children: [
            for (final line in area.serviceLines)
              _LabelledLine(label: line.name, value: line.description),
          ],
        ),

        if (platformDependent.isNotEmpty)
          _ShellCard(
            title: 'What it needs',
            // TODO(copy): generated from the platform-dependent measures. The
            // second sentence is the point: the honest failure mode is a gap,
            // not a zero.
            body:
                'Permission for the things your phone has to measure: ${platformDependent.join(', ').toLowerCase()}. '
                'Your phone can refuse, and where it does the number is missing rather than guessed.',
          ),

        // whatIsShared — "required".
        _ShellCard(
          tone: CardTone.mintPale,
          title: 'What your coach would see',
          // TODO(copy): the authored version names BreatheFree. This is the
          // same promise without the other program's name in it, because the
          // other program is different for everybody.
          body:
              'Totals and adherence for this program only, and only once you switch it on. Nothing from any other program, and not your notes.',
          children: [
            const SizedBox(height: 10),
            if (area.measures.isEmpty)
              const Text(
                // TODO(copy): fallback for an area with no measures.
                'This area does not record a measure yet.',
                style: TetherText.cardBody,
              ),
            for (final measure in area.measures) _MeasureLine(measure: measure),
          ],
        ),

        if (safeguards.isNotEmpty)
          _ShellCard(
            // TODO(copy): heading for the safeguard list. The statements under
            // it are `safeguards.json` verbatim.
            title: 'What it is not allowed to do',
            children: [
              for (final safeguard in safeguards)
                _LabelledLine(
                  label: safeguard.name,
                  value: safeguard.statement,
                ),
            ],
          ),

        if (area.hasClinicalThresholds)
          const _ShellCard(
            tone: CardTone.coral,
            // TODO(copy): threshold notice. `threshold_areas_separable` is a
            // build-level rule, and this is the person-facing half of it.
            title: 'This area can tell you to call someone',
            // TODO(copy): as above.
            body:
                'Some of what it records has a range where the right answer is to contact a clinician rather than log it and carry on. That also means this area may not be in every build of the app.',
          ),

        // limitNote — "optional", and present exactly when the ceiling is in
        // the way.
        if (notImplemented)
          const _ShellCard(
            tone: CardTone.coral,
            // TODO(copy): title for an area with no implementation.
            title: 'There is nothing to join yet',
            // Body is the authored SH2 sentence, reused rather than rewritten.
            body:
                'Planned areas have no implementation. We will tell you when that changes, and not before.',
          )
        else if (atCeiling && pauseName != null)
          _ShellCard(
            tone: CardTone.coral,
            title: 'You already have two active',
            // The authored sentence, with the program name substituted.
            body:
                'Joining this would pause $pauseName. You can switch back whenever you want.',
            children: [
              const SizedBox(height: 6),
              // The explicit trade. `two_active_max` exists so that the third
              // program is a decision; a button that quietly demoted something
              // would satisfy the letter of the rule and none of it.
              CheckboxListTile(
                value: _acceptedPause,
                onChanged: (value) =>
                    setState(() => _acceptedPause = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: false,
                activeColor: TetherColors.ink,
                title: Text(
                  // TODO(copy): the confirmation a person has to tick.
                  'Yes — pause $pauseName so this one can start',
                  style: TetherText.cardBody.copyWith(
                    color: TetherColors.ink,
                  ),
                ),
              ),
            ],
          )
        else if (atCeiling)
          const _ShellCard(
            tone: CardTone.coral,
            title: 'You already have two active',
            // TODO(copy): the case where the session cannot work out which
            // program to offer up. Rare, and it still may not guess.
            body:
                'Two programs are running and we cannot tell which one you would want paused. Pause one from Your programs first.',
          ),

        // The two-at-a-time rule in the shell's own words, so that a refusal
        // above is explained rather than merely enforced.
        if (bundle.shell.rule('two_active_max') case final ShellRule rule)
          _ShellCard(
            tone: CardTone.mintPale,
            // TODO(copy): eyebrow over the ceiling rule.
            eyebrow: 'The limit',
            title: rule.rule,
            body: rule.why,
          ),

        if (product != null)
          _ShellCard(
            // TODO(copy): names the product behind the area, and its status.
            title: 'Built as ${product.name}',
            // TODO(copy): as above.
            body:
                'Status: ${product.status}. Program words: ${_vocabulary(product)}.',
          ),

        // scopeDisclaimer — "required", on every variant of this screen
        // including the ones where there is nothing to join.
        const _ShellCard(tone: CardTone.mintPale, body: _scopeDisclaimer),
      ],
      actions: [
        if (!enrolment.isJoined && !notImplemented)
          TetherActionButton(
            label: atCeiling && pauseName != null
                // The authored label, with the program name substituted.
                ? 'Join and pause $pauseName'
                // TODO(copy): the label when there is room already.
                : 'Join this program',
            // Null leaves the button visibly dead rather than silently inert.
            onPressed: _canCommit(
              atCeiling: atCeiling,
              pauseName: pauseName,
            )
                ? () => _join(context, pausing: atCeiling ? pauseId : null)
                : null,
          ),
        TetherActionButton(
          label: 'Not now',
          kind: 'ghost',
          onPressed: () => _leave(context),
        ),
      ],
      footer: 'Joining asks for consent separately, in plain language.',
    );
  }

  /// Whether the join button does anything yet.
  ///
  /// At the ceiling it stays off until the trade is ticked, which is the whole
  /// mechanism by which a refusal becomes a choice rather than a surprise.
  bool _canCommit({required bool atCeiling, required String? pauseName}) {
    if (!atCeiling) return true;
    if (pauseName == null) return false;
    return _acceptedPause;
  }

  void _join(BuildContext context, {String? pausing}) {
    final session = TetherScope.of(context);
    final outcome = session.join(widget.area.id, pausing: pausing);
    if (!outcome.joined) return;
    // Back to the home screen rather than back one step, because SH2 behind
    // this one now describes a decision that has already been made.
    Navigator.of(context).popUntil(
      (route) => route.isFirst || route.settings.name == ShellRoutes.programs,
    );
  }

  void _leave(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(ShellRoutes.areas);
  }
}

/// What the screen shows when it was handed something that is not an [Area].
class _MissingAreaScreen extends StatelessWidget {
  const _MissingAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TetherPage(
      title: 'Join a program',
      leading: LeadingControl.back,
      // TODO(copy): the wrong-argument error state. Written for a person, not
      // for a log file, because this is a screen they can actually reach.
      headline: 'We lost track of which area you were reading about.',
      sub:
          'Nothing has changed and nothing has been joined. Go back to the list and pick it again.',
      body: const [
        _ShellCard(tone: CardTone.mintPale, body: _scopeDisclaimer),
      ],
      actions: [
        TetherActionButton(
          label: 'Back to your programs',
          kind: 'ghost',
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
              return;
            }
            navigator.pushReplacementNamed(ShellRoutes.programs);
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Measures
// ---------------------------------------------------------------------------

/// One measure, with every flag the bundle sets on it stated out loud.
///
/// The flags are the honest part of the catalogue and the easy part to drop.
/// A screen that listed "Minutes on chosen apps" without saying the platform
/// may refuse to supply it, or "Money saved" without saying it is an estimate,
/// would be a more comfortable screen and a less true one.
class _MeasureLine extends StatelessWidget {
  const _MeasureLine({required this.measure});

  final Measure measure;

  @override
  Widget build(BuildContext context) {
    final notes = <String>[
      // TODO(copy): flag label for `selfReported`.
      if (measure.selfReported) 'you report it',
      // TODO(copy): flag label for `derived`.
      if (measure.derived) 'worked out from your other numbers',
      // TODO(copy): flag label for `estimate`.
      if (measure.estimate) 'an estimate, never exact',
      // TODO(copy): flag label for `platformDependent`.
      if (measure.platformDependent) 'only if your phone allows it',
      // TODO(copy): flag label for `neverDiagnostic`.
      if (measure.neverDiagnostic) 'never a diagnosis',
      // TODO(copy): flag label for `clinicalThresholds`.
      if (measure.clinicalThresholds) 'can mean we tell you to call someone',
    ];

    return _LabelledLine(
      label: measure.label,
      value: notes.isEmpty
          ? measure.unit
          : '${notes.join(' · ')}${measure.unit.isEmpty ? '' : ' · ${measure.unit}'}',
    );
  }
}

/// A label over a line of explanation. The shape most of this screen is made
/// of, because every block here is "here is a thing, here is what it means".
class _LabelledLine extends StatelessWidget {
  const _LabelledLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TetherText.rowValue),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(value, style: TetherText.cardBody),
          ],
        ],
      ),
    );
  }
}

/// The words a product renames the shared concepts to. LookUp's urge is a
/// "pull"; BreatheFree's lapse is a "slip". Worth showing before somebody
/// joins, because these are the words they will be reading every day.
String _vocabulary(Product product) {
  if (product.vocabulary.isEmpty) return 'the shared ones';
  return product.vocabulary.values.join(', ');
}

String _displayName(TetherSession session, String areaId) {
  final product = session.bundle.productForArea(areaId);
  if (product != null) return product.name;
  return session.bundle.area(areaId)?.name ?? areaId;
}

// ---------------------------------------------------------------------------
// Local drawing
// ---------------------------------------------------------------------------

/// `.cd` — the prototype's card. See `programs_home_screen.dart` for why the
/// shell screens draw their own.
class _ShellCard extends StatelessWidget {
  const _ShellCard({
    this.tone = CardTone.plain,
    this.eyebrow,
    this.title,
    this.body,
    this.children = const <Widget>[],
  });

  final CardTone tone;
  final String? eyebrow;
  final String? title;
  final String? body;
  final List<Widget> children;

  Color get _fill => switch (tone) {
        CardTone.plain => TetherColors.card,
        CardTone.mint => TetherColors.mint,
        CardTone.mintPale => TetherColors.mintPale,
        CardTone.coral => TetherColors.coralPale,
        CardTone.ink => TetherColors.ink,
        CardTone.inkSoft => TetherColors.inkSoft,
      };

  @override
  Widget build(BuildContext context) {
    final dark = tone.isDark;
    final titleText = title;
    final bodyText = body;

    return Padding(
      padding: const EdgeInsets.only(bottom: TetherSpace.blockGap),
      child: Material(
        color: _fill,
        shape: RoundedRectangleBorder(
          borderRadius: TetherRadius.blockAll,
          side: tone == CardTone.plain
              ? const BorderSide(color: TetherColors.line)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        // Nothing on the join screen is tappable except its buttons. Reading
        // is the task; a card that navigated would interrupt it.
        child: Padding(
          padding: TetherSpace.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow case final String text) ...[
                Text(
                  text.toUpperCase(),
                  style: TetherText.eyebrow.copyWith(
                    color: dark ? TetherColors.mutedOnDark : TetherColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (titleText != null)
                Text(
                  titleText,
                  style: TetherText.cardTitle.copyWith(
                    color: dark ? Colors.white : TetherColors.ink,
                  ),
                ),
              if (bodyText != null) ...[
                if (titleText != null) const SizedBox(height: 4),
                Text(
                  bodyText,
                  style: TetherText.cardBody.copyWith(
                    color: dark ? TetherColors.mutedOnDark : TetherColors.muted,
                  ),
                ),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
