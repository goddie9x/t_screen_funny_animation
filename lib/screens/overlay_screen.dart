import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../widgets/t_funny_buddy.dart';
import '../utils/config.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});
  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> with WidgetsBindingObserver {
  StreamSubscription<dynamic>? _reloadSub;
  Timer? _syncTimer;
  int _lastX = -99999;
  int _lastY = -99999;
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyWorldSize();
    _reloadSub = FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event == 'reload') {
        await AppConfig.instance.load();
        _applyWorldSize();
        if (mounted) setState(() {});
      } else if (event is Map && event['type'] == 'screen') {
        final w = (event['w'] as num?)?.toDouble();
        final h = (event['h'] as num?)?.toDouble();
        if (w == null || h == null || w < 200 || h < 200) return;
        AppConfig.instance.screenWidth = w;
        AppConfig.instance.screenHeight = h;
        BuddyHitRegistry.worldSize = Size(w, h);
        if (mounted) setState(() {});
      }
    });
    _syncTimer = Timer.periodic(const Duration(milliseconds: 50), (_) => _syncWindow());
  }

  void _applyWorldSize() {
    BuddyHitRegistry.worldSize = overlayPhysicsSize();
  }

  @override
  void didChangeMetrics() {
    final before = BuddyHitRegistry.worldSize;
    final sized = overlayPhysicsSize();
    if (before != null &&
        (before.width - sized.width).abs() < 1 &&
        (before.height - sized.height).abs() < 1) {
      return;
    }
    BuddyHitRegistry.worldSize = sized;
    AppConfig.instance.rememberScreenSize(sized);
    if (mounted) setState(() {});
  }

  Future<void> _syncWindow() async {
    if (!mounted || _moving || BuddyHitRegistry.bounds.isEmpty) return;
    var box = BuddyHitRegistry.bounds.values.first;
    for (final r in BuddyHitRegistry.bounds.values.skip(1)) {
      box = box.expandToInclude(r);
    }
    final x = (box.left - BuddyHitRegistry.padX).round();
    final y = (box.top - BuddyHitRegistry.padTop).round();
    if ((x - _lastX).abs() < 4 && (y - _lastY).abs() < 4) return;
    _moving = true;
    try {
      final ok = await FlutterOverlayWindow.moveOverlay(OverlayPosition(x.toDouble(), y.toDouble()));
      if (ok == false) return;
      _lastX = x;
      _lastY = y;
      BuddyHitRegistry.overlayOrigin = Offset(x.toDouble(), y.toDouble());
    } catch (_) {
    } finally {
      _moving = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _reloadSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
      ),
      child: ColoredBox(
        color: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(
            AppConfig.instance.shimejiCount,
            (index) => TFunnyBuddy(key: ValueKey('buddy_ovl_$index'), isOverlay: true, index: index),
          ),
        ),
      ),
    );
  }
}
