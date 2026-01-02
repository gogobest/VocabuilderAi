import 'package:visual_vocabularies/core/utils/ai/models/prompt_type.dart';
import 'package:visual_vocabularies/core/utils/secure_storage_service.dart';

/// Interface for AI providers 
abstract class AiProviderInterface {
  final SecureStorageService secureStorage;
  
  AiProviderInterface(this.secureStorage);
  
  /// Make a request to the AI provider
  Future<String> makeRequest(
    PromptType type, 
    Map<String, dynamic> parameters, 
    {bool isTestMode = false}
  );
  
  /// Check if the API key exists and is valid
  Future<void> validateApiKey();
} 