import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class PermissionController {
  static const MethodChannel _channel = MethodChannel('com.myadhan/notification');

  // Request all necessary permissions for adhan notifications
  static Future<bool> requestAdhanPermissions() async {
    try {
      // Request notification permission (Android 13+)
      if (await Permission.notification.request().isGranted) {
        print('Notification permission granted');
      } else {
        print('Notification permission denied');
        return false;
      }

      // Request exact alarm permission (Android 12+)
      if (await _requestExactAlarmPermission()) {
        print('Exact alarm permission granted');
      } else {
        print('Exact alarm permission denied');
        return false;
      }

      return true;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  // Request exact alarm permission through native code
  static Future<bool> _requestExactAlarmPermission() async {
    try {
      final result = await _channel.invokeMethod('requestExactAlarmPermission');
      return result == true;
    } catch (e) {
      print('Error requesting exact alarm permission: $e');
      return false;
    }
  }

  // Check if all permissions are granted
  static Future<bool> checkAdhanPermissions() async {
    try {
      final notificationGranted = await Permission.notification.isGranted;
      final exactAlarmGranted = await _checkExactAlarmPermission();
      
      return notificationGranted && exactAlarmGranted;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  // Check exact alarm permission through native code
  static Future<bool> _checkExactAlarmPermission() async {
    try {
      final result = await _channel.invokeMethod('checkExactAlarmPermission');
      return result == true;
    } catch (e) {
      print('Error checking exact alarm permission: $e');
      return false;
    }
  }

  // Open app settings if permissions are denied
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
} 