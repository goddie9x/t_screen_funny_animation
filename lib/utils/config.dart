import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class AppConfig extends ChangeNotifier {
  static final AppConfig instance = AppConfig._internal();
  AppConfig._internal();

  int shimejiCount = 1;
  double speedMultiplier = 1.0;
  int actionFrequency = 3;
  double sizeMultiplier = 1.0;
  bool isClickThrough = false;

  String mode = 'preset'; 
  int presetId = 0; 
  String? headImg, bodyImg, armImg, legImg;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    shimejiCount = prefs.getInt('count') ?? 1;
    speedMultiplier = prefs.getDouble('speed') ?? 1.0;
    actionFrequency = prefs.getInt('freq') ?? 3;
    sizeMultiplier = prefs.getDouble('size') ?? 1.0;
    isClickThrough = prefs.getBool('clickThrough') ?? false;
    mode = prefs.getString('mode') ?? 'preset';
    presetId = prefs.getInt('presetId') ?? 0;
    headImg = prefs.getString('headImg');
    bodyImg = prefs.getString('bodyImg');
    armImg = prefs.getString('armImg');
    legImg = prefs.getString('legImg');
    
    _updateFlag();
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('count', shimejiCount);
    await prefs.setDouble('speed', speedMultiplier);
    await prefs.setInt('freq', actionFrequency);
    await prefs.setDouble('size', sizeMultiplier);
    await prefs.setBool('clickThrough', isClickThrough);
    await prefs.setString('mode', mode);
    await prefs.setInt('presetId', presetId);
    if(headImg != null) await prefs.setString('headImg', headImg!);
    if(bodyImg != null) await prefs.setString('bodyImg', bodyImg!);
    if(armImg != null) await prefs.setString('armImg', armImg!);
    if(legImg != null) await prefs.setString('legImg', legImg!);

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
}
