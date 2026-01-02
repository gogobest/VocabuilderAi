import 'package:visual_vocabularies/core/utils/ai_service.dart';
import 'package:visual_vocabularies/core/utils/ai_word_generator.dart';

import 'package:visual_vocabularies/core/di/injection_container.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:visual_vocabularies/features/vocabulary/data/services/vocabulary_image_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:visual_vocabularies/core/utils/secure_storage_service.dart';
import 'dart:math' as math;
import 'package:visual_vocabularies/core/utils/ai/provider_factory.dart';
import 'package:visual_vocabularies/core/utils/ai/ai_provider_interface.dart';
import 'package:visual_vocabularies/core/utils/ai/models/prompt_type.dart';

/// Service for handling AI-based vocabulary generation and enhancements
class VocabularyAiService {
  static final VocabularyAiService _instance = VocabularyAiService._internal();
  final AiService _aiService = sl<AiService>();
  final AiWordGenerator _aiWordGenerator = const AiWordGenerator();
  final SecureStorageService _secureStorage = sl<SecureStorageService>();
  final VocabularyImageService _imageService = sl<VocabularyImageService>();


  /// Factory constructor to return the singleton instance
  factory VocabularyAiService() {
    return _instance;
  }

  VocabularyAiService._internal();

  /// Generate a complete vocabulary item using AI
  Future<Map<String, dynamic>> generateVocabularyItem(String word) async {
    try {
      // Call AiService with just the word, so the improved prompt template is used
      final result = await _aiService.generateVocabularyItem(word);
      
      // Suggest an appropriate category based on the meaning
      if (result.containsKey('meaning')) {
        final suggestedCategory = _suggestCategory(
          word, 
          result['meaning'] as String
        );
        
        if (suggestedCategory != null) {
          result['category'] = suggestedCategory;
        }
      }
      
      // Check for words with multiple possible parts of speech
      _checkForMultiplePartsOfSpeech(word, result);
      
      return result;
    } catch (e) {
      return _createFallbackVocabularyItem(word, e.toString());
    }
  }

  /// Suggest an appropriate category based on word and meaning
  String? _suggestCategory(String word, String meaning) {
    final lowercaseWord = word.toLowerCase();
    final lowercaseMeaning = meaning.toLowerCase();
    
    // Enhanced categorical ontology - mapping concepts to their existential contexts
    // Focus on materialist categories that help with visualization
    final Map<String, Map<String, List<String>>> ontology = {
      'Food': {
        'existence': ['food', 'eat', 'meal', 'taste', 'cuisine', 'cook', 'dish', 'flavor', 'nutrition'],
        'locations': ['kitchen', 'restaurant', 'cafe', 'bakery', 'market', 'grocery', 'pantry', 'table'],
        'objects': ['fruit', 'vegetable', 'meat', 'dessert', 'snack', 'recipe', 'ingredient', 'spice', 'herb', 'breakfast', 'lunch', 'dinner'],
        'activities': ['cook', 'bake', 'grill', 'fry', 'boil', 'simmer', 'roast', 'taste', 'chew', 'dine', 'swallow'],
        'concrete_examples': ['apple', 'banana', 'steak', 'bread', 'pizza', 'pasta', 'cake', 'cheese', 'coffee', 'tea', 'wine']
      },
      'Travel': {
        'existence': ['travel', 'journey', 'trip', 'tour', 'voyage', 'expedition', 'tourism', 'vacation'],
        'locations': ['hotel', 'airport', 'station', 'destination', 'resort', 'beach', 'mountain', 'countryside', 'city', 'landmark'],
        'objects': ['map', 'suitcase', 'luggage', 'passport', 'ticket', 'camera', 'souvenir', 'backpack', 'guidebook'],
        'activities': ['visit', 'explore', 'book', 'plan', 'tour', 'hike', 'navigate', 'photograph', 'drive', 'fly', 'sail'],
        'concrete_examples': ['paris', 'tokyo', 'hotel', 'flight', 'cruise', 'vacation', 'safari', 'hiking', 'camping', 'sightseeing']
      },
      'Sports': {
        'existence': ['sport', 'athletic', 'game', 'competition', 'tournament', 'match', 'championship', 'physical activity'],
        'locations': ['field', 'court', 'stadium', 'arena', 'gym', 'track', 'pool', 'rink', 'pitch'],
        'objects': ['ball', 'racket', 'goal', 'team', 'medal', 'trophy', 'equipment', 'uniform', 'scoreboard', 'referee'],
        'activities': ['play', 'train', 'compete', 'win', 'lose', 'score', 'exercise', 'practice', 'coach', 'race'],
        'concrete_examples': ['football', 'soccer', 'tennis', 'basketball', 'swimming', 'running', 'golf', 'baseball', 'volleyball', 'hockey']
      },
      'Technology': {
        'existence': ['digital', 'electronic', 'virtual', 'online', 'cyber', 'tech', 'innovation', 'gadget'],
        'locations': ['internet', 'cloud', 'website', 'platform', 'network', 'server', 'database', 'device', 'lab'],
        'objects': ['computer', 'smartphone', 'tablet', 'software', 'hardware', 'app', 'program', 'code', 'interface', 'screen'],
        'activities': ['program', 'code', 'develop', 'design', 'compute', 'process', 'browse', 'download', 'upload', 'install'],
        'concrete_examples': ['laptop', 'iphone', 'app', 'wifi', 'bluetooth', 'usb', 'website', 'email', 'google', 'facebook', 'twitter']
      },
      'Business': {
        'existence': ['business', 'corporate', 'commercial', 'professional', 'organization', 'enterprise', 'industry'],
        'locations': ['office', 'workplace', 'company', 'corporation', 'firm', 'enterprise', 'headquarters', 'branch'],
        'objects': ['money', 'contract', 'product', 'service', 'profit', 'report', 'investment', 'budget', 'market', 'client'],
        'activities': ['work', 'hire', 'manage', 'sell', 'buy', 'invest', 'market', 'negotiate', 'present', 'plan', 'strategize'],
        'concrete_examples': ['meeting', 'deadline', 'presentation', 'payroll', 'marketing', 'sales', 'ceo', 'manager', 'employee', 'startup']
      },
      'Health': {
        'existence': ['health', 'medical', 'wellbeing', 'fitness', 'disease', 'condition', 'therapy', 'treatment'],
        'locations': ['hospital', 'clinic', 'pharmacy', 'doctor\'s office', 'gym', 'spa', 'laboratory'],
        'objects': ['medicine', 'drug', 'pill', 'treatment', 'diagnosis', 'symptom', 'prescription', 'vaccine', 'equipment'],
        'activities': ['exercise', 'diagnose', 'heal', 'recover', 'prescribe', 'operate', 'treat', 'meditate', 'stretch'],
        'concrete_examples': ['headache', 'surgery', 'vitamin', 'checkup', 'diagnosis', 'prescription', 'recovery', 'symptoms', 'therapy']
      },
      'Arts': {
        'existence': ['art', 'creative', 'artistic', 'expression', 'aesthetic', 'beauty', 'visual', 'craft'],
        'locations': ['gallery', 'museum', 'studio', 'theater', 'stage', 'concert hall', 'exhibition', 'workshop'],
        'objects': ['painting', 'sculpture', 'music', 'dance', 'film', 'photograph', 'instrument', 'performance', 'novel', 'poem'],
        'activities': ['paint', 'draw', 'compose', 'perform', 'act', 'direct', 'design', 'write', 'play', 'sing', 'dance'],
        'concrete_examples': ['piano', 'ballet', 'novel', 'concert', 'gallery', 'museum', 'painter', 'actor', 'musician', 'sculptor']
      },
      'Nature': {
        'existence': ['nature', 'natural', 'environment', 'ecology', 'biological', 'organic', 'ecosystem', 'wilderness'],
        'locations': ['forest', 'beach', 'mountain', 'river', 'lake', 'ocean', 'desert', 'park', 'garden', 'jungle'],
        'objects': ['tree', 'flower', 'plant', 'animal', 'rock', 'water', 'soil', 'landscape', 'weather', 'climate'],
        'activities': ['grow', 'bloom', 'hibernate', 'migrate', 'adapt', 'evolve', 'conserve', 'preserve', 'pollinate'],
        'concrete_examples': ['forest', 'river', 'mountain', 'tree', 'flower', 'weather', 'season', 'plant', 'animal', 'climate']
      },
      'Education': {
        'existence': ['education', 'academic', 'learning', 'teaching', 'knowledge', 'study', 'schooling', 'training'],
        'locations': ['school', 'university', 'college', 'classroom', 'library', 'campus', 'academy', 'institute'],
        'objects': ['book', 'textbook', 'course', 'class', 'lecture', 'exam', 'assignment', 'curriculum', 'degree', 'qualification'],
        'activities': ['learn', 'teach', 'study', 'read', 'write', 'research', 'graduate', 'educate', 'train', 'lecture'],
        'concrete_examples': ['student', 'teacher', 'classroom', 'homework', 'lecture', 'exam', 'lesson', 'degree', 'textbook', 'library']
      }
    };
    
    // Extract key contextual words from the meaning to help determine category
    final contextWords = lowercaseMeaning.split(RegExp(r'[.,;: ]'))
        .where((word) => word.length > 3)  // Only consider words longer than 3 characters
        .where((word) => !['this', 'that', 'then', 'than', 'with', 'also', 'when', 'which', 'there', 'these', 'those', 'about', 'because', 'refers', 'something', 'someone'].contains(word))  // Exclude common stop words
        .toList();
    
    // Consider the word itself as a strong context clue
    contextWords.add(lowercaseWord);
    
    // Calculate scores for each category based on exact matches and approximate matches
    final Map<String, int> categoryScores = {};
    final List<String> highWeightTerms = [];
    
    for (final category in ontology.keys) {
      int score = 0;
      final categoryOntology = ontology[category]!;
      
      // First, check if the word itself is a concrete example
      if (categoryOntology['concrete_examples']!.contains(lowercaseWord)) {
        score += 15; // Very high weight for direct concrete example matches
        highWeightTerms.add('$lowercaseWord (word is concrete example for $category)');
      }
      
      // If the word appears in any other ontology entries, give points
      for (final aspect in categoryOntology.keys) {
        if (aspect != 'concrete_examples' && categoryOntology[aspect]!.contains(lowercaseWord)) {
          score += 10; // High weight for word match in other ontology aspects
          highWeightTerms.add('$lowercaseWord (word matches $aspect for $category)');
        }
      }
      
      // Check for direct matches with the meaning
      for (final contextWord in contextWords) {
        // Check concrete examples first (highest weight)
        if (categoryOntology['concrete_examples']!.contains(contextWord)) {
          score += 12;
          highWeightTerms.add('$contextWord (concrete example for $category)');
        }
        
        // Check objects (high weight)
        if (categoryOntology['objects']!.contains(contextWord)) {
          score += 10;
          highWeightTerms.add('$contextWord (object for $category)');
        }
        
        // Check activities (medium-high weight)
        if (categoryOntology['activities']!.contains(contextWord)) {
          score += 8;
          highWeightTerms.add('$contextWord (activity for $category)');
        }
        
        // Check locations (medium weight)
        if (categoryOntology['locations']!.contains(contextWord)) {
          score += 6;
          highWeightTerms.add('$contextWord (location for $category)');
        }
        
        // Check existence (medium-low weight)
        if (categoryOntology['existence']!.contains(contextWord)) {
          score += 4;
          highWeightTerms.add('$contextWord (existence term for $category)');
        }
        
        // Check for word similarity (substring matches) for partial matches
        for (final aspect in categoryOntology.keys) {
          for (final keyword in categoryOntology[aspect]!) {
            // If the keyword contains our word or vice versa, it's a partial match
            if ((contextWord.length > 3 && keyword.contains(contextWord)) || 
                (keyword.length > 3 && contextWord.contains(keyword))) {
              score += 2; // Lower weight for partial matches
            }
          }
        }
      }
      
      // Also check if the meaning as a whole contains key category terms
      for (final aspect in categoryOntology.keys) {
        for (final keyword in categoryOntology[aspect]!) {
          if (lowercaseMeaning.contains(keyword)) {
            score += 3; // Medium-low weight for meaning containing the term
          }
        }
      }
      
      categoryScores[category] = score;
    }
    
    // Find the category with the highest score
    String? bestCategory;
    int highestScore = 0;
    
    debugPrint('Word: "$word" with meaning: "$meaning"');
    debugPrint('Context words extracted: ${contextWords.join(", ")}');
    if (highWeightTerms.isNotEmpty) {
      debugPrint('High weight terms: ${highWeightTerms.join(", ")}');
    }
    
    for (final entry in categoryScores.entries) {
      debugPrint('Category ${entry.key}: ${entry.value}');
      if (entry.value > highestScore) {
        highestScore = entry.value;
        bestCategory = entry.key;
      }
    }
    
    // If we have a clear winner with score > 0, return it
    if (bestCategory != null && highestScore > 3) {
      debugPrint('Selected category: $bestCategory (score: $highestScore)');
      return bestCategory;
    }
    
    // Try to infer from just the word using some common patterns
    // Check common patterns in the word itself that might suggest a category
    if (_isColor(lowercaseWord)) {
      debugPrint('Word appears to be a color, using Arts category');
      return 'Arts';
    } else if (lowercaseWord.contains('food') || lowercaseWord.contains('eat') || 
               lowercaseWord.endsWith('berry') || lowercaseWord.endsWith('fruit')) {
      debugPrint('Word pattern suggests Food category');
      return 'Food';
    } else if (lowercaseWord.contains('tech') || lowercaseWord.endsWith('ware') || 
               lowercaseWord.contains('computer') || lowercaseWord.contains('digital')) {
      debugPrint('Word pattern suggests Technology category');
      return 'Technology';
    } else if (lowercaseWord.contains('sport') || lowercaseWord.contains('game') || 
               lowercaseWord.contains('play') || lowercaseWord.contains('ball')) {
      debugPrint('Word pattern suggests Sports category');
      return 'Sports';
    }
    
    // Use the default "General" category as fallback
    debugPrint('No clear category match, using default "General"');
    return 'General';
  }
  
  /// Extract existential context from the meaning
  List<String> _extractExistentialContext(String meaning) {
    final List<String> contextWords = [];
    final contextPatterns = [
      // Where something exists
      RegExp(r'found in ([\w\s]+)'),
      RegExp(r'located in ([\w\s]+)'),
      RegExp(r'exists in ([\w\s]+)'),
      RegExp(r'present in ([\w\s]+)'),
      RegExp(r'seen in ([\w\s]+)'),
      RegExp(r'associated with ([\w\s]+)'),
      RegExp(r'related to ([\w\s]+)'),
      RegExp(r'used in ([\w\s]+)'),
      RegExp(r'part of ([\w\s]+)'),
      RegExp(r'belongs to ([\w\s]+)'),
      RegExp(r'lives in ([\w\s]+)'),
      RegExp(r'resides in ([\w\s]+)'),
      RegExp(r'occurs in ([\w\s]+)'),
      RegExp(r'grows in ([\w\s]+)'),
      RegExp(r'made of ([\w\s]+)'),
      RegExp(r'produced by ([\w\s]+)'),
    ];
    
    for (final pattern in contextPatterns) {
      final matches = pattern.allMatches(meaning);
      for (final match in matches) {
        if (match.groupCount >= 1) {
          final contextPhrase = match.group(1)?.toLowerCase().trim();
          if (contextPhrase != null && contextPhrase.isNotEmpty) {
            // Extract key nouns from the phrase
            final words = contextPhrase.split(' ');
            for (final word in words) {
              final trimmedWord = word.replaceAll(RegExp(r'[^\w\s]'), '').trim();
              if (trimmedWord.length > 3) {  // Ignore short words like "the", "and", etc.
                contextWords.add(trimmedWord);
              }
            }
          }
        }
      }
    }
    
    return contextWords;
  }
  
  /// Check if a word is a color
  bool _isColor(String word) {
    final colors = [
      'red', 'blue', 'green', 'yellow', 'orange', 'purple', 'pink', 'brown', 
      'black', 'white', 'gray', 'silver', 'gold', 'beige', 'teal', 'cyan', 
      'magenta', 'turquoise', 'violet', 'indigo', 'maroon', 'olive', 'navy',
      'aqua', 'azure', 'crimson', 'fuchsia', 'lime', 'plum', 'sapphire'
    ];
    
    return colors.contains(word);
  }
  
  /// Count occurrences of a substring in a string
  int _countOccurrences(String text, String pattern) {
    // Simple word boundary check to avoid partial matches
    final regex = RegExp('\\b$pattern\\b', caseSensitive: false);
    return regex.allMatches(text).length;
  }

  /// Generate example sentence for a word
  Future<String> generateExample(String word, String meaning) async {
    try {
      // Implement direct generation if AiService doesn't have this method
      final result = await _generateExampleDirectly(word, meaning);
      return result;
    } catch (e) {
      return 'Example could not be generated.';
    }
  }

  /// Generate meaning for a word
  Future<String> generateMeaning(String word) async {
    try {
      // Implement direct generation if AiService doesn't have this method
      final result = await _generateMeaningDirectly(word);
      return result;
    } catch (e) {
      return 'Meaning could not be generated.';
    }
  }

  /// Generate tense variations for a word
  Future<Map<String, String>> generateTenseVariations(String word) async {
    try {
      return await _aiService.generateTenseVariations(word);
    } catch (e) {
      return {
        'Present Simple': word,
        'Past Simple': '',
        'Present Continuous': '',
        'Future Simple': '',
      };
    }
  }



  /// Generate random vocabulary word
  Future<String> generateRandomWord() async {
    try {
      // Simple implementation with common words
      final commonWords = [
        'apple', 'book', 'cat', 'dog', 'elephant', 'friend', 'garden',
        'house', 'internet', 'journey', 'knowledge', 'language', 'mountain',
        'nature', 'ocean', 'people', 'question', 'river', 'summer', 'travel'
      ];
      
      // Pick a random word from the list
      final random = DateTime.now().millisecondsSinceEpoch % commonWords.length;
      return commonWords[random];
    } catch (e) {
      return 'hello'; // Fallback to a simple word
    }
  }

  /// Create a fallback vocabulary item when AI generation fails
  Map<String, dynamic> _createFallbackVocabularyItem(String word, String errorMessage) {
    return {
      'word': word,
      'meaning': 'Failed to generate content: $errorMessage',
      'example': 'Please check your API key in settings.',
      'category': 'General',
      'difficultyLevel': 3,
      'emoji': '❓',
      'synonyms': <String>[],
      'antonyms': <String>[],
      'partOfSpeech': 'noun'
    };
  }
  
  /// Generate example directly if AiService doesn't support it
  Future<String> _generateExampleDirectly(String word, String meaning) async {
    // Simple examples based on word patterns
    if (word.endsWith('ing')) {
      return 'I enjoy $word every day.';
    } else if (word.endsWith('ly')) {
      return 'She spoke $word during the presentation.';
    } else if (word.endsWith('er') || word.endsWith('or')) {
      return 'The $word helped us solve the problem.';
    } else {
      return 'We discussed $word in our last meeting.';
    }
  }
  
  /// Generate meaning directly if AiService doesn't support it
  Future<String> _generateMeaningDirectly(String word) async {
    return 'A term related to $word, often used in various contexts.';
  }

  /// Check if a word can have multiple parts of speech and add that information to the result
  void _checkForMultiplePartsOfSpeech(String word, Map<String, dynamic> result) {
    final String lowercaseWord = word.toLowerCase();
    
    // "-ing" words can often be both nouns and verbs (present participle)
    if (lowercaseWord.endsWith('ing')) {
      // Determine the base verb form (removing 'ing')
      String baseVerb = lowercaseWord;
      if (lowercaseWord.endsWith('ing')) {
        if (lowercaseWord.endsWith('ying') && lowercaseWord.length > 4) {
          // For words like "flying" -> "fly"
          baseVerb = lowercaseWord.substring(0, lowercaseWord.length - 4) + 'y';
        } else if (lowercaseWord.endsWith('pping') || 
                   lowercaseWord.endsWith('tting') || 
                   lowercaseWord.endsWith('nning')) {
          // For words with doubled consonant before "ing": "running" -> "run"
          baseVerb = lowercaseWord.substring(0, lowercaseWord.length - 4);
        } else if (lowercaseWord.endsWith('eing')) {
          // For words like "seeing" -> "see"
          baseVerb = lowercaseWord.substring(0, lowercaseWord.length - 3);
        } else {
          // Regular form: "writing" -> "write"
          baseVerb = lowercaseWord.substring(0, lowercaseWord.length - 3);
          // Handle 'e' that was dropped: "writing" came from "write"
          if (_shouldAddEToBaseVerb(baseVerb)) {
            baseVerb += 'e';
          }
        }
      }
      
      // Add note about multiple parts of speech
      result['partOfSpeechNote'] = 'This word can function as both a noun and a verb (present participle)';
      
      // Create alternative meanings if they don't exist
      Map<String, String> alternateMeanings = {};
      
      // Generate verb meaning if current part of speech is noun
      if (result['partOfSpeech'] == 'noun') {
        alternateMeanings['verb'] = 'The action of ${baseVerb}ing something or the process of being ${baseVerb}ed.';
      } 
      // Generate noun meaning if current part of speech is verb
      else if (result['partOfSpeech'] == 'verb') {
        alternateMeanings['noun'] = 'The product, result, or activity of ${baseVerb}ing.';
      }
      
      result['alternateMeanings'] = alternateMeanings;
      
      // Add tense variations for the verb form
      Map<String, String> tenseVariations = {
        'Infinitive': 'to $baseVerb',
        'Present Simple (I/you/we/they)': '$baseVerb',
        'Present Simple (he/she/it)': '${baseVerb}s',
        'Present Continuous': '${lowercaseWord}',
        'Past Simple': _generatePastTense(baseVerb),
        'Past Continuous': 'was/were ${lowercaseWord}',
        'Future Simple': 'will $baseVerb',
      };
      
      result['verbTenseVariations'] = tenseVariations;
    }
    
    // Words ending in "-ed" can often be both past tense verbs and adjectives
    else if (lowercaseWord.endsWith('ed') && lowercaseWord.length > 3) {
      String baseVerb = lowercaseWord.substring(0, lowercaseWord.length - 2);
      if (lowercaseWord.endsWith('ied') && lowercaseWord.length > 4) {
        // For words like "carried" -> "carry"
        baseVerb = lowercaseWord.substring(0, lowercaseWord.length - 3) + 'y';
      } else if (lowercaseWord.endsWith('pped') || 
                 lowercaseWord.endsWith('tted') || 
                 lowercaseWord.endsWith('nned')) {
        // For words with doubled consonant: "stopped" -> "stop"
        baseVerb = lowercaseWord.substring(0, lowercaseWord.length - 3);
      }
      
      result['partOfSpeechNote'] = 'This word can function as both a past tense verb and an adjective';
      
      Map<String, String> alternateMeanings = {};
      
      if (result['partOfSpeech'] == 'adjective') {
        alternateMeanings['verb'] = 'Past tense of "$baseVerb": to have ${baseVerb}ed something.';
      } else if (result['partOfSpeech'] == 'verb') {
        alternateMeanings['adjective'] = 'Having the quality or state of being ${baseVerb}ed.';
      }
      
      result['alternateMeanings'] = alternateMeanings;
    }
  }
  
  /// Check if a base verb should have an 'e' added when reconstructing from "-ing" form
  bool _shouldAddEToBaseVerb(String baseVerb) {
    // Single syllable with consonant-vowel-consonant pattern usually needs 'e'
    if (baseVerb.length >= 3) {
      final lastChar = baseVerb[baseVerb.length - 1];
      final secondLastChar = baseVerb[baseVerb.length - 2];
      final thirdLastChar = baseVerb[baseVerb.length - 3];
      
      // Common patterns for verbs that end with 'e' in base form
      if (!_isVowel(lastChar) && _isVowel(secondLastChar) && !_isVowel(thirdLastChar)) {
        // Exclude verbs that double the consonant instead
        if (!'wrtpl'.contains(lastChar)) {
          return true;
        }
      }
    }
    
    // Common verbs that end with 'e'
    final commonEEndingVerbs = [
      'writ', 'mak', 'tak', 'com', 'hav', 'mov', 'liv', 'lov', 
      'giv', 'driv', 'rid', 'slid', 'hid', 'shak', 'smil', 'danc'
    ];
    
    return commonEEndingVerbs.contains(baseVerb);
  }
  
  /// Simple rule-based past tense generation
  String _generatePastTense(String verb) {
    if (verb.isEmpty) return '';
    
    // Handle common irregular verbs
    const Map<String, String> irregularVerbs = {
      'go': 'went', 
      'have': 'had', 
      'be': 'was/were', 
      'do': 'did',
      'say': 'said', 
      'make': 'made', 
      'get': 'got', 
      'know': 'knew',
      'take': 'took', 
      'see': 'saw', 
      'come': 'came', 
      'think': 'thought',
      'write': 'wrote',
      'read': 'read', // same spelling but pronounced differently
      'give': 'gave',
      'find': 'found',
      'tell': 'told',
      'put': 'put',
      'run': 'ran',
      'speak': 'spoke',
    };
    
    // Check for irregular verbs
    if (irregularVerbs.containsKey(verb.toLowerCase())) {
      return irregularVerbs[verb.toLowerCase()]!;
    }
    
    // Apply regular past tense rules
    if (verb.endsWith('e')) {
      return verb + 'd';
    } else if (verb.endsWith('y') && !_isVowel(verb[verb.length - 2])) {
      return verb.substring(0, verb.length - 1) + 'ied';
    } else if (_endsWithConsonantVowelConsonant(verb)) {
      return verb + verb[verb.length - 1] + 'ed';
    } else {
      return verb + 'ed';
    }
  }
  
  /// Check if a character is a vowel
  bool _isVowel(String char) {
    return 'aeiou'.contains(char.toLowerCase());
  }
  
  /// Check if a word ends with a consonant-vowel-consonant pattern
  bool _endsWithConsonantVowelConsonant(String word) {
    if (word.length < 3) return false;
    
    final lastChar = word[word.length - 1];
    final secondLastChar = word[word.length - 2];
    final thirdLastChar = word[word.length - 3];
    
    return !_isVowel(lastChar) && _isVowel(secondLastChar) && !_isVowel(thirdLastChar);
  }

  /// Generate a raw vocabulary item with AI - direct API call implementation
  Future<Map<String, dynamic>> generateVocabularyItemWithPrompt(String prompt) async {
    try {
      // Get the selected AI provider
      final selectedProvider = await _secureStorage.getSelectedAiProvider();
      debugPrint('Selected AI provider for vocabulary generation: $selectedProvider');
      
      if (selectedProvider.isEmpty) {
        debugPrint('No AI provider selected, returning empty result');
        return {};
      }
      
      // Use AiProviderFactory to get the appropriate provider
      final provider = AiProviderFactory.getProvider(selectedProvider, _secureStorage);
      debugPrint('Using provider: $selectedProvider for vocabulary generation');
      
      // Custom parameters
      Map<String, dynamic> parameters = {
        'customPrompt': prompt,
        'temperature': 0.7,
        'maxTokens': 800,
      };
      
      // Make the request with a timeout
      final response = await provider.makeRequest(
        PromptType.connectionTest,  // Using connectionTest as a generic type for custom prompts
        parameters
      ).timeout(const Duration(seconds: 20));
      
      debugPrint('Raw AI response length: ${response.length}');
      
      // Try to extract JSON from the response
      try {
        // Try to parse the entire content as JSON first
        final jsonData = jsonDecode(response);
        return jsonData;
      } catch (e) {
        debugPrint('Error parsing entire response as JSON: $e');
        
        // If that fails, try to extract JSON from the text
        final jsonRegex = RegExp(r'\{[\s\S]*\}');
        final match = jsonRegex.firstMatch(response);
        
        if (match != null) {
          final jsonString = match.group(0);
          if (jsonString != null) {
            try {
              return jsonDecode(jsonString);
            } catch (e) {
              debugPrint('Error parsing extracted JSON: $e');
            }
          }
        }
        
        // If all else fails, create a simple response with just the text
        return {'response': response};
      }
    } catch (e) {
      debugPrint('Error in generateVocabularyItemWithPrompt: $e');
      throw Exception('Failed to generate vocabulary item: $e');
    }
  }
  
  /// Generate only an emoji for a word based on its meaning
  Future<String?> generateEmoji(String word, String meaning) async {
    try {
      // Check for empty inputs
      if (word.isEmpty || meaning.isEmpty) {
        debugPrint('Cannot generate emoji: word or meaning is empty');
        return _imageService.generateEmojiForWord(word, meaning);
      }

      // Get the selected AI provider
      final selectedProvider = await _secureStorage.getSelectedAiProvider();
      debugPrint('Selected AI provider for emoji generation: $selectedProvider');
      
      // Use AiProviderFactory to get the appropriate provider
      if (selectedProvider.isNotEmpty) {
        try {
          // Get the correct provider
          final provider = AiProviderFactory.getProvider(selectedProvider, _secureStorage);
          debugPrint('Using provider: $selectedProvider for emoji generation');
          
          // Enhanced parameters for emoji generation - especially for multi-word phrases
          Map<String, dynamic> parameters = {
            'word': word,
            'meaning': meaning,
            'temperature': 0.5,
            'maxTokens': 150,
            'instruction': 'This is a vocabulary learning app. Please select ONE perfect emoji that represents the MEANING of this word/phrase. ' +
                           'For multi-word phrases, focus on the overall meaning, not individual words. ' +
                           'For example, "break down" should get an emoji related to failure/collapse (🔨/💔), not separate emojis for "break" and "down". ' +
                           'Choose the most visually clear, specific emoji that learners can easily associate with the meaning.',
            'examples': [
              {'word': 'apple', 'meaning': 'A round fruit with red, green, or yellow skin', 'emoji': '🍎'},
              {'word': 'break down', 'meaning': 'To stop functioning; to collapse emotionally', 'emoji': '💔'},
              {'word': 'cloud nine', 'meaning': 'A state of extreme happiness', 'emoji': '😇'},
              {'word': 'under the weather', 'meaning': 'Feeling slightly ill', 'emoji': '🤒'},
            ]
          };
          
          // Make the request with a timeout using the specific emoji generation prompt type
          final response = await provider.makeRequest(
            PromptType.emojiGeneration,
            parameters
          ).timeout(const Duration(seconds: 15));
          
          debugPrint('Raw AI response for emoji: $response');
          
          // Try to extract the emoji from the response
          String emoji = '';
          try {
            // Try to parse as JSON first
            final jsonData = jsonDecode(response);
            if (jsonData is Map<String, dynamic> && jsonData.containsKey('emoji')) {
              emoji = jsonData['emoji'] as String? ?? '';
              debugPrint('Found emoji in JSON response: $emoji');
            } else {
              debugPrint('JSON response does not contain emoji field: $jsonData');
            }
            
            // If no emoji in JSON, try to find emoji in the text
            if (emoji.isEmpty) {
              // Look for any emoji character in the response
              final emojiRegex = RegExp(r'[\p{Emoji}]', unicode: true);
              final matches = emojiRegex.allMatches(response);
              if (matches.isNotEmpty) {
                emoji = matches.first.group(0) ?? '';
                debugPrint('Found emoji using regex: $emoji');
              }
            }
          } catch (e) {
            // If JSON parsing fails, look for emoji in the plain text
            debugPrint('Error parsing emoji JSON: $e');
            
            // Try to extract JSON object from the text
            final jsonRegex = RegExp(r'\{.*"emoji"\s*:\s*"([^"]+)".*\}');
            final match = jsonRegex.firstMatch(response);
            if (match != null && match.groupCount >= 1) {
              emoji = match.group(1) ?? '';
              debugPrint('Found emoji using JSON regex: $emoji');
            }
            
            // If still no emoji, look for any emoji character
            if (emoji.isEmpty) {
              final emojiRegex = RegExp(r'[\p{Emoji}]', unicode: true);
              final matches = emojiRegex.allMatches(response);
              if (matches.isNotEmpty) {
                emoji = matches.first.group(0) ?? '';
                debugPrint('Found emoji using character regex: $emoji');
              }
            }
          }
          
          if (emoji.isNotEmpty) {
            debugPrint('AI generated emoji for "$word" ($meaning): $emoji');
            return emoji;
          } else {
            debugPrint('No emoji found in AI response');
          }
        } catch (e) {
          debugPrint('Error using provider $selectedProvider for emoji: $e');
        }
      }
      
      // Fallback to local emoji generation
      debugPrint('Falling back to local emoji generation method');
      return _imageService.generateEmojiForWord(word, meaning);
    } catch (e) {
      debugPrint('Error generating emoji with AI: $e');
      // Fallback to local emoji generation
      final fallbackEmoji = _imageService.generateEmojiForWord(word, meaning);
      debugPrint('Using fallback emoji: $fallbackEmoji');
      return fallbackEmoji;
    }
  }
} 