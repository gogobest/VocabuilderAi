import 'package:flutter/material.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/features/vocabulary/data/services/vocabulary_ai_service.dart';
import 'package:visual_vocabularies/features/vocabulary/data/services/vocabulary_image_service.dart';
import 'package:uuid/uuid.dart';
import 'package:visual_vocabularies/features/media/domain/repositories/media_repository.dart';
import 'package:visual_vocabularies/features/media/domain/entities/media_item.dart';
import 'package:visual_vocabularies/core/di/injection_container.dart';

import 'tts_helper.dart';
import 'category_dropdown.dart';
import 'tense_variations_section.dart';
import 'image_section.dart';
import 'record_button.dart';

/// A form widget for adding or editing vocabulary items
class VocabularyForm extends StatefulWidget {
  /// Existing vocabulary item for editing (null for new items)
  final VocabularyItem? existingItem;
  
  /// Pre-selected category
  final String? categoryFilter;
  
  /// Callback when form is submitted
  final Function(Map<String, dynamic>) onSubmit;
  
  /// Whether the form is currently loading
  final bool isLoading;

  /// Callback when form is changed
  final VoidCallback? onChanged;
  
  /// Controller for the word field
  final TextEditingController? wordController;

  /// Constructor for VocabularyForm
  const VocabularyForm({
    super.key,
    this.existingItem,
    this.categoryFilter,
    required this.onSubmit,
    this.isLoading = false,
    this.onChanged,
    this.wordController,
  });

  @override
  State<VocabularyForm> createState() => _VocabularyFormState();
}

class _VocabularyFormState extends State<VocabularyForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _wordController;
  final _meaningController = TextEditingController();
  final _exampleController = TextEditingController();
  final _pronunciationController = TextEditingController();
  final _emojiController = TextEditingController();
  final _synonymsController = TextEditingController();
  final _antonymsController = TextEditingController();
  final _sourceMediaController = TextEditingController();
  final _partOfSpeechNoteController = TextEditingController();
  
  // Services
  final VocabularyAiService _aiService = VocabularyAiService();
  final VocabularyImageService _imageService = VocabularyImageService();
  
  // Text-to-speech and recording
  late TtsHelper _ttsHelper;
  
  // State variables
  String _selectedCategory = AppConstants.defaultCategories.first;
  String _selectedPartOfSpeech = 'noun';
  int _difficultyLevel = 3;
  String? _selectedImageUrl;
  String? _wordEmoji;
  List<String> _synonyms = [];
  List<String> _antonyms = [];
  bool _showSynonymsAntonyms = false;
  bool _isImageLoading = false;
  bool _isEmojiLoading = false;
  String? _recordingPath;
  String _wordId = const Uuid().v4(); // Generate a unique ID for this word
  
  // Parts of speech options
  final List<String> _partsOfSpeech = [
    'noun', 'verb', 'adjective', 'adverb', 'pronoun', 
    'preposition', 'conjunction', 'interjection', 'phrase'
  ];
  
  // Media sources
  bool _isLoadingMediaSources = false;
  List<String> _mediaSourceOptions = [];
  bool _showMediaSourceDropdown = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize word controller - use the one passed in if available
    _wordController = widget.wordController ?? TextEditingController();
    
    // Initialize text-to-speech
    _ttsHelper = TtsHelper(context);
    
    // If editing, populate fields with existing item data
    if (widget.existingItem != null) {
      _populateFormWithExistingItem();
    }
    // Set pre-selected category if provided (only if not editing)
    else if (widget.categoryFilter != null) {
      _selectedCategory = widget.categoryFilter!;
    }

    // Load media sources
    _loadMediaSources();
    
    _meaningController.addListener(() {
      _updateCategoryFromMeaning();
      _notifyFormChanged();
    });
    
    // Add listeners to other controllers
    _wordController.addListener(_notifyFormChanged);
    _exampleController.addListener(_notifyFormChanged);
    _pronunciationController.addListener(_notifyFormChanged);
    _synonymsController.addListener(_notifyFormChanged);
    _antonymsController.addListener(_notifyFormChanged);
    _emojiController.addListener(_notifyFormChanged);
    _sourceMediaController.addListener(_notifyFormChanged);
    _partOfSpeechNoteController.addListener(_notifyFormChanged);
  }

  @override
  void didUpdateWidget(VocabularyForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if existingItem has changed and is not null
    if (widget.existingItem != null && widget.existingItem != oldWidget.existingItem) {
      _populateFormWithExistingItem();
    }
  }

  @override
  void dispose() {
    // Only dispose controllers we created internally
    if (widget.wordController == null) {
      _wordController.dispose();
    }
    _meaningController.dispose();
    _exampleController.dispose();
    _pronunciationController.dispose();
    _synonymsController.dispose();
    _antonymsController.dispose();
    _emojiController.dispose();
    _sourceMediaController.dispose();
    _partOfSpeechNoteController.dispose();
    _ttsHelper.dispose();
    super.dispose();
  }
  
  void _populateFormWithExistingItem() {
    final item = widget.existingItem!;
    
    // Use existing word ID if available, otherwise keep the generated one
    if (item.id != null && item.id!.isNotEmpty) {
      _wordId = item.id!;
    }
    
    // Only set word if not using external controller
    if (widget.wordController == null) {
      _wordController.text = item.word;
    }
    
    _meaningController.text = item.meaning;
    _exampleController.text = item.example ?? '';
    _pronunciationController.text = item.pronunciation ?? '';
    _sourceMediaController.text = item.sourceMedia ?? '';
    
    // Ensure category is valid and set it from the item, not the default
    debugPrint('Setting category from existing item: ${item.category}');
    _selectedCategory = item.category;
    
    _difficultyLevel = item.difficultyLevel ?? 3;
    
    // Set part of speech from the item
    if (item.partOfSpeech != null && _partsOfSpeech.contains(item.partOfSpeech)) {
      _selectedPartOfSpeech = item.partOfSpeech!;
    } else {
      _selectedPartOfSpeech = 'noun'; // Default to noun
    }
    
    _selectedImageUrl = item.imageUrl;
    _wordEmoji = item.wordEmoji;
    _emojiController.text = item.wordEmoji ?? '';
    
    // Set recording path if available
    _recordingPath = item.recordingPath;
    
    if (item.synonyms != null && item.synonyms!.isNotEmpty) {
      _synonyms = List<String>.from(item.synonyms!);
      _synonymsController.text = _synonyms.join(', ');
      _showSynonymsAntonyms = true;
    }
    
    if (item.antonyms != null && item.antonyms!.isNotEmpty) {
      _antonyms = List<String>.from(item.antonyms!);
      _antonymsController.text = _antonyms.join(', ');
      _showSynonymsAntonyms = true;
    }
    
    _partOfSpeechNoteController.text = item.partOfSpeechNote ?? '';
  }
  
  // Update category based on word meaning
  void _updateCategoryFromMeaning() {
    if (_meaningController.text.isNotEmpty) {
      final meaning = _meaningController.text.trim().toLowerCase();
      
      // Simple category matching based on meaning keywords
      for (final entry in AppConstants.wordCategoryEmojis.entries) {
        if (meaning.contains(entry.key)) {
          // Map emoji categories to actual categories
          final category = _mapEmojiKeyToCategory(entry.key);
          if (category != null && AppConstants.defaultCategories.contains(category)) {
            setState(() {
              _selectedCategory = category;
            });
            break;
          }
        }
      }
    }
  }
  
  // Map emoji key to actual category
  String? _mapEmojiKeyToCategory(String key) {
    const Map<String, String> keyToCategory = {
      'business': 'Business',
      'tech': 'Technology',
      'science': 'Science',
      'travel': 'Travel',
      'trip': 'Travel',
      'food': 'Food',
      'cuisine': 'Food',
      'sport': 'Sports',
      'art': 'Arts',
      'music': 'Arts',
      'book': 'Education',
      'study': 'Education',
      'school': 'Education',
      'health': 'Health',
      'medical': 'Health',
    };
    
    return keyToCategory[key];
  }
  

  
  String? _findEmojiForWord(String word, String meaning) {
    final lowercaseWord = word.toLowerCase();
    final lowercaseMeaning = meaning.toLowerCase();
    
    // Look for direct matches in our emoji map
    for (final entry in AppConstants.wordCategoryEmojis.entries) {
      if (lowercaseWord.contains(entry.key) || lowercaseMeaning.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isImageLoading = true;
      });
      
      final imagePath = await _imageService.pickImageFromGallery();
      
      setState(() {
        _selectedImageUrl = imagePath;
        _isImageLoading = false;
      });
    } catch (e) {
      setState(() {
        _isImageLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      setState(() {
        _isImageLoading = true;
      });
      
      final imagePath = await _imageService.takePhoto();
      
      setState(() {
        _selectedImageUrl = imagePath;
        _isImageLoading = false;
      });
    } catch (e) {
      setState(() {
        _isImageLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateImage() async {
    final word = _wordController.text.trim();
    final meaning = _meaningController.text.trim();
    
    if (word.isEmpty || meaning.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Word and meaning are required to generate an image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      setState(() {
        _isImageLoading = true;
      });
      
      final generatedImageUrl = await _imageService.generateImageForWord(word, meaning);
      
      // Generate and update emoji using the enhanced emoji generator
      final generatedEmoji = _imageService.generateEmojiForWord(word, meaning);
      
      setState(() {
        _selectedImageUrl = generatedImageUrl;
        _isImageLoading = false;
        
        // Update the emoji field with a better generated emoji
        _emojiController.text = generatedEmoji;
        _wordEmoji = generatedEmoji;
      });
    } catch (e) {
      setState(() {
        _isImageLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImageUrl = null;
      // Make sure we have an emoji to display when the image is cleared
      if (_emojiController.text.isEmpty) {
        _generateEmojiOnly();
      }
      debugPrint('Image cleared, emoji will be used: ${_emojiController.text}');
    });
  }
  
  // Search and use a GIF as the image
  Future<void> _searchGifForEmoji() async {
    final word = _wordController.text.trim();
    final meaning = _meaningController.text.trim();
    
    if (word.isEmpty || meaning.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Word and meaning are required to search for a GIF'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      setState(() {
        _isImageLoading = true;
      });
      
      final gifUrl = await _imageService.searchGifForWord(word, meaning);
      
      setState(() {
        _selectedImageUrl = gifUrl;
        _isImageLoading = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GIF successfully found and set as the image!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isImageLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error finding GIF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Generate a more accurate emoji based on word meaning
  Future<void> _generateEmojiOnly() async {
    final word = _wordController.text.trim();
    final meaning = _meaningController.text.trim();
    
    if (word.isEmpty || meaning.isEmpty) {
      // Use Future.microtask to schedule showing the snackbar after the build is complete
      Future.microtask(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Word and meaning are required to generate an emoji'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
      return;
    }
    
    try {
      // Update state before starting the async operation
      if (mounted) {
        setState(() {
          _isEmojiLoading = true;
        });
      }
      
      // Use Future.microtask to schedule showing the snackbar after the build is complete
      Future.microtask(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Generating emoji...'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      });
      
      // First try to use AI service for more accurate emoji
      final aiService = VocabularyAiService();
      String? aiEmoji;
      try {
        // Use the enhanced AI method specifically for generating emojis
        aiEmoji = await aiService.generateEmoji(word, meaning);
        
        if (aiEmoji != null && aiEmoji.isNotEmpty) {
          // If AI generated a valid emoji, use it
          if (mounted) {
            setState(() {
              _emojiController.text = aiEmoji!;
              _wordEmoji = aiEmoji;
              _isEmojiLoading = false;
            });
          
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('New emoji generated: $aiEmoji'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('AI emoji generation failed: $e');
        // Will proceed to fallback method below
      }
      
      // Fallback to the local emoji generator
      final newEmoji = _imageService.generateEmojiForWord(word, meaning);
      
      // Force a delay to ensure UI state is updated properly
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        setState(() {
          _emojiController.text = newEmoji;
          _wordEmoji = newEmoji;
          _isEmojiLoading = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New emoji generated: $newEmoji'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEmojiLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating emoji: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Update recording path when a new recording is saved
  void _onRecordingSaved(String? path) {
    setState(() {
      _recordingPath = path;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Gather form data
      final formData = <String, dynamic>{
        'word': _wordController.text.trim(),
        'meaning': _meaningController.text.trim(),
        'example': _exampleController.text.trim().isNotEmpty ? _exampleController.text.trim() : null,
        'category': _selectedCategory,
        'difficultyLevel': _difficultyLevel,
        'imageUrl': _selectedImageUrl,
        'pronunciation': _pronunciationController.text.trim(),
        'partOfSpeech': _selectedPartOfSpeech,
        'sourceMedia': _sourceMediaController.text.trim().isNotEmpty ? _sourceMediaController.text.trim() : null,
        'emoji': _emojiController.text.trim(),
        'partOfSpeechNote': _partOfSpeechNoteController.text.trim().isNotEmpty ? _partOfSpeechNoteController.text.trim() : null,
      };
      
      // Process synonyms and antonyms
      if (_synonymsController.text.isNotEmpty) {
        _synonyms = _synonymsController.text.split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        formData['synonyms'] = _synonyms;
      }
      
      if (_antonymsController.text.isNotEmpty) {
        _antonyms = _antonymsController.text.split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        formData['antonyms'] = _antonyms;
      }
      
      // Processing alternate meanings
      if (widget.existingItem?.alternateMeanings != null) {
        formData['alternateMeanings'] = widget.existingItem!.alternateMeanings;
      }
      
      // Set recording path if available
      if (_recordingPath != null) {
        formData['recordingPath'] = _recordingPath;
      }
      
      // Link with media source if specified
      _addMediaIdToFormData(formData).then((_) {
        // Submit form data to parent widget
        widget.onSubmit(formData);
      });
    }
  }
  
  // Helper method to extract media ID and update formData
  Future<void> _addMediaIdToFormData(Map<String, dynamic> formData) async {
    final sourceMedia = formData['sourceMedia'] as String?;
    if (sourceMedia == null || sourceMedia.isEmpty) {
      return;
    }
    
    try {
      // Extract information from formatted source media string
      String? title;
      int? season;
      int? episode;
      
      // Parse source media string based on format
      if (sourceMedia.startsWith('TV Show:')) {
        final tvShowInfo = sourceMedia.replaceFirst('TV Show:', '').trim();
        // Extract title and season/episode
        final seasonEpisodeRegex = RegExp(r'S(\d+)E(\d+)');
        final match = seasonEpisodeRegex.firstMatch(tvShowInfo);
        
        if (match != null) {
          // Extract season and episode numbers
          season = int.tryParse(match.group(1) ?? '');
          episode = int.tryParse(match.group(2) ?? '');
          
          // Extract title by removing the season/episode part
          title = tvShowInfo.split(' S')[0].trim();
        } else {
          title = tvShowInfo; // Just use the whole string if format is unexpected
        }
      } else if (sourceMedia.startsWith('Movie:')) {
        title = sourceMedia.replaceFirst('Movie:', '').trim();
      } else if (sourceMedia.startsWith('Book:')) {
        // Extract book title (and possibly author)
        final bookInfo = sourceMedia.replaceFirst('Book:', '').trim();
        
        // Handle book with author format: "Title" by Author
        final authorMatch = RegExp(r'"([^"]+)"\s+by\s+(.+)').firstMatch(bookInfo);
        
        if (authorMatch != null) {
          title = authorMatch.group(1)?.trim();
        } else {
          // Just the title in quotes
          final titleMatch = RegExp(r'"([^"]+)"').firstMatch(bookInfo);
          title = titleMatch?.group(1)?.trim() ?? bookInfo;
        }
      }
      
      // If we have a title, try to find the media item
      if (title != null) {
        final mediaRepo = sl<MediaRepository>();
        List<MediaItem> matchingItems = [];
        
        if (season != null && episode != null) {
          // Look for TV Show with specific season and episode
          matchingItems = await mediaRepo.getMediaItemsByEpisode(title, season, episode);
        } else if (season != null) {
          // Look for TV Show with specific season
          matchingItems = await mediaRepo.getMediaItemsBySeason(title, season);
        } else {
          // Look for movie or book by title
          matchingItems = await mediaRepo.getMediaItemsByTitle(title);
        }
        
        if (matchingItems.isNotEmpty) {
          // Use the first matching item
          formData['mediaId'] = matchingItems.first.id;
        }
      }
    } catch (e) {
      debugPrint('Error processing media source: $e');
      // Continue without media ID
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  // Load available media sources from repository
  Future<void> _loadMediaSources() async {
    setState(() {
      _isLoadingMediaSources = true;
    });

    try {
      final mediaRepository = sl<MediaRepository>();
      final mediaItems = await mediaRepository.getAllMediaItems();
      
      final sources = <String>{};
      
      // Extract unique media titles
      for (final item in mediaItems) {
        // Format TV shows with season/episode info
        if (item.season != null && item.episode != null) {
          sources.add('TV Show: ${item.title} S${item.season.toString().padLeft(2, '0')}E${item.episode.toString().padLeft(2, '0')}');
        } 
        // Format books with author
        else if (item.author != null) {
          sources.add('Book: "${item.title}" by ${item.author}');
        }
        // Plain movie titles
        else {
          sources.add('Movie: ${item.title}');
        }
      }
      
      setState(() {
        _mediaSourceOptions = sources.toList()..sort();
        _isLoadingMediaSources = false;
      });
    } catch (e) {
      debugPrint('Error loading media sources: $e');
      setState(() {
        _isLoadingMediaSources = false;
      });
    }
  }

  // Update the _showMediaSourceSelection method to save the relation to media sources
  void _showMediaSourceSelection() {
    if (_mediaSourceOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No media sources available. Add media first in the Media Center.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Media Source'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _mediaSourceOptions.length,
            itemBuilder: (context, index) {
              final source = _mediaSourceOptions[index];
              return ListTile(
                title: Text(source),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _sourceMediaController.text = source;
                    _notifyFormChanged();
                  });
                  
                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to "$source"'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          // Add "Create New" button
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCreateNewMediaDialog();
            },
            child: const Text('CREATE NEW'),
          ),
        ],
      ),
    );
  }

  // Method to create a new media source
  void _showCreateNewMediaDialog() {
    final TextEditingController titleController = TextEditingController();
    String? mediaType = 'Movie';
    int? season;
    int? episode;
    final TextEditingController authorController = TextEditingController();
    final TextEditingController imageUrlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create New Media Source'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: mediaType,
                    decoration: const InputDecoration(
                      labelText: 'Media Type',
                    ),
                    items: ['Movie', 'TV Show', 'Book'].map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        mediaType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'Enter media title',
                    ),
                  ),
                  if (mediaType == 'TV Show') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Season',
                              hintText: 'Season number',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                season = int.tryParse(value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Episode',
                              hintText: 'Episode number',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                episode = int.tryParse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (mediaType == 'Book') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: authorController,
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        hintText: 'Enter book author',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Cover Image URL (Optional)',
                      hintText: 'Enter URL for cover image',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a title'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  String formattedSource = '';
                  if (mediaType == 'TV Show') {
                    final seasonStr = season != null ? 'S${season.toString().padLeft(2, '0')}' : 'S01';
                    final episodeStr = episode != null ? 'E${episode.toString().padLeft(2, '0')}' : 'E01';
                    formattedSource = 'TV Show: $title $seasonStr$episodeStr';
                  } else if (mediaType == 'Movie') {
                    formattedSource = 'Movie: $title';
                  } else if (mediaType == 'Book') {
                    final author = authorController.text.trim();
                    formattedSource = 'Book: "$title"${author.isNotEmpty ? " by $author" : ""}';
                  }
                  
                  // Create and save the actual media item to the repository
                  try {
                    final newMediaItem = MediaItem(
                      id: const Uuid().v4(),
                      title: title,
                      season: season,
                      episode: episode,
                      coverImageUrl: imageUrlController.text.trim().isNotEmpty ? imageUrlController.text.trim() : null,
                      vocabularyItemIds: [],  // Will be updated when word is saved
                      author: mediaType == 'Book' ? authorController.text.trim() : null,
                    );
                    
                    final mediaRepo = sl<MediaRepository>();
                    await mediaRepo.addMediaItem(newMediaItem);

                    // IMPORTANT: Update parent state before closing dialog
                    // Store the values we need before closing dialog
                    final String mediaSourceText = formattedSource;
                    
                    // Close dialog before making any setState calls in the parent
                    Navigator.pop(context);
                    
                    // Now update the parent widget's state safely
                    this.setState(() {
                      _sourceMediaController.text = mediaSourceText;
                      // Add to options for future selection
                      if (!_mediaSourceOptions.contains(mediaSourceText)) {
                        _mediaSourceOptions.add(mediaSourceText);
                        _mediaSourceOptions.sort();
                      }
                      _notifyFormChanged();
                    });
                    
                    // Show confirmation
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Created and added to "$mediaSourceText"'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } catch (e) {
                    // Close dialog first
                    Navigator.pop(context);
                    
                    // Then show error in the parent context
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating media: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('CREATE'),
              ),
            ],
          );
        }
      ),
    ).then((_) {
      // Clean up controllers in any case
      titleController.dispose();
      authorController.dispose();
      imageUrlController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Update the Media Source field to show a button for selection
    Widget buildMediaSourceField() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _sourceMediaController,
                  decoration: const InputDecoration(
                    labelText: 'Media Source',
                    hintText: 'TV Show, Movie, or Book',
                    prefixIcon: Icon(Icons.movie),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.list),
                label: const Text('Browse'),
                onPressed: _isLoadingMediaSources ? null : _showMediaSourceSelection,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select an existing media source or type a new one',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word field with Recording/Part of Speech
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _wordController,
                    decoration: const InputDecoration(
                      labelText: 'Word *',
                      hintText: 'Enter the vocabulary word',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a word';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedPartOfSpeech,
                    decoration: const InputDecoration(
                      labelText: 'Part of Speech',
                      // Make field more compact
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      isDense: true,
                    ),
                    isDense: true,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    items: _partsOfSpeech.map((pos) {
                      return DropdownMenuItem<String>(
                        value: pos,
                        child: Text(
                          pos,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPartOfSpeech = value;
                        });
                      }
                    },
                  ),
                ),
                RecordButton(
                  wordId: _wordId,
                  recordingPath: _recordingPath,
                  ttsHelper: _ttsHelper,
                  onRecordingSaved: _onRecordingSaved,
                ),
              ],
            ),
            
            // Part of Speech Note (if available)
            _buildPartOfSpeechNote(),
            
            const SizedBox(height: 16),
            
            // Emoji field
            TextFormField(
              controller: _emojiController,
              decoration: const InputDecoration(
                labelText: 'Emoji',
                hintText: 'An emoji that represents this word',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Synonyms field
            TextFormField(
              controller: _synonymsController,
              decoration: const InputDecoration(
                labelText: 'Synonyms',
                hintText: 'Enter synonyms separated by commas',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Antonyms field
            TextFormField(
              controller: _antonymsController,
              decoration: const InputDecoration(
                labelText: 'Antonyms',
                hintText: 'Enter antonyms separated by commas',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Image section
            ImageSection(
              isLoading: _isImageLoading,
              selectedImageUrl: _selectedImageUrl,
              emoji: _emojiController.text,
              imageService: _imageService,
              onPickImage: _pickImage,
              onTakePhoto: _takePhoto,
              onGenerateImage: _generateImage,
              onClearImage: _clearImage,
              onSearchGif: _searchGifForEmoji,
              onGenerateEmoji: _generateEmojiOnly,
              disabled: widget.isLoading,
            ),
            
            const SizedBox(height: 16),
            
            // Meaning field
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _meaningController,
                    decoration: const InputDecoration(
                      labelText: 'Meaning *',
                      hintText: 'Enter the meaning of the word',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a meaning';
                      }
                      return null;
                    },
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            
            // Alternative meanings based on other parts of speech
            _buildAlternateMeanings(),
            
            const SizedBox(height: 16),
            
            // Example field
            TextFormField(
              controller: _exampleController,
              decoration: const InputDecoration(
                labelText: 'Example',
                hintText: 'Enter an example sentence using this word',
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // Category dropdown
            CategoryDropdown(
              selectedCategory: _selectedCategory,
              onCategoryChanged: _onCategoryChanged,
            ),
            
            const SizedBox(height: 16),
            
            // Difficulty slider
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Difficulty Level'),
              subtitle: Slider(
                value: _difficultyLevel.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _difficultyLevel.toString(),
                onChanged: (value) {
                  setState(() {
                    _difficultyLevel = value.round();
                  });
                },
              ),
              trailing: Text(
                _difficultyLevel.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Media Source
            buildMediaSourceField(),
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : _submitForm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: widget.isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          widget.existingItem != null 
                            ? 'Update Word' 
                            : 'Add Word',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Display a note about multiple parts of speech if available
  Widget _buildPartOfSpeechNote() {
    // Check if we have a part of speech note from existing item
    String? partOfSpeechNote;
    if (widget.existingItem != null) {
      partOfSpeechNote = widget.existingItem!.partOfSpeechNote;
    }
    
    if (partOfSpeechNote != null && partOfSpeechNote.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Card(
          color: Colors.amber.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        partOfSpeechNote,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
  
  /// Display alternate meanings based on other parts of speech
  Widget _buildAlternateMeanings() {
    // Check if we have alternate meanings from existing item
    Map<String, String>? alternateMeanings;
    if (widget.existingItem != null && widget.existingItem!.alternateMeanings != null) {
      alternateMeanings = widget.existingItem!.alternateMeanings;
    }
    
    if (alternateMeanings != null && alternateMeanings.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alternative Meanings:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            ...alternateMeanings.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, 
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.value),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Switch to this part of speech',
                      onPressed: () {
                        _switchToAlternatePartOfSpeech(entry.key, entry.value);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
  
  /// Switch to an alternate part of speech
  void _switchToAlternatePartOfSpeech(String partOfSpeech, String meaning) {
    setState(() {
      // Store current meaning as an alternate
      final currentMeaning = _meaningController.text;
      final currentPartOfSpeech = _selectedPartOfSpeech;
      
      // Create or update alternate meanings map
      Map<String, String> alternateMeanings = 
          widget.existingItem?.alternateMeanings != null 
          ? Map<String, String>.from(widget.existingItem!.alternateMeanings!)
          : {};
      
      // Add current meaning to alternates
      alternateMeanings[currentPartOfSpeech] = currentMeaning;
      
      // Update the part of speech and meaning
      _selectedPartOfSpeech = partOfSpeech;
      _meaningController.text = meaning;
      
      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to $partOfSpeech definition'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  // Add this method to track changes to form fields
  void _notifyFormChanged() {
    if (widget.onChanged != null) {
      widget.onChanged!();
    }
  }
} 
