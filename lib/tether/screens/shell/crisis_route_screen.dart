/// SH6 — Get help now.
///
/// `shell.json`'s `one_crisis_route` rule: "one global crisis route, identical
/// from every screen in every program", because "per-program crisis copy will
/// be wrong in at least one program. One route, reviewed once, reachable
/// everywhere." The `crisis_routing_first` safeguard goes further — emergency
/// routes "are never reordered, collapsed or filtered" — and the SH6 archetype
/// names `crisis_card_pinned_first` as a capability it cannot ship without.
///
/// **How the ordering guarantee is actually made.** The emergency card is not
/// the first element of a list of cards. It is a literal, parameterless child
/// written directly into the page body, above the loop that draws everything
/// else. There is no collection it belongs to, so there is no collection
/// anybody can sort, filter, reverse, paginate or personalise it out of. The
/// helplines below it may be reordered freely and the guarantee still holds,
/// because the guarantee is structural rather than a comment asking people to
/// be careful. [_EmergencyCard] also takes no constructor arguments at all,
/// which makes "personalise the emergency card" an edit somebody has to make
/// on purpose rather than a parameter somebody can pass.
///
/// No dialer is launched. `url_launcher` is a second runtime dependency and
/// `test/no_third_party_sdks_test.dart` fails the build if one appears, so the
/// numbers are copied to the clipboard instead — the same thing `lib/main.dart`
/// already does for the quitline number, down to the confirmation dialog and
/// the snack bar.
library;

import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../state/tether_scope.dart';
import '../../theme/tether_tokens.dart';
import '../../widgets/call_affordance.dart';
import '../../widgets/tether_page.dart';

/// The global crisis route.
///
/// Takes no arguments, and reads nothing about the person from the session
/// beyond the locale used to label a number as being in another language. It
/// is the same screen from every program because that is the rule.
class CrisisRouteScreen extends StatelessWidget {
  const CrisisRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = TetherScope.of(context);
    final bundle = session.bundle;

    return TetherPage(
      title: _shellName(bundle, 'SH6') ?? 'Get help now',
      badge: 'Always here',
      leading: LeadingControl.back,
      body: [
        // emergencyCard — "required:first".
        //
        // Written here, as a literal child, and nowhere else. It is not an
        // element of `_helplines(...)` below and never passes through a sort,
        // a filter or a locale check, so no future change to how helplines are
        // gathered can move it, drop it or push something above it.
        const _EmergencyCard(),

        // helplineCards — "required". The 988 card is written out rather than
        // taken from a product file, because it has to be here whether or not
        // any product is installed, and a crisis line that depends on which
        // program a person joined is the failure `one_crisis_route` describes.
        const _HelplineCard(
          tone: CardTone.mint,
          name: '988 Suicide & Crisis Lifeline',
          number: '988',
          detail: 'Call or text 988 · English and Spanish · 24 hours',
        ),

        // Then every helpline every product declares. Deduplicated against the
        // cards above, and against each other, because both product files
        // reach for the same numbers and a screen that listed 988 twice would
        // look like a mistake at the moment it can least afford to.
        for (final line in _helplines(bundle, session.locale))
          _HelplineCard(
            name: line.helpline.name,
            number: line.helpline.number,
            detail: line.isOtherLocale
                // TODO(copy): how a number in another language is labelled.
                // The authored SH6 card does this inline as "· Español
                // 1-855-335-3569"; here the locale is whatever the bundle says.
                ? 'Call ${line.helpline.number} · in ${line.helpline.locale}'
                : 'Call ${line.helpline.number}',
          ),

        // supporterRow — "optional". The authored version names a supporter
        // ("JORDAN") and quotes an opening line. Nothing in the session models
        // a supporter, so the name is dropped and the sentence — which is the
        // useful half — is kept.
        const _ShellCard(
          // TODO(copy): heading for the supporter prompt, with no name in it.
          title: 'Someone you trust',
          // The quoted sentence is authored SH6 copy. The rest is not.
          // TODO(copy): the surrounding explanation, including the admission
          // that this build holds nobody's contact details.
          body: '“Can you talk for ten minutes?” is usually enough to start. '
              'This build does not hold anyone’s contact details, so this '
              'is a prompt rather than a button.',
        ),

        // The promise the rest of this file exists to keep, stated on the
        // screen so that a reviewer opening the app can check it against the
        // rule without reading any Dart.
        const _ShellCard(
          tone: CardTone.mintPale,
          body: 'This screen is the same from anywhere in the app, in every program. It is never reordered or personalised.',
        ),
      ],
      actions: [
        TetherActionButton(
          label: 'Back',
          kind: 'ghost',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
      footer: 'Crisis numbers route to United States services.',
    );
  }
}

/// The card that is always first.
///
/// Deliberately takes no parameters. There is no tone to override, no copy to
/// substitute and no audience to tailor it to, so there is no signature
/// through which any of that could be attempted. Its text is a const in this
/// file rather than a lookup, because a crisis card that could fail to load is
/// a crisis card that can be blank.
class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard();

  static const _title = 'In an emergency';
  static const _body =
      'If you are in danger, or thinking about harming yourself, call 911 or '
      'your local emergency number now.';
  static const _number = '911';

  // TODO(copy): how emergency services are named in the copy dialog.
  static const _dialogName = 'emergency services';

  @override
  Widget build(BuildContext context) {
    return _ShellCard(
      tone: CardTone.coral,
      title: _title,
      body: _body,
      onTap: () =>
          _offerNumber(context, name: _dialogName, number: _number),
      children: [
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: _NumberButton(
            label: 'Call 911',
            onPressed: () => _offerNumber(
              context,
              name: _dialogName,
              number: _number,
            ),
          ),
        ),
      ],
    );
  }
}

/// One helpline.
class _HelplineCard extends StatelessWidget {
  const _HelplineCard({
    required this.name,
    required this.number,
    required this.detail,
    this.tone = CardTone.plain,
  });

  final String name;
  final String number;
  final String detail;
  final CardTone tone;

  @override
  Widget build(BuildContext context) {
    return _ShellCard(
      tone: tone,
      title: name,
      body: detail,
      onTap: () => _offerNumber(context, name: name, number: number),
      children: [
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: _NumberButton(
            // TODO(copy): the copy-number control label.
            label: 'Copy $number',
            onPressed: () => _offerNumber(context, name: name, number: number),
          ),
        ),
      ],
    );
  }
}

/// A helpline together with whether it is in the locale the session is running
/// in. Both halves are needed at the point of drawing, and returning a record
/// keeps the locale comparison in one place.
typedef _LocalisedHelpline = ({Helpline helpline, bool isOtherLocale});

/// Every helpline every product declares, deduplicated.
///
/// All locales, not just the session's. The authored SH6 card already lists
/// the Spanish quitline alongside the English one, and a person in crisis who
/// reads Spanish should not have to change an app setting to find a number
/// that was on the screen the whole time. The session's locale only decides
/// which ones get labelled as being in another language, and which come first.
List<_LocalisedHelpline> _helplines(DesignBundle bundle, String locale) {
  // 988 is already drawn as a fixed card above, so a product that also
  // declares it must not produce a second one.
  final seen = <String>{'988'};
  final matching = <_LocalisedHelpline>[];
  final other = <_LocalisedHelpline>[];

  for (final product in bundle.products.values) {
    for (final helpline in product.helplines) {
      if (helpline.number.isEmpty) continue;
      if (!seen.add(helpline.number)) continue;
      final entry = (
        helpline: helpline,
        isOtherLocale: helpline.locale != locale,
      );
      if (entry.isOtherLocale) {
        other.add(entry);
      } else {
        matching.add(entry);
      }
    }
  }

  // Sorting and grouping happen here, on the helplines only. The emergency
  // card is not in this list and cannot be affected by anything done to it.
  return [...matching, ...other];
}

/// Offers a number the only way this app can: copied, with an explanation of
/// why it was not dialled.
///
/// Delegates to [CallAffordance] rather than implementing it here. This screen
/// used to own the only copy of that dialog, and then a content card on the
/// support screen grew a "Call 988" pill of its own — which did nothing at
/// all, because the dialog lived in a file it could not reach. One
/// implementation, reachable from everywhere, is the same argument
/// `one_crisis_route` makes about the screen itself.
Future<void> _offerNumber(
  BuildContext context, {
  required String name,
  required String number,
}) =>
    CallAffordance.offer(context, name: name, number: number);

String? _shellName(DesignBundle bundle, String id) {
  for (final screen in bundle.shell.screens) {
    if (screen.id == id) return screen.name;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Local drawing
// ---------------------------------------------------------------------------

/// A pill-shaped control inside a card, forty-four logical pixels tall so that
/// it is a real tap target for somebody whose hands are not steady.
class _NumberButton extends StatelessWidget {
  const _NumberButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        foregroundColor: Colors.white,
        backgroundColor: TetherColors.ink,
        textStyle: TetherText.chip,
        shape: const RoundedRectangleBorder(borderRadius: TetherRadius.pillAll),
      ),
      child: Text(label),
    );
  }
}

/// `.cd` — the prototype's card. See `programs_home_screen.dart` for why the
/// shell screens draw their own.
class _ShellCard extends StatelessWidget {
  const _ShellCard({
    this.tone = CardTone.plain,
    this.title,
    this.body,
    this.onTap,
    this.children = const <Widget>[],
  });

  final CardTone tone;
  final String? title;
  final String? body;
  final VoidCallback? onTap;
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
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: TetherSpace.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      color: dark
                          ? TetherColors.mutedOnDark
                          : TetherColors.muted,
                    ),
                  ),
                ],
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
