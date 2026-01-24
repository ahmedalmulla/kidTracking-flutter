import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'services/background_service.dart'; // We will create this next
import 'services/persistence_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/zone_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PersistenceService.init();
  
  // Initialize Workmanager
  Workmanager().initialize(
    callbackDispatcher, 
    isInDebugMode: true 
  );
  
  // Register the background task
  BackgroundService.scheduleDailyReport();

  runApp(const ProviderScope(child: KidPlaygroundApp()));
}

class KidPlaygroundApp extends ConsumerWidget {
  const KidPlaygroundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialZone = PersistenceService.getSelectedZone();
    
    return MaterialApp(
      title: 'Playground Manager',
      theme: AppTheme.lightTheme,
      home: initialZone == null ? ZoneSelectionScreen() : HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
