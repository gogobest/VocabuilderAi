import '../entities/media_item.dart';

abstract class MediaRepository {
  Future<void> addMediaItem(MediaItem item);
  Future<MediaItem?> getMediaItemById(String id);
  Future<List<MediaItem>> getAllMediaItems();
  Future<List<MediaItem>> getMediaItemsByTitle(String title);
  Future<List<MediaItem>> getMediaItemsBySeason(String title, int season);
  Future<List<MediaItem>> getMediaItemsByEpisode(String title, int season, int episode);
  Future<void> deleteMediaItem(String id);
} 