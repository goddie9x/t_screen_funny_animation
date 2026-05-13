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
      appBar: AppBar(title: const Text('Cấu hình Buddy'), actions: [
        IconButton(icon: const Icon(Icons.save), onPressed: () async {
          await cfg.save();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu và áp dụng toàn hệ thống!')));
        })
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Cài đặt chung (Nhấn Lưu để áp dụng)'),
          _sliderRow('Số lượng Buddy', cfg.shimejiCount.toDouble(), 1, 10, (v) => cfg.shimejiCount = v.toInt()),
          _sliderRow('Tốc độ', cfg.speedMultiplier, 0.1, 2.0, (v) => cfg.speedMultiplier = v),
          _sliderRow('Kích thước', cfg.sizeMultiplier, 0.5, 2.0, (v) => cfg.sizeMultiplier = v),
          SwitchListTile(title: const Text('Xuyên thấu'), value: cfg.isClickThrough, onChanged: (v) => setState(() => cfg.isClickThrough = v)),
          SwitchListTile(title: const Text('Tiết kiệm pin'), value: cfg.pauseOnScreenOff, onChanged: (v) => setState(() => cfg.pauseOnScreenOff = v)),
          const Divider(),
          _sectionTitle('Nhân vật tùy chỉnh'),
          ElevatedButton.icon(icon: const Icon(Icons.person_add), label: const Text('Thêm Preset'), onPressed: _createNewPreset),
          ...cfg.customPresets.map((p) => _presetCard(p)).toList(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

  Widget _sliderRow(String label, double val, double min, double max, Function(double) onCh) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label: ${val.toStringAsFixed(1)}'),
      Slider(value: val, min: min, max: max, onChanged: (v) => setState(() => onCh(v))),
    ]);
  }

  Widget _presetCard(CustomPreset p) {
    final cfg = AppConfig.instance;
    return Card(
      color: cfg.activeCustomPresetId == p.id ? Colors.blue.shade50 : null,
      child: ExpansionTile(
        leading: Radio<String>(value: p.id, groupValue: cfg.activeCustomPresetId, onChanged: (v) { cfg.mode = 'custom'; cfg.activeCustomPresetId = v; setState((){}); }),
        title: Text(p.name),
        children: [
          _upRow(p, 'Đầu', p.headImg, (s) => p.headImg = s),
          _upRow(p, 'Thân', p.bodyImg, (s) => p.bodyImg = s),
          _upRow(p, 'Tay trên', p.armUpperImg, (s) => p.armUpperImg = s),
          _upRow(p, 'Tay dưới', p.armLowerImg, (s) => p.armLowerImg = s),
          _upRow(p, 'Chân trên', p.legUpperImg, (s) => p.legUpperImg = s),
          _upRow(p, 'Chân dưới', p.legLowerImg, (s) => p.legLowerImg = s),
          TextButton.icon(onPressed: (){ cfg.customPresets.remove(p); setState((){}); }, icon: const Icon(Icons.delete, color: Colors.red), label: const Text('Xóa', style: TextStyle(color: Colors.red)))
        ],
      ),
    );
  }

  void _createNewPreset() {
    TextEditingController ctrl = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text('Tên nhân vật'),
      content: TextField(controller: ctrl),
      actions: [TextButton(onPressed: () { 
        if(ctrl.text.isNotEmpty) { 
          AppConfig.instance.customPresets.add(CustomPreset(id: DateTime.now().toString(), name: ctrl.text)); 
          setState((){}); 
        } 
        Navigator.pop(c); 
      }, child: const Text('Lưu'))],
    ));
  }

  Widget _upRow(CustomPreset p, String label, String? path, Function(String) onSet) {
    return ListTile(
      dense: true, title: Text(label),
      trailing: path != null ? Image.file(File(path), width: 30) : const Icon(Icons.upload, size: 20),
      onTap: () async {
        final x = await _picker.pickImage(source: ImageSource.gallery);
        if (x != null) { onSet(x.path); setState((){}); }
      },
    );
  }
}
