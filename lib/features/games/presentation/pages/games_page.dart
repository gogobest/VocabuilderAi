import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/utils/tracking_service.dart';
import 'package:visual_vocabularies/core/widgets/app_navigation_bar.dart';

/// A page that displays all available game options
class GamesPage extends StatelessWidget {
  /// Constructor for GamesPage
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final trackingService = sl<TrackingService>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Track page view
    trackingService.trackNavigation('Games Page');
    
    return Scaffold(
      appBar: const AppNavigationBar(
        title: 'Games',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Learning Cards',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Practice with your saved words and phrases',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  // Marked Synonyms Game
                  _buildGameCard(
                    context,
                    title: 'My Marked Synonyms',
                    description: 'Practice with your marked synonyms',
                    icon: Icons.bookmark,
                    color: isDarkMode ? Colors.pink : Colors.indigo,
                    onTap: () {
                      trackingService.trackButtonClick('Marked Synonyms Game Card', screen: 'Games');
                      context.push(AppConstants.markedSynonymsGameRoute);
                      trackingService.trackNavigation('Marked Synonyms Game');
                    },
                    extraButtonText: 'All Flashcards',
                    onExtraButtonTap: () {
                      trackingService.trackButtonClick('Marked Synonyms Flashcards', screen: 'Games');
                      // Navigate to all synonyms flashcards, not just marked ones
                      context.push(AppConstants.synonymsGameRoute);
                      trackingService.trackNavigation('All Synonyms Game');
                    },
                  ),
                  
                  // Marked Antonyms Game
                  _buildGameCard(
                    context,
                    title: 'My Marked Antonyms',
                    description: 'Practice with your marked antonyms',
                    icon: Icons.compare_arrows_outlined,
                    color: isDarkMode ? Colors.orange : Colors.teal,
                    onTap: () {
                      trackingService.trackButtonClick('Marked Antonyms Game Card', screen: 'Games');
                      context.push(AppConstants.markedAntonymsGameRoute);
                      trackingService.trackNavigation('Marked Antonyms Game');
                    },
                    extraButtonText: 'All Flashcards',
                    onExtraButtonTap: () {
                      trackingService.trackButtonClick('Marked Antonyms Flashcards', screen: 'Games');
                      // Navigate to all antonyms flashcards, not just marked ones
                      context.push(AppConstants.antonymsGameRoute);
                      trackingService.trackNavigation('All Antonyms Game');
                    },
                  ),
                  
                  // Marked Tenses Game
                  _buildGameCard(
                    context,
                    title: 'My Marked Tenses',
                    description: 'Practice tenses with marked words',
                    icon: Icons.access_time,
                    color: isDarkMode ? Colors.cyan : Colors.brown,
                    onTap: () {
                      trackingService.trackButtonClick('Marked Tenses Game Card', screen: 'Games');
                      context.push(AppConstants.markedTensesGameRoute);
                      trackingService.trackNavigation('Marked Tenses Game');
                    },
                    extraButtonText: 'All Tenses',
                    onExtraButtonTap: () {
                      trackingService.trackButtonClick('All Tenses Game', screen: 'Games');
                      // Navigate to all tenses game, not just marked ones
                      context.push(AppConstants.tensesGameRoute);
                      trackingService.trackNavigation('All Tenses Game');
                    },
                    secondaryButtonText: 'Flashcard Mode',
                    onSecondaryButtonTap: () {
                      trackingService.trackButtonClick('Tenses Flashcards', screen: 'Games');
                      context.push(AppConstants.savedTenseReviewCardsRoute);
                      trackingService.trackNavigation('Tenses Flashcards');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? extraButtonText,
    VoidCallback? onExtraButtonTap,
    String? secondaryButtonText,
    VoidCallback? onSecondaryButtonTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Card(
          color: color.withOpacity(0.8),
          elevation: 4,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Card icon with container for depth
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icon,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Card title
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Card description
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.85),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const Spacer(flex: 1),
                            
                            // First extra button if provided
                            if (extraButtonText != null && onExtraButtonTap != null) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: onExtraButtonTap,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.public, size: 14),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          extraButtonText,
                                          style: const TextStyle(fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            
                            // Second extra button if provided
                            if (secondaryButtonText != null && onSecondaryButtonTap != null) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: onSecondaryButtonTap,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.flash_on, size: 14),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          secondaryButtonText,
                                          style: const TextStyle(fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
} 