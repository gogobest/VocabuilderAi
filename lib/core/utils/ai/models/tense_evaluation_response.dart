import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'tense_evaluation_response.freezed.dart';
part 'tense_evaluation_response.g.dart';

@freezed
@HiveType(typeId: 21)
class TenseEvaluationResponse with _$TenseEvaluationResponse {
  const factory TenseEvaluationResponse({
    @HiveField(0) required bool isCorrect,
    @HiveField(1) required String tense,
    @HiveField(2) required String verbForm,
    @HiveField(3) required String grammaticalCorrection,
    @HiveField(4) required String example,
    @HiveField(5) required String learningAdvice,
    @HiveField(6) required int score,
    @HiveField(7) @Default(<String, String>{}) Map<String, String> wordEmojis,
  }) = _TenseEvaluationResponse;

  factory TenseEvaluationResponse.fromJson(Map<String, dynamic> json) =>
      _$TenseEvaluationResponseFromJson(json);
} 