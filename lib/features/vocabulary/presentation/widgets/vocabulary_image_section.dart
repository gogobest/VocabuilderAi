import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:visual_vocabularies/features/vocabulary/data/services/vocabulary_image_service.dart';

/// Widget for handling vocabulary item images
class VocabularyImageSection extends StatefulWidget {
  /// Currently selected image URL
  final String? selectedImageUrl;
  
  /// Word for AI image generation
  final String word;
  
  /// Meaning for AI image generation
  final String meaning;
  
  /// Callback when image is selected or changed
  final Function(String?) onImageSelected;

  /// Constructor for VocabularyImageSection
  const VocabularyImageSection({
    super.key,
    this.selectedImageUrl,
    required this.word,
    required this.meaning,
    required this.onImageSelected,
  });

  @override
  State<VocabularyImageSection> createState() => _VocabularyImageSectionState();
}

class _VocabularyImageSectionState extends State<VocabularyImageSection> {
  final VocabularyImageService _imageService = VocabularyImageService();
  bool _isGeneratingImage = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Text(
          'Image',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Image preview
        if (widget.selectedImageUrl != null && widget.selectedImageUrl!.isNotEmpty)
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWidget(widget.selectedImageUrl!),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: () {
                      widget.onImageSelected(null);
                    },
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('No image selected'),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Image buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Pick from gallery button
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
              onPressed: _pickImageFromGallery,
            ),
            
            // Take photo button - only on mobile
            if (!kIsWeb)
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                onPressed: _takePhoto,
              ),
            
            // Generate AI image button
            ElevatedButton.icon(
              icon: _isGeneratingImage 
                ? const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.auto_awesome),
              label: const Text('Generate'),
              onPressed: widget.word.isEmpty ? null : _generateImage,
            ),
          ],
        ),
      ],
    );
  }

  /// Build the image widget based on the source type (file or network)
  Widget _buildImageWidget(String imagePath) {
    if (_imageService.isNetworkImage(imagePath)) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
          );
        },
      );
    }
  }

  /// Pick an image from the device gallery
  Future<void> _pickImageFromGallery() async {
    final imagePath = await _imageService.pickImageFromGallery();
    if (imagePath != null) {
      widget.onImageSelected(imagePath);
    }
  }

  /// Take a photo using the device camera
  Future<void> _takePhoto() async {
    final imagePath = await _imageService.takePhoto();
    if (imagePath != null) {
      widget.onImageSelected(imagePath);
    }
  }

  /// Generate an image using AI based on the word and meaning
  Future<void> _generateImage() async {
    if (widget.word.isEmpty) return;
    
    setState(() {
      _isGeneratingImage = true;
    });
    
    try {
      final imageUrl = await _imageService.generateImageForWord(
        widget.word, 
        widget.meaning,
      );
      
      if (imageUrl != null) {
        widget.onImageSelected(imageUrl);
      }
    } finally {
      setState(() {
        _isGeneratingImage = false;
      });
    }
  }
} 