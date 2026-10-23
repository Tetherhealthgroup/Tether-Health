// Decision sources (R-31): every branch in the spec has exactly one
// production decision source (a rule or visible choice, the server outcome
// of the submit it follows, native sign-in, or a device answer keyed by a
// stable branch id), and production never decides on question text.
//
// Covers: the emitted catalogues (spec/branches.json, spec/endpoints.json)
// against the generated screens; each generated device, server and sign-in
// branch decided without the resolver; the TDevice hook (order, answers that
// decide nothing, the in-flight guard, release default); release question
// redaction; email sign-in as a non-queueable submit with generic failure
// copy and the guest-plan case on the retry (P-51); and route scope: a late
// sign-in, device or resolver answer never acts on a screen the member opened.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/screens/auth/auth_merge_screen.dart';
import 'package:tether_ui/screens/auth/auth_signin_error_screen.dart';
import 'package:tether_ui/screens/auth/auth_signin_screen.dart';
import 'package:tether_ui/screens/records/records_consent_device_screen.dart';
import 'package:tether_ui/screens/records/records_importing_screen.dart';
import 'package:tether_ui/screens/rescue/crisis_screen.dart';
import 'package:tether_ui/screens/today/today_screen.dart';
import 'package:tether_ui/ui/ui.dart';

/// Synthetic payload that must never reach the UI or a recorded code.
const _canary = 'canary-synthetic-user-01';

/// No failure message may say the entry was kept (no outbox keeps it).
void _noKeptClaim(WidgetTester tester) {
  for (final t in _texts(tester)) {
    expect(t.toLowerCase().contains('kept'), isFalse, reason: t);
  }
}

const _host = '/__host';

final _branchId = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2}$');

List<Map<String, dynamic>> _catalogue() => (jsonDecode(File('../spec/branches.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();

List<Map<String, dynamic>> _endpoints() => (jsonDecode(File('../spec/endpoints.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();

Map<String, dynamic> _screens() => jsonDecode(File('../spec/screens.json').readAsStringSync()) as Map<String, dynamic>;

final Map<String, String> _routeOf = {for (final s in AppRouter.catalog) s.$1: s.$4};

/// Every branch that a device answer decides, or that is a preview-only
/// reference branch: its stable id, its ask and its full answer → case map
/// (a per-platform value maps ios and android). Pinned here, independently of
/// the spec, because the Unplug and screen-time additions are not hash-pinned
/// by the approved-design registry. Reference branches have no map.
const _mapping = <String, (String, String, Map<String, Object>?)>{
  'ob_reminders footer[0]': ('onboarding.reminders.notifications_request', 'notificationsRequest', {'granted': 'Allowed', 'denied': 'Not allowed', 'unavailable': 'Not allowed'}),
  'records_fhir_url footer[0]': ('records.fhir_url.server_check', 'fhirServerCheck', {'supported': 'SMART on FHIR R4 supported', 'unsupported': 'Not a FHIR R4 server'}),
  'records_consent footer[0] cases[0].action': ('records.connect.mychart', 'smartConnect', {'approved': 'Approved', 'cancelled': 'Cancelled', 'failed': 'Denied or error'}),
  'records_consent_bb footer[0] cases[0].action': ('records.connect.medicare', 'smartConnect', {'approved': 'Approved', 'cancelled': 'Cancelled', 'failed': 'Denied or error'}),
  'records_consent_device footer[0] cases[0].action': ('records.device.health_records_request', 'healthRecordsRequest', {'granted': 'Allowed', 'denied': 'Not allowed', 'unavailable': 'Not allowed'}),
  'sf_screentime footer[0]': ('sf.screentime.ios_request', 'screenTimeRequest', {'granted': 'Allowed', 'denied': 'Not allowed', 'unavailable': 'Not allowed'}),
  'sf_screentime_android footer[0]': ('sf.screentime.android_usage_access', 'usageAccessSettings', {'granted': 'Allowed', 'denied': 'Not allowed'}),
  'sf_unplug_intro footer[0]': ('unplug.intro.platform', 'platform', {'ios': 'iPhone', 'android': 'Android'}),
  'sf_unplug_home body[2].rows[2]': ('unplug.home.preview_platform', 'platform', {'ios': 'iPhone', 'android': 'Android'}),
  'sf_unplug_auth_notifications footer[2]': ('unplug.setup.continue_platform', 'platform', {'ios': 'iPhone', 'android': 'Android'}),
  'sf_unplug_auth footer[0]': ('unplug.setup.ios_authorization', 'unplugAuthIos', {'granted': 'Approved', 'grantedNotificationsOff': 'Approved · notifications off', 'denied': 'Denied', 'unavailable': 'Unavailable'}),
  'sf_unplug_auth_denied footer[0]': ('unplug.setup.ios_authorization_retry', 'unplugAuthIos', {'granted': 'Approved', 'grantedNotificationsOff': 'Approved', 'denied': 'Denied', 'unavailable': 'Denied'}),
  'sf_unplug_auth_notifications footer[1]': ('unplug.setup.notifications_check', 'notificationsCheck', {'granted': {'ios': 'On (iPhone)', 'android': 'On (Android)'}, 'denied': 'Still off'}),
  'sf_unplug_auth_android footer[2]': ('unplug.setup.android_check', 'unplugAndroidCheck', {'allOn': 'All on', 'notificationsOff': 'Notifications off', 'missing': 'Missing'}),
  'sf_unplug_health_notifications footer[1]': ('unplug.health.notifications_check', 'notificationsCheck', {'granted': 'On', 'denied': 'Still off'}),
  'sf_unplug_health_stopped footer[1]': ('unplug.health.tracking_check', 'unplugTrackingCheck', {'healthy': 'All pass', 'failing': 'Still failing'}),
  'sf_unplug_picker_ios footer[0]': ('unplug.picker.ios', 'reference', null),
  'sf_unplug_shield footer[0] then': ('unplug.shield.notification_action', 'reference', null),
};

/// For each device branch and each answer ('answer' or 'answer/platform'):
/// the case it takes and what that case opens: ('route', route) with the
/// route on top, ('pop', null) back to the screen below, or ('toast', null)
/// staying on the screen; plus the toast text it shows, if any.
const _opens = <String, Map<String, (String, String, String?, String?)>>{
  'ob_reminders footer[0]': {
    'granted': ('Allowed', 'route', '/onboarding/account', null),
    'denied': ('Not allowed', 'route', '/onboarding/reminders?state=denied', null),
    'unavailable': ('Not allowed', 'route', '/onboarding/reminders?state=denied', null),
  },
  'records_fhir_url footer[0]': {
    'supported': ('SMART on FHIR R4 supported', 'route', '/records/consent', null),
    'unsupported': ('Not a FHIR R4 server', 'route', '/records/error', null),
  },
  'records_consent footer[0] cases[0].action': {
    'approved': ('Approved', 'route', '/records/importing', null),
    'cancelled': ('Cancelled', 'toast', null, 'Connection cancelled. Nothing was imported.'),
    'failed': ('Denied or error', 'route', '/records/error', null),
  },
  'records_consent_bb footer[0] cases[0].action': {
    'approved': ('Approved', 'route', '/records/importing', null),
    'cancelled': ('Cancelled', 'toast', null, 'Connection cancelled. Nothing was imported.'),
    'failed': ('Denied or error', 'route', '/records/error', null),
  },
  'records_consent_device footer[0] cases[0].action': {
    'granted': ('Allowed', 'route', '/records/importing', null),
    'denied': ('Not allowed', 'route', '/records/error', null),
    'unavailable': ('Not allowed', 'route', '/records/error', null),
  },
  'sf_screentime footer[0]': {
    'granted': ('Allowed', 'pop', null, 'Screen Time connected'),
    'denied': ('Not allowed', 'route', '/p/sf/screen-time?state=denied', null),
    'unavailable': ('Not allowed', 'route', '/p/sf/screen-time?state=denied', null),
  },
  'sf_screentime_android footer[0]': {
    'granted': ('Allowed', 'pop', null, 'Usage access on'),
    'denied': ('Not allowed', 'route', '/p/sf/screen-time?state=android-denied', null),
  },
  'sf_unplug_intro footer[0]': {
    'ios': ('iPhone', 'route', '/p/sf/unplug/permission', null),
    'android': ('Android', 'route', '/p/sf/unplug/permission?state=android', null),
  },
  'sf_unplug_home body[2].rows[2]': {
    'ios': ('iPhone', 'route', '/system/unplug/shield', null),
    'android': ('Android', 'route', '/system/unplug/overlay', null),
  },
  'sf_unplug_auth_notifications footer[2]': {
    'ios': ('iPhone', 'route', '/p/sf/unplug/apps', null),
    'android': ('Android', 'route', '/p/sf/unplug/apps?state=android', null),
  },
  'sf_unplug_auth footer[0]': {
    'granted': ('Approved', 'route', '/p/sf/unplug/apps', null),
    'grantedNotificationsOff': ('Approved · notifications off', 'route', '/p/sf/unplug/permission?state=notifications', null),
    'denied': ('Denied', 'route', '/p/sf/unplug/permission?state=denied', null),
    'unavailable': ('Unavailable', 'route', '/p/sf/unplug/permission?state=unavailable', null),
  },
  'sf_unplug_auth_denied footer[0]': {
    'granted': ('Approved', 'route', '/p/sf/unplug/apps', null),
    'grantedNotificationsOff': ('Approved', 'route', '/p/sf/unplug/apps', null),
    'denied': ('Denied', 'toast', null, 'Still not allowed. You can turn it on later in Settings.'),
    'unavailable': ('Denied', 'toast', null, 'Still not allowed. You can turn it on later in Settings.'),
  },
  'sf_unplug_auth_notifications footer[1]': {
    'granted/ios': ('On (iPhone)', 'route', '/p/sf/unplug/apps', null),
    'granted/android': ('On (Android)', 'route', '/p/sf/unplug/apps?state=android', null),
    'denied': ('Still off', 'toast', null, 'Notifications are still off. You can turn them on later in Settings.'),
  },
  'sf_unplug_auth_android footer[2]': {
    'allOn': ('All on', 'route', '/p/sf/unplug/apps?state=android', null),
    'notificationsOff': ('Notifications off', 'route', '/p/sf/unplug/permission?state=notifications', null),
    'missing': ('Missing', 'toast', null, 'Unplug still needs both settings.'),
  },
  'sf_unplug_health_notifications footer[1]': {
    'granted': ('On', 'route', '/p/sf/unplug/health', null),
    'denied': ('Still off', 'toast', null, 'Notifications are still off.'),
  },
  'sf_unplug_health_stopped footer[1]': {
    'healthy': ('All pass', 'route', '/p/sf/unplug/health', null),
    'failing': ('Still failing', 'toast', null, 'Still not working. Turn Screen Time access on again in Settings.'),
  },
};

/// Sign-in branches that sit inside a rule branch (the sign-up age check,
/// P-72), keyed by where: the item to tick so the rule lets sign-in run.
const _ticks = <String, String>{
  'ob_account body[2].items[0] cases[0].action': 'I’m 18 or older',
  'ob_account body[2].items[1] cases[0].action': 'I’m 18 or older',
};

/// Device branches that sit inside a rule branch (P-78: a records consent
/// screen continues only once something is selected), keyed by where: the
/// item to tick so the rule lets the device question run.
const _deviceTicks = <String, String>{
  'records_consent footer[0] cases[0].action': 'Conditions',
  'records_consent_bb footer[0] cases[0].action': 'Conditions',
  'records_consent_device footer[0] cases[0].action': 'Blood pressure',
};

String _where(Map<String, dynamic> r) => '${r['screen']} ${r['path']}${(r['at'] as String).isEmpty ? '' : ' ${r['at']}'}';

class _ScriptedDevice implements TDevice {
  _ScriptedDevice(this.answer);
  final Future<TAnswer?> Function(TBranchRef ref) answer;
  final List<TBranchRef> asked = <TBranchRef>[];
  @override
  Future<TAnswer?> ask(BuildContext context, TBranchRef branch) {
    asked.add(branch);
    return answer(branch);
  }
}

class _ScriptedAuth implements TAuth {
  _ScriptedAuth(this.answer);
  final Future<String?> Function() answer;
  int calls = 0;
  @override
  Future<String?> signIn(String provider, List<String> outcomes) {
    calls++;
    return answer();
  }
}

class _ScriptedApi implements TApi {
  _ScriptedApi(this.result);
  final TResult result;
  final List<(String, String)> calls = [];
  @override
  Future<TResult> submit(String endpoint, {required String screenId}) async {
    calls.add((endpoint, screenId));
    return result;
  }
}

/// The navigator's stack of route names (top last).
class _Stack extends NavigatorObserver {
  final List<String?> names = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => names.add(route.settings.name);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (names.isNotEmpty) names.removeLast();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => names.remove(route.settings.name);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = names.lastIndexOf(oldRoute?.settings.name);
    if (i >= 0) {
      names[i] = newRoute?.settings.name;
    } else {
      names.add(newRoute?.settings.name);
    }
  }

  String? get top => names.isEmpty ? null : names.last;
}

/// Every route name pushed or put in place, in order.
class _Arrivals extends NavigatorObserver {
  final List<String?> names = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => names.add(route.settings.name);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => names.add(newRoute?.settings.name);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _open(WidgetTester tester, String route, {List<NavigatorObserver> observers = const []}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    navigatorObservers: observers,
    onGenerateRoute: (s) => s.name == _host ? MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: s) : AppRouter.onGenerateRoute(s),
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: const RouteSettings(name: _host)),
      AppRouter.onGenerateRoute(RouteSettings(name: route))!,
    ],
  ));
  await _settle(tester);
}

/// Taps the item labelled [label] (a checklist item to select).
Future<void> _tick(WidgetTester tester, String label) async {
  final item = find.text(label);
  await tester.ensureVisible(item);
  await tester.tap(item);
  await _settle(tester);
}

/// Opens records_consent_device with "Blood pressure" selected, so Continue
/// reaches the permission request (P-78: nothing starts selected).
Future<void> _openDeviceConsent(WidgetTester tester, {List<NavigatorObserver> observers = const []}) async {
  await _open(tester, Routes.recordsConsentDevice, observers: observers);
  await _tick(tester, 'Blood pressure');
}

Future<void> _tapKey(WidgetTester tester, String path) async {
  final finder = find.byKey(ValueKey('a:$path'));
  expect(finder, findsOneWidget, reason: 'element $path');
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder, warnIfMissed: false);
  await _settle(tester);
}

/// A host page under a navigator that also knows every app route;
/// [_hostContext] is a context on it.
late BuildContext _hostContext;

Future<void> _hostPage(WidgetTester tester, {List<NavigatorObserver> observers = const []}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    navigatorObservers: observers,
    onGenerateRoute: AppRouter.onGenerateRoute,
    home: Scaffold(body: Builder(builder: (c) {
      _hostContext = c;
      return const SizedBox();
    })),
  ));
}

/// Every text on screen, including toasts in the overlay.
Iterable<String> _texts(WidgetTester tester) => tester.widgetList<Text>(find.byType(Text, skipOffstage: false)).map((t) => t.data ?? t.textSpan?.toPlainText() ?? '');

void main() {
  setUp(() {
    TSession.clear();
    TFlow.onboarding = false;
  });
  tearDown(() {
    TDefaults.forPreview();
    TAuth.instance = null;
    TSim.reset();
    TSession.clear();
  });

  group('catalogue: spec/branches.json', () {
    test('every branch has exactly one production decision source, and no question text', () {
      final cat = _catalogue();
      final screens = _screens();
      final generated = Directory('lib/screens').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      final calls = generated.fold<int>(0, (n, f) => n + 'TNav.branch('.allMatches(f.readAsStringSync()).length);
      expect(cat, hasLength(calls), reason: 'one catalogue entry per generated TNav.branch call');
      const sources = {'rule', 'choice', 'server', 'auth', 'device', 'reference'};
      final questions = <String>{};
      void walk(Object? a) {
        if (a is Map) {
          if (a['type'] == 'branch') questions.add(a['question'] as String);
          for (final v in a.values) {
            walk(v);
          }
        } else if (a is List) {
          for (final v in a) {
            walk(v);
          }
        }
      }

      for (final s in screens.values) {
        walk((s as Map)['actions']);
      }
      final ids = <String>{};
      for (final r in cat) {
        final where = _where(r);
        expect(sources, contains(r['source']), reason: '$where has no production decision source');
        expect(r.containsKey('question'), isFalse, reason: where);
        for (final v in r.values) {
          if (v is String && !(r['labels'] as List).contains(v)) expect(questions.contains(v), isFalse, reason: '$where carries question text "$v"');
        }
        expect(_routeOf, contains(r['screen']), reason: where);
        final labels = (r['labels'] as List).cast<String>();
        expect(labels.length, greaterThanOrEqualTo(2), reason: where);
        switch (r['source']) {
          case 'rule' || 'choice':
            expect(r['decide'], isA<String>(), reason: where);
            expect(r['decide'].startsWith('choice:'), r['source'] == 'choice', reason: where);
          case 'server':
            expect(r['at'], 'then', reason: '$where: directly under its submit');
            expect(_endpoints().map((e) => e['endpoint']), contains(r['endpoint']), reason: where);
          case 'auth':
            expect(['apple', 'google'], contains(r['provider']), reason: where);
          case 'device' || 'reference':
            final id = r['id'] as String;
            expect(_branchId.hasMatch(id), isTrue, reason: '$where id $id');
            expect(ids.add(id), isTrue, reason: '$where id $id is not unique');
            final ask = TAsk.values.byName(r['ask'] as String);
            expect(ask == TAsk.reference, r['source'] == 'reference', reason: where);
            expect(screens[r['screen']]['reference'] == true, ask == TAsk.reference, reason: '$where: reference only on reference surfaces');
            if (ask == TAsk.reference) {
              expect(r.containsKey('when'), isFalse, reason: where);
              break;
            }
            final when = (r['when'] as Map).cast<String, Object>();
            expect(when.keys.toSet(), ask.answers.map((a) => a.name).toSet(), reason: '$where: when is total over ${ask.name}');
            final reached = <String>{};
            for (final t in when.values) {
              final targets = t is Map ? t.values.cast<String>() : [t as String];
              if (t is Map) expect(t.keys.toSet(), {'ios', 'android'}, reason: where);
              for (final l in targets) {
                expect(labels, contains(l), reason: '$where: $l');
                reached.add(l);
              }
            }
            expect(reached, labels.toSet(), reason: '$where: every case reached');
        }
      }
    });

    test('the device and reference branches are exactly the pinned mapping: id, ask and the full answer map', () {
      final cat = [for (final r in _catalogue()) if (r['source'] == 'device' || r['source'] == 'reference') r];
      expect({for (final r in cat) _where(r)}, _mapping.keys.toSet());
      for (final r in cat) {
        final (id, ask, map) = _mapping[_where(r)]!;
        expect(r['id'], id, reason: _where(r));
        expect(r['ask'], ask, reason: _where(r));
        expect(r['when'], map == null ? isNull : equals(map), reason: '${_where(r)}: answer map');
      }
      expect(_opens.keys.toSet(), {for (final e in _mapping.entries) if (e.value.$3 != null) e.key});
    });

    test('the formerly undecided branches now have a source: email sign-in by its submit, the rest by TDevice', () {
      final bySource = <String, List<String>>{};
      for (final r in _catalogue()) {
        bySource.putIfAbsent(r['source'] as String, () => []).add(_where(r));
      }
      expect(bySource['server'], ['auth_signin footer[0] then', 'auth_signin_error footer[0] then']);
      expect([...bySource['device']!, ...bySource['reference']!].length, 18);
    });

    test('spec/endpoints.json: sign-in and account endpoints are never queued, every other endpoint may be', () {
      final eps = _endpoints();
      final auth = [for (final e in eps) if ((e['endpoint'] as String).contains(' supabase /auth/')) e['endpoint']];
      expect(auth, hasLength(5));
      for (final e in eps) {
        expect(e['queueable'], !(e['endpoint'] as String).contains(' supabase /auth/'), reason: e['endpoint'] as String);
      }
    });

    test('generated screens pass queueable: false on every sign-in and account submit, and nowhere else', () {
      final submit = RegExp(r"TNav\.submit\(context, '([^']*)', screenId: '[^']*'(, queueable: false)?");
      final generated = Directory('lib/screens').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      var auth = 0;
      for (final f in generated) {
        for (final m in submit.allMatches(f.readAsStringSync())) {
          final isAuth = m.group(1)!.contains(' supabase /auth/');
          if (isAuth) auth++;
          expect(m.group(2) != null, isAuth, reason: '${f.path}: ${m.group(1)}');
        }
      }
      expect(auth, 7, reason: 'five endpoints on seven screens: the token endpoint on auth_session, auth_signin and auth_signin_error');
    });
  });

  group('every generated branch is decided without the resolver (release defaults)', () {
    final cat = _catalogue();
    for (final MapEntry(key: where, value: answers) in _opens.entries) {
      final (id, askName, _) = _mapping[where]!;
      final ask = TAsk.values.byName(askName);
      final parts = where.split(' ');
      final screen = parts[0];
      final path = parts[1];
      for (final MapEntry(key: key, value: (label, kind, route, toast)) in answers.entries) {
        final answer = TAnswer.values.byName(key.split('/').first);
        final platform = key.contains('/') ? TAnswer.values.byName(key.split('/').last) : null;
        testWidgets('device $where: $key takes "$label" and opens ${route ?? kind}', (tester) async {
          TDefaults.forRelease();
          final resolver = TFailClosedResolver();
          TNav.branchResolver = resolver.resolve;
          final device = _ScriptedDevice((ref) async => ref.ask == TAsk.platform && ask != TAsk.platform ? platform : answer);
          TDevice.instance = device;
          final stack = _Stack();
          await _open(tester, _routeOf[screen]!, observers: [stack]);
          final tick = _deviceTicks[where];
          if (tick != null) await _tick(tester, tick);
          await _tapKey(tester, path);
          expect(resolver.recorded, isEmpty, reason: 'the device answer decides the branch');
          expect(device.asked.first, TBranchRef(id, ask, screen));
          expect(device.asked, hasLength(platform == null ? 1 : 2));
          switch (kind) {
            case 'route':
              expect(stack.top, route, reason: '"$label" opens $route');
            case 'pop':
              expect(stack.top, _host, reason: '"$label" goes back');
            case 'toast':
              expect(stack.top, _routeOf[screen], reason: '"$label" stays on the screen');
          }
          if (toast != null) expect(find.text(toast), findsWidgets, reason: '"$label" shows "$toast"');
          expect(tester.takeException(), isNull);
          TCallFallback.dismiss();
          await tester.pump(const Duration(seconds: 3));
        });
      }
    }
    for (final r in cat.where((r) => r['source'] == 'server')) {
      for (final label in (r['labels'] as List).cast<String>()) {
        testWidgets('server ${_where(r)}: $label', (tester) async {
          TDefaults.forRelease();
          final resolver = TFailClosedResolver();
          TNav.branchResolver = resolver.resolve;
          final api = _ScriptedApi(TResult.outcome(label));
          TApi.instance = api;
          await _open(tester, _routeOf[r['screen']]!);
          await _tapKey(tester, r['path'] as String);
          expect(api.calls, [(r['endpoint'], r['screen'])]);
          expect(resolver.recorded, isEmpty, reason: 'the server outcome decides the branch');
          expect(tester.takeException(), isNull);
          await tester.pump(const Duration(seconds: 3));
        });
      }
    }
    test('a device branch sits inside another branch only where the pinned tick lets it run', () {
      expect({for (final r in cat) if (r['source'] == 'device' && (r['at'] as String).isNotEmpty) _where(r)}, _deviceTicks.keys.toSet());
    });
    test('a sign-in branch sits inside another branch only where the pinned tick lets it run', () {
      expect({for (final r in cat) if (r['source'] == 'auth' && (r['at'] as String).isNotEmpty) _where(r)}, _ticks.keys.toSet());
    });
    for (final r in cat.where((r) => r['source'] == 'auth')) {
      for (final label in (r['labels'] as List).cast<String>()) {
        testWidgets('auth ${_where(r)}: $label', (tester) async {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS; // shows the Apple button
          try {
            TDefaults.forRelease();
            final resolver = TFailClosedResolver();
            TNav.branchResolver = resolver.resolve;
            final auth = _ScriptedAuth(() async => label);
            TAuth.instance = auth;
            await _open(tester, _routeOf[r['screen']]!);
            final tick = _ticks[_where(r)];
            if (tick != null) {
              final item = find.text(tick);
              await tester.ensureVisible(item);
              await tester.tap(item);
              await _settle(tester);
            }
            await _tapKey(tester, r['path'] as String);
            expect(auth.calls, 1);
            expect(resolver.recorded, isEmpty, reason: 'native sign-in decides the branch');
            expect(tester.takeException(), isNull);
            await tester.pump(const Duration(seconds: 3));
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }
    }
    for (final r in cat.where((r) => r['source'] == 'reference')) {
      testWidgets('reference ${_where(r)}: never asks TDevice; the release resolver fails closed', (tester) async {
        TDefaults.forRelease();
        final resolver = TFailClosedResolver();
        TNav.branchResolver = resolver.resolve;
        final device = _ScriptedDevice((ref) async => TAnswer.granted);
        TDevice.instance = device;
        await _open(tester, _routeOf[r['screen']]!);
        await _tapKey(tester, r['path'] as String);
        expect(device.asked, isEmpty);
        expect(resolver.recorded, [TFailClosedResolver.code]);
        await tester.pump(const Duration(seconds: 3));
      });
    }
  });

  group('TDevice hook', () {
    const ref = TBranchRef('test.branch.check', TAsk.notificationsCheck, 'test_screen');
    const when = <TAnswer, String>{TAnswer.granted: 'On', TAnswer.denied: 'Off'};
    late List<String> took;
    late List<String> asked;
    Map<String, VoidCallback> outcomes() => {'On': () => took.add('On'), 'Off': () => took.add('Off')};
    setUp(() {
      took = <String>[];
      asked = <String>[];
      TNav.branchResolver = (c, q, o) async {
        asked.add(q);
        return null;
      };
    });

    testWidgets('a device answer decides the branch through when', (tester) async {
      await _hostPage(tester);
      final device = _ScriptedDevice((_) async => TAnswer.denied);
      TDevice.instance = device;
      await TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: when);
      expect(took, ['Off']);
      expect(asked, isEmpty);
      expect(device.asked, [ref]);
    });

    for (final (name, answer) in <(String, Future<TAnswer?> Function(TBranchRef))>[
      ('no answer (null)', (_) async => null),
      ('an answer outside the ask', (_) async => TAnswer.supported),
      ('a TDevice that throws', (_) async => throw Exception(_canary)),
    ]) {
      testWidgets('$name decides nothing: the resolver runs', (tester) async {
        await _hostPage(tester);
        TDevice.instance = _ScriptedDevice(answer);
        await TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: when);
        expect(took, isEmpty);
        expect(asked, ['Q']);
      });
    }

    testWidgets('an answer outside the ask decides nothing even when when maps it: the resolver runs', (tester) async {
      await _hostPage(tester);
      TDevice.instance = _ScriptedDevice((_) async => TAnswer.supported);
      await TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: const {TAnswer.supported: 'On', TAnswer.granted: 'On', TAnswer.denied: 'Off'});
      expect(took, isEmpty);
      expect(asked, ['Q']);
    });

    testWidgets('an answer the branch does not map decides nothing: the resolver runs', (tester) async {
      await _hostPage(tester);
      TDevice.instance = _ScriptedDevice((_) async => TAnswer.granted);
      await TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: const {TAnswer.denied: 'Off'});
      expect(took, isEmpty);
      expect(asked, ['Q']);
    });

    testWidgets('a mapped label that is not a case decides nothing: the resolver runs', (tester) async {
      await _hostPage(tester);
      TDevice.instance = _ScriptedDevice((_) async => TAnswer.granted);
      await TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: const {TAnswer.granted: 'Not a case', TAnswer.denied: 'Off'});
      expect(took, isEmpty);
      expect(asked, ['Q']);
    });

    testWidgets('a reference branch never asks TDevice', (tester) async {
      await _hostPage(tester);
      final device = _ScriptedDevice((_) async => TAnswer.granted);
      TDevice.instance = device;
      await TNav.branch(_hostContext, 'Q', outcomes(), device: const TBranchRef('test.branch.ref', TAsk.reference, 'test_screen'));
      expect(device.asked, isEmpty);
      expect(asked, ['Q']);
    });

    testWidgets('per platform: the platform is a second question; no platform answer decides nothing', (tester) async {
      await _hostPage(tester);
      const byPlatform = {
        TAnswer.granted: {TAnswer.ios: 'On', TAnswer.android: 'Off'},
      };
      TAnswer? platform = TAnswer.android;
      final device = _ScriptedDevice((r) async => r.ask == TAsk.platform ? platform : TAnswer.granted);
      TDevice.instance = device;
      await TNav.branch(_hostContext, 'Q', outcomes(), device: ref, whenByPlatform: byPlatform);
      expect(took, ['Off']);
      expect(device.asked, [ref, const TBranchRef('test.branch.check', TAsk.platform, 'test_screen')]);
      platform = null;
      await TNav.branch(_hostContext, 'Q', outcomes(), device: ref, whenByPlatform: byPlatform);
      expect(took, ['Off']);
      expect(asked, ['Q']);
    });

    testWidgets('order: forced, rule, server outcome and simulation queue come before TDevice', (tester) async {
      await _hostPage(tester);
      final device = _ScriptedDevice((_) async => TAnswer.granted);
      TDevice.instance = device;
      TSim.force = 'Off';
      await TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: when);
      TSim.force = null;
      TSim.queue.add('Off');
      await TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: when);
      TApi.instance = _ScriptedApi(const TResult.outcome('Off'));
      await TNav.submit(_hostContext, 'POST /x', screenId: 's', then: () => TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: when));
      await tester.pump();
      TSession.set('rr.k', 'Off');
      await TNav.branch(_hostContext, 'Q', outcomes(), decide: 'choice:rr.k', device: ref, when: when);
      expect(took, ['Off', 'Off', 'Off', 'Off']);
      expect(device.asked, isEmpty);
    });

    testWidgets('order: native sign-in comes before TDevice, TDevice before the resolver', (tester) async {
      await _hostPage(tester);
      final device = _ScriptedDevice((_) async => TAnswer.granted);
      TDevice.instance = device;
      TAuth.instance = _ScriptedAuth(() async => 'Off');
      await TNav.branch(_hostContext, 'Q', outcomes(), provider: 'apple', device: ref, when: when);
      expect(took, ['Off']);
      expect(device.asked, isEmpty);
      TAuth.instance = _ScriptedAuth(() async => null);
      await TNav.branch(_hostContext, 'Q', outcomes(), provider: 'apple', device: ref, when: when);
      expect(took, ['Off', 'On']);
      expect(device.asked, [ref]);
      expect(asked, isEmpty);
    });

    testWidgets('in flight: a second activation while the device answer is pending is ignored; once done a new one asks again', (tester) async {
      await _hostPage(tester);
      final gates = <Completer<TAnswer?>>[];
      final device = _ScriptedDevice((_) {
        final g = Completer<TAnswer?>();
        gates.add(g);
        return g.future;
      });
      TDevice.instance = device;
      final first = TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: when);
      final second = TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: when);
      await second;
      expect(device.asked, hasLength(1));
      gates.single.complete(TAnswer.granted);
      await first;
      expect(took, ['On']);
      final third = TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: when);
      expect(device.asked, hasLength(2));
      gates.last.complete(TAnswer.denied);
      await third;
      expect(took, ['On', 'Off']);
    });

    testWidgets('in flight: two pointer taps on a generated permission button raise one system prompt', (tester) async {
      final gates = <Completer<TAnswer?>>[];
      final device = _ScriptedDevice((_) {
        final g = Completer<TAnswer?>();
        gates.add(g);
        return g.future;
      });
      TDevice.instance = device;
      await _openDeviceConsent(tester);
      final button = find.byKey(const ValueKey('a:footer[0]'));
      await tester.ensureVisible(button);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(button, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(button, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 150));
      expect(device.asked, hasLength(1));
      gates.single.complete(TAnswer.granted);
      await _settle(tester);
      expect(find.byType(RecordsImportingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('in flight: after TSession.clear a new activation is not blocked by the earlier one', (tester) async {
      await _hostPage(tester);
      final gates = <Completer<TAnswer?>>[];
      final device = _ScriptedDevice((_) {
        final g = Completer<TAnswer?>();
        gates.add(g);
        return g.future;
      });
      TDevice.instance = device;
      final first = TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: when);
      TSession.clear();
      final second = TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: when);
      expect(device.asked, hasLength(2));
      gates[0].complete(TAnswer.granted);
      await first;
      final third = TNav.branch(_hostContext, 'Q', outcomes(), device: ref, when: when);
      expect(device.asked, hasLength(2), reason: 'the second activation is still in flight');
      await third;
      gates[1].complete(TAnswer.denied);
      await second;
      expect(took, ['On', 'Off']);
    });

    testWidgets('release default TInertDevice: no answer, records only its code; the fail-closed resolver shows the generic error', (tester) async {
      TDefaults.forRelease();
      final device = TDevice.instance as TInertDevice;
      final resolver = TFailClosedResolver();
      TNav.branchResolver = resolver.resolve;
      await _open(tester, Routes.obReminders);
      await _tapKey(tester, 'footer[0]');
      expect(device.recorded, [TInertDevice.code]);
      expect(device.recorded.single.contains('onboarding'), isFalse);
      expect(resolver.recorded, [TFailClosedResolver.code]);
      expect(find.text(TFailClosedResolver.message), findsOneWidget);
      expect(find.textContaining('Preview:'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    test('defaults: PreviewDevice in debug and tests, TInertDevice in release; TBranchRef prints no question', () {
      expect(TDefaults.device(), isA<PreviewDevice>());
      expect(TDefaults.device(release: true), isA<TInertDevice>());
      expect(TDevice.instance, isA<PreviewDevice>());
      expect('$ref', 'TBranchRef(test.branch.check, notificationsCheck, test_screen)');
      expect(ref, const TBranchRef('test.branch.check', TAsk.notificationsCheck, 'test_screen'));
    });
  });

  group('question redaction', () {
    testWidgets('release defaults pass an empty question to the resolver', (tester) async {
      TDefaults.forRelease();
      final got = <String>[];
      TNav.branchResolver = (c, q, o) async {
        got.add(q);
        return null;
      };
      await _openDeviceConsent(tester);
      await _tapKey(tester, 'footer[0]');
      await _hostPage(tester);
      await TNav.branch(_hostContext, 'Sign-in result', {'A': () {}, 'B': () {}});
      expect(got, ['', '']);
      expect(TNav.redactQuestion, isTrue);
    });

    testWidgets('preview defaults pass the question (the preview chooser shows it)', (tester) async {
      TDefaults.forRelease();
      TDefaults.forPreview();
      expect(TNav.redactQuestion, isFalse);
      final got = <String>[];
      TNav.branchResolver = (c, q, o) async {
        got.add(q);
        return null;
      };
      await _openDeviceConsent(tester);
      await _tapKey(tester, 'footer[0]');
      expect(got, ['System permission result']);
    });

    testWidgets('redactQuestion set directly also redacts', (tester) async {
      TNav.redactQuestion = true;
      final got = <String>[];
      TNav.branchResolver = (c, q, o) async {
        got.add(q);
        return null;
      };
      await _hostPage(tester);
      await TNav.branch(_hostContext, 'What the member chose', {'A': () {}, 'B': () {}});
      expect(got, ['']);
    });
  });

  group('email sign-in is a submit, never queued (P-51)', () {
    for (final (screen, route) in [('auth_signin', Routes.authSignin), ('auth_signin_error', Routes.authSigninError)]) {
      for (final (label, expected) in <(String, Type)>[
        ('Success', TodayScreen),
        ('Success · guest plan on phone', AuthMergeScreen),
        ('Wrong password', AuthSigninErrorScreen),
      ]) {
        testWidgets('$screen: server outcome "$label" opens $expected', (tester) async {
          final api = _ScriptedApi(TResult.outcome(label));
          TApi.instance = api;
          await _open(tester, route);
          await _tapKey(tester, 'footer[0]');
          expect(api.calls, [('POST supabase /auth/v1/token', screen)]);
          expect(find.byType(expected), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('P-51: the retry offers the guest-plan case, as normal sign-in does', (tester) async {
      final cat = _catalogue();
      List<String> labels(String screen) => (cat.singleWhere((r) => r['screen'] == screen && r['source'] == 'server')['labels'] as List).cast<String>();
      expect(labels('auth_signin_error'), labels('auth_signin'));
      expect(labels('auth_signin_error'), contains('Success · guest plan on phone'));
    });

    for (final screen in [Routes.authSignin, Routes.authSigninError]) {
      testWidgets('$screen: a queued result is a failure: nothing navigates, the generic error shows', (tester) async {
        final arrivals = _Arrivals();
        TApi.instance = _ScriptedApi(const TResult.queued());
        await _open(tester, screen, observers: [arrivals]);
        arrivals.names.clear();
        await _tapKey(tester, 'footer[0]');
        expect(arrivals.names, isEmpty);
        expect(find.text(TFailClosedResolver.message), findsOneWidget);
        _noKeptClaim(tester);
        expect(find.byType(screen == Routes.authSignin ? AuthSigninScreen : AuthSigninErrorScreen), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('$screen: a failed sign-in shows the generic error, never the code', (tester) async {
        TApi.instance = _ScriptedApi(const TResult.failed(_canary));
        await _open(tester, screen);
        await _tapKey(tester, 'footer[0]');
        expect(find.text(TFailClosedResolver.message), findsOneWidget);
        _noKeptClaim(tester);
        for (final t in _texts(tester)) {
          expect(t.contains('canary'), isFalse, reason: t);
        }
        await tester.pump(const Duration(seconds: 3));
      });
    }

    testWidgets('release defaults: sign-in fails closed with the generic error and stays on the sheet', (tester) async {
      TDefaults.forRelease();
      await _open(tester, Routes.authSignin);
      await _tapKey(tester, 'footer[0]');
      expect(find.byType(AuthSigninScreen), findsOneWidget);
      expect(find.text(TFailClosedResolver.message), findsOneWidget);
      _noKeptClaim(tester);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('an adapter that returns ok without an outcome decides nothing: release fails closed', (tester) async {
      TDefaults.forRelease();
      final resolver = TFailClosedResolver();
      TNav.branchResolver = resolver.resolve;
      TApi.instance = _ScriptedApi(const TResult.ok());
      await _open(tester, Routes.authSignin);
      await _tapKey(tester, 'footer[0]');
      expect(resolver.recorded, [TFailClosedResolver.code]);
      expect(find.byType(AuthSigninScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('TNav.submit with queueable: false returns failed(not_queueable) for a queued result; a queueable submit continues', (tester) async {
      await _hostPage(tester);
      TApi.instance = _ScriptedApi(const TResult.queued());
      var ran = 0;
      expect(await TNav.submit(_hostContext, 'POST supabase /auth/v1/token', screenId: 's', queueable: false, then: () => ran++), const TResult.failed(TNav.notQueueableCode));
      expect(ran, 0);
      expect(await TNav.submit(_hostContext, 'POST /v1/records/check-ins', screenId: 's', then: () => ran++), const TResult.queued());
      expect(ran, 1);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a failed save that may be queued shows the generic error, which never says the entry was kept', (tester) async {
      await _hostPage(tester);
      TApi.instance = _ScriptedApi(const TResult.failed('synthetic_code'));
      await TNav.submit(_hostContext, 'POST /v1/records/check-ins', screenId: 's');
      await tester.pump();
      expect(find.text(TNav.saveFailed), findsOneWidget);
      expect(TNav.saveFailed, TFailClosedResolver.message);
      _noKeptClaim(tester);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('route scope: a late answer acts only on the screen that asked', () {
    Future<void> openCrisis(WidgetTester tester) async {
      unawaited(Navigator.of(_hostContext).pushNamed(Routes.crisis));
      await _settle(tester);
      expect(find.byType(CrisisScreen), findsOneWidget);
    }

    testWidgets('a late sign-in close never pops the crisis screen the member opened', (tester) async {
      await _hostPage(tester);
      final gate = Completer<String?>();
      TAuth.instance = _ScriptedAuth(() => gate.future);
      final asked = <String>[];
      TNav.branchResolver = (c, q, o) async {
        asked.add(q);
        return null;
      };
      final done = TNav.branch(_hostContext, 'Sign in with Apple result', {'Cancelled': () => TNav.close(_hostContext), 'Success': () => TNav.reset(_hostContext, Routes.today)}, provider: 'apple');
      await openCrisis(tester);
      gate.complete('Cancelled');
      await done;
      await _settle(tester);
      expect(find.byType(CrisisScreen), findsOneWidget);
      expect(asked, isEmpty, reason: 'no fail-closed error over the crisis screen either');
    });

    testWidgets('a late sign-in success on a generated sheet never resets past the crisis screen', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final gate = Completer<String?>();
        TAuth.instance = _ScriptedAuth(() => gate.future);
        await _open(tester, Routes.authSignin);
        await _tapKey(tester, 'body[1].items[0]'); // Continue with Apple
        final ctx = tester.element(find.byType(AuthSigninScreen));
        unawaited(Navigator.of(ctx).pushNamed(Routes.crisis));
        await _settle(tester);
        gate.complete('Success');
        await _settle(tester);
        expect(find.byType(CrisisScreen), findsOneWidget);
        expect(find.byType(TodayScreen), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('a late device answer does not push over the crisis screen', (tester) async {
      final arrivals = _Arrivals();
      final gate = Completer<TAnswer?>();
      TDevice.instance = _ScriptedDevice((_) => gate.future);
      await _openDeviceConsent(tester, observers: [arrivals]);
      await _tapKey(tester, 'footer[0]');
      final ctx = tester.element(find.byType(RecordsConsentDeviceScreen));
      unawaited(Navigator.of(ctx).pushNamed(Routes.crisis));
      await _settle(tester);
      arrivals.names.clear();
      gate.complete(TAnswer.granted);
      await _settle(tester);
      expect(arrivals.names, isEmpty);
      expect(find.byType(CrisisScreen), findsOneWidget);
      expect(find.textContaining('Preview:'), findsNothing);
    });

    testWidgets('a late empty device answer never asks the resolver over the crisis screen (no error toast there)', (tester) async {
      TDefaults.forRelease();
      final resolver = TFailClosedResolver();
      TNav.branchResolver = resolver.resolve;
      final gate = Completer<TAnswer?>();
      TDevice.instance = _ScriptedDevice((_) => gate.future);
      await _openDeviceConsent(tester);
      await _tapKey(tester, 'footer[0]');
      unawaited(Navigator.of(tester.element(find.byType(RecordsConsentDeviceScreen))).pushNamed(Routes.crisis));
      await _settle(tester);
      gate.complete(null);
      await _settle(tester);
      expect(resolver.recorded, isEmpty);
      expect(find.text(TFailClosedResolver.message), findsNothing);
      expect(find.byType(CrisisScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a branch started on a covered screen does not ask the resolver over the screen on top', (tester) async {
      await _hostPage(tester);
      final asked = <String>[];
      TNav.branchResolver = (c, q, o) async {
        asked.add(q);
        return o.first;
      };
      await openCrisis(tester);
      final took = <String>[];
      await TNav.branch(_hostContext, 'Q', {'Back': () => took.add('Back'), 'Other': () => took.add('Other')});
      await _settle(tester);
      expect(asked, isEmpty);
      expect(took, isEmpty);
      expect(find.byType(CrisisScreen), findsOneWidget);
    });

    testWidgets('a late resolver answer does not act over the crisis screen', (tester) async {
      await _hostPage(tester);
      final gate = Completer<String?>();
      TNav.branchResolver = (c, q, o) => gate.future;
      final took = <String>[];
      final done = TNav.branch(_hostContext, 'Q', {'Back': () => TNav.back(_hostContext), 'Other': () => took.add('Other')});
      await openCrisis(tester);
      gate.complete('Back');
      await done;
      await _settle(tester);
      expect(find.byType(CrisisScreen), findsOneWidget);
      expect(took, isEmpty);
    });

    testWidgets('a late answer after the screen was closed runs nothing', (tester) async {
      final gate = Completer<TAnswer?>();
      final arrivals = _Arrivals();
      TDevice.instance = _ScriptedDevice((_) => gate.future);
      await _openDeviceConsent(tester, observers: [arrivals]);
      await _tapKey(tester, 'footer[0]');
      Navigator.of(tester.element(find.byType(RecordsConsentDeviceScreen))).pop();
      await _settle(tester);
      arrivals.names.clear();
      gate.complete(TAnswer.granted);
      await _settle(tester);
      expect(arrivals.names, isEmpty);
      expect(find.byType(RecordsImportingScreen), findsNothing);
    });

    testWidgets('control: an answer that arrives while the screen is on top acts', (tester) async {
      await _hostPage(tester);
      final gate = Completer<String?>();
      TAuth.instance = _ScriptedAuth(() => gate.future);
      final took = <String>[];
      final done = TNav.branch(_hostContext, 'Q', {'Cancelled': () => took.add('Cancelled'), 'Success': () => took.add('Success')}, provider: 'apple');
      gate.complete('Cancelled');
      await done;
      expect(took, ['Cancelled']);
    });

    testWidgets('control: after the member closes the crisis screen, a later answer acts again on the screen that asked', (tester) async {
      await _hostPage(tester);
      final gates = <Completer<String?>>[];
      TAuth.instance = _ScriptedAuth(() {
        final g = Completer<String?>();
        gates.add(g);
        return g.future;
      });
      final took = <String>[];
      Map<String, VoidCallback> outcomes() => {'Cancelled': () => took.add('Cancelled'), 'Success': () => took.add('Success')};
      final first = TNav.branch(_hostContext, 'Q', outcomes(), provider: 'apple');
      await openCrisis(tester);
      Navigator.of(tester.element(find.byType(CrisisScreen))).pop();
      await _settle(tester);
      gates.single.complete('Success');
      await first;
      expect(took, ['Success'], reason: 'the asking screen is on top again when the answer arrives');
    });
  });
}
