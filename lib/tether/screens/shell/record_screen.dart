/// SH4 — Your record.
///
/// The `export_and_delete` safeguard asks for two capabilities by name,
/// `export_action` and `hard_delete_action`, and every one of the eleven areas
/// is bound by it. This is the one screen where both live, across every
/// program at once, because a per-program export would make "everything you
/// hold about me" a thing a person had to assemble themselves.
///
/// The authored SH4 copy promises more than this build can do, and the
/// difference matters more here than anywhere else in the shell. Its footer
/// says deletion "clears your phone, our servers and anything queued to sync";
/// there is no server in this build and nothing is queued, so repeating that
/// sentence would be describing a system that does not exist. Its export card
/// promises "a readable file plus a structured one"; writing a file needs
/// `path_provider`, which `test/no_third_party_sdks_test.dart` forbids. Both
/// are replaced here with what actually happens, and both replacements are
/// marked for copy review rather than quietly substituted.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/design_bundle.dart';
import '../../state/tether_scope.dart';
import '../../state/tether_session.dart';
import '../../theme/tether_tokens.dart';
import '../../widgets/tether_page.dart';
import 'shell_routes.dart';

/// Everything the session holds, in one place, with the two actions the
/// safeguard requires.
class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = TetherScope.of(context);
    final bundle = session.bundle;

    // One call, used for both the counts on screen and the text in the export
    // dialog, so that what a person is shown and what they can copy out cannot
    // disagree.
    final export = session.exportRecord();

    // Summed across programs rather than read from one map, because the export
    // no longer has one: answers live inside the program that recorded them,
    // and the same screen id can appear under two of them without the two
    // being the same answer. See `TetherSession.exportRecord`.
    var answeredScreens = 0;
    for (final program in (export['programs']! as List<Object?>)) {
      answeredScreens +=
          ((program! as Map<String, Object?>)['answers']! as Map).length;
    }

    final joined = [
      for (final area in bundle.areas)
        if (session.enrolment(area.id).isJoined) session.enrolment(area.id),
    ];

    return TetherPage(
      title: _shellName(bundle, 'SH4') ?? 'Your record',
      badge: 'Private',
      leading: LeadingControl.back,
      headline: 'Everything, in one place.',
      sub: 'Across every program you have joined. Yours to export or delete.',
      body: [
        // programSections — "required". Ended and paused programs are here
        // too: `EnrolmentStatus.ended` keeps its history precisely because
        // ending a program and deleting a record are two different acts, and
        // a record screen that hid the ended ones would make them the same.
        if (joined.isEmpty)
          const _ShellCard(
            // TODO(copy): empty-record title.
            title: 'There is nothing here yet',
            // TODO(copy): empty-record body.
            body: 'Once you join a program, what it records shows up here — and can be exported or deleted from here.',
          )
        else
          _RowsCard(
            items: [
              for (final enrolment in joined)
                (
                  '${_displayName(session, enrolment.areaId)} · ${_statusWord(enrolment.status)}',
                  _summarise(session, enrolment),
                ),
            ],
          ),

        // A total across every program, kept as a total. The per-program split
        // exists in the export now, but a row per program would put a count of
        // answered screens next to each programme's name on a screen somebody
        // might be looking at over a shoulder, and `discreet_program` is the
        // rule that says not to.
        _RowsCard(
          items: [
            (
              // TODO(copy): row key and value for saved screen answers.
              'Answers',
              answeredScreens == 0
                  ? 'Nothing saved on any screen yet'
                  : '$answeredScreens ${answeredScreens == 1 ? 'screen has' : 'screens have'} something saved',
            ),
            (
              // TODO(copy): row key and value for recorded slips. Phrased as a
              // count of events because `slip_never_resets` makes a lapse an
              // entry in history and never a reset of anything.
              'Slips',
              session.lapses.isEmpty
                  ? 'None recorded'
                  : '${session.lapses.length} recorded, and none of them reset anything',
            ),
          ],
        ),

        // exportAction — "required".
        _ShellCard(
          title: 'Export everything',
          // TODO(copy): replaces the authored "A readable file plus a
          // structured one", which this build cannot do without a file-system
          // dependency the app is not allowed to add.
          body: 'Shown as readable text you can copy out. Includes paused and ended programs. This build writes no file.',
          onTap: () => _showExport(context, export),
        ),

        // deleteAction — "required".
        _ShellCard(
          tone: CardTone.coral,
          title: 'Delete everything',
          body: 'Completed, not hidden. This cannot be undone, and it ends every active program.',
          onTap: () => _confirmDelete(context),
        ),

        if (bundle.safeguards['export_and_delete'] case final Safeguard safeguard)
          _ShellCard(
            tone: CardTone.mintPale,
            // TODO(copy): eyebrow over a quoted safeguard.
            eyebrow: 'The rule behind this screen',
            title: safeguard.name,
            body: safeguard.statement,
          ),
      ],
      actions: [
        TetherActionButton(
          label: 'Export',
          onPressed: () => _showExport(context, export),
        ),
        TetherActionButton(
          label: 'Back',
          kind: 'ghost',
          onPressed: () => _back(context),
        ),
      ],
      // TODO(copy): replaces the authored footer, which commits to clearing
      // servers and a sync queue. Neither exists in this build, and claiming
      // to have cleared one would be the exact failure this screen is for.
      footer: 'There is no server in this build and nothing queued to sync. Deleting clears what this phone is holding.',
    );
  }

  /// Shows the export as text, with one way to get it off the screen.
  ///
  /// A dialog rather than a share sheet: sharing needs a plugin, and a button
  /// that opened nothing would be worse than no button. Copying to the
  /// clipboard is the one route out that the Flutter SDK provides on its own,
  /// and it is the same route `lib/main.dart` already uses for the quitline
  /// number.
  Future<void> _showExport(
    BuildContext context,
    Map<String, Object?> export,
  ) async {
    final text = _renderExport(export);
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        // TODO(copy): export dialog title.
        title: const Text('Everything we hold'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(text, style: TetherText.cardBody),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            // TODO(copy): export dialog dismiss label.
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(context);
              messenger.showSnackBar(
                const SnackBar(
                  // TODO(copy): copy confirmation.
                  content: Text('Your record was copied to the clipboard'),
                ),
              );
            },
            // TODO(copy): copy action label.
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  /// Confirms a deletion by stating exactly what goes and exactly what was
  /// never there.
  ///
  /// The second half is the unusual part and the honest one.
  /// [TetherSession.deleteEverything] clears three in-memory maps; there is no
  /// persistence wired up at all in this build, so a confirmation that implied
  /// a wipe of storage or of a server would be describing work nobody did.
  Future<void> _confirmDelete(BuildContext context) async {
    final session = TetherScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // TODO(copy): delete dialog title.
        title: const Text('Delete everything?'),
        content: const SingleChildScrollView(
          // TODO(copy): the whole of this message. Every sentence is a factual
          // claim about what this build does, and a reviewer should check each
          // one against `TetherSession.deleteEverything`.
          child: Text(
            'This removes every program you have joined, every answer you have '
            'given, and every slip recorded. Paused and ended programs go too.\n\n'
            'It cannot be undone, and it ends every active program.\n\n'
            'Nothing else is cleared, because nothing else exists: this build '
            'has no server, nothing queued to sync, and nothing written to '
            'storage between launches.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            // TODO(copy): destructive confirmation label.
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    session.deleteEverything();
    messenger.showSnackBar(
      const SnackBar(
        // TODO(copy): deletion confirmation. Says what was cleared, not more.
        content: Text('Everything this phone was holding has been deleted'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summarising
// ---------------------------------------------------------------------------

/// One program's line in the record.
///
/// Assembled from parts so that a program with no join date, no slips and no
/// sharing still produces a sentence rather than a run of empty separators.
String _summarise(TetherSession session, Enrolment enrolment) {
  final joinedOn = enrolment.joinedOn;
  final lapses = session.lapsesFor(enrolment.areaId).length;
  final sharing = enrolment.sharing;

  final parts = <String>[
    // TODO(copy): each of the fragments below.
    if (joinedOn != null) 'joined ${_formatDate(joinedOn)}',
    if (lapses == 0)
      'no slips recorded'
    else
      '$lapses ${lapses == 1 ? 'slip' : 'slips'} recorded',
    if (enrolment.hidden) 'hidden from your home screen',
    if (!sharing.sharesAnything)
      'nothing shared'
    else if (sharing.totalsAndAdherence && sharing.notes)
      'sharing totals and notes'
    else if (sharing.notes)
      'sharing notes'
    else
      'sharing totals and adherence',
  ];
  return parts.join(' · ');
}

/// The word for an enrolment status.
///
/// [EnrolmentStatus] carries no display label — unlike [AreaStatus], which
/// does — so these four are written here rather than read from the bundle.
String _statusWord(EnrolmentStatus status) => switch (status) {
      // TODO(copy): each of the four status words.
      EnrolmentStatus.active => 'Active',
      EnrolmentStatus.paused => 'Paused',
      EnrolmentStatus.ended => 'Ended',
      EnrolmentStatus.none => 'Not joined',
    };

const List<String> _months = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// A date a person can read. Written out rather than formatted with `intl`,
/// which is a dependency this app is not allowed to add.
String _formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// Renders [TetherSession.exportRecord] as indented text.
///
/// The map is deliberately not run through `jsonEncode`: the point of the
/// export action is that the person it describes can read it, and JSON is a
/// format for the other side of that exchange.
String _renderExport(Object? value, {int indent = 0}) {
  final pad = '  ' * indent;

  if (value is Map<Object?, Object?>) {
    // TODO(copy): the placeholder for an empty section.
    if (value.isEmpty) return '$pad(nothing recorded)\n';
    final buffer = StringBuffer();
    for (final entry in value.entries) {
      final child = entry.value;
      if (child is Map<Object?, Object?> || child is List<Object?>) {
        buffer.write('$pad${entry.key}:\n');
        buffer.write(_renderExport(child, indent: indent + 1));
      } else {
        // TODO(copy): the placeholder for a value that was never set.
        buffer.write('$pad${entry.key}: ${child ?? 'not set'}\n');
      }
    }
    return buffer.toString();
  }

  if (value is List<Object?>) {
    // TODO(copy): the placeholder for an empty list.
    if (value.isEmpty) return '$pad(none)\n';
    final buffer = StringBuffer();
    for (final child in value) {
      buffer.write(_renderExport(child, indent: indent));
    }
    return buffer.toString();
  }

  // TODO(copy): the placeholder for a value that was never set.
  return '$pad${value ?? 'not set'}\n';
}

String _displayName(TetherSession session, String areaId) {
  final product = session.bundle.productForArea(areaId);
  if (product != null) return product.name;
  return session.bundle.area(areaId)?.name ?? areaId;
}

String? _shellName(DesignBundle bundle, String id) {
  for (final screen in bundle.shell.screens) {
    if (screen.id == id) return screen.name;
  }
  return null;
}

void _back(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  navigator.pushReplacementNamed(ShellRoutes.programs);
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
    this.onTap,
  });

  final CardTone tone;
  final String? eyebrow;
  final String? title;
  final String? body;
  final VoidCallback? onTap;

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
                if (eyebrow case final String text) ...[
                  Text(
                    text.toUpperCase(),
                    style: TetherText.eyebrow.copyWith(
                      color: dark
                          ? TetherColors.mutedOnDark
                          : TetherColors.muted,
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
                      color: dark
                          ? TetherColors.mutedOnDark
                          : TetherColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.rows` — the key-and-value list.
class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.items});

  final List<(String key, String value)> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TetherSpace.blockGap),
      child: Container(
        decoration: BoxDecoration(
          color: TetherColors.card,
          borderRadius: TetherRadius.blockAll,
          border: Border.all(color: TetherColors.line),
        ),
        // Stretch, not centre: a divider with loose constraints collapses to
        // nothing, which is a very quiet way to lose every hairline.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: TetherColors.rowDivider,
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(items[index].$1.toUpperCase(),
                        style: TetherText.rowKey),
                    const SizedBox(height: 2),
                    Text(items[index].$2, style: TetherText.rowValue),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
