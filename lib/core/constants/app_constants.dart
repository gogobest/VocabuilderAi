/// Application-wide constants
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();
  
  /// App name
  static const String appName = 'VocaBuilderAI';
  
  /// App description
  static const String appDescription = 'AI-powered vocabulary builder to enhance your language skills';
  
  /// App version
  static const String appVersion = '1.0.0';
  
  /// Hive box names
  static const String vocabularyBoxName = 'vocabulary_items';
  static const String settingsBoxName = 'app_settings';
  static const String categoriesBoxName = 'categories';
  
  /// Default categories
  static const List<String> defaultCategories = [
    'General',
    'Business',
    'Technology',
    'Science',
    'Travel',
    'Food',
    'Sports',
    'Arts',
    'Education',
    'Health',
  ];
  
  /// Routes
  static const String homeRoute = '/home';
  static const String splashRoute = '/splash';
  static const String categoriesRoute = '/categories';
  static const String flashcardsRoute = '/flashcards';
  static const String quizRoute = '/quiz';
  static const String matchGameRoute = '/match-game';
  static const String allWordsRoute = '/all-words';
  static const String wordDetailsRoute = '/word-details';
  static const String addWordRoute = '/add-word';
  static const String editWordRoute = '/edit-word';
  static const String settingsRoute = '/settings';
  static const String aiGeneratorRoute = '/ai-generator';
  static const String addEditWordRoute = '/add-edit-word';
  static const String subtitleExtractorRoute = '/select_subtitle';
  static const String mediaRoute = '/media';
  static const String mediaDiscoveryRoute = '/media/discovery';
  static const String aiAnswersRoute = '/ai-answers';
  static const String gamesRoute = '/games';
  static const String synonymsGameRoute = '/synonyms-game';
  static const String markedSynonymsGameRoute = '/marked-synonyms-game';
  static const String antonymsGameRoute = '/antonyms-game';
  static const String markedAntonymsGameRoute = '/marked-antonyms-game';
  static const String tensesGameRoute = '/tenses-game';
  static const String markedTensesGameRoute = '/marked-tenses-game';
  static const String visualFlashcardsRoute = '/visual-flashcards';
  static const String subtitleLearningRoute = '/subtitle-learning';
  
  // Subtitle learning flow
  static const String subtitleUploadRoute = '/subtitle/upload';
  static const String subtitleReadModeRoute = '/subtitle/read';
  static const String subtitleReviewRoute = '/subtitle/review';
  static const String mediaVocabulariesRoute = '/media/vocabularies';
  static const String dataBackupRoute = '/data-backup';
  
  /// Assets
  static const String defaultImagePath = 'images/placeholder.png';
  static const String logoPath = 'assets/images/logo.png';
  
  /// Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  /// Quiz settings
  static const int quizTimeLimit = 60; // seconds
  static const int defaultQuizQuestionCount = 10;
  static const int pointsPerCorrectAnswer = 10;
  
  /// Match game settings
  static const int matchGameTimeLimit = 120; // seconds
  static const int defaultMatchPairCount = 6;
  static const int pointsPerMatchedPair = 5;
  
  /// Flashcard settings
  static const int defaultFlashcardCount = 10;
  static const bool defaultEnableTpr = false; // Default TPR setting for flashcards
  
  /// Synonyms game settings
  static const int synonymsGameTimeLimit = 90; // seconds
  static const int defaultSynonymsGameCount = 10;
  static const int pointsPerCorrectSynonym = 10;
  
  /// Grammar tense emojis for vocabulary items
  static const Map<String, String> grammarTenseEmojis = {
    'noun': '📦',
    'verb': '🏃',
    'adjective': '🎨',
    'adverb': '🔄',
    'preposition': '🔀',
    'conjunction': '🔗',
    'pronoun': '👤',
    'interjection': '😲',
    'present simple': '⏱️',
    'present continuous': '🔄',
    'present perfect': '✅',
    'present perfect continuous': '✅🔄',
    'past simple': '⏮️',
    'past continuous': '⏮️🔄',
    'past perfect': '⏮️✅',
    'past perfect continuous': '⏮️✅🔄',
    'future simple': '⏭️',
    'future continuous': '⏭️🔄',
    'future perfect': '⏭️✅',
    'future perfect continuous': '⏭️✅🔄',
    'imperative': '📢',
    'conditional': '❓',
    'gerund': '〰️',
    'infinitive': '🔠',
    'participle': '📎',
  };
  
  /// Additional emoji set for AI matching with words
  static const Map<String, String> wordCategoryEmojis = {
    // Emotions and feelings
    'happy': '😊', 'sad': '😢', 'angry': '😠', 'surprised': '😲', 'afraid': '😨',
    'confused': '😕', 'tired': '😴', 'excited': '🤩', 'worried': '😟', 'calm': '😌',
    
    // Nature and environment
    'animal': '🐾', 'plant': '🌱', 'flower': '🌸', 'tree': '🌳', 'water': '💦',
    'fire': '🔥', 'earth': '🌍', 'weather': '☁️', 'sun': '☀️', 'moon': '🌙',
    
    // Food and drink
    'food': '🍽️', 'fruit': '🍎', 'vegetable': '🥦', 'meat': '🥩', 'drink': '🥤',
    'dessert': '🍰', 'breakfast': '🍳', 'lunch': '🥪', 'dinner': '🍲', 'snack': '🍿',
    
    // People and professions
    'person': '👤', 'family': '👪', 'work': '💼', 'student': '🎓', 'teacher': '📚',
    'doctor': '👩‍⚕️', 'artist': '🎨', 'musician': '🎵', 'athlete': '🏃', 'scientist': '🔬',
    
    // Activities and sports
    'travel': '✈️', 'sport': '🏆', 'game': '🎮', 'music': '🎧', 'art': '🖼️',
    'reading': '📖', 'writing': '✍️', 'dancing': '💃', 'swimming': '🏊', 'running': '🏃',
    
    // Objects and technology
    'technology': '💻', 'phone': '📱', 'book': '📔', 'car': '🚗', 'home': '🏠',
    'money': '💰', 'clock': '⏰', 'gift': '🎁', 'tool': '🔧', 'clothing': '👕',
    
    // Abstract concepts
    'idea': '💡', 'time': '⏳', 'growth': '📈', 'decrease': '📉', 'connection': '🔄',
    'communication': '💬', 'success': '🏅', 'failure': '❌', 'help': '🆘', 'direction': '🧭',
    
    // Categories
    'general': '📝', 'business': '💼', 'tech': '💻', 'science': '🔬', 'trip': '✈️',
    'cuisine': '🍽️', 'sports': '🏆', 'arts': '🎨', 'education': '📚', 'health': '❤️‍🩹'
  };
  
  /// Review intervals (days)
  static const int easyReviewInterval = 7;
  static const int mediumReviewInterval = 3;
  static const int hardReviewInterval = 1;
  
  /// New route constant
  static const String savedTenseReviewCardsRoute = '/saved-tense-review-cards';
} 