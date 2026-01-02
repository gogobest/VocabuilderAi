import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/utils/tracking_service.dart';
import 'package:visual_vocabularies/core/utils/antonyms_game_service.dart';
import 'package:visual_vocabularies/core/widgets/app_error_widget.dart';
import 'package:visual_vocabularies/core/widgets/app_loading_indicator.dart';
import 'package:visual_vocabularies/core/widgets/app_navigation_bar.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_event.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_state.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/widgets/vocabulary_form/tts_helper.dart';
import 'package:visual_vocabularies/features/vocabulary/data/models/vocabulary_item_model.dart';

/// A page that allows users to play a game with antonyms
class AntonymsGamePage extends StatefulWidget {
  /// Optional category filter
  final String? categoryFilter;
  
  /// Whether to play only with marked antonyms
  final bool onlyMarkedAntonyms;
  
  /// Constructor for AntonymsGamePage
  const AntonymsGamePage({
    super.key,
    this.categoryFilter,
    this.onlyMarkedAntonyms = false,
  });

  @override
  State<AntonymsGamePage> createState() => _AntonymsGamePageState();
}

class _AntonymsGamePageState extends State<AntonymsGamePage> {
  final VocabularyBloc _vocabularyBloc = sl<VocabularyBloc>();
  final TrackingService _trackingService = sl<TrackingService>();
  final AntonymsGameService _antonymsGameService = sl<AntonymsGameService>();
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
  String _correctAntonym = '';
  
  @override
  void initState() {
    super.initState();
    _ttsHelper = TtsHelper(context);
    _selectedCategory = widget.categoryFilter;
    
    _loadCategories();
    _loadVocabularyItems();
    
    // Track page view
    _trackingService.trackNavigation('Antonyms Game Page');
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
    
    // Filter items that have antonyms
    final itemsWithAntonyms = items.where((item) => 
      item.antonyms != null && item.antonyms!.isNotEmpty
    ).toList();
    
    if (widget.onlyMarkedAntonyms) {
      try {
        final markedItems = await _antonymsGameService.getVocabularyItemsWithMarkedAntonyms(itemsWithAntonyms);
        
        setState(() {
          _gameItems = markedItems;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading marked antonyms: $e');
        setState(() {
          _gameItems = [];
          _isLoading = false;
        });
        return;
      }
    } else {
      setState(() {
        _gameItems = itemsWithAntonyms;
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
      _correctAntonym = await _getRandomAntonym(_currentWord);
      _options = _generateOptions(_currentWord, _correctAntonym);
      
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
  
  Future<String> _getRandomAntonym(VocabularyItem item) async {
    if (item.antonyms == null || item.antonyms!.isEmpty) {
      throw Exception('No antonyms available for this word');
    }
    
    if (widget.onlyMarkedAntonyms) {
      // Get a marked antonym
      try {
        final markedAntonyms = await _antonymsGameService.getMarkedAntonymsForWord(item.id);
        if (markedAntonyms.isNotEmpty) {
          return markedAntonyms[Random().nextInt(markedAntonyms.length)];
        }
        // If no marked antonyms found, fall back to first antonym
        return item.antonyms!.first;
      } catch (e) {
        print('Error getting marked antonyms: $e');
        // Fallback to first antonym if there's an error
        return item.antonyms!.first;
      }
    }
    
    // Get a random antonym
    final antonyms = item.antonyms!;
    return antonyms[Random().nextInt(antonyms.length)];
  }
  
  List<String> _generateOptions(VocabularyItem currentWord, String correctAntonym) {
    // Create list with the correct answer
    List<String> options = [correctAntonym];
    
    // Add other words randomly as distractors
    final distractorPool = _allVocabularyItems
        .where((item) => item.id != currentWord.id)
        .toList();
    
    if (distractorPool.isEmpty) {
      // If no other words available, use some default distractors
      options.addAll(['good', 'bad', 'large', 'small', 'fast', 'slow', 'happy', 'sad']);
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
  
  // Check the selected answer
  void _checkAnswer() {
    if (_selectedOption == null) {
      return;
    }
    
    final bool isCorrect = _selectedOption == _correctAntonym;
    
    setState(() {
      _isAnswerChecked = true;
      _isCorrect = isCorrect;
      
      if (isCorrect) {
        _score++;
      }
    });
    
    _trackingService.trackGameAction(
      'Answer Antonym Question',
      {
        'word': _currentWord.word,
        'correct': isCorrect,
        'selected_option': _selectedOption,
        'correct_option': _correctAntonym,
      },
    );
  }
  
  // Move to next question
  void _nextQuestion() {
    setState(() {
      _currentItemIndex++;
    });
    
    _startNewRound();
  }
  
  // Restart the game
  void _restartGame() {
    setState(() {
      _currentItemIndex = 0;
      _score = 0;
      _totalQuestions = 0;
      _isGameComplete = false;
      _selectedOption = null;
      _isAnswerChecked = false;
    });
    
    // Shuffle the game items
    _gameItems.shuffle();
    
    _startNewRound();
    
    _trackingService.trackButtonClick('Restart Antonyms Game', screen: 'Antonyms Game');
  }
  
  // Show category filter dialog
  Future<void> _showFilterDialog() async {
    final selectedCategory = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Filter by Category'),
          children: [
            // Option for all categories
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text('All Categories'),
            ),
            // Divider
            const Divider(),
            // List of categories
            ..._availableCategories.map((category) {
              return SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, category);
                },
                child: Text(category),
              );
            }).toList(),
          ],
        );
      },
    );
    
    if (selectedCategory != _selectedCategory) {
      setState(() {
        _selectedCategory = selectedCategory;
      });
      
      _loadVocabularyItems();
      
      if (selectedCategory != null) {
        _trackingService.trackButtonClick('Filter Antonyms Game by $selectedCategory', screen: 'Antonyms Game');
      } else {
        _trackingService.trackButtonClick('Show All Categories in Antonyms Game', screen: 'Antonyms Game');
      }
    }
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
              title: widget.onlyMarkedAntonyms 
                  ? 'Marked Antonyms Game' 
                  : 'Antonyms Game',
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
              'No words with antonyms available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.onlyMarkedAntonyms 
                  ? 'You haven\'t marked any antonyms yet.\nGo to Flashcards and tap on antonyms to mark them for learning.'
                  : _selectedCategory != null 
                      ? 'No words with antonyms in the $_selectedCategory category'
                      : 'Add some vocabulary words with antonyms first',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (widget.onlyMarkedAntonyms)
              Column(
                children: [
                  const Text(
                    'How to mark antonyms:',
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
                        Text('3. Tap on antonyms to mark them'),
                        Text('4. Return here to play with your marked antonyms'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _trackingService.trackButtonClick('Go to Flashcards from Empty State', screen: 'Marked Antonyms Game');
                      context.push(AppConstants.flashcardsRoute);
                    },
                    icon: const Icon(Icons.credit_card),
                    label: const Text('Go to Flashcards'),
                  ),
                ],
              )
          ],
        ),
      );
    }
    
    if (_isGameComplete) {
      return _buildGameCompleteView();
    }
    
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
                    // Add emoji if available
                    if (_currentWord.wordEmoji != null && _currentWord.wordEmoji!.isNotEmpty)
                      Text(
                        _currentWord.wordEmoji!,
                        style: const TextStyle(fontSize: 48),
                      ),
                      
                    Text(
                      _currentWord.word,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
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
              'Select the correct antonym:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Options
            ...List.generate(_options.length, (index) {
              final option = _options[index];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ElevatedButton(
                  onPressed: _isAnswerChecked ? null : () {
                    setState(() {
                      _selectedOption = option;
                    });
                    _checkAnswer();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAnswerChecked
                        ? (option == _correctAntonym
                            ? Colors.green
                            : (_selectedOption == option ? Colors.red : null))
                        : (_selectedOption == option ? Colors.blue : null),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(option, style: const TextStyle(fontSize: 16)),
                ),
              );
            }),
            
            const SizedBox(height: 24),
            
            // Feedback and next button
            if (_isAnswerChecked)
              Column(
                children: [
                  // Feedback message
                  Text(
                    _isCorrect 
                        ? 'Correct! 👏'
                        : 'Incorrect. The correct antonym is "$_correctAntonym"',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isCorrect ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Next button
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                    ),
                    child: Text(
                      _currentItemIndex < _gameItems.length - 1 
                          ? 'Next Question'
                          : 'See Results',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGameCompleteView() {
    final double scorePercentage = _totalQuestions > 0 
        ? (_score / _totalQuestions) * 100 
        : 0;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, size: 64, color: Colors.amber),
          const SizedBox(height: 24),
          const Text(
            'Game Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your score: $_score/$_totalQuestions',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            '${scorePercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: scorePercentage >= 70 
                  ? Colors.green 
                  : (scorePercentage >= 40 ? Colors.amber : Colors.red),
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: _restartGame,
            icon: const Icon(Icons.replay),
            label: const Text('Play Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              context.go(AppConstants.gamesRoute);
            },
            icon: const Icon(Icons.games),
            label: const Text('All Games'),
          ),
        ],
      ),
    );
  }
} 