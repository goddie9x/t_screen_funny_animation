import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
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
  bool _showHint = false;
  bool _passthrough = true;
  Offset _overlayOrigin = Offset.zero;
  Timer? _hitTimer;

  @override
  void initState() {
    super.initState();
    AppConfig.instance.addListener(_onConfig);
    _initHotkey();
  }

  void _onConfig() {
    if (mounted) setState(() {});
  }

  void _initHotkey() async {
    if (!Platform.isWindows) return;
    final hk = HotKey(
      key: PhysicalKeyboardKey.keyZ,
      modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
      scope: HotKeyScope.system,
    );
    await hotKeyManager.register(hk, keyDownHandler: (_) => _toggleOverlay());
  }

  Future<void> _enterDesktopOverlay() async {
    final display = await screenRetriever.getPrimaryDisplay();
    final origin = display.visiblePosition ?? Offset.zero;
    final size = display.visibleSize ?? display.size;

    await windowManager.setAsFrameless();
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
    await windowManager.setHasShadow(false);
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(true);
    await windowManager.setMinimumSize(const Size(0, 0));
    await windowManager.setBounds(Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height));
    _overlayOrigin = origin;
    _passthrough = true;
    await windowManager.setIgnoreMouseEvents(true);
    _startHitTest();
  }

  void _startHitTest() {
    _hitTimer?.cancel();
    _hitTimer = Timer.periodic(const Duration(milliseconds: 32), (_) => _updatePassthrough());
  }

  Future<void> _updatePassthrough() async {
    if (!isWindowsOverlay || !mounted) return;
    try {
      final cursor = await screenRetriever.getCursorScreenPoint();
      final local = cursor - _overlayOrigin;
      final over = BuddyHitRegistry.hit(local, wasOver: !_passthrough);
      final shouldPass = !over;
      if (shouldPass != _passthrough) {
        _passthrough = shouldPass;
        await windowManager.setIgnoreMouseEvents(shouldPass);
        await windowManager.setBackgroundColor(Colors.transparent);
        if (!shouldPass) {
          await windowManager.setAlwaysOnTop(true);
        }
      }
    } catch (_) {}
  }

  Future<void> _leaveDesktopOverlay() async {
    _hitTimer?.cancel();
    _hitTimer = null;
    BuddyHitRegistry.bounds.clear();
    BuddyHitRegistry.dragging = 0;
    _passthrough = false;
    await windowManager.setIgnoreMouseEvents(false);
    await windowManager.setSkipTaskbar(false);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setHasShadow(true);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setBackgroundColor(Colors.white);
    await windowManager.setMinimumSize(const Size(400, 300));
    await windowManager.setSize(const Size(800, 600));
    await windowManager.center();
  }

  void _toggleOverlay() async {
    if (!Platform.isWindows) return;
    if (isWindowsOverlay) {
      setState(() {
        isWindowsOverlay = false;
        _showHint = false;
      });
      await _leaveDesktopOverlay();
    } else {
      await _enterDesktopOverlay();
      if (!mounted) return;
      setState(() {
        isWindowsOverlay = true;
        _showHint = true;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showHint = false);
      });
    }
  }

  @override
  void dispose() {
    _hitTimer?.cancel();
    AppConfig.instance.removeListener(_onConfig);
    if (Platform.isWindows) hotKeyManager.unregisterAll();
    super.dispose();
  }

  List<Widget> _buddies({required bool overlay}) {
    return List.generate(
      AppConfig.instance.shimejiCount,
      (index) => TFunnyBuddy(
        key: ValueKey('buddy_${overlay}_$index'),
        isOverlay: overlay,
        index: index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isWindowsOverlay && Platform.isWindows) {
      return ColoredBox(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            ..._buddies(overlay: true),
            if (_showHint)
              const Positioned(
                top: 28,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: _OverlayHint(),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(title: Text(AppConfig.instance.translate('title'))),
      body: Stack(
        children: [
          const Center(child: Text('TScreen Preview Area')),
          ..._buddies(overlay: false),
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
                label: const Text(
                  'KÍCH HOẠT BUDDY NGOÀI MÀN HÌNH',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  if (Platform.isAndroid) {
                    final granted = await FlutterOverlayWindow.isPermissionGranted();
                    if (!granted) await FlutterOverlayWindow.requestPermission();
                    if (await FlutterOverlayWindow.isActive()) return;
                    await FlutterOverlayWindow.showOverlay(
                      flag: AppConfig.instance.isClickThrough
                          ? OverlayFlag.clickThrough
                          : OverlayFlag.defaultFlag,
                      alignment: OverlayAlignment.center,
                      visibility: NotificationVisibility.visibilitySecret,
                      height: WindowSize.matchParent,
                      width: WindowSize.matchParent,
                    );
                  } else if (Platform.isWindows) {
                    _toggleOverlay();
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
  }
}

class _OverlayHint extends StatelessWidget {
  const _OverlayHint();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC111827),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'Rê chuột vào buddy để kéo  •  Ctrl+Shift+Z để quay lại',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
