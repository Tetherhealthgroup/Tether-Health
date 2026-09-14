import 'package:flutter/foundation.dart';

import '../data/design_bundle.dart';
import '../journey/journey.dart';

/// What a program is doing right now.
enum EnrolmentStatus {
  /// Not joined. The default for every area.
  none,

  /// Joined and counting against the two-at-once ceiling.
  active,

  /// Joined, not counting against the ceiling, history kept. `SH1` shows these
  /// as rows rather than cards.
  paused,

  /// Ended. History is kept until the person deletes it, because deleting a
  /// program is not the same act as deleting a record.
  ended,
}

/// What a program shares, and with whom.
///
/// Granted per program and never globally: `shell.json`'s `per_program_sharing`
/// rule points at 42 CFR Part 2, under which substance-use data must stay
/// segregated regardless of what the person would otherwise agree to. Pooling
/// these into one global switch is the kind of simplification that is very
/// hard to unpick later.
@immutable
class SharingSetting {
  const SharingSetting({
    this.totalsAndAdherence = false,
    this.notes = false,
    this.recipient,
  });

  /// Aggregate progress. The only thing any program shares by default, and it
  /// defaults to off.
  final bool totalsAndAdherence;

  /// The person's own words. Separate from [totalsAndAdherence] because a
  /// coach seeing a total is a different disclosure from a coach reading a
  /// note.
  final bool notes;

  /// Who it goes to, once the person has named somebody.
  final String? recipient;

  bool get sharesAnything => totalsAndAdherence || notes;

  SharingSetting copyWith({
    bool? totalsAndAdherence,
    bool? notes,
    String? recipient,
  }) {
    return SharingSetting(
      totalsAndAdherence: totalsAndAdherence ?? this.totalsAndAdherence,
      notes: notes ?? this.notes,
      recipient: recipient ?? this.recipient,
    );
  }
}

/// One program's enrolment.
@immutable
class Enrolment {
  const Enrolment({
    required this.areaId,
    required this.status,
    required this.hidden,
    required this.sharing,
    required this.joinedOn,
  });

  const Enrolment.none(this.areaId)
      : status = EnrolmentStatus.none,
        hidden = false,
        sharing = const SharingSetting(),
        joinedOn = null;

  final String areaId;
  final EnrolmentStatus status;

  /// Hidden from the home screen and reachable only from Your programs.
  /// `shell.json`'s `discreet_program` rule exists because stigma is a real
  /// adherence barrier on a shared or family device.
  final bool hidden;

  final SharingSetting sharing;
  final DateTime? joinedOn;

  bool get isActive => status == EnrolmentStatus.active;
  bool get isJoined => status != EnrolmentStatus.none;

  Enrolment copyWith({
    EnrolmentStatus? status,
    bool? hidden,
    SharingSetting? sharing,
    DateTime? joinedOn,
  }) {
    return Enrolment(
      areaId: areaId,
      status: status ?? this.status,
      hidden: hidden ?? this.hidden,
      sharing: sharing ?? this.sharing,
      joinedOn: joinedOn ?? this.joinedOn,
    );
  }
}

/// Why a join was refused.
enum JoinRefusal {
  /// Already at the ceiling from `shell.json`'s `two_active_max` rule. Three
  /// concurrent behaviour changes is where adherence collapses, and a third
  /// is meant to require a conversation rather than a tap.
  atActiveCeiling,

  /// The area has no implementation. Nine of the eleven are a plan, and the
  /// catalogue is required to be honest about that rather than offer a join
  /// that leads nowhere.
  areaNotImplemented,
}

/// The result of attempting to join a program.
@immutable
class JoinOutcome {
  const JoinOutcome.joined()
      : refusal = null,
        wouldPause = null;

  const JoinOutcome.refused(this.refusal, {this.wouldPause});

  /// Null when the join succeeded.
  final JoinRefusal? refusal;

  /// When at the ceiling, the program that would be paused to make room. The
  /// join screen shows this before the person commits — `SH3` says "Joining
  /// this would pause Healthy weight" rather than silently doing it.
  final String? wouldPause;

  bool get joined => refusal == null;
}

/// What one person has answered on one screen.
///
/// Keyed by the screen's index within its block list, which is stable for as
/// long as the content file is: reordering blocks in the JSON reorders the
/// answers with them, and that is the correct behaviour for a prototype whose
/// content is still being edited.
class ScreenAnswers {
  ScreenAnswers();

  /// Block index to the chip indices selected in it.
  final Map<int, Set<int>> chips = {};

  /// Block index to the single option chosen in it.
  final Map<int, int> option = {};

  /// Block index to the slider's position, 0 to 100.
  final Map<int, double> slider = {};

  /// Block index to the text typed into it.
  final Map<int, String> text = {};

  bool get isEmpty =>
      chips.isEmpty && option.isEmpty && slider.isEmpty && text.isEmpty;
}

/// A lapse, recorded as an event.
///
/// The `slip_never_resets` safeguard is the whole reason this is a list rather
/// than a counter that gets zeroed: "a lapse is recorded in history. It never
/// zeroes a counter, streak or progress value." There is deliberately no
/// method on this class that clears anything.
@immutable
class LapseEvent {
  const LapseEvent({
    required this.areaId,
    required this.at,
    required this.severity,
    required this.context,
  });

  final String areaId;
  final DateTime at;

  /// The person's own description, as chosen from the lapse screen's options.
  final String severity;

  /// Optional tags that feed the trigger map.
  final List<String> context;
}

/// Where a session sends itself when it changes.
///
/// The session does not know what storage is. It knows when it became
/// different from the last thing written, and it knows when everything it
/// holds has been destroyed — and those are two different events, not one.
/// [sessionChanged] may be coalesced, delayed or dropped by the
/// implementation; [sessionErased] may not, because the `export_and_delete`
/// safeguard asks that deletion be "completed rather than hidden", and a
/// deletion that waits politely behind a debounce timer is neither.
///
/// This lives here rather than in `session_store.dart` so the dependency runs
/// one way: the store knows about the session, the session knows only about
/// this. That is what keeps [TetherSession] constructible in a test with no
/// platform channel, no binding and no asynchrony anywhere near it.
abstract interface class SessionPersistence {
  /// The session's contents no longer match what is stored.
  void sessionChanged(TetherSession session);

  /// Everything the session held has been destroyed and the stored copy must
  /// go with it.
  void sessionErased(TetherSession session);
}

/// Everything the shell knows about one person.
///
/// The app has exactly one runtime dependency — the Flutter SDK — and
/// `test/no_third_party_sdks_test.dart` fails the build if a second appears,
/// so `shared_preferences`, `path_provider`, `sqflite` and `hive` are all out.
/// What survives that constraint is a Pigeon channel written here:
/// `pigeons/tether_store_api.dart` reaches Android `SharedPreferences` and iOS
/// `UserDefaults` through four string methods, and `session_store.dart` turns
/// them into the two calls below. Everything above that line — what a snapshot
/// contains, what version it is, what to do with one this build cannot read —
/// is Dart, and is therefore testable without a device.
///
/// This class remains the seam it was written to be: every mutable value in
/// the shell lives here and nothing else holds state, which is why persistence
/// could be added by giving one class a [toJson] and a [restoreFrom] rather
/// than by threading storage through thirty screens.
///
/// A session with no [bindPersistence] call behaves exactly as it did before
/// any of this existed — it changes in memory and forgets on exit. Most tests
/// use it that way on purpose.
class TetherSession extends ChangeNotifier {
  TetherSession({required this.bundle, this.locale = 'en'})
      : journeys = {
          for (final journey in JourneyBuilder.all(bundle))
            journey.area.id: journey,
        };

  final DesignBundle bundle;
  final String locale;

  /// One journey per area, built at construction.
  final Map<String, Journey> journeys;

  final Map<String, Enrolment> _enrolments = {};
  final Map<String, ScreenAnswers> _answers = {};
  final List<LapseEvent> _lapses = [];

  SessionPersistence? _persistence;

  /// Starts saving changes. Call this *after* [restoreFrom], never before:
  /// binding first would mean the restore's own writes race the snapshot they
  /// came from.
  ///
  /// Deliberately not a constructor argument. Opening the store is
  /// asynchronous and the session is not, and making the session wait for the
  /// platform would put a channel call in front of the first frame of an app
  /// that is perfectly capable of running without one.
  void bindPersistence(SessionPersistence persistence) {
    _persistence = persistence;
  }

  /// Announces that the stored copy is now stale.
  ///
  /// Every mutator calls this, including [setText], which does not notify
  /// listeners. Those two concerns look alike and are not: notifying is about
  /// repainting, saving is about durability, and text is the one case where
  /// the app must do the second without the first. Routing saves through
  /// [notifyListeners] would therefore have lost every note anybody typed.
  void _touch() => _persistence?.sessionChanged(this);

  /// The ceiling from `shell.json`, not a constant in this file.
  int get maxActivePrograms => bundle.shell.maxActivePrograms;

  Enrolment enrolment(String areaId) =>
      _enrolments[areaId] ?? Enrolment.none(areaId);

  Journey? journey(String areaId) => journeys[areaId];

  /// Programs counting against the ceiling.
  List<Enrolment> get activePrograms => [
        for (final area in bundle.areas)
          if (enrolment(area.id).isActive) enrolment(area.id),
      ];

  /// Active programs the home screen may show. A hidden one is joined and
  /// running; it simply does not appear here.
  List<Enrolment> get visiblePrograms =>
      activePrograms.where((enrolment) => !enrolment.hidden).toList();

  List<Enrolment> get pausedPrograms => [
        for (final area in bundle.areas)
          if (enrolment(area.id).status == EnrolmentStatus.paused)
            enrolment(area.id),
      ];

  /// Whether an area can be joined, and what it would cost if not.
  JoinOutcome canJoin(String areaId) {
    final area = bundle.area(areaId);
    if (area == null || area.productId == null) {
      return const JoinOutcome.refused(JoinRefusal.areaNotImplemented);
    }
    if (activePrograms.length < maxActivePrograms) {
      return const JoinOutcome.joined();
    }
    return JoinOutcome.refused(
      JoinRefusal.atActiveCeiling,
      // The longest-running active program is the one offered up, because it
      // is the one most likely to have become routine.
      wouldPause: _oldestActive()?.areaId,
    );
  }

  Enrolment? _oldestActive() {
    final active = activePrograms
        .where((enrolment) => enrolment.joinedOn != null)
        .toList()
      ..sort((a, b) => a.joinedOn!.compareTo(b.joinedOn!));
    return active.isEmpty ? null : active.first;
  }

  /// Joins a program.
  ///
  /// [pausing] names a program to pause to make room. Passing it is how the
  /// join screen turns a refusal into a choice the person made, rather than
  /// the app quietly demoting something behind their back.
  JoinOutcome join(String areaId, {String? pausing}) {
    final outcome = canJoin(areaId);
    if (!outcome.joined) {
      if (outcome.refusal == JoinRefusal.areaNotImplemented) return outcome;
      if (pausing == null) return outcome;
      _set(enrolment(pausing).copyWith(status: EnrolmentStatus.paused));
    }

    _set(
      enrolment(areaId).copyWith(
        status: EnrolmentStatus.active,
        joinedOn: enrolment(areaId).joinedOn ?? DateTime.now(),
      ),
    );
    _touch();
    notifyListeners();
    return const JoinOutcome.joined();
  }

  void pause(String areaId) {
    _set(enrolment(areaId).copyWith(status: EnrolmentStatus.paused));
    _touch();
    notifyListeners();
  }

  /// Resumes a paused program, if there is room under the ceiling.
  bool resume(String areaId) {
    if (activePrograms.length >= maxActivePrograms) return false;
    _set(enrolment(areaId).copyWith(status: EnrolmentStatus.active));
    _touch();
    notifyListeners();
    return true;
  }

  /// Ends a program. History is kept; see [deleteEverything] for the other act.
  void end(String areaId) {
    _set(enrolment(areaId).copyWith(status: EnrolmentStatus.ended));
    _touch();
    notifyListeners();
  }

  /// Hides a program from the home screen without changing what it does.
  void setHidden(String areaId, {required bool hidden}) {
    _set(enrolment(areaId).copyWith(hidden: hidden));
    _touch();
    notifyListeners();
  }

  void setSharing(String areaId, SharingSetting sharing) {
    _set(enrolment(areaId).copyWith(sharing: sharing));
    _touch();
    notifyListeners();
  }

  void _set(Enrolment enrolment) => _enrolments[enrolment.areaId] = enrolment;

  // -- Answers --------------------------------------------------------------

  /// The key one program's answers to one screen live under: `areaId/screenId`.
  ///
  /// The pair, never the screen alone. Two areas may name the same product —
  /// `behavioral` and `digital` both declare `lookup` in `areas.json` — and a
  /// shared product means a shared screen list, down to the ids: [JourneyBuilder]
  /// hands both journeys the same thirty-four, `S01`..`S28` and `SH1`..`SH6`.
  /// Keyed by screen id alone, a craving rating given in one of them is read
  /// straight back out of the other, and `two_active_max` permits exactly that
  /// pair to be running at once. That is not a display glitch; it is one
  /// person's two programmes sharing a record. `shell.json`'s
  /// `per_program_sharing` rule names the consequence — a cessation coach has
  /// no business seeing behavioural health data, and under 42 CFR Part 2
  /// substance-use data must stay segregated regardless of what anyone agreed
  /// to.
  ///
  /// Only the *answer* key carries the program. [JourneyScreen.id] stays bare,
  /// because content addresses other screens by bare id (`"to": "S12"`) and
  /// [Journey.screen] resolves them; scoping the id itself would break every
  /// link in the product in order to fix a storage problem.
  ///
  /// Neither half ever contains a slash — area ids come from `areas.json`,
  /// screen ids from the journey builder — so the composite is unambiguous on
  /// the way back out of JSON.
  static String _answerKey(String areaId, String screenId) =>
      '$areaId/$screenId';

  ScreenAnswers answersFor(String areaId, String screenId) =>
      _answers.putIfAbsent(_answerKey(areaId, screenId), ScreenAnswers.new);

  /// One program's answers, screen id to what was given, skipping screens the
  /// person left alone.
  ///
  /// The skip is not cosmetic. The seeding accessors below create an entry the
  /// first time a block is *drawn*, so every screen anybody scrolled past has a
  /// record here whether or not they touched it, and an export or a snapshot
  /// that carried those would grow with browsing rather than with answering.
  Iterable<MapEntry<String, ScreenAnswers>> _answersIn(String areaId) sync* {
    final prefix = '$areaId/';
    for (final entry in _answers.entries) {
      if (!entry.key.startsWith(prefix) || entry.value.isEmpty) continue;
      yield MapEntry(entry.key.substring(prefix.length), entry.value);
    }
  }

  // The four accessors below seed from the content file the first time a block
  // is read, then return what the person has since done with it.
  //
  // Seeding matters because the shipped content is not blank: the check-in
  // screen arrives with a mood already chosen and two symptom chips lit. If a
  // block started empty in the session and only filled on interaction, the
  // first tap on an already-lit chip would turn it *on* instead of off, which
  // is the sort of bug that survives review because the screenshot looks right.
  //
  // They mutate during build, which is safe here only because they never
  // notify: this is lazy initialisation, not a state change, and nothing
  // rebuilds as a result.

  Set<int> chipSelection(
    String areaId,
    String screenId,
    int blockIndex,
    Set<int> initial,
  ) {
    return answersFor(areaId, screenId)
        .chips
        .putIfAbsent(blockIndex, () => {...initial});
  }

  /// The chosen option, or -1 when the content selected none.
  int optionSelection(
    String areaId,
    String screenId,
    int blockIndex,
    int initial,
  ) {
    return answersFor(areaId, screenId)
        .option
        .putIfAbsent(blockIndex, () => initial);
  }

  double sliderValue(
    String areaId,
    String screenId,
    int blockIndex,
    double initial,
  ) {
    return answersFor(areaId, screenId)
        .slider
        .putIfAbsent(blockIndex, () => initial);
  }

  String textValue(
    String areaId,
    String screenId,
    int blockIndex,
    String initial,
  ) {
    return answersFor(areaId, screenId)
        .text
        .putIfAbsent(blockIndex, () => initial);
  }

  void toggleChip(
    String areaId,
    String screenId,
    int blockIndex,
    int chipIndex,
  ) {
    final selected = answersFor(areaId, screenId)
        .chips
        .putIfAbsent(blockIndex, () => <int>{});
    if (!selected.remove(chipIndex)) selected.add(chipIndex);
    _touch();
    notifyListeners();
  }

  void chooseOption(
    String areaId,
    String screenId,
    int blockIndex,
    int optionIndex,
  ) {
    answersFor(areaId, screenId).option[blockIndex] = optionIndex;
    _touch();
    notifyListeners();
  }

  void setSlider(
    String areaId,
    String screenId,
    int blockIndex,
    double value,
  ) {
    answersFor(areaId, screenId).slider[blockIndex] = value;
    _touch();
    notifyListeners();
  }

  void setText(String areaId, String screenId, int blockIndex, String value) {
    answersFor(areaId, screenId).text[blockIndex] = value;
    // Deliberately silent: rebuilding the tree on every keystroke would fight
    // the text field for cursor position.
    //
    // Saving is not silent, though. A note typed and never followed by a tap
    // is exactly the content most worth keeping, and the debounce in
    // [SessionPersistence] is what stops the keystroke rate reaching the disk.
    _touch();
  }

  // -- Lapses ---------------------------------------------------------------

  List<LapseEvent> get lapses => List.unmodifiable(_lapses);

  List<LapseEvent> lapsesFor(String areaId) =>
      _lapses.where((lapse) => lapse.areaId == areaId).toList();

  /// Records a lapse. Nothing else changes: no counter moves, no streak
  /// breaks, no progress value is recomputed downward. That is the safeguard,
  /// and it is enforced by `test/tether_safeguards_test.dart` rather than by
  /// everybody remembering it.
  void recordLapse(LapseEvent lapse) {
    _lapses.add(lapse);
    _touch();
    notifyListeners();
  }

  // -- Serialisation ---------------------------------------------------------

  /// The shape [toJson] writes and [restoreFrom] will accept.
  ///
  /// Bumped whenever a stored snapshot stops meaning what it used to. A blob
  /// carrying any other number is refused outright rather than read
  /// optimistically: a half-understood snapshot restores a person's programme
  /// into a state they never chose, and there is no way for them to tell that
  /// is what happened.
  ///
  /// Version 2 scopes every answer key to the program that recorded it — see
  /// [_answerKey]. A version 1 document is therefore discarded rather than
  /// migrated, and that is the point rather than a shortcut: its answers are
  /// keyed by screen id alone, and when two areas share a product there is
  /// nothing anywhere in the document that says which of them a given answer
  /// came from. A migration would have to guess, and the wrong guess files a
  /// person's answers under a programme they were never given in — which is
  /// precisely the cross-program merge the scoping exists to stop. Losing an
  /// old snapshot costs a person their answers; guessing costs them the
  /// segregation 42 CFR Part 2 requires, silently.
  static const schemaVersion = 2;

  /// The session as durable JSON.
  ///
  /// Separate from [exportRecord] and deliberately so. That one is written for
  /// a person reading their own record — it names areas, resolves labels,
  /// hides anything unjoined. This one is written for a machine that has to
  /// reproduce the session exactly, so it keeps empty enrolments, keeps areas
  /// the current bundle no longer lists, and carries no human-facing text at
  /// all. Collapsing them into one format would mean every change to the
  /// export's wording became a storage migration.
  ///
  /// [locale] is not stored. It comes from the app at construction, and a
  /// snapshot that disagreed with the running app would be a second source of
  /// truth for something the person sets elsewhere.
  Map<String, Object?> toJson() {
    return {
      'version': schemaVersion,
      'enrolments': [
        for (final enrolment in _enrolments.values)
          {
            'area': enrolment.areaId,
            'status': enrolment.status.name,
            'hidden': enrolment.hidden,
            'joinedOn': enrolment.joinedOn?.toIso8601String(),
            'sharing': {
              'totalsAndAdherence': enrolment.sharing.totalsAndAdherence,
              'notes': enrolment.sharing.notes,
              'recipient': enrolment.sharing.recipient,
            },
          },
      ],
      // Keyed by `areaId/screenId`, flat. Nesting these by program the way
      // [exportRecord] does would put the same information in two places —
      // the key and the tree — and a restore would then have to decide which
      // of the two to believe when they disagreed.
      'answers': {
        for (final entry in _answers.entries)
          if (!entry.value.isEmpty) entry.key: _encodeAnswers(entry.value),
      },
      'lapses': [
        for (final lapse in _lapses)
          {
            'area': lapse.areaId,
            'at': lapse.at.toIso8601String(),
            'severity': lapse.severity,
            'context': lapse.context,
          },
      ],
    };
  }

  /// Replaces everything held with the contents of [json].
  ///
  /// Throws [FormatException] when the snapshot cannot be read as a whole, and
  /// changes nothing when it does: the parse runs into locals and only commits
  /// once all of it succeeded. A partly-restored session is the worst of the
  /// three outcomes, because it looks like a working one.
  ///
  /// Individual malformed entries are dropped rather than fatal. The two
  /// failures are not the same: a snapshot from a version this build does not
  /// understand is a reason to start clean, whereas one lapse with a
  /// date nobody can parse is a reason to lose that lapse and keep the other
  /// forty.
  ///
  /// Enrolments naming areas the current bundle no longer lists are kept. They
  /// are invisible to every accessor here, all of which walk `bundle.areas`,
  /// so keeping them costs nothing and dropping them would quietly destroy
  /// somebody's history the first time an area was renamed.
  void restoreFrom(Map<String, Object?> json) {
    final version = json['version'];
    // Including version 1, which this build can parse perfectly well and still
    // refuses. Its answers name a screen and no program; see [schemaVersion]
    // for why attributing them by guesswork is worse than losing them.
    if (version != schemaVersion) {
      throw FormatException(
        'Session snapshot has version $version; this build writes '
        '$schemaVersion and will not guess at the difference.',
      );
    }

    final enrolments = <String, Enrolment>{};
    for (final entry in _listOfMaps(json['enrolments'])) {
      final areaId = entry['area'];
      if (areaId is! String) continue;
      final sharing = entry['sharing'];
      enrolments[areaId] = Enrolment(
        areaId: areaId,
        status: _statusNamed(entry['status']),
        hidden: entry['hidden'] == true,
        joinedOn: _parseDate(entry['joinedOn']),
        sharing: sharing is Map<String, Object?>
            ? SharingSetting(
                totalsAndAdherence: sharing['totalsAndAdherence'] == true,
                notes: sharing['notes'] == true,
                recipient: sharing['recipient'] is String
                    ? sharing['recipient']! as String
                    : null,
              )
            : const SharingSetting(),
      );
    }

    final answers = <String, ScreenAnswers>{};
    final answersJson = json['answers'];
    if (answersJson is Map<String, Object?>) {
      for (final entry in answersJson.entries) {
        // `areaId/screenId`, per [_answerKey]. A key with no separator names
        // no program, and an answer that cannot be attributed to one is
        // dropped rather than filed under whichever program looks likely —
        // the same reasoning that refuses a version 1 document whole.
        if (!entry.key.contains('/')) continue;
        final screen = entry.value;
        if (screen is! Map<String, Object?>) continue;
        final restored = ScreenAnswers();
        _readBlocks(screen['chips'], (block, value) {
          if (value is List) restored.chips[block] = value.whereType<int>().toSet();
        });
        _readBlocks(screen['option'], (block, value) {
          if (value is int) restored.option[block] = value;
        });
        _readBlocks(screen['slider'], (block, value) {
          if (value is num) restored.slider[block] = value.toDouble();
        });
        _readBlocks(screen['text'], (block, value) {
          if (value is String) restored.text[block] = value;
        });
        if (!restored.isEmpty) answers[entry.key] = restored;
      }
    }

    final lapses = <LapseEvent>[];
    for (final entry in _listOfMaps(json['lapses'])) {
      final areaId = entry['area'];
      final at = _parseDate(entry['at']);
      if (areaId is! String || at == null) continue;
      lapses.add(
        LapseEvent(
          areaId: areaId,
          at: at,
          severity: entry['severity'] is String
              ? entry['severity']! as String
              : '',
          context: (entry['context'] as List<Object?>? ?? const [])
              .whereType<String>()
              .toList(),
        ),
      );
    }

    _enrolments
      ..clear()
      ..addAll(enrolments);
    _answers
      ..clear()
      ..addAll(answers);
    _lapses
      ..clear()
      ..addAll(lapses);

    // No [_touch]. A restore makes the session match what is already stored,
    // which is the one change in this class that does not make the stored copy
    // stale.
    notifyListeners();
  }

  /// One screen's answers as JSON.
  ///
  /// Shared by [toJson] and [exportRecord] because the two disagreeing about
  /// what an answer looks like would be a difference nobody would find: the
  /// export is read by people and the snapshot by the next launch, and neither
  /// audience ever sees the other's copy.
  static Map<String, Object?> _encodeAnswers(ScreenAnswers answers) {
    return {
      // Chips are sorted because a Set has no order and an unordered encoding
      // would make two identical sessions produce two different strings, which
      // turns every save into a write.
      'chips': {
        for (final chip in answers.chips.entries)
          '${chip.key}': chip.value.toList()..sort(),
      },
      'option': {
        for (final option in answers.option.entries)
          '${option.key}': option.value,
      },
      'slider': {
        for (final slider in answers.slider.entries)
          '${slider.key}': slider.value,
      },
      'text': {
        for (final text in answers.text.entries) '${text.key}': text.value,
      },
    };
  }

  static List<Map<String, Object?>> _listOfMaps(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, Object?>>().toList();
  }

  /// Reads a `{"blockIndex": value}` map, skipping anything unreadable.
  ///
  /// Block indices are JSON object keys and therefore strings on the way back,
  /// which is the detail that silently drops every answer if it is missed.
  static void _readBlocks(Object? value, void Function(int, Object?) apply) {
    if (value is! Map) return;
    for (final entry in value.entries) {
      final block = int.tryParse('${entry.key}');
      if (block != null) apply(block, entry.value);
    }
  }

  static EnrolmentStatus _statusNamed(Object? name) {
    for (final status in EnrolmentStatus.values) {
      if (status.name == name) return status;
    }
    // An unrecognised status means a program whose state this build cannot
    // describe. `none` is the only safe reading: it neither counts against the
    // ceiling nor claims the person is enrolled in something they are not.
    return EnrolmentStatus.none;
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  // -- Export and deletion --------------------------------------------------

  /// A readable summary of everything held, for the export action the
  /// `export_and_delete` safeguard requires.
  ///
  /// Answers sit inside the program that recorded them rather than in one flat
  /// map at the top. A person reading this is reading a disclosure, and a
  /// single list of `S13`, `S17`, `S22` above two programme headings invites
  /// exactly the wrong conclusion — that there is one shared pool of answers
  /// underneath the programmes. There is not, and after the move to
  /// [_answerKey] there cannot be; the export should say so by its shape and
  /// not only in a sentence.
  ///
  /// The consequence is that answers belonging to an area the person never
  /// joined — a journey opened and browsed, or an area a later catalogue
  /// renamed away — do not appear here, because there is no program entry to
  /// hold them. [toJson] still carries every one of them, so nothing is lost
  /// from the record itself.
  Map<String, Object?> exportRecord() {
    return {
      'locale': locale,
      'programs': [
        for (final area in bundle.areas)
          if (enrolment(area.id).isJoined)
            {
              'area': area.id,
              'name': area.name,
              'status': enrolment(area.id).status.name,
              'joinedOn': enrolment(area.id).joinedOn?.toIso8601String(),
              'hidden': enrolment(area.id).hidden,
              'sharing': {
                'totalsAndAdherence':
                    enrolment(area.id).sharing.totalsAndAdherence,
                'notes': enrolment(area.id).sharing.notes,
                'recipient': enrolment(area.id).sharing.recipient,
              },
              'lapses': [
                for (final lapse in lapsesFor(area.id))
                  {
                    'at': lapse.at.toIso8601String(),
                    'severity': lapse.severity,
                    'context': lapse.context,
                  },
              ],
              // Keyed by bare screen id. The program is the entry this sits
              // in, and repeating it in every key would be the one place in
              // the export where a reader had to parse something.
              'answers': {
                for (final entry in _answersIn(area.id))
                  entry.key: _encodeAnswers(entry.value),
              },
            },
      ],
    };
  }

  /// Deletes everything, completed rather than hidden.
  ///
  /// The `export_and_delete` safeguard asks for a `hard_delete_action`, and
  /// `SH4`'s copy commits to it clearing the phone, the servers and anything
  /// queued to sync. In this build there is nothing queued and no server, so
  /// this clears what actually exists and the UI must not claim more.
  ///
  /// What actually exists now includes a copy on disk, which is why this calls
  /// [SessionPersistence.sessionErased] rather than leaving the ordinary
  /// autosave to notice. The safeguard's own words are that deletion must be
  /// "completed rather than hidden": clearing three maps in memory while the
  /// snapshot survives in `UserDefaults` until the next debounce — or past a
  /// crash, forever — is the precise failure it names.
  void deleteEverything() {
    _enrolments.clear();
    _answers.clear();
    _lapses.clear();
    _persistence?.sessionErased(this);
    notifyListeners();
  }
}
