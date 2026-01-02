import 'package:equatable/equatable.dart';

/// Represents a media item (Movie/TV Show, season, episode) with its vocabulary.
class MediaItem extends Equatable {
  final String id;
  final String title; // Movie or TV Show title
  final int? season;
  final int? episode;
  final String? coverImageUrl;
  final DateTime createdAt;
  final List<String> vocabularyItemIds; // List of vocabulary item IDs
  final String? author; // Book author
  final int? chapter; // Book chapter

  MediaItem({
    required this.id,
    required this.title,
    this.season,
    this.episode,
    this.coverImageUrl,
    DateTime? createdAt,
    required this.vocabularyItemIds,
    this.author,
    this.chapter,
  }) : createdAt = createdAt ?? DateTime.now();

  MediaItem copyWith({
    String? id,
    String? title,
    int? season,
    int? episode,
    String? coverImageUrl,
    DateTime? createdAt,
    List<String>? vocabularyItemIds,
    String? author,
    int? chapter,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      vocabularyItemIds: vocabularyItemIds ?? this.vocabularyItemIds,
      author: author ?? this.author,
      chapter: chapter ?? this.chapter,
    );
  }

  @override
  List<Object?> get props => [id, title, season, episode, coverImageUrl, createdAt, vocabularyItemIds, author, chapter];
} 