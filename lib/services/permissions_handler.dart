import 'package:permission_handler/permission_handler.dart';

class PermissionsHandler {
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> checkAllPermissions() async {
    final micGranted = await Permission.microphone.isGranted;
    final storageGranted = await Permission.storage.isGranted;

    return micGranted && storageGranted;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}