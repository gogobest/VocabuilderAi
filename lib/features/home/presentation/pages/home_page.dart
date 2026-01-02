import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/utils/tracking_service.dart';
import 'package:visual_vocabularies/core/widgets/app_navigation_bar.dart';
import 'package:visual_vocabularies/core/utils/app_routes.dart';

/// Home page for the app displaying all learning options with improved UI
class HomePage extends StatelessWidget {
  /// Constructor for HomePage
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final trackingService = sl<TrackingService>();
    final size = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Track page view
    trackingService.trackNavigation('Home Page');
    
    return WillPopScope(
      onWillPop: () async {
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          context.go(AppConstants.homeRoute);
        }
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true, // Makes the app bar transparent
        appBar: AppBar(
          title: Text(
            AppConstants.appName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          backgroundColor: isDarkMode 
            ? Colors.black.withOpacity(0.5)
            : Theme.of(context).primaryColor.withOpacity(0.9),
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                trackingService.trackButtonClick('Settings', screen: 'Home');
                context.push(AppConstants.settingsRoute);
                trackingService.trackNavigation('Settings');
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                ? [
                    Colors.black87,
                    Color(0xFF1E1E2C),
                    Color(0xFF252536),
                  ]
                : [
                    Theme.of(context).primaryColor.withOpacity(0.7),
                    Theme.of(context).colorScheme.background,
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05, // Responsive padding
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Animated title for visual appeal
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                    'Visual Vocabulary Learning',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Theme.of(context).primaryColor,
                        ),
                    textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      'Learn using emojis and images',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            fontSize: 16,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildEnhancedFeatures(context, trackingService),
                  ),
                  const SizedBox(height: 24),
                  _buildButtonRow(context, trackingService, isDarkMode),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedFeatures(BuildContext context, TrackingService trackingService) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine cross axis count based on screen width
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        
        // Calculate the optimal child aspect ratio to fit all cards on one screen
        // For 6 cards with 2 columns, we need 3 rows
        final availableHeight = constraints.maxHeight;
        // Account for spacing between items (16px spacing × 2 rows between items)
        final totalVerticalSpacing = 16.0 * 2;
        // Compute optimal height per card
        final cardHeight = (availableHeight - totalVerticalSpacing) / 3;
        // Calculate aspect ratio (width / height)
        final childAspectRatio = constraints.maxWidth / (cardHeight * crossAxisCount);
        
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: childAspectRatio, // Adaptive aspect ratio
          ),
          itemCount: 6, // 6 cards in total
          shrinkWrap: true, // Don't allow scrolling
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling
          itemBuilder: (context, index) {
            // Define card data
            final List<Map<String, dynamic>> cardData = [
              {
                'title': 'Visual Flashcards',
                'icon': Icons.style_outlined,
                'description': 'Learn with visual flashcards',
                'color': Colors.red,
                'route': AppConstants.flashcardsRoute,
                'analyticsName': 'Flashcards'
              },
              {
                'title': 'Categories',
                'icon': Icons.category_outlined,
                'description': 'Browse by categories',
                'color': Colors.green,
                'route': AppConstants.categoriesRoute,
                'analyticsName': 'Categories'
              },
              {
                'title': 'All Words',
                'icon': Icons.list_alt_outlined,
                'description': 'View all your vocabularies',
                'color': Colors.purple,
                'route': AppConstants.allWordsRoute,
                'analyticsName': 'All Words'
              },
              {
                'title': 'Media Center',
                'icon': Icons.movie_filter_outlined,
                'description': 'Subtitles & Media Vocabularies',
                'color': Colors.blue,
                'route': AppConstants.mediaRoute,
                'analyticsName': 'Media Center'
              },
              {
                'title': 'Games',
                'icon': Icons.sports_esports_outlined,
                'description': 'Play vocabulary games',
                'color': Colors.teal,
                'route': AppConstants.gamesRoute,
                'analyticsName': 'Games'
              },
              {
                'title': 'Tense Review Cards',
                'icon': Icons.school_outlined,
                'description': 'Review your saved AI tense feedback',
                'color': Colors.deepPurple,
                'route': AppConstants.savedTenseReviewCardsRoute,
                'analyticsName': 'Tense Review Cards'
              },
            ];
            
            // Animation for staggered appearance
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              // Staggered delay based on index
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: _buildFeatureCard(
                title: cardData[index]['title'],
                icon: cardData[index]['icon'],
                description: cardData[index]['description'],
                color: cardData[index]['color'],
                onTap: () {
                  trackingService.trackButtonClick(
                    '${cardData[index]['title']} Card',
                    screen: 'Home'
                  );
                  context.push(cardData[index]['route']);
                  trackingService.trackNavigation(cardData[index]['analyticsName']);
                },
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? description,
  }) {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Card(
          color: color.withOpacity(0.8),
          elevation: 4, // More pronounced shadow
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
              padding: const EdgeInsets.all(12.0), // Reduced padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Use min size
                children: [
                  // Card icon with container for depth
                  Container(
                    padding: const EdgeInsets.all(8), // Smaller padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 24, // Smaller icon
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8), // Smaller gap
                  // Card title
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14, // Smaller font
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4), // Smaller gap
                    // Card description
                    Flexible(
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 10, // Smaller font
                          color: Colors.white.withOpacity(0.85),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(BuildContext context, TrackingService trackingService, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              trackingService.trackButtonClick('AI Generator Button', screen: 'Home');
              context.push(AppConstants.aiGeneratorRoute);
              trackingService.trackNavigation('AI Word Generator');
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI Words'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode
                  ? Colors.deepPurple
                  : Colors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              trackingService.trackButtonClick('Add Word Button', screen: 'Home');
              context.push(AppConstants.addEditWordRoute);
              trackingService.trackNavigation('Add New Word');
            },
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add),
                const SizedBox(width: 4),
                const Icon(Icons.auto_awesome, size: 14),
              ],
            ),
            label: const Text('Add Word'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 