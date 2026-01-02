import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'dart:typed_data';
import 'package:visual_vocabularies/features/book_extractor/presentation/widgets/book_paragraph_item.dart';
import 'package:visual_vocabularies/core/utils/text_utils.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:visual_vocabularies/features/book_extractor/presentation/widgets/book_words_review_page.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:visual_vocabularies/features/book_extractor/presentation/widgets/book_read_mode_widget.dart';

/// A vocabulary item class for book reading
class BookVocabularyItem {
  final String id;
  final String text;
  final String definition;
  final String source;
  final DateTime timestamp;
  final String context;
  final String type;

  BookVocabularyItem({
    required this.id,
    required this.text,
    required this.definition,
    required this.source,
    required this.timestamp,
    required this.context,
    required this.type,
  });
}

class BookReadModePage extends StatefulWidget {
  final Uint8List bookBytes;
  final String title;
  final String author;
  
  // Add a unique identifier for the book - helpful for saving progress
  String get bookId => '${title}_${author}'.replaceAll(' ', '_');

  const BookReadModePage({
    super.key,
    required this.bookBytes,
    required this.title,
    required this.author,
  });

  @override
  State<BookReadModePage> createState() => _BookReadModePageState();
}

class _BookReadModePageState extends State<BookReadModePage> {
  bool _isLoading = true;
  List<String> _paragraphs = [];
  int _currentParagraphIndex = 0;
  bool _isDarkMode = false;
  double _fontSize = 18.0;
  
  // Track paragraph state
  Set<int> _selectedParagraphs = {};
  Set<int> _notUnderstoodParagraphs = {};
  Set<int> _difficultParagraphs = {};
  
  // Track marked words
  Map<int, Set<String>> _highlightedWords = {};
  Map<int, Set<String>> _phrasalVerbs = {};
  
  // Tracking reading progress
  int _lastReadIndex = 0;
  
  // Text-to-speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  // Store chapter information
  List<Map<String, dynamic>> _chapters = [];
  int _currentChapterIndex = 0;

  // Store chapter content separately
  Map<int, List<String>> _chapterParagraphs = {};
  
  // Add hierarchical chapter structure
  List<Map<String, dynamic>> _detailedChapters = [];

  @override
  void initState() {
    super.initState();
    _extractParagraphs();
    _initTts();
    _loadReadingProgress(); // Add this line to load saved progress
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }
  
  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
      return;
    }
    
    setState(() {
      _isSpeaking = true;
    });
    
    await _flutterTts.speak(text);
  }

  void _extractParagraphs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load the epub book
      final EpubBookRef epubBook = await EpubReader.openBook(widget.bookBytes);
      print('📘 Opened ePub book: ${widget.title}');
      
      // Create a map to store paragraphs for each chapter
      _chapterParagraphs = {};
      
      // Keep track of chapters and all paragraphs
      List<String> allParagraphs = [];
      
      // Create basic chapter structure - compatible with web
      try {
        print('🔍 Creating chapter structure...');
        
        // Try to get chapters directly (most compatible method)
        List<EpubChapterRef> chapters = await epubBook.getChapters();
        print('📚 Found ${chapters.length} chapters in the book');
        
        if (chapters.isNotEmpty) {
          // Build chapter list
          _chapters = [];
          _detailedChapters = [];
          
          for (int i = 0; i < chapters.length; i++) {
            final chapter = chapters[i];
            final chapterInfo = {
              'title': chapter.Title ?? 'Chapter ${i + 1}',
              'index': i,
              'level': 0,
              'fileName': chapter.ContentFileName,
              'anchor': chapter.Anchor,
            };
            
            _chapters.add(chapterInfo);
            _detailedChapters.add(chapterInfo);
            print('📑 Chapter ${i + 1}: ${chapter.Title ?? 'Untitled'} (${chapter.ContentFileName})');
          }
        } else {
          // If no chapters found, use HTML files as chapters
          var content = epubBook.Content;
          var htmlFiles = content?.Html?.keys.toList() ?? [];
          
          if (htmlFiles.isNotEmpty) {
            print('📄 No chapters found, using ${htmlFiles.length} HTML files as chapters');
            
            _chapters = [];
            _detailedChapters = [];
            
            for (int i = 0; i < htmlFiles.length; i++) {
              final fileName = htmlFiles[i];
              
              // Try to create a nice title from the filename
              String title = 'Chapter ${i + 1}';
              if (fileName.isNotEmpty) {
                title = fileName
                    .split('/')
                    .last
                    .replaceAll('.html', '')
                    .replaceAll('.xhtml', '')
                    .replaceAll('_', ' ')
                    .replaceAll('-', ' ');
                
                // Capitalize first letter
                if (title.length > 1) {
                  title = title[0].toUpperCase() + title.substring(1);
                }
              }
              
              final chapterInfo = {
                'title': title,
                'index': i,
                'level': 0,
                'fileName': fileName,
              };
              
              _chapters.add(chapterInfo);
              _detailedChapters.add(chapterInfo);
            }
          } else {
            // If nothing else works, create default chapters
            print('⚠️ No chapter structure found, creating default chapters');
            _chapters = List.generate(5, (i) => {
              'title': 'Chapter ${i + 1}',
              'index': i,
              'level': 0,
            });
            _detailedChapters = List.from(_chapters);
          }
        }
      } catch (e) {
        print('⚠️ Error creating chapter structure: $e');
        // Create default chapter structure as fallback
        _chapters = List.generate(5, (i) => {
          'title': 'Chapter ${i + 1}',
          'index': i,
          'level': 0,
        });
        _detailedChapters = List.from(_chapters);
      }
      
      // Continue with the existing content extraction methods
      try {
        print('🔍 Trying to extract content using direct byte parsing...');
        EpubBook book = await EpubReader.readBook(widget.bookBytes);
        if (book.Chapters != null && book.Chapters!.isNotEmpty) {
          print('✅ Successfully parsed complete ePub book with ${book.Chapters!.length} chapters');
          
          // Extract chapters
          for (int i = 0; i < book.Chapters!.length; i++) {
            final chapter = book.Chapters![i];
            
            // Extract content from HTML
            List<String> chapterContent = [];
            if (chapter.HtmlContent != null) {
              final document = html_parser.parse(chapter.HtmlContent);
              
              // Extract all paragraph elements
              final pElements = document.querySelectorAll('p');
              print('📝 Found ${pElements.length} paragraph elements in chapter ${i + 1}');
              
              for (var p in pElements) {
                final text = p.text.trim();
                if (text.isNotEmpty && text.split(' ').length > 3) {
                  chapterContent.add(text);
                }
              }
              
              // If no paragraphs found, try div elements
              if (chapterContent.isEmpty) {
                final divElements = document.querySelectorAll('div');
                for (var div in divElements) {
                  final text = div.text.trim();
                  if (text.isNotEmpty && !text.contains('<') && text.split(' ').length > 3) {
                    chapterContent.add(text);
                  }
                }
              }
              
              // If still empty, try any text from the document
              if (chapterContent.isEmpty) {
                final text = document.body?.text.trim() ?? '';
                if (text.isNotEmpty) {
                  // Split by sentences to create paragraphs
                  final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
                  for (int j = 0; j < sentences.length; j += 3) {
                    final end = j + 3 < sentences.length ? j + 3 : sentences.length;
                    final paragraph = sentences.sublist(j, end).join(' ');
                    if (paragraph.split(' ').length > 5) {
                      chapterContent.add(paragraph);
                    }
                  }
                }
              }
            }
            
            // Store chapter content
            if (chapterContent.isNotEmpty) {
              print('✅ Extracted ${chapterContent.length} paragraphs from chapter ${i + 1}');
              _chapterParagraphs[i] = chapterContent;
              allParagraphs.addAll(chapterContent);
            } else {
              print('⚠️ No content extracted from chapter ${i + 1}');
            }
          }
        }
      } catch (e) {
        print('⚠️ Error in complete book extraction: $e');
      }
      
      // Try simpler content extraction method for web
      if (allParagraphs.isEmpty && epubBook.Content?.Html != null) {
        try {
          print('🔍 Trying simplified HTML extraction for web platform...');
          
          // Process each HTML file
          var htmlFiles = epubBook.Content!.Html!.entries.toList();
          int fileIndex = 0;
          
          for (var entry in htmlFiles) {
            final fileName = entry.key;
            var htmlContent = "";
            
            try {
              // Try to get HTML content directly or indirectly
              try {
                final contentFile = entry.value;
                if (contentFile != null) {
                  // Convert file content to string
                  try {
                    htmlContent = contentFile.toString();
                    if (htmlContent.contains('<html') || htmlContent.contains('<body')) {
                      print('✅ Found HTML content in file: $fileName');
                    }
                  } catch (e) {
                    print('❌ Error converting file content to string: $e');
                  }
                }
              } catch (e) {
                print('❌ Error accessing HTML file: $e');
              }
              
              if (htmlContent.isNotEmpty) {
                // Parse HTML content
                final document = html_parser.parse(htmlContent);
                List<String> fileContent = [];
                
                // Extract paragraphs
                final pElements = document.querySelectorAll('p');
                for (var p in pElements) {
                  final text = p.text.trim();
                  if (text.isNotEmpty && text.split(' ').length > 3) {
                    fileContent.add(text);
                  }
                }
                
                // If no paragraphs found, try div elements
                if (fileContent.isEmpty) {
                  final divElements = document.querySelectorAll('div');
                  for (var div in divElements) {
                    final text = div.text.trim();
                    if (text.isNotEmpty && !text.contains('<') && text.split(' ').length > 3) {
                      fileContent.add(text);
                    }
                  }
                }
                
                // Store chapter content
                if (fileContent.isNotEmpty) {
                  _chapterParagraphs[fileIndex] = fileContent;
                  allParagraphs.addAll(fileContent);
                  fileIndex++;
                }
              }
            } catch (e) {
              print('❌ Error processing HTML file: $e');
            }
          }
          
          print('✅ Extracted content from ${fileIndex} HTML files');
        } catch (e) {
          print('❌ Error in HTML extraction: $e');
        }
      }
      
      // If no content was extracted using normal means, try raw extraction
      if (allParagraphs.isEmpty) {
        print('⚠️ All standard approaches failed, using raw text extraction');
        try {
          // Convert the epub bytes to string and look for content
          final rawEpubString = String.fromCharCodes(widget.bookBytes);
          
          // Extract chunks of text between tags
          final textMatches = RegExp(r'>([^<]{50,})<').allMatches(rawEpubString);
          List<String> extractedTexts = [];
          
          for (var match in textMatches) {
            if (match.group(1) != null) {
              final text = match.group(1)!.trim();
              if (text.length > 100 && text.contains('.')) {
                // Split by periods to form paragraphs
                final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
                
                for (int i = 0; i < sentences.length; i += 3) {
                  final end = i + 3 < sentences.length ? i + 3 : sentences.length;
                  final paragraph = sentences.sublist(i, end).join(' ');
                  if (paragraph.split(' ').length > 5) {
                    extractedTexts.add(paragraph);
                  }
                }
              }
            }
          }
          
          if (extractedTexts.isNotEmpty) {
            print('✅ Extracted ${extractedTexts.length} paragraphs using raw extraction');
            
            // Divide content across chapters
            final int chaptersCount = _chapters.length;
            final int paragraphsPerChapter = (extractedTexts.length / chaptersCount).ceil();
            
            for (int i = 0; i < chaptersCount; i++) {
              final start = i * paragraphsPerChapter;
              final end = (start + paragraphsPerChapter < extractedTexts.length) 
                  ? start + paragraphsPerChapter 
                  : extractedTexts.length;
                  
              if (start < end) {
                _chapterParagraphs[i] = extractedTexts.sublist(start, end);
              }
            }
            
            allParagraphs = extractedTexts;
          }
        } catch (e) {
          print('❌ Error in raw extraction: $e');
        }
      }
      
      // If no content could be extracted, use dummy paragraphs
      if (allParagraphs.isEmpty) {
        print('❌ All extraction methods failed, using dummy paragraphs');
        allParagraphs = _getDummyParagraphs();
        
        // Distribute dummy paragraphs across chapters
        final dummyCount = allParagraphs.length;
        final chaptersCount = _chapters.length;
        final paragraphsPerChapter = (dummyCount / chaptersCount).ceil();
        
        for (int i = 0; i < chaptersCount; i++) {
          final start = i * paragraphsPerChapter;
          final end = (start + paragraphsPerChapter < dummyCount) ? start + paragraphsPerChapter : dummyCount;
          
          if (start < end) {
            _chapterParagraphs[i] = allParagraphs.sublist(start, end);
          }
        }
      } else {
        print('✅ Successfully extracted ${allParagraphs.length} total paragraphs across chapters');
      }
      
      setState(() {
        _paragraphs = allParagraphs;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading ePub: $e');
      // Fallback to dummy paragraphs
      setState(() {
        _paragraphs = _getDummyParagraphs();
        
        // Create dummy chapters
        _chapters = List.generate(5, (i) => {
          'title': 'Chapter ${i + 1}',
          'index': i,
          'level': 0,
        });
        _detailedChapters = List.from(_chapters);
        
        // Distribute dummy paragraphs across chapters
        final dummyCount = _paragraphs.length;
        final chaptersCount = _chapters.length;
        final paragraphsPerChapter = (dummyCount / chaptersCount).ceil();
        
        for (int i = 0; i < chaptersCount; i++) {
          final start = i * paragraphsPerChapter;
          final end = (start + paragraphsPerChapter < dummyCount) ? start + paragraphsPerChapter : dummyCount;
          
          if (start < end) {
            _chapterParagraphs[i] = _paragraphs.sublist(start, end);
          }
        }
        
        _isLoading = false;
      });
    }
  }

  // Helper method to extract raw HTML content
  Future<String?> _extractRawHtmlContent(EpubBookRef epubBook, String contentFileName) async {
    try {
      // First, try normal access via Content.Html
      if (epubBook.Content?.Html != null &&
          epubBook.Content!.Html!.containsKey(contentFileName)) {
        
        final contentFile = epubBook.Content!.Html![contentFileName];
        if (contentFile != null) {
          // Try to extract the raw content
          try {
            // Try accessing properties of the contentFile using reflection
            final instance = contentFile;
            print('🔍 Examining content file: ${instance.runtimeType}');
            
            // Try the most common field names for content
            try {
              final fields = instance.toString().split(',');
              for (var field in fields) {
                field = field.trim();
                if (field.contains('Content:')) {
                  final match = RegExp(r'Content:\s*(\[.*?\])').firstMatch(field);
                  if (match != null && match.group(1) != null) {
                    // Extract the content bytes
                    final bytesStr = match.group(1)!;
                    if (bytesStr.isNotEmpty && bytesStr.length > 10) {
                      // This is a list of byte values
                      try {
                        final bytes = bytesStr
                            .replaceAll('[', '')
                            .replaceAll(']', '')
                            .split(',')
                            .map((s) => int.tryParse(s.trim()) ?? 0)
                            .toList();
                        return String.fromCharCodes(bytes);
                      } catch (e) {
                        print('❌ Failed to parse byte array: $e');
                      }
                    }
                  }
                }
              }
            } catch (e) {
              print('❌ Error in reflection extraction: $e');
            }
            
            // Try direct string conversion as a fallback
            final asString = contentFile.toString();
            if (asString.length > 50 && (asString.contains('<html') || asString.contains('<body'))) {
              return asString;
            }
            
            // Try extracting bytes from raw epub
            final index = epubBook.Schema?.Package?.Manifest?.Items?.indexWhere(
              (item) => item.Href == contentFileName || item.Id == contentFileName
            ) ?? -1;
            
            if (index >= 0 && index < (epubBook.Schema?.Package?.Manifest?.Items?.length ?? 0)) {
              final item = epubBook.Schema!.Package!.Manifest!.Items![index];
              print('✓ Found manifest item: ${item.Id} (${item.Href})');
              
              // Try to extract the content from the raw epub bytes
              try {
                final rawEpubString = String.fromCharCodes(widget.bookBytes);
                final contentPrefix = item.Id ?? item.Href ?? contentFileName;
                
                // Look for content in the raw epub
                final contentMarker = contentFileName.replaceAll('/', '_').replaceAll('.', '_');
                final contentRegex = RegExp('<$contentMarker[^>]*>(.*?)</$contentMarker>', dotAll: true);
                final contentMatch = contentRegex.firstMatch(rawEpubString);
                
                if (contentMatch != null && contentMatch.group(1) != null) {
                  return contentMatch.group(1);
                }
              } catch (e) {
                print('❌ Error extracting from raw epub: $e');
              }
            }
          } catch (e) {
            print('❌ Error accessing content: $e');
          }
        }
      }
      
      // Alternative extraction approach
      try {
        // Look for the content in the Schema
        if (epubBook.Schema?.Package?.Manifest != null) {
          final items = epubBook.Schema!.Package!.Manifest!.Items;
          final item = items?.firstWhere(
            (item) => item.Href == contentFileName || item.Id == contentFileName,
            orElse: () => items!.firstWhere(
              (item) => item.Href?.contains(contentFileName) == true || 
                        contentFileName.contains(item.Href ?? '') == true,
              orElse: () => items.first
            )
          );
          
          if (item != null) {
            print('✓ Found item in manifest: ${item.Id} (${item.Href})');
            // Try to use this information to find content
          }
        }
      } catch (e) {
        print('❌ Error in alternative extraction: $e');
      }
      
      return null;
    } catch (e) {
      print('❌ Error extracting content: $e');
      return null;
    }
  }

  List<String> _getDummyParagraphs() {
    return [
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
      "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
      "The quick brown fox jumps over the lazy dog. A fast black dog jumps over the calm fox. The five boxing wizards jump quickly.",
      "She sells seashells by the seashore. Peter Piper picked a peck of pickled peppers. How much wood would a woodchuck chuck if a woodchuck could chuck wood?",
      "All human beings are born free and equal in dignity and rights. They are endowed with reason and conscience and should act towards one another in a spirit of brotherhood.",
      "Science is the systematic study of the structure and behavior of the physical and natural world through observation and experiment. Philosophy is the study of the fundamental nature of knowledge, reality, and existence.",
      "The Nile is the longest river in Africa and has historically been considered the longest river in the world. The Amazon is the largest river by discharge volume of water in the world, and by some definitions it is the longest.",
      "In computer science, artificial intelligence (AI), sometimes called machine intelligence, is intelligence demonstrated by machines, unlike the natural intelligence displayed by humans and animals.",
      "A library is a collection of materials, books or media that are accessible for use and not just for display purposes. A book is a medium for recording information in the form of writing or images, typically composed of many pages bound together.",
      "Music is the art of arranging sounds in time through the elements of melody, harmony, rhythm, and timbre. It is one of the universal cultural aspects of all human societies.",
    ];
  }

  // Replace the _processTableOfContents method with a simpler version that doesn't use EpubNavigationItemRef
  List<Map<String, dynamic>> _processChapterData(List<dynamic> items, {int level = 0}) {
    List<Map<String, dynamic>> result = [];
    
    for (var item in items) {
      if (item is Map<String, dynamic>) {
        // Add this item
        result.add({
          'title': item['title'] ?? 'Untitled Chapter',
          'fileName': item['fileName'],
          'anchor': item['anchor'],
          'level': level,
        });
        
        // Process children with incremented level
        if (item.containsKey('children') && item['children'] is List) {
          result.addAll(_processChapterData(item['children'], level: level + 1));
        }
      }
    }
    
    return result;
  }

  void _goToPreviousParagraph() {
    if (_currentParagraphIndex > 0) {
      setState(() {
        _currentParagraphIndex--;
        _lastReadIndex = _currentParagraphIndex;
      });
      _saveReadingProgress(); // Save progress after navigation
    }
  }

  void _goToNextParagraph() {
    if (_currentParagraphIndex < _paragraphs.length - 1) {
      setState(() {
        _currentParagraphIndex++;
        _lastReadIndex = _currentParagraphIndex;
      });
      _saveReadingProgress(); // Save progress after navigation
    }
  }

  void _toggleParagraphStatus(int index, ParagraphStatus status) {
    setState(() {
      switch (status) {
        case ParagraphStatus.selected:
          if (_selectedParagraphs.contains(index)) {
            _selectedParagraphs.remove(index);
          } else {
            _selectedParagraphs.add(index);
            _notUnderstoodParagraphs.remove(index);
            _difficultParagraphs.remove(index);
          }
          break;
        case ParagraphStatus.notUnderstood:
          if (_notUnderstoodParagraphs.contains(index)) {
            _notUnderstoodParagraphs.remove(index);
          } else {
            _notUnderstoodParagraphs.add(index);
            _selectedParagraphs.remove(index);
            _difficultParagraphs.remove(index);
          }
          break;
        case ParagraphStatus.difficult:
          if (_difficultParagraphs.contains(index)) {
            _difficultParagraphs.remove(index);
          } else {
            _difficultParagraphs.add(index);
            _selectedParagraphs.remove(index);
            _notUnderstoodParagraphs.remove(index);
          }
          break;
      }
    });
  }

  void _updateHighlightedWords(Map<int, Set<String>> wordsMap) {
    setState(() {
      // Update the highlighted words map with the new values
      _highlightedWords = Map.from(_highlightedWords)..addAll(wordsMap);
      
      // Remove any entries with empty sets
      wordsMap.forEach((paragraphIndex, words) {
        if (words.isEmpty) {
          _highlightedWords.remove(paragraphIndex);
        }
      });
    });
  }

  void _updatePhrasalVerbs(int paragraphIndex, Set<String> phrases) {
    setState(() {
      if (phrases.isEmpty) {
        _phrasalVerbs.remove(paragraphIndex);
      } else {
        _phrasalVerbs[paragraphIndex] = phrases;
      }
    });
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize = _fontSize >= 28.0 ? 28.0 : _fontSize + 2.0;
    });
  }

  void _decreaseFontSize() {
    setState(() {
      _fontSize = _fontSize <= 12.0 ? 12.0 : _fontSize - 2.0;
    });
  }

  void _showMarkedParagraphsDialog() {
    final allMarkedParagraphs = <int>{};
    allMarkedParagraphs.addAll(_selectedParagraphs);
    allMarkedParagraphs.addAll(_notUnderstoodParagraphs);
    allMarkedParagraphs.addAll(_difficultParagraphs);
    
    if (allMarkedParagraphs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No marked paragraphs to show')),
      );
      return;
    }
    
    final sortedParagraphs = allMarkedParagraphs.toList()..sort();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Marked Paragraphs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: sortedParagraphs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final paragraphIndex = sortedParagraphs[index];
                    final paragraph = _paragraphs[paragraphIndex];
                    
                    // Determine the type of marking
                    final isSelected = _selectedParagraphs.contains(paragraphIndex);
                    final isNotUnderstood = _notUnderstoodParagraphs.contains(paragraphIndex);
                    final isDifficult = _difficultParagraphs.contains(paragraphIndex);
                    
                    // Determine the icon and color based on the type
                    IconData icon;
                    Color color;
                    String label;
                    
                    if (isSelected) {
                      icon = Icons.star;
                      color = Colors.amber;
                      label = 'Important';
                    } else if (isNotUnderstood) {
                      icon = Icons.help;
                      color = Colors.red;
                      label = 'Not Understood';
                    } else {
                      icon = Icons.warning;
                      color = Colors.orange;
                      label = 'Difficult';
                    }
                    
                    return ListTile(
                      leading: Icon(icon, color: color),
                      title: Text(
                        paragraph.length > 100 ? '${paragraph.substring(0, 100)}...' : paragraph,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Text('Paragraph ${paragraphIndex + 1}'),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(label),
                            backgroundColor: color.withOpacity(0.2),
                            labelStyle: TextStyle(color: color),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(0),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _jumpToParagraph(paragraphIndex);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _jumpToParagraph(int index) {
    if (index >= 0 && index < _paragraphs.length) {
      setState(() {
        _currentParagraphIndex = index;
        _lastReadIndex = index;
      });
      _saveReadingProgress();
    }
  }

  void _showReviewPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookWordsReviewPage(
          highlightedWords: _highlightedWords,
          phrasalVerbs: _phrasalVerbs,
          paragraphs: _paragraphs,
          bookTitle: widget.title,
          bookAuthor: widget.author,
        ),
      ),
    );
  }

  void _showSummary() {
    final totalMarkedWords = _highlightedWords.values.fold<int>(
      0, (sum, words) => sum + words.length);
    final totalPhrasalVerbs = _phrasalVerbs.values.fold<int>(
      0, (sum, phrases) => sum + phrases.length);
      
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reading Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book: ${widget.title}'),
            Text('Author: ${widget.author}'),
            const SizedBox(height: 16),
            Text('Total Paragraphs: ${_paragraphs.length}'),
            Text('Current Position: ${(_currentParagraphIndex + 1)}/${_paragraphs.length}'),
            Text('Reading Progress: ${((_currentParagraphIndex + 1) / _paragraphs.length * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            Text('Selected Paragraphs: ${_selectedParagraphs.length}'),
            Text('Not Understood Paragraphs: ${_notUnderstoodParagraphs.length}'),
            Text('Difficult Paragraphs: ${_difficultParagraphs.length}'),
            const SizedBox(height: 16),
            Text('Words Marked: $totalMarkedWords'),
            Text('Phrases Marked: $totalPhrasalVerbs'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
          if (totalMarkedWords > 0 || totalPhrasalVerbs > 0)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showReviewPage();
              },
              child: const Text('REVIEW VOCABULARY'),
            ),
        ],
      ),
    );
  }

  void _navigateToChapter(int chapterIndex) {
    if (chapterIndex >= 0 && chapterIndex < _chapters.length) {
      setState(() {
        _currentChapterIndex = chapterIndex;
        
        // Load paragraphs for this chapter if available
        if (_chapterParagraphs.containsKey(chapterIndex)) {
          _paragraphs = _chapterParagraphs[chapterIndex]!;
        }
        
        _currentParagraphIndex = 0; // Reset to start of chapter
      });
      
      _saveReadingProgress(); // Save progress after navigation
    }
  }

  // Add methods for saving/loading reading progress
  Future<void> _saveReadingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressData = {
        'chapterIndex': _currentChapterIndex,
        'paragraphIndex': _currentParagraphIndex,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'totalParagraphs': _paragraphs.length,
      };
      
      await prefs.setString('book_progress_${widget.bookId}', jsonEncode(progressData));
      print('✅ Reading progress saved');
    } catch (e) {
      print('❌ Error saving reading progress: $e');
    }
  }
  
  Future<void> _loadReadingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedProgress = prefs.getString('book_progress_${widget.bookId}');
      
      if (savedProgress != null) {
        final progressData = jsonDecode(savedProgress) as Map<String, dynamic>;
        final savedTime = DateTime.fromMillisecondsSinceEpoch(progressData['timestamp'] as int);
        final now = DateTime.now();
        final daysSinceLastRead = now.difference(savedTime).inDays;
        
        // Only restore position if book was read in the last 30 days
        if (daysSinceLastRead <= 30) {
          // Wait for paragraphs to load first
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            setState(() {
              _currentChapterIndex = progressData['chapterIndex'] as int;
              _currentParagraphIndex = progressData['paragraphIndex'] as int;
              
              // Load paragraphs for this chapter if available
              if (_chapterParagraphs.containsKey(_currentChapterIndex)) {
                _paragraphs = _chapterParagraphs[_currentChapterIndex]!;
              }
              
              // Ensure paragraph index is valid
              if (_currentParagraphIndex >= _paragraphs.length) {
                _currentParagraphIndex = _paragraphs.length - 1;
              }
              
              print('✅ Reading progress restored to Chapter ${_currentChapterIndex + 1}, Paragraph ${_currentParagraphIndex + 1}');
            });
            
            // Show confirmation to user
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reading progress restored'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error loading reading progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode 
        ? ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
          )
        : ThemeData.light().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              tooltip: 'Go to Home',
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleDarkMode,
              tooltip: 'Toggle Dark Mode',
            ),
            IconButton(
              icon: const Icon(Icons.text_decrease),
              onPressed: _decreaseFontSize,
              tooltip: 'Decrease Font Size',
            ),
            IconButton(
              icon: const Icon(Icons.text_increase),
              onPressed: _increaseFontSize,
              tooltip: 'Increase Font Size',
            ),
            PopupMenuButton<int>(
              tooltip: 'Chapters',
              icon: const Icon(Icons.menu_book),
              onSelected: _navigateToChapter,
              itemBuilder: (context) {
                return _chapters.map((chapter) {
                  return PopupMenuItem<int>(
                    value: chapter['index'],
                    child: Text(
                      chapter['title'],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList();
              },
            ),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              onPressed: _showSummary,
              tooltip: 'Show Summary',
            ),
          ],
        ),
        drawer: Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    if (widget.author.isNotEmpty)
                      Text(
                        'by ${widget.author}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Reading progress: ${((_currentParagraphIndex + 1) / _paragraphs.length * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = _chapters[index];
                    // Get indentation level for hierarchical display
                    final int level = chapter['level'] as int? ?? 0;
                    
                    return ListTile(
                      title: Padding(
                        padding: EdgeInsets.only(left: level * 16.0),
                        child: Text(
                          chapter['title'],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: _currentChapterIndex == index ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16 - (level * 1.0).clamp(0, 4), // Smaller font for deeper levels
                          ),
                        ),
                      ),
                      selected: _currentChapterIndex == index,
                      leading: level == 0 ? const Icon(Icons.bookmark) : null,
                      dense: level > 0, // Make nested items more compact
                      visualDensity: level > 0 ? VisualDensity.compact : null,
                      onTap: () {
                        _navigateToChapter(index);
                        Navigator.pop(context); // Close drawer
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Reading progress indicator
                      LinearProgressIndicator(
                        value: _paragraphs.isEmpty ? 0 : (_currentParagraphIndex + 1) / _paragraphs.length,
                        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      ),
                      
                      // Chapter info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: _isDarkMode ? Colors.grey[850] : Colors.grey[200],
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _chapters.isNotEmpty && _currentChapterIndex < _chapters.length
                                    ? _chapters[_currentChapterIndex]['title']
                                    : 'Chapter',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isDarkMode ? Colors.white : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Paragraph ${_currentParagraphIndex + 1} of ${_paragraphs.length}',
                              style: TextStyle(
                                color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Main content area
                      Expanded(
                        child: BookReadModeWidget(
                          paragraphs: _paragraphs,
                          currentReadIndex: _currentParagraphIndex,
                          onPrevious: _goToPreviousParagraph,
                          onNext: _goToNextParagraph,
                          onExit: () {
                            Navigator.of(context).pop();
                          },
                          onMarkNotUnderstood: () => _toggleParagraphStatus(
                            _currentParagraphIndex, ParagraphStatus.notUnderstood),
                          onMarkDifficultVocab: () => _toggleParagraphStatus(
                            _currentParagraphIndex, ParagraphStatus.difficult),
                          onShowMarkedParagraphs: _showMarkedParagraphsDialog,
                          onJumpToParagraph: (index) {
                            _jumpToParagraph(index);
                          },
                          notUnderstoodParagraphs: _notUnderstoodParagraphs,
                          difficultVocabParagraphs: _difficultParagraphs,
                          onUpdateDifficultWords: _updateHighlightedWords,
                          onUpdateNotes: (notes) {
                            // Handle notes if needed
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  // Review Words button as a positioned element instead of FAB
                  if (_highlightedWords.isNotEmpty || _phrasalVerbs.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: ElevatedButton.icon(
                        onPressed: _showReviewPage,
                        icon: const Icon(Icons.format_list_bulleted),
                        label: const Text('Review Words'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }
}

enum ParagraphStatus {
  selected,
  notUnderstood,
  difficult,
} 