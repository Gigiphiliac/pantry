import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/theme/theme_mode_provider.dart';
import 'package:pantry/widgets/app_bar_logo.dart';

// ── Storage keys ──────────────────────────────────────────────────────────────

const _kActiveProvider = 'llm_active_provider';
const _kOllamaHost = 'llm_ollama_host';
const _kOllamaModel = 'llm_ollama_model';
const _kOpenRouterApiKey = 'llm_openrouter_api_key';
const _kOpenRouterModel = 'llm_openrouter_model';
const _kUnitPrefKey = 'unit_preference';

const _storage = FlutterSecureStorage();

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

// ── LLM provider types ────────────────────────────────────────────────────────

enum LlmProvider { ollama, openRouter }

class LlmConfig {
  final LlmProvider provider;
  final String endpoint;
  final String apiKey;
  final String model;

  const LlmConfig({
    required this.provider,
    required this.endpoint,
    required this.apiKey,
    required this.model,
  });

  bool get isConfigured => endpoint.isNotEmpty && model.isNotEmpty;
}

class LlmProviderConfig {
  final LlmProvider active;
  final String ollamaHost;
  final String ollamaModel;
  final String openRouterApiKey;
  final String openRouterModel;

  const LlmProviderConfig({
    required this.active,
    required this.ollamaHost,
    required this.ollamaModel,
    required this.openRouterApiKey,
    required this.openRouterModel,
  });

  LlmConfig get activeLlmConfig {
    switch (active) {
      case LlmProvider.ollama:
        return LlmConfig(
          provider: LlmProvider.ollama,
          endpoint: ollamaHost.isEmpty ? '' : 'http://$ollamaHost:11434',
          apiKey: '',
          model: ollamaModel,
        );
      case LlmProvider.openRouter:
        return LlmConfig(
          provider: LlmProvider.openRouter,
          endpoint: 'https://openrouter.ai/api/v1',
          apiKey: openRouterApiKey,
          model: openRouterModel,
        );
    }
  }

  bool get isConfigured => activeLlmConfig.isConfigured;
}

// ── LLM config notifier ───────────────────────────────────────────────────────

final llmConfigProvider =
    AsyncNotifierProvider<LlmConfigNotifier, LlmProviderConfig>(
      LlmConfigNotifier.new,
    );

class LlmConfigNotifier extends AsyncNotifier<LlmProviderConfig> {
  @override
  Future<LlmProviderConfig> build() async {
    final active = await _storage.read(key: _kActiveProvider);
    return LlmProviderConfig(
      active: active == 'openrouter'
          ? LlmProvider.openRouter
          : LlmProvider.ollama,
      ollamaHost: await _storage.read(key: _kOllamaHost) ?? '',
      ollamaModel: await _storage.read(key: _kOllamaModel) ?? '',
      openRouterApiKey: await _storage.read(key: _kOpenRouterApiKey) ?? '',
      openRouterModel: await _storage.read(key: _kOpenRouterModel) ?? '',
    );
  }

  Future<void> saveOllama({required String host, required String model}) async {
    await Future.wait([
      _storage.write(key: _kOllamaHost, value: host),
      _storage.write(key: _kOllamaModel, value: model),
      _storage.write(key: _kActiveProvider, value: 'ollama'),
    ]);
    final current = state.valueOrNull;
    state = AsyncData(
      LlmProviderConfig(
        active: LlmProvider.ollama,
        ollamaHost: host,
        ollamaModel: model,
        openRouterApiKey: current?.openRouterApiKey ?? '',
        openRouterModel: current?.openRouterModel ?? '',
      ),
    );
  }

  Future<void> saveOpenRouter({
    required String apiKey,
    required String model,
  }) async {
    await Future.wait([
      _storage.write(key: _kOpenRouterApiKey, value: apiKey),
      _storage.write(key: _kOpenRouterModel, value: model),
      _storage.write(key: _kActiveProvider, value: 'openrouter'),
    ]);
    final current = state.valueOrNull;
    state = AsyncData(
      LlmProviderConfig(
        active: LlmProvider.openRouter,
        ollamaHost: current?.ollamaHost ?? '',
        ollamaModel: current?.ollamaModel ?? '',
        openRouterApiKey: apiKey,
        openRouterModel: model,
      ),
    );
  }
}

// ── Settings screen ───────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _initialized = false;

  // Which provider panel is shown (local UI state — not committed until Save)
  LlmProvider _selectedProvider = LlmProvider.ollama;

  // Ollama
  final _ollamaHostCtrl = TextEditingController();
  List<String> _discoveredModels = [];
  String? _selectedOllamaModel;
  bool _testing = false;
  String? _testResult;
  bool _testSuccess = false;

  // OpenRouter
  final _openRouterKeyCtrl = TextEditingController();
  final _openRouterModelCtrl = TextEditingController();
  bool _obscureKey = true;

  @override
  void dispose() {
    _ollamaHostCtrl.dispose();
    _openRouterKeyCtrl.dispose();
    _openRouterModelCtrl.dispose();
    super.dispose();
  }

  void _initFromConfig(LlmProviderConfig c) {
    if (_initialized) return;
    _initialized = true;
    setState(() {
      _selectedProvider = c.active;
      _ollamaHostCtrl.text = c.ollamaHost;
      _openRouterKeyCtrl.text = c.openRouterApiKey;
      _openRouterModelCtrl.text = c.openRouterModel;
      if (c.ollamaModel.isNotEmpty) {
        _selectedOllamaModel = c.ollamaModel;
        _discoveredModels = [c.ollamaModel];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(llmConfigProvider);
    config.whenData(_initFromConfig);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarLogo(),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Units ──────────────────────────────────────────────────────────
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

          // ── Theme ────────────────────────────────────────────────────────────
          Text('Theme', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Choose your preferred appearance.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          // Use LayoutBuilder to detect overflow and hide labels on small screens.
          LayoutBuilder(
            builder: (context, constraints) {
              final showLabels = constraints.maxWidth >= 360;
              return ref.watch(themeModeProvider).when(
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
          const Divider(),
          const SizedBox(height: 24),

          // ── LLM Configuration ──────────────────────────────────────────────
          Text(
            'LLM Configuration',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Configure an LLM provider to enable AI-assisted recipe import and smart suggestions.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SegmentedButton<LlmProvider>(
            segments: const [
              ButtonSegment(
                value: LlmProvider.ollama,
                label: Text('Ollama'),
                icon: Icon(Icons.computer_outlined),
              ),
              ButtonSegment(
                value: LlmProvider.openRouter,
                label: Text('OpenRouter'),
                icon: Icon(Icons.cloud_outlined),
              ),
            ],
            selected: {_selectedProvider},
            onSelectionChanged: (set) =>
                setState(() => _selectedProvider = set.first),
          ),
          const SizedBox(height: 20),
          config.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (_) => _selectedProvider == LlmProvider.ollama
                ? _buildOllamaSection()
                : _buildOpenRouterSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildOllamaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ollamaHostCtrl,
          decoration: const InputDecoration(
            labelText: 'Host',
            hintText: 'localhost or 192.168.1.x',
            border: OutlineInputBorder(),
            helperText: 'Port 11434 · /v1 path used automatically',
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: _testing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_tethering, size: 18),
          label: Text(_testing ? 'Testing…' : 'Test Connection'),
          onPressed: _testing ? null : _testOllama,
        ),
        if (_testResult != null) ...[
          const SizedBox(height: 8),
          Text(
            _testResult!,
            style: TextStyle(
              color: _testSuccess ? Colors.green.shade700 : Colors.red.shade700,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _discoveredModels.contains(_selectedOllamaModel)
              ? _selectedOllamaModel
              : null,
          decoration: const InputDecoration(
            labelText: 'Model',
            border: OutlineInputBorder(),
          ),
          hint: Text(
            _discoveredModels.isEmpty
                ? 'Test connection first'
                : 'Select a model',
          ),
          items: _discoveredModels
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: _discoveredModels.isEmpty
              ? null
              : (v) => setState(() => _selectedOllamaModel = v),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed:
              (_selectedOllamaModel != null && _selectedOllamaModel!.isNotEmpty)
              ? _saveOllama
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildOpenRouterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Endpoint', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 2),
              const Text(
                'https://openrouter.ai/api/v1',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _openRouterKeyCtrl,
          decoration: InputDecoration(
            labelText: 'API Key',
            hintText: 'sk-or-v1-…',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureKey = !_obscureKey),
            ),
          ),
          obscureText: _obscureKey,
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _openRouterModelCtrl,
          decoration: const InputDecoration(
            labelText: 'Model',
            hintText: 'anthropic/claude-3-haiku',
            border: OutlineInputBorder(),
          ),
          autocorrect: false,
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: _saveOpenRouter, child: const Text('Save')),
      ],
    );
  }

  Future<void> _testOllama() async {
    final host = _ollamaHostCtrl.text.trim();
    if (host.isEmpty) {
      setState(() {
        _testResult = 'Enter a host first';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _testing = true;
      _testResult = null;
      _discoveredModels = [];
      _selectedOllamaModel = null;
    });

    try {
      final uri = Uri.parse('http://$host:11434/api/tags');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final names = (json['models'] as List)
            .map((m) => m['name'] as String)
            .toList();
        if (names.isEmpty) {
          setState(() {
            _testResult =
                'Connected — no models found. Pull one with `ollama pull <name>`.';
            _testSuccess = true;
          });
        } else {
          setState(() {
            _discoveredModels = names;
            _selectedOllamaModel = names.first;
            _testResult =
                'Found ${names.length} model${names.length == 1 ? '' : 's'}: ${names.join(', ')}';
            _testSuccess = true;
          });
        }
      } else {
        setState(() {
          _testResult = 'Returned ${resp.statusCode}';
          _testSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _testResult = 'Could not connect: $e';
        _testSuccess = false;
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _saveOllama() async {
    await ref
        .read(llmConfigProvider.notifier)
        .saveOllama(
          host: _ollamaHostCtrl.text.trim(),
          model: _selectedOllamaModel ?? '',
        );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ollama configured')));
    }
  }

  Future<void> _saveOpenRouter() async {
    await ref
        .read(llmConfigProvider.notifier)
        .saveOpenRouter(
          apiKey: _openRouterKeyCtrl.text.trim(),
          model: _openRouterModelCtrl.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OpenRouter configured')));
    }
  }
}
