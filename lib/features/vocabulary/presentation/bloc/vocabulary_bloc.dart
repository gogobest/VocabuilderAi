import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_event.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_state.dart';
import 'package:visual_vocabularies/core/utils/failure.dart';

/// BLoC for vocabulary operations
class VocabularyBloc extends Bloc<VocabularyEvent, VocabularyState> {
  final VocabularyRepository _repository;

  VocabularyBloc(this._repository) : super(const VocabularyInitial()) {
    on<LoadVocabularyItems>(_onLoadVocabularyItems);
    on<LoadVocabularyItemById>(_onLoadVocabularyItemById);
    on<LoadVocabularyItemsByCategory>(_onLoadVocabularyItemsByCategory);
    on<AddVocabularyItem>(_onAddVocabularyItem);
    on<UpdateVocabularyItem>(_onUpdateVocabularyItem);
    on<DeleteVocabularyItem>(_onDeleteVocabularyItem);
    on<SearchVocabularyItems>(_onSearchVocabularyItems);
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<ClearVocabularyItems>(_onClearVocabularyItems);
    on<DeleteCategoryAndWords>(_onDeleteCategoryAndWords);
    on<RestoreVocabularyItem>(_onRestoreVocabularyItem);
    on<RenameCategory>(_onRenameCategory);
    on<ExportVocabularyData>(_onExportVocabularyData);
    on<ImportVocabularyData>(_onImportVocabularyData);
    on<DeleteAllCategories>(_onDeleteAllCategories);
  }

  Future<void> _onLoadVocabularyItems(
    LoadVocabularyItems event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    final result = await _repository.getAllVocabularyItems();
    result.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (items) => emit(VocabularyLoaded(items)),
    );
  }

  Future<void> _onLoadVocabularyItemById(
    LoadVocabularyItemById event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    print('Loading vocabulary item by ID: ${event.id}');
    final result = await _repository.getVocabularyItemById(event.id);
    result.fold(
      (failure) {
        print('Error loading item: ${failure.message}');
        emit(VocabularyError(failure.message));
      },
      (item) {
        print('Item loaded successfully: ${item.word}');
        emit(VocabularyItemLoaded(item));
      },
    );
  }

  Future<void> _onLoadVocabularyItemsByCategory(
    LoadVocabularyItemsByCategory event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    final result = await _repository.getVocabularyItemsByCategory(event.category);
    result.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (items) => emit(VocabularyLoaded(items)),
    );
  }

  Future<void> _onAddVocabularyItem(
    AddVocabularyItem event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    final result = await _repository.addVocabularyItem(event.item);
    result.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (item) => emit(const VocabularyOperationSuccess('Word added successfully')),
    );
  }

  Future<void> _onUpdateVocabularyItem(
    UpdateVocabularyItem event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    final result = await _repository.updateVocabularyItem(event.item);
    result.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (item) => emit(const VocabularyOperationSuccess('Word updated successfully')),
    );
  }

  Future<void> _onDeleteVocabularyItem(
    DeleteVocabularyItem event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    final result = await _repository.deleteVocabularyItem(event.id);
    result.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (success) => emit(const VocabularyOperationSuccess('Word deleted successfully')),
    );
  }

  Future<void> _onSearchVocabularyItems(
    SearchVocabularyItems event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    final result = await _repository.searchVocabularyItems(event.query);
    result.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (items) => emit(VocabularyLoaded(items)),
    );
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    final result = await _repository.getAllCategories();
    result.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (categories) => emit(CategoriesLoaded(categories)),
    );
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<VocabularyState> emit,
  ) async {
    final result = await _repository.addCategory(event.category);
    result.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (_) => emit(VocabularyOperationSuccess('Category added')),
    );
    
    // Reload categories
    add(const LoadCategories());
  }
  
  /// Clears the currently loaded vocabulary items without making repository calls
  Future<void> _onClearVocabularyItems(
    ClearVocabularyItems event,
    Emitter<VocabularyState> emit,
  ) async {
    // Just emit initial state to clear the items
    emit(const VocabularyInitial());
  }

  Future<void> _onDeleteCategoryAndWords(
    DeleteCategoryAndWords event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    final allItemsResult = await _repository.getVocabularyItemsByCategory(event.category);
    if (allItemsResult.isLeft()) {
      final failure = allItemsResult.swap().getOrElse(() => ApplicationFailure('Unknown error'));
      emit(VocabularyError(failure.message));
      return;
    }
    final items = allItemsResult.getOrElse(() => []);
    bool allDeleted = true;
    for (final item in items) {
      final result = await _repository.deleteVocabularyItem(item.id);
      if (result.isLeft()) {
        allDeleted = false;
      }
    }
    if (allDeleted) {
      emit(const VocabularyOperationSuccess('Category and all words deleted successfully'));
    } else {
      emit(const VocabularyOperationSuccess('Some words could not be deleted'));
    }
    // Now fetch and emit the updated categories
    final categoriesResult = await _repository.getAllCategories();
    categoriesResult.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (categories) => emit(CategoriesLoaded(categories)),
    );
  }

  Future<void> _onRestoreVocabularyItem(
    RestoreVocabularyItem event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    final result = await _repository.addVocabularyItem(event.item);
    result.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (item) => emit(const VocabularyOperationSuccess('Word restored successfully')),
    );
  }

  Future<void> _onRenameCategory(
    RenameCategory event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    final result = await _repository.renameCategory(event.oldCategory, event.newCategory);
    result.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (_) => emit(const VocabularyOperationSuccess('Category renamed successfully')),
    );
    
    // Reload categories
    add(const LoadCategories());
  }

  Future<void> _onExportVocabularyData(
    ExportVocabularyData event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    final result = await _repository.exportVocabularyData();
    result.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (jsonData) => emit(VocabularyExported(jsonData)),
    );
  }

  Future<void> _onImportVocabularyData(
    ImportVocabularyData event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    final result = await _repository.importVocabularyData(event.jsonData);
    result.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (count) {
        emit(VocabularyImported(count));
        // Reload categories since they might have changed
        add(const LoadCategories());
      },
    );
  }

  Future<void> _onDeleteAllCategories(
    DeleteAllCategories event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(const VocabularyLoading());
    final result = await _repository.deleteAllCategories();
    result.fold(
      (failure) => emit(VocabularyError(failure.message)),
      (count) {
        emit(VocabularyOperationSuccess('All categories deleted. $count words moved to General category.'));
        // Reload categories
        add(const LoadCategories());
      },
    );
  }
} 