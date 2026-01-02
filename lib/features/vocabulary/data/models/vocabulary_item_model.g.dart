// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocabulary_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VocabularyItemModelAdapter extends TypeAdapter<VocabularyItemModel> {
  @override
  final int typeId = 0;

  @override
  VocabularyItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VocabularyItemModel(
      id: fields[0] as String,
      word: fields[1] as String,
      meaning: fields[2] as String,
      example: fields[3] as String?,
      category: fields[4] as String,
      imageUrl: fields[5] as String?,
      pronunciation: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      lastReviewed: fields[8] as DateTime?,
      difficultyLevel: fields[9] as int,
      masteryLevel: fields[10] as int,
      sourceMedia: fields[11] as String?,
      grammarTense: fields[12] as String?,
      wordEmoji: fields[13] as String?,
      synonyms: (fields[14] as List?)?.cast<String>(),
      antonyms: (fields[15] as List?)?.cast<String>(),
      tenseVariations: (fields[16] as Map?)?.cast<String, String>(),
      partOfSpeechNote: fields[17] as String?,
      alternateMeanings: (fields[18] as Map?)?.cast<String, String>(),
      verbTenseVariations: (fields[19] as Map?)?.cast<String, String>(),
      partOfSpeech: fields[20] as String?,
      recordingPath: fields[21] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VocabularyItemModel obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.word)
      ..writeByte(2)
      ..write(obj.meaning)
      ..writeByte(3)
      ..write(obj.example)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.pronunciation)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.lastReviewed)
      ..writeByte(9)
      ..write(obj.difficultyLevel)
      ..writeByte(10)
      ..write(obj.masteryLevel)
      ..writeByte(11)
      ..write(obj.sourceMedia)
      ..writeByte(12)
      ..write(obj.grammarTense)
      ..writeByte(13)
      ..write(obj.wordEmoji)
      ..writeByte(14)
      ..write(obj.synonyms)
      ..writeByte(15)
      ..write(obj.antonyms)
      ..writeByte(16)
      ..write(obj.tenseVariations)
      ..writeByte(17)
      ..write(obj.partOfSpeechNote)
      ..writeByte(18)
      ..write(obj.alternateMeanings)
      ..writeByte(19)
      ..write(obj.verbTenseVariations)
      ..writeByte(20)
      ..write(obj.partOfSpeech)
      ..writeByte(21)
      ..write(obj.recordingPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
