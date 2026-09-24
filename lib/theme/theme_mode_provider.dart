import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kThemeModeKey = 'theme_mode';
const _storage = FlutterSecureStorage();

enum AppThemeMode { light, dark, system }

// ── Theme mode provider ──────────────────────────────────────────────────────

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends AsyncNotifier<AppThemeMode> {
  @override
  Future<AppThemeMode> build() async {
    final value = await _storage.read(key: _kThemeModeKey);
    return switch (value) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  Future<void> save(AppThemeMode mode) async {
    final key = switch (mode) {
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
      AppThemeMode.system => 'system',
    };
    await _storage.write(key: _kThemeModeKey, value: key);
    state = AsyncData(mode);
  }
}