import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/failure.dart';
import 'package:visual_vocabularies/core/utils/image_cache_service.dart';
import 'package:visual_vocabularies/features/vocabulary/data/models/vocabulary_item_model.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:visual_vocabularies/features/media/data/models/media_item_model.dart';
import 'package:visual_vocabularies/core/utils/ai/models/tense_evaluation_response.dart';

/// Implementation of the VocabularyRepository using Hive for local storage
class VocabularyRepositoryImpl implements VocabularyRepository {
  final Box<VocabularyItemModel> _vocabularyBox;
  final ImageCacheService _imageCacheService = ImageCacheService.instance;
  
  /// Constructor that takes a Hive Box for vocabulary items
  VocabularyRepositoryImpl(this._vocabularyBox);
  
  @override
  Future<Either<Failure, List<VocabularyItem>>> getAllVocabularyItems() async {
    try {
      final items = _vocabularyBox.values.toList();
      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Failed to get vocabulary items: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, List<VocabularyItem>>> getVocabularyItemsByCategory(String category) async {
    try {
      final items = _vocabularyBox.values.where((item) => item.category == category).toList();
      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Failed to get vocabulary items by category: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, VocabularyItem>> getVocabularyItemById(String id) async {
    try {
      final item = _vocabularyBox.values.firstWhere(
        (item) => item.id == id,
        orElse: () => throw StateError('Item not found'),
      );
      return Right(item);
    } catch (e) {
      return Left(NotFoundFailure('Vocabulary item not found: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, VocabularyItem>> addVocabularyItem(VocabularyItem item) async {
    try {
      // Process the image URL for cross-platform compatibility
      String? processedImageUrl;
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        processedImageUrl = await _imageCacheService.processImageUrl(item.imageUrl!);
      }
      
      // Create a new item with the processed image URL
      final itemToSave = item.copyWith(imageUrl: processedImageUrl);
      final model = VocabularyItemModel.fromEntity(itemToSave);
      
      await _vocabularyBox.put(model.id, model);
      return Right(model);
    } catch (e) {
      return Left(CacheFailure('Failed to add vocabulary item: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, VocabularyItem>> updateVocabularyItem(VocabularyItem item) async {
    try {
      // Check if item exists
      if (!_vocabularyBox.containsKey(item.id)) {
        return Left(NotFoundFailure('Item with ID ${item.id} not found'));
      }
      
      // Process the image URL for cross-platform compatibility
      String? processedImageUrl;
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        processedImageUrl = await _imageCacheService.processImageUrl(item.imageUrl!);
      }
      
      // Create a new item with the processed image URL
      final itemToUpdate = item.copyWith(imageUrl: processedImageUrl);
      final model = VocabularyItemModel.fromEntity(itemToUpdate);
      
      await _vocabularyBox.put(model.id, model);
      return Right(model);
    } catch (e) {
      return Left(CacheFailure('Failed to update vocabulary item: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> deleteVocabularyItem(String id) async {
    try {
      if (!_vocabularyBox.containsKey(id)) {
        return Left(NotFoundFailure('Item with ID $id not found'));
      }
      
      await _vocabularyBox.delete(id);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure('Failed to delete vocabulary item: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, List<String>>> getAllCategories() async {
    try {
      final categories = _vocabularyBox.values
          .map((item) => item.category)
          .toSet()
          .toList();
      return Right(categories);
    } catch (e) {
      return Left(CacheFailure('Failed to get categories: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> addCategory(String category) async {
    try {
      // Categories are stored implicitly with vocabulary items
      // We can just check if it already exists
      final categories = await getAllCategories();
      
      return categories.fold(
        (failure) => Left(failure),
        (existingCategories) {
          // Category already exists, so no need to do anything
          if (existingCategories.contains(category)) {
            return const Right(true);
          }
          
          // Since we can't add an empty category, we'll just return success
          // The category will be added when a vocabulary item is saved with this category
          return const Right(true);
        },
      );
    } catch (e) {
      return Left(CacheFailure('Failed to add category: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, List<VocabularyItem>>> searchVocabularyItems(String query) async {
    try {
      final lowercaseQuery = query.toLowerCase();
      final items = _vocabularyBox.values.where((item) {
        return item.word.toLowerCase().contains(lowercaseQuery) || 
               item.meaning.toLowerCase().contains(lowercaseQuery) ||
               (item.example?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Failed to search vocabulary items: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, List<VocabularyItem>>> getItemsDueForReview({int? limit}) async {
    try {
      final now = DateTime.now();
      final items = _vocabularyBox.values.where((item) {
        // If never reviewed or reviewed more than 7 days ago
        if (item.lastReviewed == null) return true;
        final daysSinceLastReview = now.difference(item.lastReviewed!).inDays;
        return daysSinceLastReview >= 7;
      }).toList();
      
      // Sort by last review date (null first) and mastery level
      items.sort((a, b) {
        if (a.lastReviewed == null && b.lastReviewed == null) {
          return a.masteryLevel.compareTo(b.masteryLevel);
        }
        if (a.lastReviewed == null) return -1;
        if (b.lastReviewed == null) return 1;
        return a.lastReviewed!.compareTo(b.lastReviewed!);
      });
      
      if (limit != null && limit < items.length) {
        return Right(items.sublist(0, limit));
      }
      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Failed to get items due for review: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> renameCategory(String oldCategory, String newCategory) async {
    try {
      // Get all items in the old category
      final items = _vocabularyBox.values.where((item) => item.category == oldCategory).toList();
      
      // Update each item with the new category
      for (final item in items) {
        final updatedItem = VocabularyItemModel(
          id: item.id,
          word: item.word,
          meaning: item.meaning,
          category: newCategory,
          imageUrl: item.imageUrl,
          example: item.example,
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
        
        await _vocabularyBox.put(updatedItem.id, updatedItem);
      }
      
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure('Failed to rename category: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, int>> deleteAllCategories() async {
    try {
      // Get all vocabulary items
      final items = _vocabularyBox.values.toList();
      int updatedCount = 0;
      
      // Update each item to use the "General" category
      for (final item in items) {
        // Skip if already in General category
        if (item.category == "General") {
          continue;
        }
        
        final updatedItem = VocabularyItemModel(
          id: item.id,
          word: item.word,
          meaning: item.meaning,
          category: "General", // Reset to General category
          imageUrl: item.imageUrl,
          example: item.example,
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
        
        await _vocabularyBox.put(updatedItem.id, updatedItem);
        updatedCount++;
      }
      
      return Right(updatedCount);
    } catch (e) {
      return Left(CacheFailure('Failed to delete all categories: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> exportVocabularyData() async {
    try {
      // Get all vocabulary items
      final items = _vocabularyBox.values.toList();
      final categories = items.map((item) => item.category).toSet().toList();
      
      // Get all media items
      final mediaBox = await Hive.openBox<MediaItemModel>('media_items');
      final mediaItems = mediaBox.values.toList();
      
      // Get saved tense review cards - both standard and organized boxes
      final tenseReviewBox = await Hive.openBox<TenseEvaluationResponse>('saved_tense_review_cards');
      final savedTenseCards = tenseReviewBox.values.toList();
      
      // Get organized tense review cards
      final organizedTenseBox = await Hive.openBox('organized_tense_review_cards');
      final organizedTenseData = <String, List<dynamic>>{};
      
      // Convert to a standard map format for JSON serialization
      for (final key in organizedTenseBox.keys) {
        if (key is String && organizedTenseBox.get(key) is List) {
          organizedTenseData[key] = List<dynamic>.from(organizedTenseBox.get(key));
        }
      }
      
      final data = {
        'vocabulary': items.map((e) => e.toJson()).toList(),
        'categories': categories,
        'media': mediaItems.map((e) => e.toJson()).toList(),
        'tenseReviewCards': savedTenseCards.map((e) => e.toJson()).toList(),
        'organizedTenseReviewCards': organizedTenseData,
      };
      return Right(jsonEncode(data));
    } catch (e) {
      return Left(ApplicationFailure('Failed to export data: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> importVocabularyData(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);
      final vocabList = (data['vocabulary'] as List)
          .map((e) => VocabularyItemModel.fromEntity(VocabularyItem.fromJson(e)))
          .toList();
      
      int importCount = 0;
      // Insert items, skipping duplicates by id
      for (final item in vocabList) {
        if (!_vocabularyBox.containsKey(item.id)) {
          await _vocabularyBox.put(item.id, item);
          importCount++;
        }
      }
      
      // Import media items if they exist in the data
      if (data.containsKey('media') && data['media'] is List && (data['media'] as List).isNotEmpty) {
        try {
          final mediaBox = await Hive.openBox<MediaItemModel>('media_items');
          final mediaItems = (data['media'] as List)
              .map((e) => MediaItemModel.fromJson(e as Map<String, dynamic>))
              .toList();
          
          // Import media items, skipping duplicates
          for (final mediaItem in mediaItems) {
            if (!mediaBox.containsKey(mediaItem.id)) {
              await mediaBox.put(mediaItem.id, mediaItem);
            }
          }
        } catch (mediaError) {
          debugPrint('Error importing media items: $mediaError');
          // Don't fail the import if media fails
        }
      }
      
      // Import tense review cards if they exist in the data
      if (data.containsKey('tenseReviewCards') && data['tenseReviewCards'] is List) {
        try {
          final tenseReviewBox = await Hive.openBox<TenseEvaluationResponse>('saved_tense_review_cards');
          final tenseReviewCards = (data['tenseReviewCards'] as List)
              .map((e) => TenseEvaluationResponse.fromJson(e as Map<String, dynamic>))
              .toList();
          
          // Import saved tense cards
          for (final card in tenseReviewCards) {
            await tenseReviewBox.add(card);
          }
          
          debugPrint('Imported ${tenseReviewCards.length} tense review cards');
        } catch (tenseCardError) {
          debugPrint('Error importing tense review cards: $tenseCardError');
          // Don't fail the import if tense cards fail
        }
      }
      
      // Import organized tense review cards if they exist
      if (data.containsKey('organizedTenseReviewCards') && 
          data['organizedTenseReviewCards'] is Map<String, dynamic>) {
        try {
          final organizedTenseBox = await Hive.openBox('organized_tense_review_cards');
          final organizedCards = data['organizedTenseReviewCards'] as Map<String, dynamic>;
          
          // Import each tense group
          for (final tense in organizedCards.keys) {
            if (organizedCards[tense] is List) {
              final cards = List<dynamic>.from(organizedCards[tense]);
              
              // If we already have cards for this tense, merge them
              List<dynamic> existingCards = [];
              if (organizedTenseBox.containsKey(tense)) {
                existingCards = List<dynamic>.from(organizedTenseBox.get(tense));
              }
              
              // Combine lists and save
              existingCards.addAll(cards);
              await organizedTenseBox.put(tense, existingCards);
            }
          }
          
          debugPrint('Imported organized tense review cards for ${organizedCards.keys.length} tenses');
        } catch (organizedTenseError) {
          debugPrint('Error importing organized tense review cards: $organizedTenseError');
          // Don't fail the import if organized tense cards fail
        }
      }
      
      return Right(importCount);
    } catch (e) {
      return Left(ApplicationFailure('Failed to import data: ${e.toString()}'));
    }
  }
} 