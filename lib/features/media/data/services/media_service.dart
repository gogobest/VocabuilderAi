import '../../domain/entities/media_item.dart';
import '../../domain/repositories/media_repository.dart';

class MediaService {
  final MediaRepository repository;

  MediaService(this.repository);

  Future<void> addMediaItem(MediaItem item) => repository.addMediaItem(item);
  Future<MediaItem?> getMediaItemById(String id) => repository.getMediaItemById(id);
  Future<List<MediaItem>> getAllMediaItems() => repository.getAllMediaItems();
  Future<List<MediaItem>> getMediaItemsByTitle(String title) => repository.getMediaItemsByTitle(title);
  Future<List<MediaItem>> getMediaItemsBySeason(String title, int season) => repository.getMediaItemsBySeason(title, season);
  Future<List<MediaItem>> getMediaItemsByEpisode(String title, int season, int episode) => repository.getMediaItemsByEpisode(title, season, episode);
  Future<void> deleteMediaItem(String id) => repository.deleteMediaItem(id);
} 