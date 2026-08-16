import 'package:design_qa_companion/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the project picker on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const CompanionApp());
    expect(find.image(const AssetImage('assets/icon/vera_app_display_icon.png')), findsOneWidget);
    expect(find.text('Choose app folder'), findsOneWidget);
  });
}
