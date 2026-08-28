import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'screens/home_screen.dart';
import 'screens/overlay_screen.dart';
import 'utils/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await hotKeyManager.unregisterAll();
    const windowOptions = WindowOptions(
      size: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.show();
      await windowManager.focus();
    });
  }
  await AppConfig.instance.load();
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
            scaffoldBackgroundColor: Colors.transparent,
            canvasColor: Colors.transparent,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.transparent,
            canvasColor: Colors.transparent,
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
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    color: Colors.transparent,
    theme: ThemeData(
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
    ),
    home: const OverlayScreen(),
  ));
}
