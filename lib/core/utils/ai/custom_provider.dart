import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:visual_vocabularies/core/utils/secure_storage_service.dart';
import 'package:visual_vocabularies/core/utils/ai/ai_provider_interface.dart';
import 'package:visual_vocabularies/core/utils/ai/models/prompt_type.dart';

/// Implementation of a custom AI provider allowing users to configure their own AI service
class CustomProvider implements AiProviderInterface {
  @override
  final SecureStorageService secureStorage;
  
  /// Constructor
  CustomProvider(this.secureStorage);
  
  @override
  Future<void> validateApiKey() async {
    final apiKey = await secureStorage.getCustomApiKey();
    final apiUrl = await secureStorage.getCustomApiUrl();
    
    if (apiKey.isEmpty) {
      throw Exception('Custom API key not found. Please set it in Settings.');
    }
    
    if (apiUrl.isEmpty) {
      throw Exception('Custom API URL not found. Please set it in Settings.');
    }
  }
  
  @override
  Future<String> makeRequest(
    PromptType type, 
    Map<String, dynamic> parameters, 
    {bool isTestMode = false}
  ) async {
    await validateApiKey();
    final apiKey = await secureStorage.getCustomApiKey();
    final apiUrl = await secureStorage.getCustomApiUrl();
    final promptTemplate = PromptTemplate.getTemplate(type, parameters);
    
    // Get header format from storage
    final headerFormat = await secureStorage.getCustomHeaderFormat() ?? 'Bearer';
    final modelParam = await secureStorage.getCustomModelParam() ?? 'model';
    final model = await secureStorage.getCustomModel() ?? 'default-model';
    
    // Build the payload based on stored format preferences
    final payloadFormat = await secureStorage.getCustomPayloadFormat() ?? 'openai';
    Map<String, dynamic> payload;
    
    switch (payloadFormat) {
      case 'openai':
        payload = {
          modelParam: model,
          "max_tokens": promptTemplate['maxTokens'] ?? 1024,
          "temperature": promptTemplate['temperature'] ?? 0.7,
          "messages": [
            {"role": "system", "content": promptTemplate['systemPrompt'] ?? "You are a helpful assistant for vocabulary learning."},
            {"role": "user", "content": promptTemplate['prompt']}
          ]
        };
        break;
      case 'anthropic':
        payload = {
          modelParam: model,
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
        break;
      case 'gemini':
        payload = {
          "contents": [
            {
              "parts": [
                {
                  "text": promptTemplate['prompt']
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": promptTemplate['temperature'] ?? 0.7,
            "maxOutputTokens": promptTemplate['maxTokens'] ?? 1024,
            "topK": 40,
            "topP": 0.95
          }
        };
        break;
      default:
        // Simple prompt-only format for custom implementations
        payload = {
          modelParam: model,
          "prompt": promptTemplate['prompt'],
          "system_prompt": promptTemplate['systemPrompt'],
          "max_tokens": promptTemplate['maxTokens'] ?? 1024,
          "temperature": promptTemplate['temperature'] ?? 0.7
        };
    }
    
    final timeoutDuration = isTestMode ? const Duration(seconds: 15) : const Duration(seconds: 30);
    
    // Build headers with API key based on format
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    // Add authorization header in the specified format
    if (headerFormat == 'Bearer') {
      headers['Authorization'] = 'Bearer $apiKey';
    } else if (headerFormat == 'Key') {
      headers['Api-Key'] = apiKey;
    } else if (headerFormat == 'X-API-Key') {
      headers['X-API-Key'] = apiKey;
    } else {
      // Custom header format
      headers[headerFormat] = apiKey;
    }
    
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: jsonEncode(payload)
    ).timeout(timeoutDuration, onTimeout: () {
      throw TimeoutException('The request timed out after ${isTestMode ? 15 : 30} seconds');
    });
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Try different response formats based on what's stored or common patterns
      final responseFormat = await secureStorage.getCustomResponseFormat() ?? 'auto';
      
      try {
        if (responseFormat == 'auto') {
          // Try common response formats
          if (data.containsKey('choices') && data['choices'] is List && data['choices'].isNotEmpty) {
            // OpenAI-like format
            if (data['choices'][0].containsKey('message')) {
              return data['choices'][0]['message']['content'];
            } else if (data['choices'][0].containsKey('text')) {
              return data['choices'][0]['text'];
            }
          } else if (data.containsKey('content') && data['content'] is List && data['content'].isNotEmpty) {
            // Claude-like format
            return data['content'][0]['text'];
          } else if (data.containsKey('candidates') && data['candidates'] is List && data['candidates'].isNotEmpty) {
            // Gemini-like format
            return data['candidates'][0]['content']['parts'][0]['text'];
          } else if (data.containsKey('result')) {
            // Simple result key
            return data['result'].toString();
          } else if (data.containsKey('response')) {
            // Simple response key
            return data['response'].toString();
          } else if (data.containsKey('text')) {
            // Simple text key
            return data['text'].toString();
          }
          
          // If we still don't have a response, return the whole JSON as a string
          return response.body;
        } else {
          // Use a specific path in the JSON response
          final pathParts = responseFormat.split('.');
          dynamic value = data;
          
          for (final part in pathParts) {
            if (value is Map && value.containsKey(part)) {
              value = value[part];
            } else {
              throw Exception('Response format path "$responseFormat" not found in API response');
            }
          }
          
          return value.toString();
        }
      } catch (e) {
        // If all extraction attempts fail, return the raw response
        return response.body;
      }
    }
    
    // For better debugging, include the response body in the error
    String errorDetails = 'Unknown error';
    try {
      final errorData = jsonDecode(response.body);
      errorDetails = errorData.toString();
    } catch (_) {
      errorDetails = response.body;
    }
    
    throw Exception('Custom API error (${response.statusCode}): $errorDetails');
  }
} 