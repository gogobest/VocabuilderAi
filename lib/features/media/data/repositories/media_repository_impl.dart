import '../../domain/entities/media_item.dart';
import '../../domain/repositories/media_repository.dart';
import 'package:hive/hive.dart';
import '../models/media_item_model.dart';
import 'package:flutter/foundation.dart';

class MediaRepositoryImpl implements MediaRepository {
  static const String _boxName = 'media_items';
  
  @override
  Future<void> addMediaItem(MediaItem item) async {
    try {
      final box = await Hive.openBox<MediaItemModel>(_boxName);
      final model = MediaItemModel.fromEntity(item);
      await box.put(item.id, model);
    } catch (e) {
      debugPrint('Error adding media item: $e');
      rethrow;
    }
  }

  @override
  Future<MediaItem?> getMediaItemById(String id) async {
    try {
      final box = await Hive.openBox<MediaItemModel>(_boxName);
      final model = box.get(id);
      return model?.toEntity();
    } catch (e) {
      debugPrint('Error getting media item by ID: $e');
      return null;
    }
  }

  @override
  Future<List<MediaItem>> getAllMediaItems() async {
    try {
      final box = await Hive.openBox<MediaItemModel>(_boxName);
      return box.values.map((model) => model.toEntity()).toList();
    } catch (e) {
      debugPrint('Error getting all media items: $e');
      return [];
    }
  }

  @override
  Future<List<MediaItem>> getMediaItemsByTitle(String title) async {
    try {
      final box = await Hive.openBox<MediaItemModel>(_boxName);
      return box.values
          .where((model) => model.title == title)
          .map((model) => model.toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting media items by title: $e');
      return [];
    }
  }

  @override
  Future<List<MediaItem>> getMediaItemsBySeason(String title, int season) async {
    try {
      final box = await Hive.openBox<MediaItemModel>(_boxName);
      return box.values
          .where((model) => model.title == title && model.season == season)
          .map((model) => model.toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting media items by season: $e');
      return [];
    }
  }

  @override
  Future<List<MediaItem>> getMediaItemsByEpisode(String title, int season, int episode) async {
    try {
      final box = await Hive.openBox<MediaItemModel>(_boxName);
      return box.values
          .where((model) => 
              model.title == title && 
              model.season == season && 
              model.episode == episode)
          .map((model) => model.toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting media items by episode: $e');
      return [];
    }
  }

  @override
  Future<void> deleteMediaItem(String id) async {
    try {
      final box = await Hive.openBox<MediaItemModel>(_boxName);
      await box.delete(id);
    } catch (e) {
      debugPrint('Error deleting media item: $e');
      rethrow;
    }
  }
} 