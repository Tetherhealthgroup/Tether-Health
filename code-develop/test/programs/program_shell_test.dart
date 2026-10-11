import 'package:breathefree_patient/programs/program.dart';
import 'package:breathefree_patient/programs/widgets/program_home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder byLabel(String label) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties?.label == label,
    );

Widget buildShell({
  bool isLoading = false,
  String? errorMessage,
  VoidCallback? onRetry,
  List<Widget> children = const [Text('content')],
}) {
  return MaterialApp(
    home: ProgramHomeShell(
      spec: programSpecs[ProgramId.heartwise]!,
      title: 'Heartwise',
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRetry: onRetry ?? () {},
      children: children,
    ),
  );
}

void main() {
  testWidgets('shows the loading state', (tester) async {
    await tester.pumpWidget(buildShell(isLoading: true));

    expect(byLabel('Loading'), findsOneWidget);
    expect(find.text('content'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the error state with retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      buildShell(
        errorMessage: 'Something went wrong.',
        onRetry: () => retried = true,
      ),
    );

    expect(find.text('Something went wrong.'), findsOneWidget);
    await tester.tap(byLabel('Try again'));
    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows offline notice, privacy footer, and disclaimer',
      (tester) async {
    await tester.pumpWidget(buildShell());

    expect(find.text('content'), findsOneWidget);
    expect(find.text(ProgramCopy.offlineNotice), findsOneWidget);
    expect(find.text(ProgramCopy.privacyFooter), findsOneWidget);
    expect(find.text(ProgramCopy.disclaimer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
