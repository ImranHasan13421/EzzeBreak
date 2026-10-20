import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class NativeAppService {
  static const MethodChannel _channel = MethodChannel(AppConstants.channelName);

  static Function(String packageName)? onForegroundAppChanged;
  static Function(String action, String packageName)? onPendingActionReceived;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onForegroundAppChanged':
          final args = call.arguments as Map?;
          final pkg = args?['packageName'] as String?;
          if (pkg != null && onForegroundAppChanged != null) {
            onForegroundAppChanged!(pkg);
          }
          break;
        case 'onPendingAction':
          final args = call.arguments as Map?;
          final action = args?['action'] as String?;
          final pkg = args?['packageName'] as String?;
          if (action != null && onPendingActionReceived != null) {
            onPendingActionReceived!(action, pkg ?? '');
          }
          break;
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Error getting installed apps: $e');
      return [];
    }
  }

  static Future<bool> checkUsagePermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('checkUsagePermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (e) {
      debugPrint('Error opening usage settings: $e');
    }
  }

  static Future<bool> checkOverlayPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('checkOverlayPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } catch (e) {
      debugPrint('Error opening overlay settings: $e');
    }
  }

  static Future<bool> checkAccessibilityPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('checkAccessibilityPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      debugPrint('Error opening accessibility settings: $e');
    }
  }

  static Future<bool> checkNotificationPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('checkNotificationPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('Error opening notification settings: $e');
    }
  }

  static Future<void> updateRestrictions(Map<String, String> restrictions) async {
    try {
      await _channel.invokeMethod('updateRestrictions', {'restrictions': restrictions});
    } catch (e) {
      debugPrint('Error updating restrictions: $e');
    }
  }

  static Future<void> triggerRestriction(String packageName, String reason) async {
    try {
      await _channel.invokeMethod('triggerRestriction', {
        'packageName': packageName,
        'reason': reason,
      });
    } catch (e) {
      debugPrint('Error triggering restriction: $e');
    }
  }

  static Future<Map<String, int>> getUsageStats(int startTime, int endTime) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getUsageStats', {
        'startTime': startTime,
        'endTime': endTime,
      });
      if (result == null) return {};
      return result.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    } catch (e) {
      debugPrint('Error getting usage stats: $e');
      return {};
    }
  }

  static Future<String?> savePdfToDownloads(String fileName, Uint8List bytes) async {
    try {
      final path = await _channel.invokeMethod<String>('savePdfToDownloads', {
        'fileName': fileName,
        'bytes': bytes,
      });
      return path;
    } catch (e) {
      debugPrint('Error saving PDF to Downloads: $e');
      return null;
    }
  }

  static Future<bool> openFile(String filePath) async {
    try {
      final res = await _channel.invokeMethod<bool>('openFile', {'filePath': filePath});
      return res ?? false;
    } catch (e) {
      debugPrint('Error opening file: $e');
      return false;
    }
  }

  static Future<Map<String, String>?> getPendingAction() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('getPendingAction');
      if (res == null) return null;
      return res.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return null;
    }
  }
}
