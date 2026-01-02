import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// A vocabulary item that represents a word or phrase with its meaning and additional information.
class VocabularyItem extends Equatable {
  /// Unique identifier for the vocabulary item
  final String id;

  /// The word or phrase
  final String word;

  /// The meaning or definition of the word
  final String meaning;

  /// Example sentence using the word
  final String? example;

  /// Category or topic this word belongs to
  final String category;

  /// Optional image URL for visual representation
  final String? imageUrl;

  /// Optional pronunciation guide
  final String? pronunciation;

  /// Creation date of this vocabulary item
  final DateTime createdAt;

  /// Last time this item was reviewed
  final DateTime? lastReviewed;

  /// Difficulty level (1-5, where 1 is easiest and 5 is hardest)
  final int difficultyLevel;

  /// Mastery level (0-100, where 100 means fully mastered)
  final int masteryLevel;
  
  /// Optional source media (e.g. "Movie Title", "TV Show S01E01")
  final String? sourceMedia;
  
  /// Optional grammar tense (e.g. "Past Simple", "Present Continuous")
  final String? grammarTense;

  
  /// Optional emoji that visually represents this word
  final String? wordEmoji;
  
  /// Optional list of synonyms for this word
  final List<String>? synonyms;
  
  /// Optional list of antonyms for this word
  final List<String>? antonyms;
  
  /// Optional map of tense variations of this word (e.g. "Present Simple" -> "walk", "Past Simple" -> "walked")
  final Map<String, String>? tenseVariations;

  /// Part of speech of the word (noun, verb, adjective, etc.)
  final String? partOfSpeech;
  
  /// New fields for multi-part-of-speech support
  final String? partOfSpeechNote;
  final Map<String, String>? alternateMeanings;
  final Map<String, String>? verbTenseVariations;
  
  /// Path to the user's voice recording of this word
  final String? recordingPath;

  /// Creates a VocabularyItem with all required and optional parameters.
  /// 
  /// If [id] is not provided, a new UUID will be generated.
  /// If [createdAt] is not provided, the current time will be used.
  VocabularyItem({
    String? id,
    required this.word,
    required this.meaning,
    this.example,
    required this.category,
    this.imageUrl,
    this.pronunciation,
    DateTime? createdAt,
    this.lastReviewed,
    this.difficultyLevel = 3,
    this.masteryLevel = 0,
    this.sourceMedia,
    this.grammarTense,
  
    this.wordEmoji,
    this.synonyms,
    this.antonyms,
    this.tenseVariations,
    this.partOfSpeech,
    this.partOfSpeechNote,
    this.alternateMeanings,
    this.verbTenseVariations,
    this.recordingPath,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Creates a copy of this VocabularyItem with the given fields replaced with the new values.
  VocabularyItem copyWith({
    String? id,
    String? word,
    String? meaning,
    String? example,
    String? category,
    String? pronunciation,
    int? difficultyLevel,

    String? wordEmoji,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? lastReviewed,
    int? masteryLevel,
    Map<String, String>? tenseVariations,
    List<String>? synonyms,
    List<String>? antonyms,
    String? grammarTense,
    String? partOfSpeech,
    String? partOfSpeechNote,
    Map<String, String>? alternateMeanings,
    Map<String, String>? verbTenseVariations,
    String? recordingPath,
    String? sourceMedia,
  }) {
    return VocabularyItem(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      example: example ?? this.example,
      category: category ?? this.category,
      pronunciation: pronunciation ?? this.pronunciation,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,

      wordEmoji: wordEmoji ?? this.wordEmoji,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      tenseVariations: tenseVariations ?? this.tenseVariations,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      grammarTense: grammarTense ?? this.grammarTense,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      partOfSpeechNote: partOfSpeechNote ?? this.partOfSpeechNote,
      alternateMeanings: alternateMeanings ?? this.alternateMeanings,
      verbTenseVariations: verbTenseVariations ?? this.verbTenseVariations,
      recordingPath: recordingPath ?? this.recordingPath,
      sourceMedia: sourceMedia ?? this.sourceMedia,
    );
  }

  /// Updates the mastery level after a review.
  ///
  /// [correct] - whether the user answered correctly
  VocabularyItem updateMasteryAfterReview(bool correct) {
    final now = DateTime.now();
    int newMastery = masteryLevel;
    
    if (correct) {
      // Increase mastery level with diminishing returns as it gets higher
      newMastery += (100 - masteryLevel) ~/ 10;
      if (newMastery > 100) newMastery = 100;
    } else {
      // Decrease mastery level more if it's already high
      newMastery -= (masteryLevel ~/ 10) + 5;
      if (newMastery < 0) newMastery = 0;
    }

    return copyWith(
      lastReviewed: now,
      masteryLevel: newMastery,
    );
  }

  @override
  List<Object?> get props => [
        id,
        word,
        meaning,
        example,
        category,
        imageUrl,
        pronunciation,
        createdAt,
        lastReviewed,
        difficultyLevel,
        masteryLevel,
        sourceMedia,
        grammarTense,
        wordEmoji,
        synonyms,
        antonyms,
        tenseVariations,
        partOfSpeech,
        partOfSpeechNote,
        alternateMeanings,
        verbTenseVariations,
        recordingPath,
      ];
      
  /// Converts this VocabularyItem to a JSON object for serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'example': example,
      'category': category,
      'imageUrl': imageUrl,
      'pronunciation': pronunciation,
      'createdAt': createdAt.toIso8601String(),
      'lastReviewed': lastReviewed?.toIso8601String(),
      'difficultyLevel': difficultyLevel,
      'masteryLevel': masteryLevel,
      'sourceMedia': sourceMedia,
      'grammarTense': grammarTense,
      'wordEmoji': wordEmoji,
      'synonyms': synonyms,
      'antonyms': antonyms,
      'tenseVariations': tenseVariations,
      'partOfSpeech': partOfSpeech,
      'partOfSpeechNote': partOfSpeechNote,
      'alternateMeanings': alternateMeanings,
      'verbTenseVariations': verbTenseVariations,
      'recordingPath': recordingPath,
    };
  }
  
  /// Creates a VocabularyItem from a JSON object.
  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'],
      word: json['word'],
      meaning: json['meaning'],
      example: json['example'],
      category: json['category'],
      imageUrl: json['imageUrl'],
      pronunciation: json['pronunciation'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      lastReviewed: json['lastReviewed'] != null ? DateTime.parse(json['lastReviewed']) : null,
      difficultyLevel: json['difficultyLevel'] ?? 3,
      masteryLevel: json['masteryLevel'] ?? 0,
      sourceMedia: json['sourceMedia'],
      grammarTense: json['grammarTense'],
      wordEmoji: json['wordEmoji'],
      synonyms: json['synonyms'] != null ? List<String>.from(json['synonyms']) : null,
      antonyms: json['antonyms'] != null ? List<String>.from(json['antonyms']) : null,
      tenseVariations: json['tenseVariations'] != null ? Map<String, String>.from(json['tenseVariations']) : null,
      partOfSpeech: json['partOfSpeech'],
      partOfSpeechNote: json['partOfSpeechNote'],
      alternateMeanings: json['alternateMeanings'] != null ? Map<String, String>.from(json['alternateMeanings']) : null,
      verbTenseVariations: json['verbTenseVariations'] != null ? Map<String, String>.from(json['verbTenseVariations']) : null,
      recordingPath: json['recordingPath'],
    );
  }
} 