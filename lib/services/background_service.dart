import 'package:workmanager/workmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'report_service.dart';
import 'persistence_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final now = DateTime.now();
    debugPrint("[BG] Task started at $now");

    // Re-init Hive in background isolate
    try {
      await PersistenceService.init();
      debugPrint("[BG] Persistence initialized");
    } catch (e) {
      debugPrint("[BG] Persistence init failed: $e");
      return Future.value(false);
    }
    
    switch (task) {
      case 'sendDailyReportTask':
        try {
          // Check Schedule
          final schedule = PersistenceService.getReportScheduleTime();
          bool shouldSend = false;
          
          if (schedule == null) {
            // Default 9 PM
            if (now.hour >= 21) shouldSend = true;
            debugPrint("[BG] No schedule. Now: ${now.hour}. ShouldSend: $shouldSend");
          } else {
             final scheduledTime = DateTime(now.year, now.month, now.day, schedule.hour, schedule.minute);
             // Allow a grace period? No, just "isAfter" is fine for "Has time passed?"
             if (now.isAfter(scheduledTime)) {
               shouldSend = true;
             }
             debugPrint("[BG] Schedule: ${schedule.hour}:${schedule.minute} ($scheduledTime). Now: $now. ShouldSend: $shouldSend");
          }

          if (shouldSend) {
             if (await ReportService.isReportSentToday()) {
               debugPrint("[BG] Report already sent today. Skipping.");
             } else {
               debugPrint("[BG] Sending daily report...");
               await ReportService.sendDailyReport();
               debugPrint("[BG] Daily report sent successfully.");
             }
          } else {
            debugPrint("[BG] Not time yet.");
          }
        } catch (e) {
          debugPrint("[BG] Error sending report: $e");
          return Future.value(false);
        }
        break;
    }
    return Future.value(true);
  });

}

class BackgroundService {
  static const String taskName = 'sendDailyReportTask';
  
  static void scheduleDailyReport() async {
    // Schedule a periodic task that runs every 24 hours?
    // Or closer to a one-off that repeats.
    // Workmanager periodic is min 15 mins.
    // For 9PM every day, we might calculate initialDelay.
    
    // For simplicity, we'll scheduling a periodic task every 1 hour to check
    // "Is it past 9PM and have we not sent report yet?"
    // OR we schedule it once per day.
    
    await Workmanager().registerPeriodicTask(
      "1",
      taskName,
      frequency: const Duration(minutes: 15), 
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}
