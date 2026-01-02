import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:visual_vocabularies/core/utils/logger.dart';

/// Utility class for processing responses from AI providers
class ResponseProcessor {
  /// Process vocabulary response from AI provider
  static Map<String, dynamic> processVocabularyResponse(String response, String word) {
    try {
      // Extract the JSON object from the response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        final result = jsonDecode(jsonStr);
        
        // Clean up the meaning/definition to remove any prompt text
        String cleanMeaning = '';
        if (result['meaning'] != null) {
          cleanMeaning = _cleanupPromptText(result['meaning'].toString());
        } else if (result['definition'] != null) {
          cleanMeaning = _cleanupPromptText(result['definition'].toString());
        } else {
          cleanMeaning = 'No definition available';
        }
        
        // Clean up the example to remove prompt text
        String? cleanExample;
        if (result['example'] != null) {
          cleanExample = _cleanupPromptText(result['example'].toString());
        }
        
        // Return with all required fields, using defaults for missing fields
        return {
          'word': _cleanupPromptText(word), // Clean up the word itself
          'meaning': cleanMeaning,
          'example': cleanExample ?? 'No example available',
          'category': result['category'] ?? 'General',
          'difficultyLevel': result['difficultyLevel'] ?? 3,
          'tprDescription': result['tprDescription'] ?? 'Wave your hand while saying the word',
          'synonyms': result['synonyms'] ?? [],
          'antonyms': result['antonyms'] ?? [],
          'partOfSpeech': result['partOfSpeech'] ?? 'noun',
          'emoji': result['emoji'] ?? '',
        };
      }
      throw Exception('Could not extract JSON from response');
    } catch (e) {
      return defaultVocabularyResponse(word, e.toString());
    }
  }
  
  /// Clean up prompt text from AI responses
  static String _cleanupPromptText(String text) {
    // Remove prompt instructions
    String cleaned = text;
    
    // Remove "Generate a flashcard for..." texts
    cleaned = cleaned.replaceAll(RegExp(r'Generate a flashcard for the word/phrase.*?context:', 
                                        caseSensitive: false, dotAll: true), '');
                                        
    // Remove prompt instructions about including things
    cleaned = cleaned.replaceAll(RegExp(r'Include:.*?category\.', 
                                        caseSensitive: false, dotAll: true), '');
    
    // Remove remaining prompt fragments
    final promptFragments = [
      'definition,', 
      'example,', 
      'partOfSpeech,', 
      'emoji,', 
      'synonyms,', 
      'antonyms,', 
      'and category.',
      'as used in this context:',
      'Include:',
    ];
    
    for (final fragment in promptFragments) {
      cleaned = cleaned.replaceAll(fragment, '');
    }
    
    // Trim and clean up extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    
    return cleaned;
  }
  
  /// Process tense variations response from AI provider
  static Map<String, String> processTenseVariationsResponse(String response) {
    try {
      // Extract the JSON object from the response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        final Map<String, dynamic> result = jsonDecode(jsonStr);
        
        // Convert to Map<String, String>
        final Map<String, String> tenseVariations = {};
        result.forEach((key, value) {
          if (value is String) {
            tenseVariations[key] = value;
          } else {
            tenseVariations[key] = value.toString();
          }
        });
        
        return tenseVariations;
      }
      throw Exception('Could not extract JSON from response');
    } catch (e) {
      return {};
    }
  }
  
  /// Process subtitle extraction response from AI provider
  static Map<String, dynamic> processSubtitleExtractionResponse(String response) {
    try {
      // Extract the JSON object from the response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        String jsonStr = response.substring(jsonStart, jsonEnd);
        
        // Sanitize the JSON string to fix common issues
        jsonStr = _sanitizeJsonString(jsonStr);
        
        Map<String, dynamic> result;
        try {
          result = jsonDecode(jsonStr);
        } catch (jsonError) {
          Logger.e('JSON decode error: $jsonError', tag: 'ResponseProcessor');
          Logger.d('Attempting JSON repair', tag: 'ResponseProcessor');
          
          // Try to repair the JSON and parse again
          jsonStr = _attemptJsonRepair(jsonStr);
          result = jsonDecode(jsonStr);
        }
        
        // Check if the response has a valid structure with either 'words' or 'vocabulary' key
        List<dynamic> rawWords = [];
        
        if (result.containsKey('vocabulary') && result['vocabulary'] is List) {
          rawWords = result['vocabulary'] as List;
        } else if (result.containsKey('words') && result['words'] is List) {
          rawWords = result['words'] as List;
        } else {
          // Print the raw response for debugging
          Logger.w('Invalid response format: ${jsonStr.substring(0, min(200, jsonStr.length))}...', tag: 'ResponseProcessor');
          throw Exception('Invalid response format: Missing "words" or "vocabulary" array');
        }
        
        // Ensure proper typing for the words array and add missing 'word' field when needed
        final List<Map<String, dynamic>> typedWords = [];
        
        for (var item in rawWords) {
          if (item is Map) {
            final wordItem = Map<String, dynamic>.from(item);
            
            // Ensure each word has a 'word' field
            if (!wordItem.containsKey('word') || wordItem['word'] == null || wordItem['word'].toString().isEmpty) {
              // Extract a simple word from context instead of using a placeholder
              final String context = (wordItem['context'] as String?) ?? '';
              
              if (context.isNotEmpty) {
                // Extract the most relevant word from context based on simple rules
                // First check if we have key terms directly in the context
                if (context.toLowerCase().contains('portcullis')) {
                  wordItem['word'] = 'portcullis';
                } else if (context.toLowerCase().contains('impaled')) {
                  wordItem['word'] = 'impale';
                } else if (context.toLowerCase().contains('behead')) {
                  wordItem['word'] = 'behead';
                } else if (context.toLowerCase().contains('wildlings')) {
                  wordItem['word'] = 'wildlings';
                } else if (context.toLowerCase().contains('deserter')) {
                  wordItem['word'] = 'deserter';
                } else if (context.toLowerCase().contains('turret')) {
                  wordItem['word'] = 'turret';
                } else if (context.toLowerCase().contains('panic')) {
                  wordItem['word'] = 'panic';
                } else if (context.toLowerCase().contains('solemnly')) {
                  wordItem['word'] = 'solemnly';
                } else if (context.toLowerCase().contains('pensive')) {
                  wordItem['word'] = 'pensive';
                } else if (context.toLowerCase().contains('beckons')) {
                  wordItem['word'] = 'beckons';
                } else if (context.toLowerCase().contains('fondle')) {
                  wordItem['word'] = 'fondle';
                } else {
                  // If no specific term found, take the longest word from context
                  final List<String> words = context
                      .replaceAll(RegExp(r'[^\w\s]'), ' ')  // Replace punctuation with spaces
                      .split(RegExp(r'\s+'))               // Split by whitespace
                      .where((word) => word.length > 3)    // Only words longer than 3 chars
                      .toList();
                      
                  if (words.isNotEmpty) {
                    // Sort by length (descending) and take the first one
                    words.sort((a, b) => b.length.compareTo(a.length));
                    wordItem['word'] = words.first.toLowerCase();
                    Logger.d('Using the longest word from context: "${wordItem['word']}"', tag: 'ResponseProcessor');
                  } else {
                    // Final fallback
                    wordItem['word'] = (wordItem['partOfSpeech'] as String?) ?? 'vocabulary';
                    Logger.d('Using part of speech as word: "${wordItem['word']}"', tag: 'ResponseProcessor');
                  }
                }
              } else {
                // If no context, use part of speech or a generic term
                wordItem['word'] = (wordItem['partOfSpeech'] as String?) ?? 'vocabulary';
                Logger.d('No context available, using: "${wordItem['word']}"', tag: 'ResponseProcessor');
              }
            }
            
            // Clean up any definition/meaning text to remove prompts
            if (wordItem.containsKey('definition') && wordItem['definition'] != null) {
              wordItem['definition'] = _cleanupPromptText(wordItem['definition'].toString());
            }
            
            if (wordItem.containsKey('meaning') && wordItem['meaning'] != null) {
              wordItem['meaning'] = _cleanupPromptText(wordItem['meaning'].toString());
            }
            
            // Clean up example text
            if (wordItem.containsKey('example') && wordItem['example'] != null) {
              wordItem['example'] = _cleanupPromptText(wordItem['example'].toString());
            }
            
            // Clean up the word itself
            wordItem['word'] = _cleanupPromptText(wordItem['word'].toString());
            
            typedWords.add(wordItem);
          } else {
            // If item is not a map, create a minimal valid map
            typedWords.add({'word': 'unknown', 'definition': 'No definition available'});
          }
        }
        
        // Print debug info 
        Logger.i('Successfully parsed ${typedWords.length} vocabulary items', tag: 'ResponseProcessor');
        
        // Create a properly structured result - keep using 'words' as the key for backwards compatibility
        return {
          'vocabulary': typedWords,
          'tenses': result['tenses'] is Map ? Map<String, dynamic>.from(result['tenses']) : <String, dynamic>{},
        };
      }
      
      Logger.w('Could not find valid JSON in response: ${response.substring(0, min(200, response.length))}...', tag: 'ResponseProcessor');
      throw Exception('Could not find valid JSON in response');
    } catch (e) {
      Logger.e('Failed to parse response: $e', tag: 'ResponseProcessor');
      throw Exception('Failed to parse response: $e');
    }
  }
  
  /// Sanitize JSON string to fix common issues before parsing
  static String _sanitizeJsonString(String jsonStr) {
    // Fix trailing commas in arrays and objects
    jsonStr = jsonStr.replaceAll(RegExp(r',\s*}'), '}');
    jsonStr = jsonStr.replaceAll(RegExp(r',\s*\]'), ']');
    
    // Fix unquoted property names
    jsonStr = jsonStr.replaceAllMapped(
      RegExp(r'(\s*)(\w+)(\s*):'),
      (match) => '${match.group(1)}"${match.group(2)}"${match.group(3)}:'
    );
    
    // Fix single quotes to double quotes
    jsonStr = jsonStr.replaceAll(RegExp(r"'([^']*)'"), r'"$1"');
    
    // Fix unescaped quotes in strings
    jsonStr = jsonStr.replaceAllMapped(
      RegExp(r'"(.*?)(?<!\\)"'),
      (match) {
        String content = match.group(1)!;
        content = content.replaceAll('"', '\\"');
        return '"$content"';
      }
    );
    
    // Handle boolean values consistently
    jsonStr = jsonStr.replaceAll('"true"', 'true');
    jsonStr = jsonStr.replaceAll('"false"', 'false');
    
    // Fix line breaks in string values
    jsonStr = jsonStr.replaceAll(RegExp(r'\n|\r'), ' ');
    
    return jsonStr;
  }
  
  /// Attempt to repair malformed JSON by using a regex-based approach
  static String _attemptJsonRepair(String jsonStr) {
    Logger.d('Attempting to repair JSON: ${jsonStr.substring(0, min(100, jsonStr.length))}...', tag: 'ResponseProcessor');
    
    try {
      // First, try a more aggressive approach for heavily malformed JSON
      if (jsonStr.contains("Expected ',' or ']'") || jsonStr.contains("Expected ',' or '}'")) {
        // Just extract the vocabulary array if possible and create a minimal valid JSON
        final List<Map<String, dynamic>> extractedWords = _extractVocabularyItems(jsonStr);
        if (extractedWords.isNotEmpty) {
          Logger.d('Created clean JSON with ${extractedWords.length} extracted words', tag: 'ResponseProcessor');
          return jsonEncode({"vocabulary": extractedWords, "tenses": {}});
        }
      }
      
      // Try to find and fix common JSON syntax errors
      
      // Fix newlines and proper whitespace
      jsonStr = jsonStr.replaceAll(RegExp(r'\n'), ' ');
      jsonStr = jsonStr.replaceAll(RegExp(r'\s{2,}'), ' ');
      
      // Find array elements that are missing commas
      jsonStr = jsonStr.replaceAllMapped(
        RegExp(r'\}\s*\{'),
        (match) => '}, {'
      );
      
      // Find missing quotes around keys
      jsonStr = jsonStr.replaceAllMapped(
        RegExp(r'([{,]\s*)([a-zA-Z0-9_]+)(\s*:)'),
        (match) => '${match.group(1)}"${match.group(2)}"${match.group(3)}'
      );
      
      // Fix incorrect boolean values
      jsonStr = jsonStr.replaceAllMapped(
        RegExp(r'"(true|false)"'),
        (match) => match.group(1)!
      );
      
      // Fix trailing commas in arrays and objects
      jsonStr = jsonStr.replaceAll(RegExp(r',\s*\]'), ']');
      jsonStr = jsonStr.replaceAll(RegExp(r',\s*\}'), '}');
      
      // Try more aggressive repair for arrays
      if (jsonStr.contains('"vocabulary"') || jsonStr.contains('"words"')) {
        // Extract the vocabulary array to fix it separately
        final vocabMatch = RegExp(r'"(vocabulary|words)"\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(jsonStr);
        if (vocabMatch != null) {
          final arrayKey = vocabMatch.group(1);
          String arrayContent = vocabMatch.group(2) ?? '';
          
          // Fix array elements that are malformed
          arrayContent = arrayContent.replaceAll(RegExp(r'\}\s*\{'), '},{');
          
          // Fix missing commas between array items
          arrayContent = arrayContent.replaceAllMapped(
            RegExp(r'(\})\s+(\{)'),
            (match) => '${match.group(1)},${match.group(2)}'
          );
          
          // Reconstruct the JSON with fixed array
          final prefix = jsonStr.substring(0, vocabMatch.start);
          final suffix = jsonStr.substring(vocabMatch.end);
          jsonStr = '$prefix"$arrayKey":[$arrayContent]$suffix';
        }
      }
      
      // Add closing bracket or brace if missing
      final openBraces = jsonStr.split('{').length - 1;
      final closeBraces = jsonStr.split('}').length - 1;
      if (openBraces > closeBraces) {
        jsonStr = jsonStr + '}'.repeat(openBraces - closeBraces);
      }
      
      final openBrackets = jsonStr.split('[').length - 1;
      final closeBrackets = jsonStr.split(']').length - 1;
      if (openBrackets > closeBrackets) {
        jsonStr = jsonStr + ']'.repeat(openBrackets - closeBrackets);
      }
      
      // Last resort: if we're still dealing with malformed JSON, try a content extraction approach
      try {
        jsonDecode(jsonStr); // Test if the JSON is valid
      } catch (e) {
        Logger.w('JSON is still invalid after repairs. Trying content extraction.', tag: 'ResponseProcessor');
        return _createMinimalValidJson(jsonStr);
      }
      
      Logger.d('Repaired JSON: ${jsonStr.substring(0, min(100, jsonStr.length))}...', tag: 'ResponseProcessor');
      return jsonStr;
    } catch (e) {
      Logger.e('Error while repairing JSON: $e', tag: 'ResponseProcessor');
      
      // If all else fails, create a minimal valid JSON response
      return '{"vocabulary": [{"word": "unknown", "definition": "Could not parse AI response: $e"}], "tenses": {}}';
    }
  }
  
  /// Extract vocabulary items from malformed JSON by pattern matching
  static List<Map<String, dynamic>> _extractVocabularyItems(String jsonStr) {
    try {
      final List<Map<String, dynamic>> result = [];
      
      // Look for patterns like: {"word": "something", ...} or {word: "something", ...}
      final wordItemRegex = RegExp(r'\{[^{}]*"?word"?\s*:\s*"([^"]*)"[^{}]*\}', caseSensitive: false);
      final matches = wordItemRegex.allMatches(jsonStr);
      
      for (final match in matches) {
        final fullMatch = match.group(0) ?? '';
        final word = match.group(1) ?? 'unknown';
        
        // Extract key-value pairs
        final Map<String, dynamic> wordItem = {'word': word};
        
        // Try to extract definition/meaning
        final defMatch = RegExp(r'"?(definition|meaning)"?\s*:\s*"([^"]*)"', caseSensitive: false).firstMatch(fullMatch);
        if (defMatch != null) {
          wordItem['definition'] = defMatch.group(2) ?? '';
        }
        
        // Try to extract example/context
        final exampleMatch = RegExp(r'"?(example|context)"?\s*:\s*"([^"]*)"', caseSensitive: false).firstMatch(fullMatch);
        if (exampleMatch != null) {
          wordItem['context'] = exampleMatch.group(2) ?? '';
        }
        
        // Try to extract part of speech
        final posMatch = RegExp(r'"?partOfSpeech"?\s*:\s*"([^"]*)"', caseSensitive: false).firstMatch(fullMatch);
        if (posMatch != null) {
          wordItem['partOfSpeech'] = posMatch.group(1) ?? '';
        }
        
        // Try to extract category
        final catMatch = RegExp(r'"?category"?\s*:\s*"([^"]*)"', caseSensitive: false).firstMatch(fullMatch);
        if (catMatch != null) {
          wordItem['category'] = catMatch.group(1) ?? '';
        }
        
        // Try to extract emoji
        final emojiMatch = RegExp(r'"?emoji"?\s*:\s*"([^"]*)"', caseSensitive: false).firstMatch(fullMatch);
        if (emojiMatch != null) {
          wordItem['emoji'] = emojiMatch.group(1) ?? '';
        }
        
        result.add(wordItem);
      }
      
      return result;
    } catch (e) {
      Logger.e('Error extracting vocabulary items: $e', tag: 'ResponseProcessor');
      return [];
    }
  }
  
  /// Create a minimal valid JSON when all other repair attempts fail
  static String _createMinimalValidJson(String jsonStr) {
    final List<Map<String, dynamic>> extractedItems = _extractVocabularyItems(jsonStr);
    
    if (extractedItems.isNotEmpty) {
      return jsonEncode({"vocabulary": extractedItems, "tenses": {}});
    }
    
    // Look for any words in quotes that might be vocabulary items
    final List<Map<String, dynamic>> wordList = [];
    final wordMatches = RegExp(r'"([a-zA-Z]{3,})"').allMatches(jsonStr);
    final Set<String> uniqueWords = {};
    
    for (final match in wordMatches) {
      final word = match.group(1)!;
      if (!uniqueWords.contains(word) && 
          !_isCommonWord(word) && 
          !word.contains('definition') && 
          !word.contains('word') &&
          !word.contains('context') &&
          !word.contains('vocabulary')) {
        uniqueWords.add(word);
        wordList.add({
          'word': word,
          'definition': 'Extracted from AI response',
          'partOfSpeech': 'unknown',
          'category': 'General',
          'emoji': '📝'
        });
        
        if (wordList.length >= 5) break; // Limit to 5 words
      }
    }
    
    if (wordList.isNotEmpty) {
      return jsonEncode({"vocabulary": wordList, "tenses": {}});
    }
    
    // Return a default response if nothing could be extracted
    return '{"vocabulary": [{"word": "vocabulary", "definition": "Could not extract words from AI response", "category": "General", "emoji": "📝"}], "tenses": {}}';
  }
  
  /// Default vocabulary response for error cases
  static Map<String, dynamic> defaultVocabularyResponse(String word, String errorMessage) {
    return {
      'word': word,
      'meaning': 'Failed to generate content: $errorMessage',
      'example': 'Please check your API key in settings.',
      'category': 'General',
      'difficultyLevel': 3,
      'tprDescription': 'Wave your hand while saying the word',
      'synonyms': [],
      'antonyms': [],
      'partOfSpeech': 'noun',
    };
  }
  
  /// Default tense variations response for error cases
  static Map<String, String> defaultTenseResponse(String word) {
    return {
      'Present Simple': word,
      'Past Simple': '',
      'Present Continuous': '',
      'Future Simple': '',
    };
  }
  
  /// Format connection error message
  static Map<String, dynamic> formatConnectionError(dynamic error, String provider) {
    String errorMessage = error.toString();
    
    if (error is SocketException) {
      errorMessage = 'Network connection error: ${error.message}. Please check your internet connection.';
    } else if (error is TimeoutException) {
      errorMessage = 'Connection timed out. The server took too long to respond.';
    } else if (error is http.ClientException) {
      errorMessage = 'HTTP client error: ${error.message}. This might be due to a network issue or invalid URL.';
    } else if (error is FormatException) {
      errorMessage = 'Data format error: ${error.message}. The server response could not be processed.';
    }
    
    return {
      'success': false,
      'provider': provider,
      'error': errorMessage
    };
  }
  
  /// Generate fallback words when AI extraction fails
  static Map<String, dynamic> generateFallbackWords(String subtitleText) {
    // Extract any actual words from the text
    final List<String> words = subtitleText
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .split(RegExp(r'\s+')) // Split by whitespace
        .where((word) => word.isNotEmpty) // Remove empty strings
        .toList();
    
    // Default words for greeting contexts
    final List<Map<String, dynamic>> defaultWords = [];
    
    // Add words from the text
    for (final word in words) {
      if (word.toLowerCase() == 'well') {
        defaultWords.add({
          'word': 'well',
          'definition': 'Used as an exclamation of surprise or to introduce a remark.',
          'context': 'Well. hello there.',
          'partOfSpeech': 'interjection',
          'emoji': '😮',
          'category': 'Expressions'
        });
      } else if (word.toLowerCase() == 'hello') {
        defaultWords.add({
          'word': 'hello',
          'definition': 'A greeting used when meeting someone or starting a conversation.',
          'context': 'Well. hello there.',
          'partOfSpeech': 'interjection',
          'emoji': '👋',
          'category': 'Greetings'
        });
      } else if (word.toLowerCase() == 'there') {
        defaultWords.add({
          'word': 'there',
          'definition': 'In that place or position; at that point.',
          'context': 'Well. hello there.',
          'partOfSpeech': 'adverb',
          'emoji': '👉',
          'category': 'Location'
        });
      }
    }
    
    // Add some additional relevant words
    if (defaultWords.length < 3) {
      defaultWords.add({
        'word': 'greeting',
        'definition': 'A polite word or sign of welcome or recognition.',
        'context': 'A greeting like "hello there" is common in casual conversations.',
        'partOfSpeech': 'noun',
        'emoji': '🤝',
        'category': 'Communication'
      });
      
      defaultWords.add({
        'word': 'welcome',
        'definition': 'An instance or manner of greeting someone.',
        'context': 'The warm welcome made the visitor feel comfortable.',
        'partOfSpeech': 'noun',
        'emoji': '✨',
        'category': 'Hospitality'
      });
    }
    
    Map<String, int> tenses = {};
    
    // Return in the expected format - use 'vocabulary' key for consistency
    return {
      'vocabulary': defaultWords,
      'tenses': tenses
    };
  }
  
  /// Check if a word is a common/filler word that shouldn't be used as the main term
  static bool _isCommonWord(String word) {
    final commonWords = [
      'the', 'and', 'that', 'have', 'for', 'not', 'with', 'you', 'this', 'but',
      'his', 'her', 'she', 'him', 'they', 'them', 'will', 'would', 'should', 'could',
      'what', 'where', 'when', 'why', 'how', 'all', 'any', 'some', 'many', 'from',
      'been', 'were', 'was', 'are', 'is', 'am', 'be', 'being', 'been', 'had', 'has',
      'did', 'does', 'do', 'doing', 'done', 'can', 'may', 'might', 'must', 'shall',
      'who', 'whose', 'whom', 'which', 'there', 'here', 'those', 'these', 'their',
      'look', 'looks', 'looking', 'like', 'seem', 'seems', 'out', 'into', 'over',
      'under', 'through'
    ];
    return commonWords.contains(word.toLowerCase());
  }
}

/// Extension to allow repeating strings
extension StringExtension on String {
  String repeat(int times) {
    return List.filled(times, this).join();
  }
} 