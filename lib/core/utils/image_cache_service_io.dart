class ImageCacheService {
  static final ImageCacheService instance = ImageCacheService._();

  ImageCacheService._();

  Future<String> processImageUrl(String url) async {
    // Non-web logic (e.g., Android, iOS)
    return url; // Example: Return the URL as-is
  }
}