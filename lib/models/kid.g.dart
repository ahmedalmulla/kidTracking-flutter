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
      durationMinutes: fields[3] == null ? 60 : fields[3] as int,
      checkInTime: fields[4] as DateTime,
      isCompleted: fields[5] == null ? false : fields[5] as bool,
      pausedAt: fields[6] as DateTime?,
      totalPausedDurationSeconds: fields[7] == null ? 0 : fields[7] as int,
      completedAt: fields[8] as DateTime?,
      zone: fields[9] == null ? 'Trampoline' : fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Kid obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.pausedAt)
      ..writeByte(7)
      ..write(obj.totalPausedDurationSeconds)
      ..writeByte(8)
      ..write(obj.completedAt)
      ..writeByte(9)
      ..write(obj.zone);
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
