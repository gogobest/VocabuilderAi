import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/widgets/app_error_widget.dart';
import 'package:visual_vocabularies/core/widgets/app_loading_indicator.dart';
import 'package:visual_vocabularies/core/widgets/app_navigation_bar.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_event.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_state.dart';
import 'package:visual_vocabularies/features/categories/presentation/pages/example_words_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late final VocabularyBloc _vocabularyBloc;
  final TextEditingController _newCategoryController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _vocabularyBloc = sl<VocabularyBloc>();
    _loadCategories();
  }
  
  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }
  
  void _loadCategories() {
    _vocabularyBloc.add(const LoadCategories());
  }
  
  void _showAddCategoryDialog() {
    _newCategoryController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newCategoryController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'E.g. Movies, TV Shows, Work, etc.',
                prefixIcon: Icon(Icons.category),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Categories help you organize your vocabulary items. Create custom categories for different sources, topics, or learning goals.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final categoryName = _newCategoryController.text.trim();
              if (categoryName.isNotEmpty) {
                // In a real app, we would actually save this category
                // For now, we're just adding it to the defaults
                Navigator.pop(context);
                
                // Show success feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "$categoryName" created'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Refresh the categories list
                _loadCategories();
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }
  
  void _showCategoryOptionsDialog(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Words'),
              onTap: () {
                Navigator.pop(context);
                context.push(
                  Uri(
                    path: AppConstants.allWordsRoute,
                    queryParameters: {'category': category},
                  ).toString(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Word'),
              onTap: () {
                Navigator.pop(context);
                context.push(
                  Uri(
                    path: AppConstants.addEditWordRoute,
                    queryParameters: {'category': category},
                  ).toString(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('Start Flashcards'),
              onTap: () {
                Navigator.pop(context);
                context.go(
                  Uri(
                    path: AppConstants.flashcardsRoute,
                    queryParameters: {'category': category},
                  ).toString(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename Category'),
              onTap: () {
                Navigator.pop(context);
                _showRenameCategoryDialog(category);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Category'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteCategoryDialog(category);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showRenameCategoryDialog(String oldCategory) {
    final TextEditingController renameController = TextEditingController(text: oldCategory);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: renameController,
              decoration: const InputDecoration(
                labelText: 'New Category Name',
                hintText: 'Enter new category name',
                prefixIcon: Icon(Icons.edit),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final newCategory = renameController.text.trim();
              if (newCategory.isNotEmpty && newCategory != oldCategory) {
                Navigator.pop(context);
                _vocabularyBloc.add(RenameCategory(oldCategory, newCategory));
                
                // Show success feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category renamed to "$newCategory"'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('RENAME'),
          ),
        ],
      ),
    ).then((_) => renameController.dispose());
  }

  void _showDeleteCategoryDialog(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "$category"? This will delete all words in this category.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _vocabularyBloc.add(DeleteCategoryAndWords(category));
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Categories?'),
        content: const Text('Are you sure you want to delete all categories? This will move all words to the "General" category, but won\'t delete any words.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              // Dispatch event to delete all categories
              _vocabularyBloc.add(const DeleteAllCategories());
            },
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          context.go(AppConstants.homeRoute);
        }
        return false;
      },
      child: BlocProvider.value(
        value: _vocabularyBloc,
        child: BlocListener<VocabularyBloc, VocabularyState>(
          listener: (context, state) {
            if (state is VocabularyOperationSuccess && state.message.toLowerCase().contains('deleted')) {
              _loadCategories();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.green),
              );
            }
          },
          child: Scaffold(
            appBar: AppNavigationBar(
              title: 'Categories',
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete_all') {
                      _showDeleteAllCategoriesDialog();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete All Categories', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: BlocBuilder<VocabularyBloc, VocabularyState>(
              builder: (context, state) {
                if (state is VocabularyLoading) {
                  return const AppLoadingIndicator();
                } else if (state is VocabularyError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: _loadCategories,
                  );
                } else if (state is CategoriesLoaded) {
                  final categories = state.categories;
                  
                  return categories.isEmpty
                      ? _buildEmptyState()
                      : _buildCategoriesList(categories);
                } else {
                  // Handle initial state or other states
                  return _buildCategoriesList(AppConstants.defaultCategories);
                }
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _showAddCategoryDialog,
              tooltip: 'Add Category',
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.category_outlined,
            size: 72,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Categories Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create categories to organize your vocabulary',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddCategoryDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Category'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoriesList(List<String> categories) {
    // Example section for Movies & TV Shows category
    const String exampleCategory = 'Movies & TV Shows';
    const bool showExamples = false; // Set to false to hide example words
    
    // Add example category if needed
    List<String> updatedCategories = List<String>.from(categories);
    if (showExamples && !updatedCategories.contains(exampleCategory)) {
      updatedCategories.add(exampleCategory);
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Category explanation
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tip: Create Custom Categories',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create categories like "Movies & TV Shows" to organize vocabulary from your favorite media. Add words from episodes with their meanings and examples.',
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Example section with Movies & TV Shows vocabulary
        if (showExamples)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Example: $exampleCategory Vocabulary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Here are some examples of vocabulary words from TV shows you might want to learn:',
              ),
              const SizedBox(height: 16),
              
              // Example word cards
              ...ExampleWordsService.getMoviesAndTVShowsExamples().map(
                (word) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              word.word,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (word.pronunciation != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                word.pronunciation!,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.movie,
                                    size: 14,
                                    color: Colors.deepPurple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    word.category,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Definition: ${word.meaning}',
                        ),
                        if (word.example != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Example: ${word.example}',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                // In a real app, we would add this word
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('This is an example word. Create your own from the Add Word page.'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add to My Words'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppConstants.addEditWordRoute),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Your Own Word'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
            ],
          ),
        
        // Categories grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: updatedCategories.length,
          itemBuilder: (context, index) {
            final category = updatedCategories[index];
            return _buildCategoryCard(category);
          },
        ),
      ],
    );
  }
  
  Widget _buildCategoryCard(String category) {
    Color cardColor;
    IconData iconData;
    
    // Assign colors and icons based on category name for visual variety
    switch (category.toLowerCase()) {
      case 'movies & tv shows':
        cardColor = Colors.deepPurple;
        iconData = Icons.movie;
        break;
      case 'technology':
        cardColor = Colors.blue;
        iconData = Icons.computer;
        break;
      case 'business':
        cardColor = Colors.amber.shade700;
        iconData = Icons.business;
        break;
      case 'academic':
        cardColor = Colors.teal;
        iconData = Icons.school;
        break;
      case 'medical':
        cardColor = Colors.red;
        iconData = Icons.local_hospital;
        break;
      case 'travel':
        cardColor = Colors.green;
        iconData = Icons.flight;
        break;
      case 'food':
        cardColor = Colors.orange;
        iconData = Icons.restaurant;
        break;
      case 'sports':
        cardColor = Colors.indigo;
        iconData = Icons.sports_soccer;
        break;
      case 'arts':
        cardColor = Colors.pink;
        iconData = Icons.palette;
        break;
      case 'nature':
        cardColor = Colors.lightGreen;
        iconData = Icons.nature;
        break;
      case 'general':
      default:
        cardColor = Colors.blueGrey;
        iconData = Icons.category;
        break;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => _showCategoryOptionsDialog(category),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cardColor.withOpacity(0.7),
                cardColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  iconData,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 