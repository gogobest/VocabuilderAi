import 'package:flutter/material.dart';
import 'highlighted_words_review_page.dart';
import 'package:visual_vocabularies/core/utils/ai_service.dart';
import 'package:visual_vocabularies/core/utils/ai/models/tense_evaluation_response.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/features/tenses_game/presentation/widgets/tense_evaluation_dialog.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ReadModeWidget extends StatefulWidget {
  final List<String> subtitleLines;
  final int currentReadIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onExit;
  final VoidCallback onMarkNotUnderstood;
  final VoidCallback onMarkDifficultVocab;
  final VoidCallback onShowMarkedLines;
  final void Function(int) onJumpToLine;
  final void Function(String) onSearchPhrase;
  final Set<int> notUnderstoodLines;
  final Set<int> difficultVocabLines;
  final void Function(Map<int, Set<String>>) onUpdateDifficultWords;
  final void Function(Map<int, String>) onUpdateNotes;
  final void Function(Map<int, Set<String>>) onUpdatePhrasalVerbs;

  const ReadModeWidget({
    super.key,
    required this.subtitleLines,
    required this.currentReadIndex,
    required this.onPrevious,
    required this.onNext,
    required this.onExit,
    required this.onMarkNotUnderstood,
    required this.onMarkDifficultVocab,
    required this.onShowMarkedLines,
    required this.onJumpToLine,
    required this.onSearchPhrase,
    required this.notUnderstoodLines,
    required this.difficultVocabLines,
    required this.onUpdateDifficultWords,
    required this.onUpdateNotes,
    required this.onUpdatePhrasalVerbs,
  });

  @override
  State<ReadModeWidget> createState() => _ReadModeWidgetState();
}

class _ReadModeWidgetState extends State<ReadModeWidget> {
  final TextEditingController _jumpToController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _searchError;
  final AiService _aiService = sl<AiService>();
  bool _isAnalyzingTense = false;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  // Annotation state
  final Map<int, String> _lineNotes = {};
  final Map<int, Set<String>> _difficultWords = {};
  final Map<int, Set<String>> _phrasalVerbs = {};
  bool _isSelectingPhrase = false;
  int? _phraseStartLineIdx;
  int? _phraseStartWordIdx;
  int? _phraseEndLineIdx;
  int? _phraseEndWordIdx;
  
  // Line selection for phrases
  int _selectionLineIdx = -1; // The line currently being used for selection

  void _showNoteDialog() {
    final idx = widget.currentReadIndex;
    final controller = TextEditingController(text: _lineNotes[idx] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter a note or question...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (controller.text.trim().isEmpty) {
                  _lineNotes.remove(idx);
                } else {
                  _lineNotes[idx] = controller.text.trim();
                }
              });
              // Update parent
              widget.onUpdateNotes(_lineNotes);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _toggleDifficultWord(String word) {
    final idx = widget.currentReadIndex;
    setState(() {
      final set = _difficultWords.putIfAbsent(idx, () => <String>{});
      if (set.contains(word)) {
        set.remove(word);
      } else {
        set.add(word);
      }
    });
    // Update parent
    widget.onUpdateDifficultWords(_difficultWords);
  }

  void _showWordOptions(String word) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final isDifficult = (_difficultWords[widget.currentReadIndex] ?? {}).contains(word);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                word,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  isDifficult ? Icons.check_circle : Icons.circle_outlined,
                  color: isDifficult ? Colors.amber : null,
                ),
                title: Text('Mark as Difficult Word'),
                onTap: () {
                  _toggleDifficultWord(word);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_fix_high),
                title: const Text('Analyze Tense of this Word'),
                onTap: () {
                  Navigator.pop(context);
                  _analyzeTense(specificText: word);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearPhrasalVerb(String phrase, int lineIdx) {
    setState(() {
      final set = _phrasalVerbs[lineIdx];
      if (set != null) {
        set.remove(phrase);
        if (set.isEmpty) {
          _phrasalVerbs.remove(lineIdx);
        }
      }
    });
    // Update parent
    widget.onUpdatePhrasalVerbs(_phrasalVerbs);
  }

  Color? _getLineColor(int idx) {
    final isNotUnderstood = widget.notUnderstoodLines.contains(idx);
    final isDifficult = widget.difficultVocabLines.contains(idx);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (isNotUnderstood && isDifficult) {
      return isDarkMode ? Colors.orange[900] : Colors.orange[100];
    } else if (isNotUnderstood) {
      return isDarkMode ? Colors.red[900] : Colors.red[100];
    } else if (isDifficult) {
      return isDarkMode ? Colors.amber[900] : Colors.yellow[100];
    }
    return null;
  }

  Icon? _getLineIcon(int idx) {
    final isNotUnderstood = widget.notUnderstoodLines.contains(idx);
    final isDifficult = widget.difficultVocabLines.contains(idx);
    if (isNotUnderstood && isDifficult) {
      return const Icon(Icons.warning, color: Colors.orange, size: 18);
    } else if (isNotUnderstood) {
      return const Icon(Icons.error_outline, color: Colors.red, size: 18);
    } else if (isDifficult) {
      return const Icon(Icons.flag, color: Colors.amber, size: 18);
    }
    return null;
  }

  @override
  void dispose() {
    _jumpToController.dispose();
    _searchController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakCurrentLine() async {
    if (_isSpeaking) {
      setState(() {
        _isSpeaking = false;
      });
      await _flutterTts.stop();
      return;
    }
    
    final idx = widget.currentReadIndex;
    if (idx < 0 || idx >= widget.subtitleLines.length) {
      return;
    }

    setState(() {
      _isSpeaking = true;
    });

    try {
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
      
      await _flutterTts.speak(widget.subtitleLines[idx]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing text-to-speech: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleJumpToLine() {
    final input = _jumpToController.text.trim();
    final index = int.tryParse(input);
    if (index != null && index > 0 && index <= widget.subtitleLines.length) {
      widget.onJumpToLine(index - 1);
      setState(() { _searchError = null; });
    } else {
      setState(() { _searchError = 'Invalid line number'; });
    }
  }

  void _handleSearchForPhrase() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    widget.onSearchPhrase(query);
    setState(() { _searchError = null; });
  }

  void _goToFinalReviewPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HighlightedWordsReviewPage(
          highlightedWords: _difficultWords,
          phrasalVerbs: _phrasalVerbs,
          notes: _lineNotes,
          subtitleLines: widget.subtitleLines,
        ),
      ),
    );
  }

  void _startPhrasalVerbSelection() {
    setState(() {
      _isSelectingPhrase = true;
      _phraseStartLineIdx = null;
      _phraseStartWordIdx = null;
      _phraseEndLineIdx = null;
      _phraseEndWordIdx = null;
      _selectionLineIdx = -1;
    });
  }

  void _cancelPhrasalVerbSelection() {
    setState(() {
      _isSelectingPhrase = false;
      _phraseStartLineIdx = null;
      _phraseStartWordIdx = null;
      _phraseEndLineIdx = null;
      _phraseEndWordIdx = null;
      _selectionLineIdx = -1;
    });
  }

  void _selectWordForPhrase(int lineIdx, int wordIdx) {
    setState(() {
      if (_phraseStartLineIdx == null) {
        _phraseStartLineIdx = lineIdx;
        _phraseStartWordIdx = wordIdx;
        _selectionLineIdx = lineIdx;
      } else {
        _phraseEndLineIdx = lineIdx;
        _phraseEndWordIdx = wordIdx;
        
        // Extract the phrase based on line selection
        String phrase;
        if (_phraseStartLineIdx == _phraseEndLineIdx) {
          // Same line selection
          final words = widget.subtitleLines[_phraseStartLineIdx!].split(' ');
          final start = _phraseStartWordIdx! < _phraseEndWordIdx! ? _phraseStartWordIdx! : _phraseEndWordIdx!;
          final end = _phraseStartWordIdx! > _phraseEndWordIdx! ? _phraseStartWordIdx! : _phraseEndWordIdx!;
          phrase = words.sublist(start, end + 1).join(' ');
          
          // Add to the phrasal verbs map
          final set = _phrasalVerbs.putIfAbsent(_phraseStartLineIdx!, () => <String>{});
          set.add(phrase);
        } else {
          // Multi-line selection
          final startLineIdx = _phraseStartLineIdx! < _phraseEndLineIdx! ? _phraseStartLineIdx! : _phraseEndLineIdx!;
          final endLineIdx = _phraseStartLineIdx! > _phraseEndLineIdx! ? _phraseStartLineIdx! : _phraseEndLineIdx!;
          final startWordIdx = startLineIdx == _phraseStartLineIdx! ? _phraseStartWordIdx! : _phraseEndWordIdx!;
          final endWordIdx = endLineIdx == _phraseEndLineIdx! ? _phraseEndWordIdx! : _phraseStartWordIdx!;
          
          // First line (partial)
          final firstLineWords = widget.subtitleLines[startLineIdx].split(' ');
          String firstPart = firstLineWords.sublist(startWordIdx).join(' ');
          
          // Middle lines (if any)
          List<String> middleParts = [];
          for (int i = startLineIdx + 1; i < endLineIdx; i++) {
            middleParts.add(widget.subtitleLines[i]);
          }
          
          // Last line (partial)
          String lastPart = "";
          if (startLineIdx != endLineIdx) {
            final lastLineWords = widget.subtitleLines[endLineIdx].split(' ');
            lastPart = lastLineWords.sublist(0, endWordIdx + 1).join(' ');
          }
          
          // Combine all parts
          phrase = [firstPart, ...middleParts, lastPart].where((s) => s.isNotEmpty).join(' ');
          
          // Add to the phrasal verbs map for the first line
          final set = _phrasalVerbs.putIfAbsent(startLineIdx, () => <String>{});
        set.add(phrase);
        }
        
        // Reset selection state
        _isSelectingPhrase = false;
        _phraseStartLineIdx = null;
        _phraseStartWordIdx = null;
        _phraseEndLineIdx = null;
        _phraseEndWordIdx = null;
        _selectionLineIdx = -1;
        
        // Update parent
        widget.onUpdatePhrasalVerbs(_phrasalVerbs);
      }
    });
  }

  void _showPhrasalVerbOptions(String phrase, int lineIdx) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Phrasal Verb',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                phrase,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove Marked Phrase'),
                onTap: () {
                  Navigator.pop(context);
                  _clearPhrasalVerb(phrase, lineIdx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_fix_high),
                title: const Text('Analyze Tense of this Phrase'),
                onTap: () {
                  Navigator.pop(context);
                  _analyzeTense(specificText: phrase);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLineWithSelectableWords(int lineIdx, bool isMainLine) {
    final words = widget.subtitleLines[lineIdx].split(' ');
    final phrasalVerbs = _phrasalVerbs[lineIdx] ?? <String>{};
    final difficultWords = isMainLine ? (_difficultWords[lineIdx] ?? <String>{}) : <String>{};
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      runSpacing: 2,
      children: List.generate(words.length, (i) {
        final word = words[i];
        final isDifficult = difficultWords.contains(word);
        
        final isInPhrase = _isSelectingPhrase && 
            (_selectionLineIdx == -1 || _selectionLineIdx == lineIdx) && 
            _phraseStartLineIdx != null && 
            ((lineIdx == _phraseStartLineIdx && i >= _phraseStartWordIdx!) || 
            (lineIdx > _phraseStartLineIdx! && _phraseEndLineIdx == null) || 
            (lineIdx == _phraseEndLineIdx && i <= _phraseEndWordIdx!));
        
        // Check if this word is part of any saved phrasal verb
        final matchingPhrases = phrasalVerbs.where((phrase) => 
          phrase.split(' ').contains(word)).toList();
        final isPhrasal = matchingPhrases.isNotEmpty;
        
        return GestureDetector(
          onTap: () {
            if (_isSelectingPhrase) {
              _selectWordForPhrase(lineIdx, i);
            } else if (isMainLine) {
              // Directly toggle the word as difficult
              _toggleDifficultWord(word);
            }
          },
          onLongPress: isMainLine && !_isSelectingPhrase ? () {
            // Show the options menu on long press
            _showWordOptions(word);
          } : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            decoration: isInPhrase
                ? BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.purple[800] 
                        : Colors.purple[200],
                    borderRadius: BorderRadius.circular(3),
                  )
                : isDifficult
                    ? BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.amber[800] 
                            : Colors.amber[200],
                        borderRadius: BorderRadius.circular(3),
                      )
                    : isPhrasal
                        ? BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.purple[700] 
                                : Colors.purple[100],
                            borderRadius: BorderRadius.circular(3),
                          )
                        : null,
            child: Text(
              word,
              style: TextStyle(
                fontSize: isMainLine ? 16 : 13,
                fontWeight: isMainLine ? FontWeight.bold : FontWeight.normal,
                color: isInPhrase
                    ? Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.purple[900]
                    : isDifficult
                        ? Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.brown[900]
                        : isPhrasal
                            ? Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.purple[900]
                            : Theme.of(context).textTheme.bodyLarge?.color,
                decoration: isDifficult || isInPhrase || isPhrasal 
                    ? TextDecoration.underline 
                    : null,
                fontStyle: isMainLine ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _analyzeTense({String? specificText}) async {
    if (widget.currentReadIndex < 0 || widget.currentReadIndex >= widget.subtitleLines.length) {
      return;
    }

    // Check if there are marked words or phrases to analyze
    final currentLineIndex = widget.currentReadIndex;
    final markedWords = _difficultWords[currentLineIndex]?.toList() ?? [];
    final markedPhrases = _phrasalVerbs[currentLineIndex]?.toList() ?? [];
    
    String? textToAnalyze;
    
    // If specificText is provided, use it directly
    if (specificText != null) {
      textToAnalyze = specificText;
    }
    // Otherwise, if there are marked words, analyze the first marked word
    else if (markedWords.isNotEmpty) {
      textToAnalyze = markedWords.first;
    }
    // If there are marked phrases, analyze the first phrase
    else if (markedPhrases.isNotEmpty) {
      textToAnalyze = markedPhrases.first;
    }
    // If nothing is marked, analyze the whole line
    else {
      textToAnalyze = widget.subtitleLines[currentLineIndex];
    }
    
    if (textToAnalyze.trim().isEmpty) {
      return;
    }

    // Show analyzing indicator
    setState(() {
      _isAnalyzingTense = true;
    });

    try {
      // Get context from surrounding lines if available
      String? contextText;
      if (widget.subtitleLines.length > 1) {
        final contextLines = <String>[];
        
        // Add up to 2 previous lines
        for (int i = 1; i <= 2; i++) {
          final prevIndex = widget.currentReadIndex - i;
          if (prevIndex >= 0 && prevIndex < widget.subtitleLines.length) {
            contextLines.add(widget.subtitleLines[prevIndex]);
          }
        }
        
        // Add up to 2 next lines
        for (int i = 1; i <= 2; i++) {
          final nextIndex = widget.currentReadIndex + i;
          if (nextIndex >= 0 && nextIndex < widget.subtitleLines.length) {
            contextLines.add(widget.subtitleLines[nextIndex]);
          }
        }
        
        if (contextLines.isNotEmpty) {
          contextText = contextLines.join(' ');
        }
      }

      // Call the AI service to analyze the tense usage
      final evaluation = await _aiService.analyzeTextTenseUsage(
        text: textToAnalyze,
        contextText: contextText,
      );

      // Display the analysis in a dialog
      if (mounted) {
        setState(() {
          _isAnalyzingTense = false;
        });
        
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

  @override
  Widget build(BuildContext context) {
    final idx = widget.currentReadIndex;
    final lineColor = _getLineColor(idx);
    final lineIcon = _getLineIcon(idx);
    final noteExists = _lineNotes.containsKey(idx) && _lineNotes[idx]!.isNotEmpty;
    final phrasalVerbs = _phrasalVerbs[idx] ?? <String>{};
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Theme.of(context).cardColor.withOpacity(0.8) 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: isDarkMode 
            ? Border.all(color: Theme.of(context).dividerColor) 
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Line ${idx + 1} of ${widget.subtitleLines.length}',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (_isSelectingPhrase) ...[
            Text(
              'Tap words across any visible lines to select a phrase.',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.purpleAccent 
                    : Colors.purple,
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _cancelPhrasalVerbSelection,
              child: const Text('Cancel Phrase Selection'),
            ),
          ] else ...[
            TextButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Select Phrase'),
              onPressed: _startPhrasalVerbSelection,
            ),
          ],
          // Display and allow clearing existing phrases
          if (phrasalVerbs.isNotEmpty && !_isSelectingPhrase) ...[
            const Divider(),
            const Text('Marked Phrases:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: phrasalVerbs.map((phrase) => InkWell(
                onTap: () => _showPhrasalVerbOptions(phrase, idx),
                child: Chip(
                  label: Text(phrase),
                  backgroundColor: isDarkMode ? Colors.purple[700] : Colors.purple[100],
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.purple[900],
                    fontSize: 12,
                  ),
                ),
              )).toList(),
            ),
            const Divider(),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _jumpToController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jump to line',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _handleJumpToLine(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search phrase',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _handleSearchForPhrase(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search',
                onPressed: _handleSearchForPhrase,
              ),
            ],
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 4),
            Text(_searchError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          if (idx > 0) ...[
            // Previous line with selectable words for phrases
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: _isSelectingPhrase ? 
                    (isDarkMode ? Colors.grey[800]?.withOpacity(0.4) : Colors.grey[200]) : 
                    (isDarkMode ? Colors.grey[850] : Colors.grey[100]),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: _buildLineWithSelectableWords(idx - 1, false),
            ),
          ],
          const SizedBox(height: 14),
          // Main content container with the subtitle line
          Container(
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? lineColor ?? Theme.of(context).cardColor
                  : lineColor ?? Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (lineIcon != null) ...[
                  lineIcon,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: _buildLineWithSelectableWords(idx, true),
                ),
                IconButton(
                  icon: Icon(
                    noteExists ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined, 
                    color: noteExists 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  tooltip: noteExists ? 'Edit Note' : 'Add Note',
                  onPressed: _showNoteDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a word to mark as difficult • Long-press for more options',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          if (idx < widget.subtitleLines.length - 1) ...[
            // Next line with selectable words for phrases
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: _isSelectingPhrase ? 
                    (isDarkMode ? Colors.grey[800]?.withOpacity(0.4) : Colors.grey[200]) : 
                    (isDarkMode ? Colors.grey[850] : Colors.grey[100]),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: _buildLineWithSelectableWords(idx + 1, false),
            ),
          ],
          const SizedBox(height: 16),
          if (_lineNotes[idx]?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sticky_note_2, 
                    color: Theme.of(context).colorScheme.primary, 
                    size: 16
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _lineNotes[idx]!,
                      style: TextStyle(
                        fontSize: 13, 
                        color: Theme.of(context).colorScheme.primary
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Navigation group
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: widget.onPrevious,
                    tooltip: 'Previous',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
                    onPressed: widget.onNext,
                    tooltip: 'Next',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: _isAnalyzingTense 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_fix_high, color: Colors.white),
                onPressed: _isAnalyzingTense ? null : () => _analyzeTense(),
                tooltip: 'Analyze Tense',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: Icon(
                  _isSpeaking ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: _speakCurrentLine,
                tooltip: _isSpeaking ? 'Stop' : 'Listen',
                style: IconButton.styleFrom(
                  backgroundColor: _isSpeaking 
                    ? Colors.red.shade400 
                    : Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 