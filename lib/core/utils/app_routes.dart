import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/pages/ai_generate_words_page.dart';
import 'package:visual_vocabularies/features/subtitle_extractor/presentation/pages/select_subtitle_page.dart';
import 'package:visual_vocabularies/features/media/presentation/pages/media_center_page.dart';
import 'package:visual_vocabularies/features/media/data/services/media_service.dart';
import 'package:visual_vocabularies/features/media/data/repositories/media_repository_impl.dart';
import 'package:visual_vocabularies/features/synonyms_game/presentation/pages/synonyms_game_page.dart';
import 'package:visual_vocabularies/features/synonyms_game/presentation/pages/marked_synonyms_game_page.dart';
import 'package:visual_vocabularies/features/media/presentation/pages/media_discovery_page.dart';

/// Class containing routes for grammar tenses features
class TensesRoutes {
  // Private constructor to prevent instantiation
  TensesRoutes._();

  /// Route for grammar tenses list page
  static const String tensesListRoute = '/tenses';

  /// Route for tense details page with parameter
  static const String tenseDetailsRoute = '/tenses/:id';

  /// Get routes for grammar tenses feature
  static List<RouteBase> getTensesRoutes() {
    return [
      GoRoute(
        path: tensesListRoute,
        builder: (context, state) {
          // Use a placeholder widget until the actual page is implemented
          return _TensesListPlaceholder();
        },
      ),
      GoRoute(
        path: tenseDetailsRoute,
        builder: (context, state) {
          final tenseId = state.pathParameters['id'] ?? '';
          // Use a placeholder widget until the actual page is implemented
          return _TenseDetailsPlaceholder(tenseId: tenseId);
        },
      ),
    ];
  }
}

/// Placeholder for the tenses list page
class _TensesListPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grammar Tenses')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              'Grammar Tenses',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('This feature is coming soon!'),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for the tense details page
class _TenseDetailsPlaceholder extends StatelessWidget {
  final String tenseId;
  
  const _TenseDetailsPlaceholder({required this.tenseId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tense Details')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Tense: $tenseId',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Detailed information coming soon!'),
          ],
        ),
      ),
    );
  }
}

/// Builds the app routes for Go Router
class AppRoutes {
  /// Create GoRouter configuration
  static final router = GoRouter(
    initialLocation: AppConstants.splashRoute,
    routes: [
      // ... existing routes ...
      
      /// AI Word Generator route
      GoRoute(
        path: AppConstants.aiGeneratorRoute,
        builder: (context, state) => const AiGenerateWordsPage(),
      ),
      
      /// Select Subtitle route (individual access still available)
      GoRoute(
        path: AppConstants.subtitleExtractorRoute,
        builder: (context, state) => const SelectSubtitlePage(isEmbedded: false),
      ),
      
      /// Media Center route (combined media features)
      GoRoute(
        path: AppConstants.mediaRoute,
        builder: (context, state) => const MediaCenterPage(),
      ),
      
      /// Media Discovery route (direct access)
      GoRoute(
        path: AppConstants.mediaDiscoveryRoute,
        builder: (context, state) => MediaDiscoveryPage(
          mediaService: MediaService(MediaRepositoryImpl()),
          isEmbedded: false,
        ),
      ),
      
      /// Synonyms Game route
      GoRoute(
        path: AppConstants.synonymsGameRoute,
        builder: (context, state) {
          final categoryFilter = state.uri.queryParameters['category'];
          return SynonymsGamePage(
            categoryFilter: categoryFilter,
          );
        },
      ),
      
      /// Marked Synonyms Game route
      GoRoute(
        path: AppConstants.markedSynonymsGameRoute,
        builder: (context, state) {
          final categoryFilter = state.uri.queryParameters['category'];
          return MarkedSynonymsGamePage(
            categoryFilter: categoryFilter,
          );
        },
      ),
      
      // ... existing code ...
    ],
  );
} 