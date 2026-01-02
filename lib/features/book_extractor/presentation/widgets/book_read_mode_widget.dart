import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_vocabularies/core/utils/ai_service.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/features/tenses_game/presentation/widgets/tense_evaluation_dialog.dart';
import 'package:visual_vocabularies/features/book_extractor/presentation/widgets/book_paragraph_item.dart';
import 'package:flutter_tts/flutter_tts.dart';

class BookReadModeWidget extends StatefulWidget {
  final List<String> paragraphs;
  final int currentReadIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onExit;
  final VoidCallback onMarkNotUnderstood;
  final VoidCallback onMarkDifficultVocab;
  final VoidCallback onShowMarkedParagraphs;
  final void Function(int) onJumpToParagraph;
  final Set<int> notUnderstoodParagraphs;
  final Set<int> difficultVocabParagraphs;
  final void Function(Map<int, Set<String>>) onUpdateDifficultWords;
  final void Function(Map<int, String>) onUpdateNotes;

  const BookReadModeWidget({
    super.key,
    required this.paragraphs,
    required this.currentReadIndex,
    required this.onPrevious,
    required this.onNext,
    required this.onExit,
    required this.onMarkNotUnderstood,
    required this.onMarkDifficultVocab,
    required this.onShowMarkedParagraphs,
    required this.onJumpToParagraph,
    required this.notUnderstoodParagraphs,
    required this.difficultVocabParagraphs,
    required this.onUpdateDifficultWords,
    required this.onUpdateNotes,
  });

  @override
  State<BookReadModeWidget> createState() => _BookReadModeWidgetState();
}

class _BookReadModeWidgetState extends State<BookReadModeWidget> {
  final TextEditingController _jumpToController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = sl<AiService>();
  bool _isAnalyzingTense = false;
  
  // Text selection variables
  String _selectedText = '';
  final TextEditingController _selectedTextController = TextEditingController();
  bool _isSelectingText = false;
  
  // Track highlighted words for the current paragraph
  final Map<int, Set<String>> _highlightedWords = {};
  final Map<int, Set<String>> _phrasalVerbs = {};

  @override
  void initState() {
    super.initState();
    // Initialize highlighted words for the current paragraph
    _highlightedWords[widget.currentReadIndex] = {};
    _phrasalVerbs[widget.currentReadIndex] = {};
  }

  @override
  void didUpdateWidget(BookReadModeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentReadIndex != widget.currentReadIndex) {
      // Initialize highlighted words for the new paragraph if not already present
      _highlightedWords.putIfAbsent(widget.currentReadIndex, () => {});
      _phrasalVerbs.putIfAbsent(widget.currentReadIndex, () => {});
    }
  }

  @override
  void dispose() {
    _jumpToController.dispose();
    _scrollController.dispose();
    _selectedTextController.dispose();
    super.dispose();
  }

  Future<void> _analyzeTense() async {
    if (widget.currentReadIndex < 0 || widget.currentReadIndex >= widget.paragraphs.length) {
      return;
    }

    // Get the text to analyze - either selected text or the full paragraph
    final textToAnalyze = _selectedText.isNotEmpty 
        ? _selectedText 
        : widget.paragraphs[widget.currentReadIndex];

    if (textToAnalyze.trim().isEmpty) {
      return;
    }

    // Show analyzing indicator
    setState(() {
      _isAnalyzingTense = true;
    });

    try {
      // Get context from surrounding text
      String? contextText;
      if (_selectedText.isEmpty) {
        // If analyzing the whole paragraph, use adjacent paragraphs as context
        if (widget.paragraphs.length > 1) {
          final contextParagraphs = <String>[];
          
          // Add up to 1 previous paragraph
          final prevIndex = widget.currentReadIndex - 1;
          if (prevIndex >= 0 && prevIndex < widget.paragraphs.length) {
            contextParagraphs.add(widget.paragraphs[prevIndex]);
          }
          
          // Add up to 1 next paragraph
          final nextIndex = widget.currentReadIndex + 1;
          if (nextIndex >= 0 && nextIndex < widget.paragraphs.length) {
            contextParagraphs.add(widget.paragraphs[nextIndex]);
          }
          
          if (contextParagraphs.isNotEmpty) {
            contextText = contextParagraphs.join(' ');
          }
        }
      } else {
        // If analyzing selected text, use some surrounding text from the current paragraph
        final currentParagraph = widget.paragraphs[widget.currentReadIndex];
        final position = currentParagraph.indexOf(_selectedText);
        if (position >= 0) {
          // Get some context before and after the selected text
          const contextLength = 100; // Characters of context to include
          final startPos = (position - contextLength) < 0 ? 0 : position - contextLength;
          final endPos = (position + _selectedText.length + contextLength) > currentParagraph.length 
              ? currentParagraph.length 
              : position + _selectedText.length + contextLength;
          
          final beforeContext = position > 0 ? currentParagraph.substring(startPos, position) : '';
          final afterContext = (position + _selectedText.length < currentParagraph.length) 
              ? currentParagraph.substring(position + _selectedText.length, endPos) 
              : '';
          
          contextText = beforeContext + ' ' + afterContext;
        }
      }

      // Call the AI service to analyze the tense usage
      final evaluation = await _aiService.analyzeTextTenseUsage(
        text: textToAnalyze,
        contextText: contextText,
      );

      // Reset selection after analysis
      setState(() {
        _isAnalyzingTense = false;
        _selectedText = '';
        _isSelectingText = false;
      });
      
      // Display the analysis in a dialog
      if (mounted) {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => TenseEvaluationDialog(
            evaluation: evaluation,
            onNext: () => Navigator.of(context).pop(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzingTense = false;
          _selectedText = '';
          _isSelectingText = false;
        });
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing tense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleTextSelection() {
    setState(() {
      _isSelectingText = !_isSelectingText;
      if (!_isSelectingText) {
        _selectedText = '';
      }
    });
  }

  void _showTextSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Text for Analysis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select text containing a verb tense you want to analyze.',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _selectedTextController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter or paste text to analyze...',
              ),
              onChanged: (value) {
                setState(() {
                  _selectedText = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedText = '';
                _selectedTextController.clear();
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (_selectedText.isNotEmpty) {
                _analyzeTense();
              }
            },
            child: const Text('Analyze'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paragraphIndex = widget.currentReadIndex + 1;
    final isCurrentParagraphMarked = widget.notUnderstoodParagraphs.contains(widget.currentReadIndex) ||
                                    widget.difficultVocabParagraphs.contains(widget.currentReadIndex);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                                    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isCurrentParagraphMarked
                        ? (widget.notUnderstoodParagraphs.contains(widget.currentReadIndex)
                            ? (isDarkMode ? Colors.red.withOpacity(0.2) : Colors.red.withOpacity(0.1))
                            : (isDarkMode ? Colors.amber.withOpacity(0.2) : Colors.amber.withOpacity(0.1)))
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isDarkMode ? Border.all(color: Colors.grey[800]!) : null,
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Paragraph $paragraphIndex of ${widget.paragraphs.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                            ),
                          ),
                          if (_isSelectingText)
                            Text(
                              'Select text to analyze',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BookParagraphItem(
                        paragraph: widget.paragraphs[widget.currentReadIndex],
                        index: widget.currentReadIndex,
                        isSelected: false,
                        isNotUnderstood: widget.notUnderstoodParagraphs.contains(widget.currentReadIndex),
                        isDifficult: widget.difficultVocabParagraphs.contains(widget.currentReadIndex),
                        isDarkMode: isDarkMode,
                        fontSize: 18,
                        highlightedWords: {widget.currentReadIndex: _highlightedWords[widget.currentReadIndex]!},
                        phrasalVerbs: {widget.currentReadIndex: _phrasalVerbs[widget.currentReadIndex]!},
                        onUpdateHighlightedWords: (index, words) {
                          setState(() {
                            _highlightedWords[index] = words;
                          });
                          final Map<int, Set<String>> difficultWords = {};
                          difficultWords[index] = words;
                          widget.onUpdateDifficultWords(difficultWords);
                        },
                        onUpdatePhrasalVerbs: (index, phrases) {
                          setState(() {
                            _phrasalVerbs[index] = phrases;
                          });
                        },
                        flutterTts: sl<FlutterTts>(),
                      ),
                      Tooltip(
                        message: 'Tap a word to mark it as difficult. Long-press for more options.',
                        child: Icon(Icons.help_outline, color: Colors.grey),
                      ),
                      if (_selectedText.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode 
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.2) 
                                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Selected Text',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _selectedText = '';
                                        _selectedTextController.clear();
                                      });
                                    },
                                    tooltip: 'Clear selection',
                                    iconSize: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedText,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _isAnalyzingTense ? null : _analyzeTense,
                                icon: _isAnalyzingTense
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.auto_fix_high, size: 16),
                                label: const Text('Analyze Selected Text'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom controls
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width < 500 ? double.infinity : null,
                    child: FilledButton.icon(
                      icon: Icon(_isSelectingText ? Icons.done : Icons.text_format),
                      label: Text(_isSelectingText ? 'Done' : 'Select Text'),
                      onPressed: _toggleTextSelection,
                      style: FilledButton.styleFrom(
                        backgroundColor: _isSelectingText
                          ? (isDarkMode ? Colors.blue[700] : Theme.of(context).colorScheme.primary)
                          : (isDarkMode ? Colors.grey[800] : Theme.of(context).colorScheme.secondary),
                        foregroundColor: isDarkMode ? Colors.white : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width < 500 ? double.infinity : null,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Analyze Full Paragraph'),
                      onPressed: _selectedText.isNotEmpty || _isAnalyzingTense ? null : _analyzeTense,
                      style: FilledButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.blue[800] : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width < 500 ? double.infinity : null,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Enter Text Manually'),
                      onPressed: _showTextSelectionDialog,
                      style: FilledButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.grey[800] : Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onPrevious,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Previous paragraph',
                  ),
                  Expanded(
                    child: Slider(
                      value: widget.currentReadIndex.toDouble(),
                      min: 0,
                      max: (widget.paragraphs.length - 1).toDouble(),
                      divisions: widget.paragraphs.length - 1,
                      label: 'Paragraph ${widget.currentReadIndex + 1}',
                      onChanged: (value) {
                        widget.onJumpToParagraph(value.toInt());
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onNext,
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Next paragraph',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _jumpToController,
                      decoration: InputDecoration(
                        labelText: 'Jump to paragraph',
                        hintText: '1-${widget.paragraphs.length}',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onSubmitted: (value) {
                        final paragraphNumber = int.tryParse(value);
                        if (paragraphNumber != null && paragraphNumber > 0 &&
                            paragraphNumber <= widget.paragraphs.length) {
                          widget.onJumpToParagraph(paragraphNumber - 1);
                          _jumpToController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final paragraphNumber = int.tryParse(_jumpToController.text);
                      if (paragraphNumber != null && paragraphNumber > 0 &&
                          paragraphNumber <= widget.paragraphs.length) {
                        widget.onJumpToParagraph(paragraphNumber - 1);
                        _jumpToController.clear();
                      }
                    },
                    child: const Text('Jump'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: widget.onShowMarkedParagraphs,
                    icon: const Icon(Icons.bookmark),
                    label: const Text('Bookmarks'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
} 