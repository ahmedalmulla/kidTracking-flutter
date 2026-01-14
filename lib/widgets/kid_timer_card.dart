import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:gap/gap.dart';
import '../models/kid.dart';
import '../providers/playground_provider.dart';

class KidTimerCard extends ConsumerStatefulWidget {
  final Kid kid;

  const KidTimerCard({super.key, required this.kid});

  @override
  ConsumerState<KidTimerCard> createState() => _KidTimerCardState();
}

class _KidTimerCardState extends ConsumerState<KidTimerCard> {
  late Timer _timer;
  bool _alertShown = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.kid.remainingTime;
    final totalSeconds = widget.kid.durationMinutes * 60;
    final remainingSeconds = remaining.inSeconds > 0 ? remaining.inSeconds : 0;
    
    // Progress calculation
    double percent = remainingSeconds / totalSeconds;
    if (percent < 0) percent = 0;
    if (percent > 1) percent = 1;

    // Color logic
    Color progressColor = Colors.green;
    if (remaining.inMinutes < 5) progressColor = Colors.orange;
    if (remaining.inSeconds == 0) progressColor = Colors.red;

    return Card(
      elevation: 4,
      color: remaining.inSeconds == 0 ? Colors.red.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 60.0,
              lineWidth: 10.0,
              percent: percent,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                    "${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
                  ),
                  const Text("Left", style: TextStyle(fontSize: 12)),
                ],
              ),
              progressColor: progressColor,
              backgroundColor: Colors.grey.shade200,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const Gap(16),
            Text(
              widget.kid.name,
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const Gap(4),
                Text(widget.kid.parentPhone, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                 ref.read(activeKidsProvider.notifier).completeKid(widget.kid.id);
              },
              icon: const Icon(Icons.check),
              label: const Text("Checkout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue,
              ),
            )
          ],
        ),
      ),
    );
  }
}
