import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Returns a unique device ID based on the current platform.
  static Future<String> getDeviceId() async {
    try {
      if (kIsWeb) {
        return 'web-unsupported';
      }

      if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        // Use the device ID (machine GUID) which is unique per Windows installation
        return 'WIN-${windowsInfo.deviceId}';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        // Use the system GUID which is unique per Mac
        return 'MAC-${macInfo.systemGUID ?? macInfo.computerName}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // identifierForVendor is unique per app per device
        return 'IOS-${iosInfo.identifierForVendor ?? 'unknown'}';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Android ID is unique per device per user
        return 'AND-${androidInfo.id}';
      }

      return 'UNKNOWN-${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      return 'ERROR-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
