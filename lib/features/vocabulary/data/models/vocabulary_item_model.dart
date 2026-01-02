import 'package:hive/hive.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';

part 'vocabulary_item_model.g.dart';

/// TypeId for the VocabularyItemModel in Hive
@HiveType(typeId: 0)
class VocabularyItemModel extends VocabularyItem {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String word;

  @HiveField(2)
  @override
  final String meaning;

  @HiveField(3)
  @override
  final String? example;

  @HiveField(4)
  @override
  final String category;

  @HiveField(5)
  @override
  final String? imageUrl;

  @HiveField(6)
  @override
  final String? pronunciation;

  @HiveField(7)
  @override
  final DateTime createdAt;

  @HiveField(8)
  @override
  final DateTime? lastReviewed;

  @HiveField(9)
  @override
  final int difficultyLevel;

  @HiveField(10)
  @override
  final int masteryLevel;
  
  @HiveField(11)
  @override
  final String? sourceMedia;
  
  @HiveField(12)
  @override
  final String? grammarTense;
  


  @HiveField(13)
  @override
  final String? wordEmoji;
  
  @HiveField(14)
  @override
  final List<String>? synonyms;
  
  @HiveField(15)
  @override
  final List<String>? antonyms;
  
  @HiveField(16)
  @override
  final Map<String, String>? tenseVariations;
  
  @HiveField(17)
  @override
  final String? partOfSpeechNote;
  
  @HiveField(18)
  @override
  final Map<String, String>? alternateMeanings;
  
  @HiveField(19)
  @override
  final Map<String, String>? verbTenseVariations;
  
  @HiveField(20)
  @override
  final String? partOfSpeech;
  
  @HiveField(21)
  @override
  final String? recordingPath;

  /// Creates a VocabularyItemModel with all required and optional parameters.
  VocabularyItemModel({
    required this.id,
    required this.word,
    required this.meaning,
    this.example,
    required this.category,
    this.imageUrl,
    this.pronunciation,
    required this.createdAt,
    this.lastReviewed,
    required this.difficultyLevel,
    required this.masteryLevel,
    this.sourceMedia,
    this.grammarTense,

    this.wordEmoji,
    this.synonyms,
    this.antonyms,
    this.tenseVariations,
    this.partOfSpeechNote,
    this.alternateMeanings,
    this.verbTenseVariations,
    this.partOfSpeech,
    this.recordingPath,
  }) : super(
          id: id,
          word: word,
          meaning: meaning,
          example: example,
          category: category,
          imageUrl: imageUrl,
          pronunciation: pronunciation,
          createdAt: createdAt,
          lastReviewed: lastReviewed,
          difficultyLevel: difficultyLevel,
          masteryLevel: masteryLevel,
          sourceMedia: sourceMedia,
          grammarTense: grammarTense,

          wordEmoji: wordEmoji,
          synonyms: synonyms,
          antonyms: antonyms,
          tenseVariations: tenseVariations,
          partOfSpeechNote: partOfSpeechNote,
          alternateMeanings: alternateMeanings,
          verbTenseVariations: verbTenseVariations,
          partOfSpeech: partOfSpeech,
          recordingPath: recordingPath,
        );

  /// Creates a VocabularyItemModel from a VocabularyItem entity.
  factory VocabularyItemModel.fromEntity(VocabularyItem item) {
    return VocabularyItemModel(
      id: item.id,
      word: item.word,
      meaning: item.meaning,
      example: item.example,
      category: item.category,
      imageUrl: item.imageUrl,
      pronunciation: item.pronunciation,
      createdAt: item.createdAt,
      lastReviewed: item.lastReviewed,
      difficultyLevel: item.difficultyLevel,
      masteryLevel: item.masteryLevel,
      sourceMedia: item.sourceMedia,
      grammarTense: item.grammarTense,

      wordEmoji: item.wordEmoji,
      synonyms: item.synonyms,
      antonyms: item.antonyms,
      tenseVariations: item.tenseVariations,
      partOfSpeechNote: item.partOfSpeechNote,
      alternateMeanings: item.alternateMeanings,
      verbTenseVariations: item.verbTenseVariations,
      partOfSpeech: item.partOfSpeech,
      recordingPath: item.recordingPath,
    );
  }

  /// Creates a copy of this VocabularyItemModel with the given fields replaced with the new values.
  @override
  VocabularyItemModel copyWith({
    String? id,
    String? word,
    String? meaning,
    String? example,
    String? category,
    String? imageUrl,
    String? pronunciation,
    DateTime? createdAt,
    DateTime? lastReviewed,
    int? difficultyLevel,
    int? masteryLevel,
    String? sourceMedia,
    String? grammarTense,

    String? wordEmoji,
    List<String>? synonyms,
    List<String>? antonyms,
    Map<String, String>? tenseVariations,
    String? partOfSpeechNote,
    Map<String, String>? alternateMeanings,
    Map<String, String>? verbTenseVariations,
    String? partOfSpeech,
    String? recordingPath,
  }) {
    return VocabularyItemModel(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      example: example ?? this.example,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      pronunciation: pronunciation ?? this.pronunciation,
      createdAt: createdAt ?? this.createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      sourceMedia: sourceMedia ?? this.sourceMedia,
      grammarTense: grammarTense ?? this.grammarTense,

      wordEmoji: wordEmoji ?? this.wordEmoji,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      tenseVariations: tenseVariations ?? this.tenseVariations,
      partOfSpeechNote: partOfSpeechNote ?? this.partOfSpeechNote,
      alternateMeanings: alternateMeanings ?? this.alternateMeanings,
      verbTenseVariations: verbTenseVariations ?? this.verbTenseVariations,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      recordingPath: recordingPath ?? this.recordingPath,
    );
  }

  VocabularyItem toEntity() {
    return VocabularyItem(
      id: id,
      word: word,
      meaning: meaning,
      example: example,
      category: category,
      imageUrl: imageUrl,
      pronunciation: pronunciation,
      createdAt: createdAt,
      lastReviewed: lastReviewed,
      difficultyLevel: difficultyLevel,
      masteryLevel: masteryLevel,
      sourceMedia: sourceMedia,
      grammarTense: grammarTense,
      wordEmoji: wordEmoji,
      synonyms: synonyms,
      antonyms: antonyms,
      tenseVariations: tenseVariations,
      partOfSpeechNote: partOfSpeechNote,
      alternateMeanings: alternateMeanings,
      verbTenseVariations: verbTenseVariations,
      partOfSpeech: partOfSpeech,
      recordingPath: recordingPath,
    );
  }
} 