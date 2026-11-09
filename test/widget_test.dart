import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tetr_io_wrapper/main.dart';

void main() {
  testWidgets('Smoke test: App launches without crashing', (
    WidgetTester tester,
  ) async {
    InAppWebViewPlatform.instance = _FakeInAppWebViewPlatform();

    await tester.pumpWidget(const TetrIoApp());

    expect(find.byType(TetrIoApp), findsOneWidget);
  });
}

class _FakeInAppWebViewPlatform extends InAppWebViewPlatform {
  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) => _FakeInAppWebViewWidget(params);
}

class _FakeInAppWebViewWidget extends PlatformInAppWebViewWidget {
  // The platform interface exposes this as a named implementation constructor.
  // ignore: use_super_parameters
  _FakeInAppWebViewWidget(PlatformInAppWebViewWidgetCreationParams params)
    : super.implementation(params);

  @override
  Widget build(BuildContext context) => const SizedBox.expand();

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      throw UnimplementedError(
        'The smoke test does not use a WebView controller.',
      );

  @override
  void dispose() {}
}
