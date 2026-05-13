import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'screens/home_screen.dart';
import 'utils/config.dart';
import 'widgets/t_funny_buddy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.instance.load();
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen()));
}

@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.instance.load();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(backgroundColor: Colors.transparent, body: OverlayScreen()),
  ));
}

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});
  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  StreamSubscription? _accelSub;
  DateTime _lastShake = DateTime.now();
  bool _showFlash = false;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event == 'reload') {
        await AppConfig.instance.load();
        if (mounted) setState(() {});
      }
    });
    _initSensor();
  }

  void _initSensor() {
    _accelSub = accelerometerEventStream().listen((event) async {
      double gForce = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) / 9.8;
      if (gForce > 2.8) { 
        if (DateTime.now().difference(_lastShake) > const Duration(seconds: 2)) {
          _lastShake = DateTime.now();
          AppConfig.instance.isClickThrough = !AppConfig.instance.isClickThrough;
          await AppConfig.instance.save();
          if (mounted) setState(() => _showFlash = true);
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) setState(() => _showFlash = false);
          });
        }
      }
    });
  }

  @override
  void dispose() { _accelSub?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cfg = AppConfig.instance;
    return Stack(
      children: [
        if (_showFlash)
          Positioned.fill(
            child: Container(
              color: cfg.isClickThrough ? Colors.green.withOpacity(0.6) : Colors.blue.withOpacity(0.6),
              child: Center(
                child: Text(
                  cfg.isClickThrough ? 'XUYÊN THẤU' : 'TƯƠNG TÁC',
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                ),
              ),
            ),
          ),
        ...List.generate(
          cfg.shimejiCount,
          (index) => TFunnyBuddy(key: ValueKey('buddy_ovl_$index'), isOverlay: true),
        ),
      ],
    );
  }
}
