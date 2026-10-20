import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/platform/native_app_service.dart';
import 'core/services/usage_monitor_service.dart';
import 'features/settings/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize platform channel listeners
  NativeAppService.initialize();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Start usage monitor background ticking
  UsageMonitorService.instance.start();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const EzzeBreakApp(),
    ),
  );
}
