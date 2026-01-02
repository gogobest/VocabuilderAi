import 'package:equatable/equatable.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';

/// Base class for vocabulary states
abstract class VocabularyState extends Equatable {
  const VocabularyState();

  @override
  List<Object?> get props => [];
}

/// Initial state for vocabulary
class VocabularyInitial extends VocabularyState {
  const VocabularyInitial();
}

/// State when vocabulary items are loading
class VocabularyLoading extends VocabularyState {
  const VocabularyLoading();
}

/// State when vocabulary items are loaded successfully
class VocabularyLoaded extends VocabularyState {
  final List<VocabularyItem> items;

  const VocabularyLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

/// State when a single vocabulary item is loaded successfully
class VocabularyItemLoaded extends VocabularyState {
  final VocabularyItem item;

  const VocabularyItemLoaded(this.item);

  @override
  List<Object?> get props => [item];
}

/// State when categories are loaded successfully
class CategoriesLoaded extends VocabularyState {
  final List<String> categories;

  const CategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

/// State when a vocabulary operation is successful with message
class VocabularyOperationSuccess extends VocabularyState {
  final String message;

  const VocabularyOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

/// State when vocabulary data has been successfully exported
class VocabularyExported extends VocabularyState {
  final String jsonData;
  
  const VocabularyExported(this.jsonData);
  
  @override
  List<Object> get props => [jsonData];
}

/// State when vocabulary data has been successfully imported
class VocabularyImported extends VocabularyState {
  final int itemCount;
  
  const VocabularyImported(this.itemCount);
  
  @override
  List<Object> get props => [itemCount];
}

/// State when an error occurs
class VocabularyError extends VocabularyState {
  final String message;

  const VocabularyError(this.message);

  @override
  List<Object?> get props => [message];
} 