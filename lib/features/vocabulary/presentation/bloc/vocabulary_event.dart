import 'package:equatable/equatable.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';

/// Base class for vocabulary events
abstract class VocabularyEvent extends Equatable {
  const VocabularyEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all vocabulary items
class LoadVocabularyItems extends VocabularyEvent {
  const LoadVocabularyItems();
}

/// Event to load a specific vocabulary item by ID
class LoadVocabularyItemById extends VocabularyEvent {
  final String id;

  const LoadVocabularyItemById(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event to load vocabulary items by category
class LoadVocabularyItemsByCategory extends VocabularyEvent {
  final String category;

  const LoadVocabularyItemsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event to add a new vocabulary item
class AddVocabularyItem extends VocabularyEvent {
  final VocabularyItem item;

  const AddVocabularyItem(this.item);

  @override
  List<Object?> get props => [item];
}

/// Event to update an existing vocabulary item
class UpdateVocabularyItem extends VocabularyEvent {
  final VocabularyItem item;

  const UpdateVocabularyItem(this.item);

  @override
  List<Object?> get props => [item];
}

/// Event to delete a vocabulary item
class DeleteVocabularyItem extends VocabularyEvent {
  final String id;

  const DeleteVocabularyItem(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event to search vocabulary items
class SearchVocabularyItems extends VocabularyEvent {
  final String query;

  const SearchVocabularyItems(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event to load all available categories
class LoadCategories extends VocabularyEvent {
  const LoadCategories();
}

/// Event to add a new category
class AddCategory extends VocabularyEvent {
  final String category;

  const AddCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event to clear the currently loaded vocabulary items
class ClearVocabularyItems extends VocabularyEvent {
  const ClearVocabularyItems();
}

/// Event to delete all words in a category
class DeleteCategoryAndWords extends VocabularyEvent {
  final String category;

  const DeleteCategoryAndWords(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event to restore a deleted vocabulary item
class RestoreVocabularyItem extends VocabularyEvent {
  final VocabularyItem item;

  const RestoreVocabularyItem(this.item);

  @override
  List<Object?> get props => [item];
}

/// Event to rename a category
class RenameCategory extends VocabularyEvent {
  final String oldCategory;
  final String newCategory;

  const RenameCategory(this.oldCategory, this.newCategory);

  @override
  List<Object?> get props => [oldCategory, newCategory];
}

/// Event to export vocabulary data
class ExportVocabularyData extends VocabularyEvent {
  const ExportVocabularyData();
}

/// Event to import vocabulary data from a JSON string
class ImportVocabularyData extends VocabularyEvent {
  final String jsonData;

  const ImportVocabularyData(this.jsonData);

  @override
  List<Object?> get props => [jsonData];
}

/// Event to delete all categories and reset words to General category
class DeleteAllCategories extends VocabularyEvent {
  const DeleteAllCategories();
} 