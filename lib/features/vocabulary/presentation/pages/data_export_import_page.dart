import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/widgets/app_navigation_bar.dart';
import 'package:visual_vocabularies/core/widgets/app_loading_indicator.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_event.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_state.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Add this import only for web
// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'package:visual_vocabularies/features/vocabulary/presentation/utils/data_export_helper.dart';
import 'dart:math' show min;

/// Page for exporting and importing vocabulary data
class DataExportImportPage extends StatelessWidget {
  /// Constructor for the DataExportImportPage
  const DataExportImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return BlocListener<VocabularyBloc, VocabularyState>(
      listener: (context, state) async {
        if (state is VocabularyExported) {
          // Handle export success
          await _handleExportSuccess(context, state.jsonData);
        } else if (state is VocabularyImported) {
          // Handle import success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported ${state.itemCount} vocabulary items'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is VocabularyError) {
          // Handle error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppNavigationBar(
          title: 'Backup & Restore Data',
          onBackPressed: () => context.pop(),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                isDarkMode 
                  ? Theme.of(context).colorScheme.surface.withOpacity(0.7)
                  : Theme.of(context).colorScheme.surface.withOpacity(0.5),
              ],
            ),
          ),
          child: BlocBuilder<VocabularyBloc, VocabularyState>(
            builder: (context, state) {
              final bool isLoading = state is VocabularyLoading;
              
              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Export section
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.upload_file, 
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Export Your Vocabulary Data',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Export all your words and categories to a file that you can save or share. You can use this file to migrate your data to another device or as a backup.',
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'This will export:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _buildBulletPoint('All vocabulary items and their details'),
                              _buildBulletPoint('Categories'),
                              _buildBulletPoint('Mastery levels and progress data'),
                              _buildBulletPoint('Saved tense review cards and their feedback'),
                              
                              const SizedBox(height: 24),
                              
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () => _onExportPressed(context),
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(isLoading ? 'Exporting...' : 'Export Data'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Import section
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.download_rounded,
                                    color: Theme.of(context).colorScheme.secondary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Import Vocabulary Data',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Import vocabulary data from a previously exported file. This will add new words to your collection while preserving your existing words.',
                              ),
                              
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.amber, 
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.amber[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Note: This will merge the imported data with your existing data. Items with the same ID will be skipped to avoid duplicates.',
                                        style: TextStyle(
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () => _onImportPressed(context),
                                  icon: const Icon(Icons.download),
                                  label: Text(isLoading ? 'Importing...' : 'Import Data'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isLoading) 
                    const AppLoadingIndicator(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _onExportPressed(BuildContext context) {
    // Dispatch export event to bloc
    context.read<VocabularyBloc>().add(const ExportVocabularyData());
  }

  Future<void> _handleExportSuccess(BuildContext context, String jsonData) async {
    try {
      final result = await exportVocabularyData(jsonData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing export file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onImportPressed(BuildContext context) async {
    try {
      // Open file picker to select JSON file, but also allow any file type
      // in case the user has a JSON file without the proper extension
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        // We don't restrict by extension to handle files that may have lost their extension
        // allowedExtensions: ['json'],
      );
      
      // If user canceled, do nothing
      if (result == null || result.files.isEmpty) {
        return;
      }
      
      final file = result.files.first;
      
      // Read file as string
      String jsonData;
      
      // For web platform - ALWAYS check bytes first
      if (kIsWeb) {
        // On web, we must use bytes
        if (file.bytes != null) {
          final bytes = file.bytes!;
          jsonData = String.fromCharCodes(bytes);
        } else {
          throw Exception('Could not read file: no bytes available');
        }
      } 
      // For mobile platforms
      else if (file.path != null) {
        // File available on device
        final fileObj = File(file.path!);
        jsonData = await fileObj.readAsString();
      } 
      // Fallback for any other case
      else if (file.bytes != null) {
        // File available as bytes
        final bytes = file.bytes!;
        jsonData = String.fromCharCodes(bytes);
      } 
      else {
        throw Exception('Could not read file: neither path nor bytes available');
      }
      
      // Try to parse the JSON to validate it before sending to the bloc
      try {
        final decoded = jsonDecode(jsonData);
        // Check if the JSON has the expected structure
        if (decoded is Map<String, dynamic> && 
            decoded.containsKey('vocabulary') && 
            decoded['vocabulary'] is List) {
          // Valid format - proceed with import
          context.read<VocabularyBloc>().add(ImportVocabularyData(jsonData));
        } else {
          throw FormatException('The file does not contain valid vocabulary data. Expected a "vocabulary" array.');
        }
      } catch (parseError) {
        // Show a more detailed error for JSON parse failures
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: The file is not in valid JSON format. Please make sure you\'re importing a proper vocabulary export file.\n\nDetails: ${parseError.toString().substring(0, min(parseError.toString().length, 100))}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
        return;
      }
    } catch (e) {
      // Show an error message if something went wrong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }
} 