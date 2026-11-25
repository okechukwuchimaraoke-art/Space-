import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:space/features/welcome/welcome_screen.dart';

void main() {
  testWidgets('Welcome screen shows brand and actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(find.text('SPACE'), findsOneWidget);
    expect(find.text('Beyond Messaging.'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
