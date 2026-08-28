import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../widgets/t_funny_buddy.dart';
import '../utils/config.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});
  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  static const _overlayCh = MethodChannel('x-slayer/overlay');
  StreamSubscription<dynamic>? _reloadSub;
  Timer? _syncTimer;
  int _lastX = -99999;
  int _lastY = -99999;
  int _lastW = -1;
  int _lastH = -1;

  @override
  void initState() {
    super.initState();
    _reloadSub = FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event == 'reload') {
        await AppConfig.instance.load();
        if (mounted) setState(() {});
      }
    });
    _syncTimer = Timer.periodic(const Duration(milliseconds: 32), (_) => _syncWindow());
  }

  Future<void> _syncWindow() async {
    if (!mounted || BuddyHitRegistry.bounds.isEmpty) return;
    var box = BuddyHitRegistry.bounds.values.first;
    for (final r in BuddyHitRegistry.bounds.values.skip(1)) {
      box = box.expandToInclude(r);
    }
    box = box.inflate(8);
    final x = box.left.round();
    final y = box.top.round();
    final w = box.width.ceil().clamp(80, 2000);
    final h = box.height.ceil().clamp(100, 2000);
    BuddyHitRegistry.overlayOrigin = Offset(x.toDouble(), y.toDouble());
    try {
      if (x != _lastX || y != _lastY) {
        _lastX = x;
        _lastY = y;
        await _overlayCh.invokeMethod('updateOverlayPosition', {'x': x, 'y': y});
      }
      if (w != _lastW || h != _lastH) {
        _lastW = w;
        _lastH = h;
        await FlutterOverlayWindow.resizeOverlay(w, h, false);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _reloadSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(
          AppConfig.instance.shimejiCount,
          (index) => TFunnyBuddy(key: ValueKey('buddy_ovl_$index'), isOverlay: true, index: index),
        ),
      ),
    );
  }
}
