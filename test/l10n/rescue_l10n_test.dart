// The rescue screens' speech follows the app locale: the voice is US
// Spanish for Spanish and US English otherwise, and what is spoken is the
// same localized message the screen shows.
import 'package:breathefree_patient/l10n/app_localizations.dart';
import 'package:breathefree_patient/screens/active_craving_rescue_screen.dart';
import 'package:breathefree_patient/screens/craving_rescue_start_screen.dart';
import 'package:breathefree_patient/screens/guided_stress_reset_screen.dart';
import 'package:breathefree_patient/screens/recommended_rescue_tool_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _tts = MethodChannel('flutter_tts');

List<MethodCall> _recordSpeech() {
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_tts, (call) async {
    calls.add(call);
    return 1;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(_tts, null));
  return calls;
}

Widget _app(Locale locale, Widget home) => MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );

void _ignoreProgress(StressResetStep step, int stepSeconds, int totalSeconds) {}

void main() {
  test('the speech voice follows the language', () {
    expect(rescueSpeechLanguage(const Locale('en')), 'en-US');
    expect(rescueSpeechLanguage(const Locale('en', 'GB')), 'en-US');
    expect(rescueSpeechLanguage(const Locale('es')), 'es-US');
    expect(rescueSpeechLanguage(const Locale('es', 'MX')), 'es-US');
    expect(rescueSpeechLanguage(const Locale('fr')), 'en-US');
  });

  for (final (locale, voice) in [
    (const Locale('en'), 'en-US'),
    (const Locale('es'), 'es-US'),
  ]) {
    testWidgets(
        'craving rescue speaks the shown breathing cue in ${locale.languageCode}',
        (tester) async {
      final calls = _recordSpeech();
      await tester.pumpWidget(_app(
        locale,
        ActiveCravingRescueScreen(
          isSpanish: locale.languageCode == 'es',
          tool: RescueTool.slowBreathing,
          elapsedSeconds: 0,
          isPaused: false,
          voiceEnabled: true,
          hapticsEnabled: false,
          onElapsedChanged: (_) {},
          onPausedChanged: (_) {},
          onVoiceChanged: (_) {},
          onHapticsChanged: (_) {},
          onClose: () {},
          onComplete: () {},
          onSwitchTool: () {},
          onOpenSupport: () {},
        ),
      ));
      await tester.pump();
      await tester.pump();
      final l10n = lookupAppLocalizations(locale);
      expect(
          calls.where((c) => c.method == 'setLanguage').map((c) => c.arguments),
          [voice]);
      expect(calls.where((c) => c.method == 'speak').map((c) => c.arguments),
          contains(l10n.activeCravingRescueSpokenBreatheIn));
      expect(
          l10n.activeCravingRescueSpokenBreatheIn,
          locale.languageCode == 'es'
              ? 'Inhala lentamente'
              : 'Breathe in slowly');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'stress reset speaks the shown instruction in ${locale.languageCode}',
        (tester) async {
      final calls = _recordSpeech();
      await tester.pumpWidget(_app(
        locale,
        GuidedStressResetScreen(
          isSpanish: locale.languageCode == 'es',
          step: StressResetStep.breathe,
          stepElapsedSeconds: 0,
          totalElapsedSeconds: 0,
          isPaused: false,
          voiceGuidanceEnabled: true,
          reducedMotionEnabled: true,
          onProgressChanged: _ignoreProgress,
          onPausedChanged: (_) {},
          onVoiceGuidanceChanged: (_) {},
          onReducedMotionChanged: (_) {},
          onClose: () {},
          onComplete: () {},
          onOpenRescue: () {},
        ),
      ));
      await tester.pump();
      await tester.pump();
      final l10n = lookupAppLocalizations(locale);
      final instruction = l10n.guidedStressResetBreatheInInstruction;
      expect(find.text(instruction), findsOneWidget,
          reason: 'the spoken text is the shown instruction');
      expect(
          calls.where((c) => c.method == 'setLanguage').map((c) => c.arguments),
          [voice]);
      expect(calls.where((c) => c.method == 'speak').map((c) => c.arguments),
          contains(instruction));
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'each rescue screen asserts that its language matches the app locale',
      (tester) async {
    _recordSpeech();
    final screens = <String, Widget>{
      'start': CravingRescueStartScreen(
        isSpanish: true,
        intensity: 6,
        selectedContexts: const {},
        topReason: 'Protect my family',
        supportName: 'Jordan',
        onIntensityChanged: (_) {},
        onContextsChanged: (_) {},
        onClose: () {},
        onContinue: () {},
        onViewSupport: () {},
      ),
      'recommended': RecommendedRescueToolScreen(
        isSpanish: true,
        intensity: 6,
        stressSelected: false,
        supportName: 'Jordan',
        selectedTool: RescueTool.slowBreathing,
        onToolChanged: (_) {},
        onBack: () {},
        onStart: () {},
        onViewSupport: () {},
      ),
      'active': ActiveCravingRescueScreen(
        isSpanish: true,
        tool: RescueTool.slowBreathing,
        elapsedSeconds: 0,
        isPaused: true,
        voiceEnabled: false,
        hapticsEnabled: false,
        onElapsedChanged: (_) {},
        onPausedChanged: (_) {},
        onVoiceChanged: (_) {},
        onHapticsChanged: (_) {},
        onClose: () {},
        onComplete: () {},
        onSwitchTool: () {},
        onOpenSupport: () {},
      ),
      'stress reset': GuidedStressResetScreen(
        isSpanish: true,
        step: StressResetStep.breathe,
        stepElapsedSeconds: 0,
        totalElapsedSeconds: 0,
        isPaused: true,
        voiceGuidanceEnabled: false,
        reducedMotionEnabled: true,
        onProgressChanged: _ignoreProgress,
        onPausedChanged: (_) {},
        onVoiceGuidanceChanged: (_) {},
        onReducedMotionChanged: (_) {},
        onClose: () {},
        onComplete: () {},
        onOpenRescue: () {},
      ),
    };
    for (final entry in screens.entries) {
      await tester.pumpWidget(_app(const Locale('en'), entry.value));
      final error = tester.takeException();
      expect(
          '$error', contains('the screen language must match the app locale'),
          reason: entry.key);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
