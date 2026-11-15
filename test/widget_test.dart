import 'package:flutter_test/flutter_test.dart';
import 'package:sikhun_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SikhunApp());
    expect(find.byType(SikhunApp), findsOneWidget);
  });
}
