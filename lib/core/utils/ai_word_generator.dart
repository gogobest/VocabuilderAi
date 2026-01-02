import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'dart:math';

/// A service that generates AI-enhanced vocabulary items
class AiWordGenerator {
  const AiWordGenerator();
  
  /// Generate a complete vocabulary item from just a word
  Map<String, dynamic> generateVocabularyItem(String word) {
    // Normalize the word
    final normalizedWord = word.trim();
    
    // Generate meaning and example based on the word
    final meaningAndExample = _generateMeaningAndExample(normalizedWord);
    
    // Select an appropriate category
    final category = _selectCategory(normalizedWord, meaningAndExample['meaning'] ?? '');
    
    // Determine difficulty level (1-5)
    final difficultyLevel = _determineDifficultyLevel(normalizedWord);
    
    // Return complete generated vocabulary item
    return {
      'word': normalizedWord,
      'meaning': meaningAndExample['meaning'] ?? '',
      'example': meaningAndExample['example'] ?? '',
      'category': category,
      'difficultyLevel': difficultyLevel,
    };
  }
  
  /// Generate a random word
  Future<String?> generateRandomWord() async {
    // Define components for creating dynamic words
    final prefixes = ['un', 're', 'in', 'dis', 'en', 'em', 'pre', 'pro', 'ex', 'de', 'con', 'com', 'sub', 'over', 'under'];
    final suffixes = ['able', 'ible', 'al', 'ial', 'ful', 'ic', 'ical', 'ious', 'ous', 'ive', 'less', 'ly', 'ment', 'ness', 'ship', 'tion', 'sion'];
    final rootWords = [
      'act', 'art', 'build', 'care', 'change', 'clear', 'color', 'cover', 'create', 'design',
      'do', 'drive', 'end', 'fall', 'feel', 'find', 'form', 'give', 'go', 'grow',
      'help', 'hold', 'hope', 'keep', 'know', 'lead', 'learn', 'level', 'light', 'like',
      'look', 'make', 'move', 'need', 'open', 'play', 'point', 'read', 'run', 'see',
      'send', 'set', 'show', 'speak', 'stand', 'start', 'state', 'take', 'talk', 'tell',
      'think', 'turn', 'use', 'view', 'walk', 'want', 'work', 'write'
    ];
    final nouns = [
      'time', 'year', 'day', 'way', 'thing', 'world', 'life', 'hand', 'part', 'place',
      'case', 'group', 'fact', 'point', 'book', 'word', 'house', 'side', 'kind', 'head'
    ];
    final adjectives = [
      'good', 'new', 'first', 'last', 'long', 'great', 'small', 'high', 'old', 'right',
      'big', 'few', 'early', 'young', 'clear', 'black', 'free', 'sure', 'full', 'real'
    ];
    
    // List of common English words as fallback
    final List<String> commonWords = [
      'apple', 'book', 'cat', 'dog', 'elephant', 'friend', 'garden',
      'house', 'internet', 'journey', 'knowledge', 'language', 'mountain',
      'nature', 'ocean', 'people', 'question', 'river', 'summer', 'travel',
      'umbrella', 'vision', 'water', 'xylophone', 'yellow', 'zebra',
      'time', 'day', 'year', 'way', 'thing', 'world', 'life', 'hand',
      'part', 'child', 'eye', 'woman', 'place', 'work', 'week', 'case',
      'point', 'company', 'number', 'group', 'problem', 'fact'
    ];
    
    final random = Random();
    
    // Choose a random word generation method (0-6)
    final method = random.nextInt(7);
    
    String randomWord;
    
    switch (method) {
      case 0:
        // Simple word from the list as fallback
        randomWord = commonWords[random.nextInt(commonWords.length)];
        break;
        
      case 1:
        // Add prefix to a root word
        final prefix = prefixes[random.nextInt(prefixes.length)];
        final root = rootWords[random.nextInt(rootWords.length)];
        randomWord = '$prefix$root';
        break;
        
      case 2:
        // Add suffix to a root word
        final root = rootWords[random.nextInt(rootWords.length)];
        final suffix = suffixes[random.nextInt(suffixes.length)];
        // Handle basic spelling rules for adding suffixes
        if (suffix.startsWith('i') && root.endsWith('y')) {
          // Change y to i for suffixes starting with i (e.g., happy -> happily)
          randomWord = '${root.substring(0, root.length - 1)}i$suffix';
        } else if (suffix.startsWith('e') && root.endsWith('e')) {
          // Drop the final e when adding a suffix starting with a vowel
          randomWord = '${root.substring(0, root.length - 1)}$suffix';
        } else {
          randomWord = '$root$suffix';
        }
        break;
        
      case 3:
        // Add both prefix and suffix
        final prefix = prefixes[random.nextInt(prefixes.length)];
        final root = rootWords[random.nextInt(rootWords.length)];
        final suffix = suffixes[random.nextInt(suffixes.length)];
        // Handle basic spelling rules
        String modifiedRoot = root;
        if (suffix.startsWith('i') && root.endsWith('y')) {
          modifiedRoot = '${root.substring(0, root.length - 1)}i';
        } else if (suffix.startsWith('e') && root.endsWith('e')) {
          modifiedRoot = root.substring(0, root.length - 1);
        }
        randomWord = '$prefix$modifiedRoot$suffix';
        break;
        
      case 4:
        // Create a compound word from two nouns
        final noun1 = nouns[random.nextInt(nouns.length)];
        final noun2 = nouns[random.nextInt(nouns.length)];
        randomWord = '$noun1$noun2';
        break;
        
      case 5:
        // Create a compound word from adjective + noun
        final adjective = adjectives[random.nextInt(adjectives.length)];
        final noun = nouns[random.nextInt(nouns.length)];
        randomWord = '$adjective$noun';
        break;
        
      case 6:
        // Create a phrasal verb (two words)
        final verb = rootWords[random.nextInt(rootWords.length)];
        final particles = ['up', 'down', 'in', 'out', 'on', 'off', 'away', 'over', 'back'];
        final particle = particles[random.nextInt(particles.length)];
        randomWord = '$verb $particle';
        break;
        
      default:
        // Fallback to simple selection
        randomWord = commonWords[random.nextInt(commonWords.length)];
    }
    
    return randomWord;
  }
  
  /// Generate meaning and example for a given word
  Map<String, String> _generateMeaningAndExample(String word) {
    // This is a simple simulation of AI-generated meanings and examples
    // In a real implementation, this would call an external AI API
    
    final Map<String, Map<String, String>> knownWords = {
      'apple': {
        'meaning': 'A round fruit with red, green, or yellow skin and firm white flesh',
        'example': 'I eat an apple every morning for breakfast.'
      },
      'run': {
        'meaning': 'To move quickly on foot by taking long steps',
        'example': 'She runs five kilometers every day to stay fit.'
      },
      'happy': {
        'meaning': 'Feeling or showing pleasure or contentment',
        'example': 'The children were happy to see their grandparents.'
      },
      'book': {
        'meaning': 'A written or printed work consisting of pages',
        'example': 'I borrowed three books from the library.'
      },
      'computer': {
        'meaning': 'An electronic device for storing and processing data',
        'example': 'He uses his computer to write code and create applications.'
      },
      'house': {
        'meaning': 'A building for human habitation, typically for a family',
        'example': 'They bought a new house near the park.'
      },
      'water': {
        'meaning': 'A transparent, odorless, tasteless liquid that forms seas, lakes, and rain',
        'example': 'Drink plenty of water to stay hydrated.'
      },
      'friend': {
        'meaning': 'A person with whom one has a bond of mutual affection',
        'example': 'My friends helped me move to my new apartment.'
      },
      'time': {
        'meaning': 'The indefinite continued progress of existence',
        'example': 'We don\'t have much time to finish this project.'
      },
      'love': {
        'meaning': 'An intense feeling of deep affection',
        'example': 'Parents naturally feel love for their children.'
      },
    };
    
    // Check if we have predefined meaning and example
    if (knownWords.containsKey(word.toLowerCase())) {
      return knownWords[word.toLowerCase()]!;
    }
    
    // Generate generic meaning and example for unknown words
    return {
      'meaning': 'A term referring to $word, commonly used in various contexts',
      'example': 'Let me tell you about $word and how it works in a sentence.'
    };
  }
  
  /// Select appropriate category for the word based on meaning
  String _selectCategory(String word, String meaning) {
    final lowerWord = word.toLowerCase();
    final lowerMeaning = meaning.toLowerCase();
    
    // Simple category matching based on keywords
    final Map<String, List<String>> categoryKeywords = {
      'Business': ['work', 'company', 'office', 'business', 'finance', 'money', 'job', 'career', 'market'],
      'Technology': ['computer', 'app', 'software', 'digital', 'tech', 'device', 'internet', 'code', 'online'],
      'Science': ['science', 'research', 'laboratory', 'experiment', 'biology', 'physics', 'chemistry', 'data'],
      'Travel': ['travel', 'journey', 'trip', 'destination', 'vacation', 'tourist', 'country', 'place', 'visit'],
      'Food': ['food', 'eat', 'meal', 'recipe', 'dish', 'cook', 'taste', 'flavor', 'ingredient', 'cuisine'],
      'Sports': ['sport', 'game', 'team', 'play', 'athlete', 'competition', 'ball', 'race', 'fitness'],
      'Arts': ['art', 'music', 'paint', 'creative', 'design', 'draw', 'culture', 'dance', 'artist', 'sculpture'],
      'Education': ['learn', 'study', 'school', 'student', 'teacher', 'knowledge', 'class', 'education', 'book'],
      'Health': ['health', 'body', 'medical', 'doctor', 'fitness', 'disease', 'medicine', 'wellness', 'care'],
    };
    
    for (final category in categoryKeywords.keys) {
      for (final keyword in categoryKeywords[category]!) {
        if (lowerWord.contains(keyword) || lowerMeaning.contains(keyword)) {
          return category;
        }
      }
    }
    
    // Default to General if no matches
    return 'General';
  }
  
  /// Determine difficulty level based on word characteristics
  int _determineDifficultyLevel(String word) {
    // Base difficulty on word length, unusual characters, etc.
    final lowerWord = word.toLowerCase();
    
    // Start with a base difficulty
    int difficulty = 1;
    
    // Longer words tend to be more difficult
    if (lowerWord.length > 8) {
      difficulty += 2;
    } else if (lowerWord.length > 6) {
      difficulty += 1;
    }
    
    // Words with unusual characters may be harder
    final hasUnusualChars = lowerWord.contains(RegExp(r'[^a-z ]'));
    if (hasUnusualChars) {
      difficulty += 1;
    }
    
    // Less common letters might indicate a more difficult word
    final uncommonLetters = ['j', 'k', 'q', 'v', 'x', 'z'];
    for (final letter in uncommonLetters) {
      if (lowerWord.contains(letter)) {
        difficulty += 1;
        break;
      }
    }
    
    // Ensure difficulty is within 1-5 range
    return min(5, max(1, difficulty));
  }
} 