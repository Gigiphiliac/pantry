import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:pantry/features/settings/settings_screen.dart';

class LlmClient {
  /// Send a system + user message to the configured LLM.
  /// Returns the raw assistant text response.
  /// Throws [Exception] with a user-readable message on any failure.
  static Future<String> complete(
    String systemPrompt,
    String userText,
    LlmConfig config,
  ) async {
    return config.provider == LlmProvider.ollama
        ? _ollamaChat(systemPrompt, userText, config)
        : _openAiChat(systemPrompt, userText, config);
  }

  static Future<String> _ollamaChat(
    String systemPrompt,
    String userText,
    LlmConfig config,
  ) async {
    final uri = Uri.parse('${config.endpoint}/api/chat');
    final body = jsonEncode({
      'model': config.model.isNotEmpty ? config.model : 'llama3.2',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userText},
      ],
      'stream': false,
    });

    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {HttpHeaders.contentTypeHeader: 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 120));
    } catch (e) {
      throw Exception('Could not reach Ollama: $e');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Ollama returned ${response.statusCode}: ${response.body}',
      );
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded['message']['content'] as String;
    } catch (e) {
      throw Exception('Failed to parse Ollama response: $e');
    }
  }

  static Future<String> _openAiChat(
    String systemPrompt,
    String userText,
    LlmConfig config,
  ) async {
    final uri = Uri.parse('${config.endpoint}/chat/completions');
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      if (config.apiKey.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer ${config.apiKey}',
    };
    final body = jsonEncode({
      'model': config.model.isNotEmpty ? config.model : 'llama3.2',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userText},
      ],
      'temperature': 0.1,
      'stream': false,
    });

    late http.Response response;
    try {
      response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 120));
    } catch (e) {
      throw Exception('Could not reach LLM endpoint: $e');
    }

    if (response.statusCode != 200) {
      throw Exception('LLM returned ${response.statusCode}: ${response.body}');
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw Exception('Failed to parse LLM response: $e');
    }
  }
}
