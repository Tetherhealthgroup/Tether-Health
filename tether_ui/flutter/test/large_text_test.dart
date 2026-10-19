// GENERATED — unit fields at 200% text. On every screen with a unit field
// (mmHg, mg/dL, %...) the unit must be visible while the field is empty, the
// example hint must not be cut, and a typed value of the example's length
// must fit in full next to its unit. Text is measured with Roboto from the
// Flutter SDK (the test font draws every glyph 1 em wide).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

const _cases = <(String, String, List<(String, String, String)>)>[
  ('ca_plan', Routes.caPlan, [('ca_plan.green_from', 'L/min', '400'), ('ca_plan.peak_flow', 'L/min', '200–399'), ('ca_plan.red_below', 'L/min', '200')]),
  ('ca_zone', Routes.caZone, [('ca_zone.peak_flow', 'L/min', '310')]),
  ('hw_targets', Routes.hwTargets, [('hw_targets.top_below', 'mmHg', '130'), ('hw_targets.bottom_below', 'mmHg', '80')]),
  ('hw_log', Routes.hwLog, [('hw_log.systolic', 'mmHg', '138'), ('hw_log.diastolic', 'mmHg', '86'), ('hw_log.pulse_optional', 'bpm', '72')]),
  ('hw_log2', Routes.hwLog2, [('hw_log2.systolic', 'mmHg', '132'), ('hw_log2.diastolic', 'mmHg', '84'), ('hw_log2.pulse_optional', 'bpm', '70')]),
  ('hw_log_error', Routes.hwLogError, [('hw_log_error.top_systolic', 'mmHg', '128'), ('hw_log_error.bottom_diastolic', 'mmHg', '310')]),
  ('hw_lipids', Routes.hwLipids, [('hw_lipids.total', 'mg/dL', '212'), ('hw_lipids.ldl', 'mg/dL', '138'), ('hw_lipids.hdl', 'mg/dL', '46'), ('hw_lipids.triglycerides', 'mg/dL', 'Optional')]),
  ('st_range', Routes.stRange, [('st_range.before_meals_from', 'mg/dL', '80'), ('st_range.to', 'mg/dL', '130'), ('st_range.2_h_after_meals_below', 'mg/dL', '180'), ('st_range.low', 'mg/dL', '70')]),
  ('st_log', Routes.stLog, [('st_log.reading', 'mg/dL', '142')]),
  ('st_a1c', Routes.stA1c, [('st_a1c.a1c', '%', '7.4')]),
  ('re_labs', Routes.reLabs, [('re_labs.egfr', 'mL/min/1.73m²', '58'), ('re_labs.urine_acr', 'mg/g', '42'), ('re_labs.alt_liver', 'U/L', 'Optional')]),
  ('records_manual', Routes.recordsManual, [('records_manual.value', '%', '7.4')]),
  ('records_manual_error', Routes.recordsManualError, [('records_manual_error.value', '%', '74')]),
];

/// The unit's text exists inside [field] and no ancestor fades it out.
void _expectUnitVisible(WidgetTester tester, Finder field, String unit, String state) {
  final f = find.descendant(of: field, matching: find.text(unit));
  expect(f, findsOneWidget, reason: 'unit "$unit" missing ($state)');
  RenderObject? r = tester.renderObject(f);
  final stop = tester.renderObject(field);
  while (r != null && r != stop) {
    if (r is RenderOpacity) expect(r.opacity, greaterThan(0), reason: 'unit "$unit" hidden ($state)');
    if (r is RenderAnimatedOpacity) expect(r.opacity.value, greaterThan(0), reason: 'unit "$unit" hidden ($state)');
    r = r.parent;
  }
}

Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  expect(root, isNotNull, reason: 'FLUTTER_ROOT is not set; run with flutter test');
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    final file = File('$root/bin/cache/artifacts/material_fonts/Roboto-$w.ttf');
    expect(file.existsSync(), isTrue, reason: '${file.path} is missing (flutter precache)');
    loader.addFont(Future.value(ByteData.view(Uint8List.fromList(file.readAsBytesSync()).buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadRoboto);
  for (final c in _cases) {
    testWidgets('200% text · ${c.$1}', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      TSession.clear();
      await tester.pumpWidget(MaterialApp(
        theme: tetherTheme(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        onGenerateInitialRoutes: (_) => [AppRouter.onGenerateRoute(RouteSettings(name: c.$2))!],
      ));
      await tester.pump(const Duration(milliseconds: 400));
      for (final (key, unit, example) in c.$3) {
        final field = find.byKey(ValueKey('field:$key'));
        expect(field, findsOneWidget, reason: 'field $key');
        await tester.ensureVisible(field);
        await tester.pump();
        _expectUnitVisible(tester, field, unit, '$key empty');
        if (example.isNotEmpty) {
          final hint = tester.renderObject<RenderParagraph>(find.descendant(of: field, matching: find.text(example)));
          expect(hint.didExceedMaxLines, isFalse, reason: '$key: hint "$example" is cut at 200% text');
        }
        final value = example.contains(RegExp(r'\d')) ? example : '123';
        await tester.enterText(field, value);
        await tester.pump(const Duration(milliseconds: 300));
        _expectUnitVisible(tester, field, unit, '$key with "$value"');
        final editable = tester.state<EditableTextState>(find.descendant(of: field, matching: find.byType(EditableText))).renderEditable;
        expect(editable.getMaxIntrinsicWidth(double.infinity), lessThanOrEqualTo(editable.size.width + 0.5),
            reason: '$key: "$value" does not fit at 200% text (needs ${editable.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}, has ${editable.size.width.toStringAsFixed(1)})');
      }
      expect(tester.takeException(), isNull);
    });
  }
}
