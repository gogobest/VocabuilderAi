import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/app_routes.dart';
import 'package:visual_vocabularies/features/home/presentation/pages/home_page.dart';
import 'package:visual_vocabularies/features/home/presentation/pages/splash_screen.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/pages/add_edit_word_page.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/pages/all_words_page.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/pages/word_details_page.dart';
import 'package:visual_vocabularies/features/flashcards/presentation/pages/flashcards_page.dart';
import 'package:visual_vocabularies/features/categories/presentation/pages/categories_page.dart';
import 'package:visual_vocabularies/features/settings/presentation/pages/settings_page.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/pages/ai_generate_words_page.dart';
import 'package:visual_vocabularies/features/subtitle_extractor/presentation/pages/select_subtitle_page.dart';
import 'package:visual_vocabularies/features/media/presentation/pages/media_discovery_page.dart';
import 'package:visual_vocabularies/features/media/data/services/media_service.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/features/subtitle_extractor/presentation/widgets/read_mode_page.dart';
import 'package:visual_vocabularies/features/subtitle_extractor/presentation/widgets/highlighted_words_review_page.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/pages/data_export_import_page.dart';
import 'package:visual_vocabularies/features/synonyms_game/presentation/pages/synonyms_game_page.dart';
import 'package:visual_vocabularies/features/synonyms_game/presentation/pages/marked_synonyms_game_page.dart';
import 'package:visual_vocabularies/features/antonyms_game/presentation/pages/antonyms_game_page.dart';
import 'package:visual_vocabularies/features/antonyms_game/presentation/pages/marked_antonyms_game_page.dart';
import 'package:visual_vocabularies/features/tenses_game/presentation/pages/tenses_game_page.dart';
import 'package:visual_vocabularies/features/tenses_game/presentation/pages/marked_tenses_game_page.dart';
import 'package:visual_vocabularies/features/games/presentation/pages/games_page.dart';
import 'package:visual_vocabularies/features/media/presentation/pages/media_center_page.dart';
import 'package:visual_vocabularies/features/tenses_game/presentation/pages/saved_tense_review_cards_page.dart';
import 'package:visual_vocabularies/features/media/presentation/pages/ai_answers_page.dart';

/// Router configuration for the app
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Creates router configuration with all routes
  static GoRouter getRouter() {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/splash',
      // Add redirect to ensure navigation always starts at home after splash
      redirect: (context, state) {
        // Don't redirect splash or home route
        if (state.matchedLocation == '/splash' || 
            state.matchedLocation == AppConstants.homeRoute) {
          return null;
        }
        
        return null;
      },
      routes: [
        // Splash
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        
        // Home
        GoRoute(
          path: AppConstants.homeRoute,
          builder: (context, state) => const HomePage(),
        ),
        
        // Categories
        GoRoute(
          path: AppConstants.categoriesRoute,
          builder: (context, state) => const CategoriesPage(),
        ),
        
        // Flashcards
        GoRoute(
          path: AppConstants.flashcardsRoute,
          builder: (context, state) {
            // Get category from query parameter
            final category = state.uri.queryParameters['category'];
            return FlashcardsPage(categoryFilter: category);
          },
        ),
        
        // All Words
        GoRoute(
          path: AppConstants.allWordsRoute,
          builder: (context, state) {
            // Get category from query parameter
            final category = state.uri.queryParameters['category'];
            return AllWordsPage(categoryFilter: category);
          },
        ),
        
        // Word Details
        GoRoute(
          path: '${AppConstants.wordDetailsRoute}/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return WordDetailsPage(id: id);
          },
        ),
        
        // Add Word
        GoRoute(
          path: AppConstants.addEditWordRoute,
          builder: (context, state) {
            // Get category from query parameter for pre-selection
            final preselectedCategory = state.uri.queryParameters['category'];
            return AddEditWordPage(categoryFilter: preselectedCategory);
          },
        ),
        
        // Edit Word
        GoRoute(
          path: '${AppConstants.addEditWordRoute}/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return AddEditWordPage(id: id);
          },
        ),
        
        // Settings
        GoRoute(
          path: AppConstants.settingsRoute,
          builder: (context, state) => const SettingsPage(),
        ),
        
        // AI Generator
        GoRoute(
          path: AppConstants.aiGeneratorRoute,
          builder: (context, state) => const AiGenerateWordsPage(),
        ),
        
        // Synonyms Game
        GoRoute(
          path: AppConstants.synonymsGameRoute,
          builder: (context, state) {
            final categoryFilter = state.uri.queryParameters['category'];
            return SynonymsGamePage(
              categoryFilter: categoryFilter,
              onlyMarkedSynonyms: false,
            );
          },
        ),
        
        // Marked Synonyms Game
        GoRoute(
          path: AppConstants.markedSynonymsGameRoute,
          builder: (context, state) {
            final categoryFilter = state.uri.queryParameters['category'];
            return MarkedSynonymsGamePage(
              categoryFilter: categoryFilter,
            );
          },
        ),
        
        // Antonyms Game
        GoRoute(
          path: AppConstants.antonymsGameRoute,
          builder: (context, state) {
            final categoryFilter = state.uri.queryParameters['category'];
            return AntonymsGamePage(
              categoryFilter: categoryFilter,
              onlyMarkedAntonyms: false,
            );
          },
        ),
        
        // Marked Antonyms Game
        GoRoute(
          path: AppConstants.markedAntonymsGameRoute,
          builder: (context, state) {
            final categoryFilter = state.uri.queryParameters['category'];
            return MarkedAntonymsGamePage(
              categoryFilter: categoryFilter,
            );
          },
        ),
        
        // Tenses Game
        GoRoute(
          path: AppConstants.tensesGameRoute,
          builder: (context, state) {
            final categoryFilter = state.uri.queryParameters['category'];
            return TensesGamePage(
              categoryFilter: categoryFilter,
              onlyMarkedWords: false,
            );
          },
        ),
        
        // Saved Tense Review Cards
        GoRoute(
          path: AppConstants.savedTenseReviewCardsRoute,
          builder: (context, state) => const SavedTenseReviewCardsPage(),
        ),
        
        // Marked Tenses Game
        GoRoute(
          path: AppConstants.markedTensesGameRoute,
          builder: (context, state) {
            final categoryFilter = state.uri.queryParameters['category'];
            return MarkedTensesGamePage(
              categoryFilter: categoryFilter,
            );
          },
        ),
        
        // Subtitle Learning
        GoRoute(
          path: AppConstants.subtitleExtractorRoute,
          builder: (context, state) => const SelectSubtitlePage(),
        ),
        
        // Subtitle Upload (same as above, but with the new constant)
        GoRoute(
          path: AppConstants.subtitleUploadRoute,
          builder: (context, state) => const SelectSubtitlePage(),
        ),
        
        // Subtitle Read Mode
        GoRoute(
          path: AppConstants.subtitleReadModeRoute,
          builder: (context, state) {
            // Get parameters for the subtitle content
            final content = state.uri.queryParameters['content'];
            final title = state.uri.queryParameters['title'] ?? 'Subtitle';
            
            if (content == null || content.isEmpty) {
              return _ErrorScreen(path: state.uri.path);
            }
            
            return ReadModePage.fromContent(
              subtitleContent: content,
              title: title,
            );
          },
        ),
        
        // Subtitle Review
        GoRoute(
          path: AppConstants.subtitleReviewRoute,
          builder: (context, state) {
            // Extract query parameters for highlighted words, phrasal verbs, notes, etc.
            // This is a placeholder - we'll need to determine how to pass this data
            final Map<String, dynamic> params = state.extra as Map<String, dynamic>? ?? {};
            
            if (params.isEmpty) {
              return _ErrorScreen(path: state.uri.path);
            }
            
            return HighlightedWordsReviewPage(
              highlightedWords: params['highlightedWords'] ?? {},
              phrasalVerbs: params['phrasalVerbs'] ?? {},
              notes: params['notes'] ?? {},
              subtitleLines: params['subtitleLines'] ?? [],
              difficultVocabLines: params['difficultVocabLines'],
              notUnderstoodLines: params['notUnderstoodLines'],
            );
          },
        ),
        
        // Media Vocabularies (a shortcut/alias to the media route)
        GoRoute(
          path: AppConstants.mediaVocabulariesRoute,
          builder: (context, state) => MediaDiscoveryPage(
            mediaService: sl<MediaService>(),
          ),
        ),
        
        // Media
        GoRoute(
          path: AppConstants.mediaRoute,
          builder: (context, state) => const MediaCenterPage(),
        ),
        
        // Data Export/Import
        GoRoute(
          path: AppConstants.dataBackupRoute,
          builder: (context, state) => const DataExportImportPage(),
        ),
        
        // Add Games route
        GoRoute(
          name: 'games',
          path: AppConstants.gamesRoute,
          builder: (context, state) => const GamesPage(),
        ),
        
        // AI Answers
        GoRoute(
          path: AppConstants.aiAnswersRoute,
          builder: (context, state) => const AIAnswersPage(),
        ),
      ],
      errorBuilder: (context, state) => _ErrorScreen(path: state.uri.path),
    );
  }
}

/// A placeholder screen for routes that are not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String description;

  const _PlaceholderScreen({
    required this.title,
    this.description = 'Coming Soon',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}

/// An error screen for routes that don't exist
class _ErrorScreen extends StatelessWidget {
  final String path;

  const _ErrorScreen({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('The page $path does not exist.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.homeRoute),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
} 