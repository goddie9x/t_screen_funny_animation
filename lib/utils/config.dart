import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class CustomPreset {
  String id;
  String name;
  String? headImg;
  String? bodyImg;
  String? armUpperImg;
  String? armLowerImg;
  String? handImg;
  String? legUpperImg;
  String? legLowerImg;
  String? footImg;

  CustomPreset({
    required this.id,
    required this.name,
    this.headImg,
    this.bodyImg,
    this.armUpperImg,
    this.armLowerImg,
    this.handImg,
    this.legUpperImg,
    this.legLowerImg,
    this.footImg,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'headImg': headImg,
        'bodyImg': bodyImg,
        'armUpperImg': armUpperImg,
        'armLowerImg': armLowerImg,
        'handImg': handImg,
        'legUpperImg': legUpperImg,
        'legLowerImg': legLowerImg,
        'footImg': footImg,
      };

  factory CustomPreset.fromJson(Map<String, dynamic> j) => CustomPreset(
        id: j['id'],
        name: j['name'],
        headImg: j['headImg'],
        bodyImg: j['bodyImg'],
        armUpperImg: j['armUpperImg'],
        armLowerImg: j['armLowerImg'],
        handImg: j['handImg'],
        legUpperImg: j['legUpperImg'],
        legLowerImg: j['legLowerImg'],
        footImg: j['footImg'],
      );
}

class AppConfig extends ChangeNotifier {
  static final AppConfig instance = AppConfig._internal();
  AppConfig._internal();
  int shimejiCount = 1; double speedMultiplier = 0.5; double sizeMultiplier = 1.0; int actionFrequency = 3;
  bool isClickThrough = true; bool pauseOnScreenOff = true; bool buddyOnScreen = true;
  ThemeMode themeMode = ThemeMode.system; Locale locale = const Locale('vi');
  String mode = 'preset'; String? activeCustomPresetId;
  List<CustomPreset> customPresets = [];
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    shimejiCount = prefs.getInt('count') ?? 1;
    speedMultiplier = prefs.getDouble('speed') ?? 0.5;
    sizeMultiplier = prefs.getDouble('size') ?? 1.0;
    actionFrequency = prefs.getInt('freq') ?? 3;
    isClickThrough = prefs.getBool('clickThrough') ?? true;
    pauseOnScreenOff = prefs.getBool('pauseOnScreenOff') ?? true;
    buddyOnScreen = prefs.getBool('buddyOnScreen') ?? true;
    mode = prefs.getString('mode') ?? 'preset';
    activeCustomPresetId = prefs.getString('activeCustomPresetId');
    String themeStr = prefs.getString('themeMode') ?? 'system';
    themeMode = themeStr == 'light' ? ThemeMode.light : (themeStr == 'dark' ? ThemeMode.dark : ThemeMode.system);
    locale = Locale(prefs.getString('lang') ?? 'vi');
    List<String>? saved = prefs.getStringList('customPresets');
    if (saved != null) customPresets = saved.map((e) => CustomPreset.fromJson(jsonDecode(e))).toList();
    notifyListeners();
  }
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('count', shimejiCount);
    await prefs.setDouble('speed', speedMultiplier);
    await prefs.setDouble('size', sizeMultiplier);
    await prefs.setInt('freq', actionFrequency);
    await prefs.setBool('clickThrough', isClickThrough);
    await prefs.setBool('pauseOnScreenOff', pauseOnScreenOff);
    await prefs.setBool('buddyOnScreen', buddyOnScreen);
    await prefs.setString('mode', mode);
    await prefs.setString('themeMode', themeMode == ThemeMode.light ? 'light' : (themeMode == ThemeMode.dark ? 'dark' : 'system'));
    await prefs.setString('lang', locale.languageCode);
    if (activeCustomPresetId != null) {
      await prefs.setString('activeCustomPresetId', activeCustomPresetId!);
    } else {
      await prefs.remove('activeCustomPresetId');
    }
    await prefs.setStringList('customPresets', customPresets.map((e) => jsonEncode(e.toJson())).toList());
    if (Platform.isAndroid) {
      try {
        if (await FlutterOverlayWindow.isActive()) {
          await FlutterOverlayWindow.updateFlag(isClickThrough ? OverlayFlag.clickThrough : OverlayFlag.defaultFlag);
          await FlutterOverlayWindow.shareData('reload');
        }
      } catch (_) {}
    }
    notifyListeners();
  }
  void toggleTheme(ThemeMode m) { themeMode = m; save(); }
  void toggleLang(Locale l) { locale = l; save(); }
  String translate(String k) {
    Map<String, Map<String, String>> localized = {
      'vi': {
        'title': 'TScreen Funny Animation',
        'settings': 'Cài đặt',
        'save': 'Lưu cấu hình',
        'theme': 'Giao diện',
        'lang': 'Ngôn ngữ',
        'add_preset': 'Thêm nhân vật',
        'count': 'Số lượng',
        'speed': 'Tốc độ',
        'size': 'Kích thước',
        'click_through': 'Xuyên thấu (click xuyên buddy)',
        'battery': 'Tiết kiệm pin',
        'overlay_mode': 'Buddy ngoài màn hình',
        'overlay_mode_hint': 'Mở app là chạy buddy nổi trên màn hình',
        'tray_open': 'Mở ứng dụng',
        'tray_settings': 'Cài đặt',
        'tray_exit': 'Thoát',
        'part_head': 'Đầu',
        'part_body': 'Thân',
        'part_arm_upper': 'Bắp tay',
        'part_arm_lower': 'Cẳng tay',
        'part_hand': 'Bàn tay',
        'part_leg_upper': 'Đùi',
        'part_leg_lower': 'Cẳng chân',
        'part_foot': 'Bàn chân',
        'joint_head': 'Nối cổ',
        'joint_body': 'Thân / hông',
        'joint_shoulder': 'Khớp vai → khuỷu',
        'joint_elbow': 'Khớp khuỷu → cổ tay',
        'joint_wrist': 'Khớp cổ tay',
        'joint_hip': 'Khớp háng → gối',
        'joint_knee': 'Khớp gối → cổ chân',
        'joint_ankle': 'Khớp cổ chân',
        'parts_torso': 'Đầu & thân',
        'parts_arm': 'Tay (vai, khuỷu, cổ tay)',
        'parts_leg': 'Chân (háng, gối, cổ chân)',
        'preset_default': 'Mặc định',
        'preset_default_hint': 'Buddy có sẵn, không dùng ảnh tùy chỉnh',
        'preset_preview': 'Xem trước buddy',
      },
      'en': {
        'title': 'TScreen Funny Animation',
        'settings': 'Settings',
        'save': 'Save Config',
        'theme': 'Theme',
        'lang': 'Language',
        'add_preset': 'Add Preset',
        'count': 'Quantity',
        'speed': 'Speed',
        'size': 'Size',
        'click_through': 'Click through',
        'battery': 'Battery Saver',
        'overlay_mode': 'On-screen buddy',
        'overlay_mode_hint': 'Start with buddy floating on the screen',
        'tray_open': 'Open app',
        'tray_settings': 'Settings',
        'tray_exit': 'Exit',
        'part_head': 'Head',
        'part_body': 'Body',
        'part_arm_upper': 'Upper arm',
        'part_arm_lower': 'Forearm',
        'part_hand': 'Hand',
        'part_leg_upper': 'Thigh',
        'part_leg_lower': 'Shin',
        'part_foot': 'Foot',
        'joint_head': 'Neck joint',
        'joint_body': 'Torso / hips',
        'joint_shoulder': 'Shoulder → elbow',
        'joint_elbow': 'Elbow → wrist',
        'joint_wrist': 'Wrist joint',
        'joint_hip': 'Hip → knee',
        'joint_knee': 'Knee → ankle',
        'joint_ankle': 'Ankle joint',
        'parts_torso': 'Head & body',
        'parts_arm': 'Arms (shoulder, elbow, wrist)',
        'parts_leg': 'Legs (hip, knee, ankle)',
        'preset_default': 'Default',
        'preset_default_hint': 'Built-in buddy, no custom parts',
        'preset_preview': 'Buddy preview',
      },
    };
    return localized[locale.languageCode]?[k] ?? k;
  }
  CustomPreset? getActiveCustom() {
    if (mode != 'custom' || activeCustomPresetId == null) return null;
    try { return customPresets.firstWhere((p) => p.id == activeCustomPresetId); } catch (_) { return null; }
  }

  Future<void> selectPreset(String? id) async {
    if (id == null) {
      mode = 'preset';
      activeCustomPresetId = null;
    } else {
      mode = 'custom';
      activeCustomPresetId = id;
    }
    await save();
  }
}
