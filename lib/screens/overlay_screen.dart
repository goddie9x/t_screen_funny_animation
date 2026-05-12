import 'package:flutter/material.dart';
import '../widgets/shimeji_character.dart';

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ShimejiCharacter(),
        ],
      ),
    );
  }
}
