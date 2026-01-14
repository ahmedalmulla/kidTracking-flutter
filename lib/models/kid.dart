import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'kid.g.dart';

@HiveType(typeId: 0)
class Kid extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String parentPhone;

  @HiveField(3)
  final int durationMinutes;

  @HiveField(4)
  final DateTime checkInTime;

  @HiveField(5)
  bool isCompleted;

  Kid({
    String? id,
    required this.name,
    required this.parentPhone,
    required this.durationMinutes,
    required this.checkInTime,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  DateTime get endTime => checkInTime.add(Duration(minutes: durationMinutes));
  
  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }
}
