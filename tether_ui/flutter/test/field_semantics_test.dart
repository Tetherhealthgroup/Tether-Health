// Screen-reader semantics of TField: the label is the visible field label,
// the example (placeholder) is the hint, and the value is the typed text.
// Synthetic values only.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/ui/ui.dart';

Future<void> _open(WidgetTester tester, String id) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final route = AppRouter.catalog.firstWhere((c) => c.$1 == id).$4;
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    onGenerateRoute: AppRouter.onGenerateRoute,
    onGenerateInitialRoutes: (_) => [AppRouter.onGenerateRoute(RouteSettings(name: route))!],
  ));
  await tester.pump(const Duration(milliseconds: 400));
}

Finder _field(String key) => find.byKey(ValueKey('field:$key'));

SemanticsData _data(WidgetTester tester, String key) => tester.getSemantics(_field(key)).getSemanticsData();

TField _widget(WidgetTester tester, String key) => tester.widget<TField>(find.ancestor(of: _field(key), matching: find.byType(TField)));

void main() {
  setUp(TSession.clear);
  tearDown(TSession.clear);

  // (screen, field key, the text typed, or null for a field that is not typed in)
  const cases = <(String, String, String?)>[
    ('hw_log', 'hw_log.systolic', '120'),
    ('hw_log', 'hw_log.diastolic', '80'),
    ('auth_signin', 'auth_signin.email', 'synthetic-user-01@example.test'),
    ('auth_signin', 'auth_signin.password', 'synthetic-pass-1'),
    ('ob_basics', 'ob_basics.what_should_we_call_you', 'Sam'),
    ('ob_basics', 'ob_basics.age_range', null), // select: chosen, not typed
    ('learn', 'learn.search', 'sleep'), // search: no visible label, same semantics
  ];

  for (final (id, key, typed) in cases) {
    testWidgets('$id · $key: label is the field label, hint is the example (none for a password)${typed == null ? '' : ', value is the typed text'}', (tester) async {
      final semantics = tester.ensureSemantics();
      await _open(tester, id);
      final field = _widget(tester, key);
      expect(field.placeholder, isNotNull, reason: 'the case needs an example');
      // A password's example is bullets: it is not spoken.
      final hint = field.kind == TFieldKind.password ? '' : field.placeholder;
      var data = _data(tester, key);
      expect(data.flagsCollection.isTextField, isTrue);
      expect(data.label, field.label);
      expect(data.hint, hint);
      expect(data.value, isEmpty);
      // The visible label is announced once: as the field's label.
      expect(find.semantics.byLabel(field.label), findsOne);
      // The example is never (part of) a label.
      expect(find.semantics.byLabel(field.placeholder!), findsNothing);
      if (typed != null) {
        await tester.enterText(_field(key), typed);
        await tester.pump();
        data = _data(tester, key);
        expect(data.label, field.label);
        expect(data.hint, hint);
        if (field.kind == TFieldKind.password) {
          expect(data.value, isNot(contains(typed)), reason: 'a password is never exposed');
          expect(data.value.length, typed.length);
        } else {
          expect(data.value, typed);
        }
      }
      semantics.dispose();
    });
  }

  testWidgets('a field without an example has no hint', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(theme: tetherTheme(), home: const Scaffold(body: TField(label: 'Note', fieldKey: 'synthetic.note'))));
    final data = _data(tester, 'synthetic.note');
    expect(data.label, 'Note');
    expect(data.hint, isEmpty);
    semantics.dispose();
  });
}
