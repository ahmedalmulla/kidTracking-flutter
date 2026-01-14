import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import '../models/kid.dart';
import '../services/persistence_service.dart';
import '../services/report_service.dart';

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
    // We want to see ALL kids for that date, not just active or completed?
    // User requested "see checkout kids", but usually history implies everything for that day.
    // PersistenceService.getKidsForDate returns everything matching the date.
    final kids = PersistenceService.getKidsForDate(_selectedDate);
    // Filter only completed? "see checkout kids". 
    // Let's show all but distinguish them, or filter. 
    // Usually "History" implies past records. 
    // Let's show completed ones primarily, or all.
    // User said "see checkout kids".
    final checkoutKids = kids.where((k) => k.isCompleted).toList();
    
    setState(() {
      _kids = checkoutKids;
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
    if (picked != null && picked != _selectedDate) {
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
            onPressed: _pickDate,
          ),
          IconButton(
             icon: const Icon(Icons.email),
             tooltip: "Send Report for this date",
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
                        child: Text("No checked out kids found for this date.",
                            style: Theme.of(context).textTheme.bodyLarge))
                    : ListView.separated(
                        itemCount: _kids.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final kid = _kids[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(kid.name.substring(0, 1).toUpperCase()),
                            ),
                            title: Text(kid.name),
                            subtitle: Text("Phone: ${kid.parentPhone}"),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("In: ${DateFormat('HH:mm').format(kid.checkInTime)}"),
                                Text("${kid.durationMinutes} min"),
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
