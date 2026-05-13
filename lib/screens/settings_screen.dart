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
      appBar: AppBar(title: const Text('Buddy Customizer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(title: const Text('Xuyên thấu'), subtitle: const Text('Lắc điện thoại để đổi nhanh'), value: cfg.isClickThrough, onChanged: (v) { cfg.isClickThrough = v; cfg.save(); setState((){}); }),
          SwitchListTile(title: const Text('Tắt khi tắt màn hình'), subtitle: const Text('Tiết kiệm pin tối đa'), value: cfg.pauseOnScreenOff, onChanged: (v) { cfg.pauseOnScreenOff = v; cfg.save(); setState((){}); }),
          const Divider(),
          Text('Kích thước: ${cfg.sizeMultiplier.toStringAsFixed(1)}x'),
          Slider(value: cfg.sizeMultiplier, min: 0.5, max: 2.5, onChanged: (v) { cfg.sizeMultiplier = v; cfg.save(); setState((){}); }),
          const Divider(),
          const Text('Custom Presets', style: TextStyle(fontWeight: FontWeight.bold)),
          ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Tạo nhân vật mới'), onPressed: _createNewPreset),
          const SizedBox(height: 10),
          ...cfg.customPresets.map((p) => Card(
            color: (cfg.mode == 'custom' && cfg.activeCustomPresetId == p.id) ? Colors.blue.shade50 : null,
            child: ExpansionTile(
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              leading: Radio<String>(value: p.id, groupValue: cfg.activeCustomPresetId, onChanged: (v) { cfg.mode = 'custom'; cfg.activeCustomPresetId = v; cfg.save(); setState((){}); }),
              children: [
                _upRow(p, 'Đầu', p.headImg, (s) => p.headImg = s),
                _upRow(p, 'Thân', p.bodyImg, (s) => p.bodyImg = s),
                _upRow(p, 'Tay trên', p.armUpperImg, (s) => p.armUpperImg = s),
                _upRow(p, 'Tay dưới', p.armLowerImg, (s) => p.armLowerImg = s),
                _upRow(p, 'Chân trên', p.legUpperImg, (s) => p.legUpperImg = s),
                _upRow(p, 'Chân dưới', p.legLowerImg, (s) => p.legLowerImg = s),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { cfg.customPresets.remove(p); cfg.save(); setState((){}); })
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  void _createNewPreset() {
    TextEditingController ctrl = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text('Tên Buddy'),
      content: TextField(controller: ctrl),
      actions: [TextButton(onPressed: () {
        if(ctrl.text.isNotEmpty) {
          AppConfig.instance.customPresets.add(CustomPreset(id: DateTime.now().toString(), name: ctrl.text));
          AppConfig.instance.save(); Navigator.pop(c); setState((){});
        }
      }, child: const Text('Tạo'))],
    ));
  }

  Widget _upRow(CustomPreset p, String label, String? path, Function(String) onSet) {
    return ListTile(
      title: Text(label),
      trailing: path != null ? Image.file(File(path), width: 30) : const Icon(Icons.upload),
      onTap: () async {
        final x = await _picker.pickImage(source: ImageSource.gallery);
        if (x != null) { onSet(x.path); AppConfig.instance.save(); setState((){}); }
      },
    );
  }
}
