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
    
    // Check send status only if not test and reporting for TODAY
    final isToday = reportDate.year == now.year && reportDate.month == now.month && reportDate.day == now.day;

    if (!isTest && isToday && await isReportSentToday()) {
      print("Report already sent today.");
      return;
    }
    
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
    // Or simpler: PersistenceService should return all kids for that date from history?
    // Actually, persistence service getKidsForDate might only look at history?
    // Let's assume getHistoryKids handles it or we merge.
    // Ideally we want ALL kids checked in on that date.
    
    // We already have getKidsForDate in PersistenceService but let's check its implementation.
    // It checks _box.values. 
    // If we changed checkout to NOT delete, then _box has everything.
    // Wait, did I change checkout to NOT delete? 
    // I need to verify that in the next step.
    // For now assuming getKidsForDate returns all kids (active + completed) for that date.
    final kids = PersistenceService.getKidsForDate(reportDate);
    
    // Generate CSV
    final List<List<dynamic>> rows = [];
    rows.add(["Name", "Parent Phone", "Check In Time", "Duration (min)", "Status"]);
    
    for (var kid in kids) {
      rows.add([
        kid.name,
        kid.parentPhone,
        DateFormat('HH:mm').format(kid.checkInTime),
        kid.durationMinutes,
        kid.isCompleted ? "Completed" : "Active"
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
      // Only mark as sent if it's NOT a test and it IS for today
      if (!isTest && isToday) {
        await PersistenceService.settingsBox.put('last_report_date', now.toIso8601String());
      }
    } on MailerException catch (e) {
      print('Message not sent. \n' + e.toString());
      rethrow;
    }
  }
}
