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
    await PersistenceService.updateKid(kid);
    state = PersistenceService.getActiveKids();
  }
}
