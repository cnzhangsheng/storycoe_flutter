import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storybird_flutter/services/api_service.dart';

/// User settings state
class UserSettings {
  final String speedLabel;
  final String accent;
  final bool loopEnabled;

  const UserSettings({
    this.speedLabel = '中',
    this.accent = 'US',
    this.loopEnabled = false,
  });

  UserSettings copyWith({
    String? speedLabel,
    String? accent,
    bool? loopEnabled,
  }) {
    return UserSettings(
      speedLabel: speedLabel ?? this.speedLabel,
      accent: accent ?? this.accent,
      loopEnabled: loopEnabled ?? this.loopEnabled,
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      speedLabel: json['speed_label'] as String? ?? '中',
      accent: json['accent'] as String? ?? 'US',
      loopEnabled: json['loop_enabled'] as bool? ?? false,
    );
  }
}

/// User settings notifier
class UserSettingsNotifier extends StateNotifier<UserSettings> {
  UserSettingsNotifier() : super(const UserSettings()) {
    // Load settings on init
    loadSettings();
  }

  /// Load settings from API
  Future<void> loadSettings() async {
    try {
      final response = await usersApi.getSettings();
      state = UserSettings.fromJson(response);
    } catch (e) {
      // Use defaults if API fails
    }
  }

  /// Set speed
  Future<void> setSpeed(String speed) async {
    final oldState = state;
    state = state.copyWith(speedLabel: speed);
    try {
      await usersApi.updateSettings(speedLabel: speed);
    } catch (e) {
      // Revert on failure
      state = oldState;
    }
  }

  /// Set accent
  Future<void> setAccent(String accent) async {
    final oldState = state;
    state = state.copyWith(accent: accent);
    try {
      await usersApi.updateSettings(accent: accent);
    } catch (e) {
      // Revert on failure
      state = oldState;
    }
  }

  /// Toggle loop
  Future<void> toggleLoop() async {
    final oldState = state;
    state = state.copyWith(loopEnabled: !state.loopEnabled);
    try {
      await usersApi.updateSettings(loopEnabled: state.loopEnabled);
    } catch (e) {
      // Revert on failure
      state = oldState;
    }
  }
}

/// User settings provider
final userSettingsProvider =
    StateNotifierProvider<UserSettingsNotifier, UserSettings>((ref) {
  return UserSettingsNotifier();
});