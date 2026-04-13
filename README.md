# Tetrimized - Tetr.io Mobile Wrapper

A Flutter-based mobile application wrapper for the popular online Tetris game [Tetr.io](https://tetr.io). This project provides a native mobile experience for playing Tetr.io on iOS and Android devices.

## 🎮 Features

- **Native Mobile Experience**: Play Tetr.io on your mobile device with a responsive interface
- **Cross-Platform**: Built with Flutter for iOS and Android support
- **WebView Integration**: Uses Flutter's WebView to render the Tetr.io web interface
- **Mobile Optimizations**: Touch controls and mobile-friendly UI adaptations

## 📱 Supported Platforms

- **Android**: Minimum SDK 21 (Android 5.0+)
- **iOS**: iOS 11.0+
- **Web**: Progressive Web App support
- **Desktop**: Windows, macOS, and Linux (via Flutter desktop)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Android Studio / Xcode for platform-specific builds
- Git for version control

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/siraprem/tetrimized.git
   cd tetrimized
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For Android
   flutter run -d android
   
   # For iOS
   flutter run -d ios
   
   # For web
   flutter run -d chrome
   ```

### Building

```bash
# Build APK for Android
flutter build apk

# Build App Bundle for Android
flutter build appbundle

# Build for iOS
flutter build ios

# Build for web
flutter build web
```

## 🏗️ Project Structure

```
tetrimized/
├── android/          # Android-specific files
├── ios/             # iOS-specific files
├── lib/             # Dart application code
│   └── main.dart    # Main application entry point
├── web/             # Web-specific files
├── windows/         # Windows desktop support
├── macos/           # macOS desktop support
├── linux/           # Linux desktop support
├── pubspec.yaml     # Flutter dependencies
└── README.md        # This file
```

## 🔧 Technical Details

- **Framework**: Flutter 3.0+
- **WebView**: `webview_flutter` package for rendering Tetr.io
- **State Management**: Provider pattern
- **Platform Channels**: For native platform integrations
- **Responsive Design**: Adaptive layout for different screen sizes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For issues, questions, or suggestions:
- Open an [Issue](https://github.com/siraprem/tetrimized/issues)
- Check the [Discussions](https://github.com/siraprem/tetrimized/discussions)

## 🙏 Acknowledgments

- [Tetr.io](https://tetr.io) - The amazing online Tetris game
- [Flutter](https://flutter.dev) - The cross-platform UI toolkit
- All contributors and testers

---

**Note**: This is an unofficial wrapper application. Tetr.io is owned by its respective creators. This project is not affiliated with or endorsed by the Tetr.io development team.
