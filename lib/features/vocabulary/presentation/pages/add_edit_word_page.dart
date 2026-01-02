import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/di/injection_container.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc_exports.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/widgets/vocabulary_form/vocabulary_form.dart';
import 'package:visual_vocabularies/features/vocabulary/data/services/vocabulary_ai_service.dart';
import 'package:visual_vocabularies/features/vocabulary/data/services/vocabulary_image_service.dart';
import 'package:visual_vocabularies/core/utils/ai_word_generator.dart';
import 'package:visual_vocabularies/core/widgets/app_navigation_bar.dart';
import 'package:visual_vocabularies/features/media/domain/repositories/media_repository.dart';
import 'package:visual_vocabularies/features/media/domain/entities/media_item.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

/// Page for adding or editing vocabulary items
class AddEditWordPage extends StatefulWidget {
  /// The ID of the vocabulary item to edit, or null for adding a new item
  final String? id;
  
  /// Pre-selected category for new items
  final String? categoryFilter;

  /// Constructor for AddEditWordPage
  const AddEditWordPage({
    super.key,
    this.id,
    this.categoryFilter,
  });

  @override
  State<AddEditWordPage> createState() => _AddEditWordPageState();
}

class _AddEditWordPageState extends State<AddEditWordPage> {
  late final VocabularyBloc _vocabularyBloc;
  bool _isLoading = false;
  VocabularyItem? _existingItem;
  final VocabularyAiService _aiService = VocabularyAiService();
  final VocabularyImageService _imageService = VocabularyImageService();
  final AiWordGenerator _aiWordGenerator = const AiWordGenerator();
  bool _hasChanges = false;
  final TextEditingController _wordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vocabularyBloc = sl<VocabularyBloc>();
    
    // Load categories
    _vocabularyBloc.add(const LoadCategories());
    
    // If editing, load the existing item
    if (widget.id != null) {
      _loadExistingItem();
    }
  }

  void _loadExistingItem() {
    _vocabularyBloc.add(
      LoadVocabularyItemById(widget.id!),
    );
  }
  
  void _handleFormSubmit(Map<String, dynamic> formData) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Process data from form
      final word = formData['word'] as String;
      final meaning = formData['meaning'] as String;
      final example = formData['example'] as String?;
      final category = formData['category'] as String;
      final difficultyLevel = formData['difficultyLevel'] as int;
      
      // Handle imageUrl - explicitly set to null when cleared rather than empty string
      String? imageUrl = (formData['imageUrl'] as String?)?.isNotEmpty == true 
                        ? formData['imageUrl'] as String? 
                        : null;
      
      // Process the image URL if not null to ensure it's optimized
      if (imageUrl != null && imageUrl.isNotEmpty) {
        debugPrint('Processing image URL before saving: ${imageUrl.substring(0, math.min(50, imageUrl.length))}...');
        imageUrl = await _imageService.processImageUrl(imageUrl);
      }
                        
      final pronunciation = formData['pronunciation'] as String?;
      final partOfSpeech = formData['partOfSpeech'] as String?;
      
      // Media source handling
      String? sourceMedia = formData['sourceMedia'] as String?;
      // If sourceMedia is provided but doesn't match TV show format, format it correctly
      if (sourceMedia != null && sourceMedia.isNotEmpty) {
        if (!sourceMedia.contains('TV Show:')) {
          // Check if it looks like a TV show or movie format
          final tvShowMatch = RegExp(r'S\d+E\d+').hasMatch(sourceMedia);
          if (tvShowMatch) {
            // Format as TV show with our prefix
            sourceMedia = 'TV Show: $sourceMedia';
          }
        }
      }
      
      // Get the new fields for multiple parts of speech
      final partOfSpeechNote = formData['partOfSpeechNote'] as String?;
      final alternateMeanings = formData['alternateMeanings'] as Map<String, String>?;

      // Convert synonyms and antonyms to correct types
      List<String> synonyms = [];
      List<String> antonyms = [];

      if (formData['synonyms'] is List<String>) {
        synonyms = formData['synonyms'] as List<String>;
      } else if (formData['synonyms'] != null) {
        // Handle potential conversion issues
        synonyms = (formData['synonyms'] as List<dynamic>).map((e) => e.toString()).toList();
      }

      if (formData['antonyms'] is List<String>) {
        antonyms = formData['antonyms'] as List<String>;
      } else if (formData['antonyms'] != null) {
        // Handle potential conversion issues
        antonyms = (formData['antonyms'] as List<dynamic>).map((e) => e.toString()).toList();
      }
      
      // Capture the BuildContext before the async operation
      final currentContext = context;
      
      // Ensure we have an emoji even if the image is cleared
      String? finalEmoji = formData['emoji'] as String?;
      if (finalEmoji == null || finalEmoji.isEmpty) {
        debugPrint('No emoji provided, generating one for: $word');
        finalEmoji = await _imageService.generateEmoji(word, meaning: meaning) ?? '📝';
      }
      
      debugPrint('Updating vocabulary item - imageUrl: ${imageUrl != null ? "present" : "null"}, emoji: $finalEmoji, category: $category');

      // Create the vocabulary item
      VocabularyItem updatedItem;
      String itemId;
      
      // If editing, update the existing item, otherwise create new
      if (widget.id != null && _existingItem != null) {
        itemId = _existingItem!.id;
        updatedItem = _existingItem!.copyWith(
          word: word,
          meaning: meaning,
          example: example,
          category: category,
          difficultyLevel: difficultyLevel,
          imageUrl: imageUrl, // Will be null if the image was cleared
          wordEmoji: finalEmoji,
          pronunciation: pronunciation,
          partOfSpeech: partOfSpeech,
          sourceMedia: sourceMedia,
          partOfSpeechNote: partOfSpeechNote,
          alternateMeanings: alternateMeanings,
          synonyms: synonyms,
          antonyms: antonyms,
        );
      } else {
        // Create a new item
        itemId = const Uuid().v4();
        updatedItem = VocabularyItem(
          id: itemId,
          word: word,
          meaning: meaning,
          example: example,
          category: category,
          difficultyLevel: difficultyLevel,
          imageUrl: imageUrl,
          wordEmoji: finalEmoji,
          pronunciation: pronunciation,
          partOfSpeech: partOfSpeech,
          sourceMedia: sourceMedia,
          partOfSpeechNote: partOfSpeechNote,
          alternateMeanings: alternateMeanings,
          synonyms: synonyms,
          antonyms: antonyms,
        );
      }

      // Process media relationship if a media ID was provided
      if (formData['mediaId'] is String) {
        final mediaId = formData['mediaId'] as String;
        if (mediaId.isNotEmpty) {
          try {
            // Get the media repository
            final mediaRepo = sl<MediaRepository>();
            
            // Get the current media item
            final mediaItem = await mediaRepo.getMediaItemById(mediaId);
            
            if (mediaItem != null) {
              // Add this vocabulary item to the media item's vocabulary items list
              final vocabularyItemIds = [...mediaItem.vocabularyItemIds];
              if (!vocabularyItemIds.contains(itemId)) {
                vocabularyItemIds.add(itemId);
                
                // Update the media item
                final updatedMediaItem = mediaItem.copyWith(
                  vocabularyItemIds: vocabularyItemIds,
                );
                
                // Save the updated media item
                await mediaRepo.addMediaItem(updatedMediaItem);
                debugPrint('Added vocabulary item $itemId to media item $mediaId');
              }
            }
          } catch (e) {
            debugPrint('Error updating media item with vocabulary ID: $e');
            // Continue with saving the vocabulary item even if media update fails
          }
        }
      }

      // Save to the repository
      if (widget.id != null) {
        _vocabularyBloc.add(UpdateVocabularyItem(updatedItem));
      } else {
        _vocabularyBloc.add(AddVocabularyItem(updatedItem));
      }

      // Navigate back on success using WidgetsBinding to avoid async gap issues
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.canPop(currentContext)) {
            Navigator.of(currentContext).pop();
            // Force a reload of vocabulary items to update flashcards
            _vocabularyBloc.add(const LoadVocabularyItems());
          }
        });
      }
    } catch (e) {
      // Show error message using a stored context reference
      if (mounted) {
        // Use a post-frame callback to avoid async gap issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving vocabulary item: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          _showDiscardChangesDialog(context);
          return false;
        }
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          context.go(AppConstants.homeRoute);
        }
        return false;
      },
      child: BlocProvider.value(
        value: _vocabularyBloc,
        child: BlocListener<VocabularyBloc, VocabularyState>(
          listener: (context, state) {
            if (state is VocabularyItemLoaded) {
              setState(() {
                _existingItem = state.item;
                // Initialize the word controller with the existing word
                _wordController.text = state.item.word;
              });
            } else if (state is VocabularyOperationSuccess) {
              // Handle successful operation
              setState(() {
                _isLoading = false;
              });
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Navigate back safely after the frame is complete
              Future.microtask(() {
                if (mounted && Navigator.canPop(context)) {
                  context.pop();
                }
              });
            } else if (state is VocabularyError) {
              // Handle error
              setState(() {
                _isLoading = false;
              });
              
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Stack(
            children: [
              Scaffold(
                appBar: AppNavigationBar(
                  title: widget.id != null ? 'Edit Word' : 'Add New Word',
                  onBackPressed: () {
                    if (_hasChanges) {
                      _showDiscardChangesDialog(context);
                    } else {
                      context.pop();
                    }
                  },
                  actions: [
                    // AI generation button
                    IconButton(
                      icon: const Icon(Icons.auto_awesome),
                      tooltip: 'Generate with AI',
                      onPressed: _isLoading ? null : _showAiGenerationOptions,
                    ),
                  ],
                ),
                body: BlocBuilder<VocabularyBloc, VocabularyState>(
                  builder: (context, state) {
                    if (state is VocabularyLoading && widget.id != null && _existingItem == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    return VocabularyForm(
                      existingItem: _existingItem,
                      categoryFilter: widget.categoryFilter,
                      onSubmit: _handleFormSubmit,
                      isLoading: _isLoading,
                      onChanged: _onFormChanged,
                      wordController: _wordController, // Pass the controller to form
                    );
                  },
                ),
              ),
              // Show loading overlay if loading
              if (_isLoading)
                Container(
                  color: Colors.black.withAlpha(77),
                  child: const Center(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAiGenerationOptions() {
    // Check if word is already entered before showing options
    final currentWord = _wordController.text.trim();
    
    if (currentWord.isNotEmpty) {
      // If word is already entered, directly generate content
      _generateContentForWord(currentWord);
    } else {
      // Otherwise show the options
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: const Text('Generate for current word'),
                  subtitle: const Text('Use AI to generate details for the current word'),
                  onTap: () {
                    Navigator.pop(context);
                    _showWordInputDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.new_releases),
                  title: const Text('Generate random word'),
                  subtitle: const Text('Generate a completely new random word'),
                  onTap: () {
                    Navigator.pop(context);
                    _generateRandomWord();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showWordInputDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter word to generate'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Word',
            hintText: 'Enter the word to generate content for',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generateContentForWord(controller.text.trim());
            },
            child: const Text('GENERATE'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  Future<void> _generateContentForWord(String word) async {
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a word'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      // Use the improved prompt for vocabulary generation - removed tense references
      final result = await _aiService.generateVocabularyItem(
        "Generate comprehensive vocabulary information for the word '$word'. "
        "Structure your response as a JSON object with these fields:\n"
        "- meaning: a clear, concise definition\n"
        "- example: a natural example sentence\n"
        "- partOfSpeech: the grammatical part of speech (noun, verb, adjective, adverb, etc.)\n"
        "- category: select the most appropriate logical category based on the word's meaning (e.g., Feelings/Emotions, Actions/Verbs, Animals, etc.)\n"
        "- difficultyLevel: a number from 1-5 (1=easy, 5=hard)\n"
        "- synonyms: array of 3-5 synonyms for this word\n"
        "- antonyms: array of 2-3 antonyms for this word (if applicable)\n"
        "- emoji: a single, highly relevant emoji that best represents the meaning of the word. Do NOT use generic or default emojis like 📝, 🔤, or similar. Only use an emoji that is specific and meaningful for the word."
      );

      // Properly convert synonyms and antonyms to List<String>
      List<String>? synonymsList;
      if (result['synonyms'] != null) {
        synonymsList = (result['synonyms'] as List).map((item) => item.toString()).toList();
      }
      
      List<String>? antonymsList;
      if (result['antonyms'] != null) {
        antonymsList = (result['antonyms'] as List).map((item) => item.toString()).toList();
      }
      
      // Ensure category is one of the valid options
      String category = result['category'] as String;
      if (!AppConstants.defaultCategories.contains(category)) {
        // Default to General if the category doesn't exist
        category = 'General';
      }
      
      // Ensure part of speech is valid
      String? partOfSpeech = result['partOfSpeech'] as String?;
      final validPartsOfSpeech = [
        'noun', 'verb', 'adjective', 'adverb', 'pronoun', 
        'preposition', 'conjunction', 'interjection', 'phrase'
      ];
      
      if (partOfSpeech == null || !validPartsOfSpeech.contains(partOfSpeech.toLowerCase())) {
        partOfSpeech = 'noun'; // Default to noun if invalid
      }
      
      // Get any alternate meanings or part of speech notes
      final partOfSpeechNote = result['partOfSpeechNote'] as String?;
      final alternateMeanings = result['alternateMeanings'] as Map<String, String>?;
      
      // Generate an image for the word - prioritize a GIF from GIPHY
      String? imageUrl;
      try {
        // First try to generate a GIPHY GIF for better visual representation
        imageUrl = await _imageService.searchGiphyGif(word);
        
        // If GIPHY fails or returns empty, try to generate a static image as fallback
        if (imageUrl == null || imageUrl.isEmpty) {
          imageUrl = await _imageService.generateImage(word, result['meaning'] as String);
        }
      } catch (e) {
        debugPrint('Error generating image: $e');
        // We'll continue even if image generation fails
      }
      
      // Always have an emoji as fallback
      String emoji = result['emoji'] as String? ?? '';
      if (emoji.isEmpty) {
        // If the AI fails completely, you may show an error or skip emoji
        emoji = '';
      }
      
      // Create a vocabulary item with the generated content - removed tense variations
      final newItem = VocabularyItem(
        id: const Uuid().v4(),
        word: word,
        meaning: result['meaning'] as String,
        category: category,
        example: result['example'] as String?,
        difficultyLevel: 2, // Medium difficulty by default
        imageUrl: imageUrl,
        wordEmoji: emoji,
        pronunciation: result['pronunciation'] as String?,
        partOfSpeech: partOfSpeech,
        partOfSpeechNote: partOfSpeechNote,
        alternateMeanings: alternateMeanings,
        synonyms: synonymsList,
        antonyms: antonymsList,
      );
      
      // Update the form state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _existingItem = newItem;
          });
        }
      });
      
      // Set after a short delay to ensure UI updates
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _existingItem = newItem;
            _isLoading = false;
          });
        }
      });
            
      // Show success toast
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating content: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateRandomWord() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Generate a random word
      final randomWord = await _aiWordGenerator.generateRandomWord();
      
      if (randomWord != null && randomWord.isNotEmpty) {
        // Update the word controller to show the random word
        _wordController.text = randomWord;
        
        // Generate content for this word
        await _generateContentForWord(randomWord);
      } else {
        throw Exception('Failed to generate random word');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating random word: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDiscardChangesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              
              // First try context.pop() from go_router as it better handles navigation stacks
              if (context.canPop()) {
                context.pop();
              } else if (Navigator.canPop(context)) {
                // If go_router can't pop, try Navigator.pop
                Navigator.of(context).pop();
              } else {
                // Last resort: go to home route
                context.go(AppConstants.homeRoute);
              }
            },
            child: const Text('DISCARD'),
          ),
        ],
      ),
    );
  }

  _onFormChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hasChanges = true;
        });
      }
    });
  }
}