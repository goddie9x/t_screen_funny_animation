import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import '../utils/config.dart';
import '../widgets/t_funny_buddy.dart';
import 'settings_screen.dart';

const _appChannel = MethodChannel('com.god.tscreenfunny/app');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener, TrayListener, WidgetsBindingObserver {
  bool isWindowsOverlay = false;
  bool _showHint = false;
  bool _passthrough = true;
  bool _openingSettings = false;
  bool _lastBuddyOnScreen = true;
  bool _startingAndroidOverlay = false;
  Offset _overlayOrigin = Offset.zero;
  Timer? _hitTimer;
  StreamSubscription<dynamic>? _overlayMsgSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppConfig.instance.addListener(_onConfig);
    _lastBuddyOnScreen = AppConfig.instance.buddyOnScreen;
    windowManager.addListener(this);
    trayManager.addListener(this);
    _initHotkey();
    _initTray();
    _listenOverlayMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await _captureAndPersistScreenSize();
    if (!mounted) return;
    if (AppConfig.instance.buddyOnScreen) {
      await _enableBuddyOnScreen(fromStart: true);
    }
  }

  @override
  void didChangeMetrics() {
    if (!Platform.isAndroid) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureAndPersistScreenSize(notifyOverlay: true);
    });
  }

  Future<void> _captureAndPersistScreenSize({bool notifyOverlay = false}) async {
    if (!Platform.isAndroid || !mounted) return;
    final size = _androidDeviceScreenSize();
    if (size.width < 200 || size.height < 200) return;
    final before = AppConfig.instance.savedScreenSize();
    await AppConfig.instance.rememberScreenSize(size);
    BuddyHitRegistry.worldSize = AppConfig.instance.savedScreenSize();
    final changed = (before.width - size.width).abs() > 1 || (before.height - size.height).abs() > 1;
    if (notifyOverlay && changed) {
      await _pushAndroidScreenSize();
    }
  }

  Size _androidDeviceScreenSize() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    if (dispatcher.displays.isNotEmpty) {
      final d = dispatcher.displays.first;
      final dpr = d.devicePixelRatio == 0 ? 1.0 : d.devicePixelRatio;
      final s = Size(d.size.width / dpr, d.size.height / dpr);
      if (s.width > 200 && s.height > 200) return s;
    }
    final view = View.of(context);
    final dpr = view.devicePixelRatio == 0 ? 1.0 : view.devicePixelRatio;
    return Size(view.physicalSize.width / dpr, view.physicalSize.height / dpr);
  }

  void _onConfig() {
    if (!mounted) return;
    setState(() {});
    final want = AppConfig.instance.buddyOnScreen;
    if (want != _lastBuddyOnScreen) {
      _lastBuddyOnScreen = want;
      _syncOverlayWithSetting();
    }
    _rebuildTrayMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !Platform.isWindows || isWindowsOverlay) return;
      windowManager.setBackgroundColor(_appWindowColor());
    });
  }

  Color _appWindowColor() {
    if (!mounted) return const Color(0xFF1C1B1F);
    return Theme.of(context).colorScheme.surface;
  }

  void _listenOverlayMessages() {
    if (!Platform.isAndroid) return;
    _overlayMsgSub = FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map && event['type'] == 'pos') {
        final x = (event['x'] as num?)?.toDouble();
        final y = (event['y'] as num?)?.toDouble();
        if (x == null || y == null) return;
        FlutterOverlayWindow.moveOverlay(OverlayPosition(x, y));
      }
    });
  }

  Future<void> _pushAndroidScreenSize() async {
    final cfg = AppConfig.instance;
    try {
      await FlutterOverlayWindow.shareData({
        'type': 'screen',
        'w': cfg.screenWidth,
        'h': cfg.screenHeight,
      });
    } catch (_) {}
  }

  Future<void> _syncOverlayWithSetting() async {
    final want = AppConfig.instance.buddyOnScreen;
    if (Platform.isWindows) {
      if (want && !isWindowsOverlay && !_openingSettings) {
        await _enableBuddyOnScreen();
      } else if (!want && isWindowsOverlay) {
        await _disableBuddyOnScreen();
      }
    } else if (Platform.isAndroid) {
      if (_startingAndroidOverlay) return;
      final active = await FlutterOverlayWindow.isActive();
      if (want && !active) {
        await _enableBuddyOnScreen();
      } else if (!want && active) {
        await FlutterOverlayWindow.closeOverlay();
      }
    }
  }

  void _initHotkey() async {
    if (!Platform.isWindows) return;
    final hk = HotKey(
      key: PhysicalKeyboardKey.keyZ,
      modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
      scope: HotKeyScope.system,
    );
    await hotKeyManager.register(hk, keyDownHandler: (_) => _showAppWindow());
  }

  Future<void> _initTray() async {
    if (!Platform.isWindows) return;
    try {
      await trayManager.setIcon('windows/runner/resources/app_icon.ico');
      await trayManager.setToolTip(AppConfig.instance.translate('title'));
      await _rebuildTrayMenu();
    } catch (_) {
      try {
        await trayManager.setIcon('assets/icon/app_icon.png');
        await _rebuildTrayMenu();
      } catch (_) {}
    }
  }

  Future<void> _rebuildTrayMenu() async {
    if (!Platform.isWindows) return;
    final cfg = AppConfig.instance;
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show', label: cfg.translate('tray_open')),
      MenuItem(key: 'settings', label: cfg.translate('tray_settings')),
      MenuItem.separator(),
      MenuItem(
        key: 'overlay',
        label: cfg.translate('overlay_mode'),
        checked: cfg.buddyOnScreen,
      ),
      MenuItem.separator(),
      MenuItem(key: 'exit', label: cfg.translate('tray_exit')),
    ]));
  }

  @override
  void onTrayIconMouseDown() => _showAppWindow();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem item) {
    switch (item.key) {
      case 'show':
        _showAppWindow();
        break;
      case 'settings':
        _openSettings();
        break;
      case 'overlay':
        _toggleBuddySetting();
        break;
      case 'exit':
        _quitApp();
        break;
    }
  }

  @override
  void onWindowClose() async {
    if (AppConfig.instance.buddyOnScreen) {
      await _enableBuddyOnScreen();
    } else {
      await _quitApp();
    }
  }

  Future<void> _quitApp() async {
    if (Platform.isWindows) {
      await windowManager.setPreventClose(false);
      await trayManager.destroy();
      await windowManager.destroy();
    } else if (Platform.isAndroid) {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
      SystemNavigator.pop();
    }
  }

  Future<void> _toggleBuddySetting() async {
    final cfg = AppConfig.instance;
    cfg.buddyOnScreen = !cfg.buddyOnScreen;
    await cfg.save();
  }

  Future<void> _activateOverlayFromHome() async {
    final cfg = AppConfig.instance;
    if (!cfg.buddyOnScreen) {
      cfg.buddyOnScreen = true;
      await cfg.save();
    }
    if (!mounted) return;
    await _enableBuddyOnScreen();
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
    await windowManager.show();
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
    await windowManager.setTitleBarStyle(TitleBarStyle.normal, windowButtonVisibility: true);
    await windowManager.setBackgroundColor(_appWindowColor());
    await windowManager.setMinimumSize(const Size(400, 300));
    await windowManager.setSize(const Size(800, 600));
    await windowManager.center();
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _enableBuddyOnScreen({bool fromStart = false}) async {
    if (Platform.isWindows) {
      if (isWindowsOverlay) return;
      await _enterDesktopOverlay();
      if (!mounted) return;
      setState(() {
        isWindowsOverlay = true;
        _showHint = fromStart;
      });
      if (fromStart) {
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _showHint = false);
        });
      }
      await _rebuildTrayMenu();
    } else if (Platform.isAndroid) {
      if (_startingAndroidOverlay) return;
      _startingAndroidOverlay = true;
      try {
        await _enableAndroidOverlay();
      } finally {
        _startingAndroidOverlay = false;
      }
    }
  }

  Future<void> _enableAndroidOverlay() async {
    var granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      await FlutterOverlayWindow.requestPermission();
      granted = await FlutterOverlayWindow.isPermissionGranted();
    }
    if (!granted || !mounted) return;
    await _captureAndPersistScreenSize();
    if (!mounted) return;
    final cfg = AppConfig.instance;
    if (await FlutterOverlayWindow.isActive()) {
      await _pushAndroidScreenSize();
      await _moveAndroidToBackWhenReady();
      return;
    }
    try {
      await _appChannel.invokeMethod('resetOverlayEngine');
    } catch (_) {}
    if (!mounted) return;
    final scale = cfg.sizeMultiplier;
    final logicalW = BuddyHitRegistry.overlayWidth(scale).ceil();
    final logicalH = BuddyHitRegistry.overlayHeight(scale).ceil();
    final dpr = MediaQuery.devicePixelRatioOf(context);
    await FlutterOverlayWindow.showOverlay(
      flag: OverlayFlag.defaultFlag,
      alignment: OverlayAlignment.topLeft,
      visibility: NotificationVisibility.visibilityPublic,
      overlayTitle: cfg.translate('title'),
      overlayContent: cfg.translate('overlay_mode'),
      height: (logicalH * dpr).round(),
      width: (logicalW * dpr).round(),
      enableDrag: false,
      startPosition: const OverlayPosition(24.0, 80.0),
    );
    await _moveAndroidToBackWhenReady();
    await _pushAndroidScreenSize();
    await cfg.save();
  }

  Future<void> _moveAndroidToBackWhenReady() async {
    for (var i = 0; i < 25; i++) {
      if (await FlutterOverlayWindow.isActive()) break;
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await _moveAndroidToBack();
  }

  Future<void> _disableBuddyOnScreen() async {
    if (Platform.isWindows) {
      if (!isWindowsOverlay) return;
      setState(() {
        isWindowsOverlay = false;
        _showHint = false;
      });
      await _leaveDesktopOverlay();
      await _rebuildTrayMenu();
    } else if (Platform.isAndroid) {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
    }
  }

  Future<void> _moveAndroidToBack() async {
    if (!Platform.isAndroid) return;
    try {
      await _appChannel.invokeMethod('moveToBack');
    } catch (_) {}
  }

  Future<void> _showAppWindow() async {
    if (Platform.isWindows) {
      _openingSettings = true;
      if (isWindowsOverlay) {
        setState(() {
          isWindowsOverlay = false;
          _showHint = false;
        });
        await _leaveDesktopOverlay();
      } else {
        await windowManager.show();
        await windowManager.focus();
      }
      _openingSettings = false;
      await _rebuildTrayMenu();
    }
  }

  Future<void> _openSettings() async {
    await _showAppWindow();
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    if (AppConfig.instance.buddyOnScreen && Platform.isWindows && mounted) {
      await _enableBuddyOnScreen();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hitTimer?.cancel();
    _overlayMsgSub?.cancel();
    AppConfig.instance.removeListener(_onConfig);
    windowManager.removeListener(this);
    trayManager.removeListener(this);
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
                  child: Center(child: _OverlayHint()),
                ),
              ),
          ],
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(AppConfig.instance.translate('title')),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppConfig.instance.translate('overlay_mode_hint'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: Text(AppConfig.instance.translate('start_overlay')),
                    onPressed: _activateOverlayFromHome,
                  ),
                ],
              ),
            ),
          ),
          ..._buddies(overlay: false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openSettings,
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
            'Icon khay hệ thống để mở app  •  Ctrl+Shift+Z',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
