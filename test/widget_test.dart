import 'package:flutter_test/flutter_test.dart';

import 'package:neuro_link/main.dart';

void main() {
  testWidgets('NeuroLink home loads', (WidgetTester tester) async {
    await tester.pumpWidget(const NeuroLinkApp());
    await tester.pumpAndSettle();

    expect(find.text('NeuroLink'), findsOneWidget);
    expect(find.text('Vocal Mode'), findsOneWidget);
  });
}
