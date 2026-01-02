import 'package:flutter/material.dart';
import 'package:visual_vocabularies/core/utils/ai/models/tense_evaluation_response.dart';
import 'package:hive/hive.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';

class TenseEvaluationDialog extends StatelessWidget {
  final TenseEvaluationResponse evaluation;
  final VoidCallback onNext;

  const TenseEvaluationDialog({
    super.key,
    required this.evaluation,
    required this.onNext,
  });

  Future<void> _saveCard(BuildContext context) async {
    // First save to regular box
    final standardBox = sl<Box<TenseEvaluationResponse>>();
    await standardBox.add(evaluation);
    
    // Then save to organized box with tense grouping
    try {
      final organizedBox = sl<Box>(instanceName: 'organized_tense_review_box');
      final tense = evaluation.tense.toLowerCase();
      
      // For organized storage, convert to JSON for proper Hive storage
      final cardJson = evaluation.toJson();
      
      // Get existing cards for this tense
      List<dynamic> existingCards = [];
      if (organizedBox.containsKey(tense)) {
        existingCards = List<dynamic>.from(organizedBox.get(tense));
      }
      
      // Add new card and save
      existingCards.add(cardJson);
      await organizedBox.put(tense, existingCards);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Tense Review Cards!')),
      );
    } catch (e) {
      print('Error saving organized card: $e');
      // At least the standard box save worked
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Tense Review Cards!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final borderColor = isDark ? Theme.of(context).dividerColor.withOpacity(0.3) : Colors.grey.shade300;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: backgroundColor,
      elevation: isDark ? 8 : 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with score
              Row(
                children: [
                  Expanded(
                    child: Text(
                      evaluation.isCorrect ? 'Correct!' : 'Needs Improvement',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: evaluation.isCorrect ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: evaluation.isCorrect 
                          ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.withOpacity(0.1))
                          : (isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Score: ${evaluation.score}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: evaluation.isCorrect ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Tense Used
                      _buildSectionHeader(context, '1. Tense Used', Icons.access_time, isDark),
                      const SizedBox(height: 8),
                      _buildContentBox(
                        context, 
                        '${evaluation.tense}  ${(AppConstants.grammarTenseEmojis[evaluation.tense.toLowerCase()] ?? '')}',
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      
                      // Section 2: Correct Verb Form
                      _buildSectionHeader(context, '2. Correct Verb Form', Icons.edit, isDark),
                      const SizedBox(height: 8),
                      _buildContentBox(
                        context, 
                        '✍️ ${evaluation.verbForm}', 
                        isDark,
                      ),
                      const SizedBox(height: 16),

                      // Section 3: Grammatical Correction with emoji (if available)
                      if (evaluation.grammaticalCorrection.isNotEmpty) ...[
                        _buildSectionHeader(context, '3. ✏️ Correction', Icons.auto_fix_high, isDark),
                        const SizedBox(height: 8),
                        _buildContentBox(
                          context, 
                          evaluation.grammaticalCorrection, 
                          isDark,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Section 4: Example with emoji
                      _buildSectionHeader(context, '4. 💡 Example', Icons.lightbulb_outline, isDark),
                      const SizedBox(height: 8),
                      _buildContentBox(
                        context, 
                        '🗣️ ${evaluation.example}', 
                        isDark,
                      ),
                      const SizedBox(height: 16),

                      // Section 5: Learning Advice with emoji
                      _buildSectionHeader(context, '5. 🎓 Learning Tip', Icons.school, isDark),
                      const SizedBox(height: 8),
                      _buildContentBox(
                        context, 
                        evaluation.learningAdvice, 
                        isDark,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              
              // Save and Next Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _saveCard(context),
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: isDark ? Theme.of(context).primaryColor.withOpacity(0.8) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: isDark ? Colors.blueGrey.shade700 : null,
                      ),
                      child: const Text('Next Question'),
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
          height: 1.4,
          color: isDark ? Colors.grey.shade300 : null,
        ),
        softWrap: true,
      ),
    );
  }
} 