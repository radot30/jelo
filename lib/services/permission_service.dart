import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestAllAppPermissions() async {
    try {
      await [
        Permission.location,
        Permission.locationWhenInUse,
        Permission.notification,
        Permission.camera,
        Permission.photos,
        Permission.storage,
      ].request();
    } catch (_) {
      // Ignore exception if permission dialog is dismissed
    }
  }
}
