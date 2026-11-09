# Disclaimer (English Version)

Note: This document was translated from the original Portuguese README using AI tools. As English is not my native language, some nuances or specific expressions may be lost in translation or might not perfectly reflect my original intent. Please keep this in mind while reading!

# Tetrimized - A Mobile Wrapper for Tetr.io

A mobile app built with Flutter to play Tetr.io on your phone. Basically, it's a wrapper that runs the Tetr.io website inside a WebView, but with some adaptations to make it more mobile-friendly.

## What is this?

You know Tetr.io, that online Tetris game everyone plays in the browser? Well, this project is an attempt to make a mobile app to play it in a more native way on your phone.

## Features

- Runs Tetr.io directly on your phone
- Touch-adapted interface (better than opening in a browser)
- Customizable button opacity (so they don't block the game)
- Quick menu to hide/show UI
- Integrated 'R' key for quick reset

## Which version to download?

The `master`, `bleeding-edge`, and `stability-pro` branches have different histories. See releases for distributed versions; no relative performance is guaranteed between branches.

### How to Download
To download the application, visit our releases page:

**[Click here to see all versions (Releases)](https://github.com/siraprem/tetrimized/releases)**

**Golden tip:** Use common sense. If there's version 1.1.2 and 1.1.0, 1.1.2 is LOGICALLY newer. Choose between Pro or Turbo and be happy.

## How to run and build

### Prerequisites
- Flutter SDK compatible with Dart `^3.11.4`, as declared in `pubspec.yaml`
- Android Studio or Xcode
- Git (obviously)

### Step by step
1. **Clone the code**
   ```bash
   git clone https://github.com/siraprem/tetrimized.git
   cd tetrimized
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Build the APK (Android)**
   ```bash
   # Generate APK for direct installation
   flutter build apk --release

   # If uploading somewhere, generate the bundle
   flutter build appbundle
   ```

## Project Structure

Historical reports and instructions are preserved in [`docs/archive/`](docs/archive/). They document past experiments and do not prove performance gains.

```
tetrimized/
├── android/          # Android-specific stuff
├── lib/             # Main Dart code (Where the magic happens)
├── pubspec.yaml     # Flutter dependencies
└── README.md        # This file here
```

## License

**MIT** - basically you can do whatever you want with the code, just don't sue me if something goes wrong. I recommend reading the LICENSE.md though.

## Note about ads and performance

TETR.IO displays ads, and since the app is a wrapper, they appear. If you want to filter them, use a private DNS (like `dns.adguard.com`) in your Android settings. But hey, osk (the game's developer) needs this to keep the servers running, so if you can, support him on the official site!

## AI-Augmented Development

Tetrimized uses an AI-Augmented Development workflow. This allows me, as a student, to focus on architecture and user experience, while using advanced language models to optimize implementation and accelerate bug resolution.

## Legal Notice

**This is an unofficial project.** Tetr.io belongs to its original creators. This app has no affiliation with the Tetr.io team, it's just a wrapper made by a fan for fans. Please don't strike me, I love the game.
