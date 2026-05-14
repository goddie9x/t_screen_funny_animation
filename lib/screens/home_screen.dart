import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/config.dart';
import '../widgets/t_funny_buddy.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isWindowsOverlay = false;
  double winX = 100;
  double winY = 100;

  @override
  void initState() {
    super.initState();
    AppConfig.instance.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  Widget build(BuildContext context) {
    Widget mainUI = Scaffold(
      appBar: AppBar(title: const Text('TScreen Funny Animation')),
      body: Stack(
        children: [
          const Center(child: Text("TScreen Preview Area")),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.rocket_launch),
                label: const Text("KÍCH HOẠT BUDDY NGOÀI MÀN HÌNH", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  if (Platform.isAndroid) {
                    bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
                    if (!isGranted) await FlutterOverlayWindow.requestPermission();
                    if (await FlutterOverlayWindow.isActive()) return;
                    await FlutterOverlayWindow.showOverlay(
                      flag: AppConfig.instance.isClickThrough ? OverlayFlag.clickThrough : OverlayFlag.defaultFlag,
                      alignment: OverlayAlignment.center,
                      visibility: NotificationVisibility.visibilitySecret,
                      height: WindowSize.matchParent, width: WindowSize.matchParent,
                    );
                  } else if (Platform.isWindows) {
                    setState(() { isWindowsOverlay = true; });
                    await windowManager.setFullScreen(true);
                    await windowManager.setAsFrameless();
                    await windowManager.setBackgroundColor(Colors.transparent);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        child: const Icon(Icons.settings),
      ),
    );

    if (isWindowsOverlay && Platform.isWindows) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            ...List.generate(
              AppConfig.instance.shimejiCount,
              (index) => TFunnyBuddy(key: ValueKey('shimeji_$index'), isOverlay: true),
            ),
            Positioned(
              left: winX, top: winY,
              child: GestureDetector(
                onPanUpdate: (d) => setState(() { winX += d.delta.dx; winY += d.delta.dy; }),
                child: Container(
                  width: 350, height: 180,
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)]),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Theme.of(context).primaryColorDark, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Bảng Điều Khiển Buddy', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(AppConfig.instance.isClickThrough ? Icons.lock_open : Icons.lock, size: 20, color: Colors.white),
                                  onPressed: () async {
                                    AppConfig.instance.isClickThrough = !AppConfig.instance.isClickThrough;
                                    await AppConfig.instance.save();
                                    await windowManager.setIgnoreMouseEvents(AppConfig.instance.isClickThrough);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.settings, size: 20, color: Colors.white),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            icon: const Icon(Icons.exit_to_app),
                            label: const Text("THOÁT CHẾ ĐỘ OVERLAY"),
                            onPressed: () async {
                              setState(() { isWindowsOverlay = false; });
                              await windowManager.setFullScreen(false);
                              await windowManager.setTitleBarStyle(TitleBarStyle.normal);
                              await windowManager.setBackgroundColor(Colors.white);
                              await windowManager.setSize(const Size(800, 600));
                              await windowManager.center();
                              await windowManager.setIgnoreMouseEvents(false);
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          mainUI,
          ...List.generate(
            AppConfig.instance.shimejiCount,
            (index) => TFunnyBuddy(key: ValueKey('shimeji_$index'), isOverlay: false),
          ),
        ],
      ),
    );
  }
}
