import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The staging files: render.staging.yaml (parsed with Ruby's YAML parser,
// Psych, which macOS and the CI's ubuntu-latest image ship), the guarded seed
// supabase/staging/seed_staging.sql, docs/STAGING.md and tool/staging_db.sh.
// The seed's database guard is checked on PostgreSQL outside this suite; here
// its text is pinned. tool/staging_db.sh runs in a temporary root with a fake
// supabase CLI on a private PATH. Every value is synthetic.

String join(List<String> parts) => parts.join(Platform.pathSeparator);

final _hostsList = RegExp(r'STAGING_HOSTS = frozenset\(\([^)]*\)\)');

Map<String, Object?> _parseYaml(String path) {
  final r = Process.runSync('ruby', [
    '-ryaml',
    '-rjson',
    '-e',
    'puts JSON.generate(YAML.safe_load(File.read(ARGV[0])))',
    path,
  ]);
  expect(r.exitCode, 0, reason: '${r.stderr}');
  return jsonDecode(r.stdout as String) as Map<String, Object?>;
}

void main() {
  group('render.staging.yaml', () {
    late List<Map<String, Object?>> services;

    setUpAll(() {
      final blueprint = _parseYaml('render.staging.yaml');
      expect(blueprint.keys, ['services']);
      services = [
        for (final s in blueprint['services']! as List)
          s as Map<String, Object?>,
      ];
    });

    Map<String, Object?> service(String name) =>
        services.singleWhere((s) => s['name'] == name);

    List<Map<String, Object?>> vars(String name) => [
          for (final v in service(name)['envVars']! as List)
            v as Map<String, Object?>,
        ];

    test('exactly the API and thsync staging services', () {
      expect(services.map((s) => s['name']),
          ['tether-api-staging', 'tether-thsync-staging']);
      for (final s in services) {
        expect(s['type'], 'web');
        expect(s['autoDeployTrigger'], 'off', reason: '${s['name']}');
        expect(s.containsKey('autoDeploy'), isFalse);
      }
    });

    test('the API service', () {
      final api = service('tether-api-staging');
      expect(api['runtime'], 'node');
      expect(api['rootDir'], 'api');
      expect(api['healthCheckPath'], '/health');
      expect(api['startCommand'], 'node dist/main.js');
      expect(
        {for (final v in vars('tether-api-staging')) v['key']: v},
        {
          'NODE_ENV': {'key': 'NODE_ENV', 'value': 'production'},
          'SUPABASE_URL': {'key': 'SUPABASE_URL', 'sync': false},
          'SUPABASE_ANON_KEY': {'key': 'SUPABASE_ANON_KEY', 'sync': false},
          'SUPABASE_JWT_AUDIENCE': {
            'key': 'SUPABASE_JWT_AUDIENCE',
            'value': 'authenticated',
          },
        },
      );
    });

    test('the thsync service', () {
      final sync = service('tether-thsync-staging');
      expect(sync['runtime'], 'python');
      expect(sync['rootDir'], 'sync');
      expect(sync['healthCheckPath'], '/v1/health');
      expect(sync['buildCommand'],
          'pip install --require-hashes -r requirements-lock.txt');
      expect(sync['startCommand'],
          'uvicorn --factory thsync.app:create_app --host 0.0.0.0 --port \$PORT');
      expect(
        {for (final v in vars('tether-thsync-staging')) v['key']: v},
        {
          'PYTHON_VERSION': {'key': 'PYTHON_VERSION', 'value': '3.12.11'},
          'THSYNC_ENVIRONMENT': {
            'key': 'THSYNC_ENVIRONMENT',
            'value': 'production',
          },
          'THSYNC_SUPABASE_URL': {'key': 'THSYNC_SUPABASE_URL', 'sync': false},
          'THSYNC_DATABASE_URL': {'key': 'THSYNC_DATABASE_URL', 'sync': false},
          'THSYNC_JWT_AUDIENCE': {
            'key': 'THSYNC_JWT_AUDIENCE',
            'value': 'authenticated',
          },
        },
      );
    });

    test('every secret is sync: false and no service key or JWT secret', () {
      final secretish = RegExp(r'KEY|SECRET|PASSWORD|TOKEN|DATABASE_URL');
      for (final s in services) {
        for (final v in vars(s['name']! as String)) {
          final key = v['key']! as String;
          expect(key, isNot(contains('SERVICE_ROLE')));
          expect(key, isNot('THSYNC_JWT_SECRET'));
          if (secretish.hasMatch(key)) {
            expect(v, {'key': key, 'sync': false}, reason: key);
          }
          if (v.containsKey('value')) {
            expect(v['value'], isNot(contains('supabase.co')), reason: key);
          }
        }
      }
      final text = File('render.staging.yaml').readAsStringSync();
      expect(text, isNot(contains('sb_secret_')));
      expect(text, isNot(contains('sb_publishable_')));
      expect(text, isNot(contains('eyJ')));
    });
  });

  group('seed_staging.sql', () {
    final seed = File('supabase/staging/seed_staging.sql').readAsStringSync();
    final code = seed
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('--'))
        .join('\n');

    test('the guard runs first, inside the one transaction', () {
      final statements = code.trim();
      expect(statements, startsWith('begin;\n\ndo \$guard\$\nbegin\n'));
      expect(
        code,
        contains("  if coalesce(current_setting('app.environment', true), '') "
            "<> 'staging' then\n    raise exception"),
      );
      expect(statements, endsWith('commit;'));
      expect(RegExp(r'\bcommit\b').allMatches(code), hasLength(1));
      expect(
          RegExp(r'\brollback\b|\bset\s+app\.', caseSensitive: false)
              .hasMatch(code),
          isFalse);
      final guard = code.indexOf('raise exception');
      final insert = code.indexOf('insert into');
      expect(guard, greaterThan(0));
      expect(insert, greaterThan(guard));
    });

    test('it writes only DRAFT · staging consent documents', () {
      expect(RegExp(r'\binsert into\b').allMatches(code), hasLength(1));
      expect(code, contains('insert into public.consent_documents '));
      expect(code, contains("'[DRAFT · staging] "));
      expect(code, contains("'v1-staging'"));
      expect(code, isNot(contains('approved_ref')));
      expect(
        RegExp(r'\b(update|delete|truncate|drop|alter|grant|create)\b',
                caseSensitive: false)
            .hasMatch(code.replaceAll('raise exception', '')),
        isFalse,
      );
      expect(code, isNot(contains('auth.users')));
    });
  });

  group('docs/STAGING.md', () {
    final doc = File('docs/STAGING.md').readAsStringSync();

    test('counsel comes first and the steps are the owner runbook', () {
      final counsel = doc.indexOf('## 0. Before anything: counsel');
      expect(counsel, greaterThan(0));
      for (final heading in [
        '## 1. Create the Supabase project',
        '## 2. Mark the database as staging',
        '## 3. Apply the migrations',
        '## 4. Give the sync role a login',
        '## 5. Create the two Render services',
        '## 6. Set STAGING_HOSTS',
        '## 7. Seed the staging consent documents',
        '## 8. Read-only checks',
      ]) {
        expect(doc.indexOf(heading), greaterThan(counsel), reason: heading);
      }
      expect(doc, contains('Never promote an internal build to production.'));
    });

    test('it names the migration range that exists', () {
      final files = Directory('supabase/migrations')
          .listSync()
          .map((e) => e.uri.pathSegments.last)
          .where((n) => n.endsWith('.sql'))
          .toList()
        ..sort();
      expect(
          doc,
          contains('today ${files.length} files, from '
              '`${files.first}` to\n`${files.last}`'));
    });

    test('it holds no secret value', () {
      expect(RegExp(r'sb_secret_[A-Za-z0-9]').hasMatch(doc), isFalse);
      expect(doc, isNot(contains('eyJ')));
      expect(
          RegExp(r'postgres(ql)?(\+psycopg)?://[^<\s`]*:[^<\s`]+@[^<]')
              .hasMatch(doc),
          isFalse);
      expect(RegExp(r'sb_publishable_[A-Za-z0-9]').hasMatch(doc), isFalse);
    });
  });

  group('tool/staging_db.sh', () {
    late Directory root;
    late File supabaseLog;

    File inRoot(String relative) =>
        File(join([root.path, ...relative.split('/')]));

    void useHosts(List<String> hosts) {
      final source = File('tool/release_define_check.sh').readAsStringSync();
      inRoot('tool/release_define_check.sh')
          .writeAsStringSync(source.replaceFirst(
              _hostsList,
              'STAGING_HOSTS = frozenset((\n'
              '${hosts.map((h) => '    "$h",\n').join()}))'));
    }

    setUp(() {
      root = Directory.systemTemp.createTempSync('staging_db_test_');
      inRoot('tool/x').parent.createSync(recursive: true);
      File('tool/staging_db.sh').copySync(inRoot('tool/staging_db.sh').path);
      useHosts(const []);
      inRoot('supabase/staging/seed_staging.sql')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('select 1;\n');
      final bin = Directory(join([root.path, 'bin']))..createSync();
      final python = Process.runSync('which', ['python3']).stdout.toString();
      Link(join([bin.path, 'python3'])).createSync(python.trim());
      supabaseLog = inRoot('supabase_log');
      final fake = File(join([bin.path, 'supabase']))
        ..writeAsStringSync('#!/bin/sh\n'
            'for a in "\$@"; do printf "[%s]" "\$a" >> "${supabaseLog.path}"; '
            'done\necho >> "${supabaseLog.path}"\n');
      Process.runSync('chmod', ['+x', fake.path]);
    });

    tearDown(() => root.deleteSync(recursive: true));

    const password = 'SyntheticPassw0rdCanary';
    const direct = 'postgresql://postgres:$password@db.stagingref.supabase.co'
        ':5432/postgres';
    const pooler = 'postgresql://postgres.stagingref:$password'
        '@aws-0-us-west-1.pooler.supabase.com:5432/postgres';
    const production = 'postgresql://postgres:$password@db.prodref.supabase.co'
        ':5432/postgres';

    ProcessResult run(List<String> args, {String? url}) => Process.runSync(
          '/bin/sh',
          [inRoot('tool/staging_db.sh').path, ...args],
          environment: {
            'PATH': '${root.path}/bin:/usr/bin:/bin',
            if (url != null) 'STAGING_DATABASE_URL': url,
          },
          includeParentEnvironment: false,
        );

    List<String> calls() => supabaseLog.existsSync()
        ? supabaseLog.readAsLinesSync()
        : const <String>[];

    void expectNoLeak(ProcessResult r) {
      final out = '${r.stdout}${r.stderr}';
      expect(out, isNot(contains(password)));
      expect(out, isNot(contains('stagingref')));
      expect(out, isNot(contains('prodref')));
    }

    test('every command is refused while STAGING_HOSTS is empty', () {
      for (final args in [
        ['check'],
        ['migrate', '--dry-run'],
        ['migrate'],
        ['list'],
        ['seed', '--dry-run'],
        ['seed'],
      ]) {
        final r = run(args, url: direct);
        expect(r.exitCode, 1, reason: '$args');
        expect(
            r.stderr,
            'staging_db: STAGING_HOSTS in tool/release_define_check.sh is '
            'empty; the staging backend does not exist yet\n');
        expectNoLeak(r);
      }
      expect(calls(), isEmpty);
    });

    test('usage errors and a missing URL never reach the CLI', () {
      for (final (args, code) in [
        (<String>[], 2),
        (['drop'], 2),
        (['seed', '--force'], 2),
        (['check', '--dry-run'], 2),
      ]) {
        expect(run(args, url: direct).exitCode, code, reason: '$args');
      }
      final missing = run(['check']);
      expect(missing.exitCode, 1);
      expect(missing.stderr, contains('STAGING_DATABASE_URL is not set'));
      expect(calls(), isEmpty);
    });

    group('with STAGING_HOSTS listed', () {
      setUp(() => useHosts(const ['stagingref.supabase.co']));

      test('a production database is refused', () {
        for (final url in [
          production,
          'postgresql://postgres.prodref:$password'
              '@aws-0-us-west-1.pooler.supabase.com:5432/postgres',
          'postgresql://postgres:$password'
              '@aws-0-us-west-1.pooler.supabase.com:5432/postgres',
          'https://stagingref.supabase.co',
        ]) {
          final r = run(['seed'], url: url);
          expect(r.exitCode, 1, reason: url);
          expectNoLeak(r);
        }
        expect(calls(), isEmpty);
      });

      test('the staging database, direct or through the pooler, passes', () {
        for (final url in [direct, pooler]) {
          final r = run(['check'], url: url);
          expect(r.exitCode, 0, reason: '${r.stderr}');
          expect(r.stdout,
              'staging_db: the target belongs to a host in STAGING_HOSTS.\n');
          expectNoLeak(r);
        }
        expect(calls(), isEmpty);
      });

      test('dry runs never write; each command calls the CLI once', () {
        final seedDry = run(['seed', '--dry-run'], url: direct);
        expect(seedDry.exitCode, 0);
        expect(seedDry.stdout, contains('nothing was run'));
        expect(calls(), isEmpty);
        for (final (args, expected) in [
          (
            ['migrate', '--dry-run'],
            '[db][push][--db-url][$direct][--dry-run]'
          ),
          (['migrate'], '[db][push][--db-url][$direct]'),
          (['list'], '[migration][list][--db-url][$direct]'),
          (
            ['seed'],
            '[db][query][--db-url][$direct][-f]'
                '[supabase/staging/seed_staging.sql]'
          ),
        ]) {
          if (supabaseLog.existsSync()) supabaseLog.deleteSync();
          final r = run(args, url: direct);
          expect(r.exitCode, 0, reason: '$args ${r.stderr}');
          expect(calls(), [expected], reason: '$args');
          expectNoLeak(r);
        }
      });
    });
  });
}
