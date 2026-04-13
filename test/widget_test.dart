import 'package:flutter_test/flutter_test.dart';
import 'package:tetr_io_wrapper/main.dart';

void main() {
  testWidgets('Smoke test: App launches and shows Optimize button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TetrIoApp());

    // Verify that the optimize button is present
    expect(find.text('Otimizar'), findsOneWidget);
  });
}
