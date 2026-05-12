import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/config.dart';

class ShimejiCharacter extends StatefulWidget {
  final bool isOverlay;
  const ShimejiCharacter({super.key, required this.isOverlay});
  @override
  State<ShimejiCharacter> createState() => _ShimejiCharacterState();
}

class _ShimejiCharacterState extends State<ShimejiCharacter> with TickerProviderStateMixin {
  double posX = 50, posY = 50, velX = 0, velY = 0;
  bool isLeft = false; String mode = 'fall';
  late AnimationController _animCtrl; late Timer _logicTimer; final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    posX = _rng.nextDouble() * 150 + 50;
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
    _logicTimer = Timer.periodic(const Duration(milliseconds: 16), (t) => _update());
    _brain();
  }

  void _brain() {
    Future.delayed(Duration(seconds: _rng.nextInt(AppConfig.instance.actionFrequency) + 1), () {
      if (!mounted) return;
      if (mode != 'fall' && mode != 'drag' && mode != 'climb') {
        int r = _rng.nextInt(100);
        if (r < 20) { mode = 'idle'; velX = 0; }
        else if (r < 50) { mode = 'walk'; velX = (isLeft ? -2.0 : 2.0) * AppConfig.instance.speedMultiplier; }
        else if (r < 80) { mode = 'crawl'; velX = (isLeft ? -1.0 : 1.0) * AppConfig.instance.speedMultiplier; }
        else { mode = 'jump'; velY = -12 * AppConfig.instance.speedMultiplier; mode = 'fall'; }
      }
      _brain();
    });
  }

  void _update() {
    if (!mounted || mode == 'drag') return;
    Size s = MediaQuery.of(context).size;
    double scale = AppConfig.instance.sizeMultiplier;
    double hitW = 100 * scale; double hitH = 150 * scale;
    
    setState(() {
      if (mode != 'climb') velY += 0.8 * AppConfig.instance.speedMultiplier;
      posX += velX; posY += velY;
      if (posY >= s.height - hitH && s.height > 0) { posY = s.height - hitH; velY = 0; if (mode == 'fall') mode = 'idle'; }
      if (posX <= 0) {
        posX = 0;
        if (mode == 'walk' || mode == 'crawl') { isLeft = false; velX = (mode == 'walk' ? 2.0 : 1.0) * AppConfig.instance.speedMultiplier; }
        else if (mode == 'climb') { isLeft = true; }
        if (mode != 'fall' && mode != 'drag' && _rng.nextBool() && posY > 0) { mode = 'climb'; velY = -2 * AppConfig.instance.speedMultiplier; velX = 0; isLeft = true; }
      } else if (posX >= s.width - hitW && s.width > 0) {
        posX = s.width - hitW;
        if (mode == 'walk' || mode == 'crawl') { isLeft = true; velX = (mode == 'walk' ? -2.0 : -1.0) * AppConfig.instance.speedMultiplier; }
        else if (mode == 'climb') { isLeft = false; }
        if (mode != 'fall' && mode != 'drag' && _rng.nextBool() && posY > 0) { mode = 'climb'; velY = -2 * AppConfig.instance.speedMultiplier; velX = 0; isLeft = false; }
      } else { if (mode == 'climb') { mode = 'fall'; velY = 0; } }
      if (posY <= 0 && mode == 'climb') { mode = 'fall'; velY = 2 * AppConfig.instance.speedMultiplier; velX = isLeft ? 2 : -2; }
    });
  }

  @override
  void dispose() { _animCtrl.dispose(); _logicTimer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    bool ignoreTouches = widget.isOverlay && AppConfig.instance.isClickThrough;
    return Positioned(
      left: posX, top: posY,
      child: IgnorePointer(
        ignoring: ignoreTouches,
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onPanUpdate: (d) => setState(() { mode = 'drag'; posX += d.delta.dx; posY += d.delta.dy; }),
          onPanEnd: (d) => setState(() { mode = 'fall'; velX = d.velocity.pixelsPerSecond.dx / 100; velY = d.velocity.pixelsPerSecond.dy / 100; }),
          child: Transform.scale(
            scale: AppConfig.instance.sizeMultiplier,
            alignment: Alignment.topLeft,
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, child) => Transform(
                alignment: const Alignment(0, 0.5),
                transform: Matrix4.rotationY(isLeft ? pi : 0),
                child: _buildSkeleton(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    double t = _animCtrl.value * (AppConfig.instance.speedMultiplier);
    double walkPhase = sin(t * pi * 2); double climbPhase = sin(t * pi * 4);
    double headRot = mode == 'idle' ? sin(t * pi) * 0.1 : 0;
    double bodyTilt = 0, armRot = 0, legRot = 0;

    if (mode == 'walk') { bodyTilt = 0.1; armRot = walkPhase * 0.5; legRot = walkPhase * 0.6; }
    else if (mode == 'crawl') { bodyTilt = pi / 2 - 0.2; headRot = -pi / 2 + 0.3; armRot = walkPhase * 0.8; legRot = walkPhase * 0.8; }
    else if (mode == 'fall') { armRot = pi - 0.5; legRot = 0.2; }
    else if (mode == 'climb') { armRot = pi + climbPhase * 0.2; legRot = climbPhase * 0.3; }
    else if (mode == 'drag') { armRot = pi; legRot = 0.5; }

    final cfg = AppConfig.instance;
    Color hC = Colors.orange, bC = Colors.blue, aC = Colors.blueGrey, lC = Colors.brown;
    if (cfg.mode == 'preset' && cfg.presetId == 1) { hC = Colors.red; bC = Colors.black87; aC = Colors.grey; lC = Colors.redAccent; }
    else if (cfg.mode == 'preset' && cfg.presetId == 2) { hC = Colors.greenAccent; bC = Colors.purple; aC = Colors.teal; lC = Colors.deepPurple; }

    CustomPreset? cp = cfg.getActiveCustom();
    bool isCustom = cfg.mode == 'custom';

    return SizedBox(
      width: 100, height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 35, top: 50, child: _joint(25, 50, bC, bodyTilt, Alignment.bottomCenter, isCustom ? cp?.bodyImg : null, [
            Positioned(left: -5, top: -35, child: _joint(35, 35, hC, headRot, Alignment.bottomCenter, isCustom ? cp?.headImg : null, [
              if (!isCustom || cp?.headImg == null) Positioned(left: 5, top: 5, child: _eye()),
              if (!isCustom || cp?.headImg == null) Positioned(left: 20, top: 5, child: _eye()),
            ])),
            Positioned(left: -10, top: 0, child: _joint(12, 35, aC, -armRot, Alignment.topCenter, isCustom ? cp?.armImg : null, [
              Positioned(left: 0, top: 30, child: _joint(10, 30, aC, -0.2, Alignment.topCenter, isCustom ? cp?.armImg : null, [])),
            ])),
            Positioned(left: 25, top: 0, child: _joint(12, 35, aC, armRot, Alignment.topCenter, isCustom ? cp?.armImg : null, [
              Positioned(left: 0, top: 30, child: _joint(10, 30, aC, 0.2, Alignment.topCenter, isCustom ? cp?.armImg : null, [])),
            ])),
            Positioned(left: 0, top: 45, child: _joint(12, 35, lC, legRot, Alignment.topCenter, isCustom ? cp?.legImg : null, [
              Positioned(left: 0, top: 30, child: _joint(11, 30, lC, legRot.abs(), Alignment.topCenter, isCustom ? cp?.legImg : null, [])),
            ])),
            Positioned(left: 15, top: 45, child: _joint(12, 35, lC, -legRot, Alignment.topCenter, isCustom ? cp?.legImg : null, [
              Positioned(left: 0, top: 30, child: _joint(11, 30, lC, legRot.abs(), Alignment.topCenter, isCustom ? cp?.legImg : null, [])),
            ])),
          ])),
        ],
      ),
    );
  }

  Widget _eye() => Container(width: 5, height: 5, color: Colors.white, child: Center(child: Container(width: 2, height: 2, color: Colors.black)));

  // BỎ HOÀN TOÀN ĐÓNG KHUNG THEO YÊU CẦU
  Widget _joint(double w, double h, Color c, double r, Alignment a, String? img, List<Widget> children) {
    bool hasImg = img != null && img.isNotEmpty;
    return Transform.rotate(
      angle: r, alignment: a,
      child: Container(
        width: w, height: h,
        decoration: hasImg ? null : BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
        child: Stack(clipBehavior: Clip.none, children: [
          if (hasImg) Positioned.fill(
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Image.file(File(img), fit: BoxFit.contain, width: w * 2.5) // Ảnh không bị bó hẹp, tự phóng to vượt khung
            )
          ),
          ...children
        ]),
      ),
    );
  }
}
