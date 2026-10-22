// Localized strings (generator/l10n.py, lib/ui/strings.dart):
// - every screen in the pseudo-locale shows only pseudo-localized text, so
//   no member-visible string is hard-coded, and no screen overflows;
// - a locale ships only when complete, fresh and reviewed: drafts and the
//   pseudo-locale exist in debug builds only, and a missing key throws there;
// - option values stay the English source while the labels are translated;
// - the ICU subset (placeholders, plurals) and the kit's English source.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

const _pseudo = Locale('en', 'XA');

Future<void> _pump(WidgetTester tester, Widget home, {Locale locale = _pseudo, double scale = 1.0}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  TSession.clear();
  await tester.pumpWidget(MaterialApp(
    theme: tetherTheme(),
    locale: locale,
    supportedLocales: TStrings.supportedLocales(),
    localizationsDelegates: const [TStrings.delegate],
    onGenerateRoute: AppRouter.onGenerateRoute,
    builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
    home: home,
  ));
  await tester.pump(const Duration(milliseconds: 50));
}

Widget _screen(String route) {
  final builder = AppRouter.screens[route]!;
  return Builder(builder: (c) => AppRouter.sheets.contains(route) ? TSheetPreview(child: builder(c)) : builder(c));
}

/// Every text drawn and every semantics label, value, hint and tooltip.
List<String> _shown(WidgetTester tester) {
  final out = <String>[];
  void visit(RenderObject r) {
    if (r is RenderParagraph) out.add(r.text.toPlainText());
    r.visitChildren(visit);
  }

  visit(tester.binding.renderViews.first);
  void sem(SemanticsNode n) {
    final d = n.getSemanticsData();
    for (final s in [d.label, d.value, d.hint, d.tooltip]) {
      out.addAll(s.split('\n'));
    }
    n.visitChildren((c) {
      sem(c);
      return true;
    });
  }

  sem(tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
  return out;
}

// Literals that are the same in every language: generated (brands, units,
// numbers, phone numbers, language names) and the kit's programme names.
final _same = <String>[
  ...tUntranslatedLiterals,
  ...TProgramTag.names.values,
]..sort((a, b) => b.length.compareTo(a.length));

final _letter = RegExp(r'\p{L}', unicode: true);

/// What is left of [text] after removing pseudo-localized runs and literals
/// that are the same in every language; non-empty means hard-coded text.
String _untranslated(String text) {
  var rest = text;
  for (var prev = ''; prev != rest;) {
    prev = rest;
    rest = rest.replaceAll(RegExp('⟦[^⟦⟧]*⟧'), ' ');
  }
  final lower = rest.toLowerCase();
  for (final s in _same) {
    if (s.isEmpty) continue;
    var i = lower.indexOf(s.toLowerCase());
    while (i >= 0) {
      rest = rest.replaceRange(i, i + s.length, ' ' * s.length);
      i = rest.toLowerCase().indexOf(s.toLowerCase(), i + s.length);
    }
  }
  // Native view placeholders are developer previews of an OS view.
  rest = rest.replaceAll(RegExp(r'NATIVE VIEW · \w+|, native view placeholder'), ' ');
  final letters = rest.split('').where(_letter.hasMatch).length;
  // A single letter is an initial (avatar, programme badge).
  return letters <= 1 ? '' : rest.trim();
}

void main() {
  group('pseudo-locale', () {
    for (final s in AppRouter.catalog) {
      testWidgets('${s.$1}: every member-visible string is localized and nothing overflows', (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, _screen(s.$4));
        expect(tester.takeException(), isNull);
        final bad = [for (final t in _shown(tester)) if (_untranslated(t).isNotEmpty) t];
        expect(bad, isEmpty, reason: 'not localized on ${s.$1}: $bad');
        handle.dispose();
      });
    }

    test('the check catches a hard-coded string next to a localized one', () {
      expect(_untranslated('⟦Ĝéţ~⟧'), isEmpty);
      expect(_untranslated('BreatheFree · ⟦Ƒöŕ~⟧'), isEmpty);
      expect(_untranslated('${tUntranslatedLiterals.first} 120'), isEmpty);
      expect(_untranslated('⟦Ĝéţ~⟧ zone'), 'zone');
      expect(_untranslated('⟦⟦Ţöðàý~⟧ ţàƀ~⟧'), isEmpty);
      expect(_untranslated('Get started'), 'Get started');
    });
  });

  group('locales', () {
    test('a release build offers only the release locales', () {
      expect(TStrings.supportedLocales(release: true).map((l) => l.toLanguageTag()), tReleaseLocales);
      // The pseudo-locale is not offered: a phone set to it gets English.
      expect(TStrings.forLocale(_pseudo, release: true)!.locale, const Locale('en'));
      for (final draft in tDraftLocales) {
        expect(TStrings.forLocale(Locale(draft), release: true), isNull, reason: draft);
      }
    });

    test('a debug build adds the draft locales and the pseudo-locale', () {
      final debug = TStrings.supportedLocales(release: false).map((l) => l.toLanguageTag()).toList();
      expect(debug, [...tReleaseLocales, ...tDraftLocales, tPseudoLocale]);
      expect(TStrings.forLocale(_pseudo, release: false)!.locale, _pseudo);
    });

    test('a regional locale uses its language; an unknown one is not offered', () {
      expect(TStrings.forLocale(const Locale('en', 'GB'), release: true)!.locale, const Locale('en'));
      expect(TStrings.forLocale(const Locale('xx'), release: false), isNull);
    });

    test('every release catalog has every key', () {
      final en = tCatalog('en', release: true)!;
      for (final tag in tReleaseLocales) {
        final table = tCatalog(tag, release: true)!;
        expect(en.keys.where((k) => !table.containsKey(k)), isEmpty, reason: tag);
      }
      final pseudo = tCatalog(tPseudoLocale, release: false)!;
      expect(pseudo.keys.toSet(), en.keys.toSet());
    });

    test('a missing key throws in debug and test builds', () {
      final s = TStrings.forLocale(_pseudo, release: false)!;
      expect(() => s.get('nope.body[0].text'), throwsA(isA<FlutterError>()));
      expect(() => TStrings.english.get('nope.body[0].text'), throwsA(isA<FlutterError>()));
    });

    testWidgets('without the delegate, screens show English', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(theme: tetherTheme(), onGenerateRoute: AppRouter.onGenerateRoute, home: _screen(Routes.welcome)));
      await tester.pump();
      expect(find.text('Get started'), findsOneWidget);
    });
  });

  group('option values', () {
    testWidgets('the welcome language choice stores en or es and shows the language names', (tester) async {
      await _pump(tester, _screen(Routes.welcome));
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(TSession.values['welcome.value'], 'en');
      await tester.tap(find.text('Español'));
      await tester.pump();
      expect(TSession.values['welcome.value'], 'es');
    });

    testWidgets('translated chips, segments, radios, checklists and tiles keep their values', (tester) async {
      await _pump(
          tester,
          Scaffold(
            body: ListView(children: [
              TChips(fieldKey: 't.c', options: const ['Morning', 'Evening'], labels: const ['Mañana', 'Tarde'], multi: false),
              TSegmented(fieldKey: 't.s', options: const ['mg/dL', 'mmol/L'], labels: const ['A', 'B'], selected: 'mg/dL'),
              const TRadioList(fieldKey: 't.r', items: [TRadioItem('Sí', value: 'Yes'), TRadioItem('No', value: 'No')], selected: -1),
              const TChecklist(fieldKey: 't.k', items: [TCheckItem('Lunes', value: 'Monday')]),
              TTileGrid(fieldKey: 't.t', tiles: const [TTile(label: 'Respirar', value: 'Breathe')]),
            ]),
          ));
      await tester.tap(find.text('Tarde'));
      await tester.tap(find.text('B'));
      await tester.tap(find.text('Sí'));
      await tester.tap(find.text('Lunes'));
      await tester.tap(find.text('Respirar'));
      await tester.pump();
      expect(TSession.values['t.c'], ['Evening']);
      expect(TSession.values['t.s'], 'mmol/L');
      expect(TSession.values['t.r'], 'Yes');
      expect(TSession.values['t.k'], ['Monday']);
      expect(TSession.values['t.t'], ['Breathe']);
      expect(find.text('Evening'), findsNothing);
    });
  });

  group('ICU subset', () {
    String one(num n) => n == 1 ? 'one' : 'other';
    test('placeholders and plurals', () {
      expect(TIcu.format('Step {n} of {total}', {'n': 2, 'total': 5}, one), 'Step 2 of 5');
      const days = '{n, plural, =0{No days} one{# day} other{# days}}';
      expect([for (final n in [0, 1, 2, 21]) TIcu.format(days, {'n': n}, one)], ['No days', '1 day', '2 days', '21 days']);
      expect(TIcu.format('{n, plural, one{# {who}} other{# {who}s}}', {'n': 3, 'who': 'friend'}, one), '3 friends');
    });

    test('malformed messages and missing values are errors', () {
      expect(() => TIcu.format('{n', {'n': 1}, one), throwsFormatException);
      expect(() => TIcu.format('a }', {}, one), throwsFormatException);
      expect(() => TIcu.format('{n, select, a{x} other{y}}', {'n': 1}, one), throwsFormatException);
      expect(() => TIcu.format('{who}', {}, one), throwsArgumentError);
      expect(() => TIcu.format('{n, plural, other{#}}', {'n': 'x'}, one), throwsArgumentError);
    });

    test('kit strings are formatted through the catalog', () {
      expect(TStrings.english.kitStepOf(n: 1, total: 5), 'Step 1 of 5');
      expect(TStrings.forLocale(_pseudo, release: false)!.kitStepOf(n: 1, total: 5), contains('1'));
    });
  });

  test("the kit's English constants match the English catalog", () {
    final s = TStrings.english;
    expect(s.kitGenericError, TFailClosedResolver.message);
    expect(s.kitSaveError, TNav.saveError);
    expect(s.kitCallFallback(number: '988'), TCallFallbackCopy.callMessage('988'));
    expect(s.kitSmsFallback(number: '988'), TCallFallbackCopy.smsMessage('988'));
    expect([s.kitCopy, s.kitCopied, s.kitClose], [TCallFallbackCopy.copy, TCallFallbackCopy.copied, TCallFallbackCopy.close]);
  });
}
