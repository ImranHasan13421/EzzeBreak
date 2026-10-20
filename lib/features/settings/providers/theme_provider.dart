import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_loadTheme(_prefs));

  static ThemeMode _loadTheme(SharedPreferences prefs) {
    final raw = prefs.getString(AppConstants.keyThemeMode);
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    String val = 'system';
    if (mode == ThemeMode.dark) val = 'dark';
    if (mode == ThemeMode.light) val = 'light';
    await _prefs.setString(AppConstants.keyThemeMode, val);
  }
}

final profileNameProvider = StateNotifierProvider<ProfileNameNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileNameNotifier(prefs);
});

class ProfileNameNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  ProfileNameNotifier(this._prefs)
      : super(_prefs.getString(AppConstants.keyDisplayName) ?? '');

  Future<void> setName(String name) async {
    state = name.trim();
    await _prefs.setString(AppConstants.keyDisplayName, state);
  }
}

final onboardingCompletedProvider = StateNotifierProvider<OnboardingCompletedNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingCompletedNotifier(prefs);
});

class OnboardingCompletedNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  OnboardingCompletedNotifier(this._prefs)
      : super(_prefs.getBool(AppConstants.keyOnboardingCompleted) ?? false);

  Future<void> completeOnboarding() async {
    state = true;
    await _prefs.setBool(AppConstants.keyOnboardingCompleted, true);
  }

  Future<void> resetOnboarding() async {
    state = false;
    await _prefs.setBool(AppConstants.keyOnboardingCompleted, false);
  }
}
