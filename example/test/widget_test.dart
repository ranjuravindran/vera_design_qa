import 'package:design_qa_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home screen renders and navigates to the broken screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('This screen is clean'), findsOneWidget);

    await tester.tap(find.text('Open the broken screen'));
    await tester.pumpAndSettle();

    expect(find.text('This heading is off-scale'), findsOneWidget);
  });
}
