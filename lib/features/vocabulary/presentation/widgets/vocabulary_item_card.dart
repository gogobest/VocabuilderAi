import 'package:flutter/material.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/utils/tracking_service.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';

/// A card widget that displays a vocabulary item
class VocabularyItemCard extends StatelessWidget {
  /// The vocabulary item to display
  final VocabularyItem item;

  /// Callback when the card is tapped
  final VoidCallback onTap;

  /// Callback when the edit button is tapped
  final VoidCallback? onEdit;

  /// Callback when the delete button is tapped
  final VoidCallback? onDelete;

  /// Text to highlight in the card (for search results)
  final String? highlightedText;

  /// Constructor for VocabularyItemCard
  const VocabularyItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.highlightedText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackingService = sl<TrackingService>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            trackingService.trackButtonClick('Vocabulary Card', screen: 'Vocabulary List');
            trackingService.trackVocabularyInteraction('Tap card', word: item.word);
            onTap();
          }
        },
        onLongPress: () {
          trackingService.trackVocabularyInteraction('Long press card', word: item.word);
          _showContextMenu(context, trackingService);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.wordEmoji != null && item.wordEmoji!.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: Text(
                        item.wordEmoji!,
                        style: const TextStyle(
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ] else if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: _buildThumbnail(item.imageUrl!),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? theme.colorScheme.surfaceVariant
                            : theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.word.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          item.word,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(width: 8),
                        if (item.partOfSpeech != null && item.partOfSpeech!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPartOfSpeechColor(item.partOfSpeech!, theme, isDarkMode),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.partOfSpeech!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white.withOpacity(0.95) : Colors.black.withOpacity(0.8),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (item.grammarTense != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.grammarTense!,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        trackingService.trackButtonClick('Edit', screen: 'Vocabulary Card');
                        trackingService.trackVocabularyInteraction('Edit from button', word: item.word);
                        onEdit!();
                      },
                      tooltip: 'Edit',
                    ),
                  if (onDelete != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          trackingService.trackButtonClick('Delete', screen: 'Vocabulary Card');
                          trackingService.trackVocabularyInteraction('Delete from button', word: item.word);
                          onDelete!();
                        },
                        tooltip: 'Delete',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.meaning,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.partOfSpeechNote != null && item.partOfSpeechNote!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.partOfSpeechNote!,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(item.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Show a context menu for long press
  void _showContextMenu(BuildContext context, TrackingService trackingService) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + renderBox.size.height,
        position.dx + renderBox.size.width,
        position.dy,
      ),
      items: [
        if (onEdit != null)
          PopupMenuItem(
            onTap: () {
              trackingService.trackButtonClick('Edit (Menu)', screen: 'Vocabulary Card');
              trackingService.trackVocabularyInteraction('Edit from context menu', word: item.word);
              // Need to schedule a callback as onTap will dismiss the menu
              WidgetsBinding.instance.addPostFrameCallback((_) => onEdit!());
            },
            child: const Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            onTap: () {
              trackingService.trackButtonClick('Delete (Menu)', screen: 'Vocabulary Card');
              trackingService.trackVocabularyInteraction('Delete from context menu', word: item.word);
              // Need to schedule a callback as onTap will dismiss the menu
              WidgetsBinding.instance.addPostFrameCallback((_) => onDelete!());
            },
            child: const Row(
              children: [
                Icon(Icons.delete),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
      ],
    );
  }

  /// Format date as "Jan 1, 2023" or relative to today
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Returns appropriate color for part of speech tag
  Color _getPartOfSpeechColor(String partOfSpeech, ThemeData theme, bool isDarkMode) {
    final pos = partOfSpeech.toLowerCase();
    
    if (pos.contains('noun')) {
      return isDarkMode ? Colors.blue[700]! : Colors.blue[100]!;
    } else if (pos.contains('verb')) {
      return isDarkMode ? Colors.green[700]! : Colors.green[100]!;
    } else if (pos.contains('adjective')) {
      return isDarkMode ? Colors.purple[700]! : Colors.purple[100]!;
    } else if (pos.contains('adverb')) {
      return isDarkMode ? Colors.deepPurple[700]! : Colors.deepPurple[100]!;
    } else if (pos.contains('phrasal')) {
      return isDarkMode ? Colors.orange[700]! : Colors.orange[100]!;
    } else if (pos.contains('idiom') || pos.contains('expression') || pos.contains('phrase')) {
      return isDarkMode ? Colors.amber[700]! : Colors.amber[100]!;
    } else if (pos.contains('preposition')) {
      return isDarkMode ? Colors.cyan[700]! : Colors.cyan[100]!;
    } else if (pos.contains('pronoun')) {
      return isDarkMode ? Colors.indigo[700]! : Colors.indigo[100]!;
    } else if (pos.contains('conjunction')) {
      return isDarkMode ? Colors.pink[700]! : Colors.pink[100]!;
    } else if (pos.contains('article') || pos.contains('determiner')) {
      return isDarkMode ? Colors.teal[700]! : Colors.teal[100]!;
    }
    
    // Default color
    return isDarkMode ? theme.colorScheme.tertiaryContainer : theme.colorScheme.secondaryContainer;
  }

  /// Build a thumbnail from URL
  Widget _buildThumbnail(String url) {
    // Implementation of _buildThumbnail method
    // This is a placeholder and should be replaced with the actual implementation
    return Image.network(url);
  }
} 