import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class BookParagraphItem extends StatefulWidget {
  final String paragraph;
  final int index;
  final bool isSelected;
  final bool isNotUnderstood;
  final bool isDifficult;
  final bool isDarkMode;
  final double fontSize;
  final Map<int, Set<String>> highlightedWords;
  final Map<int, Set<String>> phrasalVerbs;
  final Function(int, Set<String>) onUpdateHighlightedWords;
  final Function(int, Set<String>) onUpdatePhrasalVerbs;
  final FlutterTts flutterTts;

  const BookParagraphItem({
    super.key,
    required this.paragraph,
    required this.index,
    required this.isSelected,
    required this.isNotUnderstood,
    required this.isDifficult,
    required this.isDarkMode,
    required this.fontSize,
    required this.highlightedWords,
    required this.phrasalVerbs,
    required this.onUpdateHighlightedWords,
    required this.onUpdatePhrasalVerbs,
    required this.flutterTts,
  });

  @override
  State<BookParagraphItem> createState() => _BookParagraphItemState();
}

class _BookParagraphItemState extends State<BookParagraphItem> {
  final Set<String> _markedWords = {};
  List<String> _wordTokens = [];
  int? _phraseStartIndex;
  int? _phraseEndIndex;
  List<int> _selectedWordIndices = [];

  @override
  void initState() {
    super.initState();
    // Initialize the marked words from the passed-in highlightedWords
    if (widget.highlightedWords.containsKey(widget.index)) {
      _markedWords.addAll(widget.highlightedWords[widget.index]!);
    }
    // Initialize the word tokens
    _tokenizeParagraph();
  }

  @override
  void didUpdateWidget(BookParagraphItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paragraph != widget.paragraph) {
      _tokenizeParagraph();
    }
    // Update marked words if the highlightedWords changed
    if (oldWidget.highlightedWords != widget.highlightedWords) {
      _markedWords.clear();
      if (widget.highlightedWords.containsKey(widget.index)) {
        _markedWords.addAll(widget.highlightedWords[widget.index]!);
      }
    }
  }

  void _tokenizeParagraph() {
    // Split the paragraph into tokens (words and punctuation)
    final RegExp tokenRegex = RegExp("[a-zA-Z0-9][\\w'-]*|[^\\w\\s]|[\\s]+");
    
    _wordTokens = tokenRegex
        .allMatches(widget.paragraph)
        .map((match) => match.group(0)!)
        .where((token) => token.trim().isNotEmpty)
        .toList();
  }

  void _handleWordTap(int index) {
    // If we're selecting a phrase, process that
    if (_phraseStartIndex != null) {
      _phraseEndIndex = index;
      _updateSelectedWordIndices();
      return;
    }

    // Standard word selection (toggle)
    final word = _wordTokens[index].trim();
    // If the word is empty or just whitespace, ignore
    if (word.isEmpty || RegExp(r'^\s+$').hasMatch(word)) return;
    // If it's punctuation, ignore
    if (RegExp(r'^[^\w\s]$').hasMatch(word)) return;

    setState(() {
      if (_markedWords.contains(word)) {
        _markedWords.remove(word);
      } else {
        _markedWords.add(word);
      }
    });

    final updatedMarkedWords = Set<String>.from(_markedWords);
    widget.onUpdateHighlightedWords(widget.index, updatedMarkedWords);
  }

  void _handleWordLongPress(int index) {
    // Start selecting a phrase
    setState(() {
      _phraseStartIndex = index;
      _phraseEndIndex = index;
      _updateSelectedWordIndices();
    });
  }

  void _updateSelectedWordIndices() {
    if (_phraseStartIndex == null || _phraseEndIndex == null) {
      setState(() {
        _selectedWordIndices = [];
      });
      return;
    }

    // Determine the correct start and end indices (handle selecting backwards)
    final startIdx = _phraseStartIndex! < _phraseEndIndex! 
      ? _phraseStartIndex! 
      : _phraseEndIndex!;
    final endIdx = _phraseStartIndex! < _phraseEndIndex! 
      ? _phraseEndIndex! 
      : _phraseStartIndex!;

    setState(() {
      _selectedWordIndices = List.generate(
        endIdx - startIdx + 1, 
        (i) => startIdx + i
      );
    });
  }

  void _confirmPhraseSelection() {
    if (_selectedWordIndices.isEmpty) {
      _cancelPhraseSelection();
      return;
    }

    // Extract the phrase from selected indices
    final List<String> phraseWords = [];
    for (final idx in _selectedWordIndices) {
      if (idx >= 0 && idx < _wordTokens.length) {
        final word = _wordTokens[idx].trim();
        if (word.isNotEmpty && !RegExp(r'^[^\w\s]$').hasMatch(word)) {
          phraseWords.add(word);
        }
      }
    }

    if (phraseWords.isEmpty) {
      _cancelPhraseSelection();
      return;
    }

    // Join the words to form a phrase
    final phrase = phraseWords.join(' ');

    // Update both phrasal verbs and highlighted words
    final updatedPhrasalVerbs = Set<String>.from(
      widget.phrasalVerbs[widget.index] ?? <String>{});
    
    if (updatedPhrasalVerbs.contains(phrase)) {
      updatedPhrasalVerbs.remove(phrase);
    } else {
      updatedPhrasalVerbs.add(phrase);
      // Also add the phrase to highlighted words for review
      _markedWords.add(phrase);
    }
    
    widget.onUpdatePhrasalVerbs(widget.index, updatedPhrasalVerbs);
    widget.onUpdateHighlightedWords(widget.index, Set<String>.from(_markedWords));
    
    // Reset the phrase selection state
    _cancelPhraseSelection();
  }

  void _cancelPhraseSelection() {
    setState(() {
      _phraseStartIndex = null;
      _phraseEndIndex = null;
      _selectedWordIndices = [];
    });
  }

  bool _isWordInPhrases(String word, int index) {
    if (!widget.phrasalVerbs.containsKey(widget.index)) return false;
    
    // Check if the word at this index is part of any phrase
    for (final phrase in widget.phrasalVerbs[widget.index]!) {
      final phraseWords = phrase.split(' ');
      
      // Look back to see if this word is at the end of a phrase
      for (int i = 1; i <= phraseWords.length; i++) {
        // Check if we have enough words before this index
        if (index - i + 1 < 0) continue;
        
        // Build a potential phrase from the words leading up to this one
        final List<String> potentialPhraseWords = [];
        for (int j = 0; j < i; j++) {
          final wordIndex = index - i + 1 + j;
          if (wordIndex >= 0 && wordIndex < _wordTokens.length) {
            final w = _wordTokens[wordIndex].trim();
            if (w.isNotEmpty && !RegExp(r'^[^\w\s]$').hasMatch(w)) {
              potentialPhraseWords.add(w);
            }
          }
        }
        
        final potentialPhrase = potentialPhraseWords.join(' ');
        if (potentialPhrase == phrase) return true;
      }
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Determine background color based on selection and understanding status
    Color? backgroundColor;
    if (widget.isSelected) {
      backgroundColor = widget.isDarkMode ? Colors.blue[900] : Colors.blue[100];
    } else if (widget.isNotUnderstood) {
      backgroundColor = widget.isDarkMode ? Colors.red[900] : Colors.red[100];
    } else if (widget.isDifficult) {
      backgroundColor = widget.isDarkMode ? Colors.orange[900] : Colors.orange[100];
    }

    // Check if we're in phrase selection mode
    final isSelectingPhrase = _phraseStartIndex != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Colors.blueGrey[700] : Colors.blueGrey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.volume_up, size: 18),
                onPressed: () async {
                  await widget.flutterTts.speak(widget.paragraph);
                },
                tooltip: 'Read Aloud',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 2,
            children: List.generate(_wordTokens.length, (index) {
              final token = _wordTokens[index];
              final isMarked = widget.highlightedWords[widget.index]?.contains(token.trim()) ?? false;
              final isPartOfPhrase = _isWordInPhrases(token, index);
              final isCurrentlySelected = _selectedWordIndices.contains(index);
              
              // Skip rendering for whitespace
              if (token.trim().isEmpty) {
                return const SizedBox(width: 4);
              }
              
              // Only put space between words, not punctuation
              final shouldAddSpace = !RegExp(r'^[^\w\s]$').hasMatch(token) && 
                (index > 0 && !RegExp(r'^[^\w\s]$').hasMatch(_wordTokens[index - 1]));
              
              return GestureDetector(
                onTap: () => isSelectingPhrase 
                  ? setState(() {
                      _phraseEndIndex = index;
                      _updateSelectedWordIndices();
                    })
                  : _handleWordTap(index),
                onLongPress: () => _handleWordLongPress(index),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: shouldAddSpace ? 4.0 : 0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    decoration: isPartOfPhrase
                        ? BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.purple[800] 
                                : Colors.purple[200],
                            borderRadius: BorderRadius.circular(3),
                          )
                        : isMarked
                            ? BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.amber[800] 
                                    : Colors.amber[200],
                                borderRadius: BorderRadius.circular(3),
                              )
                            : null,
                    child: Text(
                      token,
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight: isPartOfPhrase || isMarked ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentlySelected 
                          ? (widget.isDarkMode ? Colors.yellow : Colors.blue[800])
                          : isMarked 
                            ? (widget.isDarkMode ? Colors.white : Colors.brown[900])
                            : isPartOfPhrase
                              ? Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.purple[900]
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        decoration: isPartOfPhrase || isMarked 
                            ? TextDecoration.underline 
                            : null,
                        fontStyle: isPartOfPhrase ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          
          // Show confirmation buttons when selecting a phrase
          if (isSelectingPhrase) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Cancel'),
                  onPressed: _cancelPhraseSelection,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Mark Phrase'),
                  onPressed: _confirmPhraseSelection,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
} 