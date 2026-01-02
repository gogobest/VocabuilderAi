import 'package:visual_vocabularies/features/media/domain/entities/media_item.dart';
import 'package:hive/hive.dart';

part 'media_item_model.g.dart';

@HiveType(typeId: 2) // Make sure this type ID is unique across your app
class MediaItemModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final int? season;
  
  @HiveField(3)
  final int? episode;
  
  @HiveField(4)
  final String? coverImageUrl;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final List<String> vocabularyItemIds;
  
  @HiveField(7)
  final String? author;
  
  @HiveField(8)
  final int? chapter;

  MediaItemModel({
    required this.id,
    required this.title,
    this.season,
    this.episode,
    this.coverImageUrl,
    required this.createdAt,
    required this.vocabularyItemIds,
    this.author,
    this.chapter,
  });

  factory MediaItemModel.fromJson(Map<String, dynamic> json) {
    return MediaItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      season: json['season'] as int?,
      episode: json['episode'] as int?,
      coverImageUrl: json['coverImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      vocabularyItemIds: List<String>.from(json['vocabularyItemIds'] as List),
      author: json['author'] as String?,
      chapter: json['chapter'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'season': season,
      'episode': episode,
      'coverImageUrl': coverImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'vocabularyItemIds': vocabularyItemIds,
      'author': author,
      'chapter': chapter,
    };
  }

  factory MediaItemModel.fromEntity(MediaItem entity) {
    return MediaItemModel(
      id: entity.id,
      title: entity.title,
      season: entity.season,
      episode: entity.episode,
      coverImageUrl: entity.coverImageUrl,
      createdAt: entity.createdAt ?? DateTime.now(),
      vocabularyItemIds: entity.vocabularyItemIds,
      author: entity.author,
      chapter: entity.chapter,
    );
  }

  MediaItem toEntity() {
    return MediaItem(
      id: id,
      title: title,
      season: season,
      episode: episode,
      coverImageUrl: coverImageUrl,
      createdAt: createdAt,
      vocabularyItemIds: vocabularyItemIds,
      author: author,
      chapter: chapter,
    );
  }
} 