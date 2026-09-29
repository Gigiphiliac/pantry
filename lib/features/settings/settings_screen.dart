import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/theme/theme_mode_provider.dart';
import 'package:pantry/widgets/app_bar_logo.dart';

const _storage = FlutterSecureStorage();
const _kUnitPrefKey = 'unit_preference';

// ── Unit preference ───────────────────────────────────────────────────────────

final unitPreferenceProvider =
    AsyncNotifierProvider<UnitPreferenceNotifier, UnitPreference>(
      UnitPreferenceNotifier.new,
    );

class UnitPreferenceNotifier extends AsyncNotifier<UnitPreference> {
  @override
  Future<UnitPreference> build() async {
    final value = await _storage.read(key: _kUnitPrefKey);
    return value == 'imperial'
        ? UnitPreference.imperial
        : UnitPreference.metric;
  }

  Future<void> save(UnitPreference pref) async {
    await _storage.write(
      key: _kUnitPrefKey,
      value: pref == UnitPreference.imperial ? 'imperial' : 'metric',
    );
    state = AsyncData(pref);
  }
}

// ── Settings screen ───────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBarLogo(),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Units ─────────────────────────────────────────────────
          Text('Units', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Choose whether quantities are displayed in metric or imperial.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ref
              .watch(unitPreferenceProvider)
              .when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('Error: $e'),
                data: (pref) => SegmentedButton<UnitPreference>(
                  segments: const [
                    ButtonSegment(
                      value: UnitPreference.metric,
                      label: Text('Metric'),
                    ),
                    ButtonSegment(
                      value: UnitPreference.imperial,
                      label: Text('Imperial'),
                    ),
                  ],
                  selected: {pref},
                  onSelectionChanged: (set) =>
                      ref.read(unitPreferenceProvider.notifier).save(set.first),
                ),
              ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // ── Theme ─────────────────────────────────────────────────
          Text('Theme', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Choose your preferred appearance.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final showLabels = constraints.maxWidth >= 360;
              return ref
                  .watch(themeModeProvider)
                  .when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => Text('Error: $e'),
                    data: (mode) => SegmentedButton<AppThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: AppThemeMode.light,
                          label: showLabels ? const Text('Light') : null,
                          icon: const Icon(Icons.light_mode),
                        ),
                        ButtonSegment(
                          value: AppThemeMode.dark,
                          label: showLabels ? const Text('Dark') : null,
                          icon: const Icon(Icons.dark_mode),
                        ),
                        ButtonSegment(
                          value: AppThemeMode.system,
                          label: showLabels ? const Text('System') : null,
                          icon: const Icon(Icons.settings_suggest),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (set) =>
                          ref.read(themeModeProvider.notifier).save(set.first),
                    ),
                  );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
