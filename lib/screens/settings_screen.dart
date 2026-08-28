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
      appBar: AppBar(title: Text(cfg.translate('settings')), actions: [
        IconButton(icon: const Icon(Icons.check_circle_outline), onPressed: () async {
          await cfg.save();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cfg.translate('save'))));
        })
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(cfg.translate('theme')),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_brightness), label: Text('Auto')),
            ],
            selected: {cfg.themeMode},
            onSelectionChanged: (Set<ThemeMode> s) => setState(() => cfg.toggleTheme(s.first)),
          ),
          const SizedBox(height: 10),
          _sectionTitle(cfg.translate('lang')),
          Row(
            children: [
              ChoiceChip(label: const Text('Tiếng Việt'), selected: cfg.locale.languageCode == 'vi', onSelected: (v) => cfg.toggleLang(const Locale('vi'))),
              const SizedBox(width: 10),
              ChoiceChip(label: const Text('English'), selected: cfg.locale.languageCode == 'en', onSelected: (v) => cfg.toggleLang(const Locale('en'))),
            ],
          ),
          const Divider(),
          _sliderRow(cfg.translate('count'), cfg.shimejiCount.toDouble(), 1, 10, (v) => cfg.shimejiCount = v.toInt()),
          _sliderRow(cfg.translate('speed'), cfg.speedMultiplier, 0.1, 2.0, (v) => cfg.speedMultiplier = v),
          _sliderRow(cfg.translate('size'), cfg.sizeMultiplier, 0.5, 2.0, (v) => cfg.sizeMultiplier = v),
          SwitchListTile(title: Text(cfg.translate('click_through')), value: cfg.isClickThrough, onChanged: (v) => setState(() => cfg.isClickThrough = v)),
          SwitchListTile(title: Text(cfg.translate('battery')), value: cfg.pauseOnScreenOff, onChanged: (v) => setState(() => cfg.pauseOnScreenOff = v)),
          const Divider(),
          ElevatedButton.icon(icon: const Icon(Icons.person_add), label: Text(cfg.translate('add_preset')), onPressed: _createNewPreset),
          RadioGroup<String?>(
            groupValue: cfg.activeCustomPresetId,
            onChanged: (v) {
              cfg.mode = 'custom';
              cfg.activeCustomPresetId = v;
              setState(() {});
            },
            child: Column(children: cfg.customPresets.map(_presetCard).toList()),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)));

  Widget _sliderRow(String label, double val, double min, double max, Function(double) onCh) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label: ${val.toStringAsFixed(1)}'),
      Slider(value: val, min: min, max: max, onChanged: (v) => setState(() => onCh(v))),
    ]);
  }

  Widget _presetCard(CustomPreset p) {
    final cfg = AppConfig.instance;
    return Card(
      child: ExpansionTile(
        leading: Radio<String?>(value: p.id),
        title: Text(p.name),
        children: [
          _upRow(p, 'Đầu', p.headImg, (s) => p.headImg = s),
          _upRow(p, 'Thân', p.bodyImg, (s) => p.bodyImg = s),
          TextButton(onPressed: (){ cfg.customPresets.remove(p); setState((){}); }, child: const Text('Xóa', style: TextStyle(color: Colors.red)))
        ],
      ),
    );
  }

  void _createNewPreset() {
    TextEditingController ctrl = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text('New Buddy'),
      content: TextField(controller: ctrl),
      actions: [TextButton(onPressed: () { if(ctrl.text.isNotEmpty) { AppConfig.instance.customPresets.add(CustomPreset(id: DateTime.now().toString(), name: ctrl.text)); setState((){}); } Navigator.pop(c); }, child: const Text('OK'))],
    ));
  }

  Widget _upRow(CustomPreset p, String label, String? path, Function(String) onSet) {
    return ListTile(
      dense: true, title: Text(label),
      trailing: path != null ? const Icon(Icons.check, color: Colors.green) : const Icon(Icons.upload, size: 20),
      onTap: () async {
        final x = await _picker.pickImage(source: ImageSource.gallery);
        if (x != null) { onSet(x.path); setState((){}); }
      },
    );
  }
}
