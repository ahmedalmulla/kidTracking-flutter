import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../providers/playground_provider.dart';
import '../widgets/kid_timer_card.dart';
import '../widgets/registration_form.dart'; 
import 'history_screen.dart';
import 'settings_screen.dart';
import '../services/notification_service.dart';
import 'dart:async';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  Timer? _globalTimer;
  final Set<String> _alertedKidIds = {};
  final Map<String, DateTime> _snoozedUntil = {};

  @override
  void initState() {
    super.initState();
    // Init local notifications
    NotificationService.init();
    // Start global check
    _startGlobalCheck();
  }

  void _startGlobalCheck() {
    _globalTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final activeKids = ref.read(activeKidsProvider);
      final now = DateTime.now();
      // debugPrint("Checking active kids: ${activeKids.length}");

      for (var kid in activeKids) {
        // Handle Snooze Expiration
        if (_snoozedUntil.containsKey(kid.id)) {
           if (now.isAfter(_snoozedUntil[kid.id]!)) {
             debugPrint("Snooze expired for ${kid.name}");
             // Snooze expired, allow re-alert
             _snoozedUntil.remove(kid.id);
             _alertedKidIds.remove(kid.id);
           } else {
             // Still snoozed, skip
             // debugPrint("Skipping ${kid.name} (Snoozed)");
             continue; 
           }
        }

        if (kid.remainingTime.inSeconds <= 0 && !_alertedKidIds.contains(kid.id)) {
          debugPrint("Triggering alert for ${kid.name}");
          _showAlert(kid);
          _alertedKidIds.add(kid.id);
        }
      }
    });
  }

  Future<void> _showAlert(dynamic kid) async {
    // Play sound - Try multiple channels to ensure audibility
    try {
      // Try aggressive ringing
      await FlutterRingtonePlayer().play(
        android: AndroidSounds.ringtone,
        ios: IosSounds.electronic,
        looping: true,
        volume: 1.0,
      );
    } catch (e) {
      debugPrint("Error playing sound: $e");
      try {
        FlutterRingtonePlayer().playNotification();
      } catch (_) {}
    }

    // Show local notification - WRAPPED IN TRY-CATCH so it doesn't block dialog on failure
    try {
      await NotificationService.showNotification(
        id: kid.id.hashCode,
        title: "Time Up!",
        body: "Time finished for ${kid.name}. Phone: ${kid.parentPhone}",
      );
    } catch (e) {
      debugPrint("Error showing notification: $e");
    }

    // Also show dialog if app is in foreground (context valid)
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Time Up!'),
          content: Text('Time finished for ${kid.name}.\nPlease inform the parent: ${kid.parentPhone}'),
          actions: [
            TextButton(
              onPressed: () {
                FlutterRingtonePlayer().stop();
                Navigator.pop(context);
                
                debugPrint("Snoozing ${kid.name} for 30s");
                // Snooze Logic
                setState(() {
                  _snoozedUntil[kid.id] = DateTime.now().add(const Duration(seconds: 30));
                });
              },
              child: const Text('Snooze (30s)'),
            ),
            ElevatedButton(
              onPressed: () {
                FlutterRingtonePlayer().stop();
                Navigator.pop(context);
              },
              child: const Text('Acknowledge'),
            ),
          ],
        ),
      ).then((_) => FlutterRingtonePlayer().stop());
    }
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_add_outlined),
                selectedIcon: Icon(Icons.person_add),
                label: Text('Register'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('History'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildContent(_selectedIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return const DashboardView();
      case 1:
        return const RegistrationView();
      case 2:
        return const HistoryScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const Center(child: Text('Unknown'));
    }
  }
}

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeKids = ref.watch(activeKidsProvider);
    
    if (activeKids.isEmpty) {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.child_care, size: 64, color: Colors.grey.shade300),
             const Gap(16),
             Text("No kids currently playing.", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey)),
           ],
         ),
       );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: activeKids.length,
        itemBuilder: (context, index) {
          final kid = activeKids[index];
          // Use Key to ensure timer state persists correctly during grid updates
          return KidTimerCard(key: ValueKey(kid.id), kid: kid);
        },
      ),
    );
  }
}
