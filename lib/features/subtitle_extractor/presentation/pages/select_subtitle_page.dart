import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import '../widgets/read_mode_widget.dart';
import '../widgets/highlighted_words_review_page.dart';
import '../widgets/read_mode_page.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';

class SelectSubtitlePage extends StatefulWidget {
  /// Flag to indicate if the page is embedded in a tab view
  final bool isEmbedded;

  /// Default constructor
  const SelectSubtitlePage({super.key, this.isEmbedded = true});

  @override
  State<SelectSubtitlePage> createState() => _SelectSubtitlePageState();
}

class _SelectSubtitlePageState extends State<SelectSubtitlePage> {
  String? _selectedFileName;
  Uint8List? _subtitleBytes;
  String? _subtitleText;
  bool _isLoading = false;
  String? _fetchError;

  // Form fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _seasonController = TextEditingController();
  final TextEditingController _episodeController = TextEditingController();
  final TextEditingController _subtitleTextController = TextEditingController();


  int? _originalLineCount;
  int? _formattedLineCount;

  bool _readMode = false;
  int _currentReadIndex = 0;
  List<String> _subtitleLines = [];
  final Set<int> _notUnderstoodLines = {};
  final Set<int> _difficultVocabLines = {};

  final TextEditingController _jumpToController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _searchError;

  @override
  void dispose() {
    _titleController.dispose();
    _seasonController.dispose();
    _episodeController.dispose();
    _jumpToController.dispose();
    _searchController.dispose();
    _subtitleTextController.dispose();
    super.dispose();
  }

  void _showFormForSubtitle(String fileName, Uint8List bytes) async {
    final text = String.fromCharCodes(bytes);
    setState(() {
      _selectedFileName = fileName;
      _subtitleBytes = bytes;
      _subtitleText = text;
      _subtitleTextController.text = text;
      _originalLineCount = text.split('\n').length;
      _formattedLineCount = null;
      // Improved regex to match S01E01 and 1x01 styles
      final regex = RegExp(r'(.+?)[. _-]+(?:[Ss](\d+)[. _-]?[Ee](\d+)|(\d+)[xX](\d+))');
      final match = regex.firstMatch(fileName);
      if (match != null) {
        _titleController.text = match.group(1)?.replaceAll('.', ' ').replaceAll('_', ' ').trim() ?? '';
        // S01E01 style
        if (match.group(2) != null && match.group(3) != null) {
          _seasonController.text = match.group(2) ?? '';
          _episodeController.text = match.group(3) ?? '';
        }
        // 1x01 style
        else if (match.group(4) != null && match.group(5) != null) {
          _seasonController.text = match.group(4) ?? '';
          _episodeController.text = match.group(5) ?? '';
        }
      } else {
        _titleController.text = fileName.split('.').first.replaceAll('.', ' ').replaceAll('_', ' ').trim();
        _seasonController.text = '';
        _episodeController.text = '';
      }
    });
  }

  void _formatSubtitleText() {
    final textToFormat = _subtitleTextController.text;
    if (textToFormat.isEmpty) return;
    
    // Remove timestamps, sequence numbers, empty lines, HTML tags, and weird/unicode control characters
    final lines = textToFormat.split('\n');
    final buffer = StringBuffer();
    final timestampRegex = RegExp(r'\d{2}:\d{2}:\d{2},\d{3} -->');
    final htmlTagRegex = RegExp(r'<[^>]+>');
    final weirdCharRegex = RegExp(r'[\u2000-\u206F\uFEFF\u00A0-\u00BF\uFFF0-\uFFFF]|[^\x00-\x7F]');
    for (final line in lines) {
      var trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (int.tryParse(trimmed) != null) continue; // sequence number
      if (timestampRegex.hasMatch(trimmed)) continue; // timestamp
      trimmed = trimmed.replaceAll(htmlTagRegex, ''); // remove HTML tags
      trimmed = trimmed.replaceAll(weirdCharRegex, ''); // remove weird/unicode chars
      if (trimmed.isEmpty) continue;
      buffer.writeln(trimmed);
    }
    final formatted = buffer.toString();
    setState(() {
      _subtitleText = formatted;
      _subtitleTextController.text = formatted;
      _formattedLineCount = formatted.split('\n').where((l) => l.trim().isNotEmpty).length;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subtitle text formatted.')),
    );
  }

  Future<void> _pickSubtitleFile() async {
    setState(() {
      _isLoading = true;
      _fetchError = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['srt', 'vtt'], withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          _showFormForSubtitle(file.name, file.bytes!);
        } else {
          setState(() {
            _fetchError = 'Failed to read file data.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _fetchError = 'Failed to pick file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startReadMode() {
    final subtitleText = _subtitleTextController.text;
    if (subtitleText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or upload subtitle text first')),
      );
      return;
    }
    
    _subtitleLines = subtitleText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    
    // Use MaterialPageRoute instead of setState to avoid double back buttons
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReadModePage(
          subtitleLines: _subtitleLines,
          title: _titleController.text.isEmpty ? 'Subtitle Reading' : _titleController.text,
        ),
      ),
    );
  }

  void _exitReadMode() {
    setState(() {
      _readMode = false;
    });
  }

  void _markNotUnderstood() {
    setState(() {
      _notUnderstoodLines.add(_currentReadIndex);
    });
  }

  void _markDifficultVocab() {
    setState(() {
      _difficultVocabLines.add(_currentReadIndex);
    });
  }

  void _nextLine() {
    if (_currentReadIndex < _subtitleLines.length - 1) {
      setState(() {
        _currentReadIndex++;
      });
    }
  }

  void _previousLine() {
    if (_currentReadIndex > 0) {
      setState(() {
        _currentReadIndex--;
      });
    }
  }

  void _jumpToLine() {
    final input = _jumpToController.text.trim();
    final index = int.tryParse(input);
    if (index != null && index > 0 && index <= _subtitleLines.length) {
      setState(() {
        _currentReadIndex = index - 1;
        _searchError = null;
      });
    } else {
      setState(() {
        _searchError = 'Invalid line number';
      });
    }
  }

  void _searchForPhrase() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;
    final foundIndex = _subtitleLines.indexWhere((line) => line.toLowerCase().contains(query));
    if (foundIndex != -1) {
      setState(() {
        _currentReadIndex = foundIndex;
        _searchError = null;
      });
    } else {
      setState(() {
        _searchError = 'Phrase not found';
      });
    }
  }

  void _showMarkedLinesDialog() {
    final markedLines = <String>[];
    for (final idx in {..._notUnderstoodLines, ..._difficultVocabLines}) {
      if (idx >= 0 && idx < _subtitleLines.length) {
        markedLines.add(_subtitleLines[idx]);
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode 
        ? const Color(0xFF2D224A) // Darker purple for dark mode
        : const Color(0xFF673AB7); // Regular purple for light mode
    
    final bodyContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [
                  backgroundColor,
                  const Color(0xFF1D1D2B), // Darker bottom color for dark mode
                ]
              : [
                  backgroundColor,
                  backgroundColor.withOpacity(0.8),
                ],
        ),
      ),
      child: _selectedFileName == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.subtitles,
                        size: 64,
                        color: Colors.cyan,
                      ),
                    ),
                    const SizedBox(height: 24),
                
                    // Title
                    Text(
                      'Subtitle Learning',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                
                    // Description
                    Text(
                      'Upload subtitle files (.srt or .vtt) to extract vocabulary words',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 40),
                
                    // Upload button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickSubtitleFile,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: isDarkMode ? Colors.white : Colors.purple,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(_isLoading ? 'Loading...' : 'Upload Subtitle File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        minimumSize: const Size(220, 56),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_fetchError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _fetchError!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : _buildSubtitleForm(),
    );
    
    // Return content directly or wrapped in Scaffold based on isEmbedded flag
    if (widget.isEmbedded) {
      return bodyContent;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subtitle Learning'),
        centerTitle: true,
      ),
      body: bodyContent,
    );
  }

  Widget _buildSubtitleForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? const Color(0xFF2D2D3A) : Colors.white;
    final backgroundColor = isDarkMode ? const Color(0xFF21212D) : Colors.grey[100];
    
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File info card
                Card(
                  elevation: 4,
                  color: cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName != null ? 'Selected File: $_selectedFileName' : 'Enter or Paste Text',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontSize: 16,
                          ),
                        ),
                        if (_originalLineCount != null)
                          Text(
                            'Original line count: $_originalLineCount',
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                          ),
                        if (_formattedLineCount != null)
                          Text(
                            'Formatted line count: $_formattedLineCount',
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _subtitleTextController.clear();
                                  _subtitleText = '';
                                  _originalLineCount = 0;
                                  _formattedLineCount = null;
                                  // Keep selectedFileName to prevent returning to upload screen
                                  if (_selectedFileName == null) {
                                    _selectedFileName = 'Custom Text';
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Text cleared')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? Colors.red[700] : Colors.red[800],
                                foregroundColor: Colors.white,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.clear),
                                  SizedBox(width: 4),
                                  Text('Clear Text'),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _startReadMode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? Colors.indigo[700] : Colors.indigo,
                                foregroundColor: Colors.white,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.menu_book),
                                  SizedBox(width: 4),
                                  Text('Read Mode'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Media Information
                Text(
                  'Media Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode ? Colors.black26 : Colors.white,
                    labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _seasonController,
                        decoration: InputDecoration(
                          labelText: 'Season',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: isDarkMode ? Colors.black26 : Colors.white,
                          labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _episodeController,
                        decoration: InputDecoration(
                          labelText: 'Episode',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: isDarkMode ? Colors.black26 : Colors.white,
                          labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Subtitle text area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtitle Text',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (_selectedFileName == null)
                      TextButton.icon(
                        onPressed: _pickSubtitleFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload File Instead'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black26 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: TextFormField(
                    controller: _subtitleTextController,
                    onChanged: (value) {
                      _subtitleText = value;
                      setState(() {
                        _originalLineCount = value.split('\n').length;
                        _formattedLineCount = null;
                        // We're editing text directly, not from a file
                        if (_selectedFileName == null) {
                          _selectedFileName = 'Custom Text';
                        }
                      });
                    },
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter or paste subtitle text here...',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                      contentPadding: const EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                
                if (_subtitleText?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _formatSubtitleText,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Format Text'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.teal[700] : Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Add option to enter manual text if no file is uploaded
                if (_selectedFileName == null)
                  Center(
                    child: Text(
                      'Enter your subtitle text above or upload a subtitle file',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
} 