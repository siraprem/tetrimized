import 'package:flutter_test/flutter_test.dart';
import 'package:tetr_io_wrapper/main.dart';

void main() {
  testWidgets('Smoke test: App launches without crashing', (WidgetTester tester) async {
    // Inicializa o app e renderiza o primeiro frame
    await tester.pumpWidget(const TetrIoApp());

    // Confirma que o app inicializou o widget principal
    expect(find.byType(TetrIoApp), findsOneWidget);
  });
}
