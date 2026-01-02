import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:visual_vocabularies/features/book_extractor/presentation/widgets/book_read_mode_page.dart';
import 'dart:io';
import 'dart:typed_data';

class SelectBookPage extends StatefulWidget {
  /// Flag to indicate if the page is embedded in a tab view
  final bool isEmbedded;

  /// Default constructor
  const SelectBookPage({super.key, this.isEmbedded = true});

  @override
  State<SelectBookPage> createState() => _SelectBookPageState();
}

class _SelectBookPageState extends State<SelectBookPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  
  String? _selectedFileName;
  bool _isLoadingFile = false;
  String? _errorMessage;
  
  // Store the file content as bytes
  List<int>? _bookBytes;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _pickEpubFile() async {
    setState(() {
      _isLoadingFile = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        withData: true, // Always get bytes
      );

      if (result != null) {
        // Use bytes for both web and mobile platforms
        if (result.files.single.bytes != null) {
          final fileBytes = result.files.single.bytes!;
          
          // Extract file name without extension for title suggestion
          final fileName = result.files.single.name;
          final fileNameWithoutExt = fileName.replaceAll('.epub', '');
          
          // Try to extract author/title from filename if it contains " - " separator
          if (fileNameWithoutExt.contains(" - ")) {
            final parts = fileNameWithoutExt.split(" - ");
            if (parts.length >= 2) {
              _titleController.text = parts[0].trim();
              _authorController.text = parts[1].trim();
            } else {
              _titleController.text = fileNameWithoutExt;
            }
          } else {
            _titleController.text = fileNameWithoutExt;
          }

          setState(() {
            _selectedFileName = fileName;
            _bookBytes = fileBytes;
            _isLoadingFile = false;
          });
        } else if (result.files.single.path != null) {
          // Fallback to path for mobile platforms if bytes are not available
          try {
            final file = File(result.files.single.path!);
            final fileBytes = await file.readAsBytes();
            
            // Extract file name without extension for title suggestion
            final fileName = result.files.single.name;
            final fileNameWithoutExt = fileName.replaceAll('.epub', '');
            
            // Try to extract author/title from filename if it contains " - " separator
            if (fileNameWithoutExt.contains(" - ")) {
              final parts = fileNameWithoutExt.split(" - ");
              if (parts.length >= 2) {
                _titleController.text = parts[0].trim();
                _authorController.text = parts[1].trim();
              } else {
                _titleController.text = fileNameWithoutExt;
              }
            } else {
              _titleController.text = fileNameWithoutExt;
            }

            setState(() {
              _selectedFileName = fileName;
              _bookBytes = fileBytes;
              _isLoadingFile = false;
            });
          } catch (e) {
            setState(() {
              _errorMessage = 'Error reading file: ${e.toString()}';
              _isLoadingFile = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Could not access file data. Please try another file.';
            _isLoadingFile = false;
          });
        }
      } else {
        // User canceled the picker
        setState(() {
          _isLoadingFile = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: ${e.toString()}';
        _isLoadingFile = false;
      });
    }
  }

  void _startReadMode() {
    if (_bookBytes == null) {
      setState(() {
        _errorMessage = 'Please select an ePub file first';
      });
      return;
    }
    
    if (_titleController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a title for the book';
      });
      return;
    }

    // Navigate to read mode page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookReadModePage(
          bookBytes: Uint8List.fromList(_bookBytes!),
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Use the content directly or wrap in Scaffold based on isEmbedded flag
    final content = _buildContent(isDarkMode);
    
    if (widget.isEmbedded) {
      return content;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Learning'),
      ),
      body: content,
    );
  }
  
  Widget _buildContent(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Upload ePub Books',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Select an ePub file to read and learn vocabulary from books. You can tap words to mark them and create vocabulary items.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Book file selection
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select ePub File',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: _selectedFileName != null
                        ? Column(
                            children: [
                              Icon(
                                Icons.book,
                                size: 48,
                                color: isDarkMode ? Colors.blue[300] : Colors.blue,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedFileName!,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _isLoadingFile ? null : _pickEpubFile,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Change File'),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.upload_file,
                                    size: 48,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _isLoadingFile ? null : _pickEpubFile,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Select ePub File'),
                              ),
                            ],
                          ),
                  ),
                  if (_isLoadingFile)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Book details form
          if (_selectedFileName != null)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Book Title',
                        hintText: 'Enter the book title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        hintText: 'Enter the author name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _startReadMode,
                        icon: const Icon(Icons.menu_book),
                        label: const Text('Start Reading'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 