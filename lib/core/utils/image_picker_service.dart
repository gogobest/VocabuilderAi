import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:visual_vocabularies/core/utils/image_helper.dart';
import 'package:http/http.dart' as http;
import 'package:visual_vocabularies/core/utils/image_cache_service.dart';

/// Service for picking images from gallery or camera
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Check and request required permissions
  Future<bool> _checkPermissions() async {
    if (kIsWeb) return true; // No need for permissions on web
    
    debugPrint('Checking permissions for image picker');
    
    // For Android 13+ (API level 33+), we need to request specific media permissions
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      if (sdkInt >= 33) {
        // For Android 13+ use READ_MEDIA_IMAGES
        final status = await Permission.photos.status;
        if (status.isDenied) {
          debugPrint('Requesting photos permission for Android 13+');
          final result = await Permission.photos.request();
          return result.isGranted;
        }
        return status.isGranted;
      } else if (sdkInt >= 30) {
        // For Android 11-12, check for MANAGE_EXTERNAL_STORAGE
        final status = await Permission.manageExternalStorage.status;
        if (status.isDenied) {
          debugPrint('Requesting manage external storage permission for Android 11-12');
          final result = await Permission.manageExternalStorage.request();
          if (!result.isGranted) {
            // Fall back to regular storage permission
            final storageStatus = await Permission.storage.request();
            return storageStatus.isGranted;
          }
          return result.isGranted;
        }
        return status.isGranted;
      }
    }
    
    // For older Android versions
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.storage.status;
    
    if (cameraStatus.isDenied || storageStatus.isDenied) {
      debugPrint('Requesting camera and storage permissions');
      
      // Request both permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.storage,
      ].request();
      
      return statuses[Permission.camera]!.isGranted && 
             statuses[Permission.storage]!.isGranted;
    }
    
    return cameraStatus.isGranted && storageStatus.isGranted;
  }

  /// Pick an image from the gallery
  /// Returns the path to the saved image
  Future<String?> pickImageFromGallery() async {
    // Check permissions first
    bool hasPermission = await _checkPermissions();
    if (!hasPermission) {
      debugPrint('Permission denied for gallery access');
      return null;
    }
    
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (image != null) {
      return _saveImage(image);
    }
    return null;
  }

  /// Take a photo with the camera
  /// Returns the path to the saved image
  Future<String?> takePhoto() async {
    // Check permissions first
    bool hasPermission = await _checkPermissions();
    if (!hasPermission) {
      debugPrint('Permission denied for camera access');
      return null;
    }
    
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (photo != null) {
      return _saveImage(photo);
    }
    return null;
  }
  
  /// Save the image to the app's documents directory and return the path
  /// For web, converts blob URLs to base64 data URLs for persistence
  Future<String> _saveImage(XFile image) async {
    try {
      // Ensure the cache service is initialized
      ImageCacheService cacheService = ImageCacheService.instance;
      
      // First read the image bytes to ensure we can access the source
      final bytes = await image.readAsBytes();
      debugPrint('Successfully read ${bytes.length} bytes from source image');
      
      if (kIsWeb) {
        debugPrint('Web image path: ${image.path}');
        
        // Determine the mime type from the file extension
        String mimeType = 'image/jpeg'; // Default
        final String imagePath = image.path;
        if (imagePath.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        } else if (imagePath.toLowerCase().endsWith('.gif')) {
          mimeType = 'image/gif';
        } else if (imagePath.toLowerCase().endsWith('.webp')) {
          mimeType = 'image/webp';
        }
        
        // Convert to base64 data URL
        final base64Image = base64Encode(bytes);
        final dataUrl = 'data:$mimeType;base64,$base64Image';
        
        debugPrint('Converted image to data URL (length: ${dataUrl.length})');
        return dataUrl;
      } else {
        // For mobile platforms
        
        // Generate a unique filename
        final uuid = const Uuid().v4();
        final String imageName = image.name;
        String extension = 'jpg'; // Default extension
        
        // Try to get the extension from the image name or path
        if (imageName.contains('.')) {
          extension = imageName.split('.').last.toLowerCase();
        } else {
          final String imagePath = image.path;
          if (imagePath.contains('.')) {
            extension = imagePath.split('.').last.toLowerCase();
          }
        }
        
        final filename = 'vocabulary_image_$uuid.$extension';
        debugPrint('Saving image with filename: $filename');
        
        // First try external storage on Android for better accessibility
        if (Platform.isAndroid) {
          try {
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              final imagesDir = Directory('${externalDir.path}/visual_vocabularies/images');
              if (!await imagesDir.exists()) {
                await imagesDir.create(recursive: true);
              }
              
              final filePath = '${imagesDir.path}/$filename';
              final file = File(filePath);
              await file.writeAsBytes(bytes);
              
              if (await file.exists()) {
                debugPrint('Image saved to external storage: $filePath');
                return filePath;
              }
            }
          } catch (e) {
            debugPrint('Error saving to external storage: $e');
          }
        }
        
        // Fall back to app documents directory
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final imagesDir = Directory('${appDir.path}/images');
          if (!await imagesDir.exists()) {
            await imagesDir.create(recursive: true);
          }
          
          final filePath = '${imagesDir.path}/$filename';
          final file = File(filePath);
          await file.writeAsBytes(bytes);
          
          if (await file.exists()) {
            debugPrint('Image saved to app documents: $filePath');
            return filePath;
          }
        } catch (e) {
          debugPrint('Error saving to app documents: $e');
        }
        
        // If all else fails, convert to a data URL
        final base64Image = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64Image';
        debugPrint('Fallback: Converted to data URL');
        return dataUrl;
      }
    } catch (e) {
      debugPrint('Critical error in _saveImage: $e');
      
      // Return original path as last resort
      return image.path;
    }
  }
  
  /// Show a dialog to choose between gallery and camera
  static Future<String?> showImageSourceDialog(BuildContext context) async {
    final ImagePickerService service = ImagePickerService();
    
    return showDialog<String?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context, await service.pickImageFromGallery());
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context, await service.takePhoto());
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }
} 