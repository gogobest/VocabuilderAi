import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Service to securely store sensitive information like API keys
class SecureStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Keys for storage
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _claudeApiKeyKey = 'claude_api_key';
  static const String _chatGptApiKeyKey = 'chatgpt_api_key';
  static const String _qwenApiKeyKey = 'qwen_api_key';
  static const String _customApiKeyKey = 'custom_api_key';
  static const String _selectedAiProviderKey = 'selected_ai_provider';
  static const String _customApiUrlKey = 'custom_api_url';
  static const String _giphyApiKeyKey = 'giphy_api_key';
  static const String _customHeaderFormatKey = 'custom_header_format';
  static const String _customModelParamKey = 'custom_model_param';
  static const String _customModelKey = 'custom_model';
  static const String _customPayloadFormatKey = 'custom_payload_format';
  static const String _customResponseFormatKey = 'custom_response_format';
  static const String _apiKeyKey = 'api_key';
  
  /// Save Gemini API key
  Future<void> saveGeminiApiKey(String apiKey) async {
    await _secureStorage.write(key: _geminiApiKeyKey, value: apiKey);
  }
  
  /// Get Gemini API key
  Future<String> getGeminiApiKey() async {
    return await _secureStorage.read(key: _geminiApiKeyKey) ?? '';
  }
  
  /// Save Claude API key
  Future<void> saveClaudeApiKey(String apiKey) async {
    await _secureStorage.write(key: _claudeApiKeyKey, value: apiKey);
  }
  
  /// Get Claude API key
  Future<String> getClaudeApiKey() async {
    return await _secureStorage.read(key: _claudeApiKeyKey) ?? '';
  }
  
  /// Save ChatGPT API key
  Future<void> saveChatGptApiKey(String apiKey) async {
    await _secureStorage.write(key: _chatGptApiKeyKey, value: apiKey);
  }
  
  /// Get ChatGPT API key
  Future<String> getChatGptApiKey() async {
    return await _secureStorage.read(key: _chatGptApiKeyKey) ?? '';
  }
  
  /// Save Qwen API key
  Future<void> saveQwenApiKey(String apiKey) async {
    await _secureStorage.write(key: _qwenApiKeyKey, value: apiKey);
  }
  
  /// Get Qwen API key
  Future<String> getQwenApiKey() async {
    return await _secureStorage.read(key: _qwenApiKeyKey) ?? '';
  }
  
  /// Save Custom API key
  Future<void> saveCustomApiKey(String apiKey) async {
    await _secureStorage.write(key: _customApiKeyKey, value: apiKey);
  }
  
  /// Get Custom API key
  Future<String> getCustomApiKey() async {
    return await _secureStorage.read(key: _customApiKeyKey) ?? '';
  }
  
  /// Save Custom API URL
  Future<void> saveCustomApiUrl(String url) async {
    await _secureStorage.write(key: _customApiUrlKey, value: url);
  }
  
  /// Get Custom API URL
  Future<String> getCustomApiUrl() async {
    return await _secureStorage.read(key: _customApiUrlKey) ?? '';
  }
  
  /// Save Custom API header format (e.g., 'Bearer', 'Basic', etc.)
  Future<void> saveCustomHeaderFormat(String format) async {
    await _secureStorage.write(key: _customHeaderFormatKey, value: format);
  }
  
  /// Get Custom API header format
  Future<String?> getCustomHeaderFormat() async {
    return await _secureStorage.read(key: _customHeaderFormatKey);
  }
  
  /// Save Custom API model parameter name
  Future<void> saveCustomModelParam(String paramName) async {
    await _secureStorage.write(key: _customModelParamKey, value: paramName);
  }
  
  /// Get Custom API model parameter name
  Future<String?> getCustomModelParam() async {
    return await _secureStorage.read(key: _customModelParamKey);
  }
  
  /// Save Custom API model value
  Future<void> saveCustomModel(String model) async {
    await _secureStorage.write(key: _customModelKey, value: model);
  }
  
  /// Get Custom API model value
  Future<String?> getCustomModel() async {
    return await _secureStorage.read(key: _customModelKey);
  }
  
  /// Save Custom API payload format
  Future<void> saveCustomPayloadFormat(String format) async {
    await _secureStorage.write(key: _customPayloadFormatKey, value: format);
  }
  
  /// Get Custom API payload format
  Future<String?> getCustomPayloadFormat() async {
    return await _secureStorage.read(key: _customPayloadFormatKey);
  }
  
  /// Save Custom API response format
  Future<void> saveCustomResponseFormat(String format) async {
    await _secureStorage.write(key: _customResponseFormatKey, value: format);
  }
  
  /// Get Custom API response format
  Future<String?> getCustomResponseFormat() async {
    return await _secureStorage.read(key: _customResponseFormatKey);
  }
  
  /// Save GIPHY API key
  Future<void> saveGiphyApiKey(String apiKey) async {
    await _secureStorage.write(key: _giphyApiKeyKey, value: apiKey);
  }
  
  /// Get GIPHY API key
  Future<String> getGiphyApiKey() async {
    return await _secureStorage.read(key: _giphyApiKeyKey) ?? '';
  }
  
  /// Method to get the selected AI provider
  Future<String> getSelectedAiProvider() async {
    return await _secureStorage.read(key: _selectedAiProviderKey) ?? '';
  }
  
  /// Method to set the selected AI provider
  Future<void> setSelectedAiProvider(String provider) async {
    await _secureStorage.write(key: _selectedAiProviderKey, value: provider);
  }
  
  /// Delete all stored API keys
  Future<void> deleteAllApiKeys() async {
    await _secureStorage.deleteAll();
  }
  
  /// Get the general API key
  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyKey);
  }
  
  /// Save the general API key
  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyKey, value: apiKey);
  }
} 