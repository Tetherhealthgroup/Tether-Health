import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/programs/secure_program_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings switches from BreatheFree into a real program route',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(
      BreatheFreeApp(
        initialScreen: 27,
        programStore: SecureProgramStore(),
      ),
    );
    await tester.pumpAndSettle();

    final programs = find.byKey(const ValueKey('settings-programs'));
    await tester.ensureVisible(programs);
    await tester.tap(programs);
    await tester.pumpAndSettle();

    expect(find.text('Tether Health programs'), findsOneWidget);
    await tester.tap(find.text('Heartwise'));
    await tester.pumpAndSettle();

    expect(find.text('Heartwise'), findsOneWidget);
    expect(find.textContaining('smoking', findRichText: true), findsNothing);
    expect(find.byTooltip('Choose program'), findsOneWidget);
  });
}
