import 'dart:io';
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
          const Text('🔥 Mẹo: Lắc mạnh điện thoại khi đang ở màn hình chính để Bật/Tắt chế độ xuyên thấu nhanh!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Chế độ xuyên thấu hoàn toàn'),
            subtitle: const Text('Bật: Dùng app khác, thú tự chạy. Tắt: Kéo thả thú, màn hình bị khóa.'),
            value: cfg.isClickThrough,
            onChanged: (v) { cfg.isClickThrough = v; cfg.save(); setState((){}); },
          ),
          const Divider(),
          Text('Size: ${cfg.sizeMultiplier.toStringAsFixed(1)}x'),
          Slider(value: cfg.sizeMultiplier, min: 0.5, max: 2.5, onChanged: (v) { cfg.sizeMultiplier = v; cfg.save(); setState((){}); }),
          Text('Quantity: ${cfg.shimejiCount}'),
          Slider(value: cfg.shimejiCount.toDouble(), min: 1, max: 10, onChanged: (v) { cfg.shimejiCount = v.toInt(); cfg.save(); setState((){}); }),
          const Divider(),
          const Text('Built-in Presets', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Default'), selected: cfg.mode == 'preset' && cfg.presetId == 0, onSelected: (v) { if(v){ cfg.mode = 'preset'; cfg.presetId = 0; cfg.save(); setState((){}); } }),
              ChoiceChip(label: const Text('Cyber'), selected: cfg.mode == 'preset' && cfg.presetId == 1, onSelected: (v) { if(v){ cfg.mode = 'preset'; cfg.presetId = 1; cfg.save(); setState((){}); } }),
              ChoiceChip(label: const Text('Alien'), selected: cfg.mode == 'preset' && cfg.presetId == 2, onSelected: (v) { if(v){ cfg.mode = 'preset'; cfg.presetId = 2; cfg.save(); setState((){}); } }),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Custom Presets (Upload Ảnh)', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add), onPressed: _createNewPreset),
            ],
          ),
          ...cfg.customPresets.map((p) => Card(
            color: (cfg.mode == 'custom' && cfg.activeCustomPresetId == p.id) ? Colors.blue.shade100 : null,
            child: ListTile(
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUploadRow(p, 'Head', p.headImg, (path) { p.headImg = path; _activatePreset(p.id); }),
                  _buildUploadRow(p, 'Body', p.bodyImg, (path) { p.bodyImg = path; _activatePreset(p.id); }),
                  _buildUploadRow(p, 'Arm', p.armImg, (path) { p.armImg = path; _activatePreset(p.id); }),
                  _buildUploadRow(p, 'Leg', p.legImg, (path) { p.legImg = path; _activatePreset(p.id); }),
                ],
              ),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { cfg.customPresets.remove(p); if(cfg.activeCustomPresetId == p.id) { cfg.mode='preset'; cfg.presetId=0;} cfg.save(); setState((){}); }),
              onTap: () => _activatePreset(p.id),
            ),
          )).toList(),
        ],
      ),
    );
  }

  void _activatePreset(String id) { AppConfig.instance.mode = 'custom'; AppConfig.instance.activeCustomPresetId = id; AppConfig.instance.save(); setState((){}); }

  void _createNewPreset() {
    TextEditingController ctrl = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text('Tạo nhân vật mới'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Nhập tên nhân vật')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hủy')),
        TextButton(onPressed: () {
          if (ctrl.text.isNotEmpty) {
            AppConfig.instance.customPresets.add(CustomPreset(id: DateTime.now().millisecondsSinceEpoch.toString(), name: ctrl.text));
            AppConfig.instance.save(); setState((){});
          }
          Navigator.pop(c);
        }, child: const Text('Lưu')),
      ],
    ));
  }

  Widget _buildUploadRow(CustomPreset preset, String part, String? imgPath, Function(String) onSet) {
    return Row(
      children: [
        SizedBox(width: 50, child: Text(part)),
        IconButton(icon: const Icon(Icons.upload, size: 18), onPressed: () async {
          final xfile = await _picker.pickImage(source: ImageSource.gallery);
          if (xfile != null) { onSet(xfile.path); setState((){}); }
        }),
        if (imgPath != null) Container(
          margin: const EdgeInsets.only(left: 8), width: 30, height: 30,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
          child: Image.file(File(imgPath), fit: BoxFit.contain),
        ) else const Text('Chưa có ảnh', style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
