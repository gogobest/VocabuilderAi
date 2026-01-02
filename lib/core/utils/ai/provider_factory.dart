import 'package:visual_vocabularies/core/utils/secure_storage_service.dart';
import 'package:visual_vocabularies/core/utils/ai/ai_provider_interface.dart';
import 'package:visual_vocabularies/core/utils/ai/gemini_provider.dart';
import 'package:visual_vocabularies/core/utils/ai/claude_provider.dart';
import 'package:visual_vocabularies/core/utils/ai/chatgpt_provider.dart';
import 'package:visual_vocabularies/core/utils/ai/qwen_provider.dart';
import 'package:visual_vocabularies/core/utils/ai/custom_provider.dart';
import 'package:visual_vocabularies/core/utils/ai/models/prompt_type.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Factory class for creating AI provider instances
class AiProviderFactory {
  /// Default AI provider
  static const String defaultProvider = 'gemini';
  
  /// List of supported AI providers
  static const List<String> supportedProviders = [
    'gemini',
    'claude',
    'chatgpt',
    'qwen',
    'custom'
  ];
  
  /// Cache providers to avoid recreating them
  static final Map<String, AiProviderInterface> _providerCache = {};
  
  /// Creates an AI provider instance based on the provider name
  static AiProviderInterface createProvider(String provider, SecureStorageService secureStorage) {
    switch (provider) {
      case 'gemini':
        return GeminiProvider(secureStorage);
      case 'claude':
        return ClaudeProvider(secureStorage);
      case 'chatgpt':
        return ChatGptProvider(secureStorage);
      case 'qwen':
        return QwenProvider(secureStorage);
      case 'custom':
        return CustomProvider(secureStorage);
      default:
        // Return the default provider if the specified one is not supported
        return GeminiProvider(secureStorage);
    }
  }
  
  /// Validates if a provider is supported
  static bool isProviderSupported(String provider) {
    return supportedProviders.contains(provider);
  }
  
  static AiProviderInterface getProvider(String provider, SecureStorageService secureStorage) {
    final cacheKey = provider.toLowerCase();
    
    if (_providerCache.containsKey(cacheKey)) {
      return _providerCache[cacheKey]!;
    }
    
    final AiProviderInterface newProvider = createProvider(provider, secureStorage);
    _providerCache[cacheKey] = newProvider;
    return newProvider;
  }
  
  // Add response caching capability
  static final Map<String, dynamic> _resultCache = {};
  
  static Future<String> getCompletionWithCache(
    AiProviderInterface provider,
    PromptType type,
    Map<String, dynamic> parameters, 
    {Duration cacheTtl = const Duration(hours: 2)}
  ) async {
    // Generate cache key from prompt type and parameters
    final cacheKey = "$type:${_generateCacheKey(parameters)}";
    
    // Check cache
    final cachedResult = _resultCache[cacheKey];
    if (cachedResult != null) {
      final timestamp = cachedResult['timestamp'] as DateTime;
      if (DateTime.now().difference(timestamp) < cacheTtl) {
        if (kDebugMode) {
          print('Using cached AI response for $cacheKey');
        }
        return cachedResult['response'] as String;
      }
    }
    
    // Make actual request
    final response = await provider.makeRequest(type, parameters);
    
    // Cache result
    _resultCache[cacheKey] = {
      'response': response,
      'timestamp': DateTime.now(),
    };
    
    // Clean old cache entries periodically (1 in 10 chance)
    if (DateTime.now().millisecondsSinceEpoch % 10 == 0) {
      _cleanExpiredCache(cacheTtl);
    }
    
    return response;
  }
  
  static String _generateCacheKey(Map<String, dynamic> parameters) {
    // Create a stable hash from parameters
    final paramHash = parameters.entries
        .where((e) => e.key != 'subtitleText') // Don't include full subtitle text
        .map((e) => '${e.key}:${e.value}')
        .join('|');
        
    // For subtitle text, just use a hash of the content
    if (parameters.containsKey('subtitleText')) {
      final subtitleText = parameters['subtitleText'] as String;
      final textHash = subtitleText.length.toString() + 
                      ':' + subtitleText.substring(0, subtitleText.length > 100 ? 100 : subtitleText.length).hashCode.toString();
      return paramHash + '|subtitleTextHash:' + textHash;
    }
    
    return paramHash;
  }
  
  static void _cleanExpiredCache(Duration ttl) {
    final now = DateTime.now();
    _resultCache.removeWhere((key, value) {
      final timestamp = value['timestamp'] as DateTime;
      return now.difference(timestamp) > ttl;
    });
  }
} 