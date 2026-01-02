import 'package:flutter/material.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/di/injection_container.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc_exports.dart';

/// A dropdown widget for selecting or adding vocabulary categories
class CategoryDropdown extends StatefulWidget {
  /// Currently selected category
  final String selectedCategory;
  
  /// Callback when category changes
  final Function(String) onCategoryChanged;

  /// Constructor for CategoryDropdown
  const CategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  bool _isAddingCustomCategory = false;
  String _customCategory = '';
  List<String> _allCategories = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  
  // Load categories from the repository
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final repository = sl<VocabularyRepository>();
      final categoriesResult = await repository.getAllCategories();
      
      setState(() {
        categoriesResult.fold(
          (failure) {
            // If failed, use default categories
            _allCategories = List.from(AppConstants.defaultCategories);
          },
          (categories) {
            _allCategories = List.from(categories);
            // Ensure we have at least the default categories
            for (final defaultCategory in AppConstants.defaultCategories) {
              if (!_allCategories.contains(defaultCategory)) {
                _allCategories.add(defaultCategory);
              }
            }
          }
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      // Fall back to default categories
      setState(() {
        _allCategories = List.from(AppConstants.defaultCategories);
        _isLoading = false;
      });
    }
  }

  // Add a new category
  void _addNewCategory(String category) {
    if (category.isNotEmpty && !_allCategories.contains(category)) {
      // Add to local state
      setState(() {
        _allCategories.add(category);
        _isAddingCustomCategory = false;
        _customCategory = '';
      });
      
      // Save to repository via bloc
      final vocabularyBloc = BlocProvider.of<VocabularyBloc>(context);
      vocabularyBloc.add(AddCategory(category));
      
      // Notify parent of the new selection
      widget.onCategoryChanged(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category'),
          SizedBox(height: 8),
          LinearProgressIndicator(),
        ],
      );
    }
    
    if (_isAddingCustomCategory) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'New Category Name *',
                    hintText: 'Enter a new category name',
                  ),
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      _customCategory = value;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle),
                color: Colors.green,
                onPressed: _customCategory.isNotEmpty 
                    ? () => _addNewCategory(_customCategory) 
                    : null,
                tooltip: 'Add Category',
              ),
              IconButton(
                icon: const Icon(Icons.cancel),
                color: Colors.red,
                onPressed: () {
                  setState(() {
                    _isAddingCustomCategory = false;
                    _customCategory = '';
                  });
                },
                tooltip: 'Cancel',
              ),
            ],
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _allCategories.contains(widget.selectedCategory) 
              ? widget.selectedCategory 
              : _allCategories.first,
          decoration: const InputDecoration(
            labelText: 'Category *',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          isDense: true,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          items: [
            ..._allCategories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(
                  category,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            // Add new category option
            const DropdownMenuItem<String>(
              value: '_add_new_',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle, color: Colors.blue, size: 16),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Add New Category',
                      style: TextStyle(color: Colors.blue, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value == '_add_new_') {
              setState(() {
                _isAddingCustomCategory = true;
              });
            } else if (value != null) {
              widget.onCategoryChanged(value);
            }
          },
        ),
      ],
    );
  }
} 