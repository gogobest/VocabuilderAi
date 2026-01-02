import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/utils/tracking_service.dart';
import 'package:visual_vocabularies/core/utils/synonyms_game_service.dart';
import 'package:visual_vocabularies/core/widgets/app_error_widget.dart';
import 'package:visual_vocabularies/core/widgets/app_loading_indicator.dart';
import 'package:visual_vocabularies/core/widgets/app_navigation_bar.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_event.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_state.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/widgets/vocabulary_form/tts_helper.dart';
import 'package:visual_vocabularies/features/vocabulary/data/models/vocabulary_item_model.dart';

/// A page that allows users to play a game with synonyms
class SynonymsGamePage extends StatefulWidget {
  /// Optional category filter
  final String? categoryFilter;
  
  /// Whether to play only with marked synonyms
  final bool onlyMarkedSynonyms;
  
  /// Constructor for SynonymsGamePage
  const SynonymsGamePage({
    super.key,
    this.categoryFilter,
    this.onlyMarkedSynonyms = false,
  });

  @override
  State<SynonymsGamePage> createState() => _SynonymsGamePageState();
}

class _SynonymsGamePageState extends State<SynonymsGamePage> {
  final VocabularyBloc _vocabularyBloc = sl<VocabularyBloc>();
  final TrackingService _trackingService = sl<TrackingService>();
  final SynonymsGameService _synonymsGameService = sl<SynonymsGameService>();
  late TtsHelper _ttsHelper;
  
  List<VocabularyItem> _allVocabularyItems = [];
  List<VocabularyItem> _gameItems = [];
  List<String> _availableCategories = [];
  String? _selectedCategory;
  
  int _currentItemIndex = 0;
  int _score = 0;
  int _totalQuestions = 0;
  bool _isGameComplete = false;
  bool _isLoading = true;
  
  // Current game state
  late VocabularyItem _currentWord;
  List<String> _options = [];
  String? _selectedOption;
  bool _isAnswerChecked = false;
  bool _isCorrect = false;
  String _correctSynonym = '';
  
  @override
  void initState() {
    super.initState();
    _ttsHelper = TtsHelper(context);
    _selectedCategory = widget.categoryFilter;
    
    _loadCategories();
    _loadVocabularyItems();
    
    // Track page view
    _trackingService.trackNavigation('Synonyms Game Page');
  }
  
  void _loadCategories() {
    _vocabularyBloc.add(const LoadCategories());
  }
  
  void _loadVocabularyItems() {
    setState(() {
      _isLoading = true;
    });
    
    if (_selectedCategory != null) {
      _vocabularyBloc.add(LoadVocabularyItemsByCategory(_selectedCategory!));
    } else {
      _vocabularyBloc.add(const LoadVocabularyItems());
    }
  }
  
  Future<void> _setupGame(List<VocabularyItem> items) async {
    _allVocabularyItems = items;
    
    // Filter items that have synonyms
    final itemsWithSynonyms = items.where((item) => 
      item.synonyms != null && item.synonyms!.isNotEmpty
    ).toList();
    
    if (widget.onlyMarkedSynonyms) {
      try {
        final markedItems = await _synonymsGameService.getVocabularyItemsWithMarkedSynonyms(itemsWithSynonyms);
        
        setState(() {
          _gameItems = markedItems;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading marked synonyms: $e');
        setState(() {
          _gameItems = [];
          _isLoading = false;
        });
        return;
      }
    } else {
      setState(() {
        _gameItems = itemsWithSynonyms;
        _isLoading = false;
      });
    }
    
    if (_gameItems.isNotEmpty) {
      try {
        await _startNewRound();
      } catch (e) {
        print('Error starting first round: $e');
      }
    }
  }
  
  Future<void> _startNewRound() async {
    if (_currentItemIndex >= _gameItems.length) {
      setState(() {
        _isGameComplete = true;
      });
      return;
    }
    
    _currentWord = _gameItems[_currentItemIndex];
    
    try {
      _correctSynonym = await _getRandomSynonym(_currentWord);
      _options = _generateOptions(_currentWord, _correctSynonym);
      
      setState(() {
        _selectedOption = null;
        _isAnswerChecked = false;
      });
      
      _totalQuestions++;
    } catch (e) {
      print('Error starting new round: $e');
      // Move to the next word if there's an error with this one
      if (_currentItemIndex < _gameItems.length - 1) {
        setState(() {
          _currentItemIndex++;
        });
        await _startNewRound();
      } else {
        setState(() {
          _isGameComplete = true;
        });
      }
    }
  }
  
  Future<String> _getRandomSynonym(VocabularyItem item) async {
    if (item.synonyms == null || item.synonyms!.isEmpty) {
      throw Exception('No synonyms available for this word');
    }
    
    if (widget.onlyMarkedSynonyms) {
      // Get a marked synonym
      try {
        final markedSynonyms = await _synonymsGameService.getMarkedSynonymsForWord(item.id);
        if (markedSynonyms.isNotEmpty) {
          return markedSynonyms[Random().nextInt(markedSynonyms.length)];
        }
        // If no marked synonyms found, fall back to first synonym
        return item.synonyms!.first;
      } catch (e) {
        print('Error getting marked synonyms: $e');
        // Fallback to first synonym if there's an error
        return item.synonyms!.first;
      }
    }
    
    // Get a random synonym
    final synonyms = item.synonyms!;
    return synonyms[Random().nextInt(synonyms.length)];
  }
  
  List<String> _generateOptions(VocabularyItem currentWord, String correctSynonym) {
    // Create list with the correct answer
    List<String> options = [correctSynonym];
    
    // Add other words randomly as distractors
    final distractorPool = _allVocabularyItems
        .where((item) => item.id != currentWord.id)
        .toList();
    
    if (distractorPool.isEmpty) {
      // If no other words available, use some default distractors
      options.addAll(['obvious', 'accurate', 'peculiar', 'random', 'distinct', 'various', 'enormous']);
      options = options.take(4).toList();
      options.shuffle();
      return options;
    }
    
    // Add 3 random distractors
    distractorPool.shuffle();
    for (int i = 0; i < min(3, distractorPool.length); i++) {
      options.add(distractorPool[i].word);
    }
    
    options.shuffle();
    return options;
  }
  
  // Helper method to find emoji for a word if available
  String? _findEmojiForOption(String option) {
    // Check if it's the correct synonym
    if (option == _correctSynonym) {
      // Try to find the correct synonym in the current word's synonyms
      return _currentWord.wordEmoji;
    }
    
    // Otherwise check if it's a distractor from another vocabulary item
    final matchingItem = _allVocabularyItems.firstWhere(
      (item) => item.word == option,
      orElse: () => VocabularyItemModel(
        id: '',
        word: '',
        meaning: '',
        category: '',
        createdAt: DateTime.now(),
        difficultyLevel: 1,
        masteryLevel: 0,
      ),
    );
    
    if (matchingItem.id.isNotEmpty) {
      return matchingItem.wordEmoji;
    }
    
    return null;
  }
  
  void _checkAnswer() {
    if (_selectedOption == null) return;
    
    final isCorrect = _selectedOption == _correctSynonym;
    
    setState(() {
      _isAnswerChecked = true;
      _isCorrect = isCorrect;
      
      if (isCorrect) {
        _score += AppConstants.pointsPerCorrectSynonym;
      }
    });
    
    _trackingService.trackEvent(
      'Synonym Game Answer',
      data: {
        'word': _currentWord.word,
        'correct': isCorrect,
        'selected': _selectedOption,
        'expected': _correctSynonym,
      },
    );
  }
  
  Future<void> _nextQuestion() async {
    setState(() {
      _currentItemIndex++;
    });
    
    if (_currentItemIndex < _gameItems.length) {
      await _startNewRound();
    } else {
      setState(() {
        _isGameComplete = true;
      });
    }
  }
  
  void _restartGame() {
    setState(() {
      _currentItemIndex = 0;
      _score = 0;
      _totalQuestions = 0;
      _isGameComplete = false;
    });
    
    _loadVocabularyItems();
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableCategories.length + 1, // +1 for "All Categories"
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('All Categories'),
                  selected: _selectedCategory == null,
                  onTap: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                    Navigator.pop(context);
                    _loadVocabularyItems();
                  },
                );
              } else {
                final category = _availableCategories[index - 1];
                return ListTile(
                  title: Text(category),
                  selected: _selectedCategory == category,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                    Navigator.pop(context);
                    _loadVocabularyItems();
                  },
                );
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
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
      child: BlocProvider.value(
        value: _vocabularyBloc,
        child: BlocListener<VocabularyBloc, VocabularyState>(
          listener: (context, state) {
            if (state is VocabularyLoaded) {
              _setupGame(state.items);
            } else if (state is CategoriesLoaded) {
              setState(() {
                _availableCategories = state.categories;
              });
            }
          },
          child: Scaffold(
            appBar: AppNavigationBar(
              title: widget.onlyMarkedSynonyms 
                  ? 'Marked Synonyms Game' 
                  : 'Synonyms Game',
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter by category',
                ),
              ],
            ),
            body: _isLoading 
                ? const AppLoadingIndicator()
                : _buildGameContent(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGameContent() {
    if (_gameItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'No words with synonyms available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.onlyMarkedSynonyms 
                  ? 'You haven\'t marked any synonyms yet.\nGo to Flashcards and tap on synonyms to mark them for learning.'
                  : _selectedCategory != null 
                      ? 'No words with synonyms in the $_selectedCategory category'
                      : 'Add some vocabulary words with synonyms first',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (widget.onlyMarkedSynonyms)
              Column(
                children: [
                  const Text(
                    'How to mark synonyms:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Numbered instructions
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Go to Flashcards'),
                        Text('2. Flip any card to see its back side'),
                        Text('3. Tap on synonyms to mark them'),
                        Text('4. Return here to play with your marked synonyms'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _trackingService.trackButtonClick('Go to Flashcards from Empty State', screen: 'Marked Synonyms Game');
                      context.push(AppConstants.flashcardsRoute);
                    },
                    icon: const Icon(Icons.credit_card),
                    label: const Text('Go to Flashcards'),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () {
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
    }
    
    if (_isGameComplete) {
      return _buildGameCompleteScreen();
    }
    
    return _buildQuestionScreen();
  }
  
  Widget _buildQuestionScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score and progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: $_score',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Question ${_currentItemIndex + 1} of ${_gameItems.length}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Word card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _currentWord.word,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () {
                            _ttsHelper.speak(_currentWord.word);
                          },
                        ),
                      ],
                    ),
                    
                    // Display emoji if available
                    if (_currentWord.wordEmoji != null && _currentWord.wordEmoji!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          _currentWord.wordEmoji!,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      _currentWord.meaning,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    if (_currentWord.partOfSpeech != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '(${_currentWord.partOfSpeech})',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Question
            const Text(
              'Select the correct synonym:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Options
            ...List.generate(_options.length, (index) {
              final option = _options[index];
              
              Color? backgroundColor;
              if (_isAnswerChecked) {
                if (option == _correctSynonym) {
                  backgroundColor = Colors.green[100];
                } else if (option == _selectedOption && option != _correctSynonym) {
                  backgroundColor = Colors.red[100];
                }
              } else if (option == _selectedOption) {
                backgroundColor = Colors.blue[50];
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Material(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _isAnswerChecked ? null : () {
                      setState(() {
                        _selectedOption = option;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: option == _selectedOption 
                              ? Colors.blue 
                              : Colors.grey[300]!,
                          width: option == _selectedOption ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Replace emoji with voice icon
                          IconButton(
                            icon: const Icon(Icons.volume_up, size: 20),
                            onPressed: () {
                              _ttsHelper.speak(option);
                            },
                            tooltip: 'Listen to this word',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: option == _selectedOption 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (_isAnswerChecked && option == _correctSynonym)
                            const Icon(Icons.check_circle, color: Colors.green)
                          else if (_isAnswerChecked && option == _selectedOption && option != _correctSynonym)
                            const Icon(Icons.cancel, color: Colors.red)
                          else if (option == _selectedOption)
                            const Icon(Icons.radio_button_checked, color: Colors.blue)
                          else
                            const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            
            // Replace Spacer with SizedBox for fixed spacing
            const SizedBox(height: 24),
            
            // Action buttons
            if (_isAnswerChecked)
              ElevatedButton.icon(
                onPressed: _nextQuestion,
                icon: const Icon(Icons.arrow_forward),
                label: Text(_currentItemIndex < _gameItems.length - 1 
                    ? 'Next Question' 
                    : 'Finish Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _selectedOption == null ? null : _checkAnswer,
                icon: const Icon(Icons.check),
                label: const Text('Check Answer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            
            // Add bottom padding to ensure content doesn't get cut off by bottom navigation
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGameCompleteScreen() {
    final percentage = _totalQuestions > 0 
        ? (_score / (_totalQuestions * AppConstants.pointsPerCorrectSynonym) * 100).toInt() 
        : 0;
    
    String feedback;
    IconData icon;
    Color color;
    String emoji;
    
    if (percentage >= 90) {
      feedback = 'Excellent! You have mastered these synonyms!';
      icon = Icons.emoji_events;
      color = Colors.amber;
      emoji = '🏆';
    } else if (percentage >= 70) {
      feedback = 'Great job! Keep practicing to improve further.';
      icon = Icons.thumb_up;
      color = Colors.green;
      emoji = '👍';
    } else if (percentage >= 50) {
      feedback = 'Good effort! Regular practice will help you improve.';
      icon = Icons.sentiment_satisfied;
      color = Colors.blue;
      emoji = '😊';
    } else {
      feedback = 'Keep learning! Review these words and try again.';
      icon = Icons.school;
      color = Colors.purple;
      emoji = '📚';
    }
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: color),
            Text(
              emoji,
              style: const TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 24),
            const Text(
              'Game Complete!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Score: $_score / ${_totalQuestions * AppConstants.pointsPerCorrectSynonym}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              feedback,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _restartGame,
                  icon: const Icon(Icons.replay),
                  label: const Text('Play Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    if (GoRouter.of(context).canPop()) {
                      context.pop();
                    } else {
                      context.go(AppConstants.homeRoute);
                    }
                  },
                  icon: const Icon(Icons.games),
                  label: const Text('All Games'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            // Add bottom padding
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 