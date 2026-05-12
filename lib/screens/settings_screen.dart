import 'package:flutter/material.dart';
import '../utils/config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int count; late double speed; late int freq; late double size;

  @override
  void initState() {
    super.initState();
    count = AppConfig.instance.shimejiCount;
    speed = AppConfig.instance.speedMultiplier;
    freq = AppConfig.instance.actionFrequency;
    size = AppConfig.instance.sizeMultiplier;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shimeji Configuration')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Size Multiplier: ${size.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(value: size, min: 0.5, max: 2.5, onChanged: (v) {
            setState(() => size = v);
            AppConfig.instance.updateSize(size);
          }),
          const SizedBox(height: 20),
          Text('Quantity: $count', style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(value: count.toDouble(), min: 1, max: 20, divisions: 19, onChanged: (v) {
            setState(() => count = v.toInt());
            AppConfig.instance.updateCount(count);
          }),
          const SizedBox(height: 20),
          Text('Speed Multiplier: ${speed.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(value: speed, min: 0.5, max: 5.0, onChanged: (v) {
            setState(() => speed = v);
            AppConfig.instance.updateSpeed(speed);
          }),
          const SizedBox(height: 20),
          Text('Action Frequency (s): $freq', style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(value: freq.toDouble(), min: 1, max: 10, divisions: 9, onChanged: (v) {
            setState(() => freq = v.toInt());
            AppConfig.instance.updateFrequency(freq);
          }),
        ],
      ),
    );
  }
}
