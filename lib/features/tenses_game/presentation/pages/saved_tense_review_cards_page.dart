import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:visual_vocabularies/core/utils/ai/models/tense_evaluation_response.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/widgets/app_navigation_bar.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';

class SavedTenseReviewCardsPage extends StatefulWidget {
  const SavedTenseReviewCardsPage({super.key});

  @override
  State<SavedTenseReviewCardsPage> createState() => _SavedTenseReviewCardsPageState();
}

class _SavedTenseReviewCardsPageState extends State<SavedTenseReviewCardsPage> {
  late final Box<TenseEvaluationResponse> _box;
  late final Box _organizedBox;
  int _currentIndex = 0;
  String? _selectedTense;
  List<TenseEvaluationResponse> _filteredCards = [];

  // List of tenses for filtering
  final List<String> _tenses = [
    'All Tenses',
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
    _box = sl<Box<TenseEvaluationResponse>>();
    _organizedBox = sl<Box>(instanceName: 'organized_tense_review_box');
    _selectedTense = 'All Tenses';
    _loadCards();
  }

  void _loadCards() {
    setState(() {
      if (_selectedTense == 'All Tenses') {
        _filteredCards = _box.values.toList();
      } else {
        // Load cards only from the selected tense
        final tenseKey = _selectedTense!.toLowerCase();
        if (_organizedBox.containsKey(tenseKey)) {
          final tenseCards = List<dynamic>.from(_organizedBox.get(tenseKey));
          _filteredCards = tenseCards
              .map((json) => TenseEvaluationResponse.fromJson(json))
              .toList();
        } else {
          // Fallback to filtering from the standard box
          _filteredCards = _box.values
              .where((card) => card.tense.toLowerCase() == tenseKey)
              .toList();
        }
      }
      _currentIndex = _filteredCards.isEmpty ? 0 : 0;
    });
  }

  void _deleteCard(int index) async {
    final card = _filteredCards[index];
    
    // Delete from standard box if it exists there
    for (final key in _box.keys) {
      final boxCard = _box.get(key);
      if (boxCard?.tense == card.tense && 
          boxCard?.verbForm == card.verbForm &&
          boxCard?.example == card.example) {
        await _box.delete(key);
        break;
      }
    }
    
    // Also delete from organized box
    final tenseKey = card.tense.toLowerCase();
    if (_organizedBox.containsKey(tenseKey)) {
      final cards = List<dynamic>.from(_organizedBox.get(tenseKey));
      // Find and remove the matching card
      cards.removeWhere((json) {
        if (json is Map) {
          return json['verbForm'] == card.verbForm && 
                 json['example'] == card.example;
        }
        return false;
      });
      
      if (cards.isEmpty) {
        await _organizedBox.delete(tenseKey);
      } else {
        await _organizedBox.put(tenseKey, cards);
      }
    }
    
    setState(() {
      _filteredCards.removeAt(index);
      if (_currentIndex >= _filteredCards.length) {
        _currentIndex = _filteredCards.isEmpty ? 0 : _filteredCards.length - 1;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: const AppNavigationBar(title: 'Tense Review Cards'),
      body: Column(
        children: [
          // Tense filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filter by Tense',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.filter_list),
                filled: isDark,
                fillColor: isDark ? Colors.grey.shade900 : null,
              ),
              value: _selectedTense,
              dropdownColor: isDark ? Colors.grey.shade900 : null,
              items: _tenses.map((tense) {
                return DropdownMenuItem(
                  value: tense,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          tense,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (tense != 'All Tenses')
                        Text(
                          AppConstants.grammarTenseEmojis[tense.toLowerCase()] ?? '',
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedTense = newValue;
                  _loadCards();
                });
              },
              isExpanded: true,
            ),
          ),
          
          // Card counter
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _filteredCards.isEmpty
                  ? 'No cards available for this tense'
                  : 'Card ${_currentIndex + 1} of ${_filteredCards.length}',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade200 : null,
              ),
            ),
          ),
          
          // Cards
          _filteredCards.isEmpty
              ? Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No saved review cards yet.',
                            style: TextStyle(
                              fontSize: 18, 
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Save cards from the Tenses Game.',
                            style: TextStyle(
                              fontSize: 14, 
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Expanded(
                  child: PageView.builder(
                    itemCount: _filteredCards.length,
                    controller: PageController(initialPage: _currentIndex),
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder: (context, index) {
                      final card = _filteredCards[index];
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            elevation: isDark ? 8 : 4,
                            color: isDark ? Theme.of(context).cardColor.withOpacity(0.9) : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: isDark 
                                  ? BorderSide(color: Colors.grey.shade800, width: 1) 
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with correct/incorrect, score and delete button
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: _buildCardHeader(context, card, index, isDark),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Section 1: Tense Used
                                  _buildSectionHeader(context, '1. Tense Used', Icons.access_time, isDark),
                                  const SizedBox(height: 8),
                                  _buildContentBox(context, card.tense, isDark),
                                  const SizedBox(height: 16),
                                  
                                  // Section 2: Correct Verb Form
                                  _buildSectionHeader(context, '2. Correct Verb Form', Icons.edit, isDark),
                                  const SizedBox(height: 8),
                                  _buildContentBox(context, '✍️ ${card.verbForm}', isDark),
                                  const SizedBox(height: 16),
                                  
                                  // Section 3: Correction (if available)
                                  if (card.grammaticalCorrection.isNotEmpty) ...[
                                    _buildSectionHeader(context, '3. ✏️ Correction', Icons.auto_fix_high, isDark),
                                    const SizedBox(height: 8),
                                    _buildContentBox(context, card.grammaticalCorrection, isDark),
                                    const SizedBox(height: 16),
                                  ],
                                  
                                  // Section 4: Example
                                  _buildSectionHeader(context, '4. 💡 Example', Icons.lightbulb_outline, isDark),
                                  const SizedBox(height: 8),
                                  _buildContentBox(context, '🗣️ ${card.example}', isDark),
                                  const SizedBox(height: 16),
                                  
                                  // Section 5: Learning Tip
                                  _buildSectionHeader(context, '5. 🎓 Learning Tip', Icons.school, isDark),
                                  const SizedBox(height: 8),
                                  _buildContentBox(context, card.learningAdvice, isDark),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context, TenseEvaluationResponse card, int index, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row with status text and tense emoji
        Row(
          children: [
            Expanded(
              child: Text(
                card.isCorrect ? 'Correct!' : 'Needs Improvement',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: card.isCorrect 
                      ? (isDark ? Colors.green.shade300 : Colors.green) 
                      : (isDark ? Colors.orange.shade300 : Colors.orange),
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              AppConstants.grammarTenseEmojis[card.tense.toLowerCase()] ?? '',
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Row with score and delete button
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: card.isCorrect 
                    ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.withOpacity(0.1))
                    : (isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Score: ${card.score}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: card.isCorrect 
                      ? (isDark ? Colors.green.shade300 : Colors.green) 
                      : (isDark ? Colors.orange.shade300 : Colors.orange),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: isDark ? Colors.red.shade300 : Colors.red,
              ),
              tooltip: 'Delete',
              onPressed: () => _deleteCard(index),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? Theme.of(context).primaryColor.withOpacity(0.2) 
            : Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon, 
            size: 20, 
            color: isDark 
                ? Colors.white.withOpacity(0.9) 
                : Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isDark 
                    ? Colors.white.withOpacity(0.9) 
                    : Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBox(BuildContext context, String content, bool isDark) {
    final backgroundColor = isDark ? Colors.grey.shade900 : Theme.of(context).cardColor;
    final borderColor = isDark ? Colors.grey.shade800 : Theme.of(context).dividerColor;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Text(
        content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.grey.shade300 : null,
          height: 1.4,
        ),
        softWrap: true,
      ),
    );
  }
} 