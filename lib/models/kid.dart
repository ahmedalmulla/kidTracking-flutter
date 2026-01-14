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

  @HiveField(6)
  DateTime? pausedAt;

  @HiveField(7)
  int totalPausedDurationSeconds;

  @HiveField(8)
  DateTime? completedAt;

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
  }) : id = id ?? const Uuid().v4();

  DateTime get endTime => checkInTime.add(Duration(minutes: durationMinutes, seconds: totalPausedDurationSeconds));
  
  Duration get remainingTime {
    if (isCompleted) return Duration.zero;
    
    // If currently paused, strict remaining time is calculated from the pause point
    if (pausedAt != null) {
      // Logic: EndTime is fixed relative to checkIn + totalPaused (so far).
      // But if we are paused, time is effectively stopped.
      // Actually simpler:
      // TimePassed = (Now - CheckIn) - TotalPaused
      // Remaining = Duration - TimePassed
      // BUT if paused, 'Now' effectively stops moving regarding the session.
      
      // Let's use:
      // Effective CheckIn = CheckIn + TotalPaused
      // EndTime = Effective CheckIn + Duration
      
      // If paused, we don't count time since pausedAt.
      final now = DateTime.now();
      final pauseDurationSoFar = now.difference(pausedAt!);
      // We don't verify if it's paused in the getter, we just return what it *shoud* be. 
      // If paused, the visual timer should stay static.
      // The `endTime` getter assumes we add totalPausedDurationSeconds.
      // If we are currently paused, `totalPausedDurationSeconds` hasn't been updated yet (it updates on resume).
      // So visual remaining time should be: 
      // EndTime (calculated with known totalPaused) - PausedAt
      
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
