import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:visual_vocabularies/core/utils/secure_storage_service.dart';
import 'package:visual_vocabularies/core/utils/ai/ai_provider_interface.dart';
import 'package:visual_vocabularies/core/utils/ai/models/prompt_type.dart';

/// Implementation of Claude AI provider
class ClaudeProvider implements AiProviderInterface {
  @override
  final SecureStorageService secureStorage;
  
  /// Constructor
  ClaudeProvider(this.secureStorage);
  
  @override
  Future<void> validateApiKey() async {
    final apiKey = await secureStorage.getClaudeApiKey();
    if (apiKey.isEmpty) {
      throw Exception('Claude API key not found. Please set it in Settings or via the API Key dialog.');
    }
  }
  
  @override
  Future<String> makeRequest(
    PromptType type, 
    Map<String, dynamic> parameters, 
    {bool isTestMode = false}
  ) async {
    await validateApiKey();
    final apiKey = await secureStorage.getClaudeApiKey();
    final promptTemplate = PromptTemplate.getTemplate(type, parameters);
    
    // Use appropriate model based on request type
    final model = isTestMode ? "claude-3-haiku-20240307" : "claude-3-sonnet-20240229";
    final url = 'https://api.anthropic.com/v1/messages';
    
    final payload = {
      "model": model,
      "max_tokens": promptTemplate['maxTokens'] ?? 1024,
      "temperature": promptTemplate['temperature'] ?? 0.7,
      "messages": [
        {
          "role": "user",
          "content": promptTemplate['prompt']
        }
      ]
    };
    
    // Add system prompt if provided
    if (promptTemplate.containsKey('systemPrompt') && promptTemplate['systemPrompt'] != null) {
      payload['system'] = promptTemplate['systemPrompt'];
    }
    
    final timeoutDuration = isTestMode ? const Duration(seconds: 15) : const Duration(seconds: 30);
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01'
      },
      body: jsonEncode(payload)
    ).timeout(timeoutDuration, onTimeout: () {
      throw TimeoutException('The request timed out after ${isTestMode ? 15 : 30} seconds');
    });
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data.containsKey('content') && 
          data['content'] is List && 
          data['content'].isNotEmpty) {
        return data['content'][0]['text'];
      }
      
      throw Exception('Empty or invalid response from Claude API');
    }
    
    // For better debugging, include the response body in the error
    String errorDetails = 'Unknown error';
    try {
      final errorData = jsonDecode(response.body);
      if (errorData.containsKey('error')) {
        errorDetails = errorData['error']['message'] ?? errorData['error'].toString();
      } else {
        errorDetails = response.body;
      }
    } catch (_) {
      errorDetails = response.body;
    }
    
    throw Exception('Claude API error (${response.statusCode}): $errorDetails');
  }
} 