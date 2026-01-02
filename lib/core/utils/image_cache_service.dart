import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:visual_vocabularies/core/utils/image_helper.dart';
import 'package:universal_html/html.dart' as html;
import 'image_cache_service_web.dart'
    if (dart.library.io) 'image_cache_service_io.dart';

/// A service to handle image caching, conversion and cross-platform compatibility
class ImageCacheService {
  static const String _cacheKeyPrefix = 'img_cache_';
  static const String _blobMappingKey = 'blob_url_mapping';

  /// Private constructor for singleton
  ImageCacheService._();
  static final ImageCacheService _instance = ImageCacheService._();

  /// Get the singleton instance
  static ImageCacheService get instance => _instance;
  
  /// Map of blob URLs to their cached data URL or file path
  Map<String, String> _blobMapping = {};
  bool _initialized = false;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappingJson = prefs.getString(_blobMappingKey);
      
      if (mappingJson != null) {
        _blobMapping = Map<String, String>.from(jsonDecode(mappingJson));
        debugPrint('Loaded ${_blobMapping.length} cached image mappings');
      }
      
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing ImageCacheService: $e');
    }
  }
  
  /// Save the blob mapping to persistent storage
  Future<void> _saveBlobMapping() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_blobMappingKey, jsonEncode(_blobMapping));
    } catch (e) {
      debugPrint('Error saving blob mapping: $e');
    }
  }
  
  /// Process an image URL for proper caching and consistent format
  Future<String> processImageUrl(String? imageUrl) async {
    // Handle empty URLs
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    
    try {
      // Remove query parameters from data URLs
      if (imageUrl.startsWith('data:image/') && imageUrl.contains('?')) {
        String cleanImageUrl = imageUrl.split('?')[0];
        debugPrint('Removed query parameters from data URL in image cache service');
        imageUrl = cleanImageUrl;
      }
      
      await initialize();
      
      // Return if already cached
      if (_blobMapping.containsKey(imageUrl)) {
        debugPrint('Using cached version of image: ${imageUrl.substring(0, math.min(30, imageUrl.length))}...');
        return _blobMapping[imageUrl]!;
      }
      
      // Always optimize data URLs to files to avoid storing large strings
      if (imageUrl.startsWith('data:')) {
        return _optimizeDataUrl(imageUrl);
      }
      
      // Handle different types
      if (kIsWeb) {
        // On web, convert blob URLs to data URLs
        if (imageUrl.startsWith('blob:')) {
          return _convertWebBlobToDataUrl(imageUrl);
        }
      } else {
        // On mobile, ensure file paths are valid
        if (imageUrl.startsWith('file:') || 
            imageUrl.contains('/') || 
            imageUrl.contains('\\')) {
          return _ensureValidFilePath(imageUrl);
        }
      }
      
      // Network URLs are handled the same on all platforms
      if (imageUrl.startsWith('http:') || imageUrl.startsWith('https:')) {
        return imageUrl;
      }
      
      // Default: return the URL as is
      return imageUrl;
    } catch (e) {
      debugPrint('Error in processImageUrl: $e');
      return imageUrl ?? ''; // Return original URL if processing fails, or empty string if null
    }
  }
  
  /// Convert a web blob URL to a data URL 
  /// Uses a JavaScript-based approach for web platforms to properly handle blob URLs
  Future<String> _convertWebBlobToDataUrl(String blobUrl) async {
    if (!kIsWeb) {
      debugPrint('Not a web platform, returning blob URL as is');
      return blobUrl;
    }

    try {
      debugPrint('Converting blob URL to data URL using web platform methods');
      
      // Create a completer to handle the async process
      Completer<String> completer = Completer<String>();
      
      // Create a FileReader
      final reader = html.FileReader();
      
      // Set up onLoad event
      reader.onLoad.listen((_) {
        final dataUrl = reader.result as String;
        debugPrint('Successfully converted blob to data URL (length: ${dataUrl.length})');
        
        // Cache the result
        _blobMapping[blobUrl] = dataUrl;
        _saveBlobMapping();
        
        completer.complete(dataUrl);
      });
      
      // Set up error handler
      reader.onError.listen((event) {
        debugPrint('Error reading blob: $event');
        completer.complete(blobUrl); // Return original URL on error
      });
      
      // Fetch the blob using XMLHttpRequest
      final xhr = html.HttpRequest();
      xhr.open('GET', blobUrl);
      xhr.responseType = 'blob';
      
      xhr.onLoad.listen((_) {
        if (xhr.status == 200) {
          final blob = xhr.response as html.Blob;
          reader.readAsDataUrl(blob);
        } else {
          debugPrint('Failed to fetch blob: HTTP ${xhr.status}');
          completer.complete(blobUrl);
        }
      });
      
      xhr.onError.listen((_) {
        debugPrint('XHR error fetching blob');
        
        // Fall back to simpler method that works better with local blobs
        _fetchLocalBlob(blobUrl).then((dataUrl) {
          if (dataUrl != null) {
            debugPrint('Successfully fetched local blob');
            
            // Cache the result
            _blobMapping[blobUrl] = dataUrl;
            _saveBlobMapping();
            
            completer.complete(dataUrl);
          } else {
            completer.complete(blobUrl);
          }
        });
      });
      
      xhr.send();
      
      // Wait for the result
      return await completer.future;
    } catch (e) {
      debugPrint('Error in _convertWebBlobToDataUrl: $e');
      return blobUrl;
    }
  }
  
  /// Try to fetch a local blob URL using a simpler approach for localhost
  Future<String?> _fetchLocalBlob(String blobUrl) async {
    try {
      if (!kIsWeb) return null;
      
      // For web, create a completer to handle the async process
      final completer = Completer<String?>();
      
      // Use Fetch API directly through DOM
      final xhr = html.HttpRequest();
      xhr.open('GET', blobUrl);
      xhr.responseType = 'blob';
      
      xhr.onLoad.listen((_) {
        if (xhr.status == 200) {
          final blob = xhr.response as html.Blob;
          final reader = html.FileReader();
          
          reader.onLoad.listen((_) {
            final dataUrl = reader.result as String;
            debugPrint('Successfully converted blob to data URL with FileReader');
            completer.complete(dataUrl);
          });
          
          reader.onError.listen((event) {
            debugPrint('FileReader error: $event');
            completer.complete(null);
          });
          
          reader.readAsDataUrl(blob);
        } else {
          debugPrint('HTTP error: ${xhr.status}');
          completer.complete(null);
        }
      });
      
      xhr.onError.listen((_) {
        debugPrint('XHR error');
        completer.complete(null);
      });
      
      xhr.send();
      
      return await completer.future;
    } catch (e) {
      debugPrint('Error in _fetchLocalBlob: $e');
      return null;
    }
  }
  
  /// Optimize data URLs by storing them with a unique ID instead of embedding the full data
  Future<String> _optimizeDataUrl(String dataUrl) async {
    try {
      // Generate a unique ID for this image
      final id = const Uuid().v4();
      
      // Determine file extension based on the image type
      String extension = 'img';
      if (dataUrl.startsWith('data:image/jpeg')) {
        extension = 'jpg';
      } else if (dataUrl.startsWith('data:image/png')) {
        extension = 'png';
      } else if (dataUrl.startsWith('data:image/gif')) {
        extension = 'gif';
      } else if (dataUrl.startsWith('data:image/webp')) {
        extension = 'webp';
      }
      
      // For web, we can't save to file system, so store in cache with the ID
      if (kIsWeb) {
        // Store the mapping with the UUID and data URL
        _blobMapping[dataUrl] = 'uuid:$id:$extension:$dataUrl';
        await _saveBlobMapping();
        debugPrint('Optimized data URL on web with ID $id');
        return 'uuid:$id:$extension:$dataUrl';
      }
      
      // For mobile platforms, store the image data in a local file
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = '${directory.path}/images';
      final filePath = '$dirPath/$id.$extension';
      
      // Ensure directory exists
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Extract and decode the base64 data
      final dataStart = dataUrl.indexOf(',') + 1;
      final base64Data = dataUrl.substring(dataStart);
      
      // Try to decode the data
      Uint8List imageData;
      try {
        imageData = base64Decode(base64Data);
      } catch (e) {
        debugPrint('Error decoding base64 data: $e');
        // Try to fix padding issues
        String paddedBase64 = base64Data;
        while (paddedBase64.length % 4 != 0) {
          paddedBase64 += '=';
        }
        imageData = base64Decode(paddedBase64);
      }
      
      // Write the binary data to the file
      final file = File(filePath);
      await file.writeAsBytes(imageData);
      
      // Save the mapping for future reference
      _blobMapping[dataUrl] = 'file://$filePath';
      await _saveBlobMapping();
      
      debugPrint('Optimized data URL: saved to file at $filePath with ID $id');
      return 'file://$filePath';
    } catch (e) {
      debugPrint('Error optimizing data URL: $e');
      return dataUrl; // Return original if optimization fails
    }
  }
  
  /// Ensure a file path is valid and accessible
  Future<String> _ensureValidFilePath(String filePath) async {
    try {
      String sanitizedPath = ImageHelper.sanitizeFilePath(filePath);
      final file = File(sanitizedPath);
      
      if (await file.exists()) {
        debugPrint('File exists at path: $sanitizedPath');
        return sanitizedPath;
      }
      
      // Try to find the file in standard locations
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = sanitizedPath.split('/').last;
      
      // Check in images directory
      final appImagesPath = '${appDir.path}/images/$fileName';
      final appImagesFile = File(appImagesPath);
      
      if (await appImagesFile.exists()) {
        debugPrint('Found file in app images directory: $appImagesPath');
        return appImagesPath;
      }
      
      // If on Android, check external storage
      if (Platform.isAndroid) {
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final externalPath = '${externalDir.path}/visual_vocabularies/images/$fileName';
            final externalFile = File(externalPath);
            
            if (await externalFile.exists()) {
              debugPrint('Found file in external storage: $externalPath');
              return externalPath;
            }
          }
        } catch (e) {
          debugPrint('Error checking external storage: $e');
        }
      }
      
      debugPrint('File not found at any standard location: $filePath');
      return filePath; // Return original as fallback
    } catch (e) {
      debugPrint('Error ensuring valid file path: $e');
      return filePath;
    }
  }
  
  /// Clear the image cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_blobMappingKey);
      _blobMapping.clear();
      debugPrint('Image cache cleared');
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }
}