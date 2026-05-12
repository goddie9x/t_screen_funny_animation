import 'dart:io';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'widgets/shimeji_character.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen()));
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.transparent,
      body: ShimejiCharacter(),
    ),
  ));
}
