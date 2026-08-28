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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(cfg.translate('settings')),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () async {
              await cfg.save();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cfg.translate('save'))));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(cfg.translate('overlay_mode')),
            subtitle: Text(cfg.translate('overlay_mode_hint')),
            value: cfg.buddyOnScreen,
            onChanged: (v) async {
              cfg.buddyOnScreen = v;
              await cfg.save();
              setState(() {});
            },
          ),
          const Divider(height: 24),
          _sectionTitle(cfg.translate('theme')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Light'),
                avatar: const Icon(Icons.light_mode, size: 18),
                selected: cfg.themeMode == ThemeMode.light,
                onSelected: (_) => setState(() => cfg.toggleTheme(ThemeMode.light)),
              ),
              ChoiceChip(
                label: const Text('Dark'),
                avatar: const Icon(Icons.dark_mode, size: 18),
                selected: cfg.themeMode == ThemeMode.dark,
                onSelected: (_) => setState(() => cfg.toggleTheme(ThemeMode.dark)),
              ),
              ChoiceChip(
                label: const Text('Auto'),
                avatar: const Icon(Icons.settings_brightness, size: 18),
                selected: cfg.themeMode == ThemeMode.system,
                onSelected: (_) => setState(() => cfg.toggleTheme(ThemeMode.system)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle(cfg.translate('lang')),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tiếng Việt'),
                selected: cfg.locale.languageCode == 'vi',
                onSelected: (_) => setState(() => cfg.toggleLang(const Locale('vi'))),
              ),
              ChoiceChip(
                label: const Text('English'),
                selected: cfg.locale.languageCode == 'en',
                onSelected: (_) => setState(() => cfg.toggleLang(const Locale('en'))),
              ),
            ],
          ),
          const Divider(height: 32),
          _sliderRow(cfg.translate('count'), cfg.shimejiCount.toDouble(), 1, 10, (v) => cfg.shimejiCount = v.toInt()),
          _sliderRow(cfg.translate('speed'), cfg.speedMultiplier, 0.1, 2.0, (v) => cfg.speedMultiplier = v),
          _sliderRow(cfg.translate('size'), cfg.sizeMultiplier, 0.5, 2.0, (v) => cfg.sizeMultiplier = v),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(cfg.translate('click_through')),
            value: cfg.isClickThrough,
            onChanged: (v) => setState(() => cfg.isClickThrough = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(cfg.translate('battery')),
            value: cfg.pauseOnScreenOff,
            onChanged: (v) => setState(() => cfg.pauseOnScreenOff = v),
          ),
          const Divider(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: Text(cfg.translate('add_preset')),
              onPressed: _createNewPreset,
            ),
          ),
          const SizedBox(height: 8),
          RadioGroup<String?>(
            groupValue: cfg.activeCustomPresetId,
            onChanged: (v) {
              cfg.mode = 'custom';
              cfg.activeCustomPresetId = v;
              setState(() {});
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: cfg.customPresets.map(_presetCard).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Widget _sliderRow(String label, double val, double min, double max, Function(double) onCh) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$label: ${val.toStringAsFixed(1)}'),
          Slider(value: val, min: min, max: max, onChanged: (v) => setState(() => onCh(v))),
        ],
      ),
    );
  }

  Widget _presetCard(CustomPreset p) {
    final cfg = AppConfig.instance;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Radio<String?>(value: p.id),
        title: Text(p.name),
        children: [
          _partGroup(cfg.translate('parts_torso'), [
            _upRow(cfg.translate('part_head'), cfg.translate('joint_head'), p.headImg, (s) => p.headImg = s),
            _upRow(cfg.translate('part_body'), cfg.translate('joint_body'), p.bodyImg, (s) => p.bodyImg = s),
          ]),
          _partGroup(cfg.translate('parts_arm'), [
            _upRow(cfg.translate('part_arm_upper'), cfg.translate('joint_shoulder'), p.armUpperImg, (s) => p.armUpperImg = s),
            _upRow(cfg.translate('part_arm_lower'), cfg.translate('joint_elbow'), p.armLowerImg, (s) => p.armLowerImg = s),
            _upRow(cfg.translate('part_hand'), cfg.translate('joint_wrist'), p.handImg, (s) => p.handImg = s),
          ]),
          _partGroup(cfg.translate('parts_leg'), [
            _upRow(cfg.translate('part_leg_upper'), cfg.translate('joint_hip'), p.legUpperImg, (s) => p.legUpperImg = s),
            _upRow(cfg.translate('part_leg_lower'), cfg.translate('joint_knee'), p.legLowerImg, (s) => p.legLowerImg = s),
            _upRow(cfg.translate('part_foot'), cfg.translate('joint_ankle'), p.footImg, (s) => p.footImg = s),
          ]),
          TextButton(
            onPressed: () {
              cfg.customPresets.remove(p);
              if (cfg.activeCustomPresetId == p.id) {
                cfg.activeCustomPresetId = null;
                cfg.mode = 'preset';
              }
              setState(() {});
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _partGroup(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }

  void _createNewPreset() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('New Buddy'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                AppConfig.instance.customPresets.add(CustomPreset(id: DateTime.now().toString(), name: ctrl.text));
                setState(() {});
              }
              Navigator.pop(c);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _upRow(String label, String joint, String? path, Function(String?) onSet) {
    final fileOk = path != null && File(path).existsSync();
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 40,
          height: 40,
          child: fileOk
              ? Image.file(File(path), fit: BoxFit.cover)
              : Container(
                  color: Colors.black12,
                  child: const Icon(Icons.upload, size: 18),
                ),
        ),
      ),
      title: Text(label),
      subtitle: Text(joint, style: const TextStyle(fontSize: 12)),
      trailing: fileOk
          ? IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Xóa ảnh',
              onPressed: () {
                onSet(null);
                setState(() {});
              },
            )
          : const Icon(Icons.add_photo_alternate_outlined, size: 20),
      onTap: () async {
        final x = await _picker.pickImage(source: ImageSource.gallery);
        if (x != null) {
          onSet(x.path);
          setState(() {});
        }
      },
    );
  }
}
