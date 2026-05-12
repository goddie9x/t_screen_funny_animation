import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/config.dart';
import '../widgets/shimeji_character.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestOverlayPermission();
    AppConfig.instance.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _requestOverlayPermission() async {
    if (Platform.isAndroid && await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        title: const Text('TScreenFunnyAnimation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.desktop_windows),
            tooltip: 'Start Background Overlay',
            onPressed: () async {
              if (Platform.isAndroid) {
                if (await FlutterOverlayWindow.isActive()) return;
                await FlutterOverlayWindow.showOverlay(
                  flag: OverlayFlag.defaultFlag,
                  alignment: OverlayAlignment.topLeft,
                  visibility: NotificationVisibility.visibilitySecret,
                );
              }
            },
          )
        ],
      ),
      body: Stack(
        children: List.generate(
          AppConfig.instance.shimejiCount,
          (index) => ShimejiCharacter(key: ValueKey('shimeji_$index')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        child: const Icon(Icons.settings),
      ),
    );
  }
}
