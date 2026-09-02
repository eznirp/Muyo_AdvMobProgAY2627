import 'package:flutter_test/flutter_test.dart';

import 'package:muyo_mobprog/main.dart';
import 'package:muyo_mobprog/screens/splash_screen.dart';

void main() {
  testWidgets('starts behind the authentication gate', (WidgetTester tester) async {
    await tester.pumpWidget(const RoblesAdvMobProg());
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
