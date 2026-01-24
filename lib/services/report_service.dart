import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'persistence_service.dart';

class ReportService {
  
  static Future<bool> isReportSentToday() async {
    final lastSent = PersistenceService.settingsBox.get('last_report_date');
    if (lastSent == null) return false;
    
    final date = DateTime.parse(lastSent);
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  static Future<void> sendDailyReport({
    String? overrideEmail,
    String? overridePassword,
    String? overrideHost,
    int? overridePort,
    String? overrideTo,
    bool isTest = false,
    DateTime? date, // Specific date to report
  }) async {
    final now = DateTime.now();
    final reportDate = date ?? now;
    
    // Check send status: LIMIT REMOVED per user request
    // Users can now send multiple reports per day.
    
    final settings = PersistenceService.getSmtpSettings();
    final String username = overrideEmail ?? settings['email'];
    final String password = overridePassword ?? settings['password'];
    final String host = overrideHost ?? settings['host'];
    final int port = overridePort ?? settings['port'];
    final String recipients = overrideTo ?? settings['toEmail'];
    
    if (username.isEmpty || password.isEmpty || recipients.isEmpty) {
      throw Exception("SMTP settings incomplete. Please check Email, Password, and Recipient fields.");
    }

    // Combined active kids (if today) and history kids for that date
    // PersistenceService.getKidsForDate returns all kids (active + completed) for that date.
    final kids = PersistenceService.getKidsForDate(reportDate);
    
    // Generate CSV
    final List<List<dynamic>> rows = [];
    rows.add(["Name", "Parent Phone", "Check In Time", "Check Out Time", "Duration (min)", "Zone", "Status"]);
    
    for (var kid in kids) {
      final checkOutTime = kid.completedAt != null ? DateFormat('HH:mm').format(kid.completedAt!) : "-";
      
      String durationStr;
      if (kid.durationMinutes == 0) {
        durationStr = "${kid.elapsedTime.inMinutes} (Open)";
      } else {
        durationStr = "${kid.durationMinutes}";
      }

      String status;
      if (!kid.isCompleted) {
        status = "Active";
      } else {
        if (kid.durationMinutes == 0) {
          status = "Completed";
        } else {
          // Check if they completed the full duration
          // We allow a small buffer e.g. 1 minute if needed, but let's be strict for now or use >= duration - 1
          // User said "if he completed the full duration".
          if (kid.elapsedTime.inMinutes >= kid.durationMinutes) {
             status = "Completed";
          } else {
             status = "Incomplete";
          }
        }
      }

      rows.add([
        kid.name,
        kid.parentPhone,
        DateFormat('HH:mm').format(kid.checkInTime),
        checkOutTime,
        durationStr,
        kid.zone,
        status
      ]);
    }
    
    final csvData = const ListToCsvConverter().convert(rows);
    
    // Save to temp file
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/report_${DateFormat('yyyyMMdd').format(reportDate)}.csv";
    final file = File(path);
    await file.writeAsString(csvData);
    
    // Build Email Body
    final sb = StringBuffer();
    sb.writeln('Daily Playground Activity Report - ${DateFormat('yyyy-MM-dd').format(reportDate)}');
    if (isTest) sb.writeln('(TEST EMAIL)');
    sb.writeln('');
    sb.writeln('Please find the attached CSV report.');
    sb.writeln('Total Kids: ${kids.length}');
    
    final smtpServer = SmtpServer(host, port: port, username: username, password: password, ssl: port == 465);

    final message = Message()
      ..from = Address(username, 'Playground System')
      ..recipients.add(recipients)
      ..subject = 'Daily Report - ${DateFormat('yyyy-MM-dd').format(reportDate)} ${isTest ? '[TEST]' : ''}'
      ..text = sb.toString()
      ..attachments.add(FileAttachment(file));

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      // No longer marking as sent since limit is removed
    } on MailerException catch (e) {
      print('Message not sent. \n' + e.toString());
      rethrow;
    }
  }
}
