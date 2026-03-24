import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_reader/backgroundhandler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/helpers/theme_helper.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/overlay_provider.dart';
import 'services/local_storage_service.dart';
import 'services/platform_channel_service.dart';
import 'ui/main_ui/homeScreen.dart';
import 'ui/overlay_ui/overlay.dart';

// ===================================================================
// BACKGROUND ISOLATE ENTRY POINT
// ===================================================================
@pragma("vm:entry-point")
void backgroundMain() {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundIsolateHandler.start();
}


// ===================================================================
// MAIN APP ENTRY POINT
// ===================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- SERVICE INITIALIZATION & DEPENDENCY INJECTION ---
  final prefs = await SharedPreferences.getInstance();
  final localStorageService = LocalStorageService(prefs);
  final platformChannelService = PlatformChannelService();


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => OverlayProvider(platformChannelService),lazy: false,),
        ChangeNotifierProvider(create: (_) => SettingsProvider(localStorageService),lazy: false,),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            // showPerformanceOverlay: true,
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: appTheme(Brightness.light),
            darkTheme: appTheme(Brightness.dark),
            home: const HomeScreen(),
          );
        },
      ),
    ),
  );
}

// ===================================================================
// OVERLAY UI ENTRY POINT
// ===================================================================
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    // showPerformanceOverlay: true,
    debugShowCheckedModeBanner: false,
    home: OverlayView(), 
  ));
}