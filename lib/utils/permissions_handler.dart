// permissions_handler.dart
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

  // 修复：添加一个静态方法来打开应用设置
  static Future<void> openSystemSettings() async {
    await openAppSettings();
  }
}