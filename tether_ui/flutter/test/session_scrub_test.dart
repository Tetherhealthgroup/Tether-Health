// Session hygiene: TSession.scrub / scrubPasswords / clear, and every
// password field in the generated screens writes to a key that
// scrubPasswords removes. Synthetic values only.
import 'package:flutter/material.dart';
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

  test('clear empties the session and the simulation hooks', () {
    TSession.set('auth_signin.email', 'synthetic-user-01@example.test');
    TSession.set('hw_log.systolic', '120');
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
