import 'dart:convert';
import 'dart:html' as html;

Future<String> exportVocabularyData(String jsonData) async {
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
  final filename = 'visualvocab_export_${timestamp}.json';
  final bytes = utf8.encode(jsonData);
  
  // Create blob with proper MIME type
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Create download link and trigger download
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  
  // Clean up
  html.Url.revokeObjectUrl(url);
  
  return 'Export successful. File downloaded.';
} 