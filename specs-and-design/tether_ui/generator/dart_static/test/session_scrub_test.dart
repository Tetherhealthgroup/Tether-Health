// Session hygiene: TSession.scrub / scrubPasswords / clear, and every
// password field in the generated screens writes to a key that
// scrubPasswords removes. Synthetic values only.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/ui/ui.dart';

void main() {
  setUp(TSession.clear);
  tearDown(TSession.clear);

  test('scrub removes exactly the given keys and notifies once', () {
    TSession.set('hw_log.systolic', '120');
    TSession.set('hw_log.diastolic', '80');
    TSession.set('auth_signin.email', 'synthetic-user-01@example.test');
    var notified = 0;
    void listener() => notified++;
    TSession.changes.addListener(listener);
    addTearDown(() => TSession.changes.removeListener(listener));
    TSession.scrub(['hw_log.systolic', 'hw_log.diastolic', 'not.present']);
    expect(TSession.values.keys, ['auth_signin.email']);
    expect(notified, 1);
  });

  test('scrub of absent keys changes nothing and does not notify', () {
    TSession.set('a.b', 1);
    var notified = 0;
    void listener() => notified++;
    TSession.changes.addListener(listener);
    addTearDown(() => TSession.changes.removeListener(listener));
    TSession.scrub(['x.y']);
    expect(TSession.values, {'a.b': 1});
    expect(notified, 0);
  });

  test('scrub accepts a lazy view of the session keys', () {
    TSession.set('a.one', 1);
    TSession.set('a.two', 2);
    TSession.set('b.one', 3);
    TSession.scrub(TSession.values.keys.where((k) => k.startsWith('a.')));
    expect(TSession.values, {'b.one': 3});
  });

  test('password keys are *.password and auth_newpass.*', () {
    for (final k in ['auth_signin.password', 'account_delete.password', 'ob_account.password', 'auth_newpass.new_password', 'auth_newpass.confirm_password', 'auth_newpass.anything']) {
      expect(TSession.isPasswordKey(k), isTrue, reason: k);
    }
    for (final k in ['auth_signin.email', 'password', 'auth_signin.password_hint', 'x.passwords', 'auth_newpass', 'auth_newpassword.x', 'hw_log.systolic']) {
      expect(TSession.isPasswordKey(k), isFalse, reason: k);
    }
  });

  test('scrubPasswords removes every password key and keeps the rest', () {
    TSession.set('auth_signin.email', 'synthetic-user-01@example.test');
    TSession.set('auth_signin.password', 'synthetic-pass-1');
    TSession.set('auth_newpass.new_password', 'synthetic-pass-2');
    TSession.set('auth_newpass.confirm_password', 'synthetic-pass-2');
    TSession.set('account_delete.password', 'synthetic-pass-3');
    TSession.set('hw_log.systolic', '120');
    TSession.scrubPasswords();
    expect(TSession.values, {'auth_signin.email': 'synthetic-user-01@example.test', 'hw_log.systolic': '120'});
    for (final v in TSession.values.values) {
      expect('$v'.contains('synthetic-pass'), isFalse);
    }
  });

  test('clear empties the session, password keys included, and the simulation hooks', () {
    TSession.set('auth_signin.email', 'synthetic-user-01@example.test');
    TSession.set('hw_log.systolic', '120');
    TSession.set('auth_signin.password', 'synthetic-pass-1');
    TSession.set('auth_newpass.new_password', 'synthetic-pass-2');
    TSim.queue.add('Allowed');
    TSim.force = 'Allowed';
    var notified = 0;
    void listener() => notified++;
    TSession.changes.addListener(listener);
    addTearDown(() => TSession.changes.removeListener(listener));
    TSession.clear();
    expect(TSession.values, isEmpty);
    expect(TSim.queue, isEmpty);
    expect(TSim.force, isNull);
    expect(notified, 1);
  });

  testWidgets('a typed password is in the session until scrubbed', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: tetherTheme(), onGenerateRoute: AppRouter.onGenerateRoute, initialRoute: '/auth/signin'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(const ValueKey('field:auth_signin.password')), 'synthetic-pass-9');
    await tester.pump();
    expect(TSession.values['auth_signin.password'], 'synthetic-pass-9');
    TSession.scrubPasswords();
    expect(TSession.values.containsKey('auth_signin.password'), isFalse);
  });

  // The text in the field's controller (what the field shows and holds).
  String fieldText(WidgetTester tester, String key) => tester.widget<EditableText>(find.descendant(of: find.byKey(ValueKey('field:$key')), matching: find.byType(EditableText))).controller.text;

  Future<void> openSignIn(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: tetherTheme(), onGenerateRoute: AppRouter.onGenerateRoute, initialRoute: '/auth/signin'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(const ValueKey('field:auth_signin.email')), 'synthetic-user-01@example.test');
    await tester.enterText(find.byKey(const ValueKey('field:auth_signin.password')), 'synthetic-pass-9');
    await tester.pump();
    expect(fieldText(tester, 'auth_signin.password'), 'synthetic-pass-9');
  }

  testWidgets('scrubPasswords empties the password field on screen and keeps the other fields', (tester) async {
    await openSignIn(tester);
    TSession.scrubPasswords();
    await tester.pump();
    expect(TSession.values['auth_signin.password'], isNull);
    expect(fieldText(tester, 'auth_signin.password'), isEmpty);
    expect(fieldText(tester, 'auth_signin.email'), 'synthetic-user-01@example.test');
    expect(TSession.values['auth_signin.email'], 'synthetic-user-01@example.test');
    expect(find.text('synthetic-pass-9', skipOffstage: false), findsNothing);
    // Typing again works as before.
    await tester.enterText(find.byKey(const ValueKey('field:auth_signin.password')), 'synthetic-pass-10');
    await tester.pump();
    expect(TSession.values['auth_signin.password'], 'synthetic-pass-10');
  });

  testWidgets('undo after scrubPasswords does not bring the password back', (tester) async {
    await openSignIn(tester);
    await tester.pump(const Duration(seconds: 1)); // the undo history records the typing
    TSession.scrubPasswords();
    await tester.pump();
    expect(fieldText(tester, 'auth_signin.password'), isEmpty);
    // Focus the field again and press the platform undo shortcut.
    await tester.tap(find.byKey(const ValueKey('field:auth_signin.password')));
    await tester.pump();
    final apple = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    final modifier = apple ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(modifier);
    await tester.pump();
    expect(fieldText(tester, 'auth_signin.password'), isEmpty);
    expect(TSession.values['auth_signin.password'], isNull);
    expect(find.text('synthetic-pass-9', skipOffstage: false), findsNothing);
  });

  // Focuses the field and presses the platform undo shortcut (Cmd+Z on
  // Apple platforms, Ctrl+Z elsewhere).
  Future<void> undoIn(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey('field:$key')));
    await tester.pump();
    final apple = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    final modifier = apple ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(modifier);
    await tester.pump();
  }

  // Types a password and erases it again, so the field is empty but its undo
  // history holds the typed text.
  Future<void> typeAndErasePassword(WidgetTester tester) async {
    await openSignIn(tester);
    await tester.pump(const Duration(seconds: 1)); // the undo history records the typing
    await tester.enterText(find.byKey(const ValueKey('field:auth_signin.password')), '');
    await tester.pump(const Duration(seconds: 1));
    expect(fieldText(tester, 'auth_signin.password'), isEmpty);
    expect(TSession.values.containsKey('auth_signin.password'), isTrue);
    expect(TSession.values['auth_signin.password'], isNull);
  }

  final undoPlatforms = TargetPlatformVariant(<TargetPlatform>{TargetPlatform.android, TargetPlatform.macOS});

  testWidgets('undo after a password was typed, erased and then scrubbed does not bring it back', (tester) async {
    await typeAndErasePassword(tester);
    TSession.scrubPasswords();
    await tester.pump();
    await undoIn(tester, 'auth_signin.password');
    expect(fieldText(tester, 'auth_signin.password'), isEmpty);
    expect(TSession.values['auth_signin.password'], isNull);
    expect(find.text('synthetic-pass-9', skipOffstage: false), findsNothing);
  }, variant: undoPlatforms);

  testWidgets('undo after a password was typed, erased and then cleared with the session does not bring it back', (tester) async {
    await typeAndErasePassword(tester);
    TSession.clear();
    await tester.pump();
    await undoIn(tester, 'auth_signin.password');
    expect(fieldText(tester, 'auth_signin.password'), isEmpty);
    expect(TSession.values['auth_signin.password'], isNull);
    expect(find.text('synthetic-pass-9', skipOffstage: false), findsNothing);
  }, variant: undoPlatforms);

  testWidgets('other session changes do not rebuild a field or take its focus', (tester) async {
    EditableTextState editable(String key) => tester.state<EditableTextState>(find.descendant(of: find.byKey(ValueKey('field:$key')), matching: find.byType(EditableText)));
    Future<void> otherChanges() async {
      TSession.set('hw_log.systolic', '120');
      TSession.scrub(['hw_log.systolic']);
      TSession.scrub(['auth_signin.email']);
      await tester.pump();
    }

    // A field with typed text.
    await openSignIn(tester);
    await tester.tap(find.byKey(const ValueKey('field:auth_signin.password')));
    await tester.pump();
    var before = editable('auth_signin.password');
    expect(before.widget.focusNode.hasFocus, isTrue);
    await otherChanges();
    expect(identical(editable('auth_signin.password'), before), isTrue);
    expect(before.widget.focusNode.hasFocus, isTrue);
    expect(fieldText(tester, 'auth_signin.password'), 'synthetic-pass-9');

    // A field that was typed in, erased and scrubbed, then focused again
    // without typing.
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byKey(const ValueKey('field:auth_signin.password')), '');
    await tester.pump(const Duration(seconds: 1));
    TSession.scrubPasswords();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('field:auth_signin.password')));
    await tester.pump();
    before = editable('auth_signin.password');
    expect(before.widget.focusNode.hasFocus, isTrue);
    await otherChanges();
    expect(identical(editable('auth_signin.password'), before), isTrue);
    expect(before.widget.focusNode.hasFocus, isTrue);
    expect(fieldText(tester, 'auth_signin.password'), isEmpty);
  });

  testWidgets('scrub of a field key empties that field', (tester) async {
    await openSignIn(tester);
    TSession.scrub(['auth_signin.email']);
    await tester.pump();
    expect(fieldText(tester, 'auth_signin.email'), isEmpty);
    expect(fieldText(tester, 'auth_signin.password'), 'synthetic-pass-9');
  });

  testWidgets('clear empties every field on screen', (tester) async {
    await openSignIn(tester);
    TSession.clear();
    await tester.pump();
    expect(fieldText(tester, 'auth_signin.email'), isEmpty);
    expect(fieldText(tester, 'auth_signin.password'), isEmpty);
    expect(TSession.values, isEmpty);
  });

  testWidgets('every password field in every screen writes to a password key', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final seen = <String>{};
    for (final s in AppRouter.catalog) {
      final builder = AppRouter.screens[s.$4]!;
      final sheet = AppRouter.sheets.contains(s.$4);
      await tester.pumpWidget(MaterialApp(
        theme: tetherTheme(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: Builder(builder: (c) => sheet ? TSheetPreview(child: builder(c)) : builder(c)),
      ));
      for (final f in tester.widgetList<TField>(find.byType(TField, skipOffstage: false))) {
        if (f.kind != TFieldKind.password) continue;
        expect(f.fieldKey, isNotNull, reason: '${s.$1}: password field without a key');
        expect(TSession.isPasswordKey(f.fieldKey!), isTrue, reason: '${s.$1}: ${f.fieldKey} is not scrubbed by scrubPasswords');
        seen.add(f.fieldKey!);
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    // The spec's password fields (ob_account, auth_signin(+error), auth_link,
    // auth_newpass x2, auth_session, account_delete) were all found.
    expect(seen, containsAll(<String>['ob_account.password', 'auth_signin.password', 'auth_link.password', 'auth_newpass.new_password', 'auth_newpass.confirm_password', 'auth_session.password', 'account_delete.password']));
  });
}
