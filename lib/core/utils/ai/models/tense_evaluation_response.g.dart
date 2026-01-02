// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tense_evaluation_response.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TenseEvaluationResponseAdapter
    extends TypeAdapter<TenseEvaluationResponse> {
  @override
  final int typeId = 21;

  @override
  TenseEvaluationResponse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TenseEvaluationResponse(
      isCorrect: fields[0] as bool,
      tense: fields[1] as String,
      verbForm: fields[2] as String,
      grammaticalCorrection: fields[3] as String,
      example: fields[4] as String,
      learningAdvice: fields[5] as String,
      score: fields[6] as int,
      wordEmojis: (fields[7] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, TenseEvaluationResponse obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.isCorrect)
      ..writeByte(1)
      ..write(obj.tense)
      ..writeByte(2)
      ..write(obj.verbForm)
      ..writeByte(3)
      ..write(obj.grammaticalCorrection)
      ..writeByte(4)
      ..write(obj.example)
      ..writeByte(5)
      ..write(obj.learningAdvice)
      ..writeByte(6)
      ..write(obj.score)
      ..writeByte(7)
      ..write(obj.wordEmojis);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TenseEvaluationResponseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TenseEvaluationResponseImpl _$$TenseEvaluationResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$TenseEvaluationResponseImpl(
      isCorrect: json['isCorrect'] as bool,
      tense: json['tense'] as String,
      verbForm: json['verbForm'] as String,
      grammaticalCorrection: json['grammaticalCorrection'] as String,
      example: json['example'] as String,
      learningAdvice: json['learningAdvice'] as String,
      score: (json['score'] as num).toInt(),
      wordEmojis: (json['wordEmojis'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
    );

Map<String, dynamic> _$$TenseEvaluationResponseImplToJson(
        _$TenseEvaluationResponseImpl instance) =>
    <String, dynamic>{
      'isCorrect': instance.isCorrect,
      'tense': instance.tense,
      'verbForm': instance.verbForm,
      'grammaticalCorrection': instance.grammaticalCorrection,
      'example': instance.example,
      'learningAdvice': instance.learningAdvice,
      'score': instance.score,
      'wordEmojis': instance.wordEmojis,
    };
