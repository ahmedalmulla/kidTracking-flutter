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
    final isPaused = widget.kid.pausedAt != null;
    
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
      color: remaining.inSeconds == 0 
          ? Colors.red.shade50 
          : isPaused 
              ? Colors.grey.shade100 
              : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Timer display
            CircularPercentIndicator(
              radius: 40.0,
              lineWidth: 6.0,
              percent: percent,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14.0,
                    ),
                  ),
                  const Text(
                    "Left", 
                    style: TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
              progressColor: progressColor,
              backgroundColor: Colors.grey.shade200,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            
            const Gap(6),
            
            // Paused indicator
            if (isPaused)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300, width: 1.5),
                ),
                child: Text(
                  'PAUSED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            
            if (isPaused) const Gap(4),
            
            // Kid info
            Text(
              widget.kid.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            
            const Gap(2),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 10, color: Colors.grey),
                const Gap(3),
                Flexible(
                  child: Text(
                    widget.kid.parentPhone, 
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const Gap(6),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pause/Play button
                Expanded(
                  child: IconButton(
                    onPressed: () {
                      ref.read(activeKidsProvider.notifier).togglePause(widget.kid.id);
                    },
                    icon: Icon(
                      isPaused ? Icons.play_arrow : Icons.pause,
                      size: 18,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isPaused 
                          ? Colors.green.shade50 
                          : Colors.orange.shade50,
                      foregroundColor: isPaused 
                          ? Colors.green.shade700 
                          : Colors.orange.shade700,
                      padding: const EdgeInsets.all(6),
                    ),
                    tooltip: isPaused ? 'Resume' : 'Pause',
                  ),
                ),
                
                const Gap(6),
                
                // Checkout button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(activeKidsProvider.notifier).completeKid(widget.kid.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    child: const Text("Checkout"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
