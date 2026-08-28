import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'screens/home_screen.dart';
import 'screens/overlay_screen.dart';
import 'utils/config.dart';
import 'widgets/t_funny_buddy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.instance.load();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await hotKeyManager.unregisterAll();
    final overlay = AppConfig.instance.buddyOnScreen;
    final windowOptions = WindowOptions(
      size: const Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: overlay,
      titleBarStyle: overlay ? TitleBarStyle.hidden : TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setPreventClose(true);
      await windowManager.show();
      if (!overlay) await windowManager.focus();
    });
  }
  runApp(const TFunnyApp());
}

class TFunnyApp extends StatelessWidget {
  const TFunnyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppConfig.instance,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConfig.instance.translate('title'),
          color: Colors.transparent,
          themeMode: AppConfig.instance.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
              clipBehavior: Clip.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                side: BorderSide.none,
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB),
              brightness: Brightness.dark,
            ),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
              clipBehavior: Clip.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                side: BorderSide.none,
              ),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}

@pragma('vm:entry-point')
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.instance.load();
  BuddyHitRegistry.worldSize = overlayPhysicsSize();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    color: Colors.transparent,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
    ),
    home: const OverlayScreen(),
  ));
}
