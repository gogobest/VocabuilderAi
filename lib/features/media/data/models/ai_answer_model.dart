import 'package:hive/hive.dart';
import 'package:visual_vocabularies/features/media/domain/entities/ai_answer.dart';

part 'ai_answer_model.g.dart';

@HiveType(typeId: 5)
class AIAnswerModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String question;

  @HiveField(2)
  final String answer;

  @HiveField(3)
  final String subtitleLine;

  @HiveField(4)
  final String? context;

  @HiveField(5)
  final String emoji;

  @HiveField(6)
  final String sourceMediaTitle;

  @HiveField(7)
  final int? sourceMediaSeason;

  @HiveField(8)
  final int? sourceMediaEpisode;

  @HiveField(9)
  final DateTime createdAt;

  AIAnswerModel({
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

  // Convert from entity to model
  factory AIAnswerModel.fromEntity(AIAnswer answer) {
    return AIAnswerModel(
      id: answer.id,
      question: answer.question,
      answer: answer.answer,
      subtitleLine: answer.subtitleLine,
      context: answer.context,
      emoji: answer.emoji,
      sourceMediaTitle: answer.sourceMediaTitle,
      sourceMediaSeason: answer.sourceMediaSeason,
      sourceMediaEpisode: answer.sourceMediaEpisode,
      createdAt: answer.createdAt,
    );
  }

  // Convert from model to entity
  AIAnswer toEntity() {
    return AIAnswer(
      id: id,
      question: question,
      answer: answer,
      subtitleLine: subtitleLine,
      context: context,
      emoji: emoji,
      sourceMediaTitle: sourceMediaTitle,
      sourceMediaSeason: sourceMediaSeason,
      sourceMediaEpisode: sourceMediaEpisode,
      createdAt: createdAt,
    );
  }
} 