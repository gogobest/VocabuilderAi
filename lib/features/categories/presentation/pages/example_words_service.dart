import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';

/// Service to provide example vocabulary items for different categories
class ExampleWordsService {
  /// Gets example vocabulary items for the "Movies & TV Shows" category
  static List<VocabularyItem> getMoviesAndTVShowsExamples() {
    return [
      VocabularyItem(
        word: 'Cliffhanger',
        meaning: 'A dramatic ending to a TV episode that leaves the audience in suspense until the next episode',
        example: 'The season finale ended with a major cliffhanger when the main character was revealed to be the villain all along.',
        category: 'Movies & TV Shows',
        pronunciation: '/ˈklɪfhæŋɡər/',
        difficultyLevel: 3,
      ),
      
      VocabularyItem(
        word: 'Binge-watch',
        meaning: 'To watch multiple episodes of a TV show in rapid succession',
        example: 'I binge-watched the entire season of Stranger Things in one weekend.',
        category: 'Movies & TV Shows',
        pronunciation: '/bɪndʒ wɒtʃ/',
        difficultyLevel: 2,
      ),
      
      VocabularyItem(
        word: 'MacGuffin',
        meaning: 'An object, device, or event that serves as a trigger for the plot but may have little actual importance',
        example: 'The briefcase in Pulp Fiction is a classic MacGuffin - we never learn what\'s inside, but it drives the entire plot.',
        category: 'Movies & TV Shows',
        pronunciation: '/məˈɡʌfɪn/',
        difficultyLevel: 4,
      ),
    ];
  }
  
  /// Gets example vocabulary items for the "Technology" category
  static List<VocabularyItem> getTechnologyExamples() {
    return [
      VocabularyItem(
        word: 'Algorithm',
        meaning: 'A process or set of rules to be followed in calculations or other problem-solving operations, especially by a computer',
        example: 'The search engine uses a sophisticated algorithm to rank web pages by relevance.',
        category: 'Technology',
        pronunciation: '/ˈælɡəˌrɪðəm/',
        difficultyLevel: 3,
      ),
      
      VocabularyItem(
        word: 'Cloud Computing',
        meaning: 'The practice of using a network of remote servers hosted on the internet to store, manage, and process data',
        example: 'The company migrated their entire infrastructure to cloud computing to reduce hardware costs.',
        category: 'Technology',
        pronunciation: '/klaʊd kəmˈpjuːtɪŋ/',
        difficultyLevel: 3,
      ),
    ];
  }
  
  /// Gets example vocabulary items for a specific category
  static List<VocabularyItem> getExamplesForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'movies & tv shows':
        return getMoviesAndTVShowsExamples();
      case 'technology':
        return getTechnologyExamples();
      default:
        return [];
    }
  }
} 