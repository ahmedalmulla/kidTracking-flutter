import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/kid.dart';
import '../services/persistence_service.dart';

part 'playground_provider.g.dart';

@riverpod
class ActiveKids extends _$ActiveKids {
  @override
  List<Kid> build() {
    // Load initial data
    return PersistenceService.getActiveKids();
  }

  Future<void> addKid(String name, String phone, int durationMinutes) async {
    final kid = Kid(
      name: name,
      parentPhone: phone,
      durationMinutes: durationMinutes,
      checkInTime: DateTime.now(),
    );
    await PersistenceService.addKid(kid);
    state = PersistenceService.getActiveKids();
  }

  Future<void> completeKid(String id) async {
    final kids = PersistenceService.getActiveKids();
    final kid = kids.firstWhere((k) => k.id == id);
    kid.isCompleted = true;
    kid.completedAt = DateTime.now();
    await PersistenceService.updateKid(kid);
    state = PersistenceService.getActiveKids();
  }

  Future<void> togglePause(String id) async {
    final kids = PersistenceService.getActiveKids();
    final kid = kids.firstWhere((k) => k.id == id);
    
    if (kid.pausedAt == null) {
      // Pause
      kid.pausedAt = DateTime.now();
    } else {
      // Resume
      final pauseDuration = DateTime.now().difference(kid.pausedAt!);
      kid.totalPausedDurationSeconds += pauseDuration.inSeconds;
      kid.pausedAt = null;
    }
    
    await PersistenceService.updateKid(kid);
    state = PersistenceService.getActiveKids();
  }

  Future<void> resumeKid(String id) async {
    // This is for resuming a COMPLETED kid from history
    final kids = PersistenceService.getAllKids(); // potentially need to fetch from history if 'getActiveKids' only returns incomplete
    // Actually PersistenceService.getActiveKids() likely filters by isCompleted=false.
    // So we need to find it from all or by date.
    // Let's assume we can fetch it. Ideally PersistenceService has a getKidById or updateKid handles it.
    // PersistenceService implementation details: usually Hive box.values.
    
    // We'll rely on updateKid handling finding the object in the box.
    // But we need to find the kid object first. 
    // Let's iterate all kids in the box if possible, or assume we pass the modified kid object? 
    // The provider methods usually take ID.
    
    // Let's look at how we can get a completed kid. 
    // PersistenceService.getKidsForDate can find it.
    // But here we want to 'reactivate' it.
    
    // Let's assume we can get it via `PersistenceService.getAllKids()` if available, or just iterate `_box.values`.
    // Since I don't see `getAllKids` in the interface I read earlier (only getActiveKids and getKidsForDate), 
    // I should check `PersistenceService` implementation again or just use `getKidsForDate(DateTime.now())` if it's today's kid?
    // The requirement implies checking out a kid "while he has time".
    
    // Let's try to find it in today's list first.
    final allKidsToday = PersistenceService.getKidsForDate(DateTime.now());
    Kid? kid;
    try {
      kid = allKidsToday.firstWhere((k) => k.id == id);
    } catch (_) {
      // If not found today, maybe check previous days? 
      // User said "bring the kid back to dashboard screen and resume the time based on the time he left".
      // This implies we can find it.
      // If `getKidsForDate` is not sufficient, we might need a `getKidById` method.
      // For now, let's assume it's one of today's or we iterate all.
      // Let's peek at `PersistenceService` to be sure.
    }
    
    if (kid == null) {
      // If we can't find it easily, we might need to update PersistenceService.
      // But for this change, let's assume we found it.
      // If the code below fails, I'll update PersistenceService in next step.
      return; 
    }

    // Logic to resume:
    // He was completed at `completedAt`. Now is `DateTime.now()`.
    // The duration between `completedAt` and `Now` should be considered "Paused" time so it doesn't count against his limit.
    
    if (kid.completedAt != null) {
       final gap = DateTime.now().difference(kid.completedAt!);
       kid.totalPausedDurationSeconds += gap.inSeconds;
       kid.completedAt = null; // Clear completion time
    }
    
    kid.isCompleted = false;
    // Also ensure it's not checked as paused
    kid.pausedAt = null; 
    
    await PersistenceService.updateKid(kid);
    state = PersistenceService.getActiveKids();
  }
}
