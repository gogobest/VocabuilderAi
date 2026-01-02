import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:visual_vocabularies/features/vocabulary/presentation/pages/add_edit_word_page.dart';
import 'package:visual_vocabularies/features/vocabulary/data/services/vocabulary_ai_service.dart';
import 'package:visual_vocabularies/features/media/presentation/pages/media_discovery_page.dart';
import 'package:visual_vocabularies/features/media/data/services/media_service.dart';
import 'package:visual_vocabularies/features/media/data/repositories/media_repository_impl.dart';
import 'package:visual_vocabularies/core/utils/ai_service.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/features/media/domain/entities/media_item.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/features/vocabulary/data/models/vocabulary_item_model.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/features/media/data/services/ai_answer_service.dart';
import 'package:visual_vocabularies/features/media/domain/entities/ai_answer.dart';

class HighlightedWordsReviewPage extends StatefulWidget {
  final Map<int, Set<String>> highlightedWords;
  final Map<int, Set<String>> phrasalVerbs;
  final Map<int, String> notes;
  final List<String> subtitleLines;
  final Set<int>? difficultVocabLines;
  final Set<int>? notUnderstoodLines;

  const HighlightedWordsReviewPage({
    super.key,
    required this.highlightedWords,
    required this.phrasalVerbs,
    required this.notes,
    required this.subtitleLines,
    this.difficultVocabLines,
    this.notUnderstoodLines,
  });

  @override
  State<HighlightedWordsReviewPage> createState() => _HighlightedWordsReviewPageState();
}

class _HighlightedWordsReviewPageState extends State<HighlightedWordsReviewPage> {
  final Set<String> _selectedForAI = {};
  final Set<String> _selectedForCards = {};
  final Set<int> difficultVocabLines = {};
  final Set<int> notUnderstoodLines = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    difficultVocabLines.addAll(widget.highlightedWords.keys);
    difficultVocabLines.addAll(widget.phrasalVerbs.keys);
    if (widget.difficultVocabLines != null) {
      difficultVocabLines.addAll(widget.difficultVocabLines!);
    }
    notUnderstoodLines.addAll(widget.notes.keys);
    if (widget.notUnderstoodLines != null) {
      notUnderstoodLines.addAll(widget.notUnderstoodLines!);
    }
  }

  Widget _buildSection(String title, Map<int, Set<String>> data, Color color) {
    final items = <Widget>[];
    data.forEach((idx, words) {
      if (words.isEmpty) return;
      items.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Line ${idx + 1}:', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            Wrap(
              spacing: 8,
              children: words.map((word) => FilterChip(
                label: Text(word),
                selected: _selectedForAI.contains(word) || _selectedForCards.contains(word),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedForAI.add(word);
                    } else {
                      _selectedForAI.remove(word);
                      _selectedForCards.remove(word);
                    }
                  });
                },
                backgroundColor: color.withOpacity(0.15),
                selectedColor: color.withOpacity(0.35),
              )).toList(),
            ),
          ],
        ),
      ));
    });
    if (items.isEmpty) {
      return const Text('None', style: TextStyle(color: Colors.grey));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }

  Widget _buildNotesSection() {
    final items = <Widget>[];
    widget.notes.forEach((idx, note) {
      if (note.isEmpty) return;
      items.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          leading: const Icon(Icons.sticky_note_2, color: Colors.blue),
          title: Text('Line ${idx + 1}: ${widget.subtitleLines[idx]}'),
          subtitle: Text(note),
          trailing: Checkbox(
            value: _selectedForAI.contains(note) || _selectedForCards.contains(note),
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _selectedForAI.add(note);
                } else {
                  _selectedForAI.remove(note);
                  _selectedForCards.remove(note);
                }
              });
            },
          ),
        ),
      ));
    });
    if (items.isEmpty) {
      return const Text('None', style: TextStyle(color: Colors.grey));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }

  Widget _buildCombinedSection() {
    // Add a Select All option at the top
    final allLines = <int>{...difficultVocabLines, ...notUnderstoodLines, ...widget.notes.keys};
    if (allLines.isEmpty) {
      return const Text('None', style: TextStyle(color: Colors.grey));
    }
    
    // Count statistics
    int totalDifficultWords = 0;
    int totalPhrasalVerbs = 0;
    int totalNotes = widget.notes.length;
    
    // Count difficult words
    widget.highlightedWords.forEach((_, words) {
      totalDifficultWords += words.length;
    });
    
    // Count phrasal verbs
    widget.phrasalVerbs.forEach((_, phrases) {
      totalPhrasalVerbs += phrases.length;
    });
    
    final allSelectable = <String>[];
    for (final idx in allLines) {
      final words = widget.highlightedWords[idx] ?? <String>{};
      final phrases = widget.phrasalVerbs[idx] ?? <String>{};
      final note = widget.notes[idx];
      allSelectable.addAll(words);
      allSelectable.addAll(phrases);
      if (note != null && note.isNotEmpty) allSelectable.add(note);
    }
    final allSelected = allSelectable.every(_selectedForAI.contains);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistics Card
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vocabulary Statistics', 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatisticItem(
                  icon: Icons.format_bold,
                  color: isDarkMode ? Colors.amber[400] : Colors.amber,
                  label: 'Difficult Words',
                  value: totalDifficultWords
                ),
                _buildStatisticItem(
                  icon: Icons.link,
                  color: isDarkMode ? Colors.purple[300] : Colors.purple,
                  label: 'Phrases & Phrasal Verbs',
                  value: totalPhrasalVerbs
                ),
                _buildStatisticItem(
                  icon: Icons.note,
                  color: isDarkMode ? Colors.blue[300] : Colors.blue,
                  label: 'Notes & Questions',
                  value: totalNotes
                ),
                const Divider(),
                _buildStatisticItem(
                  icon: Icons.calculate,
                  color: isDarkMode ? Colors.green[300] : Colors.green,
                  label: 'Total Items',
                  value: totalDifficultWords + totalPhrasalVerbs + totalNotes,
                  isBold: true
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Checkbox(
              value: allSelected,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedForAI.addAll(allSelectable);
                  } else {
                    _selectedForAI.removeAll(allSelectable);
                  }
                });
              },
            ),
            const Text('Select All for AI', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        for (final idx in (allLines.toList()..sort()))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Line ${idx + 1}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (difficultVocabLines.contains(idx))
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.amber[800] 
                              : Colors.amber[100],
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          'Difficult Vocabulary', 
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.black 
                                : Colors.amber[800],
                            fontWeight: FontWeight.bold, 
                            fontSize: 12
                          )
                        ),
                      ),
                    if (notUnderstoodLines.contains(idx))
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.red[800] 
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          'Not Understood', 
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : Colors.red[800],
                            fontWeight: FontWeight.bold, 
                            fontSize: 12
                          )
                        ),
                      ),
                  ],
                ),
                if ((widget.highlightedWords[idx] ?? <String>{}).isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: (widget.highlightedWords[idx] ?? <String>{}).map((word) => FilterChip(
                      label: Text(word),
                      selected: _selectedForAI.contains(word),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedForAI.add(word);
                          } else {
                            _selectedForAI.remove(word);
                          }
                        });
                      },
                      backgroundColor: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.amber[800]?.withOpacity(0.5) 
                          : Colors.amber[100],
                      selectedColor: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.amber[600] 
                          : Colors.amber[300],
                      labelStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black
                      ),
                    )).toList(),
                  ),
                if ((widget.phrasalVerbs[idx] ?? <String>{}).isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: (widget.phrasalVerbs[idx] ?? <String>{}).map((phrase) => FilterChip(
                      label: Text(phrase),
                      selected: _selectedForAI.contains(phrase),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedForAI.add(phrase);
                          } else {
                            _selectedForAI.remove(phrase);
                          }
                        });
                      },
                      backgroundColor: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.purple[800]?.withOpacity(0.5) 
                          : Colors.purple[100],
                      selectedColor: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.purple[600] 
                          : Colors.purple[200],
                      labelStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black
                      ),
                    )).toList(),
                  ),
                Text(
                  widget.subtitleLines[idx], 
                  style: TextStyle(
                    fontSize: 13, 
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
                  )
                ),
                if ((widget.notes[idx] ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sticky_note_2, 
                          color: Theme.of(context).colorScheme.primary, 
                          size: 16
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.notes[idx]!,
                            style: TextStyle(
                              fontSize: 13, 
                              color: Theme.of(context).colorScheme.primary
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        Checkbox(
                          value: _selectedForAI.contains(widget.notes[idx]),
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedForAI.add(widget.notes[idx]!);
                              } else {
                                _selectedForAI.remove(widget.notes[idx]!);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatisticItem({required IconData icon, required Color? color, required String label, required int value, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14)),
          const Spacer(),
          Text(
            value.toString(), 
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal
            )
          ),
        ],
      ),
    );
  }

  Future<void> _onGenerateAIWords() async {
    if (_selectedForAI.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No words selected for AI processing.')),
      );
      return;
    }
    
    setState(() { _isLoading = true; });
    try {
      final titleController = TextEditingController(text: 'Show Title');
      final seasonController = TextEditingController(text: '1');
      final episodeController = TextEditingController(text: '1');
      
      // Show simple form dialog to collect media info
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Media Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: seasonController,
                      decoration: const InputDecoration(labelText: 'Season'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: episodeController,
                      decoration: const InputDecoration(labelText: 'Episode'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('GENERATE'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) {
        setState(() { _isLoading = false; });
        return;
      }
      
      final showTitle = titleController.text.trim();
      final season = seasonController.text.trim();
      final episode = episodeController.text.trim();
      
      // Get access to the vocabulary AI service
      final aiService = sl<AiService>();
      
      // Get all words
      final selectedWords = _selectedForAI.toList();
      final vocabResults = <Map<String, dynamic>>[];
      
      // Process each word to get full vocabulary info
      for (final word in selectedWords) {
        try {
          final result = await aiService.generateVocabularyItem(word);
          vocabResults.add(result);
        } catch (e) {
          // Skip words that fail to process
          debugPrint('Failed to process word: $word - $e');
        }
      }
      
      // Now save the results to Hive
      final box = await Hive.openBox<VocabularyItemModel>('vocabulary_items');
      final vocabIds = <String>[];
      
      for (final result in vocabResults) {
        // Skip if we couldn't generate a good word
        final actualWord = result['word'] as String?;
        final definition = result['meaning'] as String?;
        
        if (actualWord == null || actualWord.isEmpty || definition == null || definition.isEmpty) {
          continue;
        }
        
        // Clean up the word for display
        final displayWord = actualWord.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
        
        // Extract example
        String? example;
        if (result['example'] is String) {
          example = result['example'] as String;
        }
        
        // Extract part of speech and note
        String partOfSpeech = 'noun';
        String? partOfSpeechNote;
        
        if (result['partOfSpeech'] is String) {
          partOfSpeech = result['partOfSpeech'] as String;
          
          // Check if we have additional details in the part of speech
          if (partOfSpeech.contains('-')) {
            final parts = partOfSpeech.split(' - ');
            partOfSpeech = parts[0].trim();
            if (parts.length > 1) {
              partOfSpeechNote = parts[1].trim();
            }
          }
        } else {
          // Default fallback based on word characteristics
          if (displayWord.endsWith('ing')) {
            partOfSpeech = 'gerund';
          } else if (displayWord.endsWith('ly')) {
            partOfSpeech = 'adverb';
          } else if (displayWord.endsWith('ed')) {
            partOfSpeech = 'past tense verb';
          } else {
            partOfSpeech = 'noun'; // Default fallback
          }
        }
        
        // Create a real VocabularyItem with clean data
        final vocab = VocabularyItem(
          id: const Uuid().v4(), // Generate a real UUID
          word: actualWord,
          meaning: definition,
          example: example,
          category: result['category'] is String ? result['category'] as String : 'Media',
          difficultyLevel: 3, // Default difficulty
          masteryLevel: 0, // Start with 0 mastery
          sourceMedia: '$showTitle S$season E$episode',
          wordEmoji: result['emoji'] is String ? result['emoji'] as String : null,
          partOfSpeech: partOfSpeech,
          partOfSpeechNote: partOfSpeechNote,
          synonyms: result['synonyms'] is List ? 
              (result['synonyms'] as List).map((e) => e.toString()).toList() : null,
          antonyms: result['antonyms'] is List ? 
              (result['antonyms'] as List).map((e) => e.toString()).toList() : null,
        );
        
        // Convert to model and save to Hive
        final vocabModel = VocabularyItemModel.fromEntity(vocab);
        await box.put(vocabModel.id, vocabModel);
        
        // Store the real ID
        vocabIds.add(vocabModel.id);
      }

      // Create MediaItem with real vocabulary IDs
      final mediaItem = MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: showTitle,
        season: int.tryParse(season),
        episode: int.tryParse(episode),
        vocabularyItemIds: vocabIds,
      );

      // Save the MediaItem using the service locator
      final mediaService = sl<MediaService>();
      await mediaService.addMediaItem(mediaItem);

      setState(() { _isLoading = false; });
      if (!mounted) return;
      
      // Show success dialog informing the user about Media Discovery page
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Words Generated Successfully'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${vocabIds.length} words have been created and saved to your Media Vocabulary.'),
              const SizedBox(height: 16),
              const Text(
                'You can access these words in the Media Discovery page as flashcards.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('STAY HERE'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to Media Discovery page
                Navigator.pop(context);
                context.pushReplacement('/media');
              },
              child: const Text('GO TO MEDIA VOCABULARY'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate AI words: $e')),
      );
    }
  }

  // Generate a contextual explanation based on subtitle content
  String _generateFallbackExplanation(String question, String subtitleLine) {
    question = question.toLowerCase();
    
    if (question.contains("what does") || question.contains("mean") || question.contains("definition")) {
      // For definition questions
      return "This subtitle line describes a scene where \"$subtitleLine\". " +
             "It's showing what the character is seeing or experiencing in this moment.";
    } else if (question.contains("don't understand") || question.contains("confused")) {
      // For comprehension questions
      return "This subtitle \"$subtitleLine\" is describing what's happening in the scene. " +
             "The character is witnessing something significant in the storyline.";
    } else if (subtitleLine.contains("impaled") || subtitleLine.contains("headless") || 
              subtitleLine.contains("horrified") || subtitleLine.contains("corpse")) {
      // For violent/disturbing content
      return "This subtitle is describing a disturbing or violent scene in the movie or show. " +
             "The character is reacting to something shocking they've witnessed.";
    } else {
      // Generic fallback
      return "This subtitle describes what's happening in the scene: \"$subtitleLine\". " + 
             "Without watching the actual video, this appears to be showing the character's actions or reactions.";
    }
  }

  // Generate appropriate emoji based on the context
  String _generateContextEmoji(String subtitleLine, String question) {
    subtitleLine = subtitleLine.toLowerCase();
    question = question.toLowerCase();
    
    if (subtitleLine.contains("horrified") || subtitleLine.contains("scared") || 
        subtitleLine.contains("terrified") || subtitleLine.contains("fear")) {
      return "😱";  // Scared face
    } else if (subtitleLine.contains("impaled") || subtitleLine.contains("blood") || 
              subtitleLine.contains("dead") || subtitleLine.contains("corpse") || 
              subtitleLine.contains("headless")) {
      return "⚠️";  // Warning
    } else if (question.contains("what")) {
      return "🤔";  // Thinking face
    } else if (question.contains("don't understand")) {
      return "❓";  // Question mark
    } else if (question.contains("why")) {
      return "🧐";  // Face with monocle
    } else if (question.contains("how")) {
      return "📝";  // Note
    } else {
      return "💬";  // Speech bubble
    }
  }

  void _onAskAI() async {
    // We'll focus specifically on notes/questions that users have created
    final selectedNotes = <Map<String, dynamic>>[];
    widget.notes.forEach((lineIdx, note) {
      // If the note is selected for AI or the line is selected
      if (_selectedForAI.contains(note) || 
          _selectedForAI.any((word) => widget.subtitleLines[lineIdx].contains(word))) {
        selectedNotes.add({
          'note': note,
          'lineIdx': lineIdx,
          'subtitleLine': widget.subtitleLines[lineIdx]
        });
      }
    });
    
    if (selectedNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notes or questions selected. Please select lines with notes.')),
      );
      return;
    }
    
    setState(() { _isLoading = true; });
    try {
      final aiService = sl<AiService>();
      
      // Process each note/question to get an answer
      final results = <Map<String, dynamic>>[];
      
      for (final noteData in selectedNotes) {
        final note = noteData['note'] as String;
        final lineIdx = noteData['lineIdx'] as int;
        final subtitleLine = noteData['subtitleLine'] as String;
            
        // Get surrounding subtitle lines for better context
        final contextLines = <String>[];
        
        // Add previous line if available
        if (lineIdx > 0) {
          contextLines.add(widget.subtitleLines[lineIdx - 1]);
        }
        
        // Add current line
        contextLines.add(subtitleLine);
        
        // Add next line if available
        if (lineIdx < widget.subtitleLines.length - 1) {
          contextLines.add(widget.subtitleLines[lineIdx + 1]);
        }
        
        final context = contextLines.join(' ');
        
        // Default to fallback answer in case of any issues
        String answer = _generateFallbackExplanation(note, subtitleLine);
        String emoji = _generateContextEmoji(subtitleLine, note);
        
        try {
          final prompt = note.contains('?')
              ? "Answer this question about the subtitle: '$note'. The subtitle line is: '$subtitleLine'. Additional context: '$context'. Include relevant emojis in your answer to make it engaging and memorable. Be concise but informative."
              : "Explain this note about the subtitle: '$note'. The subtitle line is: '$subtitleLine'. Additional context: '$context'. Include relevant emojis in your answer to make it engaging and memorable. Be concise but informative.";
          
          final result = await aiService.generateVocabularyItem(prompt);
          
          // Only use AI result if it's valid and not empty
          if (result != null && 
              result is Map<String, dynamic> && 
              ((result['meaning'] is String && (result['meaning'] as String).isNotEmpty) || 
               (result['definition'] is String && (result['definition'] as String).isNotEmpty))) {
            
            if (result['meaning'] is String && (result['meaning'] as String).isNotEmpty) {
              answer = result['meaning'] as String;
            } else if (result['definition'] is String && (result['definition'] as String).isNotEmpty) {
              answer = result['definition'] as String;
            }
            
            // Get emoji from result if available
            if (result['emoji'] is String && (result['emoji'] as String).isNotEmpty) {
              emoji = result['emoji'] as String;
            }
          } else {
            // If AI returned something but it's not usable, log for debugging
            debugPrint('AI returned empty or invalid result for: $note');
          }
        } catch (aiError) {
          // Silently log error but use our fallback answer
          debugPrint('AI processing error (using fallback): $aiError');
        }
        
        results.add({
          'note': note,
          'answer': answer,
          'subtitleLine': subtitleLine,
          'lineIdx': lineIdx,
          'emoji': emoji,
          'context': context,
        });
      }
      
      // Show answers dialog first
      if (!mounted) return;

      // Show dialog with the results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI Answers'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: results.map((result) {
                final note = result['note'] as String;
                final answer = result['answer'] as String;
                final subtitleLine = result['subtitleLine'] as String;
                final lineIdx = result['lineIdx'] as int;
                final emoji = result['emoji'] as String;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show line number and subtitle text
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Line ${lineIdx + 1}:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                // Display emoji as small indicator
                                Text(emoji, style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(subtitleLine),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Q: $note',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('A: $answer'),
                      const Divider(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSaveAIAnswersDialog(results);
              },
              child: const Text('SAVE ANSWERS'),
            ),
          ],
        ),
      );
      
      setState(() { _isLoading = false; });
      
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process questions: $e')),
      );
    }
  }

  void _showSaveAIAnswersDialog(List<Map<String, dynamic>> results) async {
    // Collect media information
    final titleController = TextEditingController(text: 'Show Title');
    final seasonController = TextEditingController(text: '1');
    final episodeController = TextEditingController(text: '1');
    
    // Show dialog to collect media info
    bool? infoConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Show Title'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: seasonController,
                    decoration: const InputDecoration(labelText: 'Season'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: episodeController,
                    decoration: const InputDecoration(labelText: 'Episode'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (infoConfirmed != true || !mounted) {
      // User canceled providing media info
      return;
    }
    
    setState(() { _isLoading = true; });
    
    try {
      final showTitle = titleController.text.trim();
      final season = int.tryParse(seasonController.text.trim());
      final episode = int.tryParse(episodeController.text.trim());
      
      // Get AIAnswerService from dependency injection
      final aiAnswerService = sl<AIAnswerService>();
      final savedCount = await _saveAIAnswers(
        results, 
        aiAnswerService, 
        showTitle, 
        season, 
        episode
      );
      
      setState(() { _isLoading = false; });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$savedCount answers saved to AI Answers!')),
        );
        
        // Ask if they want to view the AI Answers page
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Answers Saved'),
            content: const Text('Do you want to go to the AI Answers page to view your saved answers?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('NO'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to AI answers page
                  context.push('/ai-answers');
                },
                child: const Text('VIEW ANSWERS'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save answers: $e')),
        );
      }
    }
  }

  Future<int> _saveAIAnswers(
    List<Map<String, dynamic>> results, 
    AIAnswerService aiAnswerService,
    String mediaTitle,
    int? season,
    int? episode
  ) async {
    int savedCount = 0;
    
    for (final result in results) {
      final question = result['note'] as String;
      final answer = result['answer'] as String;
      final subtitleLine = result['subtitleLine'] as String;
      final emoji = result['emoji'] as String;
      final context = result['context'] as String?;
      
      // Create AI answer entity
      final aiAnswer = AIAnswer(
        id: const Uuid().v4(),
        question: question,
        answer: answer,
        subtitleLine: subtitleLine,
        context: context,
        emoji: emoji,
        sourceMediaTitle: mediaTitle,
        sourceMediaSeason: season,
        sourceMediaEpisode: episode,
        createdAt: DateTime.now(),
      );
      
      // Save the answer
      final success = await aiAnswerService.saveAIAnswer(aiAnswer);
      if (success) {
        savedCount++;
      }
    }
    
    return savedCount;
  }

  @override
  Widget build(BuildContext context) {
    final allLines = <int>{...difficultVocabLines, ...notUnderstoodLines};
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Highlights & Questions'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildCombinedSection(),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: isDarkMode ? Colors.black.withOpacity(0.7) : Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Ask AI'),
                      onPressed: _selectedForAI.isEmpty 
                          ? null 
                          : _onAskAI,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('AI words'),
                      onPressed: _selectedForAI.isEmpty 
                          ? null 
                          : _onGenerateAIWords,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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
} 