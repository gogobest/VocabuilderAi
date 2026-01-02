import 'package:flutter/material.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/features/flashcards/presentation/widgets/flashcard_widget.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/widgets/vocabulary_form/tts_helper.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/media_item.dart';

/// A dedicated flashcard player for media vocabulary items with all necessary controls
class MediaFlashcardPlayer extends StatefulWidget {
  final List<VocabularyItem> vocabularyItems;
  final MediaItem mediaItem;
  final void Function(VocabularyItem)? onEditWord;
  
  const MediaFlashcardPlayer({
    super.key,
    required this.vocabularyItems,
    required this.mediaItem,
    this.onEditWord,
  });

  @override
  State<MediaFlashcardPlayer> createState() => _MediaFlashcardPlayerState();
}

class _MediaFlashcardPlayerState extends State<MediaFlashcardPlayer> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _showBack = false;
  late TtsHelper _ttsHelper;
  
  @override
  void initState() {
    super.initState();
    _ttsHelper = TtsHelper(context);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsHelper.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final title = widget.mediaItem.season != null && widget.mediaItem.episode != null
        ? '${widget.mediaItem.title} S${widget.mediaItem.season}E${widget.mediaItem.episode}'
        : widget.mediaItem.author != null
            ? '${widget.mediaItem.title} by ${widget.mediaItem.author}'
            : widget.mediaItem.title;
        
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Add feedback icon
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Cards',
            onPressed: () {
              setState(() {
                // Reset to front side
                _showBack = false;
                
                // Go back to first card
                _pageController.animateToPage(
                  0, 
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut
                );
              });
            },
          ),
        ],
      ),
      body: widget.vocabularyItems.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: isDarkMode ? Colors.amber[300] : Colors.amber,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No vocabulary items found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This media item doesn\'t have any vocabulary items.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: widget.vocabularyItems.isNotEmpty 
                    ? (_currentIndex + 1) / widget.vocabularyItems.length
                    : 0,
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              
              // Flashcard
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.vocabularyItems.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      _showBack = false; // Reset to front side when changing cards
                    });
                  },
                  itemBuilder: (context, index) {
                    final vocabItem = widget.vocabularyItems[index];
                    return FlashcardWidget(
                      word: vocabItem.word,
                      definition: vocabItem.meaning,
                      examples: vocabItem.example != null ? [vocabItem.example!] : [],
                      wordEmoji: vocabItem.wordEmoji,
                      partOfSpeech: vocabItem.partOfSpeech,
                      synonyms: vocabItem.synonyms,
                      antonyms: vocabItem.antonyms,
                      category: vocabItem.category,
                      showBack: _showBack,
                      onTap: () {
                        setState(() {
                          _showBack = !_showBack;
                        });
                      },
                      ttsHelper: _ttsHelper,
                      imageUrl: vocabItem.imageUrl,
                      id: vocabItem.id, // Pass the ID for proper cache busting with images
                      onEdit: widget.onEditWord != null 
                          ? () => widget.onEditWord!(vocabItem)
                          : null,
                    );
                  },
                ),
              ),
              
              // Card counter
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Card ${_currentIndex + 1} of ${widget.vocabularyItems.length}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              
              // Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Previous button
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _currentIndex > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    ),
                    
                    // Flip button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.flip),
                      label: Text(_showBack ? 'Show Word' : 'Show Meaning'),
                      onPressed: () {
                        setState(() {
                          _showBack = !_showBack;
                        });
                      },
                    ),

                    // Edit button
                    if (widget.onEditWord != null)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Word',
                        onPressed: () => widget.onEditWord!(widget.vocabularyItems[_currentIndex]),
                      ),
                    
                    // Next button
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _currentIndex < widget.vocabularyItems.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    ),
                  ],
                ),
              ),
              
              // Add game buttons at the bottom
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          context.push(AppConstants.synonymsGameRoute);
                        },
                        icon: const Icon(Icons.text_fields),
                        label: const Text('Synonyms Game'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          context.push(AppConstants.antonymsGameRoute);
                        },
                        icon: const Icon(Icons.compare_arrows),
                        label: const Text('Antonyms Game'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // One more row of buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          context.push(AppConstants.tensesGameRoute);
                        },
                        icon: const Icon(Icons.timer),
                        label: const Text('Tenses Game'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          context.push(AppConstants.flashcardsRoute);
                        },
                        icon: const Icon(Icons.school),
                        label: const Text('All Flashcards'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
} 