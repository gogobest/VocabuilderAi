import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/ai_service.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/utils/logger.dart';
import 'package:visual_vocabularies/core/utils/tracking_service.dart';
import 'package:visual_vocabularies/core/presentation/widgets/responsive_scaffold.dart';
import 'package:visual_vocabularies/features/vocabulary/data/models/vocabulary_item_model.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_event.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_state.dart';
import 'package:go_router/go_router.dart';

/// Page for generating vocabulary words using AI
class AiGenerateWordsPage extends StatefulWidget {
  /// Constructor
  const AiGenerateWordsPage({super.key});

  @override
  State<AiGenerateWordsPage> createState() => _AiGenerateWordsPageState();
}

class _AiGenerateWordsPageState extends State<AiGenerateWordsPage> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final AiService _aiService = sl<AiService>();
  final TrackingService _trackingService = sl<TrackingService>();
  final VocabularyRepository _vocabularyRepository = sl<VocabularyRepository>();
  
  String _selectedCategory = AppConstants.defaultCategories.first;
  int _selectedDifficulty = 3;
  int _wordCount = 5;
  bool _isGenerating = false;
  List<Map<String, dynamic>> _generatedWords = [];
  List<String> _existingCategories = [];
  List<VocabularyItem> _existingWords = [];
  bool _isAddingCustomCategory = false;
  int _currentProgress = 0;
  String _statusMessage = '';
  Set<String> _savedWords = {};
  int _filteredDuplicates = 0;
  
  @override
  void initState() {
    super.initState();
    _trackingService.trackNavigation('AI Word Generator');
    _loadCategories();
    
    // Initialize with default categories to avoid empty list errors
    _existingCategories = List.from(AppConstants.defaultCategories);
  }
  
  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCategories() async {
    try {
      final categoriesResult = await _vocabularyRepository.getAllCategories();
      categoriesResult.fold(
        (failure) {
          Logger.e('Error loading categories: ${failure.message}', tag: 'AiGenerateWords');
          setState(() {
            _existingCategories = List.from(AppConstants.defaultCategories);
          });
        },
        (categories) {
          setState(() {
            // Combine default and user categories without duplicates
            _existingCategories = {...AppConstants.defaultCategories, ...categories}.toList();
            // Sort alphabetically
            _existingCategories.sort();
          });
        }
      );
    } catch (e) {
      Logger.e('Error loading categories: $e', tag: 'AiGenerateWords');
      setState(() {
        _existingCategories = List.from(AppConstants.defaultCategories);
      });
    }
  }
  
  Future<void> _loadExistingWords(String category) async {
    try {
      final wordsResult = await _vocabularyRepository.getVocabularyItemsByCategory(category);
      wordsResult.fold(
        (failure) {
          Logger.e('Error loading words for category $category: ${failure.message}', tag: 'AiGenerateWords');
          setState(() {
            _existingWords = [];
          });
        },
        (words) {
          setState(() {
            _existingWords = words;
          });
        }
      );
    } catch (e) {
      Logger.e('Error loading words for category $category: $e', tag: 'AiGenerateWords');
      setState(() {
        _existingWords = [];
      });
    }
  }
  
  Future<void> _addCustomCategory(String categoryName) async {
    if (categoryName.trim().isEmpty) return;
    
    try {
      final result = await _vocabularyRepository.addCategory(categoryName.trim());
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding category: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (success) {
          setState(() {
            if (!_existingCategories.contains(categoryName.trim())) {
              _existingCategories.add(categoryName.trim());
              _existingCategories.sort();
            }
            _selectedCategory = categoryName.trim();
            _isAddingCustomCategory = false;
          });
          _categoryController.clear();
          
          _trackingService.trackEvent('Added Custom Category', data: {
            'category': categoryName.trim(),
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added category "$categoryName"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      );
    } catch (e) {
      Logger.e('Error adding category: $e', tag: 'AiGenerateWords');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'AI Word Generator',
      showBackButton: true,
      onBackPressed: () {
        context.go(AppConstants.homeRoute);
      },
      onWillPop: () async {
        context.go(AppConstants.homeRoute);
        return false;
      },
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneratorForm(),
            const SizedBox(height: 24),
            if (_isGenerating) _buildProgressIndicator(),
            if (_generatedWords.isNotEmpty && !_isGenerating) _buildWordsList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGeneratorForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Generate Vocabulary Words',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Category selection
              if (!_isAddingCustomCategory)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        value: _existingCategories.isEmpty ? AppConstants.defaultCategories.first : 
                              (_existingCategories.contains(_selectedCategory) 
                                ? _selectedCategory 
                                : _existingCategories.first),
                        items: _existingCategories.isNotEmpty 
                            ? _existingCategories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList()
                            : AppConstants.defaultCategories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                            _loadExistingWords(value);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      tooltip: 'Add custom category',
                      onPressed: () {
                        setState(() {
                          _isAddingCustomCategory = true;
                        });
                      },
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'New Category Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.create_new_folder),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a category name';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle),
                      tooltip: 'Add category',
                      onPressed: () {
                        if (_categoryController.text.trim().isNotEmpty) {
                          _addCustomCategory(_categoryController.text);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel),
                      tooltip: 'Cancel',
                      onPressed: () {
                        setState(() {
                          _isAddingCustomCategory = false;
                          _categoryController.clear();
                        });
                      },
                    ),
                  ],
                ),
              
              const SizedBox(height: 16),
              
              // Difficulty level slider
              Text(
                'Difficulty Level: $_selectedDifficulty',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: _selectedDifficulty.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _getDifficultyLabel(_selectedDifficulty),
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value.round();
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Word count input
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Number of Words (1-20)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                initialValue: _wordCount.toString(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a number';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 1 || number > 20) {
                    return 'Please enter a number between 1 and 20';
                  }
                  return null;
                },
                onChanged: (value) {
                  final number = int.tryParse(value);
                  if (number != null && number >= 1 && number <= 20) {
                    setState(() {
                      _wordCount = number;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 24),
              
              // Generate button
              ElevatedButton.icon(
                onPressed: _isAddingCustomCategory || _isGenerating 
                  ? null 
                  : () {
                    _loadExistingWords(_selectedCategory).then((_) {
                      _generateWords();
                    });
                  },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('GENERATE VOCABULARY WORDS'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    final progress = _currentProgress / _wordCount;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generating Words...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_statusMessage),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress > 0 ? progress : null,
            ),
            const SizedBox(height: 8),
            Text('Generated $_currentProgress of $_wordCount words'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWordsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Generated Words (${_generatedWords.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: _generatedWords.isEmpty ? null : _saveAllWords,
              icon: const Icon(Icons.save),
              label: const Text('SAVE ALL'),
            ),
          ],
        ),
        if (_filteredDuplicates > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtered $_filteredDuplicates duplicate ${_filteredDuplicates == 1 ? 'word' : 'words'} already in your vocabulary.',
                      style: const TextStyle(color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        ..._generatedWords.map((word) => _buildWordCard(word)),
      ],
    );
  }
  
  Widget _buildWordCard(Map<String, dynamic> word) {
    final String wordText = word['word'] as String? ?? '';
    final bool isSaved = _savedWords.contains(wordText);
    
    // Skip rendering if word data contains raw prompt text
    if (wordText.isEmpty || 
        wordText.toLowerCase().contains('generate') || 
        wordText.toLowerCase().contains('provide') ||
        wordText.length > 30) {
      return const SizedBox.shrink();
    }
    
    // Clean definition and example (remove JSON formatting if present)
    String definition = word['definition'] as String? ?? 'No definition available';
    String example = word['example'] as String? ?? 'No example available';
    
    // Remove JSON formatting if present in definition or example
    if (definition.contains('"definition"') || definition.contains('"meaning"')) {
      definition = 'A term related to ${_selectedCategory.toLowerCase()}.';
    }
    
    if (example.contains('"example"')) {
      example = 'Example usage in ${_selectedCategory.toLowerCase()}.';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        '${word['emoji'] ?? '📝'} ',
                        style: const TextStyle(fontSize: 28),
                      ),
                      Expanded(
                        child: Text(
                          wordText,
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.check_circle : Icons.add_circle_outline,
                    color: isSaved ? Colors.green : null,
                  ),
                  onPressed: isSaved ? null : () => _saveWord(word),
                  tooltip: isSaved ? 'Saved' : 'Save Word',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              definition,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Example: $example',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(word['partOfSpeech'] as String? ?? 'noun'),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
                Chip(
                  label: Text(word['category'] as String? ?? _selectedCategory),
                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                ),
                Chip(
                  label: Text('Level ${word['difficultyLevel'] ?? _selectedDifficulty}'),
                  backgroundColor: Colors.amber.withOpacity(0.2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getDifficultyLabel(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Elementary';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Proficient';
      default:
        return 'Intermediate';
    }
  }
  
  Future<void> _generateWords() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isGenerating = true;
      _currentProgress = 0;
      _generatedWords = [];
      _savedWords = {};
      _filteredDuplicates = 0;
      _statusMessage = 'Initializing AI generator...';
    });
    
    try {
      // Generate list of words for the category
      final prompt = 'Generate $_wordCount simple ${_getDifficultyLabel(_selectedDifficulty)} level '
                    'vocabulary words for category: $_selectedCategory';
      
      _trackingService.trackEvent('Generate AI Words', data: {
        'category': _selectedCategory,
        'difficulty': _selectedDifficulty,
        'wordCount': _wordCount,
      });
      
      // Generate a list of words first
      setState(() {
        _statusMessage = 'Requesting word list from AI...';
      });
      
      final List<String> wordSuggestions = await _generateWordSuggestions();
      
      // Filter out words that already exist in this category
      final existingWordTexts = _existingWords.map((item) => item.word.toLowerCase()).toList();
      final filteredSuggestions = wordSuggestions.where((word) => 
        !existingWordTexts.contains(word.toLowerCase())
      ).toList();
      
      setState(() {
        _filteredDuplicates = wordSuggestions.length - filteredSuggestions.length;
      });
      
      // If too many words were filtered, generate more
      if (filteredSuggestions.length < _wordCount && _filteredDuplicates > 0) {
        // Try to get additional words to make up for filtered ones
        setState(() {
          _statusMessage = 'Generating additional words to replace duplicates...';
        });
        
        try {
          final additionalPrompt = 'Generate ${_wordCount - filteredSuggestions.length} more unique ${_getDifficultyLabel(_selectedDifficulty)} level '
                      'words for category: $_selectedCategory that are not in this list: ${existingWordTexts.join(", ")}';
                      
          final additionalWords = await _aiService.generateVocabularyItem(additionalPrompt);
          
          if (additionalWords.containsKey('suggestions') && additionalWords['suggestions'] is List) {
            final newWords = List<String>.from(additionalWords['suggestions'] as List);
            
            // Only add words that don't already exist
            for (final word in newWords) {
              if (!existingWordTexts.contains(word.toLowerCase()) && 
                  !filteredSuggestions.map((w) => w.toLowerCase()).contains(word.toLowerCase())) {
                filteredSuggestions.add(word);
                if (filteredSuggestions.length >= _wordCount) break;
              }
            }
          }
        } catch (e) {
          Logger.e('Error generating additional words: $e', tag: 'AiGenerateWords');
          // Continue with what we have
        }
      }
      
      // For each suggested word, generate full vocabulary item
      for (int i = 0; i < filteredSuggestions.length; i++) {
        if (!mounted) return; // Check if widget is still mounted
        
        final word = filteredSuggestions[i];
        
        // Skip if it contains "generate" or other prompt text
        if (word.toLowerCase().contains('generate') || 
            word.toLowerCase().contains('provide') ||
            word.length > 30) {
          continue;
        }
        
        setState(() {
          _statusMessage = 'Generating details for: $word (${i+1}/${filteredSuggestions.length})';
        });
        
        try {
          // Use a direct word-focused prompt to get clean results
          final wordData = await _aiService.generateVocabularyItem(
            'Word: $word\nCategory: $_selectedCategory\nDifficulty: $_selectedDifficulty\n\n'
            'Please provide a short definition and example for this word.'
          );
          
          // Always set the word field to our original clean word
          wordData['word'] = word;
          
          // Ensure we have a definition one way or another
          if (!wordData.containsKey('definition') || wordData['definition'] == null || 
              wordData['definition'].toString().trim().isEmpty ||
              wordData['definition'].toString().contains('"definition"')) {
            
            // Try the meaning field as fallback
            if (wordData.containsKey('meaning') && wordData['meaning'] != null && 
                wordData['meaning'].toString().trim().isNotEmpty &&
                !wordData['meaning'].toString().contains('"meaning"')) {
              wordData['definition'] = wordData['meaning'];
            } else {
              // Generate a simple definition based on category if all else fails
              wordData['definition'] = 'A $word related to ${_selectedCategory.toLowerCase()}.';
            }
          }
          
          // Ensure we have an example sentence
          if (!wordData.containsKey('example') || wordData['example'] == null || 
              wordData['example'].toString().trim().isEmpty ||
              wordData['example'].toString().contains('"example"')) {
            wordData['example'] = 'The $word is important in ${_selectedCategory.toLowerCase()}.';
          }
          
          // Clean up any excessively long definition or example
          if (wordData['definition'].toString().length > 150) {
            wordData['definition'] = wordData['definition'].toString().substring(0, 147) + '...';
          }
          
          if (wordData['example'].toString().length > 120) {
            wordData['example'] = wordData['example'].toString().substring(0, 117) + '...';
          }
          
          // Clean up example to start with "Example: " if it doesn't already
          if (wordData['example'].toString().toLowerCase().startsWith('example:')) {
            wordData['example'] = wordData['example'].toString().substring(8).trim();
          }
          
          // Ensure the category and difficulty are set correctly
          wordData['category'] = _selectedCategory;
          wordData['difficultyLevel'] = _selectedDifficulty;
          
          setState(() {
            _generatedWords.add(wordData);
            _currentProgress = i + 1;
          });
        } catch (e) {
          Logger.e('Error generating details for word $word: $e', tag: 'AiGenerateWords');
          
          // Add a basic entry with fallback values if the API call fails
          final fallbackWordData = {
            'word': word,
            'definition': 'A term related to ${_selectedCategory.toLowerCase()}.',
            'example': 'This $word is used in ${_selectedCategory.toLowerCase()}.',
            'partOfSpeech': 'noun',
            'category': _selectedCategory,
            'difficultyLevel': _selectedDifficulty,
          };
          
          setState(() {
            _generatedWords.add(fallbackWordData);
            _currentProgress = i + 1;
          });
        }
      }
    } catch (e) {
      Logger.e('Error generating words: $e', tag: 'AiGenerateWords');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating words: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '';
        });
      }
    }
  }
  
  Future<List<String>> _generateWordSuggestions() async {
    return await _aiService.generateWordList(
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
      count: _wordCount,
    );
  }
  
  Future<void> _saveWord(Map<String, dynamic> wordData) async {
    try {
      final wordText = wordData['word'] as String? ?? '';
      
      // Skip if this contains prompt text
      if (wordText.isEmpty || 
          wordText.toLowerCase().contains('generate') || 
          wordText.toLowerCase().contains('provide') ||
          wordText.length > 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot save invalid word'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Create a VocabularyItemModel directly instead of VocabularyItem
      final model = VocabularyItemModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        word: wordText,
        meaning: wordData['definition'] as String? ?? wordData['meaning'] as String? ?? 'No definition available',
        example: wordData['example'] as String? ?? 'No example available',
        category: _selectedCategory,
        partOfSpeech: wordData['partOfSpeech'] as String? ?? 'noun',
        difficultyLevel: wordData['difficultyLevel'] as int? ?? _selectedDifficulty,
        masteryLevel: 0,
        createdAt: DateTime.now(),
        wordEmoji: wordData['emoji'] as String? ?? '📝',
        synonyms: wordData['synonyms'] is List
            ? List<String>.from(wordData['synonyms'] as List)
            : null,
        antonyms: wordData['antonyms'] is List
            ? List<String>.from(wordData['antonyms'] as List)
            : null,
      );
      
      // Add to vocabulary directly to repository to ensure correct type
      final result = await _vocabularyRepository.addVocabularyItem(model);
      
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving word: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (savedItem) {
          setState(() {
            _savedWords.add(wordText);
            // Add to existing words to prevent saving it again if regenerating
            _existingWords.add(model);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved "$wordText" to vocabulary'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          _trackingService.trackEvent('Save Generated Word', data: {
            'word': wordText,
            'category': _selectedCategory,
          });
        }
      );
    } catch (e) {
      Logger.e('Error saving word: $e', tag: 'AiGenerateWords');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving word: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _saveAllWords() async {
    int savedCount = 0;
    
    try {
      for (final wordData in _generatedWords) {
        final wordText = wordData['word'] as String? ?? '';
        
        // Skip already saved words
        if (_savedWords.contains(wordText)) {
          continue;
        }
        
        // Skip words that look like JSON prompts or are too long
        if (wordText.isEmpty || 
            wordText.toLowerCase().contains('generate') || 
            wordText.toLowerCase().contains('provide') ||
            wordText.length > 30) {
          continue; 
        }
        
        // Create a VocabularyItemModel directly
        final model = VocabularyItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          word: wordText,
          meaning: wordData['definition'] as String? ?? wordData['meaning'] as String? ?? 'No definition available',
          example: wordData['example'] as String? ?? 'No example available',
          category: _selectedCategory,
          partOfSpeech: wordData['partOfSpeech'] as String? ?? 'noun',
          difficultyLevel: wordData['difficultyLevel'] as int? ?? _selectedDifficulty,
          masteryLevel: 0,
          createdAt: DateTime.now(),
          wordEmoji: wordData['emoji'] as String? ?? '📝',
          synonyms: wordData['synonyms'] is List
              ? List<String>.from(wordData['synonyms'] as List)
              : null,
          antonyms: wordData['antonyms'] is List
              ? List<String>.from(wordData['antonyms'] as List)
              : null,
        );
        
        // Add to vocabulary directly through repository
        final result = await _vocabularyRepository.addVocabularyItem(model);
        
        result.fold(
          (failure) {
            Logger.e('Error saving word $wordText: ${failure.message}', tag: 'AiGenerateWords');
          },
          (savedItem) {
            setState(() {
              _savedWords.add(wordText);
              // Add to existing words to prevent saving it again if regenerating
              _existingWords.add(model);
            });
            
            savedCount++;
          }
        );
      }
      
      if (savedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved $savedCount words to vocabulary'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        _trackingService.trackEvent('Save All Generated Words', data: {
          'count': savedCount,
          'category': _selectedCategory,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new words to save'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Logger.e('Error saving all words: $e', tag: 'AiGenerateWords');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving words: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 