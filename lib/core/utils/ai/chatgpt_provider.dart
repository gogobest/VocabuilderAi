import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:visual_vocabularies/core/utils/secure_storage_service.dart';
import 'package:visual_vocabularies/core/utils/ai/ai_provider_interface.dart';
import 'package:visual_vocabularies/core/utils/ai/models/prompt_type.dart';

/// Implementation of ChatGPT AI provider
class ChatGptProvider implements AiProviderInterface {
  @override
  final SecureStorageService secureStorage;
  
  /// Constructor
  ChatGptProvider(this.secureStorage);
  
  @override
  Future<void> validateApiKey() async {
    final apiKey = await secureStorage.getChatGptApiKey();
    if (apiKey.isEmpty) {
      throw Exception('ChatGPT API key not found. Please set it in Settings or via the API Key dialog.');
    }
  }
  
  @override
  Future<String> makeRequest(
    PromptType type, 
    Map<String, dynamic> parameters, 
    {bool isTestMode = false}
  ) async {
    await validateApiKey();
    final apiKey = await secureStorage.getChatGptApiKey();
    final promptTemplate = PromptTemplate.getTemplate(type, parameters);
    
    // Use appropriate model based on request type
    final model = isTestMode ? "gpt-3.5-turbo" : "gpt-4";
    final url = 'https://api.openai.com/v1/chat/completions';
    
    final payload = {
      "model": model,
      "max_tokens": promptTemplate['maxTokens'] ?? 1024,
      "temperature": promptTemplate['temperature'] ?? 0.7,
      "messages": [
        {"role": "system", "content": promptTemplate['systemPrompt'] ?? "You are a helpful assistant for vocabulary learning."},
        {"role": "user", "content": promptTemplate['prompt']}
      ]
    };
    
    final timeoutDuration = isTestMode ? const Duration(seconds: 15) : const Duration(seconds: 30);
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey'
      },
      body: jsonEncode(payload)
    ).timeout(timeoutDuration, onTimeout: () {
      throw TimeoutException('The request timed out after ${isTestMode ? 15 : 30} seconds');
    });
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data.containsKey('choices') && 
          data['choices'] is List && 
          data['choices'].isNotEmpty &&
          data['choices'][0].containsKey('message') &&
          data['choices'][0]['message'].containsKey('content')) {
        return data['choices'][0]['message']['content'];
      }
      
      throw Exception('Empty or invalid response from ChatGPT API');
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
    
    throw Exception('ChatGPT API error (${response.statusCode}): $errorDetails');
  }
} 