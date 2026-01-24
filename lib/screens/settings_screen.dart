import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../services/persistence_service.dart';
import '../services/report_service.dart';
import '../providers/playground_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _recipientController = TextEditingController();
  final _durationsController = TextEditingController();
  TimeOfDay? _reportTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  void _loadSettings() {
    final settings = PersistenceService.getSmtpSettings();
    _emailController.text = settings['email'];
    _passwordController.text = settings['password'];
    _hostController.text = settings['host'];
    _portController.text = settings['port'].toString();
    _recipientController.text = settings['toEmail'];
    _reportTime = PersistenceService.getReportScheduleTime();
    
    final durations = PersistenceService.getCustomDurations();
    _durationsController.text = durations.join(', ');
  }

  Future<void> _pickTime() async {
    final pickedContext = context; // Capture context
    final time = await showTimePicker(
      context: pickedContext,
      initialTime: _reportTime ?? const TimeOfDay(hour: 21, minute: 0),
    );
    
    if (time != null) {
      setState(() {
        _reportTime = time;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    await PersistenceService.saveSmtpSettings(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 587,
      toEmail: _recipientController.text.trim(),
    );
    
    // Save durations
    try {
      final List<int> durations = _durationsController.text
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .where((e) => e != null)
          .cast<int>()
          .toList();
      if (durations.isNotEmpty) {
        await PersistenceService.saveCustomDurations(durations);
      }
    } catch (e) {
      debugPrint("Error saving durations: $e");
    }

    if (_reportTime != null) {
      await PersistenceService.saveReportScheduleTime(_reportTime!.hour, _reportTime!.minute);
    }
    if (_reportTime != null) {
      await PersistenceService.saveReportScheduleTime(_reportTime!.hour, _reportTime!.minute);
    }
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings Saved')));
    }
  }

  Future<void> _testEmail() async {
     setState(() => _isLoading = true);
     try {
       // Force send report even if empty or sent, just to test connection
      await ReportService.sendDailyReport(
         overrideEmail: _emailController.text.trim(),
         overridePassword: _passwordController.text.trim(),
         overrideHost: _hostController.text.trim(),
         overridePort: int.tryParse(_portController.text.trim()),
         overrideTo: _recipientController.text.trim(),
         isTest: true,
       );
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test Report Sent (Check Inbox)')));
       }
     } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
       }
     } finally {
       setState(() => _isLoading = false);
     }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email Configuration (SMTP)", style: Theme.of(context).textTheme.headlineSmall),
                  const Gap(8),
                  const Text("Configure how the daily report email is sent."),
                  const Gap(24),
                  TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(labelText: "SMTP Host (e.g. smtp.gmail.com)"),
                  ),
                  const Gap(16),
                  TextField(
                    controller: _portController,
                    decoration: const InputDecoration(labelText: "SMTP Port (e.g. 587 or 465)"),
                    keyboardType: TextInputType.number,
                  ),
                  const Gap(16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Sender Email Address"),
                  ),
                  const Gap(16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: "App Password"),
                    obscureText: true,
                  ),
                  const Gap(16),
                  const Gap(16),
                  TextField(
                    controller: _recipientController,
                    decoration: const InputDecoration(labelText: "Recipient Email(s)"),
                  ),
                  const Gap(24),
                  const Gap(24),
                  const Divider(),
                  const Gap(24),
                  Text("Duration Shortcuts", style: Theme.of(context).textTheme.headlineSmall),
                  const Gap(8),
                  const Text("Customize time buttons (comma separated minutes)."),
                  const Gap(16),
                  TextField(
                    controller: _durationsController,
                    decoration: const InputDecoration(labelText: "Durations (e.g. 30, 60, 90, 120)"),
                  ),
                  const Gap(24),
                  const Divider(),
                  const Gap(24),
                  Text("Schedule", style: Theme.of(context).textTheme.headlineSmall),
                  const Gap(8),
                  ListTile(
                    title: const Text("Daily Report Time"),
                    subtitle: Text(_reportTime != null ? _reportTime!.format(context) : "Not Set (Default 9:00 PM)"),
                    trailing: const Icon(Icons.access_time),
                    onTap: _pickTime,
                  ),
                  const Gap(24),
                  const Divider(),
                  const Gap(24),
                  Text("Playground Zone", style: Theme.of(context).textTheme.headlineSmall),
                  const Gap(8),
                  const Text("Change the active zone for new registrations."),
                  const Gap(16),
                  Consumer(
                    builder: (context, ref, child) {
                      final currentZone = ref.watch(currentZoneProvider);
                      return Wrap(
                        spacing: 8.0,
                        children: ['Trampoline', 'Ninja Course', 'Climbing'].map((zone) {
                          return ChoiceChip(
                            label: Text(zone),
                            selected: currentZone == zone,
                            onSelected: (selected) {
                              if (selected) {
                                PersistenceService.saveSelectedZone(zone);
                                ref.read(currentZoneProvider.notifier).setZone(zone);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Zone changed to $zone')),
                                );
                              }
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const Gap(32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : _testEmail,
                        child: const Text("Test Send Report"),
                      ),
                      const Gap(16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveSettings,
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Save Settings"),
                      ),
                    ],
                  ),
                  const Gap(24),
                  const Divider(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
