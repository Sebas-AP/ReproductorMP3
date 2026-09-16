import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reproductor_musica/core/constants/app_constants.dart';
import 'package:reproductor_musica/core/themes/app_theme.dart';
import 'package:reproductor_musica/domain/entities/media.dart';

class ThemeNotifier extends StateNotifier<ThemeData> {
  final SharedPreferences? _prefs;
  UserTheme _userTheme;
  bool _useDynamicColors = true;
  DynamicColors? _currentDynamicColors;

  ThemeNotifier(this._prefs, this._userTheme) : super(_userTheme.toThemeData()) {
    if (_prefs != null) {
      _loadSettings();
    }
  }

  UserTheme get userTheme => _userTheme;
  bool get useDynamicColors => _useDynamicColors;
  DynamicColors? get currentDynamicColors => _currentDynamicColors;

  Future<void> _loadSettings() async {
    final prefs = _prefs;
    if (prefs == null) return;
    _userTheme = _userTheme.copyWith(
      primaryColorValue: prefs.getInt(AppConstants.prefsPrimaryColor) ?? _userTheme.primaryColorValue,
      secondaryColorValue: prefs.getInt(AppConstants.prefsSecondaryColor) ?? _userTheme.secondaryColorValue,
      blurIntensity: prefs.getDouble(AppConstants.prefsBlurIntensity) ?? _userTheme.blurIntensity,
      surfaceOpacity: prefs.getDouble(AppConstants.prefsSurfaceOpacity) ?? _userTheme.surfaceOpacity,
      borderRadius: prefs.getDouble(AppConstants.prefsBorderRadius) ?? _userTheme.borderRadius,
      dynamicColors: prefs.getBool(AppConstants.prefsDynamicColors) ?? _userTheme.dynamicColors,
      isDark: prefs.getBool(AppConstants.prefsThemeMode) ?? _userTheme.isDark,
    );
    _useDynamicColors = _userTheme.dynamicColors;
    state = _userTheme.toThemeData();
  }

  Future<void> setThemeMode(bool isDark) async {
    _userTheme = _userTheme.copyWith(isDark: isDark);
    await _prefs?.setBool(AppConstants.prefsThemeMode, isDark);
    state = _userTheme.toThemeData();
  }

  Future<void> setPrimaryColor(Color color) async {
    _userTheme = _userTheme.copyWith(primaryColorValue: color.value);
    await _prefs?.setInt(AppConstants.prefsPrimaryColor, color.value);
    state = _userTheme.toThemeData();
  }

  Future<void> setSecondaryColor(Color color) async {
    _userTheme = _userTheme.copyWith(secondaryColorValue: color.value);
    await _prefs?.setInt(AppConstants.prefsSecondaryColor, color.value);
    state = _userTheme.toThemeData();
  }

  Future<void> setBlurIntensity(double intensity) async {
    _userTheme = _userTheme.copyWith(blurIntensity: intensity.clamp(0, 30));
    await _prefs?.setDouble(AppConstants.prefsBlurIntensity, _userTheme.blurIntensity);
    state = _userTheme.toThemeData();
  }

  Future<void> setSurfaceOpacity(double opacity) async {
    _userTheme = _userTheme.copyWith(surfaceOpacity: opacity.clamp(0.05, 0.9));
    await _prefs?.setDouble(AppConstants.prefsSurfaceOpacity, _userTheme.surfaceOpacity);
    state = _userTheme.toThemeData();
  }

  Future<void> setBorderRadius(double radius) async {
    _userTheme = _userTheme.copyWith(borderRadius: radius.clamp(0, 32));
    await _prefs?.setDouble(AppConstants.prefsBorderRadius, _userTheme.borderRadius);
    state = _userTheme.toThemeData();
  }

  Future<void> setDynamicColors(bool enabled) async {
    _useDynamicColors = enabled;
    _userTheme = _userTheme.copyWith(dynamicColors: enabled);
    await _prefs?.setBool(AppConstants.prefsDynamicColors, enabled);
    state = _userTheme.toThemeData();
  }

  Future<void> setFontFamily(String? fontFamily) async {
    _userTheme = _userTheme.copyWith(fontFamily: fontFamily);
    state = _userTheme.toThemeData();
  }

  void updateDynamicColors(DynamicColors colors) {
    _currentDynamicColors = colors;
  }

  Future<void> saveAsPreset(String name) async {
    // TODO: Save to database as UserTheme entity
  }

  Future<void> loadPreset(UserTheme theme) async {
    _userTheme = theme;
    await _prefs?.setInt(AppConstants.prefsPrimaryColor, theme.primaryColorValue);
    await _prefs?.setInt(AppConstants.prefsSecondaryColor, theme.secondaryColorValue);
    await _prefs?.setDouble(AppConstants.prefsBlurIntensity, theme.blurIntensity);
    await _prefs?.setDouble(AppConstants.prefsSurfaceOpacity, theme.surfaceOpacity);
    await _prefs?.setDouble(AppConstants.prefsBorderRadius, theme.borderRadius);
    await _prefs?.setBool(AppConstants.prefsDynamicColors, theme.dynamicColors);
    await _prefs?.setBool(AppConstants.prefsThemeMode, theme.isDark);
    state = _userTheme.toThemeData();
  }

  Future<void> resetToDefaults() async {
    _userTheme = const UserTheme(
      name: 'Default',
      primaryColorValue: 0xFF6366F1,
      secondaryColorValue: 0xFF8B5CF6,
    );
    await _prefs?.remove(AppConstants.prefsPrimaryColor);
    await _prefs?.remove(AppConstants.prefsSecondaryColor);
    await _prefs?.remove(AppConstants.prefsBlurIntensity);
    await _prefs?.remove(AppConstants.prefsSurfaceOpacity);
    await _prefs?.remove(AppConstants.prefsBorderRadius);
    await _prefs?.remove(AppConstants.prefsDynamicColors);
    await _prefs?.remove(AppConstants.prefsThemeMode);
    state = _userTheme.toThemeData();
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    return ThemeNotifier(
      null,
      const UserTheme(
        name: 'Default',
        primaryColorValue: 0xFF6366F1,
        secondaryColorValue: 0xFF8B5CF6,
      ),
    );
  }
  return ThemeNotifier(
    prefs,
    UserTheme(
      name: 'Custom',
      primaryColorValue: prefs.getInt(AppConstants.prefsPrimaryColor) ?? 0xFF6366F1,
      secondaryColorValue: prefs.getInt(AppConstants.prefsSecondaryColor) ?? 0xFF8B5CF6,
      blurIntensity: prefs.getDouble(AppConstants.prefsBlurIntensity) ?? AppTheme.defaultBlurIntensity,
      surfaceOpacity: prefs.getDouble(AppConstants.prefsSurfaceOpacity) ?? AppTheme.defaultSurfaceOpacity,
      borderRadius: prefs.getDouble(AppConstants.prefsBorderRadius) ?? AppTheme.defaultBorderRadius,
      dynamicColors: prefs.getBool(AppConstants.prefsDynamicColors) ?? true,
      isDark: prefs.getBool(AppConstants.prefsThemeMode) ?? false,
    ),
  );
});