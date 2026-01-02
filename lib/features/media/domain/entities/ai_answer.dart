class AIAnswer {
  final String id;
  final String question;
  final String answer;
  final String subtitleLine;
  final String? context;
  final String emoji;
  final String sourceMediaTitle;
  final int? sourceMediaSeason;
  final int? sourceMediaEpisode;
  final DateTime createdAt;

  const AIAnswer({
    required this.id,
    required this.question,
    required this.answer,
    required this.subtitleLine,
    this.context,
    required this.emoji,
    required this.sourceMediaTitle,
    this.sourceMediaSeason,
    this.sourceMediaEpisode,
    required this.createdAt,
  });
} 