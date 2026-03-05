import 'package:flutter_test/flutter_test.dart';
import 'package:lpu_touch/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LpuTouchApp());
    expect(find.byType(LpuTouchApp), findsOneWidget);
  });
}
