import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class CustomPreset {
  String id; String name;
  String? headImg, bodyImg, armImg, legImg;
  CustomPreset({required this.id, required this.name, this.headImg, this.bodyImg, this.armImg, this.legImg});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'headImg': headImg, 'bodyImg': bodyImg, 'armImg': armImg, 'legImg': legImg};
  factory CustomPreset.fromJson(Map<String, dynamic> j) => CustomPreset(id: j['id'], name: j['name'], headImg: j['headImg'], bodyImg: j['bodyImg'], armImg: j['armImg'], legImg: j['legImg']);
}

class AppConfig extends ChangeNotifier {
  static final AppConfig instance = AppConfig._internal();
  AppConfig._internal();

  int shimejiCount = 1; double speedMultiplier = 1.0; int actionFrequency = 3; double sizeMultiplier = 1.0;
  bool isClickThrough = true; // Mặc định phải là True để không chặn điện thoại người dùng
  String mode = 'preset'; int presetId = 0; String? activeCustomPresetId;
  List<CustomPreset> customPresets = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    shimejiCount = prefs.getInt('count') ?? 1;
    speedMultiplier = prefs.getDouble('speed') ?? 1.0;
    actionFrequency = prefs.getInt('freq') ?? 3;
    sizeMultiplier = prefs.getDouble('size') ?? 1.0;
    isClickThrough = prefs.getBool('clickThrough') ?? true;
    mode = prefs.getString('mode') ?? 'preset';
    presetId = prefs.getInt('presetId') ?? 0;
    activeCustomPresetId = prefs.getString('activeCustomPresetId');
    List<String>? savedPresets = prefs.getStringList('customPresets');
    if (savedPresets != null) customPresets = savedPresets.map((e) => CustomPreset.fromJson(jsonDecode(e))).toList();
    _updateFlag(); notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('count', shimejiCount); await prefs.setDouble('speed', speedMultiplier);
    await prefs.setInt('freq', actionFrequency); await prefs.setDouble('size', sizeMultiplier);
    await prefs.setBool('clickThrough', isClickThrough); await prefs.setString('mode', mode);
    await prefs.setInt('presetId', presetId);
    if(activeCustomPresetId != null) await prefs.setString('activeCustomPresetId', activeCustomPresetId!);
    List<String> toSave = customPresets.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('customPresets', toSave);
    _updateFlag();
    try { await FlutterOverlayWindow.shareData('reload'); } catch (_) {}
    notifyListeners();
  }
  
  Future<void> _updateFlag() async {
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.updateFlag(isClickThrough ? OverlayFlag.clickThrough : OverlayFlag.defaultFlag);
      }
    } catch (_) {}
  }
  CustomPreset? getActiveCustom() { try { return customPresets.firstWhere((p) => p.id == activeCustomPresetId); } catch (_) { return null; } }
}
