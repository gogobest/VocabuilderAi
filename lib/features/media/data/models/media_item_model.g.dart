// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MediaItemModelAdapter extends TypeAdapter<MediaItemModel> {
  @override
  final int typeId = 2;

  @override
  MediaItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaItemModel(
      id: fields[0] as String,
      title: fields[1] as String,
      season: fields[2] as int?,
      episode: fields[3] as int?,
      coverImageUrl: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      vocabularyItemIds: (fields[6] as List).cast<String>(),
      author: fields[7] as String?,
      chapter: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MediaItemModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.season)
      ..writeByte(3)
      ..write(obj.episode)
      ..writeByte(4)
      ..write(obj.coverImageUrl)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.vocabularyItemIds)
      ..writeByte(7)
      ..write(obj.author)
      ..writeByte(8)
      ..write(obj.chapter);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
