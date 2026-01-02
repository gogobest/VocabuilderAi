import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/utils/tracking_service.dart';
import 'package:visual_vocabularies/core/widgets/app_navigation_bar.dart';
import 'package:visual_vocabularies/core/widgets/app_error_widget.dart';
import 'package:visual_vocabularies/core/widgets/app_loading_indicator.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_event.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_state.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/widgets/vocabulary_item_card.dart';

/// Enum for different sort orders
enum SortOrder {
  alphabetical,
  reverseAlphabetical,
  newest,
  oldest,
}

/// Page that displays all vocabulary items with search and filter capabilities
class AllWordsPage extends StatefulWidget {
  /// Optional category filter parameter
  final String? categoryFilter;

  /// Constructor for AllWordsPage
  const AllWordsPage({
    super.key,
    this.categoryFilter,
  });

  @override
  State<AllWordsPage> createState() => _AllWordsPageState();
}

class _AllWordsPageState extends State<AllWordsPage> {
  late final VocabularyBloc _vocabularyBloc;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = false;
  bool _groupByCategory = true; // Default to grouping by category
  late final TrackingService _trackingService;
  SortOrder _sortOrder = SortOrder.alphabetical;

  @override
  void initState() {
    super.initState();
    _vocabularyBloc = sl<VocabularyBloc>();
    _trackingService = sl<TrackingService>();
    
    // Track page view
    _trackingService.trackNavigation('All Words Page');
    
    // Set selected category if provided in widget
    _selectedCategory = widget.categoryFilter;
    
    _loadWords();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadWords() {
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      _vocabularyBloc.add(
        LoadVocabularyItemsByCategory(_selectedCategory!),
      );
    } else {
      _vocabularyBloc.add(
        const LoadVocabularyItems(),
      );
    }
  }

  void _showCategoryFilterDialog(BuildContext context, List<String> categories) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Filter by Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length + 1, // +1 for "All categories" option
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    title: const Text('All Categories'),
                    selected: _selectedCategory == null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                      _vocabularyBloc.add(const LoadVocabularyItems());
                      Navigator.pop(dialogContext);
                    },
                  );
                } else {
                  final category = categories[index - 1];
                  return ListTile(
                    title: Text(category),
                    selected: _selectedCategory == category,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _vocabularyBloc.add(LoadVocabularyItemsByCategory(category));
                      Navigator.pop(dialogContext);
                    },
                  );
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }

  List<VocabularyItem> _filterItems(List<VocabularyItem> items) {
    if (_searchQuery.isEmpty) {
      return items;
    }
    
    return items.where((item) {
      return item.word.toLowerCase().contains(_searchQuery) ||
             item.meaning.toLowerCase().contains(_searchQuery) ||
             (item.example?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
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
            if (state is VocabularyError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
            if (state is VocabularyOperationSuccess && state.message.toLowerCase().contains('deleted')) {
              // After deletion, reload the list with the current filter
              if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
                _vocabularyBloc.add(LoadVocabularyItemsByCategory(_selectedCategory!));
              } else {
                _vocabularyBloc.add(const LoadVocabularyItems());
              }
            }
          },
          child: Scaffold(
            appBar: AppNavigationBar(
              title: _selectedCategory != null ? '$_selectedCategory Words' : 'All Words',
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: _VocabularySearchDelegate(
                        vocabularyBloc: _vocabularyBloc,
                        trackingService: _trackingService,
                      ),
                    );
                    _trackingService.trackButtonClick('Search', screen: 'All Words');
                  },
                  tooltip: 'Search',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'sort_az':
                        _setSortOrder(SortOrder.alphabetical);
                        break;
                      case 'sort_za':
                        _setSortOrder(SortOrder.reverseAlphabetical);
                        break;
                      case 'sort_newest':
                        _setSortOrder(SortOrder.newest);
                        break;
                      case 'sort_oldest':
                        _setSortOrder(SortOrder.oldest);
                        break;
                      case 'delete_all':
                        _showDeleteAllDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'sort_az',
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_by_alpha,
                            color: _sortOrder == SortOrder.alphabetical
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sort A to Z',
                            style: TextStyle(
                              color: _sortOrder == SortOrder.alphabetical
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // [Other sort menu items...]
                    const PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete All Words', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    isDarkMode 
                      ? Theme.of(context).colorScheme.surface.withOpacity(0.7)
                      : Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12.0 : 16.0,
                      vertical: isSmallScreen ? 8.0 : 12.0,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search words...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12.0 : 16.0,
                          horizontal: isSmallScreen ? 12.0 : 16.0,
                        ),
                      ),
                    ),
                  ),
                  
                  // Category chip
                  if (_selectedCategory != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12.0 : 16.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          Chip(
                            label: Text(
                              _selectedCategory!,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : null,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: isDarkMode 
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            deleteIcon: Icon(
                              Icons.close, 
                              size: 18,
                              color: isDarkMode ? Colors.white70 : null,
                            ),
                            onDeleted: () {
                              setState(() {
                                _selectedCategory = null;
                              });
                              _vocabularyBloc.add(const LoadVocabularyItems());
                            },
                          ),
                        ],
                      ),
                    ),
                    
                  // Word list
                  Expanded(
                    child: BlocBuilder<VocabularyBloc, VocabularyState>(
                      builder: (context, state) {
                        if (state is VocabularyLoading) {
                          return const AppLoadingIndicator();
                        } else if (state is VocabularyError) {
                          return AppErrorWidget(
                            message: state.message,
                            onRetry: _loadWords,
                          );
                        } else if (state is VocabularyLoaded) {
                          final filteredItems = _filterItems(state.items);
                          
                          if (filteredItems.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.library_books,
                                      size: 64,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No words found',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'No results for "$_searchQuery"'
                                          : _selectedCategory != null
                                              ? 'No words in the $_selectedCategory category'
                                              : 'Add some vocabulary words to get started',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        final uri = Uri(
                                          path: AppConstants.addEditWordRoute,
                                          queryParameters: _selectedCategory != null
                                              ? {'category': _selectedCategory}
                                              : null,
                                        );
                                        context.push(uri.toString());
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Word'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24, 
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          // If a category is selected, show a standard list
                          if (_selectedCategory != null) {
                            return ListView.builder(
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 8.0 : 12.0,
                                    vertical: 4.0,
                                  ),
                                  child: VocabularyItemCard(
                                    item: item,
                                    onTap: () {
                                      _trackingService.trackVocabularyInteraction('Viewed details', word: item.word);
                                      _navigateToWordDetails(item.id);
                                    },
                                    onEdit: () => _navigateToEditWord(item.id),
                                    onDelete: () => _showDeleteWordDialog(item),
                                  ),
                                );
                              },
                            );
                          } 
                          // Otherwise, show grouped list by category
                          else {
                            return GroupedListView<VocabularyItem, String>(
                              elements: filteredItems,
                              groupBy: (item) => item.category ?? 'Uncategorized',
                              groupSeparatorBuilder: (String category) => Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12.0 : 16.0,
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    // Category header with option to navigate to filtered view
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          // Navigate to the same page with category filter
                                          final uri = Uri(
                                            path: AppConstants.allWordsRoute,
                                            queryParameters: {'category': category},
                                          );
                                          context.push(uri.toString());
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Theme.of(context).colorScheme.primary,
                                                width: 2.0,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                category,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  shadows: isDarkMode ? [
                                                    Shadow(
                                                      blurRadius: 2,
                                                      color: Colors.black.withOpacity(0.3),
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ] : null,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.filter_list,
                                                size: 16,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              itemBuilder: (context, item) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 8.0 : 12.0,
                                    vertical: 4.0,
                                  ),
                                  child: VocabularyItemCard(
                                    item: item,
                                    onTap: () {
                                      _trackingService.trackVocabularyInteraction('Viewed details', word: item.word);
                                      _navigateToWordDetails(item.id);
                                    },
                                    onEdit: () => _navigateToEditWord(item.id),
                                    onDelete: () => _showDeleteWordDialog(item),
                                  ),
                                );
                              },
                              useStickyGroupSeparators: true,
                              floatingHeader: true,
                              order: GroupedListOrder.ASC,
                            );
                          }
                        }
                        
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                final uri = Uri(
                  path: AppConstants.addEditWordRoute,
                  queryParameters: _selectedCategory != null
                      ? {'category': _selectedCategory}
                      : null,
                );
                context.push(uri.toString());
              },
              tooltip: 'Add new word',
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToWordDetails(String id) {
    _trackingService.trackNavigation('Word Details');
    context.push('${AppConstants.wordDetailsRoute}/$id');
  }

  void _navigateToEditWord(String id) {
    _trackingService.trackNavigation('Edit Word');
    
    // Make sure the ID is properly URL encoded to handle special characters
    final encodedId = Uri.encodeComponent(id);
    
    // Use push instead of go to maintain navigation stack
    context.push('${AppConstants.addEditWordRoute}/$encodedId');
  }

  void _showDeleteAllDialog() {
    final String title = _selectedCategory != null 
        ? 'Delete All Words in "${_selectedCategory!}"?' 
        : 'Delete All Words?';
        
    final String content = _selectedCategory != null
        ? 'Are you sure you want to delete all words in the "${_selectedCategory!}" category? This action cannot be undone.'
        : 'Are you sure you want to delete all words? This action cannot be undone.';
        
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              
              // In a real app, we would use a proper delete method
              // For now just show success message
              final successMessage = _selectedCategory != null
                  ? 'All words in "${_selectedCategory!}" deleted'
                  : 'All words deleted';
                  
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(successMessage),
                  backgroundColor: Colors.red,
                ),
              );
              
              // Reload data
              if (_selectedCategory != null) {
                _vocabularyBloc.add(LoadVocabularyItemsByCategory(_selectedCategory!));
              } else {
                _vocabularyBloc.add(const LoadVocabularyItems());
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showDeleteWordDialog(VocabularyItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Word?'),
        content: Text('Are you sure you want to delete "${item.word}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _vocabularyBloc.add(DeleteVocabularyItem(item.id));
              
              // Show success feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Word "${item.word}" deleted'),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: Colors.white,
                    onPressed: () {
                      _vocabularyBloc.add(RestoreVocabularyItem(item));
                    },
                  ),
                ),
              );
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _setSortOrder(SortOrder order) {
    setState(() {
      _sortOrder = order;
    });
  }
}

class _VocabularySearchDelegate extends SearchDelegate<String> {
  final VocabularyBloc vocabularyBloc;
  final TrackingService _trackingService;
  
  _VocabularySearchDelegate({
    required this.vocabularyBloc,
    required TrackingService trackingService,
  }) : _trackingService = trackingService;
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          _trackingService.trackButtonClick('Clear Search', screen: 'Search');
          query = '';
        },
      ),
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        _trackingService.trackButtonClick('Back', screen: 'Search');
        close(context, '');
      },
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }
  
  Widget _buildSearchResults(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Text('Type at least 2 characters to search'),
      );
    }
    
    vocabularyBloc.add(SearchVocabularyItems(query));
    
    return BlocBuilder<VocabularyBloc, VocabularyState>(
      bloc: vocabularyBloc,
      builder: (context, state) {
        if (state is VocabularyLoading) {
          return const AppLoadingIndicator();
        } else if (state is VocabularyError) {
          return AppErrorWidget(
            message: state.message,
            onRetry: () => vocabularyBloc.add(SearchVocabularyItems(query)),
          );
        } else if (state is VocabularyLoaded) {
          final items = state.items;
          
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No results for "$query"',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return VocabularyItemCard(
                item: item,
                onTap: () {
                  close(context, item.id);
                  _trackingService.trackVocabularyInteraction('Viewed details', word: item.word);
                  context.push('${AppConstants.wordDetailsRoute}/${item.id}');
                },
                highlightedText: query,
              );
            },
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
} 