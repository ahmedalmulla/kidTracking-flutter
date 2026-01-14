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
      for (var kid in activeKids) {
        if (kid.remainingTime.inSeconds <= 0 && !_alertedKidIds.contains(kid.id)) {
          _showAlert(kid);
          _alertedKidIds.add(kid.id);
        }
      }
    });
  }

  Future<void> _showAlert(dynamic kid) async {
    // Play sound
    try {
      FlutterRingtonePlayer().playAlarm();
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }

    // Show local notification
    await NotificationService.showNotification(
      id: kid.id.hashCode,
      title: "Time Up!",
      body: "Time finished for ${kid.name}. Phone: ${kid.parentPhone}",
    );

    // Also show dialog if app is in foreground (context valid)
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Time Up!'),
          content: Text('Time finished for ${kid.name}.\nPlease inform the parent: ${kid.parentPhone}'),
          actions: [
            TextButton(
              onPressed: () {
                FlutterRingtonePlayer().stop();
                Navigator.pop(context);
              },
              child: const Text('OK'),
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
          maxCrossAxisExtent: 300,
          childAspectRatio: 0.8,
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
