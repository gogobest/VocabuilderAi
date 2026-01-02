import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:visual_vocabularies/core/utils/image_helper.dart';
import 'package:visual_vocabularies/core/utils/image_cache_service.dart';
import 'package:visual_vocabularies/core/utils/synonyms_game_service.dart';
import 'package:visual_vocabularies/core/utils/antonyms_game_service.dart';
import 'package:visual_vocabularies/core/utils/tenses_game_service.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'dart:convert';
import 'package:visual_vocabularies/features/vocabulary/presentation/widgets/vocabulary_form/tts_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';

class FlashcardWidget extends StatefulWidget {
  final String word;
  final String definition;
  final List<String> examples;
  final String? pronunciation;
  final String? imageUrl;
  final bool showBack;
  final String? wordEmoji;
  final String? partOfSpeech;
  final List<String>? synonyms;
  final List<String>? antonyms;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final String? id;
  final TtsHelper? ttsHelper;
  final String? category;

  const FlashcardWidget({
    super.key,
    required this.word,
    required this.definition,
    required this.examples,
    this.pronunciation,
    this.imageUrl,
    required this.showBack,
    this.wordEmoji,
    this.partOfSpeech,
    this.synonyms,
    this.antonyms,
    this.onTap,
    this.onEdit,
    this.id,
    this.ttsHelper,
    this.category,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget> 
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _showBack = false;

  // Initialize flashcard data properly
  late List<String> _flashcards;
  late int _currentIndex;

  int get currentCardIndex => _currentIndex;
  int get totalCards => _flashcards.length;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
      setState(() {});
    });

    // Initialize flashcard data
    _flashcards = [widget.word]; // Add more data if needed
    _currentIndex = 0;
  }

  @override
  void didUpdateWidget(FlashcardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showBack != oldWidget.showBack) {
      _toggleCard();
    }
    
    // Force rebuild when image or emoji changes
    if (widget.imageUrl != oldWidget.imageUrl || widget.wordEmoji != oldWidget.wordEmoji) {
      setState(() {
        // Just triggering a rebuild is enough to update the image/emoji display
        debugPrint('Updating flashcard visual: imageUrl or emoji changed');
        debugPrint('Old imageUrl: ${oldWidget.imageUrl}, New imageUrl: ${widget.imageUrl}');
        debugPrint('Old emoji: ${oldWidget.wordEmoji}, New emoji: ${widget.wordEmoji}');
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_showBack) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    _showBack = !_showBack;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AspectRatio(
          aspectRatio: 5 / 7,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final angle = _animation.value * math.pi;
              final frontVisible = angle < (math.pi / 2);

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective effect
                  ..rotateY(angle),
                child: frontVisible 
                  ? _buildFrontCard() 
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi), // Flip back text right way around
                      child: _buildBackCard(),
                    ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Update the front card to include category display
  Widget _buildFrontCard() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: isDarkMode ? theme.cardColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Word display
            Text(
              widget.word,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                // Enhanced contrast in dark mode
                color: isDarkMode ? Colors.white : theme.primaryColor,
                // Add subtle shadow for better readability in dark mode
                shadows: isDarkMode ? [
                  Shadow(
                    blurRadius: 2.0,
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Part of speech - prominently displayed in a chip
            if (widget.partOfSpeech != null)
              Container(
                margin: const EdgeInsets.only(top: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  // Use colors based on part of speech type to match tenses game
                  color: _getPartOfSpeechColor(widget.partOfSpeech!, isDarkMode),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getPartOfSpeechBorderColor(widget.partOfSpeech!, isDarkMode),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _formatPartOfSpeech(widget.partOfSpeech!),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getPartOfSpeechTextColor(widget.partOfSpeech!, isDarkMode),
                  ),
                ),
              ),
              
            const SizedBox(height: 12),
            
            // Image display - Enhanced for better appearance
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              Expanded(
                flex: 3, // Give more space to the image
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 200, // Minimum height
                      maxHeight: 300, // Maximum height
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias, // Ensures the image respects the border radius
                    child: _buildImageDisplay(widget.imageUrl!),
                  ),
                ),
              )
            // If no image but emoji exists, show emoji
            else if (widget.wordEmoji != null && widget.wordEmoji!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  widget.wordEmoji!,
                  style: const TextStyle(fontSize: 64),
                  textAlign: TextAlign.center,
                ),
              ),
              
            const SizedBox(height: 8),
            
            // Pronunciation guide if available
            if (widget.pronunciation != null && widget.pronunciation!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.pronunciation!,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        // Enhanced contrast for dark mode
                        color: isDarkMode ? Colors.grey[100] : Colors.grey[600],
                      ),
                    ),
                    if (widget.ttsHelper != null)
                      IconButton(
                        icon: Icon(
                          Icons.volume_up, 
                          size: 18,
                          // Make the icon more visible in dark mode
                          color: isDarkMode ? Colors.blue[300] : null,
                        ),
                        tooltip: 'Hear pronunciation',
                        onPressed: () {
                          widget.ttsHelper!.speak(widget.word);
                        },
                      ),
                  ],
                ),
              ),
              
            // Category display
            if (widget.category != null && widget.category!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    // Ensure background has good contrast in dark mode
                    color: isDarkMode 
                      ? theme.colorScheme.primaryContainer.withOpacity(0.7) 
                      : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.category!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      // Ensure text has good contrast on background
                      color: isDarkMode
                        ? theme.colorScheme.onPrimaryContainer.withOpacity(0.9)
                        : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              
            const Spacer(),
            
            // Tap to see meaning
            Text(
              'Tap to see meaning',
              style: TextStyle(
                fontSize: 14,
                // Enhanced contrast for better readability
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get the appropriate color for part of speech
  Color _getPartOfSpeechColor(String partOfSpeech, bool isDarkMode) {
    final lowerPart = partOfSpeech.toLowerCase();
    
    // Check if it's a verb
    if (lowerPart == 'verb' || lowerPart.contains('verb')) {
      return isDarkMode ? Colors.blue.shade900.withOpacity(0.7) : Colors.blue.shade50;
    }
    // Check if it's a phrase
    else if (lowerPart.contains('phrase') || widget.word.contains(' ')) {
      return isDarkMode ? Colors.purple.shade900.withOpacity(0.7) : Colors.purple.shade50;
    }
    // Non-verb (noun, adjective, adverb, etc.)
    else {
      return isDarkMode ? Colors.green.shade900.withOpacity(0.7) : Colors.green.shade50;
    }
  }

  // Helper method to get the appropriate border color for part of speech
  Color _getPartOfSpeechBorderColor(String partOfSpeech, bool isDarkMode) {
    final lowerPart = partOfSpeech.toLowerCase();
    
    // Check if it's a verb
    if (lowerPart == 'verb' || lowerPart.contains('verb')) {
      return isDarkMode ? Colors.blue.shade600 : Colors.blue.shade300;
    }
    // Check if it's a phrase
    else if (lowerPart.contains('phrase') || widget.word.contains(' ')) {
      return isDarkMode ? Colors.purple.shade600 : Colors.purple.shade300;
    }
    // Non-verb (noun, adjective, adverb, etc.)
    else {
      return isDarkMode ? Colors.green.shade600 : Colors.green.shade300;
    }
  }

  // Helper method to get the appropriate text color for part of speech
  Color _getPartOfSpeechTextColor(String partOfSpeech, bool isDarkMode) {
    final lowerPart = partOfSpeech.toLowerCase();
    
    // Check if it's a verb
    if (lowerPart == 'verb' || lowerPart.contains('verb')) {
      return isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700;
    }
    // Check if it's a phrase
    else if (lowerPart.contains('phrase') || widget.word.contains(' ')) {
      return isDarkMode ? Colors.purple.shade300 : Colors.purple.shade700;
    }
    // Non-verb (noun, adjective, adverb, etc.)
    else {
      return isDarkMode ? Colors.green.shade300 : Colors.green.shade700;
    }
  }
  
  // Helper method to format the part of speech consistently with tenses game
  String _formatPartOfSpeech(String partOfSpeech) {
    final lowerPart = partOfSpeech.toLowerCase();
    
    // Check if it's a verb
    if (lowerPart == 'verb' || lowerPart.contains('verb')) {
      return 'Verb';
    }
    // Check if it's a phrase
    else if (lowerPart.contains('phrase') || widget.word.contains(' ')) {
      return 'Phrase';
    }
    // For all other types (noun, adjective, adverb, etc.)
    else {
      // Keep original format but ensure first letter is capitalized
      return partOfSpeech.substring(0, 1).toUpperCase() + partOfSpeech.substring(1);
    }
  }

  // Update the back card to include category display
  Widget _buildBackCard() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Process the examples
    final examples = widget.examples.where((e) => e.isNotEmpty).toList();
    
    // Process the definition text to clean up any prompt instructions
    final String displayWord = widget.word;
    final String definition = _cleanPromptText(widget.definition);
    
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: isDarkMode ? theme.cardColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word display (smaller on back)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    displayWord,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.ttsHelper != null)
                  IconButton(
                    icon: const Icon(Icons.volume_up, size: 20),
                    tooltip: 'Hear pronunciation',
                    onPressed: () {
                      widget.ttsHelper!.speak(displayWord);
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
              ],
            ),
            
            // Add emoji on this side too
            if (widget.wordEmoji != null && widget.wordEmoji!.isNotEmpty)
              Center(
                child: Text(
                  widget.wordEmoji!,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              
            const SizedBox(height: 8),
            
            // Category and part of speech in a row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.partOfSpeech != null && widget.partOfSpeech!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.partOfSpeech!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  
                if (widget.partOfSpeech != null && widget.category != null)
                  const SizedBox(width: 8),
                  
                if (widget.category != null && widget.category!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.category!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Make the content scrollable to fix overflow
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Definition
                    Text(
                      'Definition:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      definition,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    
                    if (examples.isNotEmpty) const SizedBox(height: 16),
                    
                    // Examples
                    if (examples.isNotEmpty) ...[
                      Text(
                        'Example${examples.length > 1 ? 's' : ''}:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...examples.map((example) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '• ${_cleanPromptText(example)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      )),
                    ],
                    
                    // Synonyms with selection capability
                    if (widget.synonyms != null && widget.synonyms!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Synonyms:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      widget.id != null 
                          ? _buildSelectableSynonymChips(widget.synonyms!, widget.id!, isDarkMode, theme)
                          : Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: widget.synonyms!.map((synonym) => Chip(
                                label: Text(
                                  synonym,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: theme.colorScheme.surfaceVariant,
                                labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                padding: const EdgeInsets.all(0),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              )).toList(),
                            ),
                    ],
                    
                    // Antonyms with selection capability
                    if (widget.antonyms != null && widget.antonyms!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Antonyms:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      widget.id != null 
                          ? _buildSelectableAntonymChips(widget.antonyms!, widget.id!, isDarkMode, theme)
                          : Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: widget.antonyms!.map((antonym) => Chip(
                                label: Text(
                                  antonym,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: theme.colorScheme.errorContainer.withOpacity(0.7),
                                labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                padding: const EdgeInsets.all(0),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              )).toList(),
                            ),
                    ],
                    
                    // Add section for Tenses Practice marking
                    if (widget.id != null) ...[
                      const SizedBox(height: 16),
                      _buildTensesPracticeSection(widget.id!, isDarkMode, theme),
                    ],
                  ],
                ),
              ),
            ),
            
            // Edit button if provided
            if (widget.onEdit != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: TextButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Clean up any remaining prompt text in the flashcard display
  String _cleanPromptText(String text) {
    String cleaned = text;
    
    // Remove "Generate a flashcard..." text
    cleaned = cleaned.replaceAll(RegExp(r'Generate a flashcard for the word/phrase.*?context:', 
                                      caseSensitive: false, dotAll: true), '');
                                      
    // Remove text about what to include
    cleaned = cleaned.replaceAll(RegExp(r'Include:.*?category\.', 
                                      caseSensitive: false, dotAll: true), '');
    
    // Remove prompt fragments
    for (final fragment in [
      'definition,', 
      'example,', 
      'partOfSpeech,', 
      'emoji,', 
      'synonyms,', 
      'antonyms,', 
      'and category.',
      'as used in this context:',
      'Include:',
    ]) {
      cleaned = cleaned.replaceAll(fragment, '');
    }
    
    // Clean up extra whitespace and quotes
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    
    // Remove quotes at start and end
    if (cleaned.startsWith("'") || cleaned.startsWith('"')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.endsWith("'") || cleaned.endsWith('"')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    
    return cleaned;
  }

  Widget _buildNetworkImage(String imageUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent, // Changed to transparent for better appearance
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Network image error: $error');
          return _buildImageErrorPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebBlobImage(String imageUrl) {
    if (imageUrl.startsWith('data:')) {
      try {
        // Extract the base64 part from the data URL
        final base64String = imageUrl.split(',').last;
        final decodedBytes = base64Decode(base64String);
        return Image.memory(
          decodedBytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder(
              message: 'Failed to display image',
            );
          },
        );
      } catch (e) {
        // Handle base64 decoding errors
        return _buildImageErrorPlaceholder(
          message: 'Invalid image format',
        );
      }
    } else if (imageUrl.startsWith('blob:')) {
      // For blob URLs, use the ImageCacheService to handle conversion
      return FutureBuilder<String>(
        // Store the BuildContext in a local variable
        future: () {
          // Capture the build context before the async gap
          return ImageCacheService.instance.processImageUrl(imageUrl);
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildImageErrorPlaceholder(
              message: 'This image is only available in the current browser session',
            );
          }
          
          final processedUrl = snapshot.data!;
          if (processedUrl.startsWith('data:')) {
            try {
              // Extract the base64 part from the data URL
              final base64String = processedUrl.split(',').last;
              final decodedBytes = base64Decode(base64String);
              return Image.memory(
                decodedBytes,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImageErrorPlaceholder(
                    message: 'Failed to display image',
                  );
                },
              );
            } catch (e) {
              return _buildImageErrorPlaceholder(
                message: 'Invalid image format',
              );
            }
          }
          
          // If not converted to data URL, show message
          return _buildImageErrorPlaceholder(
            message: 'Temporary web image (only available in current browser session)',
          );
        },
      );
    } else {
      return _buildImageErrorPlaceholder(
        message: 'Unsupported image format',
      );
    }
  }

  Widget _buildDataUrlImage(String imageUrl) {
    try {
      debugPrint('Rendering data URL image');
      
      if (!imageUrl.contains(',')) {
        throw Exception('Invalid data URL format (no comma found)');
      }
      
      // Extract the base part and query parameters if any
      String cleanImageUrl = imageUrl;
      String queryParams = '';
      if (imageUrl.contains('?')) {
        final urlParts = imageUrl.split('?');
        cleanImageUrl = urlParts[0];
        if (urlParts.length > 1) {
          queryParams = urlParts[1];
        }
        debugPrint('Removed query parameters from data URL: $queryParams');
      }
      
      // Extract the base64 part after the comma
      final parts = cleanImageUrl.split(',');
      if (parts.length < 2) {
        throw Exception('Invalid data URL format (parts < 2)');
      }
      
      // Handle different data URL formats
      final base64Data = parts[1].trim();
      
      if (base64Data.isEmpty) {
        throw Exception('Empty base64 data');
      }
      
      // Make sure we handle padding correctly
      String paddedBase64 = base64Data;
      
      // Add proper padding if needed
      final int remainder = paddedBase64.length % 4;
      if (remainder > 0) {
        paddedBase64 = paddedBase64.padRight(paddedBase64.length + (4 - remainder), '=');
      }
      
      // Try to decode the base64 data
      Uint8List imageData;
      try {
        imageData = base64Decode(paddedBase64);
      } catch (e) {
        debugPrint('Base64 decoding error: $e');
        debugPrint('Base64 string: ${paddedBase64.substring(0, math.min(100, paddedBase64.length))}...');
        throw Exception('Failed to decode base64 data: $e');
      }
      
      if (imageData.isEmpty) {
        throw Exception('Decoded data is empty');
      }
      
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent, // Changed to transparent
        child: Image.memory(
          imageData,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Data URL image error: $error');
            return _buildEmojiDisplay(); // Fall back to emoji
          },
        ),
      );
    } catch (e) {
      debugPrint('Error rendering data URL image: $e');
      return _buildEmojiDisplay(); // Fall back to emoji
    }
  }
  
  Widget _buildFileImage(String imageUrl) {
    try {
      // Use the sanitize helper for better path handling
      String filePath = ImageHelper.sanitizeFilePath(imageUrl);
      
      debugPrint('Attempting to load file image from: $filePath');
      
      // Check if file exists before trying to load it
      final file = File(filePath);
      if (!file.existsSync()) {
        debugPrint('File does not exist: ${file.path}');
        return _buildEmojiDisplay(); // Fall back to emoji
      }
      
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent, // Changed to transparent for better appearance
        child: Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Local file load error: $error for path: ${file.path}');
            debugPrint('Stack trace: $stackTrace');
            return _buildEmojiDisplay(); // Fall back to emoji
          },
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Exception loading file image: $e');
      debugPrint('Stack trace: $stackTrace');
      return _buildEmojiDisplay(); // Fall back to emoji
    }
  }

  Widget _buildAssetImage(String assetPath) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent, // Changed to transparent for better appearance
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Asset error: $error for path: $assetPath');
          
          // Try with default placeholder as a fallback
          if (assetPath != ImageHelper.defaultPlaceholderPath) {
            return Image.asset(
              ImageHelper.defaultPlaceholderPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Placeholder error: $error');
                return _buildImageErrorPlaceholder();
              },
            );
          } else {
            // If even default placeholder fails
            return _buildImageErrorPlaceholder();
          }
        },
      ),
    );
  }

  Widget _buildImageErrorPlaceholder({String? message}) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported, size: 36, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message ?? 'An error occurred while loading the image',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced emoji display
  Widget _buildEmojiDisplay() {
    if (widget.wordEmoji != null && widget.wordEmoji!.isNotEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            widget.wordEmoji!,
            style: const TextStyle(fontSize: 80),
          ),
        ),
      );
    } else {
      // No emoji available, show a placeholder
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_emotions_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No image or emoji for "${widget.word}"',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  // Add the thumbnail image builder method
  Widget _buildThumbnailImage() {
    if (widget.wordEmoji != null && widget.wordEmoji!.isNotEmpty) {
      return Center(
        child: Text(
          widget.wordEmoji!,
          style: const TextStyle(fontSize: 36),
        ),
      );
    } else if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      // Check if it's a network image (starts with http:// or https://)
      final bool isNetworkImage = widget.imageUrl!.startsWith('http://') || 
                                widget.imageUrl!.startsWith('https://');
      
      if (isNetworkImage) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            widget.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading image: $error');
              return const Icon(Icons.image_not_supported, size: 36);
            },
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(widget.imageUrl!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading image: $error');
              return const Icon(Icons.image_not_supported, size: 36);
            },
          ),
        );
      }
    }
    
    // Fallback if no image or emoji
    return const Icon(Icons.image, size: 36, color: Colors.grey);
  }

  // Build selectable synonym chips
  Widget _buildSelectableSynonymChips(List<String> synonyms, String wordId, bool isDarkMode, ThemeData theme) {
    return StatefulBuilder(
      builder: (context, setState) {
        return FutureBuilder<List<String>>(
          future: sl<SynonymsGameService>().getMarkedSynonymsForWord(wordId),
          builder: (context, snapshot) {
            final markedSynonyms = snapshot.data ?? [];
            
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: synonyms.map((synonym) {
                final cleanSynonym = _cleanPromptText(synonym);
                final isMarked = markedSynonyms.contains(cleanSynonym);
                
                return GestureDetector(
                  onTap: () async {
                    final service = sl<SynonymsGameService>();
                    bool success;
                    
                    if (isMarked) {
                      success = await service.unmarkSynonym(wordId, cleanSynonym);
                      if (success) {
                        setState(() {
                          // Just trigger a rebuild
                        });
                      }
                    } else {
                      success = await service.markSynonym(wordId, cleanSynonym);
                      
                      // Show a snackbar suggesting to play the game if synonym was successfully marked
                      if (success) {
                        setState(() {
                          // Just trigger a rebuild
                        });
                      }
                    }
                  },
                  child: Chip(
                    label: Text(
                      cleanSynonym,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    backgroundColor: isMarked
                        ? (isDarkMode ? Colors.green.shade800 : Colors.green.shade100)
                        : (isDarkMode ? theme.colorScheme.surface : Colors.grey.shade200),
                    side: isMarked 
                        ? BorderSide(color: isDarkMode ? Colors.green : Colors.green.shade700, width: 1.5)
                        : null,
                    avatar: isMarked 
                        ? Icon(
                            Icons.check_circle, 
                            size: 16, 
                            color: isDarkMode ? Colors.green.shade300 : Colors.green.shade700
                          )
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // Build selectable antonym chips
  Widget _buildSelectableAntonymChips(List<String> antonyms, String wordId, bool isDarkMode, ThemeData theme) {
    return StatefulBuilder(
      builder: (context, setState) {
        return FutureBuilder<List<String>>(
          future: sl<AntonymsGameService>().getMarkedAntonymsForWord(wordId),
          builder: (context, snapshot) {
            final markedAntonyms = snapshot.data ?? [];
            
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: antonyms.map((antonym) {
                final cleanAntonym = _cleanPromptText(antonym);
                final isMarked = markedAntonyms.contains(cleanAntonym);
                
                return GestureDetector(
                  onTap: () async {
                    final service = sl<AntonymsGameService>();
                    bool success;
                    
                    if (isMarked) {
                      success = await service.unmarkAntonym(wordId, cleanAntonym);
                      if (success) {
                        setState(() {
                          // Just trigger a rebuild
                        });
                      }
                    } else {
                      success = await service.markAntonym(wordId, cleanAntonym);
                      
                      // Show a snackbar suggesting to play the game if antonym was successfully marked
                      if (success) {
                        setState(() {
                          // Just trigger a rebuild
                        });
                      }
                    }
                  },
                  child: Chip(
                    label: Text(
                      cleanAntonym,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    backgroundColor: isMarked
                        ? (isDarkMode ? Colors.red.shade800 : Colors.red.shade100)
                        : (isDarkMode ? theme.colorScheme.errorContainer.withOpacity(0.7) : theme.colorScheme.errorContainer.withOpacity(0.7)),
                    side: isMarked 
                        ? BorderSide(color: isDarkMode ? Colors.red : Colors.red.shade700, width: 1.5)
                        : null,
                    avatar: isMarked 
                        ? Icon(
                            Icons.check_circle, 
                            size: 16, 
                            color: isDarkMode ? Colors.red.shade300 : Colors.red.shade700
                          )
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // Build the tenses practice section
  Widget _buildTensesPracticeSection(String wordId, bool isDarkMode, ThemeData theme) {
    return FutureBuilder<bool>(
      future: sl<TensesGameService>().isWordMarkedForTenses(wordId),
      builder: (context, snapshot) {
        final isMarked = snapshot.data ?? false;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tenses Practice:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _toggleTensesMark(wordId),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isMarked 
                      ? (isDarkMode ? Colors.indigo.shade800 : Colors.indigo.shade100)
                      : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                  border: isMarked
                      ? Border.all(color: isDarkMode ? Colors.indigo.shade300 : Colors.indigo)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMarked ? Icons.check_circle : Icons.access_time,
                      size: 20,
                      color: isMarked
                          ? (isDarkMode ? Colors.indigo.shade300 : Colors.indigo)
                          : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isMarked ? 'Marked for Tenses Practice' : 'Mark for Tenses Practice',
                      style: TextStyle(
                        fontSize: 14,
                        color: isMarked
                            ? (isDarkMode ? Colors.indigo.shade300 : Colors.indigo)
                            : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isMarked) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Practice Now'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  context.push(AppConstants.markedTensesGameRoute);
                },
              ),
            ],
          ],
        );
      },
    );
  }
  
  // Toggle marking a word for tenses practice
  Future<void> _toggleTensesMark(String wordId) async {
    try {
      final service = sl<TensesGameService>();
      final isCurrentlyMarked = await service.isWordMarkedForTenses(wordId);
      
      if (isCurrentlyMarked) {
        // Unmark
        final success = await service.unmarkWordForTenses(wordId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from Tenses Practice'),
            ),
          );
        }
      } else {
        // Mark
        final success = await service.markWordForTenses(wordId);
        // Don't show the notification here since we already have buttons in the UI
      }
      
      // Force a rebuild
      setState(() {});
      
    } catch (e) {
      debugPrint('Error toggling tenses mark: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Add the _buildImageDisplay method
  Widget _buildImageDisplay(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return _buildNetworkImage(imageUrl);
    } else if (imageUrl.startsWith('data:')) {
      return _buildDataUrlImage(imageUrl);
    } else if (imageUrl.startsWith('blob:')) {
      return _buildWebBlobImage(imageUrl);
    } else if (imageUrl.startsWith('file:') || !imageUrl.contains(':')) {
      return _buildFileImage(imageUrl);
    } else if (imageUrl.startsWith('asset:')) {
      return _buildAssetImage(imageUrl.replaceFirst('asset:', ''));
    } else {
      return _buildEmojiDisplay();
    }
  }
}