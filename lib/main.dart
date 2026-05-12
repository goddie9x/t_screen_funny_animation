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
  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event == 'reload') {
        await AppConfig.instance.load();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(
        AppConfig.instance.shimejiCount,
        (index) => ShimejiCharacter(key: ValueKey('shimeji_$index')),
      ),
    );
  }
}
