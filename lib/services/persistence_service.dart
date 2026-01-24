import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/kid.dart';

class PersistenceService {
  static const String _kidBoxName = 'kidsBox';
  static const String _settingsBoxName = 'settingsBox';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
       Hive.registerAdapter(KidAdapter());
    }
    await Hive.openBox<Kid>(_kidBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  static Box<Kid> get _box => Hive.box<Kid>(_kidBoxName);
  static Box get settingsBox => Hive.box(_settingsBoxName);

  // CRUD
  static Future<void> addKid(Kid kid) async {
    await _box.put(kid.id, kid);
  }

  static Future<void> updateKid(Kid kid) async {
    await kid.save();
  }

  static Future<void> deleteKid(String id) async {
    await _box.delete(id);
  }
  
  static List<Kid> getActiveKids() {
    return _box.values.where((k) => !k.isCompleted).toList();
  }

  static List<Kid> getAllKids() {
    return _box.values.toList();
  }

  static List<Kid> getKidsForDate(DateTime date) {
    return _box.values.where((k) {
      return k.checkInTime.year == date.year &&
             k.checkInTime.month == date.month &&
             k.checkInTime.day == date.day;
    }).toList();
  }
  
  // History Helpers
  static List<Kid> getHistoryKids({DateTime? date}) {
    if (date == null) {
      return _box.values.where((k) => k.isCompleted).toList();
    }
    return _box.values.where((k) {
      return k.isCompleted &&
             k.checkInTime.year == date.year &&
             k.checkInTime.month == date.month &&
             k.checkInTime.day == date.day;
    }).toList();
  }

  // Settings Helpers
  static Future<void> saveReportScheduleTime(int hour, int minute) async {
    await settingsBox.put('report_hour', hour);
    await settingsBox.put('report_minute', minute);
  }

  static TimeOfDay? getReportScheduleTime() {
    final hour = settingsBox.get('report_hour');
    final minute = settingsBox.get('report_minute');
    if (hour is! int || minute is! int) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static Future<void> saveSmtpSettings({
    required String email,
    required String password,
    required String host,
    required int port,
    required String toEmail,
  }) async {
    await settingsBox.put('smtp_email', email);
    await settingsBox.put('smtp_password', password);
    await settingsBox.put('smtp_host', host);
    await settingsBox.put('smtp_port', port);
    await settingsBox.put('recipient_email', toEmail);
  }
  
  static Map<String, dynamic> getSmtpSettings() {
    final port = settingsBox.get('smtp_port');
    return {
      'email': settingsBox.get('smtp_email', defaultValue: ''),
      'password': settingsBox.get('smtp_password', defaultValue: ''),
      'host': settingsBox.get('smtp_host', defaultValue: 'smtp.gmail.com'),
      'port': (port is int) ? port : 587,
      'toEmail': settingsBox.get('recipient_email', defaultValue: ''),
    };
  }

  // Zone Helpers
  static Future<void> saveSelectedZone(String zone) async {
    await settingsBox.put('current_zone', zone);
  }

  static String? getSelectedZone() {
    return settingsBox.get('current_zone');
  }

  // Duration Helpers
  static Future<void> saveCustomDurations(List<int> durations) async {
    await settingsBox.put('custom_durations', durations);
  }

  static List<int> getCustomDurations() {
    final List<dynamic>? stored = settingsBox.get('custom_durations');
    if (stored == null) return [30, 60, 90, 120];
    return stored.cast<int>().toList();
  }
}
