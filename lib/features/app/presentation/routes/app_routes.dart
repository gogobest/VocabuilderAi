import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/features/app/presentation/pages/media_center_page.dart';
import 'package:visual_vocabularies/features/media_vocabulary/presentation/pages/media_discovery_page.dart';
import 'package:visual_vocabularies/features/subtitle_extractor/presentation/pages/select_subtitle_page.dart';
import 'package:visual_vocabularies/features/book_extractor/presentation/pages/select_book_page.dart';
import 'package:visual_vocabularies/features/media/presentation/pages/ai_answers_page.dart';

class AppRoutes {
  // Named routes for easy navigation
  static const String home = 'home';
  static const String mediaCenter = 'media_center';
  static const String subtitles = 'subtitles';
  static const String books = 'books';
  static const String mediaVocabulary = 'media_vocabulary';
  static const String aiAnswers = 'ai_answers';

  // Return the GoRouter instance with all route configurations
  static GoRouter getRouter() {
    return GoRouter(
      initialLocation: '/$mediaCenter',
      routes: [
        GoRoute(
          path: '/',
          name: home,
          redirect: (_, __) => '/$mediaCenter',
        ),
        GoRoute(
          path: "/$mediaCenter",
          name: mediaCenter,
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              child: const MediaCenterPage(),
            );
          },
        ),
        GoRoute(
          path: "/$subtitles",
          name: subtitles,
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              child: const SelectSubtitlePage(isEmbedded: false),
            );
          },
        ),
        GoRoute(
          path: "/$books",
          name: books,
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              child: const SelectBookPage(isEmbedded: false),
            );
          },
        ),
        GoRoute(
          path: "/$mediaVocabulary",
          name: mediaVocabulary,
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              child: const MediaDiscoveryPage(),
            );
          },
        ),
        GoRoute(
          path: "/$aiAnswers",
          name: aiAnswers,
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              child: const AIAnswersPage(),
            );
          },
        ),
      ],
    );
  }
} 