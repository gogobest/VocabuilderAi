import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/utils/tracking_service.dart';
import 'package:visual_vocabularies/core/utils/tenses_game_service.dart';
import 'package:visual_vocabularies/core/widgets/app_error_widget.dart';
import 'package:visual_vocabularies/core/widgets/app_loading_indicator.dart';
import 'package:visual_vocabularies/core/widgets/app_navigation_bar.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_event.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_state.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/widgets/vocabulary_form/tts_helper.dart';
import 'package:visual_vocabularies/core/utils/ai_service.dart';
import 'package:visual_vocabularies/core/utils/tenses_ai_service.dart';
import 'package:visual_vocabularies/features/tenses_game/presentation/widgets/tense_evaluation_dialog.dart';
import 'package:go_router/go_router.dart';

/// A page that allows users to play a game to practice verb tenses
class TensesGamePage extends StatefulWidget {
  /// Optional category filter
  final String? categoryFilter;
  
  /// Whether to play only with marked words
  final bool onlyMarkedWords;
  
  /// Constructor for TensesGamePage
  const TensesGamePage({
    super.key,
    this.categoryFilter,
    this.onlyMarkedWords = false,
  });

  @override
  State<TensesGamePage> createState() => _TensesGamePageState();
}

class _TensesGamePageState extends State<TensesGamePage> {
  final VocabularyBloc _vocabularyBloc = sl<VocabularyBloc>();
  final TrackingService _trackingService = sl<TrackingService>();
  final TensesGameService _tensesGameService = sl<TensesGameService>();
  final AiService _aiService = sl<AiService>();
  final TensesAiService _tensesAiService = sl<TensesAiService>();
  late TtsHelper _ttsHelper;
  
  List<VocabularyItem> _allVocabularyItems = [];
  List<VocabularyItem> _gameItems = [];
  String? _selectedCategory;
  
  bool _isLoading = true;
  bool _isGameStarted = false;
  
  // Game state
  int _currentItemIndex = 0;
  int _score = 0;
  int _totalQuestions = 0;
  bool _isGameComplete = false;
  
  // Current game item
  late VocabularyItem _currentItem;
  String _selectedTense = 'Present Simple';
  String _userAnswer = '';
  String _aiResponse = '';
  bool _isAnswerChecked = false;
  bool _isAnswerCorrect = false;
  bool _isSubmitting = false;
  bool _isAiEvaluating = false;
  
  // Option mode
  String _selectedOption = 'verb'; // 'nonVerb', 'verb', 'phrase'
  
  // Game options
  final List<String> _tenseOptions = [
    'Present Simple',
    'Present Continuous',
    'Present Perfect',
    'Present Perfect Continuous',
    'Past Simple',
    'Past Continuous',
    'Past Perfect',
    'Past Perfect Continuous',
    'Future Simple',
    'Future Continuous',
    'Future Perfect',
    'Future Perfect Continuous',
  ];
  
  @override
  void initState() {
    super.initState();
    _ttsHelper = TtsHelper(context);
    _selectedCategory = widget.categoryFilter;
    
    _loadVocabularyItems();
    
    // Track page view
    _trackingService.trackNavigation('Tenses Game Page');
  }
  
  @override
  void dispose() {
    _ttsHelper.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavigationBar(
        title: 'Tenses Game',
        showBackButton: true,
      ),
      body: BlocListener<VocabularyBloc, VocabularyState>(
        bloc: _vocabularyBloc,
        listener: (context, state) {
          if (state is VocabularyLoaded) {
            _processLoadedItems(state.items);
          } else if (state is VocabularyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
            setState(() {
              _isLoading = false;
            });
          }
        },
        child: BlocBuilder<VocabularyBloc, VocabularyState>(
          bloc: _vocabularyBloc,
          builder: (context, state) {
            if (state is VocabularyLoading) {
              return const AppLoadingIndicator();
            } else if (state is VocabularyError) {
              return AppErrorWidget(
                message: state.message,
                onRetry: _loadVocabularyItems,
              );
            }
            
            if (_isLoading) {
              return const AppLoadingIndicator();
            }
            
            // Show game setup when not started
            if (!_isGameStarted) {
              return _buildGameSetup();
            }
            
            // Show game complete screen
            if (_isGameComplete) {
              return _buildGameComplete();
            }
            
            // Show main game screen
            return _buildGameScreen();
          },
        ),
      ),
    );
  }
  
  // Process loaded vocabulary items
  Future<void> _processLoadedItems(List<VocabularyItem> items) async {
    _allVocabularyItems = items;
    
    if (widget.onlyMarkedWords) {
      try {
        final markedItems = await _tensesGameService.getVocabularyItemsForTensesGame(items);
        
        setState(() {
          _gameItems = markedItems;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading marked words: $e');
        setState(() {
          _gameItems = [];
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _gameItems = items;
        _isLoading = false;
      });
    }
  }
  
  // Build game setup screen
  Widget _buildGameSetup() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordCount = _gameItems.length;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title with icon
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.timeline,
                  size: 48,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  'Timeline Tenses Game',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Word count badge
                if (wordCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$wordCount words available',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Choose game option
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.category, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Select Word Type:',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Option buttons
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Non-Verb Words'),
                        selected: _selectedOption == 'nonVerb',
                        labelStyle: TextStyle(
                          fontWeight: _selectedOption == 'nonVerb' ? FontWeight.bold : FontWeight.normal,
                        ),
                        avatar: _selectedOption == 'nonVerb' ? const Icon(Icons.check, size: 18) : null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedOption = 'nonVerb';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Verbs'),
                        selected: _selectedOption == 'verb',
                        labelStyle: TextStyle(
                          fontWeight: _selectedOption == 'verb' ? FontWeight.bold : FontWeight.normal,
                        ),
                        avatar: _selectedOption == 'verb' ? const Icon(Icons.check, size: 18) : null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedOption = 'verb';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Phrases'),
                        selected: _selectedOption == 'phrase',
                        labelStyle: TextStyle(
                          fontWeight: _selectedOption == 'phrase' ? FontWeight.bold : FontWeight.normal,
                        ),
                        avatar: _selectedOption == 'phrase' ? const Icon(Icons.check, size: 18) : null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedOption = 'phrase';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Option descriptions
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.primaryContainer),
                    ),
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: _selectedOption == 'nonVerb' 
                          ? CrossFadeState.showFirst 
                          : CrossFadeState.showSecond,
                      firstChild: Row(
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Practice creating sentences with non-verb vocabulary in different tenses.',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onBackground,
                              ),
                            ),
                          ),
                        ],
                      ),
                      secondChild: _selectedOption == 'verb'
                          ? Row(
                              children: [
                                Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Practice conjugating verbs in different tenses.',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: colorScheme.onBackground,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Identify the tense used in common phrases and expressions.',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: colorScheme.onBackground,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Choose tense
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.watch_later, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Select Tense to Practice:',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Tense selection grid
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Present tenses
                      _buildTenseCategoryHeader(
                        icon: Icons.access_time, 
                        color: Colors.green,
                        title: 'Present Tenses',
                        subtitle: 'Actions happening now or regularly',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tenseOptions
                            .where((tense) => tense.contains('Present'))
                            .map((tense) => _buildTenseChip(
                              tense: tense,
                              icon: _getTenseIcon(tense),
                              color: Colors.green,
                              materialColor: Colors.green,
                              isDark: isDark,
                            ))
                            .toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      // Divider
                      Divider(color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      
                      // Past tenses
                      _buildTenseCategoryHeader(
                        icon: Icons.history, 
                        color: Colors.purple,
                        title: 'Past Tenses',
                        subtitle: 'Actions that happened before now',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tenseOptions
                            .where((tense) => tense.contains('Past'))
                            .map((tense) => _buildTenseChip(
                              tense: tense,
                              icon: _getTenseIcon(tense),
                              color: Colors.purple,
                              materialColor: Colors.purple,
                              isDark: isDark,
                            ))
                            .toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      // Divider
                      Divider(color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      
                      // Future tenses
                      _buildTenseCategoryHeader(
                        icon: Icons.update, 
                        color: Colors.blue,
                        title: 'Future Tenses',
                        subtitle: 'Actions that will happen later',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tenseOptions
                            .where((tense) => tense.contains('Future'))
                            .map((tense) => _buildTenseChip(
                              tense: tense,
                              icon: _getTenseIcon(tense),
                              color: Colors.blue,
                              materialColor: Colors.blue,
                              isDark: isDark,
                            ))
                            .toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Timeline visualization
          _buildTimelineVisualization(),
          
          const SizedBox(height: 30),
          
          // Start game button
          ElevatedButton.icon(
            onPressed: _gameItems.isEmpty 
                ? null 
                : () => _startGame(),
            icon: const Icon(Icons.play_arrow, size: 28),
            label: Text(
              _gameItems.isEmpty 
                  ? 'No Words Available' 
                  : 'Start Game',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          if (_gameItems.isEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: isDark ? Colors.amber.shade900.withOpacity(0.3) : Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? Colors.amber.shade700 : Colors.amber.shade300,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You need to mark some words for tenses practice first.',
                        style: TextStyle(
                          color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                context.push(AppConstants.savedTenseReviewCardsRoute);
              },
              icon: const Icon(Icons.bookmark),
              label: const Text('Go to Saved Tense Cards'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Build timeline visualization
  Widget _buildTimelineVisualization() {
    // Determine if selected tense is past, present, or future
    final bool isPast = _selectedTense.contains('Past');
    final bool isPresent = _selectedTense.contains('Present');
    final bool isFuture = _selectedTense.contains('Future');
    
    // Determine if continuous or perfect
    final bool isContinuous = _selectedTense.contains('Continuous');
    final bool isPerfect = _selectedTense.contains('Perfect');
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Define colors that work in both light and dark modes
    final pastColor = isPast 
        ? (isDark ? Colors.purple.shade300 : Colors.purple) 
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);
    
    final presentColor = isPresent 
        ? (isDark ? Colors.green.shade300 : Colors.green) 
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);
    
    final futureColor = isFuture 
        ? (isDark ? Colors.blue.shade300 : Colors.blue) 
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 260),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceVariant : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timeline header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    _getTenseTimelineDescription(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            
            // Fixed timeline part
            SizedBox(
              height: 90,
              child: Stack(
                children: [
                  // Timeline line
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 30,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            pastColor.withOpacity(0.7),
                            presentColor.withOpacity(0.7),
                            futureColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  
                  // Past marker
                  Positioned(
                    left: 20,
                    top: 20,
                    child: Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: pastColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.black54 : Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: pastColor.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'PAST',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isPast ? FontWeight.bold : FontWeight.normal,
                            color: isPast 
                                ? (isDark ? Colors.purple.shade300 : Colors.purple.shade700) 
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Present marker
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 20,
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: presentColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.black54 : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: presentColor.withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'NOW',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isPresent ? FontWeight.bold : FontWeight.normal,
                              color: isPresent 
                                  ? (isDark ? Colors.green.shade300 : Colors.green.shade700) 
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Future marker
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: futureColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.black54 : Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: futureColor.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'FUTURE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isFuture ? FontWeight.bold : FontWeight.normal,
                            color: isFuture 
                                ? (isDark ? Colors.blue.shade300 : Colors.blue.shade700) 
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Aspect visualization
                  if (isPerfect || isContinuous) ...[
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (isContinuous)
                              Chip(
                                label: const Text('ONGOING'),
                                backgroundColor: isDark 
                                    ? Colors.purple.shade900.withOpacity(0.7) 
                                    : Colors.purple.shade50,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark 
                                      ? Colors.purple.shade200 
                                      : Colors.purple.shade900,
                                ),
                                visualDensity: VisualDensity.compact,
                                side: BorderSide(
                                  color: isDark 
                                      ? Colors.purple.shade700 
                                      : Colors.purple.shade300,
                                ),
                              ),
                            if (isPerfect)
                              Chip(
                                label: const Text('COMPLETED'),
                                backgroundColor: isDark 
                                    ? Colors.red.shade900.withOpacity(0.7) 
                                    : Colors.red.shade50,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark 
                                      ? Colors.red.shade200 
                                      : Colors.red.shade900,
                                ),
                                visualDensity: VisualDensity.compact,
                                side: BorderSide(
                                  color: isDark 
                                      ? Colors.red.shade700 
                                      : Colors.red.shade300,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Divider
            const Divider(height: 16, thickness: 1),
            
            // Scrollable use cases section
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // When to use header
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline, 
                          size: 16, 
                          color: _getTenseColor(isDark),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'WHEN TO USE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getTenseColor(isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Use cases container
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getTenseColor(isDark).withOpacity(isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getTenseColor(isDark).withOpacity(isDark ? 0.3 : 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _getUseCases(_selectedTense).map((useCase) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getTenseColor(isDark),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    useCase,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Example
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getTenseColor(isDark).withOpacity(isDark ? 0.25 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getTenseExample(_selectedTense),
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? _getTenseColor(isDark).shade200 : _getTenseColor(isDark).shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to get color based on selected tense
  MaterialColor _getTenseColor(bool isDark) {
    if (_selectedTense.contains('Past')) {
      return Colors.purple;
    } else if (_selectedTense.contains('Present')) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }
  
  // Helper method to get list of use cases for each tense
  List<String> _getUseCases(String tense) {
    switch (tense) {
      case 'Present Simple':
        return [
          'Facts or general truths',
          'Habits or routines',
          'Scheduled future events',
        ];
      case 'Present Continuous':
        return [
          'Actions happening right now',
          'Temporary situations',
          'Planned arrangements in near future',
        ];
      case 'Present Perfect':
        return [
          'Past actions with present results',
          'Experiences without specific time',
          'Actions that continue to present',
        ];
      case 'Present Perfect Continuous':
        return [
          'Actions that started in past and continue to now',
          'Recent continuous activities with present results',
          'Emphasizing duration of an ongoing action',
        ];
      case 'Past Simple':
        return [
          'Completed actions at a specific time in the past',
          'Series of completed actions',
          'Past habits or states',
        ];
      case 'Past Continuous':
        return [
          'Actions in progress at a specific moment in the past',
          'Background actions interrupted by another action',
          'Repeated past actions that were annoying',
        ];
      case 'Past Perfect':
        return [
          'Actions completed before another past action',
          'Reported speech with backshift',
          'Past wishes or regrets',
        ];
      case 'Past Perfect Continuous':
        return [
          'Actions that continued up until another time in the past',
          'Emphasizing duration of a past action with results',
          'Explaining cause of a past situation',
        ];
      case 'Future Simple':
        return [
          'Predictions about the future',
          'Spontaneous decisions',
          'Promises or threats',
        ];
      case 'Future Continuous':
        return [
          'Actions in progress at a specific time in the future',
          'Predicted future ongoing events',
          'Polite questions about someone\'s plans',
        ];
      case 'Future Perfect':
        return [
          'Actions that will be completed before a specific time in future',
          'Looking back from a point in the future',
          'Emphasizing results by a future time',
        ];
      case 'Future Perfect Continuous':
        return [
          'Actions that will continue up until a point in the future',
          'Emphasizing duration of a future action up to specific time',
          'Future actions with focus on process rather than completion',
        ];
      default:
        return ['Select a tense to see usage examples'];
    }
  }
  
  // Helper method to get example sentence for each tense
  String _getTenseExample(String tense) {
    switch (tense) {
      case 'Present Simple':
        return 'She works at a bank. (habit)';
      case 'Present Continuous':
        return 'I am studying English now. (current action)';
      case 'Present Perfect':
        return 'I have visited Paris three times. (experience)';
      case 'Present Perfect Continuous':
        return 'I have been waiting for an hour. (ongoing)';
      case 'Past Simple':
        return 'I watched a movie yesterday. (completed)';
      case 'Past Continuous':
        return 'I was reading when you called. (interrupted)';
      case 'Past Perfect':
        return 'I had already eaten when they arrived. (before)';
      case 'Past Perfect Continuous':
        return 'I had been working for 5 hours before I took a break.';
      case 'Future Simple':
        return 'I will call you tomorrow. (promise)';
      case 'Future Continuous':
        return 'This time next week, I will be flying to London.';
      case 'Future Perfect':
        return 'By next year, I will have graduated. (by a point)';
      case 'Future Perfect Continuous':
        return 'By December, I will have been studying here for 2 years.';
      default:
        return 'Example: Select a tense';
    }
  }
  
  // Get description for the selected tense
  String _getTenseTimelineDescription() {
    switch (_selectedTense) {
      case 'Present Simple':
        return 'Regular actions or states in the present';
      case 'Present Continuous':
        return 'Actions happening right now or temporarily';
      case 'Present Perfect':
        return 'Past actions with present relevance';
      case 'Present Perfect Continuous':
        return 'Actions that started in the past and continue to now';
      case 'Past Simple':
        return 'Completed actions in the past';
      case 'Past Continuous':
        return 'Actions in progress at a specific time in the past';
      case 'Past Perfect':
        return 'Actions completed before another past action';
      case 'Past Perfect Continuous':
        return 'Ongoing actions that started and ended in the past';
      case 'Future Simple':
        return 'Actions that will happen in the future';
      case 'Future Continuous':
        return 'Actions in progress at a specific time in the future';
      case 'Future Perfect':
        return 'Actions that will be completed before a future time';
      case 'Future Perfect Continuous':
        return 'Ongoing actions that will continue until a future time';
      default:
        return 'Select a tense to see its timeline';
    }
  }
  
  // Helper method to build tense category header
  Widget _buildTenseCategoryHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            border: Border.all(
              color: isDark ? color.withOpacity(0.6) : color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isDark ? color.withOpacity(0.9) : color,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? color.withOpacity(0.9) : color.withOpacity(0.8),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Helper method to build tense selection chip
  Widget _buildTenseChip({
    required String tense,
    required IconData icon,
    required Color color,
    required MaterialColor materialColor,
    required bool isDark,
  }) {
    final bool isSelected = _selectedTense == tense;
    final simplifiedName = tense.replaceAll('Present ', '')
                              .replaceAll('Past ', '')
                              .replaceAll('Future ', '');
    
    // Get syntax pattern for the tense
    final String syntaxPattern = _getTenseSyntax(tense);
    
    return FilterChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected 
                    ? (isDark ? materialColor.shade200 : materialColor.shade700)
                    : isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(simplifiedName),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(height: 4),
            Text(
              syntaxPattern,
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: isDark ? materialColor.shade200 : materialColor.shade700,
              ),
            ),
          ]
        ],
      ),
      selected: isSelected,
      selectedColor: color.withOpacity(isDark ? 0.4 : 0.2),
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      checkmarkColor: isDark ? materialColor.shade200 : materialColor.shade700,
      labelStyle: TextStyle(
        color: isSelected 
            ? (isDark ? materialColor.shade200 : materialColor.shade800)
            : isDark ? Colors.grey.shade300 : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      side: isSelected
          ? BorderSide(color: isDark ? materialColor.withOpacity(0.7) : materialColor.withOpacity(0.5), width: 1.5)
          : BorderSide(color: Colors.transparent),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedTense = tense;
          });
        }
      },
    );
  }
  
  // Get syntax pattern for each tense
  String _getTenseSyntax(String tense) {
    switch (tense) {
      case 'Present Simple':
        return 'S + V(s/es)';
      case 'Present Continuous':
        return 'S + am/is/are + V-ing';
      case 'Present Perfect':
        return 'S + have/has + V3';
      case 'Present Perfect Continuous':
        return 'S + have/has + been + V-ing';
      case 'Past Simple':
        return 'S + V2 (past)';
      case 'Past Continuous':
        return 'S + was/were + V-ing';
      case 'Past Perfect':
        return 'S + had + V3';
      case 'Past Perfect Continuous':
        return 'S + had + been + V-ing';
      case 'Future Simple':
        return 'S + will + V';
      case 'Future Continuous':
        return 'S + will + be + V-ing';
      case 'Future Perfect':
        return 'S + will + have + V3';
      case 'Future Perfect Continuous':
        return 'S + will + have + been + V-ing';
      default:
        return '';
    }
  }
  
  // Get appropriate icon for the tense
  IconData _getTenseIcon(String tense) {
    if (tense.contains('Simple')) {
      return Icons.circle_outlined;
    } else if (tense.contains('Continuous')) {
      return Icons.timelapse;
    } else if (tense.contains('Perfect Continuous')) {
      return Icons.linear_scale;
    } else if (tense.contains('Perfect')) {
      return Icons.check_circle_outline;
    } else {
      return Icons.access_time;
    }
  }
  
  // Start the game
  Future<void> _startGame() async {
    // Filter items based on selected option
    List<VocabularyItem> filteredItems = [];
    
    switch (_selectedOption) {
      case 'nonVerb':
        filteredItems = await _tensesGameService.getNonVerbItemsForTensesGame(_gameItems);
        break;
      case 'verb':
        filteredItems = await _tensesGameService.getVerbItemsForTensesGame(_gameItems);
        break;
      case 'phrase':
        filteredItems = await _tensesGameService.getPhrasesForTensesGame(_gameItems);
        break;
    }
    
    // If no items after filtering, show error
    if (filteredItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No ${_selectedOption} words available for practice. Try a different option.'),
        ),
      );
      return;
    }
    
    // Shuffle items for randomness
    filteredItems.shuffle();
    
    setState(() {
      _gameItems = filteredItems;
      _isGameStarted = true;
      _currentItemIndex = 0;
      _score = 0;
      _totalQuestions = 0;
      _isGameComplete = false;
      _currentItem = _gameItems[0];
      _userAnswer = '';
      _aiResponse = '';
      _isAnswerChecked = false;
      _isAnswerCorrect = false;
    });
    
    _trackingService.trackGameAction(
      'Started Tenses Game', 
      {
        'option': _selectedOption,
        'tense': _selectedTense,
        'itemCount': _gameItems.length,
      },
    );
  }
  
  // Build main game screen
  Widget _buildGameScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Game progress
          LinearProgressIndicator(
            value: (_currentItemIndex + 1) / _gameItems.length,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Word ${_currentItemIndex + 1} of ${_gameItems.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Word card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _currentItem.word,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_currentItem.wordEmoji != null && _currentItem.wordEmoji!.isNotEmpty)
                        Text(
                          _currentItem.wordEmoji!,
                          style: const TextStyle(fontSize: 26),
                        ),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () {
                          _ttsHelper.speak(_currentItem.word);
                        },
                        tooltip: 'Pronounce',
                      ),
                    ],
                  ),
                  
                  const Divider(),
                  
                  // Meaning
                  Text(
                    'Meaning: ${_currentItem.meaning}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Part of speech
                  if (_currentItem.partOfSpeech != null && _currentItem.partOfSpeech!.isNotEmpty)
                    Chip(
                      label: Text(_currentItem.partOfSpeech!),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Task instruction
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getTaskInstruction(),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Timeline visualization for reference
          _buildTimelineVisualization(),
          
          const SizedBox(height: 16),
          
          // Answer input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Your Answer:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  TextField(
                    maxLines: _selectedOption == 'phrase' ? 1 : 3,
                    decoration: InputDecoration(
                      hintText: _getAnswerHint(),
                      border: const OutlineInputBorder(),
                      enabled: !_isAnswerChecked && !_isSubmitting,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _userAnswer = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Submit or next button
                  if (_isAnswerChecked)
                    ElevatedButton.icon(
                      onPressed: _goToNextQuestion,
                      icon: const Icon(Icons.navigate_next),
                      label: Text(_isLastQuestion() ? 'Finish Game' : 'Next Word'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _userAnswer.trim().isEmpty || _isSubmitting || _isAiEvaluating
                          ? null
                          : _checkAnswer,
                      icon: _isSubmitting || _isAiEvaluating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isSubmitting || _isAiEvaluating ? 'Checking...' : 'Submit Answer'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // AI Feedback - Improved display
          if (_isAnswerChecked && _aiResponse.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isAnswerCorrect 
                      ? (Theme.of(context).brightness == Brightness.dark 
                          ? Colors.green.shade900.withOpacity(0.3) 
                          : Colors.green.shade50)
                      : (Theme.of(context).brightness == Brightness.dark 
                          ? Colors.red.shade900.withOpacity(0.3) 
                          : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isAnswerCorrect ? Colors.green : Colors.red,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isAnswerCorrect ? Icons.check_circle : Icons.cancel,
                          color: _isAnswerCorrect ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isAnswerCorrect ? 'Correct!' : 'Incorrect!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isAnswerCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // Remove the YES/NO prefix from the AI response
                      _aiResponse.replaceFirst(RegExp(r'^(YES|NO)\.?\s*', caseSensitive: false), ''),
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Get task instruction based on selected option
  String _getTaskInstruction() {
    switch (_selectedOption) {
      case 'nonVerb':
        return 'Create a sentence using "$_selectedTense" tense with the word "${_currentItem.word}".';
      case 'verb':
        return 'Write the correct form of the verb "${_currentItem.word}" in $_selectedTense tense.';
      case 'phrase':
        return 'Identify which tense is used in the phrase "${_currentItem.word}".';
      default:
        return 'Practice using tenses with this word.';
    }
  }
  
  // Get hint text for answer input
  String _getAnswerHint() {
    switch (_selectedOption) {
      case 'nonVerb':
        return 'Example: I ${_selectedTense.toLowerCase()} with the ${_currentItem.word}...';
      case 'verb':
        return _getVerbFormHint();
      case 'phrase':
        return 'Which tense is used in this phrase? (e.g., Present Simple)';
      default:
        return 'Your answer...';
    }
  }
  
  // Get hint specifically for verb form
  String _getVerbFormHint() {
    final verb = _currentItem.word;
    
    switch (_selectedTense) {
      case 'Present Simple':
        return 'I/You/We/They $verb or He/She/It...';
      case 'Present Continuous':
        return 'I am... / He is... / They are...';
      case 'Past Simple':
        return 'I/You/He/She/It/We/They...';
      case 'Future Simple':
        return 'I/You/He/She/It/We/They will...';
      default:
        return 'Write the correct form...';
    }
  }
  
  // Check if answer is correct using AI
  Future<void> _checkAnswer() async {
    if (_userAnswer.trim().isEmpty) return;
    
    setState(() {
      _isSubmitting = true;
      _isAiEvaluating = true;
    });
    
    try {
      // Clean up user answer and check if it contains the test word
      final String cleanAnswer = _userAnswer.trim().toLowerCase();
      final String cleanWord = _currentItem.word.trim().toLowerCase();
      
      try {
        // Use the enhanced AI evaluation
        final evaluation = await _aiService.evaluateTenseWithFeedback(
          word: cleanWord,
          userAnswer: cleanAnswer,
          tense: _selectedTense,
          option: _selectedOption,
        );
        
        setState(() {
          _isSubmitting = false;
          _isAiEvaluating = false;
          _isAnswerChecked = true;
          _isAnswerCorrect = evaluation.isCorrect;
          
          // Award points based on correctness
          if (evaluation.isCorrect) {
            _score += max(evaluation.score ~/ 10, 1); // 1-10 points based on score
          }
          
          _totalQuestions++;
        });
        
        // Show the enhanced feedback dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => TenseEvaluationDialog(
              evaluation: evaluation,
              onNext: () {
                Navigator.of(context).pop();
                _goToNextQuestion();
              },
            ),
          );
        }
      } catch (aiError) {
        print('AI service error: $aiError');
        setState(() {
          _isSubmitting = false;
          _isAiEvaluating = false;
          _isAnswerChecked = true;
          _isAnswerCorrect = cleanAnswer.contains(cleanWord);
          _aiResponse = _isAnswerCorrect 
              ? 'YES. Your answer seems correct. Score: 85' 
              : 'NO. Your answer doesn\'t appear to use "${_currentItem.word}" correctly. Score: 30';
          
          if (_isAnswerCorrect) {
            _score += 8; // Default score for fallback
          }
          
          _totalQuestions++;
        });
      }
    } catch (e) {
      print('Error checking answer: $e');
      setState(() {
        _isSubmitting = false;
        _isAiEvaluating = false;
        _isAnswerChecked = true;
        _isAnswerCorrect = false;
        _aiResponse = 'Error checking answer: $e';
      });
    }
    
    _trackingService.trackGameAction(
      'Answered Tenses Question', 
      {
        'word': _currentItem.word,
        'option': _selectedOption,
        'tense': _selectedTense,
        'correct': _isAnswerCorrect,
      },
    );
  }
  
  // Go to next question
  void _goToNextQuestion() {
    if (_isLastQuestion()) {
      setState(() {
        _isGameComplete = true;
      });
      
      _trackingService.trackGameAction(
        'Completed Tenses Game', 
        {
          'score': _score,
          'totalQuestions': _totalQuestions,
          'option': _selectedOption,
          'tense': _selectedTense,
        },
      );
      return;
    }
    
    setState(() {
      _currentItemIndex++;
      _currentItem = _gameItems[_currentItemIndex];
      _userAnswer = '';
      _aiResponse = '';
      _isAnswerChecked = false;
      _isAnswerCorrect = false;
    });
  }
  
  // Check if this is the last question
  bool _isLastQuestion() {
    return _currentItemIndex >= _gameItems.length - 1;
  }
  
  // Build game complete screen
  Widget _buildGameComplete() {
    final accuracy = _totalQuestions > 0 ? (_score / _totalQuestions) * 10 : 0;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.celebration,
              size: 80,
              color: Colors.amber,
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Game Complete!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'You scored $_score points',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Accuracy: ${accuracy.toStringAsFixed(1)}/10',
              style: const TextStyle(
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Performance summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Your Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Words', _totalQuestions.toString()),
                        _buildStatColumn('Option', _selectedOption),
                        _buildStatColumn('Tense', _selectedTense),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isGameStarted = false;
                      _isGameComplete = false;
                    });
                  },
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
                ElevatedButton.icon(
                  onPressed: () {
                    // Use proper GoRouter navigation
                    context.push(AppConstants.savedTenseReviewCardsRoute);
                    // Track navigation
                    _trackingService.trackNavigation('Tense Review Cards');
                  },
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Tense Flashcards'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Build statistic column for game complete screen
  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
} 