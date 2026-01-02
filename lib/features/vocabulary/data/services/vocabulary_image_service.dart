import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:visual_vocabularies/core/utils/image_cache_service.dart';
import 'package:visual_vocabularies/core/utils/image_helper.dart';
import 'package:visual_vocabularies/core/utils/image_picker_service.dart';
import 'package:visual_vocabularies/core/utils/secure_storage_service.dart';
import 'package:visual_vocabularies/core/di/injection_container.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'dart:math' as math;

/// Service for handling vocabulary images
class VocabularyImageService {
  static final VocabularyImageService _instance = VocabularyImageService._internal();
  final ImageCacheService _imageCacheService = ImageCacheService.instance;
  final ImagePickerService _imagePickerService = ImagePickerService();
  final SecureStorageService _secureStorage = sl<SecureStorageService>();
  
  // URLs for emoji APIs and common GIF sources
  static const String _gifsearchApiBase = 'https://api.giphy.com/v1/gifs/search';
  
  // Default key is just a fallback and has very limited quota
  static const String _defaultGiphyApiKey = 'AN8uLY0W7lTj0waufvqR8xfyV8HNaSSA';

  /// Factory constructor to return the singleton instance
  factory VocabularyImageService() {
    return _instance;
  }

  VocabularyImageService._internal();

  /// Process an image URL to ensure it's properly cached and formatted
  Future<String> processImageUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    
    try {
      // Handle data URLs more efficiently
      if (imageUrl.startsWith('data:image/')) {
        // Remove any query parameters from data URLs
        if (imageUrl.contains('?')) {
          String cleanImageUrl = imageUrl.split('?')[0];
          debugPrint('Removed query parameters from data URL in processImageUrl');
          imageUrl = cleanImageUrl;
        }
        
        // Always optimize data URLs to prevent storing long strings
        return await _optimizeDataUrl(imageUrl);
      }
      
      // Process through the cache service to ensure consistency
      final processedUrl = await _imageCacheService.processImageUrl(imageUrl);
      debugPrint('Processed image URL: ${processedUrl.substring(0, math.min(50, processedUrl.length))}...');
      
      return processedUrl;
    } catch (e) {
      debugPrint('Error processing image URL: $e');
      return imageUrl ?? ''; // Return the original URL if processing fails, or empty string if null
    }
  }
  
  /// Optimize data URLs by storing them with a unique ID instead of embedding the full data
  Future<String> _optimizeDataUrl(String dataUrl) async {
    try {
      // Generate a unique ID for this image
      final id = const Uuid().v4();
      
      // Determine file extension based on the image type
      String extension = 'img';
      if (dataUrl.startsWith('data:image/jpeg')) {
        extension = 'jpg';
      } else if (dataUrl.startsWith('data:image/png')) {
        extension = 'png';
      } else if (dataUrl.startsWith('data:image/gif')) {
        extension = 'gif';
      }
      
      // Store the image data in a local file
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = '${directory.path}/images';
      final filePath = '$dirPath/$id.$extension';
      
      // Ensure directory exists
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Extract and decode the base64 data
      final dataStart = dataUrl.indexOf(',') + 1;
      final base64Data = dataUrl.substring(dataStart);
      
      // Try to decode the data
      Uint8List imageData;
      try {
        imageData = base64Decode(base64Data);
      } catch (e) {
        debugPrint('Error decoding base64 data: $e');
        // Try to fix padding issues
        String paddedBase64 = base64Data;
        while (paddedBase64.length % 4 != 0) {
          paddedBase64 += '=';
        }
        imageData = base64Decode(paddedBase64);
      }
      
      // Write the binary data to the file
      final file = File(filePath);
      await file.writeAsBytes(imageData);
      
      debugPrint('Optimized data URL: saved to file at $filePath with ID $id');
      
      // For web, return the data URL since file access won't work
      if (kIsWeb) {
        return dataUrl;
      }
      
      // Return a reference URL that uses the ID
      return 'file://$filePath';
    } catch (e) {
      debugPrint('Error optimizing data URL: $e');
      return dataUrl; // Return original if optimization fails
    }
  }

  /// Pick an image from gallery using the image picker service
  /// This now allows picking PNG and GIF files for emoji replacement
  Future<String?> pickImageFromGallery() async {
    final String? pickedFile = await _imagePickerService.pickImageFromGallery();
    return pickedFile;
  }

  /// Take a new photo using the image picker service
  Future<String?> takePhoto() async {
    final String? pickedFile = await _imagePickerService.takePhoto();
    return pickedFile;
  }

  /// Generate an image for a word using AI
  Future<String?> generateImageForWord(String word, String meaning, {String? apiKey}) async {
    try {
      // Generate a clean colored background without text
      // We'll use different colors based on the word length to add some variety
      final colorCode = _getColorCodeForWord(word);
      final dummyImageUrl = "https://dummyimage.com/400x300/$colorCode/ffffff";
      return await _imageCacheService.processImageUrl(dummyImageUrl);
    } catch (e) {
      debugPrint('Error generating image: $e');
    }
    return null;
  }
  
  /// Alias for generateImageForWord for more consistent naming
  Future<String?> generateImage(String word, String meaning) {
    return generateImageForWord(word, meaning);
  }
  
  /// Get the configured GIPHY API key or use the default one
  Future<String> _getGiphyApiKey() async {
    try {
      final savedKey = await _secureStorage.getGiphyApiKey();
      if (savedKey.isNotEmpty) {
        return savedKey;
      }
    } catch (e) {
      debugPrint('Error retrieving GIPHY API key: $e');
    }
    
    // Use the default key if no custom key is set
    return _defaultGiphyApiKey;
  }
  
  /// Search for a GIF using GIPHY with just the search term
  /// This is a simpler interface for the UI
  Future<String?> searchGiphyGif(String searchTerm, {int limit = 1}) async {
    try {
      // Get the API key from storage
      final apiKey = await _getGiphyApiKey();
      
      // Call GIPHY API
      final response = await http.get(
        Uri.parse('$_gifsearchApiBase?api_key=$apiKey&q=${Uri.encodeComponent(searchTerm)}&limit=$limit&rating=g')
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['data'] != null && data['data'].length > 0) {
          final gifUrl = data['data'][0]['images']['fixed_height']['url'];
          return await _imageCacheService.processImageUrl(gifUrl);
        }
      } else {
        debugPrint('GIPHY API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching GIF: $e');
    }
    
    return null;
  }
  
  /// Search and fetch a relevant GIF for the given word
  /// Returns a URL to an animated GIF that represents the word
  Future<String?> searchGifForWord(String word, String meaning) async {
    // Create search terms based on word and meaning
    final searchTerm = '$word ${_extractKeywordsFromMeaning(meaning)}';
    
    // Use the common implementation
    final gifUrl = await searchGiphyGif(searchTerm);
    
    // Fallback to regular image generation if no GIF found
    return gifUrl ?? generateImageForWord(word, meaning);
  }
  
  /// Check if an image URL is an animated GIF
  bool isAnimatedGif(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return false;
    
    return imageUrl.toLowerCase().endsWith('.gif') || 
           imageUrl.toLowerCase().contains('.gif') ||
           (imageUrl.contains('giphy.com') && !imageUrl.contains('.jpg') && !imageUrl.contains('.png'));
  }
  
  /// Extract relevant keywords from meaning to improve GIF search
  String _extractKeywordsFromMeaning(String meaning) {
    // Simple extraction - in a real app you might use NLP
    final words = meaning.split(' ')
        .where((word) => word.length > 3) // Filter out short words
        .where((word) => !['this', 'that', 'then', 'than', 'with', 'also'].contains(word.toLowerCase()))
        .take(3) // Take only first 3 meaningful words
        .join(' ');
    
    return words;
  }
  
  /// Generates an emoji for a word or returns a default
  Future<String?> generateEmoji(String word, {String? meaning}) async {
    if (meaning != null) {
      return generateEmojiForWord(word, meaning);
    }
    
    // If no meaning provided, use a simpler mapping
    final Map<String, String> simpleEmojiMap = {
      'happy': '😊', 'sad': '😢', 'angry': '😠', 'love': '❤️',
      'dog': '🐕', 'cat': '🐈', 'bird': '🐦', 'fish': '🐟',
      'sun': '☀️', 'moon': '🌙', 'star': '⭐', 'rain': '🌧️',
      'apple': '🍎', 'book': '📚', 'car': '🚗', 'house': '🏠',
    };
    
    // Check for direct matches
    final lowercaseWord = word.toLowerCase();
    for (final entry in simpleEmojiMap.entries) {
      if (lowercaseWord.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Default based on first letter
    final firstChar = word.isNotEmpty ? word[0].toLowerCase() : 'a';
    switch (firstChar) {
      case 'a': case 'b': case 'c': return '🔤';
      case 'd': case 'e': case 'f': return '📝';
      case 'g': case 'h': case 'i': return '💡';
      case 'j': case 'k': case 'l': return '🔑';
      case 'm': case 'n': case 'o': return '🌍';
      case 'p': case 'q': case 'r': return '🔍';
      case 's': case 't': case 'u': return '⭐';
      case 'v': case 'w': case 'x': return '📊';
      case 'y': case 'z': return '🏁';
      default: return '📌';
    }
  }
  
  /// Generate a detailed emoji based on word meaning
  /// Returns a suitable emoji based on semantic analysis of the word and meaning
  String generateEmojiForWord(String word, String meaning) {
    final String lowercaseWord = word.toLowerCase();
    final String lowercaseMeaning = meaning.toLowerCase();
    
    // Comprehensive emoji mapping for different categories
    final Map<String, Map<RegExp, String>> categoryEmojis = {
      // Animals and Nature
      'animals': {
        RegExp(r'dog|puppy|canine'): '🐕',
        RegExp(r'cat|kitten|feline'): '🐈', 
        RegExp(r'bird|avian'): '🐦',
        RegExp(r'fish|aquatic'): '🐟',
        RegExp(r'horse|equine'): '🐎',
        RegExp(r'lion|feline|predator'): '🦁',
        RegExp(r'elephant|trunk'): '🐘',
        RegExp(r'monkey|ape|primate'): '🐒',
        RegExp(r'cow|cattle|bovine'): '🐄',
        RegExp(r'pig|swine|pork'): '🐖',
        RegExp(r'sheep|lamb|wool'): '🐑',
        RegExp(r'goat|kid'): '🐐',
        RegExp(r'chicken|hen|rooster'): '🐔',
        RegExp(r'duck|quack'): '🦆',
        RegExp(r'frog|toad|amphibian'): '🐸',
        RegExp(r'turtle|tortoise|shell'): '🐢',
        RegExp(r'snake|serpent|reptile'): '🐍',
        RegExp(r'insect|bug'): '🐜',
        RegExp(r'ant|colony'): '🐜',
        RegExp(r'bee|honey|wasp'): '🐝',
        RegExp(r'butterfly|moth'): '🦋',
        RegExp(r'rabbit|bunny'): '🐇',
      },
      
      // Nature
      'nature': {
        RegExp(r'tree|forest'): '🌳',
        RegExp(r'flower|bloom|blossom'): '🌸',
        RegExp(r'mountain|hill|peak'): '⛰️',
        RegExp(r'sun|solar|sunny'): '☀️',
        RegExp(r'moon|lunar|night'): '🌙',
        RegExp(r'star|stellar|constellation'): '⭐',
        RegExp(r'ocean|sea|marine'): '🌊',
        RegExp(r'rain|downpour|precipitation'): '🌧️',
        RegExp(r'snow|winter|snowflake'): '❄️',
        RegExp(r'lightning|thunder|storm'): '⚡',
        RegExp(r'wind|breeze|gust'): '💨',
        RegExp(r'rainbow|spectrum'): '🌈',
        RegExp(r'beach|shore|coast'): '🏖️',
        RegExp(r'desert|sand|arid'): '🏜️',
        RegExp(r'island|isle'): '🏝️',
        RegExp(r'volcano|eruption|lava'): '🌋',
        RegExp(r'earth|planet|world'): '🌍',
        RegExp(r'water|liquid'): '💧',
        RegExp(r'fire|flame|burn'): '🔥',
      },
    
      // Food and Drink
      'food': {
        RegExp(r'apple|fruit'): '🍎',
        RegExp(r'banana|tropical'): '🍌',
        RegExp(r'orange|citrus'): '🍊',
        RegExp(r'grape|vineyard|wine'): '🍇',
        RegExp(r'watermelon|melon'): '🍉',
        RegExp(r'strawberry|berry'): '🍓',
        RegExp(r'bread|bakery|toast'): '🍞',
        RegExp(r'vegetable|veggie'): '🥦',
        RegExp(r'meat|protein|beef'): '🥩',
        RegExp(r'chicken|poultry'): '🍗',
        RegExp(r'pizza|slice'): '🍕',
        RegExp(r'burger|hamburger'): '🍔',
        RegExp(r'fries|french'): '🍟',
        RegExp(r'sushi|japanese'): '🍣',
        RegExp(r'ice cream|dessert'): '🍦',
        RegExp(r'drink|beverage'): '🥤',
        RegExp(r'coffee|caffeine'): '☕',
        RegExp(r'cake|pastry'): '🍰',
        RegExp(r'cookie|biscuit'): '🍪',
      },
      
      // Emotions/Human
      'emotions': {
        RegExp(r'happy|joy|glad|happiness'): '😊',
        RegExp(r'sad|unhappy|sorrow|grief'): '😢',
        RegExp(r'angry|fury|mad|rage'): '😠',
        RegExp(r'love|affection|adore'): '❤️',
        RegExp(r'laugh|laughter|giggle'): '😂',
        RegExp(r'smile|grin'): '😄',
        RegExp(r'cry|tear|weep'): '😭',
        RegExp(r'fear|afraid|scared'): '😨',
        RegExp(r'surprise|astonish|amazement'): '😲',
        RegExp(r'confuse|puzzle|baffle'): '😕',
        RegExp(r'kiss|smooch'): '💋',
        RegExp(r'think|ponder|contemplate'): '🤔',
        RegExp(r'sleep|slumber|rest'): '😴',
        RegExp(r'cool|awesome|great'): '😎',
        RegExp(r'nervous|anxious|worry'): '😰',
      },
      
      // Activities
      'activities': {
        RegExp(r'run|sprint|jog'): '🏃',
        RegExp(r'swim|swimming'): '🏊',
        RegExp(r'dance|dancing'): '💃',
        RegExp(r'sing|singing'): '🎤',
        RegExp(r'play|game'): '🎮',
        RegExp(r'write|writing|wrote'): '✍️',
        RegExp(r'read|reading|book'): '📚',
        RegExp(r'cook|cooking|chef'): '👨‍🍳',
        RegExp(r'drive|driving|car'): '🚗',
        RegExp(r'fly|flying|flight'): '✈️',
        RegExp(r'exercise|workout'): '🏋️',
        RegExp(r'paint|painting|draw'): '🎨',
        RegExp(r'music|musical|song'): '🎵',
        RegExp(r'travel|journey|trip'): '🧳',
        RegExp(r'shop|shopping|purchase'): '🛍️',
      },
      
      // Objects
      'objects': {
        RegExp(r'phone|mobile|call'): '📱',
        RegExp(r'computer|laptop|pc'): '💻',
        RegExp(r'book|literature|novel'): '📖',
        RegExp(r'money|cash|currency'): '💰',
        RegExp(r'gift|present|package'): '🎁',
        RegExp(r'clock|time|watch'): '⏰',
        RegExp(r'lock|secure|password'): '🔒',
        RegExp(r'key|unlock|access'): '🔑',
        RegExp(r'light|lamp|bulb'): '💡',
        RegExp(r'camera|photo|picture'): '📷',
        RegExp(r'medicine|pill|drug'): '💊',
        RegExp(r'bag|purse|backpack'): '👜',
        RegExp(r'tool|wrench|fix'): '🔧',
        RegExp(r'house|home|residence'): '🏠',
        RegExp(r'building|structure'): '🏢',
      },
      
      // Abstract concepts
      'abstract': {
        RegExp(r'time|temporal|duration'): '⏳',
        RegExp(r'idea|concept|thought'): '💭',
        RegExp(r'success|achieve|accomplish'): '🏆',
        RegExp(r'grow|growth|increase'): '📈',
        RegExp(r'decrease|reduce|fall'): '📉',
        RegExp(r'fast|quick|rapid'): '⚡',
        RegExp(r'slow|sluggish|gradual'): '🐢',
        RegExp(r'strong|strength|powerful'): '💪',
        RegExp(r'weak|feeble|fragile'): '🌱',
        RegExp(r'hot|heat|warm'): '🔥',
        RegExp(r'cold|cool|freeze'): '❄️',
        RegExp(r'begin|start|commence'): '🚩',
        RegExp(r'end|finish|complete'): '🏁',
        RegExp(r'open|uncover|reveal'): '📂',
        RegExp(r'close|shut|seal'): '📁',
        RegExp(r'language|speak|talk'): '🗣️',
        RegExp(r'learn|study|education'): '🎓',
        RegExp(r'find|search|seek'): '🔍',
        RegExp(r'listen|hear|audio'): '👂',
        RegExp(r'see|view|watch'): '👁️',
      },
    };
    
    // Check all categories for matches
    for (final categoryMap in categoryEmojis.values) {
      for (final pattern in categoryMap.keys) {
        if (pattern.hasMatch(lowercaseWord) || pattern.hasMatch(lowercaseMeaning)) {
          return categoryMap[pattern]!;
        }
      }
    }
    
    // Additional check: analyze word parts
    if (lowercaseWord.contains('work') || lowercaseMeaning.contains('work')) return '💼';
    if (lowercaseWord.contains('heart') || lowercaseMeaning.contains('heart')) return '❤️';
    if (lowercaseWord.contains('celebrat') || lowercaseMeaning.contains('celebrat')) return '🎉';
    if (lowercaseWord.contains('smart') || lowercaseMeaning.contains('intellig')) return '🧠';
    if (lowercaseWord.contains('luck') || lowercaseMeaning.contains('fortun')) return '🍀';
    if (lowercaseWord.contains('magic') || lowercaseMeaning.contains('spell')) return '✨';
    if (lowercaseWord.contains('warn') || lowercaseMeaning.contains('caution')) return '⚠️';
    if (lowercaseWord.contains('rule') || lowercaseMeaning.contains('govern')) return '📜';
    if (lowercaseWord.contains('medic') || lowercaseMeaning.contains('health')) return '🏥';
    
    // Get default emoji based on word
    final String? defaultEmoji = _getColorCodeForWord(word) == "f39c12" ? "🍊" : null;
    
    // If we have a default emoji from the word's color code, use it
    if (defaultEmoji != null) {
      return defaultEmoji;
    }
    
    // Fall back to first letter method
    final firstChar = word.isNotEmpty ? word[0].toLowerCase() : 'a';
    switch (firstChar) {
      case 'a': case 'b': case 'c': return '📝';
      case 'd': case 'e': case 'f': return '🔍';
      case 'g': case 'h': case 'i': return '💡';
      case 'j': case 'k': case 'l': return '🔑';
      case 'm': case 'n': case 'o': return '🌟';
      case 'p': case 'q': case 'r': return '📚';
      case 's': case 't': case 'u': return '🔔';
      case 'v': case 'w': case 'x': return '🎯';
      case 'y': case 'z': return '✨';
      default: return '📌';
    }
  }
  
  /// Helper method to get a color code based on word
  String _getColorCodeForWord(String word) {
    if (word.isEmpty) return "3498db"; // Default blue if no word
    
    // Use the first character to determine a color family
    final firstChar = word.toLowerCase().codeUnitAt(0);
    
    // Map ranges of characters to different colors
    if (firstChar >= 'a'.codeUnitAt(0) && firstChar <= 'e'.codeUnitAt(0)) {
      return "3498db"; // Blue
    } else if (firstChar >= 'f'.codeUnitAt(0) && firstChar <= 'j'.codeUnitAt(0)) {
      return "2ecc71"; // Green
    } else if (firstChar >= 'k'.codeUnitAt(0) && firstChar <= 'o'.codeUnitAt(0)) {
      return "9b59b6"; // Purple
    } else if (firstChar >= 'p'.codeUnitAt(0) && firstChar <= 't'.codeUnitAt(0)) {
      return "f39c12"; // Orange
    } else {
      return "e74c3c"; // Red
    }
  }

  /// Check if an image path is a network URL
  bool isNetworkImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    return imagePath.startsWith('http://') || imagePath.startsWith('https://');
  }

  /// Check if an image path is a local file
  bool isLocalImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    return !isNetworkImage(imagePath);
  }
  
  /// Check if an image is a PNG
  bool isPng(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    return imagePath.toLowerCase().endsWith('.png');
  }
} 