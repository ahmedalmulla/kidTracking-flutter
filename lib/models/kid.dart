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

  @HiveField(3, defaultValue: 60)
  final int durationMinutes;

  @HiveField(4)
  final DateTime checkInTime;

  @HiveField(5, defaultValue: false)
  bool isCompleted;

  @HiveField(6)
  DateTime? pausedAt;

  @HiveField(7, defaultValue: 0)
  int totalPausedDurationSeconds;
  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9, defaultValue: 'Trampoline')
  final String zone;

  Kid({
    String? id,
    required this.name,
    required this.parentPhone,
    required this.durationMinutes,
    required this.checkInTime,
    this.isCompleted = false,
    this.pausedAt,
    this.totalPausedDurationSeconds = 0,
    this.completedAt,
    required this.zone,
  }) : id = id ?? const Uuid().v4();

  DateTime get endTime => checkInTime.add(Duration(minutes: durationMinutes, seconds: totalPausedDurationSeconds));
  
  Duration get elapsedTime {
    // 1. If paused, duration stopped accumulating at pausedAt
    //    (Whether completed or not, if pausedAt exists and wasn't cleared, it implies we paused then maybe completed)
    if (pausedAt != null) {
       return pausedAt!.difference(checkInTime) - Duration(seconds: totalPausedDurationSeconds);
    }
    
    // 2. If completed (and not paused logic above), duration stopped at completedAt
    if (completedAt != null) {
      return completedAt!.difference(checkInTime) - Duration(seconds: totalPausedDurationSeconds);
    }
    
    // 3. Otherwise (Active and running), duration is until Now
    return DateTime.now().difference(checkInTime) - Duration(seconds: totalPausedDurationSeconds);
  }

  Duration get remainingTime {
    if (isCompleted) return Duration.zero;
    
    // Open Duration (Unlimited)
    if (durationMinutes == 0) {
      return const Duration(days: 365); // Effectively infinite so no alert
    }
    
    // If currently paused, strict remaining time is calculated from the pause point
    if (pausedAt != null) {
      final currentEndTime = checkInTime.add(Duration(minutes: durationMinutes, seconds: totalPausedDurationSeconds));
      if (pausedAt!.isAfter(currentEndTime)) return Duration.zero;
      return currentEndTime.difference(pausedAt!);
    }

    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }

  // Calculate remaining time at the moment of checkout (for history display)
  Duration get remainingTimeAtCheckout {
    if (completedAt == null) return Duration.zero;
    
    final effectiveEndTime = checkInTime.add(Duration(minutes: durationMinutes, seconds: totalPausedDurationSeconds));
    if (completedAt!.isAfter(effectiveEndTime)) return Duration.zero;
    return effectiveEndTime.difference(completedAt!);
  }
}
