import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/ai_service.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/features/vocabulary/data/models/vocabulary_item_model.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/features/media/domain/entities/media_item.dart';
import 'package:visual_vocabularies/features/media/data/services/media_service.dart';

class BookWordsReviewPage extends StatefulWidget {
  final Map<int, Set<String>> highlightedWords;
  final Map<int, Set<String>> phrasalVerbs;
  final List<String> paragraphs;
  final String bookTitle;
  final String bookAuthor;

  const BookWordsReviewPage({
    super.key,
    required this.highlightedWords,
    required this.phrasalVerbs,
    required this.paragraphs,
    required this.bookTitle,
    required this.bookAuthor,
  });

  @override
  State<BookWordsReviewPage> createState() => _BookWordsReviewPageState();
}

class _BookWordsReviewPageState extends State<BookWordsReviewPage> {
  final Set<String> _selectedForAI = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-select all words for convenience
    _preSelectAllWords();
  }

  void _preSelectAllWords() {
    for (final entry in widget.highlightedWords.entries) {
      _selectedForAI.addAll(entry.value);
    }
    for (final entry in widget.phrasalVerbs.entries) {
      _selectedForAI.addAll(entry.value);
    }
  }

  Widget _buildStatisticItem({
    required IconData icon,
    required Color? color,
    required String label,
    required int value,
    bool isBold = false
  }) {
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

  Widget _buildCombinedSection() {
    // Count statistics
    int totalWords = 0;
    int totalPhrases = 0;
    
    // Count words and phrases
    widget.highlightedWords.forEach((_, words) {
      totalWords += words.length;
    });
    
    widget.phrasalVerbs.forEach((_, phrases) {
      totalPhrases += phrases.length;
    });
    
    // Prepare all selectable items
    final allSelectable = <String>[];
    for (final entry in widget.highlightedWords.entries) {
      allSelectable.addAll(entry.value);
    }
    for (final entry in widget.phrasalVerbs.entries) {
      allSelectable.addAll(entry.value);
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
                  label: 'Words',
                  value: totalWords
                ),
                _buildStatisticItem(
                  icon: Icons.link,
                  color: isDarkMode ? Colors.purple[300] : Colors.purple,
                  label: 'Phrases',
                  value: totalPhrases
                ),
                const Divider(),
                _buildStatisticItem(
                  icon: Icons.calculate,
                  color: isDarkMode ? Colors.green[300] : Colors.green,
                  label: 'Total Items',
                  value: totalWords + totalPhrases,
                  isBold: true
                ),
              ],
            ),
          ),
        ),
        
        Row(
          children: [
            Checkbox(
              value: allSelected && allSelectable.isNotEmpty,
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
        
        // Words section
        const Text('Words:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        
        for (final entry in widget.highlightedWords.entries)
          if (entry.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paragraph ${entry.key + 1}:', 
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.paragraphs[entry.key],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: entry.value.map((word) => FilterChip(
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
                      backgroundColor: isDarkMode 
                          ? Colors.amber[800]?.withOpacity(0.5) 
                          : Colors.amber[100],
                      selectedColor: isDarkMode 
                          ? Colors.amber[600] 
                          : Colors.amber[300],
                      labelStyle: TextStyle(
                        color: isDarkMode 
                            ? Colors.white 
                            : Colors.black,
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
        
        const SizedBox(height: 16),
        
        // Phrases section
        if (widget.phrasalVerbs.isNotEmpty) ...[
          const Text('Phrases:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          
          for (final entry in widget.phrasalVerbs.entries)
            if (entry.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paragraph ${entry.key + 1}:', 
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.paragraphs[entry.key],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: entry.value.map((phrase) => FilterChip(
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
                        backgroundColor: isDarkMode 
                            ? Colors.purple[800]?.withOpacity(0.5) 
                            : Colors.purple[100],
                        selectedColor: isDarkMode 
                            ? Colors.purple[600] 
                            : Colors.purple[200],
                        labelStyle: TextStyle(
                          color: isDarkMode 
                              ? Colors.white 
                              : Colors.black,
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
        ],
      ],
    );
  }

  void _onGenerateAIWords() async {
    // Get selected words
    final selectedWords = _selectedForAI.toList();
    
    if (selectedWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vocabulary selected. Please select at least one word or phrase.')),
      );
      return;
    }
    
    // Prompt user for book information
    final TextEditingController titleController = TextEditingController(text: widget.bookTitle);
    final TextEditingController authorController = TextEditingController(text: widget.bookAuthor);
    final TextEditingController chapterController = TextEditingController(text: '1');
    
    // Show dialog to get book info
    final bookInfo = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Book Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Book Title',
                hintText: 'Enter the book title',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(
                labelText: 'Author',
                hintText: 'Enter the author name',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: chapterController,
              decoration: const InputDecoration(
                labelText: 'Chapter',
                hintText: 'Chapter number',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('GENERATE'),
            onPressed: () => Navigator.of(context).pop({
              'title': titleController.text.trim(),
              'author': authorController.text.trim(),
              'chapter': chapterController.text.trim(),
            }),
          ),
        ],
      ),
    );
    
    // User canceled
    if (bookInfo == null) return;
    
    setState(() { _isLoading = true; });
    try {
      final aiService = sl<AiService>();
      final vocabIds = <String>[];
      final box = await Hive.openBox<VocabularyItemModel>('vocabulary_items');

      // Use the book info provided by the user
      final bookTitle = bookInfo['title'] ?? 'Unknown Book';
      final bookAuthor = bookInfo['author'] ?? 'Unknown Author';
      final chapter = bookInfo['chapter'] ?? '1';

      for (final word in selectedWords) {
        // Basic normalization
        String displayWord = word.trim();
        
        // Find the context for this word
        String contextParagraph = '';
        for (final entry in {...widget.highlightedWords, ...widget.phrasalVerbs}.entries) {
          if (entry.value.contains(word)) {
            contextParagraph = widget.paragraphs[entry.key];
            break;
          }
        }
        
        // Enhanced prompt for better part of speech detection based on context
        final prompt = """Generate a flashcard for the word/phrase '${displayWord}' as used in this context: '$contextParagraph'. 
Focus on determining the precise part of speech in this specific context.

For the part of speech, analyze the syntax carefully to determine the exact function (noun, verb, adjective, adverb, preposition, pronoun, conjunction, interjection, determiner, etc.).

If it's a phrase, determine if it's a:
- phrasal verb (e.g., 'give up', 'look after')
- idiom (e.g., 'kick the bucket', 'break a leg')
- prepositional phrase (e.g., 'in spite of', 'according to')
- colloquial expression (e.g., 'hang out', 'my bad')
- fixed expression (e.g., 'by the way', 'as a matter of fact')

For verbs, specify the form (infinitive, gerund, past participle), tense (present, past, future), and aspect (simple, continuous, perfect).

Include detailed information: definition, example sentence, precise part of speech, emoji, synonyms, antonyms, and appropriate category.
""";
        
        final result = await aiService.generateVocabularyItem(prompt);
        
        // Extract clean definition
        String definition = 'No definition available';
        if (result['meaning'] is String && (result['meaning'] as String).isNotEmpty) {
          definition = result['meaning'] as String;
        } else if (result['definition'] is String && (result['definition'] as String).isNotEmpty) {
          definition = result['definition'] as String;
        }
        
        // Extract example
        String? example;
        if (result['example'] is String && (result['example'] as String).isNotEmpty) {
          example = result['example'] as String;
        } else if (result['context'] is String && (result['context'] as String).isNotEmpty) {
          example = result['context'] as String;
        } else if (contextParagraph.isNotEmpty) {
          example = contextParagraph;
        }
        
        // Get part of speech information
        String? partOfSpeech;
        String? partOfSpeechNote;
        
        // Check if it's a phrase
        bool isPhrase = false;
        for (final phrases in widget.phrasalVerbs.values) {
          if (phrases.contains(displayWord)) {
            isPhrase = true;
            break;
          }
        }
        
        if (isPhrase) {
          // It's explicitly marked as a phrase
          final words = displayWord.split(' ');
          if (words.length >= 2) {
            if (displayWord.toLowerCase().contains(' up ') || 
                displayWord.toLowerCase().contains(' down ') || 
                displayWord.toLowerCase().contains(' in ') || 
                displayWord.toLowerCase().contains(' out ') || 
                displayWord.toLowerCase().contains(' on ') || 
                displayWord.toLowerCase().contains(' off ') || 
                displayWord.toLowerCase().contains(' away ') || 
                displayWord.toLowerCase().contains(' over ')) {
              partOfSpeech = "phrasal verb";
            } else {
              partOfSpeech = "phrase";
            }
          }
        }
        
        // Use AI's part of speech detection if we couldn't determine it
        if (partOfSpeech == null) {
          if (result['partOfSpeech'] is String && (result['partOfSpeech'] as String).isNotEmpty) {
            partOfSpeech = result['partOfSpeech'] as String;
            
            // Normalize part of speech format
            if (partOfSpeech!.isNotEmpty && partOfSpeech != "I") {
              partOfSpeech = partOfSpeech[0].toLowerCase() + partOfSpeech.substring(1);
            }
            
            // Add additional details to partOfSpeechNote if available
            if (result['partOfSpeechNote'] is String && (result['partOfSpeechNote'] as String).isNotEmpty) {
              partOfSpeechNote = result['partOfSpeechNote'] as String;
            } else if (partOfSpeech.contains(' - ')) {
              // If the part of speech contains details after a dash, split it
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
        }
        
        // Create a VocabularyItem
        final vocab = VocabularyItem(
          id: const Uuid().v4(), // Generate a real UUID
          word: displayWord,
          meaning: definition,
          example: example,
          category: result['category'] is String ? result['category'] as String : 'Book',
          difficultyLevel: 3, // Default difficulty
          masteryLevel: 0, // Start with 0 mastery
          sourceMedia: '$bookTitle by $bookAuthor - Chapter $chapter',
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
        
        // Store the ID
        vocabIds.add(vocabModel.id);
      }

      // Create MediaItem with vocabulary IDs
      final mediaItem = MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: bookTitle,
        author: bookAuthor,
        chapter: int.tryParse(chapter),
        vocabularyItemIds: vocabIds,
      );

      // Save the MediaItem
      final mediaService = sl<MediaService>();
      await mediaService.addMediaItem(mediaItem);

      setState(() { _isLoading = false; });
      if (!mounted) return;
      
      // Show success notification with guidance
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vocabulary cards generated successfully! You can find them in the Media Discover section.'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'GO TO MEDIA',
            onPressed: () {
              context.pushReplacement(AppConstants.mediaRoute);
            },
          ),
        ),
      );
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate AI words: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Book Vocabulary'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vocabulary Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate AI Vocabulary Cards'),
                onPressed: _selectedForAI.isEmpty 
                    ? null 
                    : _onGenerateAIWords,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 