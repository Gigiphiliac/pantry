import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kEndpointKey = 'llm_endpoint';
const _kApiKeyKey = 'llm_api_key';
const _kModelKey = 'llm_model';

final _storage = FlutterSecureStorage();

final llmConfigProvider =
    AsyncNotifierProvider<LlmConfigNotifier, LlmConfig>(LlmConfigNotifier.new);

class LlmConfig {
  final String endpoint;
  final String apiKey;
  final String model;

  const LlmConfig({
    required this.endpoint,
    required this.apiKey,
    required this.model,
  });

  bool get isConfigured => endpoint.isNotEmpty;
}

class LlmConfigNotifier extends AsyncNotifier<LlmConfig> {
  @override
  Future<LlmConfig> build() async {
    final endpoint = await _storage.read(key: _kEndpointKey) ?? '';
    final apiKey = await _storage.read(key: _kApiKeyKey) ?? '';
    final model = await _storage.read(key: _kModelKey) ?? '';
    return LlmConfig(endpoint: endpoint, apiKey: apiKey, model: model);
  }

  Future<void> save({
    required String endpoint,
    required String apiKey,
    required String model,
  }) async {
    await Future.wait([
      _storage.write(key: _kEndpointKey, value: endpoint),
      _storage.write(key: _kApiKeyKey, value: apiKey),
      _storage.write(key: _kModelKey, value: model),
    ]);
    state = AsyncData(LlmConfig(endpoint: endpoint, apiKey: apiKey, model: model));
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _endpointCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  bool _obscureKey = true;

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(llmConfigProvider);

    config.whenData((c) {
      if (_endpointCtrl.text.isEmpty && c.endpoint.isNotEmpty) {
        _endpointCtrl.text = c.endpoint;
        _apiKeyCtrl.text = c.apiKey;
        _modelCtrl.text = c.model;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('LLM Configuration', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Configure an Ollama or OpenAI-compatible endpoint to enable AI-assisted recipe import and smart suggestions.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          config.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (_) => Column(
              children: [
                TextField(
                  controller: _endpointCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Endpoint URL',
                    hintText: 'http://192.168.1.x:11434/v1',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyCtrl,
                  decoration: InputDecoration(
                    labelText: 'API Key (optional)',
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
                  controller: _modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Model name',
                    hintText: 'llama3.2 or gpt-4o-mini',
                    border: OutlineInputBorder(),
                  ),
                  autocorrect: false,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    await ref.read(llmConfigProvider.notifier).save(
                          endpoint: _endpointCtrl.text.trim(),
                          apiKey: _apiKeyCtrl.text.trim(),
                          model: _modelCtrl.text.trim(),
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings saved')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
