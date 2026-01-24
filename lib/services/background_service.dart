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
    } catch (e, stack) {
      debugPrint("[BG] Persistence init failed: $e\n$stack");
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
            debugPrint("[BG] No schedule found in settings. Defaulting to 9 PM rule. Current hour: ${now.hour}. ShouldSend: $shouldSend");
          } else {
             final scheduledTime = DateTime(now.year, now.month, now.day, schedule.hour, schedule.minute);
             if (now.isAfter(scheduledTime)) {
               shouldSend = true;
             }
             debugPrint("[BG] Schedule found: ${schedule.hour}:${schedule.minute}. Current time: $now. ShouldSend: $shouldSend");
          }

          if (shouldSend) {
             final alreadySent = await ReportService.isReportSentToday();
             if (alreadySent) {
               debugPrint("[BG] Report already sent today according to settings. Skipping.");
             } else {
               debugPrint("[BG] Attempting to send daily report...");
               await ReportService.sendDailyReport();
               debugPrint("[BG] Daily report task finished successfully.");
             }
          } else {
            debugPrint("[BG] Not time to send report yet.");
          }
        } catch (e, stack) {
          debugPrint("[BG] Error during report task: $e\n$stack");
          return Future.value(false);
        }
        break;
      default:
        debugPrint("[BG] Unknown task: $task");
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
