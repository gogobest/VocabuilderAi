import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:visual_vocabularies/core/utils/secure_storage_service.dart';
import 'package:visual_vocabularies/core/utils/ai/ai_provider_interface.dart';
import 'package:visual_vocabularies/core/utils/ai/models/prompt_type.dart';

/// Implementation of Gemini AI provider
class GeminiProvider implements AiProviderInterface {
  @override
  final SecureStorageService secureStorage;
  
  /// Constructor
  GeminiProvider(this.secureStorage);
  
  @override
  Future<void> validateApiKey() async {
    final apiKey = await secureStorage.getGeminiApiKey();
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key not found. Please set it in Settings or via the API Key dialog.');
    }
  }
  
  @override
  Future<String> makeRequest(
    PromptType type, 
    Map<String, dynamic> parameters, 
    {bool isTestMode = false}
  ) async {
    await validateApiKey();
    final apiKey = await secureStorage.getGeminiApiKey();
    final promptTemplate = PromptTemplate.getTemplate(type, parameters);
    
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';
    
    final payload = {
      "contents": [{
        "parts": [{
          "text": promptTemplate['prompt']
        }]
      }],
      "generationConfig": {
        "temperature": promptTemplate['temperature'] ?? 0.7,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": promptTemplate['maxTokens'] ?? 1024,
        "responseMimeType": "application/json"
      }
    };
    
    final timeoutDuration = isTestMode ? const Duration(seconds: 15) : const Duration(seconds: 30);
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json'
      },
      body: jsonEncode(payload)
    ).timeout(timeoutDuration, onTimeout: () {
      throw TimeoutException('The request timed out after ${isTestMode ? 15 : 30} seconds');
    });
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String textResponse = '';
      
      // Handle response format for gemini-2.0-flash
      if (data.containsKey('candidates') && 
          data['candidates'] is List && 
          data['candidates'].isNotEmpty) {
        if (data['candidates'][0].containsKey('content') && 
            data['candidates'][0]['content'].containsKey('parts') && 
            data['candidates'][0]['content']['parts'] is List && 
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          textResponse = data['candidates'][0]['content']['parts'][0]['text'];
        }
      }
      
      if (textResponse.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }
      
      return textResponse;
    }
    
    // For better debugging, include the response body in the error
    String errorDetails = 'Unknown error';
    try {
      final errorData = jsonDecode(response.body);
      if (errorData.containsKey('error')) {
        if (errorData['error'].containsKey('message')) {
          errorDetails = errorData['error']['message'];
        } else {
          errorDetails = errorData['error'].toString();
        }
      } else {
        errorDetails = response.body;
      }
    } catch (_) {
      errorDetails = response.body;
    }
    
    throw Exception('Gemini API error (${response.statusCode}): $errorDetails');
  }
} 