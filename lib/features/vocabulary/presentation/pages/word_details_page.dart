import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/widgets/app_navigation_bar.dart';
import 'package:visual_vocabularies/core/widgets/app_loading_indicator.dart';
import 'package:visual_vocabularies/core/widgets/app_error_widget.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc_exports.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/widgets/loading_overlay.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Page that displays detailed information about a vocabulary item
class WordDetailsPage extends StatefulWidget {
  /// The ID of the vocabulary item to display
  final String id;

  /// Constructor for WordDetailsPage
  const WordDetailsPage({
    super.key,
    required this.id,
  });

  @override
  State<WordDetailsPage> createState() => _WordDetailsPageState();
}

class _WordDetailsPageState extends State<WordDetailsPage> with SingleTickerProviderStateMixin {
  late final VocabularyBloc _vocabularyBloc;
  late TabController _tabController;
  VocabularyItem? _item;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _vocabularyBloc = sl<VocabularyBloc>();
    _tabController = TabController(length: 3, vsync: this);
    _loadVocabularyItem();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadVocabularyItem() {
    _vocabularyBloc.add(LoadVocabularyItemById(widget.id));
  }

  void _incrementMasteryLevel() {
    if (_item == null) return;
    
    // Create a new item with incremented mastery level (capped at 100)
    final updatedItem = _item!.copyWith(
      masteryLevel: (_item!.masteryLevel + 5).clamp(0, 100),
      lastReviewed: DateTime.now(),
    );
    
    _vocabularyBloc.add(UpdateVocabularyItem(updatedItem));
  }

  void _decrementMasteryLevel() {
    if (_item == null) return;
    
    // Create a new item with decremented mastery level (minimum 0)
    final updatedItem = _item!.copyWith(
      masteryLevel: (_item!.masteryLevel - 5).clamp(0, 100),
      lastReviewed: DateTime.now(),
    );
    
    _vocabularyBloc.add(UpdateVocabularyItem(updatedItem));
  }
  
  /// Show information about the recording
  void _showRecordingInfo() {
    if (_item?.recordingPath == null || _item!.recordingPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recording available for this word'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Web platform doesn't have access to the file system in the same way
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recordings not available on web'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final filename = _item!.recordingPath!.split('/').last;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recording available: $filename'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _loadWord() {
    _loadVocabularyItem();
  }

  void _navigateToEdit() {
    if (_item == null) return;
    context.push('/vocabulary/edit/${_item!.id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return BlocProvider(
      create: (context) => _vocabularyBloc,
      child: BlocListener<VocabularyBloc, VocabularyState>(
        listener: (context, state) {
          if (state is VocabularyLoading) {
            setState(() => _isLoading = true);
          } else {
            setState(() => _isLoading = false);
            
            if (state is VocabularyItemLoaded) {
              setState(() => _item = state.item);
            } else if (state is VocabularyError) {
              setState(() => _error = state.message);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is VocabularyOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              _loadVocabularyItem();
            }
          }
        },
        child: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppNavigationBar(
              title: _item?.word ?? 'Loading...',
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _navigateToEdit,
                  tooltip: 'Edit word',
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Details'),
                  Tab(text: 'Study'),
                  Tab(text: 'Progress'),
                ],
              ),
            ),
            body: _isLoading 
              ? const AppLoadingIndicator() 
              : _error != null 
                ? AppErrorWidget(
                    message: _error!, 
                    onRetry: _loadWord,
                  )
                : _item == null 
                  ? const Center(child: Text('Word not found'))
                  : TabBarView(
                      children: [
                        _buildDetailsTab(),
                        _buildStudyTab(),
                        _buildProgressTab(),
                      ],
                    ),
          ),
        ),
      ),
    );
  }

  /// Builds the Details tab content
  Widget _buildDetailsTab() {
    if (_item == null) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word and pronunciation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _item!.word,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Voice recording button (if available)
                        if (_item!.recordingPath != null && _item!.recordingPath!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: _showRecordingInfo,
                            tooltip: 'Play pronunciation',
                          ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_item!.wordEmoji != null && _item!.wordEmoji!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            margin: const EdgeInsets.only(right: 8, top: 4),
                            child: Text(
                              _item!.wordEmoji!,
                              style: const TextStyle(
                                fontSize: 24,
                              ),
                            ),
                          ),
                        if (_item!.grammarTense != null && _item!.grammarTense!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            margin: const EdgeInsets.only(right: 8, top: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _item!.grammarTense!,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        if (_item!.pronunciation != null)
                          Expanded(
                            child: Text(
                              _item!.pronunciation!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.star),
                    const SizedBox(height: 4),
                    Text(
                      '${_item!.difficultyLevel}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Difficulty',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Divider(height: 32),
          
          // Meaning
          Text(
            'Meaning',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _item!.meaning,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          
          // Example (if available)
          if (_item!.example != null) ...[
            const SizedBox(height: 24),
            Text(
              'Example',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.secondary,
                  width: 1,
                ),
              ),
              child: Text(
                _item!.example!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          
          // Synonyms (if available)
          if (_item!.synonyms != null && _item!.synonyms!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Synonyms',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _item!.synonyms!.map((synonym) => 
                Chip(
                  label: Text(
                    synonym,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )
              ).toList(),
            ),
          ],
          
          // Antonyms (if available)
          if (_item!.antonyms != null && _item!.antonyms!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Antonyms',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _item!.antonyms!.map((antonym) => 
                Chip(
                  label: Text(
                    antonym,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )
              ).toList(),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Metadata
          Row(
            children: [
              _buildInfoChip(
                label: _item!.category,
                icon: Icons.category,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                label: _formatDate(_item!.createdAt),
                icon: Icons.calendar_today,
                color: theme.colorScheme.tertiary,
              ),
            ],
          ),
          
          if (_item!.lastReviewed != null) ...[
            const SizedBox(height: 8),
            _buildInfoChip(
              label: 'Last reviewed: ${_formatDate(_item!.lastReviewed!)}',
              icon: Icons.history,
              color: theme.colorScheme.secondary,
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the Study tab content
  Widget _buildStudyTab() {
    if (_item == null) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Flashcard-like widget
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 280),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.8),
                    theme.colorScheme.primary.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _item!.word,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_item!.wordEmoji != null && _item!.wordEmoji!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        _item!.wordEmoji!,
                        style: const TextStyle(
                          fontSize: 36,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Definition:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _item!.meaning,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Rate your knowledge buttons
          Text(
            'How well do you know this word?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _decrementMasteryLevel,
                icon: const Icon(Icons.thumb_down),
                label: const Text('Still Learning'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _incrementMasteryLevel,
                icon: const Icon(Icons.thumb_up),
                label: const Text('Know It'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                  foregroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the Progress tab content
  Widget _buildProgressTab() {
    if (_item == null) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    // Calculate progress color based on mastery level
    Color progressColor;
    if (_item!.masteryLevel < 30) {
      progressColor = Colors.red;
    } else if (_item!.masteryLevel < 70) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }

    // Determine progress status text
    String progressStatus;
    if (_item!.masteryLevel < 30) {
      progressStatus = 'Just started';
    } else if (_item!.masteryLevel < 70) {
      progressStatus = 'Learning';
    } else if (_item!.masteryLevel < 100) {
      progressStatus = 'Almost mastered';
    } else {
      progressStatus = 'Mastered';
    }
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mastery progress circle
          Center(
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          height: 170,
                          width: 170,
                          child: CircularProgressIndicator(
                            value: _item!.masteryLevel / 100,
                            strokeWidth: 12,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_item!.masteryLevel}%',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: progressColor,
                              ),
                            ),
                            Text(
                              'Mastery',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  progressStatus,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Word statistics
          Text(
            'Word Statistics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatisticRow(
            label: 'Category',
            value: _item!.category,
          ),
          if (_item!.grammarTense != null && _item!.grammarTense!.isNotEmpty)
            _buildStatisticRow(
              label: 'Part of Speech',
              value: _item!.grammarTense!,
            ),
          _buildStatisticRow(
            label: 'Difficulty Level',
            value: '${_item!.difficultyLevel}/5',
          ),
          _buildStatisticRow(
            label: 'Added on',
            value: _formatDate(_item!.createdAt),
          ),
          if (_item!.lastReviewed != null)
            _buildStatisticRow(
              label: 'Last Reviewed',
              value: _formatDate(_item!.lastReviewed!),
            ),
            
          const SizedBox(height: 32),
          
          // Suggestions
          if (_item!.masteryLevel < 100)
            const Text(
              'Suggestions to improve your mastery:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          if (_item!.masteryLevel < 100) ...[
            const SizedBox(height: 8),
            _buildSuggestionItem(
              icon: Icons.school,
              text: 'Practice this word in flashcards',
            ),
            _buildSuggestionItem(
              icon: Icons.quiz,
              text: 'Take a quiz including this word',
            ),
            _buildSuggestionItem(
              icon: Icons.edit_note,
              text: 'Write example sentences using this word',
            ),
          ],
        ],
      ),
    );
  }

  /// Builds an information chip with icon and label
  Widget _buildInfoChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a statistic row with label and value
  Widget _buildStatisticRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a suggestion item with icon and text
  Widget _buildSuggestionItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  /// Format date as "Jan 1, 2023" or relative to today
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  /// Build the tense variations section
  Widget _buildTenseVariationsSection() {
    if (_item == null || _item!.tenseVariations == null || _item!.tenseVariations!.isEmpty) {
      return const SizedBox.shrink(); // Don't show if no variations
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tense Variations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTenseVariationsGrid(),
          ],
        ),
      ),
    );
  }
  
  /// Build a grid to display tense variations
  Widget _buildTenseVariationsGrid() {
    if (_item == null || _item!.tenseVariations == null || _item!.tenseVariations!.isEmpty) {
      return const Center(
        child: Text('No tense variations available'),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _item!.tenseVariations!.length,
      itemBuilder: (context, index) {
        final entry = _item!.tenseVariations!.entries.elementAt(index);
        final tenseName = entry.key;
        final wordForm = entry.value;
        
        if (wordForm.isEmpty || wordForm.toLowerCase() == 'n/a') {
          return const SizedBox.shrink(); // Skip N/A entries
        }
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getTenseColor(tenseName).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getTenseColor(tenseName).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tenseName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                wordForm,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _getTenseColor(tenseName),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Get color based on tense name
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