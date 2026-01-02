import 'package:flutter/material.dart';
import 'read_mode_widget.dart';
import 'highlighted_words_review_page.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class ReadModePage extends StatefulWidget {
  final List<String> subtitleLines;
  final String title;

  // Constructor for when the subtitleLines are passed directly
  const ReadModePage({super.key, required this.subtitleLines, this.title = 'Read Mode'});

  // Constructor for when the subtitleContent is passed as a single string
  ReadModePage.fromContent({
    super.key, 
    required String subtitleContent,
    this.title = 'Read Mode',
  }) : subtitleLines = subtitleContent
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
            
  // Generate a unique ID for this subtitle based on content hash
  String get subtitleId {
    final contentHash = md5.convert(utf8.encode(subtitleLines.join('\n'))).toString();
    return '${title.replaceAll(' ', '_')}_$contentHash';
  }

  @override
  State<ReadModePage> createState() => _ReadModePageState();
}

class _ReadModePageState extends State<ReadModePage> {
  int _currentReadIndex = 0;
  final Set<int> _notUnderstoodLines = {};
  final Set<int> _difficultVocabLines = {};
  final Map<int, String> _lineNotes = {};
  final Map<int, Set<String>> _difficultWords = {};
  final Map<int, Set<String>> _phrasalVerbs = {};
  
  @override
  void initState() {
    super.initState();
    _loadReadingProgress();
  }

  void _onPrevious() {
    if (_currentReadIndex > 0) {
      setState(() {
        _currentReadIndex--;
      });
      _saveReadingProgress();
    }
  }

  void _onNext() {
    if (_currentReadIndex < widget.subtitleLines.length - 1) {
      setState(() {
        _currentReadIndex++;
      });
      _saveReadingProgress();
    }
  }

  void _onMarkNotUnderstood() {
    setState(() {
      _notUnderstoodLines.add(_currentReadIndex);
    });
  }

  void _onMarkDifficultVocab() {
    setState(() {
      _difficultVocabLines.add(_currentReadIndex);
    });
  }

  void _onShowMarkedLines() {
    final markedLines = <String>[];
    for (final idx in {..._notUnderstoodLines, ..._difficultVocabLines}) {
      if (idx >= 0 && idx < widget.subtitleLines.length) {
        markedLines.add(widget.subtitleLines[idx]);
      }
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marked Lines'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: markedLines.map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(line),
              )).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onJumpToLine(int index) {
    setState(() {
      _currentReadIndex = index;
    });
  }

  void _onSearchPhrase(String query) {
    final foundIndex = widget.subtitleLines.indexWhere((line) => line.toLowerCase().contains(query.toLowerCase()));
    if (foundIndex != -1) {
      setState(() {
        _currentReadIndex = foundIndex;
      });
    }
  }

  // Update notes and words from the ReadModeWidget
  void _onUpdateDifficultWords(Map<int, Set<String>> words) {
    setState(() {
      _difficultWords.addAll(words);
    });
  }

  void _onUpdateNotes(Map<int, String> notes) {
    setState(() {
      _lineNotes.addAll(notes);
    });
  }

  void _onUpdatePhrasalVerbs(Map<int, Set<String>> verbs) {
    setState(() {
      _phrasalVerbs.addAll(verbs);
    });
  }

  void _onFinish() {
    // Save reading progress before finishing
    _saveReadingProgress();
    
    // Count total number of selected items
    int totalDifficultWords = 0;
    int totalPhrasalVerbs = 0;
    int totalNotes = _lineNotes.length;
    
    // Count difficult words
    _difficultWords.forEach((_, words) {
      totalDifficultWords += words.length;
    });
    
    // Count phrasal verbs
    _phrasalVerbs.forEach((_, phrases) {
      totalPhrasalVerbs += phrases.length;
    });
    
    // Show summary dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reading Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have marked:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.format_bold, color: Theme.of(context).colorScheme.primary),
              title: Text('$totalDifficultWords difficult words'),
              dense: true,
            ),
            ListTile(
              leading: Icon(Icons.link, color: Theme.of(context).colorScheme.secondary),
              title: Text('$totalPhrasalVerbs phrases/phrasal verbs'),
              dense: true,
            ),
            ListTile(
              leading: Icon(Icons.note, color: Theme.of(context).colorScheme.tertiary),
              title: Text('$totalNotes notes/questions'),
              dense: true,
            ),
            const SizedBox(height: 8),
            Text('Total: ${totalDifficultWords + totalPhrasalVerbs + totalNotes} items', 
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Continue Reading'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to review page with the collected data
              context.push(
                AppConstants.subtitleReviewRoute,
                extra: {
                  'highlightedWords': _difficultWords,
                  'phrasalVerbs': _phrasalVerbs,
                  'notes': _lineNotes,
                  'subtitleLines': widget.subtitleLines,
                  'difficultVocabLines': _difficultVocabLines,
                  'notUnderstoodLines': _notUnderstoodLines,
                },
              );
            },
            child: const Text('Review All Items'),
          ),
        ],
      ),
    );
  }

  // Save reading progress to SharedPreferences
  Future<void> _saveReadingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressData = {
        'currentIndex': _currentReadIndex,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'totalLines': widget.subtitleLines.length,
      };
      
      await prefs.setString('subtitle_progress_${widget.subtitleId}', jsonEncode(progressData));
      print('✅ Subtitle reading progress saved');
    } catch (e) {
      print('❌ Error saving subtitle reading progress: $e');
    }
  }
  
  // Load reading progress from SharedPreferences
  Future<void> _loadReadingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedProgress = prefs.getString('subtitle_progress_${widget.subtitleId}');
      
      if (savedProgress != null) {
        final progressData = jsonDecode(savedProgress) as Map<String, dynamic>;
        final savedTime = DateTime.fromMillisecondsSinceEpoch(progressData['timestamp'] as int);
        final now = DateTime.now();
        final daysSinceLastRead = now.difference(savedTime).inDays;
        
        // Only restore position if subtitle was read in the last 30 days
        if (daysSinceLastRead <= 30) {
          if (mounted) {
            setState(() {
              _currentReadIndex = progressData['currentIndex'] as int;
              
              // Ensure index is valid
              if (_currentReadIndex >= widget.subtitleLines.length) {
                _currentReadIndex = widget.subtitleLines.length - 1;
              }
              
              print('✅ Subtitle reading progress restored to line ${_currentReadIndex + 1}');
            });
            
            // Show confirmation to user
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reading progress restored to line ${_currentReadIndex + 1}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error loading subtitle reading progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      ReadModeWidget(
                        subtitleLines: widget.subtitleLines,
                        currentReadIndex: _currentReadIndex,
                        onPrevious: _onPrevious,
                        onNext: _onNext,
                        onExit: () => Navigator.pop(context),
                        onMarkNotUnderstood: _onMarkNotUnderstood,
                        onMarkDifficultVocab: _onMarkDifficultVocab,
                        onShowMarkedLines: _onShowMarkedLines,
                        onJumpToLine: _onJumpToLine,
                        onSearchPhrase: _onSearchPhrase,
                        notUnderstoodLines: _notUnderstoodLines,
                        difficultVocabLines: _difficultVocabLines,
                        onUpdateDifficultWords: _onUpdateDifficultWords,
                        onUpdateNotes: _onUpdateNotes,
                        onUpdatePhrasalVerbs: _onUpdatePhrasalVerbs,
                      ),
                      const SizedBox(height: 16),
                      // Add a "Finish Reading" button at the bottom
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton.icon(
                          onPressed: _onFinish,
                          icon: const Icon(Icons.done_all),
                          label: const Text('Finish Reading'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 