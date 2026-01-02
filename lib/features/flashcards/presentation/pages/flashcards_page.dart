import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/utils/tracking_service.dart';
import 'package:visual_vocabularies/core/widgets/app_error_widget.dart';
import 'package:visual_vocabularies/core/widgets/app_loading_indicator.dart';
import 'package:visual_vocabularies/core/widgets/app_navigation_bar.dart';
import 'package:visual_vocabularies/features/flashcards/presentation/widgets/flashcard_widget.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_event.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_state.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/widgets/vocabulary_form/tts_helper.dart';

/// A page that displays flashcards for vocabulary learning
class FlashcardsPage extends StatefulWidget {
  /// Optional category filter
  final String? categoryFilter;
  
  /// Constructor for FlashcardsPage
  const FlashcardsPage({
    super.key,
    this.categoryFilter,
  });

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> {
  final PageController _pageController = PageController();
  late final VocabularyBloc _vocabularyBloc;
  late final TrackingService _trackingService;
  List<VocabularyItem> _flashcards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  String? _selectedCategory;
  List<String> _availableCategories = AppConstants.defaultCategories;
  late TtsHelper _ttsHelper;

  @override
  void initState() {
    super.initState();
    _vocabularyBloc = sl<VocabularyBloc>();
    _trackingService = sl<TrackingService>();
    _ttsHelper = TtsHelper(context);
    
    // Set selected category if provided in widget
    _selectedCategory = widget.categoryFilter;
    
    // Track page view
    _trackingService.trackNavigation('Flashcards Page' + (_selectedCategory != null ? ' - Category: $_selectedCategory' : ''));
    
    // Load data
    _loadCategories();
    _loadFlashcards();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadFlashcards() {
    _trackingService.trackEvent('Loading flashcards', data: {'category': _selectedCategory});
    
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      _vocabularyBloc.add(
        LoadVocabularyItemsByCategory(_selectedCategory!),
      );
    } else {
      _vocabularyBloc.add(
        const LoadVocabularyItems(),
      );
    }
  }
  
  void _loadCategories() {
    _trackingService.trackEvent('Loading categories');
    _vocabularyBloc.add(const LoadCategories());
  }

  void _onPageChanged(int index) {
    final currentWord = _currentIndex < _flashcards.length ? _flashcards[_currentIndex].word : null;
    final newWord = index < _flashcards.length ? _flashcards[index].word : null;
    
    _trackingService.trackSwipe(index > _currentIndex ? 'Next' : 'Previous', context: 'Flashcard');
    _trackingService.trackFlashcardInteraction(
      'Changed card from ${_currentIndex + 1} to ${index + 1}', 
      word: newWord
    );
    
    setState(() {
      _currentIndex = index;
      _showAnswer = false;
    });
  }

  void _flipCard() {
    final currentWord = _currentIndex < _flashcards.length ? _flashcards[_currentIndex].word : null;
    
    _trackingService.trackButtonClick('Flip Card', screen: 'Flashcards');
    _trackingService.trackFlashcardInteraction(
      _showAnswer ? 'Show Word' : 'Show Meaning', 
      word: currentWord
    );
    
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  void _markKnowledge(int level) {
    final item = _flashcards[_currentIndex];
    String difficulty;
    
    switch (level) {
      case 1:
        difficulty = 'Hard';
        break;
      case 2:
        difficulty = 'Medium';
        break;
      case 3:
        difficulty = 'Easy';
        break;
      default:
        difficulty = 'Unknown';
    }
    
    _trackingService.trackButtonClick(difficulty, screen: 'Flashcards');
    _trackingService.trackFlashcardInteraction(
      'Marked as $difficulty', 
      word: item.word
    );
    
    // Calculate new mastery level (simplified logic)
    int newMasteryLevel = item.masteryLevel;
    if (level == 1) { // Hard - decrease mastery slightly
      newMasteryLevel = (newMasteryLevel - 5).clamp(0, 100);
    } else if (level == 2) { // Medium - small increase
      newMasteryLevel = (newMasteryLevel + 5).clamp(0, 100);
    } else if (level == 3) { // Easy - larger increase
      newMasteryLevel = (newMasteryLevel + 10).clamp(0, 100);
    }
    
    // Only update if mastery level changed
    if (newMasteryLevel != item.masteryLevel) {
      _trackingService.trackVocabularyInteraction(
        'Updated mastery level', 
        word: item.word,
        itemId: item.id
      );
      
      _vocabularyBloc.add(
        UpdateVocabularyItem(
          item.copyWith(
            masteryLevel: newMasteryLevel,
            lastReviewed: DateTime.now(),
          ),
        ),
      );
    }
    
    // Move to next card if not at the end
    if (_currentIndex < _flashcards.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.mediumAnimationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _showFilterDialog() {
    _trackingService.trackButtonClick('Filter', screen: 'Flashcards');
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Flashcards'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                    ),
                    value: _selectedCategory,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ..._availableCategories.map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      _trackingService.trackSelection(value ?? 'All Categories', 'Category', screen: 'Flashcard Settings');
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _trackingService.trackButtonClick('Cancel', screen: 'Flashcard Settings');
                    Navigator.pop(context);
                  },
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _trackingService.trackButtonClick('Apply', screen: 'Flashcard Settings');
                    Navigator.pop(context);
                    _loadFlashcards();
                  },
                  child: const Text('APPLY'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          context.go(AppConstants.homeRoute);
        }
        return false;
      },
      child: BlocProvider(
        create: (context) => _vocabularyBloc,
        child: BlocListener<VocabularyBloc, VocabularyState>(
          listener: (context, state) {
            if (state is VocabularyLoaded) {
              setState(() {
                _flashcards = state.items;
                _currentIndex = 0;
                _showAnswer = false;
              });
            } else if (state is CategoriesLoaded) {
              setState(() {
                _availableCategories = state.categories;
              });
            }
          },
          child: Scaffold(
            appBar: AppNavigationBar(
              title: _selectedCategory ?? 'Flashcards',
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter',
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
            body: BlocConsumer<VocabularyBloc, VocabularyState>(
              listener: (context, state) {
                if (state is VocabularyLoading) {
                  // Show loading indicator
                } else if (state is VocabularyError) {
                  // Show error message and retry button
                }
              },
              builder: (context, state) {
                if (state is VocabularyLoading) {
                  return const AppLoadingIndicator();
                } else if (state is VocabularyError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: _loadFlashcards,
                  );
                } else if (_flashcards.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.library_books,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No flashcards available',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedCategory != null 
                              ? 'No words in the $_selectedCategory category'
                              : 'Add some vocabulary words first',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to add word page with category pre-selected
                            final uri = Uri(
                              path: AppConstants.addEditWordRoute,
                              queryParameters: _selectedCategory != null
                                  ? {'category': _selectedCategory}
                                  : null,
                            );
                            context.push(uri.toString());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Word'),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Column(
                    children: [
                      // Flashcard area
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemCount: _flashcards.length,
                          itemBuilder: (context, index) {
                            final item = _flashcards[index];
                            return _buildFlashcard(item);
                          },
                        ),
                      ),
                      
                      // Controls
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Progress indicator
                            Text(
                              'Card ${_currentIndex + 1} of ${_flashcards.length}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            
                            // Navigation and flip buttons row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Previous button
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: _currentIndex > 0
                                    ? () {
                                        _pageController.previousPage(
                                          duration: AppConstants.mediumAnimationDuration,
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    : null,
                                ),
                                
                                // Flip button
                                ElevatedButton.icon(
                                  onPressed: _flipCard,
                                  icon: const Icon(Icons.flip),
                                  label: Text(_showAnswer ? 'Show Word' : 'Show Meaning'),
                                ),
                                
                                // Next button
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: _currentIndex < _flashcards.length - 1
                                    ? () {
                                        _pageController.nextPage(
                                          duration: AppConstants.mediumAnimationDuration,
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    : null,
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Knowledge level buttons
                            if (_showAnswer)
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _markKnowledge(1),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[300],
                                      ),
                                      child: const Text('Hard'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _markKnowledge(2),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                      ),
                                      child: const Text('Medium'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _markKnowledge(3),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[300],
                                      ),
                                      child: const Text('Easy'),
                                    ),
                                  ),
                                ],
                              ),
                            
                            // Add button to go to Marked Synonyms Game
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      _trackingService.trackButtonClick('Go to Marked Synonyms Game', screen: 'Flashcards');
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
                                      _trackingService.trackButtonClick('Go to Marked Antonyms Game', screen: 'Flashcards');
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
                                      _trackingService.trackButtonClick('Go to Marked Tenses Game', screen: 'Flashcards');
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
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            floatingActionButton: _flashcards.isNotEmpty 
                ? null
                : FloatingActionButton(
                    onPressed: () {
                      final uri = Uri(
                        path: AppConstants.addEditWordRoute,
                        queryParameters: _selectedCategory != null
                            ? {'category': _selectedCategory}
                            : null,
                      );
                      context.push(uri.toString());
                    },
                    tooltip: 'Add New Word',
                    child: const Icon(Icons.add),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcard(VocabularyItem item) {
    return FlashcardWidget(
      word: item.word,
      definition: item.meaning,
      examples: item.example != null ? [item.example!] : [],
      pronunciation: item.pronunciation,
      imageUrl: item.imageUrl,
      showBack: _showAnswer,
      wordEmoji: item.wordEmoji,
      partOfSpeech: item.partOfSpeech,
      synonyms: item.synonyms,
      antonyms: item.antonyms,
      category: item.category,
      onTap: () {
        setState(() {
          _showAnswer = !_showAnswer;
        });
      },
      onEdit: () {
        _navigateToEditWord(item.id);
      },
      id: item.id,
      ttsHelper: _ttsHelper,
    );
  }

  void _navigateToEditWord(String id) {
    _trackingService.trackButtonClick('Edit Word from Flashcard', screen: 'Flashcards');
    context.push('${AppConstants.addEditWordRoute}/${id}');
  }

  /// Get a color based on the tense name
  Color _getTenseColor(String tenseName) {
    final name = tenseName.toLowerCase();
    
    if (name.contains('past')) {
      return Colors.purple; // Past tenses
    } else if (name.contains('present')) {
      return Colors.teal; // Present tenses
    } else if (name.contains('future')) {
      return Colors.blue; // Future tenses
    }
    
    return Colors.grey; // Default
  }
} 