# Local Android fork: `flutter_inappwebview_android` 1.1.3

This is the upstream Android implementation from `flutter_inappwebview_android` 1.1.3, vendored under its original Apache-2.0 license (see `LICENSE`). It is selected through the root `pubspec.yaml` dependency override.

## Local patch

`TetrimizedAdRequestBlocker` performs an exact-host check in Android's native `shouldInterceptRequest` path and returns an empty local response before a matching ad request reaches the network. It is enabled only when `regexToCancelSubFramesLoading` equals the Tetrimized ad rule configured in `lib/main.dart`; setting `TETRIMIZED_ADBLOCK=false` disables it. The same regex cancels matching subframe navigations.

The patch intentionally does not use Flutter/Dart callbacks, polling, observers, remote lists, or services. Do not replace it with the upstream Android `ContentBlocker` for this app: upstream's resource-type detection may make a synchronous HTTP `HEAD` request for each intercepted URL.

When upgrading the upstream plugin, reapply and re-test the patch in both `InAppWebViewClient` and `InAppWebViewClientCompat`.
