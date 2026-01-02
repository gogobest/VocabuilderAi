import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/utils/tracking_service.dart';
import 'package:visual_vocabularies/features/media/data/services/media_service.dart';
import 'package:visual_vocabularies/features/subtitle_extractor/presentation/pages/select_subtitle_page.dart';
import 'package:visual_vocabularies/features/book_extractor/presentation/pages/select_book_page.dart';
import 'package:visual_vocabularies/features/media/presentation/pages/media_discovery_page.dart';
import 'package:visual_vocabularies/core/widgets/app_navigation_bar.dart';
import 'package:visual_vocabularies/features/media/data/services/ai_answer_service.dart';
import 'package:visual_vocabularies/features/media/presentation/pages/ai_answers_page.dart';

/// A page that combines subtitle learning and media discovery features
class MediaCenterPage extends StatefulWidget {
  /// Default constructor
  const MediaCenterPage({super.key});

  @override
  State<MediaCenterPage> createState() => _MediaCenterPageState();
}

class _MediaCenterPageState extends State<MediaCenterPage> {
  final TrackingService _trackingService = sl<TrackingService>();
  final MediaService _mediaService = sl<MediaService>();
  final AIAnswerService _aiAnswerService = sl<AIAnswerService>();
  bool _isLoading = true;
  int _mediaItemCount = 0;
  int _aiAnswerCount = 0;
  
  @override
  void initState() {
    super.initState();
    // Track page view
    _trackingService.trackNavigation('Media Center Page');
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final mediaItems = await _mediaService.getAllMediaItems();
      final answerCount = await _aiAnswerService.getAIAnswerCount();
      
      setState(() {
        _mediaItemCount = mediaItems.length;
        _aiAnswerCount = answerCount;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load media data: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
        appBar: AppBar(
          title: const Text('Media Center'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (GoRouter.of(context).canPop()) {
                context.pop();
              } else {
                context.go(AppConstants.homeRoute);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              tooltip: 'Go to Home',
              onPressed: () {
                context.go(AppConstants.homeRoute);
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadCounts,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Media Center',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),
                        
                        // Media vocabulary section
                        _buildSectionCard(
                          title: 'Media Vocabulary',
                          description: 'Access vocabulary items extracted from media',
                          count: _mediaItemCount,
                          icon: Icons.movie,
                          color: isDarkMode ? Colors.indigo[300] : Colors.indigo,
                          onTap: () {
                            _trackingService.trackButtonClick('Media Vocabulary Card', screen: 'Media Center');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MediaDiscoveryPage(
                                  mediaService: _mediaService,
                                  isEmbedded: false,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // AI answers section
                        _buildSectionCard(
                          title: 'AI Answers',
                          description: 'View saved AI explanations for subtitle questions',
                          count: _aiAnswerCount,
                          icon: Icons.question_answer,
                          color: isDarkMode ? Colors.teal[300] : Colors.teal,
                          onTap: () {
                            _trackingService.trackButtonClick('AI Answers Card', screen: 'Media Center');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AIAnswersPage(),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Subtitle Learning section
                        _buildSectionCard(
                          title: 'Subtitle Learning',
                          description: 'Upload subtitles to extract vocabulary and learn',
                          count: 0,  // No count for this section
                          icon: Icons.subtitles,
                          color: isDarkMode ? Colors.purple[300] : Colors.purple,
                          onTap: () {
                            _trackingService.trackButtonClick('Subtitle Learning Card', screen: 'Media Center');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SelectSubtitlePage(isEmbedded: false),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Book Learning section
                        _buildSectionCard(
                          title: 'Book Learning',
                          description: 'Upload eBooks to extract vocabulary and learn',
                          count: 0,  // No count for this section
                          icon: Icons.book,
                          color: isDarkMode ? Colors.green[300] : Colors.green,
                          onTap: () {
                            _trackingService.trackButtonClick('Book Learning Card', screen: 'Media Center');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SelectBookPage(isEmbedded: false),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Add more sections here in the future
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
  
  Widget _buildSectionCard({
    required String title,
    required String description,
    required int count,
    required IconData icon,
    required Color? color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color?.withOpacity(0.2),
                    radius: 24,
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '$count items',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 