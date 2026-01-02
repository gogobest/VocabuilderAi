import 'package:flutter/material.dart';
import 'package:visual_vocabularies/features/synonyms_game/presentation/pages/synonyms_game_page.dart';

/// A page specifically for playing with marked synonyms
class MarkedSynonymsGamePage extends StatelessWidget {
  /// Optional category filter
  final String? categoryFilter;
  
  /// Constructor for MarkedSynonymsGamePage
  const MarkedSynonymsGamePage({
    super.key,
    this.categoryFilter,
  });

  @override
  Widget build(BuildContext context) {
    return SynonymsGamePage(
      categoryFilter: categoryFilter,
      onlyMarkedSynonyms: true,
    );
  }
} 