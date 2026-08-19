import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muyo_mobprog/main.dart';

void main() {
  testWidgets('shows product search screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RoblesAdvMobProg());

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search products'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
