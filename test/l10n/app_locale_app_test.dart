// The app language in the running app: both roots, the welcome choice across
// a restart, sign-out and the on-device wipe. Synthetic identities only.
import 'package:breathefree_patient/account/account_data_api_client.dart';
import 'package:breathefree_patient/account/account_deletion_receipt_store.dart';
import 'package:breathefree_patient/app/tether_ui_shell.dart';
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/l10n/app_locale.dart';
import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/ui/ui.dart';

import '../app/fakes.dart';

const _key = SecureAppLocaleStore.storageKey;
const _englishHeadline = 'Your next breath can be different.';
const _spanishHeadline = 'Tu próxima respiración puede ser diferente.';

Future<String?> _stored() => const FlutterSecureStorage().read(key: _key);

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Starts the legacy app as main() does: the language is restored first.
Future<AppLocale> _launch(
  WidgetTester tester, {
  List<Locale> device = const [Locale('en', 'US')],
  int initialScreen = 0,
  AccountController? account,
  QuitPlanController? quitPlan,
}) async {
  final locale = AppLocale(deviceLocales: () => device);
  await tester.runAsync(locale.load);
  await tester.pumpWidget(BreatheFreeApp(
    key: UniqueKey(),
    initialScreen: initialScreen,
    accountController: account,
    quitPlanController: quitPlan,
    appLocale: locale,
  ));
  await tester.pumpAndSettle();
  return locale;
}

AccountController _signedInAccount() {
  final account = fakeAccount(
    auth: FakeAuth(signedInAs: 'synthetic-user-01'),
  );
  addTearDown(account.dispose);
  return account;
}

QuitPlanController _noPlan() {
  final plan = QuitPlanController.disabled();
  addTearDown(plan.dispose);
  return plan;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('the welcome language choice survives a restart', (tester) async {
    _phoneSize(tester);
    await _launch(tester);
    expect(find.text(_englishHeadline), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('welcome-spanish')));
    await tester.tap(find.byKey(const ValueKey('welcome-spanish')));
    await tester.pumpAndSettle();
    expect(find.text(_spanishHeadline), findsOneWidget);
    expect(await _stored(), isNotNull);

    // Restart: a new app and a new language controller on the same storage.
    await tester.pumpWidget(const SizedBox());
    await _launch(tester);
    expect(find.text(_spanishHeadline), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('welcome-spanish')));
    await tester.tap(find.byKey(const ValueKey('welcome-spanish')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await _launch(tester);
    expect(find.text(_englishHeadline), findsOneWidget);
  });

  testWidgets('first launch on a Spanish phone opens in Spanish',
      (tester) async {
    _phoneSize(tester);
    await _launch(tester, device: const [Locale('es', 'MX')]);
    expect(find.text(_spanishHeadline), findsOneWidget);
    expect(await _stored(), isNull, reason: 'no choice was made');
  });

  testWidgets('first launch on an unsupported phone language opens in English',
      (tester) async {
    _phoneSize(tester);
    await _launch(tester, device: const [Locale('fr', 'FR')]);
    expect(find.text(_englishHeadline), findsOneWidget);
  });

  testWidgets('the legacy root localizes Material widgets in Spanish',
      (tester) async {
    _phoneSize(tester);
    final locale = await _launch(tester);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('en'));
    expect(app.supportedLocales, releaseLocales);
    expect(
      app.localizationsDelegates,
      containsAll(<LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ]),
    );
    BuildContext screen() =>
        tester.element(find.byKey(const ValueKey('functional-welcome-screen')));
    expect(MaterialLocalizations.of(screen()).backButtonTooltip, 'Back');

    await locale.choose(const Locale('es'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('es'),
    );
    expect(MaterialLocalizations.of(screen()).backButtonTooltip, 'Atrás');

    showDatePicker(
      context: screen(),
      initialDate: DateTime(2026, 11, 3),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Seleccionar fecha'), findsOneWidget);
    expect(find.text('noviembre de 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signing out keeps the language choice', (tester) async {
    _phoneSize(tester);
    FlutterSecureStorage.setMockInitialValues({
      _key: '{"choice":"es","deviceLocale":"en-US"}',
    });
    final account = _signedInAccount();
    final locale = await _launch(
      tester,
      initialScreen: 27,
      account: account,
      quitPlan: _noPlan(),
    );
    expect(locale.locale, const Locale('es'));

    await tester.ensureVisible(find.byKey(const ValueKey('settings-sign-out')));
    await tester.tap(find.byKey(const ValueKey('settings-sign-out')));
    await tester.pumpAndSettle();

    expect(account.isSignedIn, isFalse);
    expect(find.text(_spanishHeadline), findsOneWidget);
    expect(locale.locale, const Locale('es'));
    expect(await _stored(), isNotNull);
  });

  testWidgets('deleting the account clears the language choice on the device',
      (tester) async {
    _phoneSize(tester);
    FlutterSecureStorage.setMockInitialValues({
      _key: '{"choice":"es","deviceLocale":"en-US"}',
    });
    final account = _signedInAccount();
    final locale = await _launch(
      tester,
      initialScreen: 27,
      account: account,
      quitPlan: _noPlan(),
    );
    expect(locale.locale, const Locale('es'));

    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-delete-account')),
    );
    await tester.tap(find.byKey(const ValueKey('settings-delete-account')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('account-delete-password')),
      'synthetic-password',
    );
    await tester.enterText(
      find.byKey(const ValueKey('account-delete-confirmation')),
      'DELETE',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('account-delete-confirm')),
    );
    await tester.tap(find.byKey(const ValueKey('account-delete-confirm')));
    await tester.pumpAndSettle();

    expect(await _stored(), isNull);
    expect(locale.locale, const Locale('en'));

    await tester.tap(find.byKey(const ValueKey('account-delete-done')));
    await tester.pumpAndSettle();
    expect(find.text(_englishHeadline), findsOneWidget);
  });

  testWidgets(
      'finishing a deletion after a restart clears the language choice too',
      (tester) async {
    _phoneSize(tester);
    FlutterSecureStorage.setMockInitialValues({
      _key: '{"choice":"es","deviceLocale":"en-US"}',
    });
    final account = fakeAccount(
      receipts: FakeReceipts(PendingAccountDeletion(
        accountId: 'synthetic-user-01',
        receipt: AccountDeletionReceipt(
          requestId: 'synthetic-receipt-02',
          completedAt: DateTime.utc(2026, 10, 22),
          profileRowsDeleted: 1,
          quitPlanRowsDeleted: 0,
          avatarObjectsDeleted: 0,
          authIdentityDeleted: true,
        ),
      )),
    );
    addTearDown(account.dispose);
    final locale = await _launch(tester, account: account, quitPlan: _noPlan());

    expect(find.text('Account deleted'), findsOneWidget);
    expect(await _stored(), isNull);
    expect(locale.locale, const Locale('en'));
  });

  testWidgets('the tether_ui root runs in the app language', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(() {
      TDefaults.forPreview();
      TSession.values.clear();
    });
    final locale = AppLocale(
      store: MemoryAppLocaleStore(),
      deviceLocales: () => const [Locale('es', 'MX')],
    );
    late Widget app;
    final runtime = await runTetherUi(
      account: fakeAccount(),
      guestStore: FakeGuestStore(hasPlan: false),
      platform: TargetPlatform.iOS,
      appLocale: locale,
      run: (widget) => app = widget,
    );
    addTearDown(runtime.lifecycle.dispose);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    MaterialApp root() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(root().locale, const Locale('es'));
    expect(root().supportedLocales, releaseLocales);
    expect(
      root().localizationsDelegates,
      contains(GlobalMaterialLocalizations.delegate),
    );

    await locale.choose(const Locale('en'));
    await tester.pumpAndSettle();
    expect(root().locale, const Locale('en'));
  });
}
