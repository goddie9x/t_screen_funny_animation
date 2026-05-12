import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'screens/home_screen.dart';
import 'utils/config.dart';
import 'widgets/shimeji_character.dart';

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
    home: Scaffold(
      backgroundColor: Colors.transparent,
      body: OverlayScreen(),
    ),
  ));
}

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});
  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  // Logic Lắc điện thoại
  late StreamSubscription _accelSub;
  DateTime _lastShake = DateTime.now();
  bool _showFlash = false;
  bool _isInteractMode = false;

  @override
  void initState() {
    super.initState();
    _isInteractMode = !AppConfig.instance.isClickThrough;
    
    // Khởi tạo stream nghe lệnh reload từ app chính
    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event == 'reload') {
        await AppConfig.instance.load();
        if (mounted) setState(() { _isInteractMode = !AppConfig.instance.isClickThrough; });
      }
    });

    // Lắng nghe cảm biến gia tốc để đổi chế độ
    
    
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) async {
      double gForce = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) / 9.8;
      if (gForce > 2.5) { // Lắc đủ mạnh
        if (DateTime.now().difference(_lastShake) > const Duration(seconds: 2)) {
          _lastShake = DateTime.now();
          _isInteractMode = !_isInteractMode;
          AppConfig.instance.isClickThrough = !_isInteractMode;
          await AppConfig.instance.save();

          setState(() { _showFlash = true; });
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) setState(() { _showFlash = false; });
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _accelSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_showFlash)
          Positioned.fill(
            child: Container(
              color: _isInteractMode ? Colors.blue.withOpacity(0.4) : Colors.green.withOpacity(0.4),
              child: Center(
                child: Text(
                  _isInteractMode ? 'BẬT TƯƠNG TÁC\n(Vuốt để ném thú cưng)' : 'BẬT XUYÊN THẤU\n(Dùng app khác bình thường)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                )
              ),
            ),
          ),
        ...List.generate(
          AppConfig.instance.shimejiCount,
          (index) => ShimejiCharacter(key: ValueKey('shimeji_$index'), isOverlay: true),
        ),
      ],
    );
  }
}
