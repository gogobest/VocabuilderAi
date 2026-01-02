import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';

/// Helper class for image-related operations
class ImageHelper {
  /// Private constructor to prevent instantiation
  ImageHelper._();
  
  /// Ensures that the images directory structure is created
  static Future<void> ensureImageDirectories() async {
    if (kIsWeb) return; // No need on web
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
        debugPrint('Created images directory at: ${imagesDir.path}');
      }
      
      // Also create the directory in external storage on Android
      if (Platform.isAndroid) {
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final externalImagesDir = Directory('${externalDir.path}/visual_vocabularies/images');
            if (!await externalImagesDir.exists()) {
              await externalImagesDir.create(recursive: true);
              debugPrint('Created external images directory at: ${externalImagesDir.path}');
            }
          }
        } catch (e) {
          debugPrint('Error creating external image directories: $e');
        }
      }
    } catch (e) {
      debugPrint('Error creating image directories: $e');
    }
  }
  
  /// Sanitize and normalize a file path
  /// 
  /// This handles various path formats and normalizes them for consistent use
  static String sanitizeFilePath(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    
    String sanitized = path;
    
    // Remove file:// prefix
    if (sanitized.startsWith('file://')) {
      sanitized = sanitized.substring(7);
    }
    
    // Replace backslashes with forward slashes for consistency
    sanitized = sanitized.replaceAll('\\', '/');
    
    // Remove any double slashes
    while (sanitized.contains('//')) {
      sanitized = sanitized.replaceAll('//', '/');
    }
    
    debugPrint('Sanitized path from "$path" to "$sanitized"');
    return sanitized;
  }
  
  /// Get the proper image widget based on path type
  /// 
  /// This is a helper method to determine if the image is a network image,
  /// local file, or asset, and returns the appropriate widget.
  static String getImageType(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'placeholder';
    }
    
    debugPrint('Analyzing image path: $imagePath');
    
    // Handle base64 data URLs
    if (imagePath.startsWith('data:image')) {
      debugPrint('Detected base64 data URL image');
      return 'data_url';
    }
    
    // Handle web blob URLs
    if (kIsWeb && (imagePath.startsWith('blob:') || imagePath.contains('blob:'))) {
      debugPrint('Detected web blob image');
      return 'web_blob';
    }
    
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      debugPrint('Detected network image');
      return 'network';
    }
    
    if (!kIsWeb) {
      // Sanitize the path first for consistent handling
      String sanitizedPath = sanitizeFilePath(imagePath);
      
      // More comprehensive file path detection
      bool seemsLikeFilePath = sanitizedPath.contains('/') || 
                              sanitizedPath.contains('\\') ||
                              imagePath.startsWith('file:');
      
      if (seemsLikeFilePath && !sanitizedPath.startsWith('assets/')) {
        try {
          final file = File(sanitizedPath);
          final exists = file.existsSync();
          debugPrint('Checking file existence: ${file.path}, exists: $exists');
          
          if (exists) {
            debugPrint('Detected valid local file at: ${file.path}');
            return 'file';
          } else {
            debugPrint('File does not exist at path: ${file.path}');
            // Try some recovery options for common path issues
            
            // Check if file exists in images directory
            try {
              final appDir = getApplicationDocumentsDirectory().then((dir) {
                final fileName = sanitizedPath.split('/').last;
                final alternativePath = '${dir.path}/images/$fileName';
                final alternativeFile = File(alternativePath);
                if (alternativeFile.existsSync()) {
                  debugPrint('Found file in alternative location: $alternativePath');
                  // We can't return from this async context, so we just log it
                }
              });
            } catch (e) {
              debugPrint('Error checking alternative path: $e');
            }
          }
        } catch (e) {
          debugPrint('Error checking file: $e');
        }
      }
    }
    
    // Default to asset
    debugPrint('Defaulting to asset image');
    return 'asset';
  }
  
  /// Create a widget to display an emoji with a nice background
  /// This is used as a fallback when image display fails
  static Widget createEmojiDisplay({
    required String word,
    String? emoji,
    bool useSmallSize = false,
  }) {
    if (emoji == null || emoji.isEmpty) {
      emoji = '📝'; // Default emoji if none provided
    }
    
    // Determine background color based on the word
    final colorCode = _getColorCodeForWord(word);
    final backgroundColor = _hexToColor(colorCode).withOpacity(0.15);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: useSmallSize ? 60.0 : 100.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  /// Get a color code based on the word's first character
  static String _getColorCodeForWord(String word) {
    if (word.isEmpty) return "3498db"; // Default blue if no word
    
    // Use the first character to determine a color family
    final firstChar = word.toLowerCase().codeUnitAt(0);
    
    // Map ranges of characters to different colors
    if (firstChar >= 'a'.codeUnitAt(0) && firstChar <= 'e'.codeUnitAt(0)) {
      return "3498db"; // Blue
    } else if (firstChar >= 'f'.codeUnitAt(0) && firstChar <= 'j'.codeUnitAt(0)) {
      return "2ecc71"; // Green
    } else if (firstChar >= 'k'.codeUnitAt(0) && firstChar <= 'o'.codeUnitAt(0)) {
      return "9b59b6"; // Purple
    } else if (firstChar >= 'p'.codeUnitAt(0) && firstChar <= 't'.codeUnitAt(0)) {
      return "f39c12"; // Orange
    } else {
      return "e74c3c"; // Red
    }
  }
  
  /// Helper method to convert hex color code to Color
  static Color _hexToColor(String hexCode) {
    try {
      final hexColor = hexCode.replaceAll("#", "");
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return Colors.blue.shade100; // Default fallback color
    }
  }
  
  /// Removes any "assets/" prefix duplications
  /// 
  /// Sometimes paths can accidentally have multiple "assets/" prefixes
  static String cleanAssetPath(String assetPath) {
    // Handle common errors with duplicate asset prefixes
    if (assetPath.startsWith('assets/assets/')) {
      return assetPath.replaceFirst('assets/assets/', 'assets/');
    } else if (!assetPath.startsWith('assets/') && !assetPath.startsWith('/')) {
      return 'assets/$assetPath';
    }
    return assetPath;
  }
  
  /// Get the path to the default placeholder image
  static String get defaultPlaceholderPath {
    return 'assets/${AppConstants.defaultImagePath}';
  }
  
  /// Creates a universal placeholder widget
  static Widget createPlaceholderWidget({
    double? width,
    double? height,
    String? message,
    IconData icon = Icons.image,
    Color? backgroundColor,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 200,
      color: backgroundColor ?? Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.grey,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Creates an error placeholder widget for failed image loading
  static Widget createErrorPlaceholder({
    double? width,
    double? height,
    String message = 'Failed to load image',
    Color? backgroundColor,
  }) {
    return createPlaceholderWidget(
      width: width,
      height: height,
      message: message,
      icon: Icons.broken_image,
      backgroundColor: backgroundColor,
    );
  }
} 