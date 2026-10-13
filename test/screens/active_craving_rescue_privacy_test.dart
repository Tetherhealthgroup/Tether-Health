import 'package:breathefree_patient/screens/active_craving_rescue_screen.dart';
import 'package:breathefree_patient/screens/recommended_rescue_tool_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _syntheticDetail = 'SYNTHETIC-TTS-DETAIL-4821';
const _ttsChannel = MethodChannel('flutter_tts');

void _installThrowingTtsChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_ttsChannel, (call) async {
    throw PlatformException(code: 'synthetic', message: _syntheticDetail);
  });
}

void _clearTtsChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_ttsChannel, null);
}

Widget _screen({
  required RescueTool tool,
  required int elapsedSeconds,
  required bool isPaused,
  required bool voiceEnabled,
}) {
  return MaterialApp(
    home: ActiveCravingRescueScreen(
      isSpanish: false,
      tool: tool,
      elapsedSeconds: elapsedSeconds,
      isPaused: isPaused,
      voiceEnabled: voiceEnabled,
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
  );
}

void main() {
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('TTS configure failure logs only source and type', (
    tester,
  ) async {
    useTallViewport(tester);
    _installThrowingTtsChannel();
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message ?? '');
    try {
      await tester.pumpWidget(_screen(
        tool: RescueTool.slowBreathing,
        elapsedSeconds: 0,
        isPaused: true,
        voiceEnabled: false,
      ));
      await tester.pump();

      expect(
        logs,
        contains(
            'BreatheFree technical error: tts_configure/PlatformException'),
      );
      expect(logs.where((l) => l.contains(_syntheticDetail)), isEmpty);
      await tester.pumpWidget(const SizedBox());
    } finally {
      debugPrint = original;
      _clearTtsChannel();
    }
  });

  testWidgets('TTS movement cue failure logs only source and type', (
    tester,
  ) async {
    useTallViewport(tester);
    _installThrowingTtsChannel();
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message ?? '');
    try {
      await tester.pumpWidget(_screen(
        tool: RescueTool.move,
        elapsedSeconds: 29,
        isPaused: false,
        voiceEnabled: true,
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(
        logs,
        contains(
            'BreatheFree technical error: tts_movement_cue/PlatformException'),
      );
      expect(logs.where((l) => l.contains(_syntheticDetail)), isEmpty);
      await tester.pumpWidget(const SizedBox());
    } finally {
      debugPrint = original;
      _clearTtsChannel();
    }
  });
}
