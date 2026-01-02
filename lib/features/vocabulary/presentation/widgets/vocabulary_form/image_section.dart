import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:visual_vocabularies/features/vocabulary/data/services/vocabulary_image_service.dart';

/// A widget for displaying and managing vocabulary item images
class ImageSection extends StatefulWidget {
  /// Whether an image is currently loading
  final bool isLoading;
  
  /// URL of the selected image
  final String? selectedImageUrl;
  
  /// Emoji to display with the image
  final String emoji;
  
  /// Service for handling images
  final VocabularyImageService imageService;
  
  /// Callbacks
  final VoidCallback onPickImage;
  final VoidCallback onTakePhoto;
  final VoidCallback onGenerateImage;
  final VoidCallback onClearImage;
  final VoidCallback? onSearchGif;
  final VoidCallback? onGenerateEmoji;
  
  /// Whether actions are disabled
  final bool disabled;

  /// Constructor for ImageSection
  const ImageSection({
    super.key,
    required this.isLoading,
    required this.selectedImageUrl,
    required this.emoji,
    required this.imageService,
    required this.onPickImage,
    required this.onTakePhoto,
    required this.onGenerateImage,
    required this.onClearImage,
    this.onSearchGif,
    this.onGenerateEmoji,
    this.disabled = false,
  });

  @override
  State<ImageSection> createState() => _ImageSectionState();
}

class _ImageSectionState extends State<ImageSection> {
  String _selectedSource = 'gallery';

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.selectedImageUrl != null && widget.selectedImageUrl!.isNotEmpty;
    final hasGif = hasImage && widget.imageService.isAnimatedGif(widget.selectedImageUrl);
    final hasEmoji = widget.emoji.isNotEmpty;
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and emoji indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Visual Representation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasEmoji)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          widget.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: widget.onGenerateEmoji,
                          child: Icon(Icons.refresh, color: Colors.amber.shade800, size: 14),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Main image preview area
            GestureDetector(
              onTap: widget.disabled ? null : _getDefaultAction(),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getBorderColor(),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: widget.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image content
                          _buildImageContent(),
                          
                          // Type indicator
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: _buildTypeIndicator(),
                          ),
                          
                          // Clear button
                          if (hasImage)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                color: Colors.white.withOpacity(0.8),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: () {
                                    // Ensure we properly clear the image
                                    widget.onClearImage();
                                    // Force a rebuild immediately
                                    setState(() {
                                      debugPrint('Clearing image, emoji visibility state: ${widget.emoji.isNotEmpty}');
                                    });
                                  },
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6.0),
                                    child: Icon(Icons.delete, color: Colors.red, size: 20),
                                  ),
                                ),
                              ),
                            ),
                          
                          // Empty state overlay
                          if (!hasImage && !hasEmoji)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getIconForSource(_selectedSource),
                                    size: 48, 
                                    color: Colors.grey.shade400
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add ${_getLabelForSource(_selectedSource)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Source selector - segmented button
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageSourceButton(
                        context,
                        Icons.photo_library,
                        'Gallery',
                        () {
                          if (widget.disabled) return;
                          setState(() { _selectedSource = 'gallery'; });
                          widget.onPickImage();
                        },
                        _selectedSource == 'gallery' ? _getColorForSource('gallery') : Colors.grey.shade600,
                      ),
                      if (!kIsWeb)
                        _buildImageSourceButton(
                          context,
                          Icons.camera_alt,
                          'Camera',
                          () {
                            if (widget.disabled) return;
                            setState(() { _selectedSource = 'camera'; });
                            widget.onTakePhoto();
                          },
                          _selectedSource == 'camera' ? _getColorForSource('camera') : Colors.grey.shade600,
                        ),
                      if (widget.onSearchGif != null)
                        _buildImageSourceButton(
                          context,
                          Icons.gif,
                          'GIF',
                          () {
                            if (widget.disabled) return;
                            setState(() { _selectedSource = 'gif'; });
                            widget.onSearchGif!();
                          },
                          _selectedSource == 'gif' ? _getColorForSource('gif') : Colors.grey.shade600,
                        ),
                      if (widget.onGenerateEmoji != null)
                        _buildImageSourceButton(
                          context,
                          Icons.emoji_emotions,
                          'Emoji',
                          () {
                            if (widget.disabled) return;
                            setState(() { _selectedSource = 'emoji'; });
                            widget.onGenerateEmoji!();
                          },
                          _selectedSource == 'emoji' ? _getColorForSource('emoji') : Colors.grey.shade600,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build a button for image source selection
  Widget _buildImageSourceButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    Color iconColor,
  ) {
    final bool isSelected = iconColor != Colors.grey.shade600;
    
    return Material(
      color: isSelected ? iconColor.withOpacity(0.15) : Colors.transparent,
      shape: const CircleBorder(),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Execute action based on selected source
  void _executeSourceAction(String source) {
    switch (source) {
      case 'gallery':
        widget.onPickImage();
        break;
      case 'camera':
        widget.onTakePhoto();
        break;
      case 'gif':
        if (widget.onSearchGif != null) widget.onSearchGif!();
        break;
      case 'emoji':
        if (widget.onGenerateEmoji != null) widget.onGenerateEmoji!();
        break;
    }
  }
  
  /// Get the default action when tapping on the image area
  VoidCallback? _getDefaultAction() {
    if (widget.disabled) return null;
    
    final hasImage = widget.selectedImageUrl != null && widget.selectedImageUrl!.isNotEmpty;
    final hasEmoji = widget.emoji.isNotEmpty;
    
    // If we have an image, show it in fullscreen or edit it
    if (hasImage) {
      // If it's a GIF, let's search for another GIF
      if (widget.imageService.isAnimatedGif(widget.selectedImageUrl)) {
        return widget.onSearchGif;
      }
      // For other images, allow picking a new one
      return widget.onPickImage;
    }
    
    // If we have emoji but no image, regenerate emoji
    if (hasEmoji && !hasImage) {
      return widget.onGenerateEmoji;
    }
    
    // Default to the currently selected source action
    return () => _executeSourceAction(_selectedSource);
  }
  
  /// Get border color based on content
  Color _getBorderColor() {
    if (widget.isLoading) {
      return Colors.blue.shade200;
    }
    
    if (widget.selectedImageUrl != null && widget.selectedImageUrl!.isNotEmpty) {
      if (widget.imageService.isAnimatedGif(widget.selectedImageUrl)) {
        return Colors.purple.shade200;
      }
      return Colors.blue.shade200;
    }
    
    if (widget.emoji.isNotEmpty) {
      return Colors.amber.shade200;
    }
    
    return Colors.grey.shade300;
  }
  
  /// Get color for the selected source
  Color _getColorForSource(String source) {
    switch (source) {
      case 'gallery':
        return Colors.blue;
      case 'camera':
        return Colors.green;
      case 'gif':
        return Colors.purple;
      case 'emoji':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
  
  /// Get icon for the selected source
  IconData _getIconForSource(String source) {
    switch (source) {
      case 'gallery':
        return Icons.photo_library;
      case 'camera':
        return Icons.camera_alt;
      case 'gif':
        return Icons.gif;
      case 'emoji':
        return Icons.emoji_emotions;
      default:
        return Icons.image;
    }
  }
  
  /// Get label for the selected source
  String _getLabelForSource(String source) {
    switch (source) {
      case 'gallery':
        return 'from Gallery';
      case 'camera':
        return 'from Camera';
      case 'gif':
        return 'GIF';
      case 'emoji':
        return 'Emoji';
      default:
        return 'Image';
    }
  }
  
  /// Build an indicator for the type of visual representation
  Widget _buildTypeIndicator() {
    // Determine what type of content we're showing
    String label = 'None';
    IconData icon = Icons.image_not_supported;
    Color bgColor = Colors.grey;
    
    if (widget.selectedImageUrl != null && widget.selectedImageUrl!.isNotEmpty) {
      if (widget.imageService.isAnimatedGif(widget.selectedImageUrl)) {
        label = 'GIF';
        icon = Icons.animation;
        bgColor = Colors.purple;
      } else if (widget.imageService.isPng(widget.selectedImageUrl) || 
                widget.imageService.isNetworkImage(widget.selectedImageUrl)) {
        label = 'Image';
        icon = Icons.image;
        bgColor = Colors.blue;
      } else {
        label = 'File';
        icon = Icons.insert_drive_file;
        bgColor = Colors.green;
      }
    } else if (widget.emoji.isNotEmpty) {
      label = 'Emoji';
      icon = Icons.emoji_emotions;
      bgColor = Colors.amber;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  /// Build the image or emoji content based on what's available
  Widget _buildImageContent() {
    final hasImage = widget.selectedImageUrl != null && widget.selectedImageUrl!.isNotEmpty;
    final hasEmoji = widget.emoji.isNotEmpty;
    
    if (hasImage) {
      // Display the selected image
      return _buildImageWithSafety(widget.selectedImageUrl!);
    } else if (hasEmoji) {
      // Display emoji if we have one and no image
      debugPrint('Displaying emoji: ${widget.emoji} because no image is available');
      return Center(
        child: Text(
          widget.emoji,
          style: const TextStyle(fontSize: 80),
        ),
      );
    } else {
      // Empty state
      return Container(color: Colors.grey[50]);
    }
  }
  
  /// Build an error display for image loading failures
  Widget _buildErrorDisplay(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 32, color: Colors.red.shade300),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.red.shade300,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Get a color based on the emoji
  Color _getColorForEmoji(String emoji) {
    // Simple hash-based coloring
    int hash = 0;
    for (var i = 0; i < emoji.length; i++) {
      hash = emoji.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Generate colors from categories
    if (emoji.contains('🐕') || emoji.contains('🐈') || 
        emoji.contains('🐢') || emoji.contains('🦋')) {
      return Colors.green;
    } else if (emoji.contains('🌳') || emoji.contains('🌸') || 
               emoji.contains('☀️') || emoji.contains('🌙')) {
      return Colors.teal;
    } else if (emoji.contains('🍎') || emoji.contains('🍕') || 
               emoji.contains('🍰') || emoji.contains('🍖')) {
      return Colors.orange;
    } else if (emoji.contains('😊') || emoji.contains('😢') || 
               emoji.contains('😱') || emoji.contains('😂')) {
      return Colors.amber;
    } else {
      // Default based on hash
      final r = (hash & 0xFF0000) >> 16;
      final g = (hash & 0x00FF00) >> 8;
      final b = hash & 0x0000FF;
      return Color.fromARGB(255, r, g, b);
    }
  }
  
  Widget _buildImageWithSafety(String imageUrl) {
    try {
      // Handle animated GIFs differently
      if (widget.imageService.isAnimatedGif(imageUrl)) {
        return Image.network(
          imageUrl,
          fit: BoxFit.contain,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return child;
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading GIF',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        );
      }
      
      // Handle regular images based on type
      if (widget.imageService.isNetworkImage(imageUrl)) {
        return Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading image',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        );
      } else if (kIsWeb) {
        // For web platforms, all images render as network images
        return Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading image',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        // For non-web platforms, handle local files
        try {
          final file = File(imageUrl);
          return Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading image file',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            },
          );
        } catch (e) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'Invalid image file',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error displaying image: $e');
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Error displaying image',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
  }
} 