import 'package:flutter/material.dart';
import '../widgets/t_funny_buddy.dart';

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          TFunnyBuddy(isOverlay: true),
        ],
      ),
    );
  }
}
