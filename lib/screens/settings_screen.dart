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
          _upRow(p, 'Đầu', p.headImg, (s) => p.headImg = s),
          _upRow(p, 'Thân', p.bodyImg, (s) => p.bodyImg = s),
          TextButton(
            onPressed: () {
              cfg.customPresets.remove(p);
              setState(() {});
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
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

  Widget _upRow(CustomPreset p, String label, String? path, Function(String) onSet) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: path != null ? const Icon(Icons.check, color: Colors.green) : const Icon(Icons.upload, size: 20),
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
