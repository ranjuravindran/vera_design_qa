import 'package:design_qa_companion/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the project picker on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const CompanionApp());
    expect(find.text('Design QA'), findsOneWidget);
    expect(find.text('Choose app folder'), findsOneWidget);
  });
}
