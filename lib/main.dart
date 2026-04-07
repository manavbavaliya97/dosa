import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'services/printer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize services
  await StorageService().initialize();
  await PrinterService().initialize();

  runApp(const MalharDosaApp());
}

class MalharDosaApp extends StatelessWidget {
  const MalharDosaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malhar Dosa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6e88b0),
          primary: const Color(0xFF6e88b0),
          secondary: const Color(0xFFf2e0d0),
          onPrimary: const Color(0xFF341E1B),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFf2e0d0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6e88b0),
          foregroundColor: Color(0xFFf2e0d0),
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6e88b0),
            foregroundColor: const Color(0xFFf2e0d0),
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF6e88b0).withOpacity(0.15),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
