import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final cfg = AppConfig.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Chế độ xuyên thấu (Click Through)'),
            subtitle: const Text('Bật để dùng được app khác, tắt để tương tác (kéo thả) Shimeji'),
            value: cfg.isClickThrough,
            onChanged: (v) { cfg.isClickThrough = v; cfg.save(); setState((){}); },
          ),
          const Divider(),
          Text('Size: ${cfg.sizeMultiplier.toStringAsFixed(1)}x'),
          Slider(value: cfg.sizeMultiplier, min: 0.5, max: 2.5, onChanged: (v) { cfg.sizeMultiplier = v; cfg.save(); setState((){}); }),
          Text('Quantity: ${cfg.shimejiCount}'),
          Slider(value: cfg.shimejiCount.toDouble(), min: 1, max: 10, onChanged: (v) { cfg.shimejiCount = v.toInt(); cfg.save(); setState((){}); }),
          Text('Speed: ${cfg.speedMultiplier.toStringAsFixed(1)}x'),
          Slider(value: cfg.speedMultiplier, min: 0.5, max: 3.0, onChanged: (v) { cfg.speedMultiplier = v; cfg.save(); setState((){}); }),
          const Divider(),
          const Text('Model Presets', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(onPressed: () { cfg.mode = 'preset'; cfg.presetId = 0; cfg.save(); setState((){}); }, child: const Text('Default')),
              ElevatedButton(onPressed: () { cfg.mode = 'preset'; cfg.presetId = 1; cfg.save(); setState((){}); }, child: const Text('Cyber')),
              ElevatedButton(onPressed: () { cfg.mode = 'preset'; cfg.presetId = 2; cfg.save(); setState((){}); }, child: const Text('Alien')),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Custom Upload (Tự chọn ảnh)', style: TextStyle(fontWeight: FontWeight.bold)),
          _buildUploadBtn('Head', (path) => cfg.headImg = path),
          _buildUploadBtn('Body', (path) => cfg.bodyImg = path),
          _buildUploadBtn('Arm', (path) => cfg.armImg = path),
          _buildUploadBtn('Leg', (path) => cfg.legImg = path),
        ],
      ),
    );
  }

  Widget _buildUploadBtn(String part, Function(String) onSet) {
    return ListTile(
      title: Text('Upload $part Image'),
      trailing: const Icon(Icons.upload),
      onTap: () async {
        final xfile = await _picker.pickImage(source: ImageSource.gallery);
        if (xfile != null) {
          onSet(xfile.path);
          AppConfig.instance.mode = 'custom';
          AppConfig.instance.save();
          setState((){});
        }
      },
    );
  }
}
