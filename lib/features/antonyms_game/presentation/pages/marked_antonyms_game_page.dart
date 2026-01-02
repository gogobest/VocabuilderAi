import 'package:flutter/material.dart';
import 'package:visual_vocabularies/features/antonyms_game/presentation/pages/antonyms_game_page.dart';

/// A page specifically for playing with marked antonyms
class MarkedAntonymsGamePage extends StatelessWidget {
  /// Optional category filter
  final String? categoryFilter;
  
  /// Constructor for MarkedAntonymsGamePage
  const MarkedAntonymsGamePage({
    super.key,
    this.categoryFilter,
  });

  @override
  Widget build(BuildContext context) {
    return AntonymsGamePage(
      categoryFilter: categoryFilter,
      onlyMarkedAntonyms: true,
    );
  }
} 