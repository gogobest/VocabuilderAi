import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/theme/theme_provider.dart';
import 'package:visual_vocabularies/core/utils/ai_service.dart';
import 'package:visual_vocabularies/core/utils/antonyms_game_service.dart';
import 'package:visual_vocabularies/core/utils/image_helper.dart';
import 'package:visual_vocabularies/core/utils/image_cache_service.dart';
import 'package:visual_vocabularies/core/utils/secure_storage_service.dart';
import 'package:visual_vocabularies/core/utils/tenses_game_service.dart';
import 'package:visual_vocabularies/core/utils/tenses_ai_service.dart';
import 'package:visual_vocabularies/core/utils/tts_config_service.dart';
import 'package:visual_vocabularies/core/utils/synonyms_game_service.dart';
import 'package:visual_vocabularies/features/vocabulary/data/models/vocabulary_item_model.dart';
import 'package:visual_vocabularies/features/vocabulary/data/repositories/vocabulary_repository_impl.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:visual_vocabularies/core/utils/tracking_service.dart';
import 'package:visual_vocabularies/core/utils/flashcard_service.dart';
import 'package:visual_vocabularies/features/media/data/models/media_item_model.dart';
import 'package:visual_vocabularies/features/media/data/repositories/media_repository_impl.dart';
import 'package:visual_vocabularies/features/media/domain/repositories/media_repository.dart';
import 'package:visual_vocabularies/features/media/data/services/media_service.dart';
import 'package:visual_vocabularies/features/vocabulary/data/services/vocabulary_image_service.dart';
import 'package:visual_vocabularies/core/utils/ai/models/tense_evaluation_response.dart';
import 'package:visual_vocabularies/features/media/data/services/ai_answer_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service locator for dependency injection
final GetIt sl = GetIt.instance;

/// Initialize dependencies
Future<void> initDependencies() async {
  // Core
  await _initHive();
  await _initFileSystem();
  _initCoreServices();
  
  // Register tracking service
  sl.registerLazySingleton<TrackingService>(() => TrackingService());
  
  // Register FlashcardService
  sl.registerLazySingleton(() => FlashcardService());
  
  // Register ThemeProvider
  sl.registerLazySingleton(() => ThemeProvider());
  
  // Repositories
  _initRepositories();
  
  // UseCases
  _initUseCases();
  
  // BLoCs/Cubits
  _initBlocs();
  
  // Register services
  _initServices();
}

/// Initialize services
void _initServices() {
  // Register MediaService
  sl.registerLazySingleton(() => MediaService(sl<MediaRepository>()));
  
  // Register SynonymsGameService
  sl.registerLazySingleton(() => SynonymsGameService());
  
  // Register AntonymsGameService
  sl.registerLazySingleton(() => AntonymsGameService());
  
  // Register TensesGameService
  sl.registerLazySingleton(() => TensesGameService());
  
  // Register TensesAiService
  sl.registerLazySingleton(() => TensesAiService(sl<AiService>()));
  
  // Register VocabularyImageService as a singleton
  if (!sl.isRegistered<VocabularyImageService>()) {
    sl.registerLazySingleton(() => VocabularyImageService());
  }
  
  // Register ImageCacheService as a singleton
  if (!sl.isRegistered<ImageCacheService>()) {
    sl.registerLazySingleton(() => ImageCacheService.instance);
  }
  
  // Register AI answer service
  sl.registerLazySingleton<AIAnswerService>(() => AIAnswerService());
}

/// Initialize core services
void _initCoreServices() {
  // Register SecureStorageService
  sl.registerLazySingleton(() => SecureStorageService());
  
  // Register AiService
  sl.registerLazySingleton(() => AiService(sl<SecureStorageService>()));
  
  // Register TtsConfigService
  sl.registerLazySingleton(() => TtsConfigService());
  
  // Register ImageCacheService instance
  sl.registerLazySingleton(() => ImageCacheService.instance);

  // Register FlutterTts instance
  sl.registerLazySingleton(() => FlutterTts());
}

/// Initialize Hive database
Future<void> _initHive() async {
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(VocabularyItemModelAdapter());
  Hive.registerAdapter(MediaItemModelAdapter());
  Hive.registerAdapter(TenseEvaluationResponseAdapter());
  
  // Open boxes
  final vocabularyBox = await Hive.openBox<VocabularyItemModel>(
    AppConstants.vocabularyBoxName,
  );
  
  final mediaBox = await Hive.openBox<MediaItemModel>('media_items');
  final tenseReviewBox = await Hive.openBox<TenseEvaluationResponse>('saved_tense_review_cards');
  final organizedTenseReviewBox = await Hive.openBox('organized_tense_review_cards');
  
  sl.registerSingleton<Box<VocabularyItemModel>>(vocabularyBox);
  sl.registerSingleton<Box<MediaItemModel>>(mediaBox);
  sl.registerSingleton<Box<TenseEvaluationResponse>>(tenseReviewBox);
  sl.registerSingleton<Box>(organizedTenseReviewBox, instanceName: 'organized_tense_review_box');
}

/// Initialize file system directories
Future<void> _initFileSystem() async {
  // Ensure image directories exist
  await ImageHelper.ensureImageDirectories();
}

/// Initialize repositories
void _initRepositories() {
  // Register main VocabularyRepository
  sl.registerLazySingleton<VocabularyRepository>(
    () => VocabularyRepositoryImpl(sl<Box<VocabularyItemModel>>()),
  );
  
  // Register MediaRepository
  sl.registerLazySingleton<MediaRepository>(
    () => MediaRepositoryImpl(),
  );
}

/// Initialize use cases
void _initUseCases() {
  // TODO: Register use cases when implemented
}

/// Initialize BLoCs/Cubits
void _initBlocs() {
  // Register the VocabularyBloc
  sl.registerFactory(
    () => VocabularyBloc(sl<VocabularyRepository>()),
  );
}

/// Adapter for VocabularyItemModel
class VocabularyItemModelAdapter extends TypeAdapter<VocabularyItemModel> {
  @override
  final int typeId = 0;

  @override
  VocabularyItemModel read(BinaryReader reader) {
    final id = reader.readString();
    final word = reader.readString();
    final meaning = reader.readString();
    final example = reader.readString();
    final category = reader.readString();
    final imageUrl = reader.readString();
    final pronunciation = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    
    final hasLastReviewed = reader.readBool();
    final DateTime? lastReviewed = hasLastReviewed 
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) 
        : null;
    
    final difficultyLevel = reader.readInt();
    final masteryLevel = reader.readInt();
    
    // Read new fields if they exist (for backward compatibility)
    String? sourceMedia;
    String? grammarTense;
    String? wordEmoji;
    List<String>? synonyms;
    List<String>? antonyms;
    
    try {
      final hasSourceMedia = reader.readBool();
      sourceMedia = hasSourceMedia ? reader.readString() : null;
      
      final hasGrammarTense = reader.readBool();
      grammarTense = hasGrammarTense ? reader.readString() : null;
      
      // Try to read wordEmoji field
      try {
        final hasWordEmoji = reader.readBool();
        wordEmoji = hasWordEmoji ? reader.readString() : null;
        
        // Try to read synonyms field
        try {
          final hasSynonyms = reader.readBool();
          if (hasSynonyms) {
            final count = reader.readInt();
            synonyms = List.generate(count, (_) => reader.readString());
          }
          
          // Try to read antonyms field
          try {
            final hasAntonyms = reader.readBool();
            if (hasAntonyms) {
              final count = reader.readInt();
              antonyms = List.generate(count, (_) => reader.readString());
            }
          } catch (e) {
            // Antonyms field doesn't exist in older data
            antonyms = null;
          }
        } catch (e) {
          // Synonyms field doesn't exist in older data
          synonyms = null;
          antonyms = null;
        }
      } catch (e) {
        // WordEmoji field doesn't exist in older data
        wordEmoji = null;
        synonyms = null;
        antonyms = null;
      }
    } catch (e) {
      // Fields don't exist in older data, use defaults
      sourceMedia = null;
      grammarTense = null;
      wordEmoji = null;
      synonyms = null;
      antonyms = null;
    }

    return VocabularyItemModel(
      id: id,
      word: word,
      meaning: meaning,
      example: example.isEmpty ? null : example,
      category: category,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      pronunciation: pronunciation.isEmpty ? null : pronunciation,
      createdAt: createdAt,
      lastReviewed: lastReviewed,
      difficultyLevel: difficultyLevel,
      masteryLevel: masteryLevel,
      sourceMedia: sourceMedia,
      grammarTense: grammarTense,
      wordEmoji: wordEmoji,
      synonyms: synonyms,
      antonyms: antonyms,
    );
  }

  @override
  void write(BinaryWriter writer, VocabularyItemModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.word);
    writer.writeString(obj.meaning);
    writer.writeString(obj.example ?? '');
    writer.writeString(obj.category);
    writer.writeString(obj.imageUrl ?? '');
    writer.writeString(obj.pronunciation ?? '');
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    
    writer.writeBool(obj.lastReviewed != null);
    if (obj.lastReviewed != null) {
      writer.writeInt(obj.lastReviewed!.millisecondsSinceEpoch);
    }
    
    writer.writeInt(obj.difficultyLevel);
    writer.writeInt(obj.masteryLevel);
    
    // Write new fields
    writer.writeBool(obj.sourceMedia != null);
    if (obj.sourceMedia != null) {
      writer.writeString(obj.sourceMedia!);
    }
    
    writer.writeBool(obj.grammarTense != null);
    if (obj.grammarTense != null) {
      writer.writeString(obj.grammarTense!);
    }
    
    // Write wordEmoji field
    writer.writeBool(obj.wordEmoji != null);
    if (obj.wordEmoji != null) {
      writer.writeString(obj.wordEmoji!);
    }
    
    // Write synonyms field
    writer.writeBool(obj.synonyms != null && obj.synonyms!.isNotEmpty);
    if (obj.synonyms != null && obj.synonyms!.isNotEmpty) {
      writer.writeInt(obj.synonyms!.length);
      for (final synonym in obj.synonyms!) {
        writer.writeString(synonym);
      }
    }
    
    // Write antonyms field
    writer.writeBool(obj.antonyms != null && obj.antonyms!.isNotEmpty);
    if (obj.antonyms != null && obj.antonyms!.isNotEmpty) {
      writer.writeInt(obj.antonyms!.length);
      for (final antonym in obj.antonyms!) {
        writer.writeString(antonym);
      }
    }
  }
}

/// Adapter for MediaItemModel
class MediaItemModelAdapter extends TypeAdapter<MediaItemModel> {
  @override
  final int typeId = 2; // Make sure this matches the type ID in MediaItemModel

  @override
  MediaItemModel read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    
    final hasSeason = reader.readBool();
    final int? season = hasSeason ? reader.readInt() : null;
    
    final hasEpisode = reader.readBool();
    final int? episode = hasEpisode ? reader.readInt() : null;
    
    final hasCoverImageUrl = reader.readBool();
    final String? coverImageUrl = hasCoverImageUrl ? reader.readString() : null;
    
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    
    // Read vocabulary item IDs
    final count = reader.readInt();
    final List<String> vocabularyItemIds = List.generate(count, (_) => reader.readString());
    
    // Read author and chapter if they exist (for backward compatibility)
    String? author;
    int? chapter;
    
    try {
      final hasAuthor = reader.readBool();
      author = hasAuthor ? reader.readString() : null;
      
      final hasChapter = reader.readBool();
      chapter = hasChapter ? reader.readInt() : null;
    } catch (e) {
      // Fields don't exist in older data
      author = null;
      chapter = null;
    }
    
    return MediaItemModel(
      id: id,
      title: title,
      season: season,
      episode: episode,
      coverImageUrl: coverImageUrl,
      createdAt: createdAt,
      vocabularyItemIds: vocabularyItemIds,
      author: author,
      chapter: chapter,
    );
  }

  @override
  void write(BinaryWriter writer, MediaItemModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    
    writer.writeBool(obj.season != null);
    if (obj.season != null) {
      writer.writeInt(obj.season!);
    }
    
    writer.writeBool(obj.episode != null);
    if (obj.episode != null) {
      writer.writeInt(obj.episode!);
    }
    
    writer.writeBool(obj.coverImageUrl != null);
    if (obj.coverImageUrl != null) {
      writer.writeString(obj.coverImageUrl!);
    }
    
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    
    // Write vocabulary item IDs
    writer.writeInt(obj.vocabularyItemIds.length);
    for (final id in obj.vocabularyItemIds) {
      writer.writeString(id);
    }
    
    // Write author field
    writer.writeBool(obj.author != null);
    if (obj.author != null) {
      writer.writeString(obj.author!);
    }
    
    // Write chapter field
    writer.writeBool(obj.chapter != null);
    if (obj.chapter != null) {
      writer.writeInt(obj.chapter!);
    }
  }
}