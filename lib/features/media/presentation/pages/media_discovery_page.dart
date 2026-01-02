import 'package:flutter/material.dart';
import '../../domain/entities/media_item.dart';
import '../../data/services/media_service.dart';
import 'package:hive/hive.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/features/vocabulary/data/models/vocabulary_item_model.dart';
import 'package:flutter/foundation.dart';
import 'package:visual_vocabularies/features/flashcards/presentation/pages/flashcards_page.dart';
import 'package:visual_vocabularies/features/flashcards/presentation/widgets/flashcard_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/widgets/vocabulary_form/tts_helper.dart';
import 'package:get_it/get_it.dart';
import 'package:visual_vocabularies/core/utils/synonyms_game_service.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/features/subtitle_extractor/presentation/pages/select_subtitle_page.dart';
import 'package:visual_vocabularies/features/media/presentation/widgets/flashcard_player.dart';

class MediaDiscoveryPage extends StatefulWidget {
  final MediaService mediaService;
  final bool isEmbedded;
  
  const MediaDiscoveryPage({
    super.key, 
    required this.mediaService,
    this.isEmbedded = true,
  });

  @override
  State<MediaDiscoveryPage> createState() => _MediaDiscoveryPageState();
}

class _MediaDiscoveryPageState extends State<MediaDiscoveryPage> {
  late Future<List<MediaItem>> _mediaItemsFuture;
  bool _isLoading = false;

  // Group items by show title
  Map<String, List<MediaItem>> _groupByShow(List<MediaItem> items) {
    final Map<String, List<MediaItem>> grouped = {};
    
    for (final item in items) {
      // Use a default title if needed
      final showTitle = item.title.isEmpty ? 'Unknown Show' : item.title;
      
      if (!grouped.containsKey(showTitle)) {
        grouped[showTitle] = [];
      }
      
      grouped[showTitle]!.add(item);
    }
    
    // Sort each show's episodes
    for (final shows in grouped.values) {
      shows.sort((a, b) {
        // Sort by season first
        if (a.season != null && b.season != null) {
          final seasonCompare = a.season!.compareTo(b.season!);
          if (seasonCompare != 0) return seasonCompare;
          
          // Then by episode
          if (a.episode != null && b.episode != null) {
            return a.episode!.compareTo(b.episode!);
          }
        }
        // Sort by chapter for books
        else if (a.chapter != null && b.chapter != null) {
          return a.chapter!.compareTo(b.chapter!);
        }
        
        // Default to creation date if no other sorting criteria
        return a.createdAt.compareTo(b.createdAt);
      });
    }
    
    return grouped;
  }

  void _onPlayPressed(MediaItem item) async {
    final vocabularyItems = await _getVocabularyItemsByIds(item.vocabularyItemIds);
    if (vocabularyItems.isEmpty) {
      // Show an error message if no vocabulary items were found
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No vocabulary items found for this media item.'),
        ),
      );
      return;
    }
    
    // Navigate to the new MediaFlashcardPlayer widget
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaFlashcardPlayer(
          vocabularyItems: vocabularyItems,
          mediaItem: item,
          onEditWord: (vocabItem) {
            // Navigate to edit word and refresh on return
            context.push(
              '${AppConstants.addEditWordRoute}/${vocabItem.id}',
            ).then((_) => _refreshMediaItems());
          },
        ),
      ),
    );
  }

  Future<List<VocabularyItem>> _getVocabularyItemsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    try {
      final box = await Hive.openBox<VocabularyItemModel>('vocabulary_items');
      return ids
          .map((id) => box.get(id))
          .where((model) => model != null)
          .map((model) => model!.toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error retrieving vocabulary items: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshMediaItems();
  }

  void _refreshMediaItems() {
    setState(() {
      _mediaItemsFuture = widget.mediaService.getAllMediaItems();
    });
  }
  
  @override
  void dispose() {
    // Close any open resources if needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildPageContent();
    
    if (widget.isEmbedded) {
      return content;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Vocabulary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save to Media',
            onPressed: () => _showSaveToMediaDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshMediaItems();
            },
          ),
        ],
      ),
      body: content,
    );
  }
  
  Widget _buildPageContent() {
    return Stack(
      children: [
        FutureBuilder<List<MediaItem>>(
          future: _mediaItemsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(context);
            }
            
            final items = snapshot.data!;
            final groupedItems = _groupByShow(items);
            
            // Build an expandable list view for each show
            return Column(
              children: [
                // Add action buttons at the top when embedded
                if (widget.isEmbedded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.save),
                          tooltip: 'Save to Media',
                          onPressed: () => _showSaveToMediaDialog(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh',
                          onPressed: () {
                            _refreshMediaItems();
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: groupedItems.length,
                    itemBuilder: (context, index) {
                      final showTitle = groupedItems.keys.elementAt(index);
                      final episodes = groupedItems[showTitle]!;
                      
                      // Count total words across all episodes
                      final totalWordCount = episodes.fold<int>(
                        0, 
                        (sum, item) => sum + item.vocabularyItemIds.length
                      );
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 2,
                        child: ExpansionTile(
                          title: Text(
                            showTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('$totalWordCount vocabulary items'),
                          leading: Icon(_getMediaTypeIcon(episodes.first)),
                          children: episodes.map((item) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                              title: Text(
                                _getItemDisplayTitle(item),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text('${item.vocabularyItemIds.length} words'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete',
                                    onPressed: () => _showDeleteConfirmation(context, item),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Play'),
                                    onPressed: () => _onPlayPressed(item),
                                  ),
                                ],
                              ),
                              onTap: () => _onPlayPressed(item),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          
          // Empty illustration
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.movie_outlined,
                size: 50,
                color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade400,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Empty state title
          Text(
            'No media vocabulary found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Empty state description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Extract vocabulary from subtitles to build your media vocabulary collection',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action button
          ElevatedButton.icon(
            onPressed: () {
              // Navigate directly to subtitle selection page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SelectSubtitlePage(isEmbedded: false),
                ),
              );
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Subtitles'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Or divider
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Divider(
                  indent: 80,
                  endIndent: 16,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
              ),
              Text(
                'OR',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Divider(
                  indent: 16,
                  endIndent: 80,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Refresh button
          TextButton.icon(
            onPressed: _refreshMediaItems,
            icon: Icon(
              Icons.refresh,
              color: isDarkMode ? Colors.purple[200] : Colors.purple,
            ),
            label: Text(
              'Refresh Media Vocabulary',
              style: TextStyle(
                color: isDarkMode ? Colors.purple[200] : Colors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog to save media items
  void _showSaveToMediaDialog(BuildContext context) async {
    // Get the current media items first
    final List<MediaItem> mediaItems = await _mediaItemsFuture;
    
    if (mediaItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No media items to save!')),
      );
      return;
    }
    
    // Controllers for the dialog
    final TextEditingController titleController = TextEditingController(text: 'My Collection');
    final TextEditingController seasonController = TextEditingController(text: '1');
    final TextEditingController episodeController = TextEditingController(text: '1');
    
    // Track selected media items
    final Set<String> selectedItemIds = <String>{};
    
    // Show dialog
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Save to Media Collection'),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Collection Title',
                      hintText: 'Enter a title for this collection',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: seasonController,
                          decoration: const InputDecoration(
                            labelText: 'Season',
                            hintText: 'Season number',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: episodeController,
                          decoration: const InputDecoration(
                            labelText: 'Episode',
                            hintText: 'Episode number',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Media Items:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: mediaItems.length,
                      itemBuilder: (context, index) {
                        final item = mediaItems[index];
                        final isSelected = selectedItemIds.contains(item.id);
                        
                        return CheckboxListTile(
                          title: Text(item.title),
                          subtitle: Text(
                            item.season != null && item.episode != null
                                ? 'S${item.season} E${item.episode} • ${item.vocabularyItemIds.length} words'
                                : '${item.vocabularyItemIds.length} words',
                          ),
                          value: isSelected,
                          onChanged: (selected) {
                            setDialogState(() {
                              if (selected!) {
                                selectedItemIds.add(item.id);
                              } else {
                                selectedItemIds.remove(item.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () async {
                  // Get the selected items by ID
                  final selectedItems = mediaItems
                      .where((item) => selectedItemIds.contains(item.id))
                      .toList();
                      
                  if (selectedItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one media item')),
                    );
                    return;
                  }
                  
                  // Show loading indicator
                  setState(() {
                    _isLoading = true;
                  });
                  
                  try {
                    // Collect all vocabulary IDs from selected media items
                    final Set<String> allVocabularyIds = <String>{};
                    for (final item in selectedItems) {
                      allVocabularyIds.addAll(item.vocabularyItemIds);
                    }
                    
                    // Create a new media item with all vocabulary IDs
                    final newMediaItem = MediaItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      season: int.tryParse(seasonController.text),
                      episode: int.tryParse(episodeController.text),
                      vocabularyItemIds: allVocabularyIds.toList(),
                    );
                    
                    // Save the new media item
                    await widget.mediaService.addMediaItem(newMediaItem);
                    
                    // Close dialog
                    Navigator.of(context).pop();
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Media collection saved to Home Media section!')),
                    );
                    
                    // Refresh the media items list
                    _refreshMediaItems();
                  } catch (e) {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving media: $e')),
                    );
                  } finally {
                    // Hide loading indicator
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                child: const Text('SAVE TO COLLECTION'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MediaItem item) {
    final itemDetails = item.season != null && item.episode != null
        ? '${item.title} - Season ${item.season}, Episode ${item.episode}'
        : item.title;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media Item'),
        content: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: itemDetails,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? This action cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              // Close the dialog first
              Navigator.of(context).pop();
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                await widget.mediaService.deleteMediaItem(item.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$itemDetails deleted successfully')),
                );
                _refreshMediaItems();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting media item: $e')),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            style: FilledButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  String _getItemDisplayTitle(MediaItem item) {
    if (item.season != null && item.episode != null) {
      return 'Season ${item.season} • Episode ${item.episode}';
    } else if (item.chapter != null) {
      return 'Chapter ${item.chapter}';
    } else {
      return item.title;
    }
  }

  IconData _getMediaTypeIcon(MediaItem item) {
    if (item.author != null) {
      return Icons.book;
    } else {
      return Icons.tv;
    }
  }

  String _getMediaSubtitleText(MediaItem item) {
    if (item.season != null && item.episode != null) {
      return 'TV Show • Season ${item.season}, Episode ${item.episode}';
    } else if (item.author != null) {
      return 'Book by ${item.author}' + (item.chapter != null ? ' • Chapter ${item.chapter}' : '');
    } else {
      return 'Media • ${item.vocabularyItemIds.length} words';
    }
  }
}

// Custom flashcards page specifically for media items
class _MediaFlashcardsPage extends StatefulWidget {
  final List<VocabularyItem> vocabularyItems;
  final MediaItem mediaItem;
  
  const _MediaFlashcardsPage({
    required this.vocabularyItems, 
    required this.mediaItem,
  });

  @override
  State<_MediaFlashcardsPage> createState() => _MediaFlashcardsPageState();
}

class _MediaFlashcardsPageState extends State<_MediaFlashcardsPage> {
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
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final title = widget.mediaItem.season != null && widget.mediaItem.episode != null
        ? '${widget.mediaItem.title} S${widget.mediaItem.season}E${widget.mediaItem.episode}'
        : widget.mediaItem.author != null
            ? '${widget.mediaItem.title} by ${widget.mediaItem.author}'
            : widget.mediaItem.title;
        
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: widget.vocabularyItems.isEmpty
        ? const Center(child: Text('No vocabulary items found'))
        : Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.vocabularyItems.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      
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
                      onEdit: () => _navigateToEditWord(vocabItem),
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
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Word',
                      onPressed: () => _navigateToEditWord(widget.vocabularyItems[_currentIndex]),
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          context.push(AppConstants.markedSynonymsGameRoute);
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
                          context.push(AppConstants.markedAntonymsGameRoute);
                        },
                        icon: const Icon(Icons.compare_arrows),
                        label: const Text('Antonyms Game'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          context.push(AppConstants.markedTensesGameRoute);
                        },
                        icon: const Icon(Icons.timer),
                        label: const Text('Tenses Game'),
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

  // Navigate to edit word page
  void _navigateToEditWord(VocabularyItem vocabItem) {
    context.push(
      '${AppConstants.addEditWordRoute}/${vocabItem.id}',
    ).then((_) {
      // Refresh the list when returning from edit
      setState(() {
        // Reload vocabulary items
        final currentId = widget.vocabularyItems[_currentIndex].id;
        _refreshVocabularyItems().then((_) {
          // Maintain current position if possible
          final newIndex = widget.vocabularyItems.indexWhere((item) => item.id == currentId);
          if (newIndex != -1) {
            _pageController.jumpToPage(newIndex);
            setState(() {
              _currentIndex = newIndex;
            });
          }
        });
      });
    });
  }

  // Mark synonym functionality - COMMENTING OUT as it requires model changes
  Future<void> _markSynonym(String wordId, String synonym) async {
    // Use the SynonymsGameService directly for marking synonyms
    // This is the same approach used in the main flashcards implementation
    try {
      final service = sl<SynonymsGameService>();
      final success = await service.markSynonym(wordId, synonym);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked "$synonym" as known'),
            action: SnackBarAction(
              label: 'Play Game',
              onPressed: () {
                context.push(AppConstants.markedSynonymsGameRoute);
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking synonym: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark synonym: $e')),
      );
    }
  }

  // Refresh vocabulary items
  Future<void> _refreshVocabularyItems() async {
    final updatedItems = await _getVocabularyItemsByIds(widget.mediaItem.vocabularyItemIds);
    setState(() {
      widget.vocabularyItems.clear();
      widget.vocabularyItems.addAll(updatedItems);
    });
  }

  // Get vocabulary items by IDs
  Future<List<VocabularyItem>> _getVocabularyItemsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    try {
      final box = await Hive.openBox<VocabularyItemModel>('vocabulary_items');
      return ids
          .map((id) => box.get(id))
          .where((model) => model != null)
          .map((model) => model!.toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error retrieving vocabulary items: $e');
      return [];
    }
  }
} 