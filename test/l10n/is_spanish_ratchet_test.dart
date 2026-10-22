// The files still allowed to choose their text with `isSpanish`. Each ticket
// that moves a file's text into the translation files removes that file
// from [isSpanishFiles] in the same change; the list only ever shrinks, and
// the last ticket empties it. The language mapping itself
// (lib/l10n/app_locale.dart) is not text selection and stays.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const isSpanishFiles = <String>{
  'lib/screens/active_craving_rescue_screen.dart',
  'lib/screens/approved_screen_player.dart',
  'lib/screens/baseline_assessment_screen.dart',
  'lib/screens/choose_quit_path_screen.dart',
  'lib/screens/consent_privacy_screen.dart',
  'lib/screens/craving_recheck_screen.dart',
  'lib/screens/craving_rescue_start_screen.dart',
  'lib/screens/daily_check_in_screen.dart',
  'lib/screens/exercise_complete_recheck_screen.dart',
  'lib/screens/guided_stress_reset_screen.dart',
  'lib/screens/home_preparation_screen.dart',
  'lib/screens/learn_library_screen.dart',
  'lib/screens/medication_center_screen.dart',
  'lib/screens/my_reasons_screen.dart',
  'lib/screens/personalized_next_step_screen.dart',
  'lib/screens/progress_dashboard_screen.dart',
  'lib/screens/quit_day_home_screen.dart',
  'lib/screens/readiness_result_screen.dart',
  'lib/screens/recommended_rescue_tool_screen.dart',
  'lib/screens/rescue_result_next_step_screen.dart',
  'lib/screens/resource_screen_widgets.dart',
  'lib/screens/review_quit_plan_screen.dart',
  'lib/screens/select_quit_date_screen.dart',
  'lib/screens/settings_privacy_screen.dart',
  'lib/screens/slip_recovery_screen.dart',
  'lib/screens/support_hub_screen.dart',
  'lib/screens/support_preparation_screen.dart',
  'lib/screens/trigger_map_screen.dart',
  'lib/screens/welcome_screen.dart',
  'lib/screens/why_breathefree_screen.dart',
};

/// The app language mapping: AppLocale.isSpanish says which language the
/// app runs in; it chooses no text.
const languageMapping = <String>{'lib/l10n/app_locale.dart'};

final _word = RegExp(r'\bisSpanish\b');

Set<String> filesUsingIsSpanish() => {
      for (final f
          in Directory('lib').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') && _word.hasMatch(f.readAsStringSync()))
          f.path.replaceAll(r'\', '/'),
    };

void main() {
  test('only the listed files choose text with isSpanish', () {
    final using = filesUsingIsSpanish();
    final extra = using.difference({...isSpanishFiles, ...languageMapping});
    expect(extra, isEmpty,
        reason:
            'new isSpanish text selection; use the translation files (lib/l10n/app_*.arb)');
  });

  test('a file whose text has moved leaves the list', () {
    final using = filesUsingIsSpanish();
    final stale = isSpanishFiles.difference(using);
    expect(stale, isEmpty,
        reason:
            'remove these from isSpanishFiles: they no longer use isSpanish');
  });

  test(
      'the list only shrinks: every listed file had en/es text at the baseline',
      () {
    final inventory = jsonDecode(
            File('test/l10n/baseline/legacy_literals.json').readAsStringSync())
        as Map<String, Object?>;
    final files = (inventory['files']! as Map<String, Object?>).entries.where(
        (e) => (e.value! as List).any((r) => const {'en', 'es'}
            .contains((r as Map<String, Object?>)['branch'])));
    final withText = {for (final e in files) e.key};
    expect(isSpanishFiles.difference(withText), isEmpty,
        reason: 'a file that had no English/Spanish branches at the baseline '
            'cannot be added to the list');
  });

  test('the language mapping is still where the app reads the language', () {
    expect(filesUsingIsSpanish().containsAll(languageMapping), isTrue);
  });
}
