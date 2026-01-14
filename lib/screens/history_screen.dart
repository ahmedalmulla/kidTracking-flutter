import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import '../models/kid.dart';
import '../services/persistence_service.dart';
import '../services/report_service.dart';
import '../providers/playground_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Kid> _kids = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
    });
    
    // Show kids for selected date
    List<Kid> kids = PersistenceService.getKidsForDate(_selectedDate);
    kids = kids.where((k) => k.isCompleted).toList();
    kids.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    
    setState(() {
      _kids = kids;
      _isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  Future<void> _sendReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending report...')),
      );
      await ReportService.sendDailyReport(date: _selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Filter by Date',
            onPressed: _pickDate,
          ),
          IconButton(
             icon: const Icon(Icons.email),
             tooltip: "Send Report",
             onPressed: _kids.isEmpty ? null : _sendReport,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Text(
                  "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  "Total: ${_kids.length}",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _kids.isEmpty
                    ? Center(
                        child: Text(
                          "No checked out kids found for this date.",
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ))
                    : ListView.separated(
                        itemCount: _kids.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final kid = _kids[index];
                          final hasTimeLeft = kid.remainingTimeAtCheckout.inSeconds > 0;
                          
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(kid.name.substring(0, 1).toUpperCase()),
                            ),
                            title: Text(kid.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Phone: ${kid.parentPhone}"),
                                Text(
                                  "Date: ${DateFormat('yyyy-MM-dd').format(kid.checkInTime)}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (hasTimeLeft)
                                  Text(
                                    "Time left: ${kid.remainingTimeAtCheckout.inMinutes}:${(kid.remainingTimeAtCheckout.inSeconds % 60).toString().padLeft(2, '0')}",
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("In: ${DateFormat('HH:mm').format(kid.checkInTime)}"),
                                    Text("${kid.durationMinutes} min"),
                                  ],
                                ),
                                if (hasTimeLeft) ...[
                                  const Gap(12),
                                  IconButton(
                                    onPressed: () async {
                                      // Import the provider
                                      final container = ProviderScope.containerOf(context);
                                      await container.read(activeKidsProvider.notifier).resumeKid(kid.id);
                                      
                                      // Reload data to refresh the list
                                      _loadData();
                                      
                                      // Show confirmation
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${kid.name} resumed and moved to dashboard'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.play_circle_filled),
                                    color: Colors.green,
                                    tooltip: 'Resume / Check-in',
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
