import 'package:dartz/dartz.dart';
import 'package:visual_vocabularies/core/utils/failure.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';

/// Repository interface for vocabulary items
/// Handles all CRUD operations and additional functionality for vocabulary management
abstract class VocabularyRepository {
  /// Get all vocabulary items
  /// Returns a list of all vocabulary items or a failure if the operation fails
  Future<Either<Failure, List<VocabularyItem>>> getAllVocabularyItems();

  /// Get vocabulary items by category
  /// [category] - The category to filter by
  /// Returns a list of vocabulary items in the specified category or a failure if the operation fails
  Future<Either<Failure, List<VocabularyItem>>> getVocabularyItemsByCategory(String category);

  /// Get vocabulary item by ID
  /// [id] - The unique identifier of the vocabulary item
  /// Returns the vocabulary item or a failure if not found
  Future<Either<Failure, VocabularyItem>> getVocabularyItemById(String id);

  /// Add a new vocabulary item
  /// [item] - The vocabulary item to add
  /// Returns the added item or a failure if the operation fails
  Future<Either<Failure, VocabularyItem>> addVocabularyItem(VocabularyItem item);

  /// Update an existing vocabulary item
  /// [item] - The vocabulary item to update
  /// Returns the updated item or a failure if the operation fails
  Future<Either<Failure, VocabularyItem>> updateVocabularyItem(VocabularyItem item);

  /// Delete a vocabulary item
  /// [id] - The unique identifier of the vocabulary item to delete
  /// Returns true if successful or a failure if the operation fails
  Future<Either<Failure, bool>> deleteVocabularyItem(String id);

  /// Get all available categories
  /// Returns a list of all unique categories or a failure if the operation fails
  Future<Either<Failure, List<String>>> getAllCategories();

  /// Add a new category
  /// [category] - The category to add
  /// Returns true if successful or a failure if the operation fails
  Future<Either<Failure, bool>> addCategory(String category);

  /// Search vocabulary items by query
  /// [query] - The search query
  /// Returns a list of matching vocabulary items or a failure if the operation fails
  Future<Either<Failure, List<VocabularyItem>>> searchVocabularyItems(String query);

  /// Get items due for review
  /// [limit] - Optional limit on the number of items to return
  /// Returns a list of items that need review or a failure if the operation fails
  Future<Either<Failure, List<VocabularyItem>>> getItemsDueForReview({int? limit});

  /// Rename a category and update all items in that category
  /// [oldCategory] - The current category name
  /// [newCategory] - The new category name
  /// Returns true if successful or a failure if the operation fails
  Future<Either<Failure, bool>> renameCategory(String oldCategory, String newCategory);
  
  /// Delete all categories and reset all words to "General" category
  /// This changes the category of all words but does not delete any words
  /// Returns number of words updated or a failure if the operation fails
  Future<Either<Failure, int>> deleteAllCategories();
  
  /// Export all vocabulary items and categories as a JSON string
  /// Returns the JSON data as a string or a failure if the operation fails
  Future<Either<Failure, String>> exportVocabularyData();
  
  /// Import vocabulary items and categories from a JSON string
  /// [jsonData] - The JSON data containing vocabulary items and categories
  /// Returns the number of items imported or a failure if the operation fails
  Future<Either<Failure, int>> importVocabularyData(String jsonData);
} 