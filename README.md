# app_voice_ai

voice ai agent（仅保留 Android 版本）

## Offline Speech

This project now uses Vosk offline speech recognition on Android.

The app uses the Chinese small model by default:
- `vosk-model-small-cn-0.22.zip`

If the model file is not bundled, the app auto-downloads it on first run.
To bundle it in the APK, place the zip in `assets/models/`.

If you change the filename, update the path in `lib/services/speech_to_text.dart`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
