// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_answer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AIAnswerModelAdapter extends TypeAdapter<AIAnswerModel> {
  @override
  final int typeId = 5;

  @override
  AIAnswerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AIAnswerModel(
      id: fields[0] as String,
      question: fields[1] as String,
      answer: fields[2] as String,
      subtitleLine: fields[3] as String,
      context: fields[4] as String?,
      emoji: fields[5] as String,
      sourceMediaTitle: fields[6] as String,
      sourceMediaSeason: fields[7] as int?,
      sourceMediaEpisode: fields[8] as int?,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AIAnswerModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.question)
      ..writeByte(2)
      ..write(obj.answer)
      ..writeByte(3)
      ..write(obj.subtitleLine)
      ..writeByte(4)
      ..write(obj.context)
      ..writeByte(5)
      ..write(obj.emoji)
      ..writeByte(6)
      ..write(obj.sourceMediaTitle)
      ..writeByte(7)
      ..write(obj.sourceMediaSeason)
      ..writeByte(8)
      ..write(obj.sourceMediaEpisode)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIAnswerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
