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
  late bool _currentClickThrough;

  @override
  void initState() {
    super.initState();
    _currentClickThrough = AppConfig.instance.isClickThrough;
    
    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event == 'reload') {
        await AppConfig.instance.load();
        if (mounted) {
          setState(() {
            _currentClickThrough = AppConfig.instance.isClickThrough;
          });
        }
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
          
          _currentClickThrough = !_currentClickThrough;
          AppConfig.instance.isClickThrough = _currentClickThrough;
          
          await AppConfig.instance.save();
          
          if (mounted) {
            setState(() => _showFlash = true);
          }
          
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              setState(() => _showFlash = false);
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_showFlash)
          Positioned.fill(
            child: Container(
              color: _currentClickThrough 
                  ? Colors.green.withOpacity(0.6) 
                  : Colors.blue.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentClickThrough ? Icons.visibility_off : Icons.touch_app,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentClickThrough ? 'CHẾ ĐỘ: XUYÊN THẤU\n(Dùng app khác)' : 'CHẾ ĐỘ: TƯƠNG TÁC\n(Kéo thả Buddy)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ...List.generate(
          AppConfig.instance.shimejiCount,
          (index) => TFunnyBuddy(key: ValueKey('buddy_$index'), isOverlay: true),
        ),
      ],
    );
  }
}
