import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

Future<String> exportVocabularyData(String jsonData) async {
  try {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final filename = 'visualvocab_export_${timestamp}.json';
    
    // Use application documents directory to match app's existing logic
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    
    // Ensure the directory exists
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    // Write the file and verify it exists
    await file.writeAsString(jsonData);
    final fileExists = await file.exists();
    if (!fileExists) {
      throw Exception('Failed to create file at ${file.path}');
    }
    
    // Create an XFile with explicit MIME type and proper name
    final xFile = XFile(
      file.path,
      mimeType: 'application/json',
      name: filename,
      length: await file.length(),
      lastModified: DateTime.now(),
    );
    
    // Share the file - keep subject line clean without parentheses
    await Share.shareXFiles(
      [xFile],
      subject: 'Visual Vocabularies Export',
      text: 'Import this JSON file in the Visual Vocabularies app.',
    );
    
    return 'Export successful. Sharing file...';
  } catch (e) {
    return 'Error exporting data: $e';
  }
} 