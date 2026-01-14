// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kid.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KidAdapter extends TypeAdapter<Kid> {
  @override
  final int typeId = 0;

  @override
  Kid read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Kid(
      id: fields[0] as String?,
      name: fields[1] as String,
      parentPhone: fields[2] as String,
      durationMinutes: fields[3] as int,
      checkInTime: fields[4] as DateTime,
      isCompleted: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Kid obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.parentPhone)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.checkInTime)
      ..writeByte(5)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KidAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
