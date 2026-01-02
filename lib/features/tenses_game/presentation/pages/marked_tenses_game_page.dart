import 'package:flutter/material.dart';
import 'package:visual_vocabularies/features/tenses_game/presentation/pages/tenses_game_page.dart';

/// A page specifically for playing with marked words for tenses practice
class MarkedTensesGamePage extends StatelessWidget {
  /// Optional category filter
  final String? categoryFilter;
  
  /// Constructor for MarkedTensesGamePage
  const MarkedTensesGamePage({
    super.key,
    this.categoryFilter,
  });

  @override
  Widget build(BuildContext context) {
    return TensesGamePage(
      categoryFilter: categoryFilter,
      onlyMarkedWords: true,
    );
  }
} 